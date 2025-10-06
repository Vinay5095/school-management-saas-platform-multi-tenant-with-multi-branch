# SPEC-129: Notifications Management
## Comprehensive Notification System and Alert Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6-7 hours  
> **Dependencies**: SPEC-116, SPEC-128, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive notification management system for handling real-time alerts, email notifications, in-app notifications, and notification preferences across the entire platform including all tenant environments.

### Key Features
- ✅ Real-time notification system
- ✅ Multi-channel delivery (email, in-app, push)
- ✅ Notification templates and customization
- ✅ User preference management
- ✅ Notification scheduling and batching
- ✅ Delivery status tracking
- ✅ Notification analytics and metrics
- ✅ Emergency alert broadcasting
- ✅ Tenant-specific notifications
- ✅ Auto-escalation workflows
- ✅ Rich notification content support
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Notification types and categories
CREATE TABLE notification_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_name TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL CHECK (category IN (
    'system', 'security', 'billing', 'tenant', 'user', 
    'academic', 'support', 'marketing', 'emergency'
  )),
  display_name TEXT NOT NULL,
  description TEXT,
  default_channels TEXT[] DEFAULT ARRAY['in_app'],
  is_critical BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notification templates
CREATE TABLE notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_type_id UUID NOT NULL REFERENCES notification_types(id),
  channel TEXT NOT NULL CHECK (channel IN ('email', 'in_app', 'push', 'sms')),
  template_name TEXT NOT NULL,
  title_template TEXT NOT NULL,
  content_template TEXT NOT NULL,
  action_url_template TEXT,
  variables JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(notification_type_id, channel)
);

-- Main notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_type_id UUID NOT NULL REFERENCES notification_types(id),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  action_url TEXT,
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  channels TEXT[] NOT NULL DEFAULT ARRAY['in_app'],
  target_type TEXT NOT NULL CHECK (target_type IN ('user', 'role', 'tenant', 'global')),
  target_criteria JSONB NOT NULL DEFAULT '{}'::jsonb,
  scheduled_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  data JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_at TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed', 'cancelled')) DEFAULT 'draft'
);

-- Notification recipients and delivery tracking
CREATE TABLE notification_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id),
  channel TEXT NOT NULL CHECK (channel IN ('email', 'in_app', 'push', 'sms')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed', 'bounced')) DEFAULT 'pending',
  delivery_details JSONB DEFAULT '{}'::jsonb,
  sent_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  attempts INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMP WITH TIME ZONE
);

-- User notification preferences
CREATE TABLE user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  notification_type_id UUID NOT NULL REFERENCES notification_types(id),
  channels TEXT[] NOT NULL DEFAULT ARRAY['in_app'],
  is_enabled BOOLEAN DEFAULT TRUE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  timezone TEXT DEFAULT 'UTC',
  frequency TEXT CHECK (frequency IN ('immediate', 'hourly', 'daily', 'weekly')) DEFAULT 'immediate',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, notification_type_id)
);

-- Notification subscriptions for groups/roles
CREATE TABLE notification_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_type_id UUID NOT NULL REFERENCES notification_types(id),
  tenant_id UUID REFERENCES tenants(id),
  role_name TEXT,
  branch_id UUID REFERENCES branches(id),
  is_auto_subscribe BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(notification_type_id, tenant_id, role_name, branch_id)
);

-- Notification analytics
CREATE TABLE notification_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  notification_type_id UUID REFERENCES notification_types(id),
  tenant_id UUID REFERENCES tenants(id),
  channel TEXT,
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_read INTEGER DEFAULT 0,
  total_failed INTEGER DEFAULT 0,
  average_delivery_time INTERVAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(date, notification_type_id, tenant_id, channel)
);

-- Emergency broadcasts
CREATE TABLE emergency_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical', 'emergency')),
  target_scope TEXT NOT NULL CHECK (target_scope IN ('global', 'tenant', 'branch', 'role')),
  target_criteria JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  auto_dismiss_at TIMESTAMP WITH TIME ZONE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_notifications_tenant_status ON notifications(tenant_id, status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notification_deliveries_recipient ON notification_deliveries(recipient_id, status);
CREATE INDEX idx_notification_deliveries_notification ON notification_deliveries(notification_id);
CREATE INDEX idx_user_preferences_user ON user_notification_preferences(user_id);
CREATE INDEX idx_notification_analytics_date ON notification_analytics(date);
CREATE INDEX idx_emergency_broadcasts_active ON emergency_broadcasts(is_active);
```

---

## 🎨 UI COMPONENTS

### Notifications Dashboard
```tsx
// components/admin/notifications/NotificationsDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { NotificationComposer } from './NotificationComposer';
import { NotificationTemplates } from './NotificationTemplates';
import { NotificationAnalytics } from './NotificationAnalytics';
import { EmergencyBroadcast } from './EmergencyBroadcast';
import { 
  Bell, 
  Plus, 
  Send,
  Users, 
  Mail,
  Smartphone,
  AlertTriangle,
  TrendingUp,
  Filter,
  Search,
  Clock,
  CheckCircle,
  XCircle
} from 'lucide-react';

interface Notification {
  id: string;
  title: string;
  content: string;
  priority: string;
  channels: string[];
  target_type: string;
  status: string;
  created_at: string;
  sent_at: string | null;
  total_recipients?: number;
  delivered_count?: number;
  read_count?: number;
}

export function NotificationsDashboard() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    sent: 0,
    pending: 0,
    failed: 0
  });
  const [showComposer, setShowComposer] = useState(false);
  const [filters, setFilters] = useState({
    status: '',
    priority: '',
    search: ''
  });

  useEffect(() => {
    loadNotifications();
    loadStats();
  }, [filters]);

  const loadNotifications = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filters.status) params.append('status', filters.status);
      if (filters.priority) params.append('priority', filters.priority);
      if (filters.search) params.append('search', filters.search);
      
      const response = await fetch(`/api/admin/notifications?${params}`);
      const data = await response.json();
      setNotifications(data.notifications || []);
    } catch (error) {
      console.error('Failed to load notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await fetch('/api/admin/notifications/stats');
      const data = await response.json();
      setStats(data.stats || {});
    } catch (error) {
      console.error('Failed to load notification stats:', error);
    }
  };

  const getStatusColor = (status: string) => {
    const colors = {
      'draft': 'bg-gray-100 text-gray-800',
      'scheduled': 'bg-blue-100 text-blue-800',
      'sending': 'bg-yellow-100 text-yellow-800',
      'sent': 'bg-green-100 text-green-800',
      'failed': 'bg-red-100 text-red-800',
      'cancelled': 'bg-gray-100 text-gray-800'
    };
    return colors[status as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const getPriorityColor = (priority: string) => {
    const colors = {
      'low': 'bg-green-100 text-green-800',
      'medium': 'bg-yellow-100 text-yellow-800',
      'high': 'bg-orange-100 text-orange-800',
      'critical': 'bg-red-100 text-red-800'
    };
    return colors[priority as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const getChannelIcon = (channel: string) => {
    const icons = {
      'email': Mail,
      'in_app': Bell,
      'push': Smartphone,
      'sms': Smartphone
    };
    const Icon = icons[channel as keyof typeof icons] || Bell;
    return <Icon className="w-3 h-3" />;
  };

  if (showComposer) {
    return (
      <NotificationComposer
        onClose={() => {
          setShowComposer(false);
          loadNotifications();
        }}
      />
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Notifications</h1>
          <p className="text-gray-600">Manage platform notifications and alerts</p>
        </div>
        <div className="flex gap-2">
          <EmergencyBroadcast />
          <Button onClick={() => setShowComposer(true)}>
            <Plus className="w-4 h-4 mr-2" />
            New Notification
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <Bell className="h-4 w-4 text-muted-foreground" />
              <div className="ml-2">
                <p className="text-sm font-medium">Total Notifications</p>
                <p className="text-2xl font-bold">{stats.total}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <CheckCircle className="h-4 w-4 text-green-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Sent</p>
                <p className="text-2xl font-bold">{stats.sent}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <Clock className="h-4 w-4 text-yellow-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Pending</p>
                <p className="text-2xl font-bold">{stats.pending}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <XCircle className="h-4 w-4 text-red-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Failed</p>
                <p className="text-2xl font-bold">{stats.failed}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="notifications" className="space-y-6">
        <TabsList>
          <TabsTrigger value="notifications">
            <Bell className="w-4 h-4 mr-2" />
            Notifications
          </TabsTrigger>
          <TabsTrigger value="templates">
            <Mail className="w-4 h-4 mr-2" />
            Templates
          </TabsTrigger>
          <TabsTrigger value="analytics">
            <TrendingUp className="w-4 h-4 mr-2" />
            Analytics
          </TabsTrigger>
        </TabsList>

        <TabsContent value="notifications" className="space-y-6">
          {/* Filters */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-4">
                <div className="relative flex-1 max-w-xs">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    placeholder="Search notifications..."
                    value={filters.search}
                    onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                    className="pl-10"
                  />
                </div>
                
                <Select value={filters.status} onValueChange={(value) => setFilters({ ...filters, status: value })}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="All Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">All Status</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="scheduled">Scheduled</SelectItem>
                    <SelectItem value="sending">Sending</SelectItem>
                    <SelectItem value="sent">Sent</SelectItem>
                    <SelectItem value="failed">Failed</SelectItem>
                  </SelectContent>
                </Select>
                
                <Select value={filters.priority} onValueChange={(value) => setFilters({ ...filters, priority: value })}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="All Priority" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">All Priority</SelectItem>
                    <SelectItem value="low">Low</SelectItem>
                    <SelectItem value="medium">Medium</SelectItem>
                    <SelectItem value="high">High</SelectItem>
                    <SelectItem value="critical">Critical</SelectItem>
                  </SelectContent>
                </Select>
                
                <Button variant="outline" onClick={loadNotifications}>
                  <Filter className="w-4 h-4 mr-2" />
                  Refresh
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Notifications List */}
          <div className="space-y-4">
            {loading ? (
              <div className="text-center py-12">Loading notifications...</div>
            ) : notifications.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                No notifications found. Create your first notification to get started.
              </div>
            ) : (
              notifications.map((notification) => (
                <Card key={notification.id} className="hover:shadow-md transition-shadow">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <CardTitle className="text-lg">{notification.title}</CardTitle>
                        <CardDescription className="mt-1">
                          {notification.content.substring(0, 100)}
                          {notification.content.length > 100 && '...'}
                        </CardDescription>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge 
                          variant="secondary" 
                          className={getPriorityColor(notification.priority)}
                        >
                          {notification.priority}
                        </Badge>
                        <Badge 
                          variant="secondary"
                          className={getStatusColor(notification.status)}
                        >
                          {notification.status}
                        </Badge>
                      </div>
                    </div>
                  </CardHeader>
                  
                  <CardContent className="space-y-3">
                    <div className="flex items-center gap-4">
                      <div className="flex items-center gap-1">
                        <span className="text-sm text-gray-500">Channels:</span>
                        <div className="flex gap-1">
                          {notification.channels.map((channel) => (
                            <div key={channel} className="flex items-center text-xs bg-gray-100 px-2 py-1 rounded">
                              {getChannelIcon(channel)}
                              <span className="ml-1">{channel}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                      
                      <div className="text-sm text-gray-500">
                        Target: <span className="font-medium">{notification.target_type}</span>
                      </div>
                    </div>
                    
                    {notification.total_recipients && (
                      <div className="flex items-center gap-4 text-sm">
                        <span>Recipients: {notification.total_recipients}</span>
                        <span>Delivered: {notification.delivered_count || 0}</span>
                        <span>Read: {notification.read_count || 0}</span>
                      </div>
                    )}
                    
                    <div className="flex items-center justify-between pt-2 border-t">
                      <div className="text-xs text-gray-500">
                        Created: {new Date(notification.created_at).toLocaleString()}
                        {notification.sent_at && (
                          <span className="ml-4">
                            Sent: {new Date(notification.sent_at).toLocaleString()}
                          </span>
                        )}
                      </div>
                      
                      <div className="flex gap-2">
                        {notification.status === 'draft' && (
                          <Button size="sm" variant="outline">
                            <Send className="w-3 h-3 mr-1" />
                            Send
                          </Button>
                        )}
                        <Button size="sm" variant="outline">
                          View Details
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        <TabsContent value="templates">
          <NotificationTemplates />
        </TabsContent>

        <TabsContent value="analytics">
          <NotificationAnalytics />
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

### Notification Composer
```tsx
// components/admin/notifications/NotificationComposer.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { 
  Send, 
  Save, 
  X, 
  Clock,
  Users,
  Mail,
  Smartphone,
  Bell,
  AlertTriangle
} from 'lucide-react';

interface NotificationComposerProps {
  onClose: () => void;
}

interface NotificationType {
  id: string;
  type_name: string;
  display_name: string;
  category: string;
  default_channels: string[];
  is_critical: boolean;
}

export function NotificationComposer({ onClose }: NotificationComposerProps) {
  const [formData, setFormData] = useState({
    notification_type_id: '',
    title: '',
    content: '',
    priority: 'medium',
    channels: ['in_app'],
    target_type: 'global',
    target_criteria: {},
    scheduled_at: '',
    expires_at: ''
  });
  
  const [notificationTypes, setNotificationTypes] = useState<NotificationType[]>([]);
  const [loading, setLoading] = useState(false);
  const [previewMode, setPreviewMode] = useState(false);

  useEffect(() => {
    loadNotificationTypes();
  }, []);

  const loadNotificationTypes = async () => {
    try {
      const response = await fetch('/api/admin/notifications/types');
      const data = await response.json();
      setNotificationTypes(data.types || []);
    } catch (error) {
      console.error('Failed to load notification types:', error);
    }
  };

  const handleSubmit = async (action: 'draft' | 'send') => {
    setLoading(true);
    try {
      const response = await fetch('/api/admin/notifications', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          status: action === 'send' ? 'scheduled' : 'draft'
        })
      });
      
      if (response.ok) {
        onClose();
      }
    } catch (error) {
      console.error('Failed to create notification:', error);
    } finally {
      setLoading(false);
    }
  };

  const selectedType = notificationTypes.find(t => t.id === formData.notification_type_id);

  const getChannelIcon = (channel: string) => {
    const icons = {
      'email': Mail,
      'in_app': Bell,
      'push': Smartphone,
      'sms': Smartphone
    };
    const Icon = icons[channel as keyof typeof icons] || Bell;
    return <Icon className="w-4 h-4" />;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Create Notification</h1>
          <p className="text-gray-600">Compose and send notifications to users</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={onClose}>
            <X className="w-4 h-4 mr-2" />
            Cancel
          </Button>
          <Button 
            variant="outline" 
            onClick={() => handleSubmit('draft')}
            disabled={loading}
          >
            <Save className="w-4 h-4 mr-2" />
            Save Draft
          </Button>
          <Button 
            onClick={() => handleSubmit('send')}
            disabled={loading || !formData.title || !formData.content}
          >
            <Send className="w-4 h-4 mr-2" />
            Send Notification
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Form */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Notification Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Notification Type</label>
                <Select 
                  value={formData.notification_type_id}
                  onValueChange={(value) => {
                    const type = notificationTypes.find(t => t.id === value);
                    setFormData({ 
                      ...formData, 
                      notification_type_id: value,
                      channels: type?.default_channels || ['in_app']
                    });
                  }}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select notification type" />
                  </SelectTrigger>
                  <SelectContent>
                    {notificationTypes.map((type) => (
                      <SelectItem key={type.id} value={type.id}>
                        <div className="flex items-center">
                          <span>{type.display_name}</span>
                          {type.is_critical && (
                            <AlertTriangle className="w-4 h-4 ml-2 text-red-500" />
                          )}
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium">Title</label>
                <Input
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="Enter notification title"
                />
              </div>

              <div>
                <label className="text-sm font-medium">Content</label>
                <Textarea
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  placeholder="Enter notification message"
                  className="min-h-[120px]"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">Priority</label>
                  <Select 
                    value={formData.priority}
                    onValueChange={(value) => setFormData({ ...formData, priority: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="low">Low</SelectItem>
                      <SelectItem value="medium">Medium</SelectItem>
                      <SelectItem value="high">High</SelectItem>
                      <SelectItem value="critical">Critical</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="text-sm font-medium">Target</label>
                  <Select 
                    value={formData.target_type}
                    onValueChange={(value) => setFormData({ ...formData, target_type: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="global">All Users</SelectItem>
                      <SelectItem value="tenant">Specific Tenant</SelectItem>
                      <SelectItem value="role">Specific Role</SelectItem>
                      <SelectItem value="user">Specific Users</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Delivery Channels</CardTitle>
              <CardDescription>
                Select how this notification should be delivered
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4">
                {['in_app', 'email', 'push', 'sms'].map((channel) => (
                  <label key={channel} className="flex items-center space-x-3 p-3 border rounded cursor-pointer hover:bg-gray-50">
                    <input
                      type="checkbox"
                      checked={formData.channels.includes(channel)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setFormData({
                            ...formData,
                            channels: [...formData.channels, channel]
                          });
                        } else {
                          setFormData({
                            ...formData,
                            channels: formData.channels.filter(c => c !== channel)
                          });
                        }
                      }}
                      className="rounded"
                    />
                    <div className="flex items-center">
                      {getChannelIcon(channel)}
                      <span className="ml-2 capitalize">{channel.replace('_', ' ')}</span>
                    </div>
                  </label>
                ))}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Scheduling & Expiration</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Schedule Send Time (Optional)</label>
                <Input
                  type="datetime-local"
                  value={formData.scheduled_at}
                  onChange={(e) => setFormData({ ...formData, scheduled_at: e.target.value })}
                />
              </div>

              <div>
                <label className="text-sm font-medium">Expiration Time (Optional)</label>
                <Input
                  type="datetime-local"
                  value={formData.expires_at}
                  onChange={(e) => setFormData({ ...formData, expires_at: e.target.value })}
                />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Preview</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-4 border rounded-lg bg-gray-50">
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-medium">{formData.title || 'Notification Title'}</h4>
                  <Badge variant="secondary">{formData.priority}</Badge>
                </div>
                <p className="text-sm text-gray-600">
                  {formData.content || 'Notification content will appear here...'}
                </p>
                <div className="flex gap-1 mt-2">
                  {formData.channels.map(channel => (
                    <Badge key={channel} variant="outline" className="text-xs">
                      {channel}
                    </Badge>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>

          {selectedType && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Type Information</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <div>
                    <span className="text-sm font-medium">Category:</span>
                    <span className="text-sm text-gray-600 ml-2">{selectedType.category}</span>
                  </div>
                  <div>
                    <span className="text-sm font-medium">Default Channels:</span>
                    <div className="flex gap-1 mt-1">
                      {selectedType.default_channels.map(channel => (
                        <Badge key={channel} variant="outline" className="text-xs">
                          {channel}
                        </Badge>
                      ))}
                    </div>
                  </div>
                  {selectedType.is_critical && (
                    <div className="flex items-center text-red-600 text-sm">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      Critical notification type
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Delivery Estimate</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Estimated Recipients:</span>
                  <span className="font-medium">~1,250</span>
                </div>
                <div className="flex justify-between">
                  <span>Delivery Time:</span>
                  <span className="font-medium">~2-5 minutes</span>
                </div>
                <div className="flex justify-between">
                  <span>Channels:</span>
                  <span className="font-medium">{formData.channels.length}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
```

---

## 🔧 API ROUTES

### Notifications API
```typescript
// app/api/admin/notifications/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    const priority = searchParams.get('priority');
    const search = searchParams.get('search');

    let query = supabase
      .from('notifications')
      .select(`
        *,
        notification_types(display_name, category),
        notification_deliveries(
          status,
          channel,
          delivered_at,
          read_at
        )
      `)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    if (priority) {
      query = query.eq('priority', priority);
    }

    if (search) {
      query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
    }

    const { data: notifications, error } = await query;

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to fetch notifications' }, { status: 500 });
    }

    // Add delivery statistics
    const enrichedNotifications = notifications?.map(notification => {
      const deliveries = notification.notification_deliveries || [];
      return {
        ...notification,
        total_recipients: deliveries.length,
        delivered_count: deliveries.filter(d => d.status === 'delivered').length,
        read_count: deliveries.filter(d => d.read_at).length
      };
    });

    return NextResponse.json({ notifications: enrichedNotifications || [] });
  } catch (error) {
    console.error('Failed to fetch notifications:', error);
    return NextResponse.json(
      { error: 'Failed to fetch notifications' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();
    const user = await supabase.auth.getUser();
    const body = await request.json();

    const { data: notification, error } = await supabase
      .from('notifications')
      .insert({
        ...body,
        created_by: user.data.user?.id
      })
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to create notification' }, { status: 500 });
    }

    // If status is 'scheduled', process delivery
    if (body.status === 'scheduled') {
      await processNotificationDelivery(notification.id);
    }

    return NextResponse.json(notification, { status: 201 });
  } catch (error) {
    console.error('Failed to create notification:', error);
    return NextResponse.json(
      { error: 'Failed to create notification' },
      { status: 500 }
    );
  }
}

async function processNotificationDelivery(notificationId: string) {
  // This would typically be handled by a background job
  // For now, we'll just update the status
  const supabase = createClient();
  
  await supabase
    .from('notifications')
    .update({ 
      status: 'sending',
      sent_at: new Date().toISOString()
    })
    .eq('id', notificationId);
}
```

### Real-time Notifications API
```typescript
// app/api/admin/notifications/realtime/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const supabase = createClient();
    const body = await request.json();
    const { userId, notification } = body;

    // Send real-time notification via Supabase realtime
    await supabase.channel('notifications')
      .send({
        type: 'broadcast',
        event: 'new_notification',
        payload: {
          userId,
          notification
        }
      });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Failed to send real-time notification:', error);
    return NextResponse.json(
      { error: 'Failed to send notification' },
      { status: 500 }
    );
  }
}
```

---

## ⚙️ NOTIFICATION UTILITIES

### Notification Service
```typescript
// lib/notifications/service.ts
import { createClient } from '@/lib/supabase/server';
import { sendTemplatedEmail } from '@/lib/email/sender';

interface NotificationOptions {
  type: string;
  title: string;
  content: string;
  recipients: string[];
  channels?: string[];
  priority?: string;
  data?: Record<string, any>;
  scheduledAt?: string;
}

export class NotificationService {
  private supabase = createClient();

  async sendNotification(options: NotificationOptions) {
    try {
      // Create notification record
      const { data: notification, error } = await this.supabase
        .from('notifications')
        .insert({
          title: options.title,
          content: options.content,
          priority: options.priority || 'medium',
          channels: options.channels || ['in_app'],
          target_type: 'user',
          target_criteria: { userIds: options.recipients },
          scheduled_at: options.scheduledAt || new Date().toISOString(),
          data: options.data || {},
          status: 'sending'
        })
        .select()
        .single();

      if (error) throw error;

      // Process each channel
      for (const channel of (options.channels || ['in_app'])) {
        await this.processChannel(notification, options.recipients, channel);
      }

      // Update notification status
      await this.supabase
        .from('notifications')
        .update({ 
          status: 'sent',
          sent_at: new Date().toISOString()
        })
        .eq('id', notification.id);

      return { success: true, notificationId: notification.id };
    } catch (error) {
      console.error('Failed to send notification:', error);
      return { success: false, error: error.message };
    }
  }

  private async processChannel(notification: any, recipients: string[], channel: string) {
    for (const recipientId of recipients) {
      try {
        // Create delivery record
        const { data: delivery } = await this.supabase
          .from('notification_deliveries')
          .insert({
            notification_id: notification.id,
            recipient_id: recipientId,
            channel,
            status: 'pending'
          })
          .select()
          .single();

        // Process based on channel
        switch (channel) {
          case 'email':
            await this.sendEmailNotification(notification, recipientId, delivery.id);
            break;
          case 'in_app':
            await this.sendInAppNotification(notification, recipientId, delivery.id);
            break;
          case 'push':
            await this.sendPushNotification(notification, recipientId, delivery.id);
            break;
        }
      } catch (error) {
        console.error(`Failed to process ${channel} notification for user ${recipientId}:`, error);
      }
    }
  }

  private async sendEmailNotification(notification: any, recipientId: string, deliveryId: string) {
    try {
      // Get user email
      const { data: user } = await this.supabase
        .from('users')
        .select('email, first_name, last_name')
        .eq('id', recipientId)
        .single();

      if (!user?.email) return;

      // Send email using template
      const result = await sendTemplatedEmail({
        templateKey: 'notification_email',
        recipientEmail: user.email,
        recipientName: `${user.first_name} ${user.last_name}`,
        variables: {
          title: notification.title,
          content: notification.content,
          recipientName: user.first_name
        }
      });

      // Update delivery status
      await this.supabase
        .from('notification_deliveries')
        .update({
          status: result.success ? 'sent' : 'failed',
          sent_at: new Date().toISOString(),
          error_message: result.success ? null : result.error
        })
        .eq('id', deliveryId);
    } catch (error) {
      console.error('Email notification failed:', error);
    }
  }

  private async sendInAppNotification(notification: any, recipientId: string, deliveryId: string) {
    try {
      // Send via Supabase realtime
      await this.supabase.channel(`user:${recipientId}`)
        .send({
          type: 'broadcast',
          event: 'notification',
          payload: {
            id: notification.id,
            title: notification.title,
            content: notification.content,
            priority: notification.priority,
            createdAt: notification.created_at
          }
        });

      // Update delivery status
      await this.supabase
        .from('notification_deliveries')
        .update({
          status: 'sent',
          sent_at: new Date().toISOString()
        })
        .eq('id', deliveryId);
    } catch (error) {
      console.error('In-app notification failed:', error);
    }
  }

  private async sendPushNotification(notification: any, recipientId: string, deliveryId: string) {
    // Implementation depends on push notification service (FCM, APNS, etc.)
    console.log('Push notification not implemented yet');
  }

  async markAsRead(deliveryId: string, userId: string) {
    await this.supabase
      .from('notification_deliveries')
      .update({ 
        status: 'read',
        read_at: new Date().toISOString()
      })
      .eq('id', deliveryId)
      .eq('recipient_id', userId);
  }
}

export const notificationService = new NotificationService();
```

---

## 📋 TESTING REQUIREMENTS

### Notifications Tests
```typescript
// __tests__/admin/notifications/NotificationsDashboard.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { NotificationsDashboard } from '@/components/admin/notifications/NotificationsDashboard';

const mockNotifications = [
  {
    id: '1',
    title: 'System Maintenance',
    content: 'Scheduled maintenance tonight',
    priority: 'high',
    channels: ['email', 'in_app'],
    target_type: 'global',
    status: 'sent',
    created_at: '2025-01-01T00:00:00Z',
    sent_at: '2025-01-01T00:05:00Z',
    total_recipients: 1250,
    delivered_count: 1200,
    read_count: 800
  }
];

describe('NotificationsDashboard', () => {
  beforeEach(() => {
    global.fetch = jest.fn()
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ notifications: mockNotifications })
      })
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ 
          stats: { total: 5, sent: 3, pending: 1, failed: 1 }
        })
      });
  });

  it('renders notifications dashboard', async () => {
    render(<NotificationsDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Notifications')).toBeInTheDocument();
    });
  });

  it('displays notification stats', async () => {
    render(<NotificationsDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Total Notifications')).toBeInTheDocument();
      expect(screen.getByText('5')).toBeInTheDocument();
    });
  });

  it('displays notifications list', async () => {
    render(<NotificationsDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('System Maintenance')).toBeInTheDocument();
      expect(screen.getByText('Recipients: 1250')).toBeInTheDocument();
    });
  });

  it('filters notifications by status', async () => {
    render(<NotificationsDashboard />);
    
    await waitFor(() => {
      const statusFilter = screen.getByDisplayValue('All Status');
      fireEvent.click(statusFilter);
      
      const sentOption = screen.getByText('Sent');
      fireEvent.click(sentOption);
    });
    
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('status=sent')
    );
  });
});
```

---

## 🔐 PERMISSIONS & ROLES

### Required Permissions
- **Super Admin**: Full access to all notification features
- **Platform Manager**: Create and manage platform-wide notifications
- **Tenant Admin**: Manage tenant-specific notifications
- **Support Manager**: Send support and emergency notifications

### Role-based Access Control
```sql
-- Notification management permissions
INSERT INTO role_permissions (role_name, permission) VALUES
('super_admin', 'notifications:manage_all'),
('super_admin', 'notifications:create_emergency'),
('super_admin', 'notifications:manage_templates'),
('super_admin', 'notifications:view_analytics'),
('platform_manager', 'notifications:create_platform'),
('platform_manager', 'notifications:view_analytics'),
('tenant_admin', 'notifications:create_tenant'),
('support_manager', 'notifications:create_support'),
('support_manager', 'notifications:create_emergency');
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH