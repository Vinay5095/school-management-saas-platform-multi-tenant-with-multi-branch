# SPEC-203: Discipline Case Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-203  
**Title**: Discipline Case Management System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Student Discipline  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-194  

---

## 📋 DESCRIPTION

Comprehensive discipline case investigation and management system for vice principals to handle student behavior incidents, collect evidence, record witness statements, coordinate with teachers/parents, and escalate cases to principal when necessary.

---

## 🎯 SUCCESS CRITERIA

- [ ] Investigation workflow operational
- [ ] Evidence collection functioning
- [ ] Witness statements recording
- [ ] Case escalation working
- [ ] Parent communication tracking
- [ ] Document management functional
- [ ] Reporting capabilities working
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Discipline Investigations
CREATE TABLE IF NOT EXISTS discipline_investigations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  discipline_case_id UUID NOT NULL REFERENCES discipline_cases(id),
  case_number VARCHAR(50),
  
  investigation_status VARCHAR(50) DEFAULT 'initiated', -- initiated, in_progress, evidence_collected, completed, closed
  
  investigator_id UUID NOT NULL REFERENCES staff(id), -- usually VP
  investigation_start_date DATE DEFAULT CURRENT_DATE,
  investigation_end_date DATE,
  
  -- Evidence collection
  evidence_collected JSONB DEFAULT '[]', -- [{type, description, file_url, collected_date, collected_by}]
  evidence_summary TEXT,
  
  -- Witness statements
  witness_statements JSONB DEFAULT '[]', -- [{witness_name, witness_type (student/staff/parent), statement, recorded_date, recorded_by}]
  
  -- Investigation findings
  findings TEXT,
  severity_assessment VARCHAR(50), -- minor, moderate, serious, severe
  recommended_action TEXT,
  
  -- Actions taken
  action_taken TEXT,
  counseling_provided BOOLEAN DEFAULT false,
  counseling_notes TEXT,
  
  -- Escalation
  escalated_to_principal BOOLEAN DEFAULT false,
  escalation_date DATE,
  escalation_reason TEXT,
  principal_decision TEXT,
  
  -- Parent involvement
  parent_contacted BOOLEAN DEFAULT false,
  parent_contact_date DATE,
  parent_response TEXT,
  parent_meeting_scheduled BOOLEAN DEFAULT false,
  parent_meeting_date DATE,
  
  -- Follow-up
  follow_up_required BOOLEAN DEFAULT false,
  follow_up_date DATE,
  follow_up_notes TEXT,
  
  -- Closure
  case_closed BOOLEAN DEFAULT false,
  closure_date DATE,
  closure_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON discipline_investigations(tenant_id, branch_id);
CREATE INDEX ON discipline_investigations(discipline_case_id);
CREATE INDEX ON discipline_investigations(investigator_id, investigation_status);
CREATE INDEX ON discipline_investigations(investigation_start_date);

-- Investigation Evidence Files
CREATE TABLE IF NOT EXISTS investigation_evidence_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  investigation_id UUID NOT NULL REFERENCES discipline_investigations(id),
  
  file_type VARCHAR(50), -- photo, video, document, audio_recording, written_statement
  file_name VARCHAR(200),
  file_url TEXT,
  file_size_kb INTEGER,
  
  description TEXT,
  
  collected_by UUID REFERENCES staff(id),
  collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES staff(id),
  verified_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX ON investigation_evidence_files(investigation_id);
CREATE INDEX ON investigation_evidence_files(tenant_id, branch_id);

-- Witness Statements
CREATE TABLE IF NOT EXISTS discipline_witness_statements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  investigation_id UUID NOT NULL REFERENCES discipline_investigations(id),
  discipline_case_id UUID NOT NULL REFERENCES discipline_cases(id),
  
  witness_type VARCHAR(50), -- student, staff, parent, security_guard, other
  witness_id UUID, -- student_id or staff_id if applicable
  witness_name VARCHAR(200),
  witness_contact TEXT,
  
  statement_date DATE DEFAULT CURRENT_DATE,
  statement_time TIME,
  
  statement_text TEXT NOT NULL,
  statement_method VARCHAR(50), -- written, verbal_recorded, interview
  
  recorded_by UUID NOT NULL REFERENCES staff(id),
  
  verified BOOLEAN DEFAULT false,
  signature_url TEXT, -- digital signature or scanned signature
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON discipline_witness_statements(investigation_id);
CREATE INDEX ON discipline_witness_statements(discipline_case_id);
CREATE INDEX ON discipline_witness_statements(witness_type, witness_id);

-- Investigation Timeline
CREATE TABLE IF NOT EXISTS investigation_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  investigation_id UUID NOT NULL REFERENCES discipline_investigations(id),
  
  event_type VARCHAR(100), -- evidence_collected, witness_interviewed, parent_contacted, action_taken, escalated, follow_up
  event_description TEXT,
  event_date DATE DEFAULT CURRENT_DATE,
  event_time TIME DEFAULT CURRENT_TIME,
  
  performed_by UUID REFERENCES staff(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON investigation_timeline(investigation_id, event_date DESC);

-- Investigation Statistics View
CREATE MATERIALIZED VIEW vp_investigation_stats AS
SELECT
  i.tenant_id,
  i.branch_id,
  i.investigator_id,
  
  DATE_TRUNC('month', i.investigation_start_date) as month,
  
  COUNT(*) as total_investigations,
  COUNT(CASE WHEN i.investigation_status = 'completed' THEN 1 END) as completed_investigations,
  COUNT(CASE WHEN i.escalated_to_principal THEN 1 END) as escalated_cases,
  COUNT(CASE WHEN i.case_closed THEN 1 END) as closed_cases,
  
  AVG(CASE WHEN i.investigation_end_date IS NOT NULL 
    THEN EXTRACT(DAY FROM (i.investigation_end_date - i.investigation_start_date)) 
    END) as avg_investigation_days,
  
  COUNT(CASE WHEN i.parent_contacted THEN 1 END) as cases_with_parent_contact,
  COUNT(CASE WHEN i.counseling_provided THEN 1 END) as cases_with_counseling,
  
  NOW() as last_calculated_at
  
FROM discipline_investigations i
GROUP BY i.tenant_id, i.branch_id, i.investigator_id, DATE_TRUNC('month', i.investigation_start_date);

CREATE INDEX ON vp_investigation_stats(tenant_id, branch_id, month DESC);

-- Auto-update trigger
CREATE OR REPLACE FUNCTION update_investigation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER investigation_update_trigger
  BEFORE UPDATE ON discipline_investigations
  FOR EACH ROW
  EXECUTE FUNCTION update_investigation_timestamp();

-- Enable RLS
ALTER TABLE discipline_investigations ENABLE ROW LEVEL SECURITY;
ALTER TABLE investigation_evidence_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_witness_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE investigation_timeline ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY discipline_investigations_isolation ON discipline_investigations
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY investigation_evidence_isolation ON investigation_evidence_files
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY witness_statements_isolation ON discipline_witness_statements
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY investigation_timeline_isolation ON investigation_timeline
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/discipline-investigations.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface Investigation {
  id: string;
  caseId: string;
  caseNumber: string;
  investigationStatus: string;
  investigatorId: string;
  investigationStartDate: string;
  investigationEndDate?: string;
  evidenceSummary?: string;
  findings?: string;
  severityAssessment?: string;
  recommendedAction?: string;
  escalatedToPrincipal: boolean;
  parentContacted: boolean;
  caseClosed: boolean;
}

export interface WitnessStatement {
  id: string;
  witnessType: string;
  witnessName: string;
  statementText: string;
  statementDate: string;
  recordedBy: string;
  verified: boolean;
}

export interface EvidenceFile {
  id: string;
  fileType: string;
  fileName: string;
  fileUrl: string;
  description: string;
  collectedBy: string;
  collectedAt: string;
  verified: boolean;
}

export class DisciplineInvestigationsAPI {
  private supabase = createClient();

  async getInvestigations(params: {
    tenantId: string;
    branchId: string;
    status?: string;
  }): Promise<Investigation[]> {
    let query = this.supabase
      .from('discipline_investigations')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.status) {
      query = query.eq('investigation_status', params.status);
    }

    const { data, error } = await query.order('investigation_start_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(inv => ({
      id: inv.id,
      caseId: inv.discipline_case_id,
      caseNumber: inv.case_number,
      investigationStatus: inv.investigation_status,
      investigatorId: inv.investigator_id,
      investigationStartDate: inv.investigation_start_date,
      investigationEndDate: inv.investigation_end_date,
      evidenceSummary: inv.evidence_summary,
      findings: inv.findings,
      severityAssessment: inv.severity_assessment,
      recommendedAction: inv.recommended_action,
      escalatedToPrincipal: inv.escalated_to_principal,
      parentContacted: inv.parent_contacted,
      caseClosed: inv.case_closed,
    }));
  }

  async createInvestigation(params: {
    tenantId: string;
    branchId: string;
    disciplineCaseId: string;
    caseNumber: string;
    investigatorId: string;
  }) {
    const { data, error } = await this.supabase
      .from('discipline_investigations')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        discipline_case_id: params.disciplineCaseId,
        case_number: params.caseNumber,
        investigator_id: params.investigatorId,
        investigation_status: 'initiated',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async addWitnessStatement(params: {
    tenantId: string;
    branchId: string;
    investigationId: string;
    disciplineCaseId: string;
    witnessType: string;
    witnessName: string;
    witnessContact?: string;
    statementText: string;
    statementMethod: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('discipline_witness_statements')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        investigation_id: params.investigationId,
        discipline_case_id: params.disciplineCaseId,
        witness_type: params.witnessType,
        witness_name: params.witnessName,
        witness_contact: params.witnessContact,
        statement_text: params.statementText,
        statement_method: params.statementMethod,
        recorded_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;

    // Add to timeline
    await this.addTimelineEvent({
      tenantId: params.tenantId,
      branchId: params.branchId,
      investigationId: params.investigationId,
      eventType: 'witness_interviewed',
      eventDescription: `Recorded statement from ${params.witnessName} (${params.witnessType})`,
    });

    return data;
  }

  async getWitnessStatements(investigationId: string): Promise<WitnessStatement[]> {
    const { data, error } = await this.supabase
      .from('discipline_witness_statements')
      .select('*')
      .eq('investigation_id', investigationId)
      .order('statement_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(stmt => ({
      id: stmt.id,
      witnessType: stmt.witness_type,
      witnessName: stmt.witness_name,
      statementText: stmt.statement_text,
      statementDate: stmt.statement_date,
      recordedBy: stmt.recorded_by,
      verified: stmt.verified,
    }));
  }

  async uploadEvidence(params: {
    tenantId: string;
    branchId: string;
    investigationId: string;
    file: File;
    fileType: string;
    description: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    // Upload file to storage
    const fileName = `${Date.now()}-${params.file.name}`;
    const { data: uploadData, error: uploadError } = await this.supabase.storage
      .from('investigation-evidence')
      .upload(`${params.tenantId}/${params.investigationId}/${fileName}`, params.file);

    if (uploadError) throw uploadError;

    // Get public URL
    const { data: { publicUrl } } = this.supabase.storage
      .from('investigation-evidence')
      .getPublicUrl(uploadData.path);

    // Save evidence record
    const { data, error } = await this.supabase
      .from('investigation_evidence_files')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        investigation_id: params.investigationId,
        file_type: params.fileType,
        file_name: params.file.name,
        file_url: publicUrl,
        file_size_kb: Math.round(params.file.size / 1024),
        description: params.description,
        collected_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;

    // Add to timeline
    await this.addTimelineEvent({
      tenantId: params.tenantId,
      branchId: params.branchId,
      investigationId: params.investigationId,
      eventType: 'evidence_collected',
      eventDescription: `Uploaded ${params.fileType}: ${params.file.name}`,
    });

    return data;
  }

  async getEvidenceFiles(investigationId: string): Promise<EvidenceFile[]> {
    const { data, error } = await this.supabase
      .from('investigation_evidence_files')
      .select('*')
      .eq('investigation_id', investigationId)
      .order('collected_at', { ascending: false });

    if (error) throw error;

    return (data || []).map(ev => ({
      id: ev.id,
      fileType: ev.file_type,
      fileName: ev.file_name,
      fileUrl: ev.file_url,
      description: ev.description,
      collectedBy: ev.collected_by,
      collectedAt: ev.collected_at,
      verified: ev.verified,
    }));
  }

  async updateInvestigationFindings(params: {
    investigationId: string;
    findings: string;
    severityAssessment: string;
    recommendedAction: string;
  }) {
    const { error } = await this.supabase
      .from('discipline_investigations')
      .update({
        findings: params.findings,
        severity_assessment: params.severityAssessment,
        recommended_action: params.recommendedAction,
        investigation_status: 'completed',
        investigation_end_date: new Date().toISOString().split('T')[0],
      })
      .eq('id', params.investigationId);

    if (error) throw error;
  }

  async escalateToPrincipal(params: {
    investigationId: string;
    escalationReason: string;
  }) {
    const { error } = await this.supabase
      .from('discipline_investigations')
      .update({
        escalated_to_principal: true,
        escalation_date: new Date().toISOString().split('T')[0],
        escalation_reason: params.escalationReason,
      })
      .eq('id', params.investigationId);

    if (error) throw error;
  }

  async contactParent(params: {
    tenantId: string;
    branchId: string;
    investigationId: string;
    parentResponse?: string;
  }) {
    const { error } = await this.supabase
      .from('discipline_investigations')
      .update({
        parent_contacted: true,
        parent_contact_date: new Date().toISOString().split('T')[0],
        parent_response: params.parentResponse,
      })
      .eq('id', params.investigationId);

    if (error) throw error;

    await this.addTimelineEvent({
      tenantId: params.tenantId,
      branchId: params.branchId,
      investigationId: params.investigationId,
      eventType: 'parent_contacted',
      eventDescription: 'Parent contacted regarding investigation',
    });
  }

  async closeCase(params: {
    investigationId: string;
    closureNotes: string;
  }) {
    const { error } = await this.supabase
      .from('discipline_investigations')
      .update({
        case_closed: true,
        closure_date: new Date().toISOString().split('T')[0],
        closure_notes: params.closureNotes,
      })
      .eq('id', params.investigationId);

    if (error) throw error;
  }

  private async addTimelineEvent(params: {
    tenantId: string;
    branchId: string;
    investigationId: string;
    eventType: string;
    eventDescription: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    await this.supabase
      .from('investigation_timeline')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        investigation_id: params.investigationId,
        event_type: params.eventType,
        event_description: params.eventDescription,
        performed_by: user?.id,
      });
  }

  async getInvestigationTimeline(investigationId: string) {
    const { data, error } = await this.supabase
      .from('investigation_timeline')
      .select('*')
      .eq('investigation_id', investigationId)
      .order('event_date', { ascending: false })
      .order('event_time', { ascending: false });

    if (error) throw error;
    return data;
  }
}

export const disciplineInvestigationsAPI = new DisciplineInvestigationsAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { DisciplineInvestigationsAPI } from '../discipline-investigations';

describe('DisciplineInvestigationsAPI', () => {
  let api: DisciplineInvestigationsAPI;

  beforeEach(() => {
    api = new DisciplineInvestigationsAPI();
  });

  it('creates investigation', async () => {
    const investigation = await api.createInvestigation({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      disciplineCaseId: 'case-123',
      caseNumber: 'DC-202410-00001',
      investigatorId: 'vp-123',
    });

    expect(investigation).toHaveProperty('id');
    expect(investigation.investigation_status).toBe('initiated');
  });

  it('adds witness statement', async () => {
    const statement = await api.addWitnessStatement({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      investigationId: 'inv-123',
      disciplineCaseId: 'case-123',
      witnessType: 'student',
      witnessName: 'John Doe',
      statementText: 'I saw the incident...',
      statementMethod: 'written',
    });

    expect(statement).toHaveProperty('id');
  });

  it('escalates to principal', async () => {
    await expect(api.escalateToPrincipal({
      investigationId: 'inv-123',
      escalationReason: 'Serious offense requiring principal decision',
    })).resolves.not.toThrow();
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Investigation workflow operational
- [ ] Evidence upload working
- [ ] Witness statements recording
- [ ] Timeline tracking functional
- [ ] Parent contact logging
- [ ] Case escalation working
- [ ] Investigation closure process
- [ ] File storage configured
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
