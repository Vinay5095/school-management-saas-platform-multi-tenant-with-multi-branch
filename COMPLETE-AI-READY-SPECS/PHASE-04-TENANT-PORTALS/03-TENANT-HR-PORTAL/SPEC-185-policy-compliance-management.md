# SPEC-185: Policy & Compliance Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-185  
**Title**: HR Policy & Compliance Management  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Policy & Compliance  
**Priority**: MEDIUM  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-179  

---

## 📋 DESCRIPTION

Comprehensive policy and compliance management system with policy library, document version control, employee acknowledgments, compliance tracking, audit trails, policy distribution, periodic reviews, and regulatory compliance reporting.

---

## 🎯 SUCCESS CRITERIA

- [ ] Policy library operational
- [ ] Version control working
- [ ] Acknowledgments tracked
- [ ] Compliance monitoring functional
- [ ] Audit trails complete
- [ ] Distribution automated
- [ ] Analytics available
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Policy Categories
CREATE TABLE IF NOT EXISTS policy_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Category details
  category_name VARCHAR(100) NOT NULL,
  category_code VARCHAR(20) NOT NULL,
  
  -- Description
  description TEXT,
  
  -- Display
  display_order INTEGER,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, category_code)
);

CREATE INDEX ON policy_categories(tenant_id);

-- Policy Documents
CREATE TABLE IF NOT EXISTS policy_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  category_id UUID REFERENCES policy_categories(id),
  
  -- Document details
  policy_name VARCHAR(200) NOT NULL,
  policy_code VARCHAR(50) UNIQUE NOT NULL,
  
  -- Version
  version_number VARCHAR(20) NOT NULL,
  version_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Content
  description TEXT,
  policy_content TEXT,
  
  -- File
  document_url TEXT NOT NULL,
  document_size_bytes BIGINT,
  
  -- Applicability
  applicable_to VARCHAR(50) DEFAULT 'all', -- all, department, branch, role
  applicable_departments VARCHAR(100)[],
  applicable_branches UUID[],
  applicable_roles VARCHAR(100)[],
  
  -- Effective dates
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Review
  review_frequency_months INTEGER,
  next_review_date DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, published, archived, superseded
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Owner
  policy_owner_id UUID REFERENCES auth.users(id),
  
  -- Requirements
  requires_acknowledgment BOOLEAN DEFAULT true,
  is_mandatory BOOLEAN DEFAULT true,
  
  -- Parent (for versioning)
  supersedes_policy_id UUID REFERENCES policy_documents(id),
  
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'published', 'archived', 'superseded'))
);

CREATE INDEX ON policy_documents(tenant_id, status);
CREATE INDEX ON policy_documents(category_id);
CREATE INDEX ON policy_documents(effective_from, effective_to);

-- Employee Policy Acknowledgments
CREATE TABLE IF NOT EXISTS employee_policy_acknowledgments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID NOT NULL REFERENCES policy_documents(id),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Acknowledgment details
  acknowledged_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  acknowledgment_type VARCHAR(50) DEFAULT 'digital', -- digital, physical, training
  
  -- Digital signature
  ip_address VARCHAR(50),
  device_info TEXT,
  
  -- Confirmation
  confirmed_read BOOLEAN DEFAULT true,
  confirmed_understood BOOLEAN DEFAULT true,
  confirmed_comply BOOLEAN DEFAULT true,
  
  -- Additional
  comments TEXT,
  certificate_url TEXT,
  
  -- Reminder
  reminder_sent_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(policy_id, employee_id)
);

CREATE INDEX ON employee_policy_acknowledgments(policy_id);
CREATE INDEX ON employee_policy_acknowledgments(employee_id);

-- Compliance Requirements
CREATE TABLE IF NOT EXISTS compliance_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Requirement details
  requirement_name VARCHAR(200) NOT NULL,
  requirement_code VARCHAR(50) NOT NULL,
  
  -- Type
  requirement_type VARCHAR(50), -- statutory, regulatory, internal, industry_standard
  
  -- Description
  description TEXT,
  compliance_criteria TEXT,
  
  -- Authority
  regulatory_body VARCHAR(200),
  regulation_reference VARCHAR(200),
  
  -- Frequency
  compliance_frequency VARCHAR(50), -- one_time, monthly, quarterly, annual, continuous
  
  -- Dates
  effective_from DATE NOT NULL,
  effective_to DATE,
  next_compliance_date DATE,
  
  -- Responsibility
  responsible_person_id UUID REFERENCES auth.users(id),
  responsible_department VARCHAR(100),
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, inactive, under_review
  
  -- Penalties
  non_compliance_penalty TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, requirement_code)
);

CREATE INDEX ON compliance_requirements(tenant_id, status);

-- Compliance Tracking
CREATE TABLE IF NOT EXISTS compliance_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requirement_id UUID NOT NULL REFERENCES compliance_requirements(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Tracking period
  compliance_period_start DATE NOT NULL,
  compliance_period_end DATE NOT NULL,
  
  -- Status
  compliance_status VARCHAR(50) DEFAULT 'pending', -- pending, compliant, non_compliant, partially_compliant, in_progress
  
  -- Evidence
  evidence_documents JSONB,
  evidence_description TEXT,
  
  -- Verification
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  verification_notes TEXT,
  
  -- Issues
  issues_identified TEXT,
  corrective_actions TEXT,
  
  -- Due date
  due_date DATE,
  completed_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (compliance_status IN ('pending', 'compliant', 'non_compliant', 'partially_compliant', 'in_progress'))
);

CREATE INDEX ON compliance_tracking(requirement_id);
CREATE INDEX ON compliance_tracking(tenant_id, compliance_status);

-- Policy Audit Log
CREATE TABLE IF NOT EXISTS policy_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID REFERENCES policy_documents(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Action details
  action_type VARCHAR(50) NOT NULL, -- created, updated, published, acknowledged, archived, viewed
  action_description TEXT,
  
  -- Actor
  performed_by UUID REFERENCES auth.users(id),
  performer_name VARCHAR(200),
  performer_role VARCHAR(100),
  
  -- Context
  ip_address VARCHAR(50),
  user_agent TEXT,
  
  -- Changes (for updates)
  changes_made JSONB,
  previous_values JSONB,
  
  performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON policy_audit_log(policy_id);
CREATE INDEX ON policy_audit_log(tenant_id, performed_at);

-- Compliance Reports
CREATE TABLE IF NOT EXISTS compliance_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Report details
  report_name VARCHAR(200) NOT NULL,
  report_type VARCHAR(50), -- periodic, ad_hoc, regulatory
  
  -- Period
  report_period_start DATE NOT NULL,
  report_period_end DATE NOT NULL,
  
  -- Content
  report_summary TEXT,
  findings JSONB,
  recommendations TEXT,
  
  -- File
  report_url TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, final, submitted
  
  -- Submission
  submitted_to VARCHAR(200),
  submitted_at TIMESTAMP WITH TIME ZONE,
  
  -- Generated
  generated_by UUID REFERENCES auth.users(id),
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'final', 'submitted'))
);

CREATE INDEX ON compliance_reports(tenant_id);

-- Function to get policy acknowledgment status
CREATE OR REPLACE FUNCTION get_policy_acknowledgment_status(
  p_tenant_id UUID,
  p_policy_id UUID DEFAULT NULL
)
RETURNS TABLE (
  policy_id UUID,
  policy_name VARCHAR,
  total_employees BIGINT,
  acknowledged_count BIGINT,
  pending_count BIGINT,
  acknowledgment_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pd.id,
    pd.policy_name,
    COUNT(DISTINCT s.id) as total_employees,
    COUNT(DISTINCT epa.employee_id) as acknowledged_count,
    COUNT(DISTINCT s.id) - COUNT(DISTINCT epa.employee_id) as pending_count,
    CASE 
      WHEN COUNT(DISTINCT s.id) = 0 THEN 0
      ELSE ROUND((COUNT(DISTINCT epa.employee_id)::NUMERIC / COUNT(DISTINCT s.id)) * 100, 2)
    END as acknowledgment_percentage
  FROM policy_documents pd
  CROSS JOIN staff s
  LEFT JOIN employee_policy_acknowledgments epa ON epa.policy_id = pd.id AND epa.employee_id = s.id
  WHERE pd.tenant_id = p_tenant_id
  AND s.tenant_id = p_tenant_id
  AND s.status = 'active'
  AND pd.status = 'published'
  AND pd.requires_acknowledgment = true
  AND (p_policy_id IS NULL OR pd.id = p_policy_id)
  GROUP BY pd.id, pd.policy_name
  ORDER BY acknowledgment_percentage ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to check compliance status
CREATE OR REPLACE FUNCTION get_compliance_summary(
  p_tenant_id UUID
)
RETURNS TABLE (
  total_requirements BIGINT,
  compliant_count BIGINT,
  non_compliant_count BIGINT,
  pending_count BIGINT,
  compliance_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH latest_compliance AS (
    SELECT DISTINCT ON (requirement_id)
      requirement_id,
      compliance_status
    FROM compliance_tracking
    WHERE tenant_id = p_tenant_id
    ORDER BY requirement_id, compliance_period_end DESC
  )
  SELECT
    COUNT(*) as total_requirements,
    COUNT(CASE WHEN lc.compliance_status = 'compliant' THEN 1 END) as compliant_count,
    COUNT(CASE WHEN lc.compliance_status = 'non_compliant' THEN 1 END) as non_compliant_count,
    COUNT(CASE WHEN lc.compliance_status IN ('pending', 'in_progress') THEN 1 END) as pending_count,
    CASE 
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND((COUNT(CASE WHEN lc.compliance_status = 'compliant' THEN 1 END)::NUMERIC / COUNT(*)) * 100, 2)
    END as compliance_rate
  FROM compliance_requirements cr
  LEFT JOIN latest_compliance lc ON lc.requirement_id = cr.id
  WHERE cr.tenant_id = p_tenant_id
  AND cr.status = 'active';
END;
$$ LANGUAGE plpgsql;

-- Trigger to log policy actions
CREATE OR REPLACE FUNCTION log_policy_action()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO policy_audit_log (
      policy_id,
      tenant_id,
      action_type,
      action_description,
      changes_made
    ) VALUES (
      NEW.id,
      NEW.tenant_id,
      'created',
      'Policy document created',
      row_to_json(NEW)
    );
  ELSIF TG_OP = 'UPDATE' AND NEW.status = 'published' AND OLD.status != 'published' THEN
    INSERT INTO policy_audit_log (
      policy_id,
      tenant_id,
      action_type,
      action_description
    ) VALUES (
      NEW.id,
      NEW.tenant_id,
      'published',
      'Policy document published'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_policy_changes
  AFTER INSERT OR UPDATE ON policy_documents
  FOR EACH ROW
  EXECUTE FUNCTION log_policy_action();

-- Enable RLS
ALTER TABLE policy_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_policy_acknowledgments ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_reports ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/policy-compliance.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface PolicyDocument {
  id: string;
  policyName: string;
  policyCode: string;
  versionNumber: string;
  status: string;
  effectiveFrom: string;
  requiresAcknowledgment: boolean;
}

export interface ComplianceRequirement {
  id: string;
  requirementName: string;
  requirementType: string;
  complianceFrequency: string;
  nextComplianceDate: string;
  status: string;
}

export class PolicyComplianceAPI {
  private supabase = createClient();

  async createPolicyDocument(params: {
    tenantId: string;
    categoryId: string;
    policyName: string;
    versionNumber: string;
    policyContent: string;
    documentFile: File;
    effectiveFrom: Date;
    requiresAcknowledgment?: boolean;
  }): Promise<PolicyDocument> {
    const policyCode = `POL-${Date.now()}`;

    // Upload document
    const filePath = `policies/${params.tenantId}/${Date.now()}_${params.documentFile.name}`;
    const { error: uploadError } = await this.supabase.storage
      .from('hr-documents')
      .upload(filePath, params.documentFile);

    if (uploadError) throw uploadError;

    const { data: urlData } = this.supabase.storage
      .from('hr-documents')
      .getPublicUrl(filePath);

    // Create policy record
    const { data, error } = await this.supabase
      .from('policy_documents')
      .insert({
        tenant_id: params.tenantId,
        category_id: params.categoryId,
        policy_name: params.policyName,
        policy_code: policyCode,
        version_number: params.versionNumber,
        policy_content: params.policyContent,
        document_url: urlData.publicUrl,
        document_size_bytes: params.documentFile.size,
        effective_from: params.effectiveFrom.toISOString().split('T')[0],
        requires_acknowledgment: params.requiresAcknowledgment !== false,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      policyName: data.policy_name,
      policyCode: data.policy_code,
      versionNumber: data.version_number,
      status: data.status,
      effectiveFrom: data.effective_from,
      requiresAcknowledgment: data.requires_acknowledgment,
    };
  }

  async publishPolicy(policyId: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('policy_documents')
      .update({
        status: 'published',
        approved_by: user?.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', policyId);

    if (error) throw error;
  }

  async acknowledgePolicy(params: {
    policyId: string;
    employeeId: string;
    tenantId: string;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('employee_policy_acknowledgments')
      .insert({
        policy_id: params.policyId,
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        acknowledged_at: new Date().toISOString(),
        confirmed_read: true,
        confirmed_understood: true,
        confirmed_comply: true,
      });

    if (error) throw error;
  }

  async getPendingPolicies(employeeId: string) {
    const { data, error } = await this.supabase
      .from('policy_documents')
      .select('*')
      .eq('status', 'published')
      .eq('requires_acknowledgment', true)
      .not(
        'id',
        'in',
        `(SELECT policy_id FROM employee_policy_acknowledgments WHERE employee_id = '${employeeId}')`
      );

    if (error) throw error;

    return (data || []).map(policy => ({
      id: policy.id,
      policyName: policy.policy_name,
      policyCode: policy.policy_code,
      versionNumber: policy.version_number,
      effectiveFrom: policy.effective_from,
      documentUrl: policy.document_url,
    }));
  }

  async getPolicyAcknowledgmentStatus(params: {
    tenantId: string;
    policyId?: string;
  }) {
    const { data, error } = await this.supabase.rpc(
      'get_policy_acknowledgment_status',
      {
        p_tenant_id: params.tenantId,
        p_policy_id: params.policyId,
      }
    );

    if (error) throw error;

    return data.map((item: any) => ({
      policyId: item.policy_id,
      policyName: item.policy_name,
      totalEmployees: item.total_employees,
      acknowledgedCount: item.acknowledged_count,
      pendingCount: item.pending_count,
      acknowledgmentPercentage: item.acknowledgment_percentage,
    }));
  }

  async createComplianceRequirement(params: {
    tenantId: string;
    requirementName: string;
    requirementType: string;
    description: string;
    complianceFrequency: string;
    effectiveFrom: Date;
    regulatoryBody?: string;
    responsiblePersonId?: string;
  }): Promise<ComplianceRequirement> {
    const requirementCode = `COMP-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('compliance_requirements')
      .insert({
        tenant_id: params.tenantId,
        requirement_name: params.requirementName,
        requirement_code: requirementCode,
        requirement_type: params.requirementType,
        description: params.description,
        compliance_frequency: params.complianceFrequency,
        effective_from: params.effectiveFrom.toISOString().split('T')[0],
        regulatory_body: params.regulatoryBody,
        responsible_person_id: params.responsiblePersonId,
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      requirementName: data.requirement_name,
      requirementType: data.requirement_type,
      complianceFrequency: data.compliance_frequency,
      nextComplianceDate: data.next_compliance_date,
      status: data.status,
    };
  }

  async recordComplianceTracking(params: {
    requirementId: string;
    tenantId: string;
    compliancePeriodStart: Date;
    compliancePeriodEnd: Date;
    complianceStatus: string;
    evidenceDescription?: string;
    issuesIdentified?: string;
  }) {
    const { data, error } = await this.supabase
      .from('compliance_tracking')
      .insert({
        requirement_id: params.requirementId,
        tenant_id: params.tenantId,
        compliance_period_start: params.compliancePeriodStart
          .toISOString()
          .split('T')[0],
        compliance_period_end: params.compliancePeriodEnd
          .toISOString()
          .split('T')[0],
        compliance_status: params.complianceStatus,
        evidence_description: params.evidenceDescription,
        issues_identified: params.issuesIdentified,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getComplianceSummary(tenantId: string) {
    const { data, error } = await this.supabase.rpc('get_compliance_summary', {
      p_tenant_id: tenantId,
    });

    if (error) throw error;

    return {
      totalRequirements: data[0].total_requirements,
      compliantCount: data[0].compliant_count,
      nonCompliantCount: data[0].non_compliant_count,
      pendingCount: data[0].pending_count,
      complianceRate: data[0].compliance_rate,
    };
  }

  async generateComplianceReport(params: {
    tenantId: string;
    reportName: string;
    reportType: string;
    periodStart: Date;
    periodEnd: Date;
    reportSummary: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('compliance_reports')
      .insert({
        tenant_id: params.tenantId,
        report_name: params.reportName,
        report_type: params.reportType,
        report_period_start: params.periodStart.toISOString().split('T')[0],
        report_period_end: params.periodEnd.toISOString().split('T')[0],
        report_summary: params.reportSummary,
        status: 'draft',
        generated_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getPolicyAuditLog(params: {
    policyId?: string;
    tenantId: string;
    startDate?: Date;
    endDate?: Date;
  }) {
    let query = this.supabase
      .from('policy_audit_log')
      .select('*')
      .eq('tenant_id', params.tenantId);

    if (params.policyId) {
      query = query.eq('policy_id', params.policyId);
    }

    if (params.startDate) {
      query = query.gte('performed_at', params.startDate.toISOString());
    }

    if (params.endDate) {
      query = query.lte('performed_at', params.endDate.toISOString());
    }

    const { data, error } = await query.order('performed_at', {
      ascending: false,
    });

    if (error) throw error;

    return data.map(log => ({
      id: log.id,
      actionType: log.action_type,
      actionDescription: log.action_description,
      performerName: log.performer_name,
      performedAt: log.performed_at,
    }));
  }
}

export const policyComplianceAPI = new PolicyComplianceAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { PolicyComplianceAPI } from '../policy-compliance';

describe('PolicyComplianceAPI', () => {
  it('retrieves compliance summary', async () => {
    const api = new PolicyComplianceAPI();
    const summary = await api.getComplianceSummary('test-tenant');

    expect(summary).toHaveProperty('complianceRate');
    expect(summary).toHaveProperty('totalRequirements');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Policy library operational
- [ ] Version control working
- [ ] Acknowledgments tracked
- [ ] Compliance monitoring functional
- [ ] Audit trails complete
- [ ] Reports generated
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-186 (IT Portal - System Integrations)  
**Time**: 4 hours  
**AI-Ready**: 100%
