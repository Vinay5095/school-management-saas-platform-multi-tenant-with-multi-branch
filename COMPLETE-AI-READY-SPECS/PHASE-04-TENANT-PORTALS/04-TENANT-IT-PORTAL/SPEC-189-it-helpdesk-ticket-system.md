# SPEC-189: IT Helpdesk & Ticket System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-189  
**Title**: IT Helpdesk & Support Ticket System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant IT Portal  
**Category**: Support & Helpdesk  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-186, SPEC-188  

---

## 📋 DESCRIPTION

Complete IT helpdesk system with ticket management, SLA tracking, priority-based routing, knowledge base, asset-linked incidents, internal notes, escalation workflows, and support analytics.

---

## 🎯 SUCCESS CRITERIA

- [ ] Ticket system operational
- [ ] SLA tracking functional
- [ ] Priority routing working
- [ ] Knowledge base accessible
- [ ] Asset linking enabled
- [ ] Escalation automated
- [ ] Analytics available
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Ticket Categories
CREATE TABLE IF NOT EXISTS ticket_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Category details
  category_name VARCHAR(100) NOT NULL,
  category_code VARCHAR(20) NOT NULL,
  
  -- SLA
  default_priority VARCHAR(20) DEFAULT 'medium',
  default_response_time_hours INTEGER DEFAULT 24,
  default_resolution_time_hours INTEGER DEFAULT 72,
  
  -- Assignment
  default_assigned_team VARCHAR(100),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  display_order INTEGER,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, category_code)
);

CREATE INDEX ON ticket_categories(tenant_id);

-- Support Tickets
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Ticket details
  ticket_number VARCHAR(50) UNIQUE NOT NULL,
  subject VARCHAR(300) NOT NULL,
  description TEXT NOT NULL,
  
  -- Category
  category_id UUID REFERENCES ticket_categories(id),
  
  -- Priority
  priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
  
  -- Requester
  requester_id UUID NOT NULL REFERENCES staff(id),
  requester_contact VARCHAR(200),
  
  -- Assignment
  assigned_to UUID REFERENCES auth.users(id),
  assigned_team VARCHAR(100),
  
  -- Asset linkage
  related_asset_id UUID REFERENCES it_assets(id),
  
  -- Status
  status VARCHAR(50) DEFAULT 'open', -- open, in_progress, waiting_on_customer, resolved, closed
  
  -- SLA tracking
  response_due_at TIMESTAMP WITH TIME ZONE,
  resolution_due_at TIMESTAMP WITH TIME ZONE,
  first_response_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE,
  
  -- Metrics
  is_sla_breached BOOLEAN DEFAULT false,
  response_time_minutes INTEGER,
  resolution_time_minutes INTEGER,
  
  -- Resolution
  resolution_notes TEXT,
  
  -- Satisfaction
  satisfaction_rating INTEGER,
  satisfaction_feedback TEXT,
  
  -- Tags
  tags VARCHAR(50)[],
  
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_priority CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  CONSTRAINT valid_status CHECK (status IN ('open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed'))
);

CREATE INDEX ON support_tickets(tenant_id, status);
CREATE INDEX ON support_tickets(assigned_to);
CREATE INDEX ON support_tickets(requester_id);
CREATE INDEX ON support_tickets(created_at DESC);

-- Ticket Comments
CREATE TABLE IF NOT EXISTS ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  
  -- Comment details
  comment_text TEXT NOT NULL,
  
  -- Author
  author_id UUID NOT NULL REFERENCES auth.users(id),
  author_name VARCHAR(200),
  
  -- Type
  comment_type VARCHAR(50) DEFAULT 'public', -- public, internal, system
  
  -- Attachments
  attachments JSONB,
  
  -- System flag
  is_system_comment BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON ticket_comments(ticket_id, created_at);

-- Ticket Attachments
CREATE TABLE IF NOT EXISTS ticket_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  
  -- File details
  file_name VARCHAR(300) NOT NULL,
  file_url TEXT NOT NULL,
  file_size_bytes BIGINT,
  file_type VARCHAR(100),
  
  -- Uploaded by
  uploaded_by UUID REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON ticket_attachments(ticket_id);

-- Knowledge Base Articles
CREATE TABLE IF NOT EXISTS knowledge_base_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Article details
  article_title VARCHAR(300) NOT NULL,
  article_slug VARCHAR(350) UNIQUE NOT NULL,
  article_content TEXT NOT NULL,
  
  -- Category
  category_id UUID REFERENCES ticket_categories(id),
  
  -- Tags
  tags VARCHAR(50)[],
  
  -- Metadata
  author_id UUID REFERENCES auth.users(id),
  
  -- Visibility
  is_published BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  
  -- Metrics
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  not_helpful_count INTEGER DEFAULT 0,
  
  -- SEO
  meta_description TEXT,
  
  -- Dates
  published_at TIMESTAMP WITH TIME ZONE,
  last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON knowledge_base_articles(tenant_id, is_published);
CREATE INDEX ON knowledge_base_articles(category_id);

-- Ticket Escalations
CREATE TABLE IF NOT EXISTS ticket_escalations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  
  -- Escalation details
  escalation_reason VARCHAR(200) NOT NULL,
  escalation_level INTEGER DEFAULT 1,
  
  -- From/To
  escalated_from UUID REFERENCES auth.users(id),
  escalated_to UUID REFERENCES auth.users(id),
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, acknowledged, resolved
  
  -- Response
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolution_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'acknowledged', 'resolved'))
);

CREATE INDEX ON ticket_escalations(ticket_id);

-- SLA Policies
CREATE TABLE IF NOT EXISTS sla_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Policy details
  policy_name VARCHAR(200) NOT NULL,
  
  -- Priority configuration
  priority_level VARCHAR(20) NOT NULL,
  
  -- Time targets
  first_response_hours INTEGER NOT NULL,
  resolution_hours INTEGER NOT NULL,
  
  -- Business hours
  apply_business_hours_only BOOLEAN DEFAULT true,
  
  -- Escalation
  escalation_enabled BOOLEAN DEFAULT false,
  escalation_after_hours INTEGER,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, priority_level)
);

CREATE INDEX ON sla_policies(tenant_id);

-- Function to generate ticket number
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.ticket_number := 'TKT-' || 
    TO_CHAR(NOW(), 'YYYYMM') || '-' ||
    LPAD(NEXTVAL('ticket_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS ticket_seq;

CREATE TRIGGER set_ticket_number
  BEFORE INSERT ON support_tickets
  FOR EACH ROW
  WHEN (NEW.ticket_number IS NULL OR NEW.ticket_number = '')
  EXECUTE FUNCTION generate_ticket_number();

-- Function to calculate SLA due times
CREATE OR REPLACE FUNCTION calculate_sla_due_times()
RETURNS TRIGGER AS $$
DECLARE
  v_policy RECORD;
BEGIN
  -- Get SLA policy for priority
  SELECT * INTO v_policy
  FROM sla_policies
  WHERE tenant_id = NEW.tenant_id
  AND priority_level = NEW.priority
  AND is_active = true
  LIMIT 1;
  
  IF FOUND THEN
    NEW.response_due_at := NEW.created_at + (v_policy.first_response_hours || ' hours')::INTERVAL;
    NEW.resolution_due_at := NEW.created_at + (v_policy.resolution_hours || ' hours')::INTERVAL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_sla_due_times
  BEFORE INSERT ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION calculate_sla_due_times();

-- Function to check SLA breach
CREATE OR REPLACE FUNCTION check_sla_breach()
RETURNS TRIGGER AS $$
BEGIN
  -- Check response SLA
  IF NEW.first_response_at IS NOT NULL AND 
     NEW.response_due_at IS NOT NULL AND
     NEW.first_response_at > NEW.response_due_at THEN
    NEW.is_sla_breached := true;
  END IF;
  
  -- Check resolution SLA
  IF NEW.resolved_at IS NOT NULL AND 
     NEW.resolution_due_at IS NOT NULL AND
     NEW.resolved_at > NEW.resolution_due_at THEN
    NEW.is_sla_breached := true;
  END IF;
  
  -- Calculate response time
  IF NEW.first_response_at IS NOT NULL THEN
    NEW.response_time_minutes := EXTRACT(EPOCH FROM (NEW.first_response_at - NEW.created_at)) / 60;
  END IF;
  
  -- Calculate resolution time
  IF NEW.resolved_at IS NOT NULL THEN
    NEW.resolution_time_minutes := EXTRACT(EPOCH FROM (NEW.resolved_at - NEW.created_at)) / 60;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_sla_breach
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION check_sla_breach();

-- Enable RLS
ALTER TABLE ticket_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_escalations ENABLE ROW LEVEL SECURITY;
ALTER TABLE sla_policies ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/helpdesk.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface SupportTicket {
  id: string;
  ticketNumber: string;
  subject: string;
  priority: string;
  status: string;
  requesterName?: string;
  assignedTo?: string;
  createdAt: string;
}

export class HelpdeskAPI {
  private supabase = createClient();

  async createTicket(params: {
    tenantId: string;
    requesterId: string;
    subject: string;
    description: string;
    priority: string;
    categoryId?: string;
    relatedAssetId?: string;
  }): Promise<SupportTicket> {
    const { data, error } = await this.supabase
      .from('support_tickets')
      .insert({
        tenant_id: params.tenantId,
        requester_id: params.requesterId,
        subject: params.subject,
        description: params.description,
        priority: params.priority,
        category_id: params.categoryId,
        related_asset_id: params.relatedAssetId,
        status: 'open',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      ticketNumber: data.ticket_number,
      subject: data.subject,
      priority: data.priority,
      status: data.status,
      createdAt: data.created_at,
    };
  }

  async getTickets(params: {
    tenantId: string;
    status?: string;
    priority?: string;
    assignedTo?: string;
  }): Promise<SupportTicket[]> {
    let query = this.supabase
      .from('support_tickets')
      .select(`
        *,
        requester:staff(full_name)
      `)
      .eq('tenant_id', params.tenantId);

    if (params.status) {
      query = query.eq('status', params.status);
    }

    if (params.priority) {
      query = query.eq('priority', params.priority);
    }

    if (params.assignedTo) {
      query = query.eq('assigned_to', params.assignedTo);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map(ticket => ({
      id: ticket.id,
      ticketNumber: ticket.ticket_number,
      subject: ticket.subject,
      priority: ticket.priority,
      status: ticket.status,
      requesterName: ticket.requester?.full_name,
      assignedTo: ticket.assigned_to,
      createdAt: ticket.created_at,
    }));
  }

  async updateTicketStatus(params: {
    ticketId: string;
    status: string;
    resolutionNotes?: string;
  }): Promise<void> {
    const updateData: any = { status: params.status };

    if (params.status === 'resolved') {
      updateData.resolved_at = new Date().toISOString();
      updateData.resolution_notes = params.resolutionNotes;
    } else if (params.status === 'closed') {
      updateData.closed_at = new Date().toISOString();
    }

    const { error } = await this.supabase
      .from('support_tickets')
      .update(updateData)
      .eq('id', params.ticketId);

    if (error) throw error;
  }

  async addComment(params: {
    ticketId: string;
    commentText: string;
    commentType?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('ticket_comments')
      .insert({
        ticket_id: params.ticketId,
        comment_text: params.commentText,
        author_id: user?.id,
        comment_type: params.commentType || 'public',
      })
      .select()
      .single();

    if (error) throw error;

    // Update first response time if this is the first response
    const { data: ticket } = await this.supabase
      .from('support_tickets')
      .select('first_response_at')
      .eq('id', params.ticketId)
      .single();

    if (ticket && !ticket.first_response_at) {
      await this.supabase
        .from('support_tickets')
        .update({ first_response_at: new Date().toISOString() })
        .eq('id', params.ticketId);
    }

    return data;
  }

  async getTicketComments(ticketId: string) {
    const { data, error } = await this.supabase
      .from('ticket_comments')
      .select('*')
      .eq('ticket_id', ticketId)
      .order('created_at');

    if (error) throw error;

    return data.map(comment => ({
      id: comment.id,
      commentText: comment.comment_text,
      authorName: comment.author_name,
      commentType: comment.comment_type,
      createdAt: comment.created_at,
    }));
  }

  async assignTicket(params: {
    ticketId: string;
    assignedTo: string;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('support_tickets')
      .update({ assigned_to: params.assignedTo })
      .eq('id', params.ticketId);

    if (error) throw error;
  }

  async escalateTicket(params: {
    ticketId: string;
    escalationReason: string;
    escalatedTo: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('ticket_escalations')
      .insert({
        ticket_id: params.ticketId,
        escalation_reason: params.escalationReason,
        escalated_from: user?.id,
        escalated_to: params.escalatedTo,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async createKBArticle(params: {
    tenantId: string;
    articleTitle: string;
    articleContent: string;
    categoryId?: string;
    tags?: string[];
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();
    const slug = params.articleTitle.toLowerCase().replace(/\s+/g, '-');

    const { data, error } = await this.supabase
      .from('knowledge_base_articles')
      .insert({
        tenant_id: params.tenantId,
        article_title: params.articleTitle,
        article_slug: slug,
        article_content: params.articleContent,
        category_id: params.categoryId,
        tags: params.tags,
        author_id: user?.id,
        is_published: false,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async searchKBArticles(params: {
    tenantId: string;
    query: string;
  }) {
    const { data, error } = await this.supabase
      .from('knowledge_base_articles')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('is_published', true)
      .or(`article_title.ilike.%${params.query}%,article_content.ilike.%${params.query}%`)
      .order('view_count', { ascending: false });

    if (error) throw error;

    return data.map(article => ({
      id: article.id,
      articleTitle: article.article_title,
      articleSlug: article.article_slug,
      viewCount: article.view_count,
      helpfulCount: article.helpful_count,
    }));
  }

  async getTicketAnalytics(params: {
    tenantId: string;
    startDate?: Date;
    endDate?: Date;
  }) {
    let query = this.supabase
      .from('support_tickets')
      .select('priority, status, is_sla_breached, created_at')
      .eq('tenant_id', params.tenantId);

    if (params.startDate) {
      query = query.gte('created_at', params.startDate.toISOString());
    }

    if (params.endDate) {
      query = query.lte('created_at', params.endDate.toISOString());
    }

    const { data, error } = await query;

    if (error) throw error;

    // Calculate statistics
    const totalTickets = data.length;
    const openTickets = data.filter(t => t.status === 'open').length;
    const closedTickets = data.filter(t => t.status === 'closed').length;
    const slaBreached = data.filter(t => t.is_sla_breached).length;

    return {
      totalTickets,
      openTickets,
      closedTickets,
      slaBreached,
      slaComplianceRate: ((totalTickets - slaBreached) / totalTickets) * 100,
    };
  }
}

export const helpdeskAPI = new HelpdeskAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { HelpdeskAPI } from '../helpdesk';

describe('HelpdeskAPI', () => {
  it('creates support ticket', async () => {
    const api = new HelpdeskAPI();
    const ticket = await api.createTicket({
      tenantId: 'test-tenant',
      requesterId: 'user-123',
      subject: 'Laptop not working',
      description: 'My laptop won't turn on',
      priority: 'high',
    });

    expect(ticket).toHaveProperty('id');
    expect(ticket.ticketNumber).toContain('TKT-');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Tickets created
- [ ] SLA tracked
- [ ] Comments added
- [ ] Assignments working
- [ ] Knowledge base functional
- [ ] Analytics available
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-190 (Security & Access - FINAL SPEC!)  
**Time**: 4 hours  
**AI-Ready**: 100%
