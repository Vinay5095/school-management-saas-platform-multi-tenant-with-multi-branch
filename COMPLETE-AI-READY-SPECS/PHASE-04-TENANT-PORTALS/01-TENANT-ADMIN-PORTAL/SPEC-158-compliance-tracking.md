# SPEC-158: Compliance Tracking System
## Regulatory Compliance and Audit Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-151, SPEC-152, SPEC-156, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Comprehensive compliance tracking system to monitor regulatory requirements, certifications, licenses, audits, and compliance activities across all branches of the organization.

### Key Features
- ✅ Compliance requirement tracking
- ✅ License and certification management
- ✅ Expiration alerts and reminders
- ✅ Audit scheduling and tracking
- ✅ Compliance checklist management
- ✅ Document storage and verification
- ✅ Compliance dashboard and reporting
- ✅ Branch-wise compliance status
- ✅ Automated reminders
- ✅ Compliance history and logs
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Compliance requirements table
CREATE TABLE compliance_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  requirement_type TEXT NOT NULL CHECK (requirement_type IN ('license', 'certification', 'audit', 'inspection', 'documentation', 'training', 'policy', 'other')),
  category TEXT NOT NULL CHECK (category IN ('safety', 'health', 'education', 'financial', 'hr', 'data_protection', 'environmental', 'other')),
  regulatory_body TEXT,
  frequency TEXT CHECK (frequency IN ('one_time', 'monthly', 'quarterly', 'semi_annual', 'annual', 'biennial')),
  is_mandatory BOOLEAN DEFAULT true,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('organization', 'branches', 'specific_branches')),
  target_branches UUID[] DEFAULT ARRAY[]::UUID[],
  checklist JSONB DEFAULT '[]'::jsonb,
  required_documents TEXT[] DEFAULT ARRAY[]::TEXT[],
  metadata JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_compliance_req_tenant ON compliance_requirements(tenant_id);
CREATE INDEX idx_compliance_req_type ON compliance_requirements(requirement_type);
CREATE INDEX idx_compliance_req_category ON compliance_requirements(category);
CREATE INDEX idx_compliance_req_active ON compliance_requirements(is_active);

-- Compliance items table (specific instances)
CREATE TABLE compliance_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requirement_id UUID NOT NULL REFERENCES compliance_requirements(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'expired', 'non_compliant', 'not_applicable')) DEFAULT 'pending',
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  assigned_to UUID REFERENCES auth.users(id),
  issue_date DATE,
  expiry_date DATE,
  renewal_date DATE,
  last_audit_date DATE,
  next_audit_date DATE,
  certificate_number TEXT,
  issuing_authority TEXT,
  verification_status TEXT CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired')),
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMPTZ,
  notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_compliance_items_req ON compliance_items(requirement_id);
CREATE INDEX idx_compliance_items_tenant ON compliance_items(tenant_id);
CREATE INDEX idx_compliance_items_branch ON compliance_items(branch_id);
CREATE INDEX idx_compliance_items_status ON compliance_items(status);
CREATE INDEX idx_compliance_items_expiry ON compliance_items(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_compliance_items_next_audit ON compliance_items(next_audit_date) WHERE next_audit_date IS NOT NULL;

-- Compliance documents table
CREATE TABLE compliance_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  compliance_item_id UUID NOT NULL REFERENCES compliance_items(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  title TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  uploaded_by UUID REFERENCES auth.users(id),
  upload_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date DATE,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compliance_docs_item ON compliance_documents(compliance_item_id);
CREATE INDEX idx_compliance_docs_tenant ON compliance_documents(tenant_id);
CREATE INDEX idx_compliance_docs_expiry ON compliance_documents(expiry_date) WHERE expiry_date IS NOT NULL;

-- Compliance audits table
CREATE TABLE compliance_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
  audit_type TEXT NOT NULL CHECK (audit_type IN ('internal', 'external', 'regulatory', 'certification')),
  title TEXT NOT NULL,
  description TEXT,
  auditor_name TEXT,
  auditor_organization TEXT,
  audit_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')) DEFAULT 'scheduled',
  findings JSONB DEFAULT '[]'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,
  action_items JSONB DEFAULT '[]'::jsonb,
  overall_rating TEXT CHECK (overall_rating IN ('excellent', 'good', 'satisfactory', 'needs_improvement', 'non_compliant')),
  conducted_by UUID REFERENCES auth.users(id),
  report_file_path TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compliance_audits_tenant ON compliance_audits(tenant_id);
CREATE INDEX idx_compliance_audits_branch ON compliance_audits(branch_id);
CREATE INDEX idx_compliance_audits_date ON compliance_audits(audit_date DESC);
CREATE INDEX idx_compliance_audits_status ON compliance_audits(status);

-- Compliance reminders table
CREATE TABLE compliance_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  compliance_item_id UUID NOT NULL REFERENCES compliance_items(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('expiry', 'renewal', 'audit', 'submission', 'review')),
  reminder_date DATE NOT NULL,
  days_before INTEGER NOT NULL DEFAULT 30,
  status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'acknowledged', 'dismissed')) DEFAULT 'pending',
  recipients UUID[] NOT NULL,
  message TEXT,
  sent_at TIMESTAMPTZ,
  acknowledged_by UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compliance_reminders_item ON compliance_reminders(compliance_item_id);
CREATE INDEX idx_compliance_reminders_tenant ON compliance_reminders(tenant_id);
CREATE INDEX idx_compliance_reminders_date ON compliance_reminders(reminder_date);
CREATE INDEX idx_compliance_reminders_status ON compliance_reminders(status);

-- Compliance activity log
CREATE TABLE compliance_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  compliance_item_id UUID REFERENCES compliance_items(id) ON DELETE CASCADE,
  audit_id UUID REFERENCES compliance_audits(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  description TEXT NOT NULL,
  performed_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compliance_activity_tenant ON compliance_activity_log(tenant_id);
CREATE INDEX idx_compliance_activity_item ON compliance_activity_log(compliance_item_id);
CREATE INDEX idx_compliance_activity_date ON compliance_activity_log(created_at DESC);

-- Function to check expiring compliance items
CREATE OR REPLACE FUNCTION check_expiring_compliance_items(
  p_days_ahead INTEGER DEFAULT 30
)
RETURNS TABLE (
  item_id UUID,
  tenant_id UUID,
  branch_id UUID,
  title TEXT,
  expiry_date DATE,
  days_until_expiry INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ci.id,
    ci.tenant_id,
    ci.branch_id,
    ci.title,
    ci.expiry_date,
    (ci.expiry_date - CURRENT_DATE)::INTEGER as days_until_expiry
  FROM compliance_items ci
  WHERE ci.expiry_date IS NOT NULL
    AND ci.expiry_date <= CURRENT_DATE + p_days_ahead
    AND ci.status NOT IN ('expired', 'completed')
    AND ci.deleted_at IS NULL
  ORDER BY ci.expiry_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate compliance score
CREATE OR REPLACE FUNCTION calculate_compliance_score(
  p_tenant_id UUID,
  p_branch_id UUID DEFAULT NULL
)
RETURNS DECIMAL(5, 2) AS $$
DECLARE
  v_total_items INTEGER;
  v_compliant_items INTEGER;
  v_score DECIMAL(5, 2);
BEGIN
  IF p_branch_id IS NULL THEN
    -- Organization-wide score
    SELECT
      COUNT(*),
      COUNT(*) FILTER (WHERE status = 'completed')
    INTO v_total_items, v_compliant_items
    FROM compliance_items
    WHERE tenant_id = p_tenant_id
      AND deleted_at IS NULL;
  ELSE
    -- Branch-specific score
    SELECT
      COUNT(*),
      COUNT(*) FILTER (WHERE status = 'completed')
    INTO v_total_items, v_compliant_items
    FROM compliance_items
    WHERE tenant_id = p_tenant_id
      AND branch_id = p_branch_id
      AND deleted_at IS NULL;
  END IF;

  IF v_total_items = 0 THEN
    RETURN 0;
  END IF;

  v_score := (v_compliant_items::DECIMAL / v_total_items) * 100;
  
  RETURN v_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create compliance reminders
CREATE OR REPLACE FUNCTION create_compliance_reminders()
RETURNS void AS $$
DECLARE
  v_item RECORD;
  v_reminder_date DATE;
  v_recipients UUID[];
BEGIN
  FOR v_item IN
    SELECT *
    FROM compliance_items
    WHERE expiry_date IS NOT NULL
      AND status NOT IN ('expired', 'completed')
      AND deleted_at IS NULL
  LOOP
    -- Create reminder 30 days before expiry
    v_reminder_date := v_item.expiry_date - INTERVAL '30 days';
    
    IF v_reminder_date >= CURRENT_DATE AND NOT EXISTS (
      SELECT 1 FROM compliance_reminders
      WHERE compliance_item_id = v_item.id
        AND reminder_date = v_reminder_date
        AND reminder_type = 'expiry'
    ) THEN
      -- Get recipients (assigned user + tenant admins)
      SELECT ARRAY_AGG(DISTINCT user_id)
      INTO v_recipients
      FROM user_profiles
      WHERE tenant_id = v_item.tenant_id
        AND (role = 'tenant_admin' OR user_id = v_item.assigned_to);

      INSERT INTO compliance_reminders (
        compliance_item_id,
        tenant_id,
        reminder_type,
        reminder_date,
        days_before,
        recipients,
        message
      ) VALUES (
        v_item.id,
        v_item.tenant_id,
        'expiry',
        v_reminder_date,
        30,
        v_recipients,
        format('Compliance item "%s" will expire on %s', v_item.title, v_item.expiry_date)
      );
    END IF;

    -- Create reminder 7 days before expiry
    v_reminder_date := v_item.expiry_date - INTERVAL '7 days';
    
    IF v_reminder_date >= CURRENT_DATE AND NOT EXISTS (
      SELECT 1 FROM compliance_reminders
      WHERE compliance_item_id = v_item.id
        AND reminder_date = v_reminder_date
        AND reminder_type = 'expiry'
    ) THEN
      INSERT INTO compliance_reminders (
        compliance_item_id,
        tenant_id,
        reminder_type,
        reminder_date,
        days_before,
        recipients,
        message
      ) VALUES (
        v_item.id,
        v_item.tenant_id,
        'expiry',
        v_reminder_date,
        7,
        v_recipients,
        format('URGENT: Compliance item "%s" will expire on %s', v_item.title, v_item.expiry_date)
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule daily reminder creation
SELECT cron.schedule(
  'create-compliance-reminders',
  '0 6 * * *', -- Run at 6 AM daily
  'SELECT create_compliance_reminders()'
);

-- RLS Policies
ALTER TABLE compliance_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_activity_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_admin_compliance_requirements ON compliance_requirements
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_compliance_items ON compliance_items
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_compliance_documents ON compliance_documents
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_compliance_audits ON compliance_audits
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_compliance_reminders ON compliance_reminders
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_compliance_activity ON compliance_activity_log
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/compliance.ts

export interface ComplianceRequirement {
  id: string
  tenantId: string
  title: string
  description?: string
  requirementType: 'license' | 'certification' | 'audit' | 'inspection' | 'documentation' | 'training' | 'policy' | 'other'
  category: 'safety' | 'health' | 'education' | 'financial' | 'hr' | 'data_protection' | 'environmental' | 'other'
  regulatoryBody?: string
  frequency?: 'one_time' | 'monthly' | 'quarterly' | 'semi_annual' | 'annual' | 'biennial'
  isMandatory: boolean
  appliesTo: 'organization' | 'branches' | 'specific_branches'
  targetBranches?: string[]
  checklist?: Array<{ item: string; completed: boolean }>
  requiredDocuments?: string[]
  metadata?: Record<string, any>
  isActive: boolean
  createdAt: string
  updatedAt: string
}

export interface ComplianceItem {
  id: string
  requirementId: string
  tenantId: string
  branchId?: string
  title: string
  description?: string
  status: 'pending' | 'in_progress' | 'completed' | 'expired' | 'non_compliant' | 'not_applicable'
  priority: 'low' | 'medium' | 'high' | 'critical'
  assignedTo?: string
  issueDate?: string
  expiryDate?: string
  renewalDate?: string
  lastAuditDate?: string
  nextAuditDate?: string
  certificateNumber?: string
  issuingAuthority?: string
  verificationStatus?: 'pending' | 'verified' | 'rejected' | 'expired'
  verifiedBy?: string
  verifiedAt?: string
  notes?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface ComplianceAudit {
  id: string
  tenantId: string
  branchId?: string
  auditType: 'internal' | 'external' | 'regulatory' | 'certification'
  title: string
  description?: string
  auditorName?: string
  auditorOrganization?: string
  auditDate: string
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled'
  findings?: Array<{ finding: string; severity: string }>
  recommendations?: Array<{ recommendation: string; priority: string }>
  actionItems?: Array<{ action: string; assignedTo: string; dueDate: string }>
  overallRating?: 'excellent' | 'good' | 'satisfactory' | 'needs_improvement' | 'non_compliant'
  conductedBy?: string
  reportFilePath?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface ComplianceDashboardData {
  overallScore: number
  branchScores: Array<{
    branchId: string
    branchName: string
    score: number
  }>
  expiringItems: ComplianceItem[]
  upcomingAudits: ComplianceAudit[]
  statusBreakdown: {
    pending: number
    inProgress: number
    completed: number
    expired: number
    nonCompliant: number
  }
  categoryBreakdown: Array<{
    category: string
    total: number
    completed: number
    percentage: number
  }>
}
```

### API Routes

```typescript
// src/app/api/tenant/compliance/dashboard/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

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
    // Calculate overall compliance score
    const { data: overallScore } = await supabase.rpc(
      'calculate_compliance_score',
      { p_tenant_id: profile.tenant_id }
    )

    // Get branch-wise scores
    const { data: branches } = await supabase
      .from('branches')
      .select('id, name')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'active')

    const branchScores = await Promise.all(
      branches?.map(async (branch) => {
        const { data: score } = await supabase.rpc(
          'calculate_compliance_score',
          { 
            p_tenant_id: profile.tenant_id,
            p_branch_id: branch.id 
          }
        )
        return {
          branchId: branch.id,
          branchName: branch.name,
          score: score || 0,
        }
      }) || []
    )

    // Get expiring items (next 30 days)
    const { data: expiringItems } = await supabase.rpc(
      'check_expiring_compliance_items',
      { p_days_ahead: 30 }
    )

    // Get upcoming audits
    const { data: upcomingAudits } = await supabase
      .from('compliance_audits')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .gte('audit_date', new Date().toISOString().split('T')[0])
      .eq('status', 'scheduled')
      .order('audit_date', { ascending: true })
      .limit(10)

    // Get status breakdown
    const { data: statusBreakdown } = await supabase
      .from('compliance_items')
      .select('status')
      .eq('tenant_id', profile.tenant_id)
      .is('deleted_at', null)

    const statusCounts = statusBreakdown?.reduce((acc, item) => {
      acc[item.status] = (acc[item.status] || 0) + 1
      return acc
    }, {} as Record<string, number>)

    // Get category breakdown
    const { data: categoryData } = await supabase
      .from('compliance_items')
      .select(`
        requirement:compliance_requirements (
          category
        ),
        status
      `)
      .eq('tenant_id', profile.tenant_id)
      .is('deleted_at', null)

    const categoryBreakdown = categoryData?.reduce((acc: any[], item: any) => {
      const category = item.requirement?.category || 'other'
      let cat = acc.find(c => c.category === category)
      if (!cat) {
        cat = { category, total: 0, completed: 0, percentage: 0 }
        acc.push(cat)
      }
      cat.total++
      if (item.status === 'completed') {
        cat.completed++
      }
      cat.percentage = (cat.completed / cat.total) * 100
      return acc
    }, [])

    return NextResponse.json({
      overallScore: overallScore || 0,
      branchScores,
      expiringItems: expiringItems || [],
      upcomingAudits: upcomingAudits || [],
      statusBreakdown: {
        pending: statusCounts?.pending || 0,
        inProgress: statusCounts?.in_progress || 0,
        completed: statusCounts?.completed || 0,
        expired: statusCounts?.expired || 0,
        nonCompliant: statusCounts?.non_compliant || 0,
      },
      categoryBreakdown: categoryBreakdown || [],
    })

  } catch (error) {
    console.error('Failed to fetch compliance dashboard:', error)
    return NextResponse.json(
      { error: 'Failed to fetch compliance dashboard' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/compliance/items/route.ts

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

  const status = searchParams.get('status')
  const branchId = searchParams.get('branch_id')
  const priority = searchParams.get('priority')

  try {
    let query = supabase
      .from('compliance_items')
      .select(`
        *,
        requirement:compliance_requirements (*),
        branch:branches (id, name),
        assignedUser:auth.users!assigned_to (id, email, user_metadata),
        documents:compliance_documents (count)
      `)
      .eq('tenant_id', profile.tenant_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })

    if (status) query = query.eq('status', status)
    if (branchId) query = query.eq('branch_id', branchId)
    if (priority) query = query.eq('priority', priority)

    const { data: items, error } = await query

    if (error) throw error

    return NextResponse.json({ items })

  } catch (error) {
    console.error('Failed to fetch compliance items:', error)
    return NextResponse.json(
      { error: 'Failed to fetch compliance items' },
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

    const { data: item, error } = await supabase
      .from('compliance_items')
      .insert({
        ...body,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single()

    if (error) throw error

    // Log activity
    await supabase
      .from('compliance_activity_log')
      .insert({
        tenant_id: profile.tenant_id,
        compliance_item_id: item.id,
        activity_type: 'created',
        description: `Compliance item "${item.title}" created`,
        performed_by: user.id,
      })

    return NextResponse.json({ item }, { status: 201 })

  } catch (error) {
    console.error('Failed to create compliance item:', error)
    return NextResponse.json(
      { error: 'Failed to create compliance item' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Compliance Dashboard Page

```typescript
// src/app/tenant/compliance/page.tsx

'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  Shield, AlertTriangle, CheckCircle, Clock, 
  FileCheck, TrendingUp, Plus 
} from 'lucide-react'
import { ComplianceItemsList } from '@/components/compliance/items-list'
import { ComplianceScoreCard } from '@/components/compliance/score-card'
import { ExpiringItemsAlert } from '@/components/compliance/expiring-items-alert'

export default function ComplianceDashboard() {
  const { data, isLoading } = useQuery({
    queryKey: ['compliance-dashboard'],
    queryFn: async () => {
      const res = await fetch('/api/tenant/compliance/dashboard')
      if (!res.ok) throw new Error('Failed to fetch data')
      return res.json()
    },
  })

  if (isLoading) {
    return <div>Loading...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Compliance Tracking</h1>
          <p className="text-muted-foreground">
            Monitor regulatory compliance across all branches
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Add Compliance Item
        </Button>
      </div>

      {/* Overall Score */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Overall Compliance Score
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-4xl font-bold">
                {data.overallScore.toFixed(1)}%
              </span>
              <Badge variant={data.overallScore >= 90 ? 'success' : 'warning'}>
                {data.overallScore >= 90 ? 'Compliant' : 'Needs Attention'}
              </Badge>
            </div>
            <Progress value={data.overallScore} className="h-3" />
          </div>
        </CardContent>
      </Card>

      {/* Expiring Items Alert */}
      {data.expiringItems.length > 0 && (
        <ExpiringItemsAlert items={data.expiringItems} />
      )}

      {/* Status Overview */}
      <div className="grid gap-4 md:grid-cols-5">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Completed</p>
                <p className="text-2xl font-bold text-green-600">
                  {data.statusBreakdown.completed}
                </p>
              </div>
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">In Progress</p>
                <p className="text-2xl font-bold text-blue-600">
                  {data.statusBreakdown.inProgress}
                </p>
              </div>
              <Clock className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Pending</p>
                <p className="text-2xl font-bold text-yellow-600">
                  {data.statusBreakdown.pending}
                </p>
              </div>
              <FileCheck className="h-8 w-8 text-yellow-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Expired</p>
                <p className="text-2xl font-bold text-red-600">
                  {data.statusBreakdown.expired}
                </p>
              </div>
              <AlertTriangle className="h-8 w-8 text-red-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Non-Compliant</p>
                <p className="text-2xl font-bold text-red-600">
                  {data.statusBreakdown.nonCompliant}
                </p>
              </div>
              <AlertTriangle className="h-8 w-8 text-red-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Branch Scores */}
      <Card>
        <CardHeader>
          <CardTitle>Branch Compliance Scores</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {data.branchScores.map((branch: any) => (
              <div key={branch.branchId} className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium">{branch.branchName}</span>
                  <span className="text-sm font-semibold">
                    {branch.score.toFixed(1)}%
                  </span>
                </div>
                <Progress value={branch.score} className="h-2" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Category Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle>Compliance by Category</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {data.categoryBreakdown.map((cat: any) => (
              <div key={cat.category} className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="capitalize">{cat.category.replace('_', ' ')}</span>
                  <span className="text-sm">
                    {cat.completed}/{cat.total} ({cat.percentage.toFixed(0)}%)
                  </span>
                </div>
                <Progress value={cat.percentage} className="h-2" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Upcoming Audits */}
      {data.upcomingAudits.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Upcoming Audits</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {data.upcomingAudits.map((audit: any) => (
                <div 
                  key={audit.id}
                  className="flex items-center justify-between p-3 border rounded-lg"
                >
                  <div>
                    <p className="font-medium">{audit.title}</p>
                    <p className="text-sm text-muted-foreground">
                      {new Date(audit.auditDate).toLocaleDateString()}
                    </p>
                  </div>
                  <Badge>{audit.auditType}</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Track compliance requirements and items
- [x] Monitor licenses and certifications
- [x] Alert on expiring items
- [x] Manage audits and findings
- [x] Calculate compliance scores
- [x] Branch-wise compliance tracking
- [x] Document management
- [x] Automated reminders
- [x] Activity logging
- [x] Comprehensive reporting
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
