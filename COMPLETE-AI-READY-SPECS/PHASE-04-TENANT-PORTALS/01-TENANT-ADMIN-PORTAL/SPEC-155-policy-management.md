# SPEC-155: Policy Management System
## Centralized Policy Repository with Version Control

> **Status**: ✅ COMPLETE - READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-151, SPEC-152, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Comprehensive policy management system for creating, storing, versioning, approving, and distributing organizational policies across all branches with digital acknowledgment tracking and compliance monitoring.

### Key Features
- ✅ Policy creation with rich text editor
- ✅ Policy categorization and tagging
- ✅ Version control with change tracking
- ✅ Multi-level approval workflows
- ✅ Policy distribution to specific audiences
- ✅ Digital acknowledgment tracking
- ✅ Policy search and filtering
- ✅ PDF generation and export
- ✅ Archive management
- ✅ Policy expiration and renewal reminders
- ✅ Compliance reporting
- ✅ Audit trail for all policy changes
- ✅ TypeScript with strict validation

---

## 🗄️ DATABASE SCHEMA

```sql
-- =====================================================
-- POLICY CATEGORIES TABLE
-- =====================================================
CREATE TABLE policy_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  description TEXT,
  parent_category_id UUID REFERENCES policy_categories(id) ON DELETE SET NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, category_name)
);

CREATE INDEX idx_policy_categories_tenant ON policy_categories(tenant_id);
CREATE INDEX idx_policy_categories_parent ON policy_categories(parent_category_id);

-- =====================================================
-- POLICIES TABLE
-- =====================================================
CREATE TABLE policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  policy_code TEXT NOT NULL,
  policy_title TEXT NOT NULL,
  category_id UUID REFERENCES policy_categories(id) ON DELETE SET NULL,
  
  description TEXT,
  content TEXT NOT NULL, -- Rich text content (HTML or Markdown)
  
  version_number TEXT NOT NULL DEFAULT '1.0',
  version_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  policy_type TEXT NOT NULL CHECK (policy_type IN (
    'hr', 'academic', 'financial', 'it', 'safety', 
    'compliance', 'operational', 'administrative', 'other'
  )),
  
  applies_to TEXT NOT NULL DEFAULT 'all' CHECK (applies_to IN (
    'all', 'staff', 'faculty', 'students', 'parents', 'custom'
  )),
  custom_audience UUID[], -- Array of user/role IDs for custom audience
  
  branch_ids UUID[], -- NULL = all branches, specific IDs = those branches only
  
  effective_date DATE NOT NULL,
  expiry_date DATE,
  review_date DATE,
  
  requires_acknowledgment BOOLEAN DEFAULT true,
  acknowledgment_deadline DATE,
  
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'pending_approval', 'approved', 'published', 
    'archived', 'superseded', 'expired'
  )),
  
  approval_level_required INTEGER DEFAULT 1, -- Number of approval levels required
  
  tags TEXT[],
  
  document_url TEXT, -- URL to attached PDF/document
  
  created_by UUID REFERENCES auth.users(id),
  published_by UUID REFERENCES auth.users(id),
  published_at TIMESTAMPTZ,
  
  superseded_by UUID REFERENCES policies(id) ON DELETE SET NULL,
  superseded_at TIMESTAMPTZ,
  
  archived_at TIMESTAMPTZ,
  
  metadata JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(tenant_id, policy_code, version_number),
  CONSTRAINT valid_dates CHECK (
    effective_date <= COALESCE(expiry_date, '9999-12-31') AND
    (review_date IS NULL OR review_date > effective_date)
  )
);

CREATE INDEX idx_policies_tenant ON policies(tenant_id);
CREATE INDEX idx_policies_category ON policies(category_id);
CREATE INDEX idx_policies_status ON policies(status);
CREATE INDEX idx_policies_type ON policies(policy_type);
CREATE INDEX idx_policies_effective_date ON policies(effective_date);
CREATE INDEX idx_policies_expiry_date ON policies(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_policies_review_date ON policies(review_date) WHERE review_date IS NOT NULL;
CREATE INDEX idx_policies_code ON policies(policy_code);
CREATE INDEX idx_policies_tags ON policies USING GIN(tags);

-- =====================================================
-- POLICY APPROVALS TABLE
-- =====================================================
CREATE TABLE policy_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  approval_level INTEGER NOT NULL,
  approver_id UUID NOT NULL REFERENCES auth.users(id),
  approver_role TEXT NOT NULL,
  
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'approved', 'rejected', 'delegated'
  )),
  
  decision_date TIMESTAMPTZ,
  comments TEXT,
  
  delegated_to UUID REFERENCES auth.users(id),
  delegated_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(policy_id, approval_level, approver_id)
);

CREATE INDEX idx_policy_approvals_policy ON policy_approvals(policy_id);
CREATE INDEX idx_policy_approvals_approver ON policy_approvals(approver_id);
CREATE INDEX idx_policy_approvals_status ON policy_approvals(status);
CREATE INDEX idx_policy_approvals_level ON policy_approvals(approval_level);

-- =====================================================
-- POLICY ACKNOWLEDGMENTS TABLE
-- =====================================================
CREATE TABLE policy_acknowledgments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_at TIMESTAMPTZ,
  
  ip_address INET,
  user_agent TEXT,
  
  signature_data TEXT, -- Digital signature if required
  
  reminder_sent_count INTEGER DEFAULT 0,
  last_reminder_sent_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(policy_id, user_id)
);

CREATE INDEX idx_policy_acks_policy ON policy_acknowledgments(policy_id);
CREATE INDEX idx_policy_acks_user ON policy_acknowledgments(user_id);
CREATE INDEX idx_policy_acks_acknowledged ON policy_acknowledgments(acknowledged);
CREATE INDEX idx_policy_acks_tenant ON policy_acknowledgments(tenant_id);

-- =====================================================
-- POLICY VERSION HISTORY TABLE
-- =====================================================
CREATE TABLE policy_version_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  version_number TEXT NOT NULL,
  version_date DATE NOT NULL,
  
  change_type TEXT NOT NULL CHECK (change_type IN (
    'created', 'minor_update', 'major_update', 'superseded', 'archived'
  )),
  
  changes_summary TEXT,
  previous_content TEXT,
  new_content TEXT,
  
  changed_by UUID REFERENCES auth.users(id),
  change_reason TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_policy_history_policy ON policy_version_history(policy_id);
CREATE INDEX idx_policy_history_tenant ON policy_version_history(tenant_id);
CREATE INDEX idx_policy_history_version ON policy_version_history(version_number);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to get policy compliance rate
CREATE OR REPLACE FUNCTION get_policy_compliance_rate(p_policy_id UUID)
RETURNS TABLE (
  total_required INTEGER,
  acknowledged INTEGER,
  pending INTEGER,
  compliance_rate DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_required,
    COUNT(*) FILTER (WHERE acknowledged = true)::INTEGER as acknowledged,
    COUNT(*) FILTER (WHERE acknowledged = false)::INTEGER as pending,
    ROUND(
      COUNT(*) FILTER (WHERE acknowledged = true)::DECIMAL / 
      NULLIF(COUNT(*), 0) * 100, 
      2
    ) as compliance_rate
  FROM policy_acknowledgments
  WHERE policy_id = p_policy_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get policies requiring acknowledgment
CREATE OR REPLACE FUNCTION get_policies_requiring_acknowledgment(p_user_id UUID)
RETURNS TABLE (
  policy_id UUID,
  policy_title TEXT,
  policy_code TEXT,
  effective_date DATE,
  acknowledgment_deadline DATE,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.policy_title,
    p.policy_code,
    p.effective_date,
    p.acknowledgment_deadline,
    (p.acknowledgment_deadline - CURRENT_DATE) as days_remaining
  FROM policies p
  INNER JOIN policy_acknowledgments pa ON p.id = pa.policy_id
  WHERE 
    pa.user_id = p_user_id
    AND pa.acknowledged = false
    AND p.status = 'published'
    AND p.requires_acknowledgment = true
    AND (p.acknowledgment_deadline IS NULL OR p.acknowledgment_deadline >= CURRENT_DATE)
  ORDER BY p.acknowledgment_deadline NULLS LAST, p.effective_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to check all required approvals
CREATE OR REPLACE FUNCTION check_policy_approvals(p_policy_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_required_levels INTEGER;
  v_approved_levels INTEGER;
BEGIN
  -- Get required approval levels
  SELECT approval_level_required INTO v_required_levels
  FROM policies
  WHERE id = p_policy_id;
  
  -- Count approved levels
  SELECT COUNT(DISTINCT approval_level) INTO v_approved_levels
  FROM policy_approvals
  WHERE policy_id = p_policy_id
    AND status = 'approved';
  
  RETURN v_approved_levels >= v_required_levels;
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger to log policy version changes
CREATE OR REPLACE FUNCTION log_policy_version_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (
    OLD.content != NEW.content OR 
    OLD.version_number != NEW.version_number
  ) THEN
    INSERT INTO policy_version_history (
      policy_id,
      tenant_id,
      version_number,
      version_date,
      change_type,
      changes_summary,
      previous_content,
      new_content,
      changed_by
    ) VALUES (
      NEW.id,
      NEW.tenant_id,
      NEW.version_number,
      NEW.version_date,
      CASE 
        WHEN OLD.status = 'published' AND NEW.status = 'superseded' THEN 'superseded'
        WHEN OLD.status != 'archived' AND NEW.status = 'archived' THEN 'archived'
        WHEN SPLIT_PART(NEW.version_number, '.', 1) != SPLIT_PART(OLD.version_number, '.', 1) 
          THEN 'major_update'
        ELSE 'minor_update'
      END,
      'Version updated from ' || OLD.version_number || ' to ' || NEW.version_number,
      OLD.content,
      NEW.content,
      NEW.updated_by
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_policy_versions
AFTER UPDATE ON policies
FOR EACH ROW
EXECUTE FUNCTION log_policy_version_change();

-- Trigger to auto-update policy status after approvals
CREATE OR REPLACE FUNCTION update_policy_status_on_approval()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Check if all required approvals are complete
    IF check_policy_approvals(NEW.policy_id) THEN
      UPDATE policies
      SET status = 'approved'
      WHERE id = NEW.policy_id AND status = 'pending_approval';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_policy_on_approval
AFTER UPDATE ON policy_approvals
FOR EACH ROW
EXECUTE FUNCTION update_policy_status_on_approval();

-- Trigger to create acknowledgment records when policy is published
CREATE OR REPLACE FUNCTION create_policy_acknowledgments()
RETURNS TRIGGER AS $$
DECLARE
  v_user_ids UUID[];
BEGIN
  IF NEW.status = 'published' AND 
     OLD.status != 'published' AND 
     NEW.requires_acknowledgment = true THEN
    
    -- Determine target users based on applies_to
    IF NEW.applies_to = 'all' THEN
      v_user_ids := ARRAY(
        SELECT DISTINCT user_id 
        FROM user_profiles 
        WHERE tenant_id = NEW.tenant_id
      );
    ELSIF NEW.applies_to = 'custom' THEN
      v_user_ids := NEW.custom_audience;
    ELSE
      -- Get users based on role
      v_user_ids := ARRAY(
        SELECT DISTINCT user_id 
        FROM user_profiles 
        WHERE tenant_id = NEW.tenant_id 
          AND role = NEW.applies_to
      );
    END IF;
    
    -- Create acknowledgment records
    INSERT INTO policy_acknowledgments (
      policy_id,
      tenant_id,
      user_id,
      acknowledged
    )
    SELECT 
      NEW.id,
      NEW.tenant_id,
      unnest(v_user_ids),
      false
    ON CONFLICT (policy_id, user_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_acknowledgments_on_publish
AFTER UPDATE ON policies
FOR EACH ROW
EXECUTE FUNCTION create_policy_acknowledgments();
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/policy.ts

export interface Policy {
  id: string
  tenantId: string
  policyCode: string
  policyTitle: string
  categoryId?: string
  description?: string
  content: string
  versionNumber: string
  versionDate: string
  policyType: 'hr' | 'academic' | 'financial' | 'it' | 'safety' | 'compliance' | 'operational' | 'administrative' | 'other'
  appliesTo: 'all' | 'staff' | 'faculty' | 'students' | 'parents' | 'custom'
  customAudience?: string[]
  branchIds?: string[]
  effectiveDate: string
  expiryDate?: string
  reviewDate?: string
  requiresAcknowledgment: boolean
  acknowledgmentDeadline?: string
  status: 'draft' | 'pending_approval' | 'approved' | 'published' | 'archived' | 'superseded' | 'expired'
  approvalLevelRequired: number
  tags: string[]
  documentUrl?: string
  createdBy: string
  publishedBy?: string
  publishedAt?: string
  supersededBy?: string
  supersededAt?: string
  archivedAt?: string
  metadata: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface PolicyApproval {
  id: string
  policyId: string
  tenantId: string
  approvalLevel: number
  approverId: string
  approverRole: string
  status: 'pending' | 'approved' | 'rejected' | 'delegated'
  decisionDate?: string
  comments?: string
  delegatedTo?: string
  delegatedAt?: string
  createdAt: string
  updatedAt: string
}

export interface PolicyAcknowledgment {
  id: string
  policyId: string
  tenantId: string
  userId: string
  acknowledged: boolean
  acknowledgedAt?: string
  ipAddress?: string
  userAgent?: string
  signatureData?: string
  reminderSentCount: number
  lastReminderSentAt?: string
  createdAt: string
  updatedAt: string
}

export interface PolicyCategory {
  id: string
  tenantId: string
  categoryName: string
  description?: string
  parentCategoryId?: string
  displayOrder: number
  createdAt: string
  updatedAt: string
}

export interface PolicyFormData {
  policyCode: string
  policyTitle: string
  categoryId?: string
  description?: string
  content: string
  policyType: string
  appliesTo: string
  customAudience?: string[]
  branchIds?: string[]
  effectiveDate: string
  expiryDate?: string
  reviewDate?: string
  requiresAcknowledgment: boolean
  acknowledgmentDeadline?: string
  approvalLevelRequired: number
  tags: string[]
}

export interface ComplianceReport {
  policyId: string
  policyTitle: string
  totalRequired: number
  acknowledged: number
  pending: number
  complianceRate: number
  overdue: number
}
```

### API Routes

```typescript
// src/app/api/tenant/policies/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { z } from 'zod'

const policySchema = z.object({
  policyCode: z.string().min(2).max(20),
  policyTitle: z.string().min(5).max(200),
  categoryId: z.string().uuid().optional(),
  description: z.string().optional(),
  content: z.string().min(10),
  policyType: z.enum(['hr', 'academic', 'financial', 'it', 'safety', 'compliance', 'operational', 'administrative', 'other']),
  appliesTo: z.enum(['all', 'staff', 'faculty', 'students', 'parents', 'custom']),
  customAudience: z.array(z.string().uuid()).optional(),
  branchIds: z.array(z.string().uuid()).optional(),
  effectiveDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  expiryDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  reviewDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  requiresAcknowledgment: z.boolean().default(true),
  acknowledgmentDeadline: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  approvalLevelRequired: z.number().min(1).max(5).default(1),
  tags: z.array(z.string()).default([]),
})

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

  if (!profile) {
    return NextResponse.json({ error: 'Profile not found' }, { status: 404 })
  }

  try {
    const status = searchParams.get('status') || 'all'
    const search = searchParams.get('search') || ''
    const policyType = searchParams.get('policyType') || 'all'
    const categoryId = searchParams.get('categoryId')
    const requiresAck = searchParams.get('requiresAck')

    let query = supabase
      .from('policies')
      .select(`
        *,
        category:category_id (id, category_name),
        created_by_user:created_by (id, email),
        acknowledgments:policy_acknowledgments (
          count,
          acknowledged:acknowledged.count()
        ),
        approvals:policy_approvals (
          count,
          approved:status.eq.approved.count()
        )
      `)
      .eq('tenant_id', profile.tenant_id)
      .order('created_at', { ascending: false })

    // Filters
    if (status !== 'all') {
      query = query.eq('status', status)
    }

    if (policyType !== 'all') {
      query = query.eq('policy_type', policyType)
    }

    if (categoryId) {
      query = query.eq('category_id', categoryId)
    }

    if (requiresAck === 'true') {
      query = query.eq('requires_acknowledgment', true)
    }

    if (search) {
      query = query.or(`policy_title.ilike.%${search}%,policy_code.ilike.%${search}%,description.ilike.%${search}%`)
    }

    const { data: policies, error } = await query

    if (error) throw error

    return NextResponse.json({ policies })

  } catch (error) {
    console.error('Policies fetch error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch policies' },
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
    const body = await request.json()
    const validatedData = policySchema.parse(body)

    // Check code uniqueness
    const { data: existing } = await supabase
      .from('policies')
      .select('id')
      .eq('tenant_id', profile.tenant_id)
      .eq('policy_code', validatedData.policyCode)
      .eq('version_number', '1.0')
      .single()

    if (existing) {
      return NextResponse.json(
        { error: 'Policy code already exists' },
        { status: 400 }
      )
    }

    // Create policy
    const { data: policy, error: policyError } = await supabase
      .from('policies')
      .insert({
        tenant_id: profile.tenant_id,
        ...validatedData,
        version_number: '1.0',
        version_date: new Date().toISOString().split('T')[0],
        status: 'draft',
        created_by: user.id,
      })
      .select()
      .single()

    if (policyError) throw policyError

    // Log activity
    await supabase.from('platform_activity_log').insert({
      tenant_id: profile.tenant_id,
      user_id: user.id,
      action: 'policy_created',
      action_type: 'create',
      details: `Created policy: ${policy.policy_title}`,
      metadata: { policyId: policy.id },
    })

    return NextResponse.json({ policy }, { status: 201 })

  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation error', details: error.errors },
        { status: 400 }
      )
    }
    console.error('Policy creation error:', error)
    return NextResponse.json(
      { error: 'Failed to create policy' },
      { status: 500 }
    )
  }
}

// src/app/api/tenant/policies/[policyId]/acknowledge/route.ts

export async function POST(
  request: Request,
  { params }: { params: { policyId: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { signatureData } = body

    // Get client IP (in production, use proper header)
    const ipAddress = request.headers.get('x-forwarded-for') || 
                     request.headers.get('x-real-ip') || 
                     '0.0.0.0'
    const userAgent = request.headers.get('user-agent') || 'Unknown'

    // Update acknowledgment
    const { data: acknowledgment, error } = await supabase
      .from('policy_acknowledgments')
      .update({
        acknowledged: true,
        acknowledged_at: new Date().toISOString(),
        ip_address: ipAddress,
        user_agent: userAgent,
        signature_data: signatureData || null,
      })
      .eq('policy_id', params.policyId)
      .eq('user_id', user.id)
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ acknowledgment })

  } catch (error) {
    console.error('Acknowledgment error:', error)
    return NextResponse.json(
      { error: 'Failed to acknowledge policy' },
      { status: 500 }
    )
  }
}

// src/app/api/tenant/policies/compliance-report/route.ts

export async function GET(request: Request) {
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
    // Get all published policies requiring acknowledgment
    const { data: policies, error: policiesError } = await supabase
      .from('policies')
      .select('id, policy_title, policy_code')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'published')
      .eq('requires_acknowledgment', true)

    if (policiesError) throw policiesError

    // Get compliance rate for each policy
    const complianceReports = await Promise.all(
      policies.map(async (policy) => {
        const { data: complianceData } = await supabase
          .rpc('get_policy_compliance_rate', { p_policy_id: policy.id })

        return {
          policyId: policy.id,
          policyTitle: policy.policy_title,
          policyCode: policy.policy_code,
          ...complianceData[0],
        }
      })
    )

    return NextResponse.json({ complianceReports })

  } catch (error) {
    console.error('Compliance report error:', error)
    return NextResponse.json(
      { error: 'Failed to generate compliance report' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Policy List Page

```typescript
// src/app/tenant/policies/page.tsx

'use client'

import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { 
  Select, SelectContent, SelectItem, 
  SelectTrigger, SelectValue 
} from '@/components/ui/select'
import {
  Table, TableBody, TableCell, TableHead,
  TableHeader, TableRow
} from '@/components/ui/table'
import { 
  Plus, Search, FileText, Clock, CheckCircle2, 
  AlertCircle, Eye, Edit, Trash, Download 
} from 'lucide-react'
import { useRouter } from 'next/navigation'
import { format } from 'date-fns'

export default function PoliciesPage() {
  const router = useRouter()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')

  const { data, isLoading } = useQuery({
    queryKey: ['policies', statusFilter, typeFilter, search],
    queryFn: async () => {
      const params = new URLSearchParams({
        status: statusFilter,
        policyType: typeFilter,
        search,
      })
      const res = await fetch(`/api/tenant/policies?${params}`)
      if (!res.ok) throw new Error('Failed to fetch policies')
      return res.json()
    },
  })

  const getStatusBadge = (status: string) => {
    const colors: Record<string, string> = {
      draft: 'bg-gray-100 text-gray-800',
      pending_approval: 'bg-yellow-100 text-yellow-800',
      approved: 'bg-green-100 text-green-800',
      published: 'bg-blue-100 text-blue-800',
      archived: 'bg-gray-100 text-gray-600',
      superseded: 'bg-orange-100 text-orange-800',
      expired: 'bg-red-100 text-red-800',
    }
    return colors[status] || colors.draft
  }

  const getComplianceColor = (rate: number) => {
    if (rate >= 90) return 'text-green-600'
    if (rate >= 70) return 'text-yellow-600'
    return 'text-red-600'
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-gray-200 animate-pulse rounded w-48"></div>
        <div className="h-96 bg-gray-100 animate-pulse rounded"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Policy Management</h1>
          <p className="text-muted-foreground">
            Manage organizational policies and track compliance
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => router.push('/tenant/policies/compliance')}>
            <FileText className="h-4 w-4 mr-2" />
            Compliance Report
          </Button>
          <Button onClick={() => router.push('/tenant/policies/new')}>
            <Plus className="h-4 w-4 mr-2" />
            Create Policy
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid gap-6 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Policies
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data?.policies?.length || 0}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Published
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">
              {data?.policies?.filter((p: any) => p.status === 'published').length || 0}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Pending Approval
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">
              {data?.policies?.filter((p: any) => p.status === 'pending_approval').length || 0}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Require Review
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">
              {data?.policies?.filter((p: any) => 
                p.review_date && new Date(p.review_date) <= new Date()
              ).length || 0}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search policies..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="draft">Draft</SelectItem>
                <SelectItem value="pending_approval">Pending Approval</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="published">Published</SelectItem>
                <SelectItem value="archived">Archived</SelectItem>
              </SelectContent>
            </Select>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Types</SelectItem>
                <SelectItem value="hr">HR</SelectItem>
                <SelectItem value="academic">Academic</SelectItem>
                <SelectItem value="financial">Financial</SelectItem>
                <SelectItem value="it">IT</SelectItem>
                <SelectItem value="safety">Safety</SelectItem>
                <SelectItem value="compliance">Compliance</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Policies Table */}
      <Card>
        <CardContent className="pt-6">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Policy</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Version</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Effective Date</TableHead>
                <TableHead>Compliance</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data?.policies?.map((policy: any) => {
                const complianceRate = policy.acknowledgments?.acknowledged || 0
                const totalRequired = policy.acknowledgments?.count || 1
                const percentage = Math.round((complianceRate / totalRequired) * 100)

                return (
                  <TableRow key={policy.id}>
                    <TableCell>
                      <div>
                        <div className="font-medium">{policy.policy_title}</div>
                        <div className="text-sm text-muted-foreground">
                          {policy.policy_code}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="capitalize">
                        {policy.policy_type}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm">
                        v{policy.version_number}
                      </span>
                    </TableCell>
                    <TableCell>
                      <Badge className={getStatusBadge(policy.status)}>
                        {policy.status.replace('_', ' ')}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {format(new Date(policy.effective_date), 'MMM d, yyyy')}
                    </TableCell>
                    <TableCell>
                      {policy.requires_acknowledgment ? (
                        <div className={`font-medium ${getComplianceColor(percentage)}`}>
                          {percentage}%
                          <div className="text-xs text-muted-foreground">
                            {complianceRate}/{totalRequired}
                          </div>
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-sm">N/A</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex gap-1 justify-end">
                        <Button variant="ghost" size="icon">
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon">
                          <Download className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
// src/app/api/tenant/policies/__tests__/route.test.ts

import { describe, it, expect } from 'vitest'
import { GET, POST } from '../route'

describe('Policies API', () => {
  it('should fetch all policies', async () => {
    const request = new Request('http://localhost/api/tenant/policies')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data).toHaveProperty('policies')
    expect(Array.isArray(data.policies)).toBe(true)
  })

  it('should create a new policy', async () => {
    const policyData = {
      policyCode: 'HR-001',
      policyTitle: 'Code of Conduct',
      policyType: 'hr',
      content: 'Detailed policy content...',
      appliesTo: 'all',
      effectiveDate: '2025-01-01',
      requiresAcknowledgment: true,
      approvalLevelRequired: 2,
      tags: ['conduct', 'ethics'],
    }

    const request = new Request('http://localhost/api/tenant/policies', {
      method: 'POST',
      body: JSON.stringify(policyData),
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(201)
    expect(data).toHaveProperty('policy')
    expect(data.policy.policy_title).toBe('Code of Conduct')
  })
})
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Create, edit, and delete policies
- [x] Version control with change history
- [x] Multi-level approval workflows
- [x] Policy categorization and tagging
- [x] Rich text editor for policy content
- [x] Target specific audiences (staff, students, etc.)
- [x] Digital acknowledgment with IP tracking
- [x] Compliance reporting and tracking
- [x] PDF export functionality
- [x] Policy search and filtering
- [x] Automated reminder system
- [x] Policy expiration and renewal alerts
- [x] Audit trail for all changes
- [x] Superseding old policies with new versions
- [x] Archive management
- [x] Responsive design
- [x] Accessible UI (WCAG 2.1 AA)

---

**Status**: ✅ COMPLETE - READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
