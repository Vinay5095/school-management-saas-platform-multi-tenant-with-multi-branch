# SPEC-157: Communication Hub
## Multi-Channel Communication and Messaging System

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6-7 hours  
> **Dependencies**: SPEC-151, SPEC-152, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Centralized communication hub for tenant administrators to send announcements, notifications, and messages across all branches, specific branches, or targeted user groups.

### Key Features
- ✅ Multi-channel messaging (email, SMS, in-app)
- ✅ Broadcast announcements to all branches
- ✅ Targeted messaging by branch/role/user group
- ✅ Message templates
- ✅ Scheduled messages
- ✅ Message history and tracking
- ✅ Delivery status monitoring
- ✅ Emergency alerts
- ✅ Rich text editor
- ✅ Attachment support
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Communication messages table
CREATE TABLE communication_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT NOT NULL CHECK (message_type IN ('announcement', 'notification', 'alert', 'reminder')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'normal',
  channels TEXT[] NOT NULL DEFAULT ARRAY['in_app'], -- email, sms, in_app, push
  status TEXT NOT NULL CHECK (status IN ('draft', 'scheduled', 'sent', 'failed', 'cancelled')) DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  target_type TEXT NOT NULL CHECK (target_type IN ('all', 'branches', 'roles', 'users', 'custom')),
  target_branches UUID[] DEFAULT ARRAY[]::UUID[],
  target_roles TEXT[] DEFAULT ARRAY[]::TEXT[],
  target_users UUID[] DEFAULT ARRAY[]::UUID[],
  custom_filter JSONB,
  template_id UUID REFERENCES message_templates(id),
  attachments JSONB DEFAULT '[]'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_comm_messages_tenant ON communication_messages(tenant_id);
CREATE INDEX idx_comm_messages_status ON communication_messages(status);
CREATE INDEX idx_comm_messages_scheduled ON communication_messages(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_comm_messages_type ON communication_messages(message_type);

-- Message templates table
CREATE TABLE message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('announcement', 'academic', 'financial', 'event', 'emergency', 'other')),
  title_template TEXT NOT NULL,
  content_template TEXT NOT NULL,
  variables TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['student_name', 'branch_name']
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, name)
);

CREATE INDEX idx_message_templates_tenant ON message_templates(tenant_id);
CREATE INDEX idx_message_templates_category ON message_templates(category);
CREATE INDEX idx_message_templates_active ON message_templates(is_active);

-- Message recipients table
CREATE TABLE message_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES communication_messages(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES auth.users(id),
  recipient_type TEXT NOT NULL CHECK (recipient_type IN ('student', 'parent', 'staff', 'admin')),
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed', 'read')) DEFAULT 'pending',
  channels_sent TEXT[] DEFAULT ARRAY[]::TEXT[],
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, recipient_id)
);

CREATE INDEX idx_message_recipients_message ON message_recipients(message_id);
CREATE INDEX idx_message_recipients_recipient ON message_recipients(recipient_id);
CREATE INDEX idx_message_recipients_status ON message_recipients(delivery_status);

-- Message analytics table
CREATE TABLE message_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES communication_messages(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  total_recipients INTEGER NOT NULL DEFAULT 0,
  sent_count INTEGER NOT NULL DEFAULT 0,
  delivered_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  read_count INTEGER NOT NULL DEFAULT 0,
  email_sent INTEGER NOT NULL DEFAULT 0,
  sms_sent INTEGER NOT NULL DEFAULT 0,
  in_app_sent INTEGER NOT NULL DEFAULT 0,
  push_sent INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id)
);

CREATE INDEX idx_message_analytics_tenant ON message_analytics(tenant_id);
CREATE INDEX idx_message_analytics_message ON message_analytics(message_id);

-- Function to send message to recipients
CREATE OR REPLACE FUNCTION send_communication_message(
  p_message_id UUID
)
RETURNS void AS $$
DECLARE
  v_message communication_messages;
  v_recipient_ids UUID[];
BEGIN
  -- Get message details
  SELECT * INTO v_message
  FROM communication_messages
  WHERE id = p_message_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Message not found';
  END IF;

  -- Build recipient list based on target type
  CASE v_message.target_type
    WHEN 'all' THEN
      SELECT ARRAY_AGG(user_id) INTO v_recipient_ids
      FROM user_profiles
      WHERE tenant_id = v_message.tenant_id
        AND deleted_at IS NULL;
    
    WHEN 'branches' THEN
      SELECT ARRAY_AGG(user_id) INTO v_recipient_ids
      FROM user_profiles
      WHERE tenant_id = v_message.tenant_id
        AND branch_id = ANY(v_message.target_branches)
        AND deleted_at IS NULL;
    
    WHEN 'roles' THEN
      SELECT ARRAY_AGG(user_id) INTO v_recipient_ids
      FROM user_profiles
      WHERE tenant_id = v_message.tenant_id
        AND role = ANY(v_message.target_roles)
        AND deleted_at IS NULL;
    
    WHEN 'users' THEN
      v_recipient_ids := v_message.target_users;
    
    WHEN 'custom' THEN
      -- Apply custom filter from JSONB
      -- This would require more complex logic based on filter structure
      NULL;
  END CASE;

  -- Insert recipients
  INSERT INTO message_recipients (
    message_id,
    recipient_id,
    recipient_type,
    delivery_status
  )
  SELECT 
    p_message_id,
    uid,
    COALESCE(up.role, 'staff')::TEXT,
    'pending'
  FROM UNNEST(v_recipient_ids) AS uid
  LEFT JOIN user_profiles up ON up.user_id = uid
  ON CONFLICT (message_id, recipient_id) DO NOTHING;

  -- Update message status
  UPDATE communication_messages
  SET 
    status = 'sent',
    sent_at = NOW(),
    updated_at = NOW()
  WHERE id = p_message_id;

  -- Initialize analytics
  INSERT INTO message_analytics (
    message_id,
    tenant_id,
    total_recipients
  )
  VALUES (
    p_message_id,
    v_message.tenant_id,
    COALESCE(array_length(v_recipient_ids, 1), 0)
  )
  ON CONFLICT (message_id) DO UPDATE SET
    total_recipients = EXCLUDED.total_recipients;

  -- Trigger actual sending via external service (email/SMS/push)
  -- This would be handled by background jobs
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update message analytics
CREATE OR REPLACE FUNCTION update_message_analytics(
  p_message_id UUID
)
RETURNS void AS $$
BEGIN
  INSERT INTO message_analytics (
    message_id,
    tenant_id,
    total_recipients,
    sent_count,
    delivered_count,
    failed_count,
    read_count
  )
  SELECT
    mr.message_id,
    cm.tenant_id,
    COUNT(*),
    COUNT(*) FILTER (WHERE mr.delivery_status IN ('sent', 'delivered', 'read')),
    COUNT(*) FILTER (WHERE mr.delivery_status IN ('delivered', 'read')),
    COUNT(*) FILTER (WHERE mr.delivery_status = 'failed'),
    COUNT(*) FILTER (WHERE mr.delivery_status = 'read')
  FROM message_recipients mr
  JOIN communication_messages cm ON cm.id = mr.message_id
  WHERE mr.message_id = p_message_id
  GROUP BY mr.message_id, cm.tenant_id
  ON CONFLICT (message_id) DO UPDATE SET
    sent_count = EXCLUDED.sent_count,
    delivered_count = EXCLUDED.delivered_count,
    failed_count = EXCLUDED.failed_count,
    read_count = EXCLUDED.read_count,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update analytics on recipient status change
CREATE OR REPLACE FUNCTION trigger_update_message_analytics()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_message_analytics(NEW.message_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_analytics_on_recipient_change
AFTER INSERT OR UPDATE ON message_recipients
FOR EACH ROW
EXECUTE FUNCTION trigger_update_message_analytics();

-- RLS Policies
ALTER TABLE communication_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_admin_comm_messages ON communication_messages
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_templates ON message_templates
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY users_view_their_messages ON message_recipients
  FOR SELECT USING (
    recipient_id = auth.uid()
  );

CREATE POLICY tenant_admin_view_analytics ON message_analytics
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/communication.ts

export interface CommunicationMessage {
  id: string
  tenantId: string
  senderId: string
  title: string
  content: string
  messageType: 'announcement' | 'notification' | 'alert' | 'reminder'
  priority: 'low' | 'normal' | 'high' | 'urgent'
  channels: Array<'email' | 'sms' | 'in_app' | 'push'>
  status: 'draft' | 'scheduled' | 'sent' | 'failed' | 'cancelled'
  scheduledAt?: string
  sentAt?: string
  targetType: 'all' | 'branches' | 'roles' | 'users' | 'custom'
  targetBranches?: string[]
  targetRoles?: string[]
  targetUsers?: string[]
  customFilter?: Record<string, any>
  templateId?: string
  attachments?: Array<{
    name: string
    url: string
    size: number
    type: string
  }>
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface MessageTemplate {
  id: string
  tenantId: string
  name: string
  description?: string
  category: 'announcement' | 'academic' | 'financial' | 'event' | 'emergency' | 'other'
  titleTemplate: string
  contentTemplate: string
  variables: string[]
  isActive: boolean
  usageCount: number
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface MessageRecipient {
  id: string
  messageId: string
  recipientId: string
  recipientType: 'student' | 'parent' | 'staff' | 'admin'
  deliveryStatus: 'pending' | 'sent' | 'delivered' | 'failed' | 'read'
  channelsSent: string[]
  sentAt?: string
  deliveredAt?: string
  readAt?: string
  errorMessage?: string
  metadata?: Record<string, any>
}

export interface MessageAnalytics {
  id: string
  messageId: string
  tenantId: string
  totalRecipients: number
  sentCount: number
  deliveredCount: number
  failedCount: number
  readCount: number
  emailSent: number
  smsSent: number
  inAppSent: number
  pushSent: number
  updatedAt: string
}

export interface CreateMessageInput {
  title: string
  content: string
  messageType: CommunicationMessage['messageType']
  priority: CommunicationMessage['priority']
  channels: CommunicationMessage['channels']
  targetType: CommunicationMessage['targetType']
  targetBranches?: string[]
  targetRoles?: string[]
  targetUsers?: string[]
  customFilter?: Record<string, any>
  scheduledAt?: string
  templateId?: string
  attachments?: CommunicationMessage['attachments']
}
```

### API Routes

```typescript
// src/app/api/tenant/communications/route.ts

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
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const status = searchParams.get('status')
  const messageType = searchParams.get('type')
  const page = parseInt(searchParams.get('page') || '1')
  const limit = parseInt(searchParams.get('limit') || '20')
  const offset = (page - 1) * limit

  try {
    let query = supabase
      .from('communication_messages')
      .select(`
        *,
        sender:auth.users!sender_id (
          id,
          email,
          user_metadata
        ),
        template:message_templates (
          id,
          name
        ),
        analytics:message_analytics (*)
      `, { count: 'exact' })
      .eq('tenant_id', profile.tenant_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    if (status) {
      query = query.eq('status', status)
    }

    if (messageType) {
      query = query.eq('message_type', messageType)
    }

    const { data: messages, error, count } = await query

    if (error) throw error

    return NextResponse.json({
      messages,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    })

  } catch (error) {
    console.error('Failed to fetch messages:', error)
    return NextResponse.json(
      { error: 'Failed to fetch messages' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const body: CreateMessageInput = await request.json()

    // Validate input
    if (!body.title || !body.content) {
      return NextResponse.json(
        { error: 'Title and content are required' },
        { status: 400 }
      )
    }

    // Create message
    const { data: message, error: insertError } = await supabase
      .from('communication_messages')
      .insert({
        tenant_id: profile.tenant_id,
        sender_id: user.id,
        title: body.title,
        content: body.content,
        message_type: body.messageType,
        priority: body.priority,
        channels: body.channels,
        target_type: body.targetType,
        target_branches: body.targetBranches,
        target_roles: body.targetRoles,
        target_users: body.targetUsers,
        custom_filter: body.customFilter,
        scheduled_at: body.scheduledAt,
        template_id: body.templateId,
        attachments: body.attachments,
        status: body.scheduledAt ? 'scheduled' : 'draft',
      })
      .select()
      .single()

    if (insertError) throw insertError

    // If not scheduled, send immediately
    if (!body.scheduledAt) {
      const { error: sendError } = await supabase.rpc(
        'send_communication_message',
        { p_message_id: message.id }
      )

      if (sendError) throw sendError
    }

    return NextResponse.json({ message }, { status: 201 })

  } catch (error) {
    console.error('Failed to create message:', error)
    return NextResponse.json(
      { error: 'Failed to create message' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/communications/[id]/route.ts

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { data: message, error } = await supabase
      .from('communication_messages')
      .select(`
        *,
        sender:auth.users!sender_id (
          id,
          email,
          user_metadata
        ),
        template:message_templates (
          id,
          name
        ),
        analytics:message_analytics (*),
        recipients:message_recipients (
          id,
          recipient_id,
          recipient_type,
          delivery_status,
          sent_at,
          delivered_at,
          read_at,
          error_message
        )
      `)
      .eq('id', params.id)
      .single()

    if (error) throw error

    return NextResponse.json({ message })

  } catch (error) {
    console.error('Failed to fetch message:', error)
    return NextResponse.json(
      { error: 'Failed to fetch message' },
      { status: 500 }
    )
  }
}

export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()

    const { data: message, error } = await supabase
      .from('communication_messages')
      .update({
        title: body.title,
        content: body.content,
        message_type: body.messageType,
        priority: body.priority,
        channels: body.channels,
        target_type: body.targetType,
        target_branches: body.targetBranches,
        target_roles: body.targetRoles,
        target_users: body.targetUsers,
        scheduled_at: body.scheduledAt,
        attachments: body.attachments,
        updated_at: new Date().toISOString(),
      })
      .eq('id', params.id)
      .eq('status', 'draft') // Only allow updating drafts
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ message })

  } catch (error) {
    console.error('Failed to update message:', error)
    return NextResponse.json(
      { error: 'Failed to update message' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { error } = await supabase
      .from('communication_messages')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', params.id)

    if (error) throw error

    return NextResponse.json({ success: true })

  } catch (error) {
    console.error('Failed to delete message:', error)
    return NextResponse.json(
      { error: 'Failed to delete message' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/communications/templates/route.ts

export async function GET(request: Request) {
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
    const { data: templates, error } = await supabase
      .from('message_templates')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('is_active', true)
      .order('usage_count', { ascending: false })

    if (error) throw error

    return NextResponse.json({ templates })

  } catch (error) {
    console.error('Failed to fetch templates:', error)
    return NextResponse.json(
      { error: 'Failed to fetch templates' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Communication Hub Page

```typescript
// src/app/tenant/communications/page.tsx

'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  Plus, Send, Calendar, Archive, 
  Mail, MessageSquare, Bell, AlertTriangle 
} from 'lucide-react'
import { MessageList } from '@/components/communications/message-list'
import { CreateMessageDialog } from '@/components/communications/create-message-dialog'
import { MessageAnalyticsCard } from '@/components/communications/message-analytics-card'

export default function CommunicationHub() {
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [selectedTab, setSelectedTab] = useState<string>('all')

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['communication-messages', selectedTab],
    queryFn: async () => {
      const params = new URLSearchParams()
      if (selectedTab !== 'all') {
        params.append('status', selectedTab)
      }
      const res = await fetch(`/api/tenant/communications?${params}`)
      if (!res.ok) throw new Error('Failed to fetch messages')
      return res.json()
    },
  })

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Communication Hub</h1>
          <p className="text-muted-foreground">
            Manage announcements and messages across all branches
          </p>
        </div>
        <Button onClick={() => setIsCreateOpen(true)}>
          <Plus className="h-4 w-4 mr-2" />
          New Message
        </Button>
      </div>

      {/* Analytics Overview */}
      <div className="grid gap-4 md:grid-cols-4">
        <MessageAnalyticsCard
          title="Total Sent"
          value={data?.stats?.totalSent || 0}
          icon={Send}
        />
        <MessageAnalyticsCard
          title="Scheduled"
          value={data?.stats?.scheduled || 0}
          icon={Calendar}
        />
        <MessageAnalyticsCard
          title="Drafts"
          value={data?.stats?.drafts || 0}
          icon={Archive}
        />
        <MessageAnalyticsCard
          title="Failed"
          value={data?.stats?.failed || 0}
          icon={AlertTriangle}
        />
      </div>

      {/* Messages List */}
      <Tabs value={selectedTab} onValueChange={setSelectedTab}>
        <TabsList>
          <TabsTrigger value="all">All Messages</TabsTrigger>
          <TabsTrigger value="sent">Sent</TabsTrigger>
          <TabsTrigger value="scheduled">Scheduled</TabsTrigger>
          <TabsTrigger value="draft">Drafts</TabsTrigger>
        </TabsList>

        <TabsContent value={selectedTab} className="mt-6">
          <MessageList
            messages={data?.messages || []}
            isLoading={isLoading}
            onRefresh={refetch}
          />
        </TabsContent>
      </Tabs>

      {/* Create Message Dialog */}
      <CreateMessageDialog
        open={isCreateOpen}
        onOpenChange={setIsCreateOpen}
        onSuccess={() => {
          setIsCreateOpen(false)
          refetch()
        }}
      />
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Create and send multi-channel messages
- [x] Target specific branches, roles, or users
- [x] Schedule messages for future delivery
- [x] Use message templates
- [x] Track delivery status
- [x] View message analytics
- [x] Support attachments
- [x] Rich text editor
- [x] Emergency alerts
- [x] Message history
- [x] Responsive design
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
