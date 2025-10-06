# SPEC-379: Call Log Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-379  
**Title**: Call Log Management System  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: Front Desk Portal  
**Category**: Operations & Management  
**Priority**: HIGH  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-376 (Front Desk Dashboard), SPEC-011 (Multi-tenant), SPEC-013 (Auth)

---

## 📋 DESCRIPTION

Efficient call log management system for tracking incoming and outgoing calls, recording messages, managing callbacks, and maintaining comprehensive call history with search and filter capabilities. The system enables front desk staff to log all communication, track follow-ups, use message templates, and maintain detailed call records for audit and analysis.

---

## 🎯 SUCCESS CRITERIA

- [ ] Log incoming calls with caller details functional
- [ ] Log outgoing calls functional
- [ ] Message recording with templates functional
- [ ] Callback tracking and reminders functional
- [ ] Call history with search/filter functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
-- Call Logs Table
CREATE TABLE IF NOT EXISTS call_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Call Details
  call_type VARCHAR(20) NOT NULL CHECK (call_type IN ('incoming', 'outgoing')),
  caller_name VARCHAR(255),
  caller_phone VARCHAR(20) NOT NULL,
  caller_email VARCHAR(255),
  call_purpose VARCHAR(100),
  call_category VARCHAR(100),
  
  -- Call Information
  called_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  duration_minutes INTEGER DEFAULT 0,
  call_status VARCHAR(20) DEFAULT 'completed' CHECK (call_status IN ('completed', 'missed', 'rejected', 'voicemail')),
  
  -- Message Details
  message_taken BOOLEAN DEFAULT false,
  message_text TEXT,
  message_urgency VARCHAR(20) DEFAULT 'normal' CHECK (message_urgency IN ('low', 'normal', 'high', 'urgent')),
  
  -- Follow-up
  requires_callback BOOLEAN DEFAULT false,
  callback_scheduled_at TIMESTAMP WITH TIME ZONE,
  callback_completed_at TIMESTAMP WITH TIME ZONE,
  callback_notes TEXT,
  
  -- Assignment
  transferred_to UUID REFERENCES auth.users(id),
  transferred_department VARCHAR(100),
  handled_by UUID REFERENCES auth.users(id),
  
  -- Metadata
  notes TEXT,
  tags TEXT[],
  metadata JSONB DEFAULT '{}',
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Call Messages Table
CREATE TABLE IF NOT EXISTS call_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  call_log_id UUID REFERENCES call_logs(id) ON DELETE CASCADE,
  
  -- Message Details
  recipient_name VARCHAR(255) NOT NULL,
  recipient_id UUID REFERENCES auth.users(id),
  message_text TEXT NOT NULL,
  urgency VARCHAR(20) DEFAULT 'normal',
  
  -- Delivery
  delivered_at TIMESTAMP WITH TIME ZONE,
  delivered_by UUID REFERENCES auth.users(id),
  delivery_method VARCHAR(50) CHECK (delivery_method IN ('in_person', 'email', 'sms', 'internal_note')),
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'read', 'acknowledged')),
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Callback Reminders Table
CREATE TABLE IF NOT EXISTS callback_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  call_log_id UUID REFERENCES call_logs(id) ON DELETE CASCADE,
  
  -- Reminder Details
  reminder_for UUID REFERENCES auth.users(id),
  reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
  reminder_note TEXT,
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'completed', 'cancelled')),
  completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Notifications
  notification_sent_at TIMESTAMP WITH TIME ZONE,
  notification_method VARCHAR(50),
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Call Message Templates Table
CREATE TABLE IF NOT EXISTS call_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Template Details
  template_name VARCHAR(255) NOT NULL,
  template_category VARCHAR(100),
  template_text TEXT NOT NULL,
  variables TEXT[], -- e.g., ['caller_name', 'phone', 'time']
  
  -- Usage
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_call_logs_tenant_branch ON call_logs(tenant_id, branch_id);
CREATE INDEX idx_call_logs_caller_phone ON call_logs(caller_phone);
CREATE INDEX idx_call_logs_called_at ON call_logs(called_at DESC);
CREATE INDEX idx_call_logs_status ON call_logs(call_status);
CREATE INDEX idx_call_logs_callback ON call_logs(requires_callback, callback_scheduled_at);
CREATE INDEX idx_call_logs_type ON call_logs(call_type);

CREATE INDEX idx_call_messages_tenant_branch ON call_messages(tenant_id, branch_id);
CREATE INDEX idx_call_messages_call_log ON call_messages(call_log_id);
CREATE INDEX idx_call_messages_recipient ON call_messages(recipient_id);
CREATE INDEX idx_call_messages_status ON call_messages(status);

CREATE INDEX idx_callback_reminders_tenant_branch ON callback_reminders(tenant_id, branch_id);
CREATE INDEX idx_callback_reminders_call_log ON callback_reminders(call_log_id);
CREATE INDEX idx_callback_reminders_user ON callback_reminders(reminder_for);
CREATE INDEX idx_callback_reminders_date ON callback_reminders(reminder_date);
CREATE INDEX idx_callback_reminders_status ON callback_reminders(status);

CREATE INDEX idx_call_templates_tenant_branch ON call_templates(tenant_id, branch_id);
CREATE INDEX idx_call_templates_active ON call_templates(is_active);

-- Enable RLS
ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE callback_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY call_logs_isolation ON call_logs
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY call_messages_isolation ON call_messages
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY callback_reminders_isolation ON callback_reminders
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY call_templates_isolation ON call_templates
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-379-call-log.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface CallLog {
  id: string;
  tenantId: string;
  branchId: string;
  callType: 'incoming' | 'outgoing';
  callerName: string;
  callerPhone: string;
  callerEmail?: string;
  callPurpose?: string;
  callCategory?: string;
  calledAt: string;
  durationMinutes: number;
  callStatus: 'completed' | 'missed' | 'rejected' | 'voicemail';
  messageTaken: boolean;
  messageText?: string;
  messageUrgency: 'low' | 'normal' | 'high' | 'urgent';
  requiresCallback: boolean;
  callbackScheduledAt?: string;
  callbackCompletedAt?: string;
  callbackNotes?: string;
  transferredTo?: string;
  transferredDepartment?: string;
  handledBy?: string;
  notes?: string;
  tags?: string[];
  metadata?: Record<string, any>;
  createdAt: string;
  updatedAt: string;
}

export interface CallMessage {
  id: string;
  callLogId: string;
  recipientName: string;
  recipientId?: string;
  messageText: string;
  urgency: string;
  status: 'pending' | 'delivered' | 'read' | 'acknowledged';
  deliveryMethod?: string;
  createdAt: string;
}

export interface CallbackReminder {
  id: string;
  callLogId: string;
  reminderFor: string;
  reminderDate: string;
  reminderNote?: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  status: 'pending' | 'sent' | 'completed' | 'cancelled';
  createdAt: string;
}

export interface CallTemplate {
  id: string;
  templateName: string;
  templateCategory?: string;
  templateText: string;
  variables?: string[];
  isActive: boolean;
  usageCount: number;
}

export class CallLogAPI {
  private supabase = createClient();

  // Call Logs
  async getCallLogs(
    filters?: {
      callType?: string;
      status?: string;
      startDate?: string;
      endDate?: string;
      search?: string;
    },
    page: number = 1,
    limit: number = 20
  ): Promise<{ data: CallLog[]; total: number }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    let query = this.supabase
      .from('call_logs')
      .select('*', { count: 'exact' })
      .order('called_at', { ascending: false });

    if (filters?.callType) {
      query = query.eq('call_type', filters.callType);
    }
    if (filters?.status) {
      query = query.eq('call_status', filters.status);
    }
    if (filters?.startDate) {
      query = query.gte('called_at', filters.startDate);
    }
    if (filters?.endDate) {
      query = query.lte('called_at', filters.endDate);
    }
    if (filters?.search) {
      query = query.or(`caller_name.ilike.%${filters.search}%,caller_phone.ilike.%${filters.search}%`);
    }

    query = query.range(start, end);

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      data: data as CallLog[],
      total: count || 0
    };
  }

  async getCallLogById(id: string): Promise<CallLog> {
    const { data, error } = await this.supabase
      .from('call_logs')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data as CallLog;
  }

  async createCallLog(callData: Partial<CallLog>): Promise<CallLog> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('call_logs')
      .insert({
        ...callData,
        handled_by: user.id,
        created_by: user.id,
        updated_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return data as CallLog;
  }

  async updateCallLog(id: string, updates: Partial<CallLog>): Promise<CallLog> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('call_logs')
      .update({
        ...updates,
        updated_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data as CallLog;
  }

  async completeCallback(id: string, notes: string): Promise<CallLog> {
    return this.updateCallLog(id, {
      callbackCompletedAt: new Date().toISOString(),
      callbackNotes: notes
    } as Partial<CallLog>);
  }

  // Messages
  async getCallMessages(callLogId: string): Promise<CallMessage[]> {
    const { data, error } = await this.supabase
      .from('call_messages')
      .select('*')
      .eq('call_log_id', callLogId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as CallMessage[];
  }

  async createMessage(messageData: Partial<CallMessage>): Promise<CallMessage> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('call_messages')
      .insert({
        ...messageData,
        created_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return data as CallMessage;
  }

  async markMessageDelivered(
    messageId: string,
    deliveryMethod: string
  ): Promise<CallMessage> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('call_messages')
      .update({
        status: 'delivered',
        delivered_at: new Date().toISOString(),
        delivered_by: user.id,
        delivery_method: deliveryMethod
      })
      .eq('id', messageId)
      .select()
      .single();

    if (error) throw error;
    return data as CallMessage;
  }

  // Callbacks
  async getCallbackReminders(
    filters?: {
      status?: string;
      userId?: string;
      upcoming?: boolean;
    }
  ): Promise<CallbackReminder[]> {
    let query = this.supabase
      .from('callback_reminders')
      .select('*, call_logs(*)')
      .order('reminder_date', { ascending: true });

    if (filters?.status) {
      query = query.eq('status', filters.status);
    }
    if (filters?.userId) {
      query = query.eq('reminder_for', filters.userId);
    }
    if (filters?.upcoming) {
      query = query.gte('reminder_date', new Date().toISOString());
    }

    const { data, error } = await query;

    if (error) throw error;
    return data as CallbackReminder[];
  }

  async createCallbackReminder(
    reminderData: Partial<CallbackReminder>
  ): Promise<CallbackReminder> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('callback_reminders')
      .insert({
        ...reminderData,
        created_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return data as CallbackReminder;
  }

  async completeCallbackReminder(id: string): Promise<CallbackReminder> {
    const { data, error } = await this.supabase
      .from('callback_reminders')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data as CallbackReminder;
  }

  // Templates
  async getTemplates(category?: string): Promise<CallTemplate[]> {
    let query = this.supabase
      .from('call_templates')
      .select('*')
      .eq('is_active', true)
      .order('usage_count', { ascending: false });

    if (category) {
      query = query.eq('template_category', category);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data as CallTemplate[];
  }

  async useTemplate(templateId: string, variables: Record<string, string>): Promise<string> {
    const { data, error } = await this.supabase
      .from('call_templates')
      .select('template_text, variables')
      .eq('id', templateId)
      .single();

    if (error) throw error;

    // Increment usage count
    await this.supabase
      .from('call_templates')
      .update({ usage_count: (data as any).usage_count + 1 })
      .eq('id', templateId);

    let text = data.template_text;
    if (data.variables) {
      data.variables.forEach((variable: string) => {
        if (variables[variable]) {
          text = text.replace(`{${variable}}`, variables[variable]);
        }
      });
    }

    return text;
  }

  // Analytics
  async getCallStatistics(startDate: string, endDate: string): Promise<{
    totalCalls: number;
    incomingCalls: number;
    outgoingCalls: number;
    missedCalls: number;
    avgDuration: number;
    callsByCategory: Record<string, number>;
    callbacksPending: number;
  }> {
    const { data: calls, error } = await this.supabase
      .from('call_logs')
      .select('*')
      .gte('called_at', startDate)
      .lte('called_at', endDate);

    if (error) throw error;

    const stats = {
      totalCalls: calls.length,
      incomingCalls: calls.filter(c => c.call_type === 'incoming').length,
      outgoingCalls: calls.filter(c => c.call_type === 'outgoing').length,
      missedCalls: calls.filter(c => c.call_status === 'missed').length,
      avgDuration: calls.reduce((sum, c) => sum + (c.duration_minutes || 0), 0) / calls.length || 0,
      callsByCategory: {} as Record<string, number>,
      callbacksPending: calls.filter(c => c.requires_callback && !c.callback_completed_at).length
    };

    calls.forEach(call => {
      if (call.call_category) {
        stats.callsByCategory[call.call_category] = 
          (stats.callsByCategory[call.call_category] || 0) + 1;
      }
    });

    return stats;
  }
}

export const callLogAPI = new CallLogAPI();
```

### React Component (`/components/front-desk/CallLogManagement.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { useToast } from '@/components/ui/use-toast';
import { 
  Phone, 
  PhoneIncoming, 
  PhoneOutgoing,
  PhoneMissed,
  Search, 
  Plus,
  Calendar,
  Bell,
  MessageSquare,
  Clock,
  Filter,
  FileText
} from 'lucide-react';
import { callLogAPI, type CallLog, type CallbackReminder, type CallTemplate } from '@/lib/api/spec-379-call-log';
import { format } from 'date-fns';

export function CallLogManagement() {
  const [calls, setCalls] = useState<CallLog[]>([]);
  const [callbacks, setCallbacks] = useState<CallbackReminder[]>([]);
  const [templates, setTemplates] = useState<CallTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [showAddDialog, setShowAddDialog] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    loadData();
    loadCallbacks();
    loadTemplates();
  }, [filterType, filterStatus, searchQuery]);

  const loadData = async () => {
    try {
      setLoading(true);
      const filters: any = {};
      if (filterType !== 'all') filters.callType = filterType;
      if (filterStatus !== 'all') filters.status = filterStatus;
      if (searchQuery) filters.search = searchQuery;

      const result = await callLogAPI.getCallLogs(filters);
      setCalls(result.data);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const loadCallbacks = async () => {
    try {
      const data = await callLogAPI.getCallbackReminders({ status: 'pending', upcoming: true });
      setCallbacks(data);
    } catch (error: any) {
      console.error('Error loading callbacks:', error);
    }
  };

  const loadTemplates = async () => {
    try {
      const data = await callLogAPI.getTemplates();
      setTemplates(data);
    } catch (error: any) {
      console.error('Error loading templates:', error);
    }
  };

  const handleCreateCall = async (callData: Partial<CallLog>) => {
    try {
      await callLogAPI.createCallLog(callData);
      toast({
        title: 'Success',
        description: 'Call log created successfully'
      });
      setShowAddDialog(false);
      loadData();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive'
      });
    }
  };

  const getStatusIcon = (call: CallLog) => {
    if (call.callType === 'incoming') {
      return call.callStatus === 'missed' ? (
        <PhoneMissed className="h-4 w-4 text-red-500" />
      ) : (
        <PhoneIncoming className="h-4 w-4 text-green-500" />
      );
    }
    return <PhoneOutgoing className="h-4 w-4 text-blue-500" />;
  };

  const getStatusBadge = (status: string) => {
    const variants: Record<string, any> = {
      completed: 'default',
      missed: 'destructive',
      rejected: 'secondary',
      voicemail: 'outline'
    };
    return (
      <Badge variant={variants[status] || 'default'}>
        {status}
      </Badge>
    );
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Call Log Management</h1>
          <p className="text-muted-foreground">Track and manage all calls</p>
        </div>
        <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Log Call
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Log New Call</DialogTitle>
            </DialogHeader>
            <CallLogForm onSubmit={handleCreateCall} templates={templates} />
          </DialogContent>
        </Dialog>
      </div>

      {/* Callback Reminders Card */}
      {callbacks.length > 0 && (
        <Card className="border-orange-200 bg-orange-50">
          <CardHeader>
            <CardTitle className="flex items-center text-orange-800">
              <Bell className="h-5 w-5 mr-2" />
              Pending Callbacks ({callbacks.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {callbacks.slice(0, 3).map((callback: any) => (
                <div key={callback.id} className="flex items-center justify-between p-3 bg-white rounded-lg">
                  <div>
                    <p className="font-medium">{callback.call_logs?.caller_name}</p>
                    <p className="text-sm text-muted-foreground">
                      {format(new Date(callback.reminder_date), 'PPp')}
                    </p>
                  </div>
                  <Button 
                    size="sm"
                    onClick={() => {
                      callLogAPI.completeCallbackReminder(callback.id);
                      loadCallbacks();
                    }}
                  >
                    Complete
                  </Button>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search by name or phone..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <Select value={filterType} onValueChange={setFilterType}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Call Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Types</SelectItem>
                <SelectItem value="incoming">Incoming</SelectItem>
                <SelectItem value="outgoing">Outgoing</SelectItem>
              </SelectContent>
            </Select>
            <Select value={filterStatus} onValueChange={setFilterStatus}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="completed">Completed</SelectItem>
                <SelectItem value="missed">Missed</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
                <SelectItem value="voicemail">Voicemail</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8">Loading...</div>
          ) : calls.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No call logs found
            </div>
          ) : (
            <div className="space-y-3">
              {calls.map((call) => (
                <div 
                  key={call.id} 
                  className="flex items-start gap-4 p-4 border rounded-lg hover:bg-accent/50 transition-colors"
                >
                  <div className="mt-1">{getStatusIcon(call)}</div>
                  
                  <div className="flex-1 space-y-1">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-medium">{call.callerName || 'Unknown Caller'}</p>
                        <p className="text-sm text-muted-foreground">{call.callerPhone}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-muted-foreground">
                          {format(new Date(call.calledAt), 'PPp')}
                        </p>
                        {call.durationMinutes > 0 && (
                          <p className="text-sm text-muted-foreground flex items-center justify-end gap-1">
                            <Clock className="h-3 w-3" />
                            {call.durationMinutes} min
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-2 flex-wrap">
                      {getStatusBadge(call.callStatus)}
                      {call.callPurpose && (
                        <Badge variant="outline">{call.callPurpose}</Badge>
                      )}
                      {call.messageTaken && (
                        <Badge variant="secondary" className="flex items-center gap-1">
                          <MessageSquare className="h-3 w-3" />
                          Message
                        </Badge>
                      )}
                      {call.requiresCallback && !call.callbackCompletedAt && (
                        <Badge variant="warning" className="flex items-center gap-1">
                          <Bell className="h-3 w-3" />
                          Callback Required
                        </Badge>
                      )}
                    </div>

                    {call.messageText && (
                      <p className="text-sm bg-accent/30 p-2 rounded">
                        {call.messageText}
                      </p>
                    )}

                    {call.notes && (
                      <p className="text-sm text-muted-foreground">{call.notes}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function CallLogForm({ 
  onSubmit, 
  templates 
}: { 
  onSubmit: (data: Partial<CallLog>) => void;
  templates: CallTemplate[];
}) {
  const [formData, setFormData] = useState<Partial<CallLog>>({
    callType: 'incoming',
    callStatus: 'completed',
    messageTaken: false,
    requiresCallback: false
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>Call Type *</Label>
          <Select 
            value={formData.callType} 
            onValueChange={(value) => setFormData({ ...formData, callType: value as any })}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="incoming">Incoming</SelectItem>
              <SelectItem value="outgoing">Outgoing</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label>Status *</Label>
          <Select 
            value={formData.callStatus} 
            onValueChange={(value) => setFormData({ ...formData, callStatus: value as any })}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="completed">Completed</SelectItem>
              <SelectItem value="missed">Missed</SelectItem>
              <SelectItem value="rejected">Rejected</SelectItem>
              <SelectItem value="voicemail">Voicemail</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>Caller Name *</Label>
          <Input
            value={formData.callerName || ''}
            onChange={(e) => setFormData({ ...formData, callerName: e.target.value })}
            required
          />
        </div>

        <div className="space-y-2">
          <Label>Phone Number *</Label>
          <Input
            value={formData.callerPhone || ''}
            onChange={(e) => setFormData({ ...formData, callerPhone: e.target.value })}
            required
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>Call Purpose</Label>
          <Input
            value={formData.callPurpose || ''}
            onChange={(e) => setFormData({ ...formData, callPurpose: e.target.value })}
          />
        </div>

        <div className="space-y-2">
          <Label>Duration (minutes)</Label>
          <Input
            type="number"
            value={formData.durationMinutes || 0}
            onChange={(e) => setFormData({ ...formData, durationMinutes: parseInt(e.target.value) })}
          />
        </div>
      </div>

      <div className="space-y-2">
        <Label>Message</Label>
        <Textarea
          value={formData.messageText || ''}
          onChange={(e) => setFormData({ ...formData, messageText: e.target.value })}
          rows={3}
        />
      </div>

      <div className="space-y-2">
        <Label>Notes</Label>
        <Textarea
          value={formData.notes || ''}
          onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          rows={2}
        />
      </div>

      <div className="flex items-center gap-4">
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={formData.requiresCallback}
            onChange={(e) => setFormData({ ...formData, requiresCallback: e.target.checked })}
          />
          <span className="text-sm">Requires Callback</span>
        </label>
      </div>

      <Button type="submit" className="w-full">
        Log Call
      </Button>
    </form>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/spec-379-call-log.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { callLogAPI } from '@/lib/api/spec-379-call-log';

describe('SPEC-379: Call Log Management API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Call Logs', () => {
    it('should fetch call logs with filters', async () => {
      const result = await callLogAPI.getCallLogs({ callType: 'incoming' });
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
      expect(Array.isArray(result.data)).toBe(true);
    });

    it('should create new call log', async () => {
      const callData = {
        callType: 'incoming',
        callerName: 'John Doe',
        callerPhone: '+1234567890',
        callStatus: 'completed',
        durationMinutes: 5
      };
      const created = await callLogAPI.createCallLog(callData as any);
      expect(created).toHaveProperty('id');
      expect(created.callerName).toBe('John Doe');
    });

    it('should update call log', async () => {
      const updated = await callLogAPI.updateCallLog('test-id', {
        notes: 'Updated notes'
      } as any);
      expect(updated.notes).toBe('Updated notes');
    });

    it('should complete callback', async () => {
      const completed = await callLogAPI.completeCallback('test-id', 'Callback completed');
      expect(completed.callbackCompletedAt).toBeDefined();
      expect(completed.callbackNotes).toBe('Callback completed');
    });
  });

  describe('Messages', () => {
    it('should fetch messages for call log', async () => {
      const messages = await callLogAPI.getCallMessages('call-log-id');
      expect(Array.isArray(messages)).toBe(true);
    });

    it('should create new message', async () => {
      const messageData = {
        callLogId: 'test-call-id',
        recipientName: 'Jane Doe',
        messageText: 'Please call back',
        urgency: 'normal'
      };
      const created = await callLogAPI.createMessage(messageData as any);
      expect(created).toHaveProperty('id');
    });

    it('should mark message as delivered', async () => {
      const delivered = await callLogAPI.markMessageDelivered('message-id', 'in_person');
      expect(delivered.status).toBe('delivered');
      expect(delivered.deliveryMethod).toBe('in_person');
    });
  });

  describe('Callbacks', () => {
    it('should fetch callback reminders', async () => {
      const reminders = await callLogAPI.getCallbackReminders({ status: 'pending' });
      expect(Array.isArray(reminders)).toBe(true);
    });

    it('should create callback reminder', async () => {
      const reminderData = {
        callLogId: 'test-call-id',
        reminderFor: 'user-id',
        reminderDate: new Date().toISOString(),
        priority: 'high'
      };
      const created = await callLogAPI.createCallbackReminder(reminderData as any);
      expect(created).toHaveProperty('id');
    });

    it('should complete callback reminder', async () => {
      const completed = await callLogAPI.completeCallbackReminder('reminder-id');
      expect(completed.status).toBe('completed');
      expect(completed.completedAt).toBeDefined();
    });
  });

  describe('Templates', () => {
    it('should fetch templates', async () => {
      const templates = await callLogAPI.getTemplates();
      expect(Array.isArray(templates)).toBe(true);
    });

    it('should use template with variables', async () => {
      const text = await callLogAPI.useTemplate('template-id', {
        caller_name: 'John',
        phone: '1234567890'
      });
      expect(typeof text).toBe('string');
    });
  });

  describe('Analytics', () => {
    it('should fetch call statistics', async () => {
      const stats = await callLogAPI.getCallStatistics(
        '2024-01-01',
        '2024-01-31'
      );
      expect(stats).toHaveProperty('totalCalls');
      expect(stats).toHaveProperty('incomingCalls');
      expect(stats).toHaveProperty('outgoingCalls');
      expect(stats).toHaveProperty('missedCalls');
      expect(stats).toHaveProperty('avgDuration');
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { CallLogManagement } from '@/components/front-desk/CallLogManagement';

export default function CallLogPage() {
  return (
    <div className="container mx-auto">
      <CallLogManagement />
    </div>
  );
}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all tables
- Tenant and branch isolation via session variables
- User authentication required for all operations
- Activity logging for audit trail
- Input validation on all operations
- Sensitive data encryption at rest

---

## 📊 PERFORMANCE

- **Page Load**: < 2 seconds
- **Search**: < 500ms with indexing
- **Create/Update**: < 1 second
- **Database Queries**: Optimized with proper indexes
- **Pagination**: Server-side for large datasets
- **Real-time Updates**: Optional WebSocket support

---

## ✅ DEFINITION OF DONE

- [ ] All database tables, indexes, and RLS policies created
- [ ] API client fully implemented with TypeScript types
- [ ] React component with full CRUD operations
- [ ] Search, filter, and callback tracking functional
- [ ] Message templates system working
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete
- [ ] Integration with front desk dashboard
- [ ] Notification system for callbacks operational
