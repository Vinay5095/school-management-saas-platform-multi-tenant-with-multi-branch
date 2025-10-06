# SPEC-164: Notification Center
## Centralized Notification Management and Delivery

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-151, SPEC-157, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Unified notification center for tenant administrators to manage, view, and respond to all system notifications, alerts, reminders, and announcements with real-time updates and notification preferences.

### Key Features
- ✅ Real-time notification feed
- ✅ Notification categorization
- ✅ Priority-based sorting
- ✅ Read/unread status tracking
- ✅ Notification actions (approve, dismiss, etc.)
- ✅ Custom notification preferences
- ✅ Notification history
- ✅ Bulk operations
- ✅ In-app notifications
- ✅ Desktop push notifications
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('system', 'alert', 'reminder', 'announcement', 'approval_request', 'task', 'message', 'event')),
  category TEXT NOT NULL CHECK (category IN ('general', 'financial', 'academic', 'hr', 'compliance', 'security', 'technical', 'other')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'normal',
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  link_url TEXT,
  link_text TEXT,
  action_type TEXT CHECK (action_type IN ('none', 'approve', 'reject', 'review', 'respond', 'custom')),
  action_url TEXT,
  action_data JSONB,
  is_read BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  related_entity_type TEXT,
  related_entity_id UUID,
  sender_id UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_tenant ON notifications(tenant_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_category ON notifications(category);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_archived ON notifications(is_archived);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_expires ON notifications(expires_at) WHERE expires_at IS NOT NULL;

-- Notification actions table
CREATE TABLE notification_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  action_label TEXT NOT NULL,
  action_url TEXT,
  action_method TEXT CHECK (action_method IN ('GET', 'POST', 'PUT', 'DELETE')) DEFAULT 'POST',
  action_payload JSONB,
  is_primary BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_actions_notification ON notification_actions(notification_id);

-- Notification history table
CREATE TABLE notification_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  performed_by UUID REFERENCES auth.users(id),
  details TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_history_notification ON notification_history(notification_id);
CREATE INDEX idx_notification_history_date ON notification_history(created_at DESC);

-- User notification preferences table
CREATE TABLE user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  category TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  delivery_channels TEXT[] DEFAULT ARRAY['in_app']::TEXT[], -- in_app, email, sms, push
  min_priority TEXT CHECK (min_priority IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'low',
  digest_enabled BOOLEAN DEFAULT false,
  digest_frequency TEXT CHECK (digest_frequency IN ('hourly', 'daily', 'weekly')),
  quiet_hours JSONB, -- {start: "22:00", end: "08:00"}
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, tenant_id, notification_type, category)
);

CREATE INDEX idx_user_notif_prefs_user ON user_notification_preferences(user_id);
CREATE INDEX idx_user_notif_prefs_tenant ON user_notification_preferences(tenant_id);

-- Notification templates table (for system notifications)
CREATE TABLE notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  template_key TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  category TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'normal',
  title_template TEXT NOT NULL,
  message_template TEXT NOT NULL,
  variables TEXT[] DEFAULT ARRAY[]::TEXT[],
  action_type TEXT,
  is_system_template BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, template_key)
);

CREATE INDEX idx_notif_templates_tenant ON notification_templates(tenant_id);
CREATE INDEX idx_notif_templates_key ON notification_templates(template_key);
CREATE INDEX idx_notif_templates_active ON notification_templates(is_active);

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
  p_tenant_id UUID,
  p_recipient_id UUID,
  p_notification_type TEXT,
  p_category TEXT,
  p_priority TEXT,
  p_title TEXT,
  p_message TEXT,
  p_link_url TEXT DEFAULT NULL,
  p_action_type TEXT DEFAULT 'none',
  p_sender_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
  v_user_prefs RECORD;
  v_should_send BOOLEAN := true;
BEGIN
  -- Check user preferences
  SELECT * INTO v_user_prefs
  FROM user_notification_preferences
  WHERE user_id = p_recipient_id
    AND tenant_id = p_tenant_id
    AND notification_type = p_notification_type
    AND category = p_category;

  IF FOUND THEN
    -- Check if enabled
    IF NOT v_user_prefs.is_enabled THEN
      v_should_send := false;
    END IF;

    -- Check priority threshold
    IF v_user_prefs.min_priority IS NOT NULL THEN
      IF (p_priority = 'low' AND v_user_prefs.min_priority IN ('normal', 'high', 'urgent')) OR
         (p_priority = 'normal' AND v_user_prefs.min_priority IN ('high', 'urgent')) OR
         (p_priority = 'high' AND v_user_prefs.min_priority = 'urgent') THEN
        v_should_send := false;
      END IF;
    END IF;

    -- Check quiet hours
    -- (Implementation would check current time against quiet_hours)
  END IF;

  IF NOT v_should_send THEN
    RETURN NULL;
  END IF;

  -- Create notification
  INSERT INTO notifications (
    tenant_id,
    recipient_id,
    notification_type,
    category,
    priority,
    title,
    message,
    link_url,
    action_type,
    sender_id,
    metadata
  ) VALUES (
    p_tenant_id,
    p_recipient_id,
    p_notification_type,
    p_category,
    p_priority,
    p_title,
    p_message,
    p_link_url,
    p_action_type,
    p_sender_id,
    p_metadata
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(
  p_notification_id UUID,
  p_user_id UUID
)
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET 
    is_read = true,
    read_at = NOW()
  WHERE id = p_notification_id
    AND recipient_id = p_user_id
    AND is_read = false;

  -- Log action
  INSERT INTO notification_history (
    notification_id,
    action,
    performed_by
  ) VALUES (
    p_notification_id,
    'read',
    p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(
  p_user_id UUID,
  p_tenant_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH updated AS (
    UPDATE notifications
    SET 
      is_read = true,
      read_at = NOW()
    WHERE recipient_id = p_user_id
      AND tenant_id = p_tenant_id
      AND is_read = false
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM updated;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread count
CREATE OR REPLACE FUNCTION get_unread_notification_count(
  p_user_id UUID,
  p_tenant_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM notifications
  WHERE recipient_id = p_user_id
    AND tenant_id = p_tenant_id
    AND is_read = false
    AND is_archived = false
    AND (expires_at IS NULL OR expires_at > NOW());

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired notifications
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM notifications
    WHERE expires_at IS NOT NULL
      AND expires_at < NOW()
      AND is_archived = false
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM deleted;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule cleanup
SELECT cron.schedule(
  'cleanup-expired-notifications',
  '0 2 * * *', -- Run at 2 AM daily
  'SELECT cleanup_expired_notifications()'
);

-- RLS Policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_view_own_notifications ON notifications
  FOR SELECT USING (
    recipient_id = auth.uid()
  );

CREATE POLICY users_update_own_notifications ON notifications
  FOR UPDATE USING (
    recipient_id = auth.uid()
  );

CREATE POLICY users_view_notification_actions ON notification_actions
  FOR SELECT USING (
    notification_id IN (
      SELECT id FROM notifications
      WHERE recipient_id = auth.uid()
    )
  );

CREATE POLICY users_view_notification_history ON notification_history
  FOR SELECT USING (
    notification_id IN (
      SELECT id FROM notifications
      WHERE recipient_id = auth.uid()
    )
  );

CREATE POLICY users_manage_own_prefs ON user_notification_preferences
  FOR ALL USING (
    user_id = auth.uid()
  );

CREATE POLICY tenant_admin_templates ON notification_templates
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
    OR is_system_template = true
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/notifications.ts

export interface Notification {
  id: string
  tenantId: string
  recipientId: string
  notificationType: 'system' | 'alert' | 'reminder' | 'announcement' | 'approval_request' | 'task' | 'message' | 'event'
  category: 'general' | 'financial' | 'academic' | 'hr' | 'compliance' | 'security' | 'technical' | 'other'
  priority: 'low' | 'normal' | 'high' | 'urgent'
  title: string
  message: string
  linkUrl?: string
  linkText?: string
  actionType?: 'none' | 'approve' | 'reject' | 'review' | 'respond' | 'custom'
  actionUrl?: string
  actionData?: Record<string, any>
  isRead: boolean
  isArchived: boolean
  readAt?: string
  archivedAt?: string
  expiresAt?: string
  relatedEntityType?: string
  relatedEntityId?: string
  senderId?: string
  metadata?: Record<string, any>
  createdAt: string
}

export interface NotificationAction {
  id: string
  notificationId: string
  actionType: string
  actionLabel: string
  actionUrl?: string
  actionMethod: 'GET' | 'POST' | 'PUT' | 'DELETE'
  actionPayload?: Record<string, any>
  isPrimary: boolean
  displayOrder: number
}

export interface UserNotificationPreference {
  id: string
  userId: string
  tenantId: string
  notificationType: string
  category: string
  isEnabled: boolean
  deliveryChannels: Array<'in_app' | 'email' | 'sms' | 'push'>
  minPriority: 'low' | 'normal' | 'high' | 'urgent'
  digestEnabled: boolean
  digestFrequency?: 'hourly' | 'daily' | 'weekly'
  quietHours?: {
    start: string
    end: string
  }
  createdAt: string
  updatedAt: string
}

export interface NotificationStats {
  total: number
  unread: number
  byPriority: {
    low: number
    normal: number
    high: number
    urgent: number
  }
  byCategory: {
    [key: string]: number
  }
}
```

### API Routes

```typescript
// src/app/api/notifications/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id')
    .eq('user_id', user.id)
    .single()

  const isRead = searchParams.get('is_read')
  const priority = searchParams.get('priority')
  const category = searchParams.get('category')
  const page = parseInt(searchParams.get('page') || '1')
  const limit = parseInt(searchParams.get('limit') || '20')
  const offset = (page - 1) * limit

  try {
    let query = supabase
      .from('notifications')
      .select(`
        *,
        sender:auth.users!sender_id (
          id,
          email,
          user_metadata
        ),
        actions:notification_actions (*)
      `, { count: 'exact' })
      .eq('recipient_id', user.id)
      .eq('is_archived', false)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    if (isRead !== null) {
      query = query.eq('is_read', isRead === 'true')
    }

    if (priority) {
      query = query.eq('priority', priority)
    }

    if (category) {
      query = query.eq('category', category)
    }

    const { data: notifications, error, count } = await query

    if (error) throw error

    // Get stats
    const { data: unreadCount } = await supabase.rpc(
      'get_unread_notification_count',
      {
        p_user_id: user.id,
        p_tenant_id: profile.tenant_id,
      }
    )

    return NextResponse.json({
      notifications,
      stats: {
        unread: unreadCount || 0,
      },
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    })

  } catch (error) {
    console.error('Failed to fetch notifications:', error)
    return NextResponse.json(
      { error: 'Failed to fetch notifications' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/notifications/[id]/read/route.ts

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { error } = await supabase.rpc('mark_notification_read', {
      p_notification_id: params.id,
      p_user_id: user.id,
    })

    if (error) throw error

    return NextResponse.json({ success: true })

  } catch (error) {
    console.error('Failed to mark as read:', error)
    return NextResponse.json(
      { error: 'Failed to mark as read' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/notifications/read-all/route.ts

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id')
    .eq('user_id', user.id)
    .single()

  try {
    const { data: count } = await supabase.rpc('mark_all_notifications_read', {
      p_user_id: user.id,
      p_tenant_id: profile.tenant_id,
    })

    return NextResponse.json({ count: count || 0 })

  } catch (error) {
    console.error('Failed to mark all as read:', error)
    return NextResponse.json(
      { error: 'Failed to mark all as read' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Notification Center

```typescript
// src/components/notifications/notification-center.tsx

'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ScrollArea } from '@/components/ui/scroll-area'
import { 
  Bell, Check, Archive, Filter, 
  AlertCircle, Info, AlertTriangle 
} from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { cn } from '@/lib/utils'

export function NotificationCenter() {
  const [filter, setFilter] = useState<'all' | 'unread'>('all')
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['notifications', filter],
    queryFn: async () => {
      const params = new URLSearchParams()
      if (filter === 'unread') {
        params.append('is_read', 'false')
      }
      const res = await fetch(`/api/notifications?${params}`)
      if (!res.ok) throw new Error('Failed to fetch notifications')
      return res.json()
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  })

  const markAsRead = useMutation({
    mutationFn: async (notificationId: string) => {
      const res = await fetch(`/api/notifications/${notificationId}/read`, {
        method: 'POST',
      })
      if (!res.ok) throw new Error('Failed to mark as read')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
    },
  })

  const markAllAsRead = useMutation({
    mutationFn: async () => {
      const res = await fetch('/api/notifications/read-all', {
        method: 'POST',
      })
      if (!res.ok) throw new Error('Failed to mark all as read')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
    },
  })

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return <AlertCircle className="h-5 w-5 text-red-500" />
      case 'high':
        return <AlertTriangle className="h-5 w-5 text-orange-500" />
      default:
        return <Info className="h-5 w-5 text-blue-500" />
    }
  }

  return (
    <div className="w-96 border rounded-lg shadow-lg bg-background">
      <div className="p-4 border-b">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Bell className="h-5 w-5" />
            <h3 className="font-semibold">Notifications</h3>
            {data?.stats?.unread > 0 && (
              <Badge variant="destructive" className="rounded-full">
                {data.stats.unread}
              </Badge>
            )}
          </div>
          {data?.stats?.unread > 0 && (
            <Button
              size="sm"
              variant="ghost"
              onClick={() => markAllAsRead.mutate()}
            >
              <Check className="h-4 w-4 mr-1" />
              Mark all read
            </Button>
          )}
        </div>

        <div className="flex gap-2">
          <Button
            size="sm"
            variant={filter === 'all' ? 'default' : 'outline'}
            onClick={() => setFilter('all')}
          >
            All
          </Button>
          <Button
            size="sm"
            variant={filter === 'unread' ? 'default' : 'outline'}
            onClick={() => setFilter('unread')}
          >
            Unread
          </Button>
        </div>
      </div>

      <ScrollArea className="h-[500px]">
        {isLoading ? (
          <div className="p-4 text-center text-muted-foreground">
            Loading...
          </div>
        ) : data?.notifications?.length === 0 ? (
          <div className="p-4 text-center text-muted-foreground">
            No notifications
          </div>
        ) : (
          <div className="divide-y">
            {data?.notifications?.map((notification: any) => (
              <div
                key={notification.id}
                className={cn(
                  'p-4 hover:bg-muted/50 cursor-pointer transition-colors',
                  !notification.is_read && 'bg-muted/30'
                )}
                onClick={() => {
                  if (!notification.is_read) {
                    markAsRead.mutate(notification.id)
                  }
                  if (notification.link_url) {
                    window.location.href = notification.link_url
                  }
                }}
              >
                <div className="flex gap-3">
                  {getPriorityIcon(notification.priority)}
                  <div className="flex-1 space-y-1">
                    <div className="flex items-start justify-between">
                      <p className="font-medium text-sm">
                        {notification.title}
                      </p>
                      {!notification.is_read && (
                        <div className="h-2 w-2 rounded-full bg-blue-500 mt-1" />
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {notification.message}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {formatDistanceToNow(new Date(notification.created_at), {
                        addSuffix: true,
                      })}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </ScrollArea>
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Real-time notification feed
- [x] Notification categorization
- [x] Priority-based display
- [x] Read/unread tracking
- [x] Notification actions
- [x] User preferences
- [x] Notification history
- [x] Bulk operations
- [x] Desktop notifications
- [x] Expired notification cleanup
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
