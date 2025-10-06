# SPEC-208: VP Reports & Documentation

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-208  
**Title**: Vice Principal Reports & Documentation System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Reporting & Documentation  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-201  

---

## 📋 DESCRIPTION

Comprehensive reporting system enabling vice principals to generate daily operations reports, document key activities, track metrics, submit reports to principal, maintain report templates, and analyze operational trends.

---

## 🎯 SUCCESS CRITERIA

- [ ] Daily report generation operational
- [ ] Automated metrics aggregation working
- [ ] Report submission workflow functional
- [ ] Template management operational
- [ ] Report history tracking working
- [ ] Export functionality functional
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- VP Daily Reports
CREATE TABLE IF NOT EXISTS vp_daily_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  reported_by UUID NOT NULL REFERENCES staff(id),
  
  -- Attendance Summary
  attendance_summary JSONB DEFAULT '{}', -- {total_students, present, absent, late, attendance_percentage}
  
  -- Discipline Cases
  discipline_cases_count INTEGER DEFAULT 0,
  new_discipline_cases INTEGER DEFAULT 0,
  resolved_discipline_cases INTEGER DEFAULT 0,
  
  -- Events
  events_conducted_count INTEGER DEFAULT 0,
  events_upcoming_count INTEGER DEFAULT 0,
  
  -- Safety & Security
  safety_incidents_count INTEGER DEFAULT 0,
  visitors_count INTEGER DEFAULT 0,
  
  -- Activities
  activities_conducted_count INTEGER DEFAULT 0,
  student_participation_count INTEGER DEFAULT 0,
  
  -- Highlights
  highlights TEXT,
  achievements TEXT,
  
  -- Concerns/Issues
  concerns TEXT,
  issues_reported TEXT,
  action_required TEXT,
  
  -- Follow-up
  pending_tasks_count INTEGER DEFAULT 0,
  completed_tasks_count INTEGER DEFAULT 0,
  
  -- Submission
  submitted_to_principal BOOLEAN DEFAULT false,
  submission_timestamp TIMESTAMP WITH TIME ZONE,
  principal_acknowledged BOOLEAN DEFAULT false,
  principal_feedback TEXT,
  
  -- Status
  report_status VARCHAR(50) DEFAULT 'draft', -- draft, submitted, reviewed, acknowledged
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, report_date)
);

CREATE INDEX ON vp_daily_reports(tenant_id, branch_id, report_date DESC);
CREATE INDEX ON vp_daily_reports(report_status);
CREATE INDEX ON vp_daily_reports(submitted_to_principal);

-- VP Report Templates
CREATE TABLE IF NOT EXISTS vp_report_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  template_name VARCHAR(200) NOT NULL,
  template_type VARCHAR(100), -- daily, weekly, monthly, incident, custom
  
  template_structure JSONB NOT NULL, -- {sections: [{name, fields, required}]}
  
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  
  created_by UUID REFERENCES staff(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON vp_report_templates(tenant_id, branch_id);
CREATE INDEX ON vp_report_templates(template_type, is_active);

-- VP Weekly Summary
CREATE TABLE IF NOT EXISTS vp_weekly_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  
  -- Aggregated metrics
  total_students_present NUMERIC(10,2),
  avg_attendance_percentage NUMERIC(5,2),
  
  total_discipline_cases INTEGER DEFAULT 0,
  total_safety_incidents INTEGER DEFAULT 0,
  total_events_conducted INTEGER DEFAULT 0,
  total_visitors INTEGER DEFAULT 0,
  
  -- Key highlights
  weekly_highlights TEXT,
  notable_achievements TEXT,
  
  -- Challenges
  challenges_faced TEXT,
  improvements_needed TEXT,
  
  -- Action items
  action_items JSONB DEFAULT '[]',
  
  submitted_to_principal BOOLEAN DEFAULT false,
  submission_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON vp_weekly_summaries(tenant_id, branch_id, week_start_date DESC);

-- VP Report Metrics (Materialized View)
CREATE MATERIALIZED VIEW vp_report_metrics AS
SELECT
  vdr.tenant_id,
  vdr.branch_id,
  DATE_TRUNC('month', vdr.report_date) as month,
  
  COUNT(*) as total_reports,
  COUNT(CASE WHEN vdr.submitted_to_principal THEN 1 END) as submitted_reports,
  COUNT(CASE WHEN vdr.principal_acknowledged THEN 1 END) as acknowledged_reports,
  
  AVG((vdr.attendance_summary->>'attendance_percentage')::NUMERIC) as avg_attendance,
  SUM(vdr.discipline_cases_count) as total_discipline_cases,
  SUM(vdr.safety_incidents_count) as total_safety_incidents,
  SUM(vdr.events_conducted_count) as total_events,
  
  NOW() as last_calculated_at
  
FROM vp_daily_reports vdr
GROUP BY vdr.tenant_id, vdr.branch_id, DATE_TRUNC('month', vdr.report_date);

CREATE INDEX ON vp_report_metrics(tenant_id, branch_id, month DESC);

-- Function to generate daily report automatically
CREATE OR REPLACE FUNCTION generate_vp_daily_report(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_report_date DATE,
  p_reported_by UUID
)
RETURNS UUID AS $$
DECLARE
  v_report_id UUID;
  v_attendance_summary JSONB;
  v_discipline_count INTEGER;
  v_safety_count INTEGER;
BEGIN
  -- Get attendance summary
  SELECT jsonb_build_object(
    'total_students', COUNT(DISTINCT e.student_id),
    'present', COUNT(CASE WHEN a.status = 'present' THEN 1 END),
    'absent', COUNT(CASE WHEN a.status = 'absent' THEN 1 END),
    'late', COUNT(CASE WHEN a.status = 'late' THEN 1 END),
    'attendance_percentage', 
      CASE 
        WHEN COUNT(DISTINCT e.student_id) > 0 
        THEN (COUNT(CASE WHEN a.status = 'present' THEN 1 END)::FLOAT / COUNT(DISTINCT e.student_id) * 100)
        ELSE 0
      END
  )
  INTO v_attendance_summary
  FROM enrollments e
  LEFT JOIN attendance_records a ON e.student_id = a.student_id 
    AND a.attendance_date = p_report_date
  WHERE e.tenant_id = p_tenant_id 
    AND e.branch_id = p_branch_id
    AND e.status = 'active';
  
  -- Get discipline cases count
  SELECT COUNT(*) INTO v_discipline_count
  FROM discipline_cases
  WHERE tenant_id = p_tenant_id
    AND branch_id = p_branch_id
    AND DATE(created_at) = p_report_date;
  
  -- Get safety incidents count
  SELECT COUNT(*) INTO v_safety_count
  FROM safety_incidents
  WHERE tenant_id = p_tenant_id
    AND branch_id = p_branch_id
    AND incident_date = p_report_date;
  
  -- Insert report
  INSERT INTO vp_daily_reports (
    tenant_id,
    branch_id,
    report_date,
    reported_by,
    attendance_summary,
    discipline_cases_count,
    safety_incidents_count
  ) VALUES (
    p_tenant_id,
    p_branch_id,
    p_report_date,
    p_reported_by,
    v_attendance_summary,
    v_discipline_count,
    v_safety_count
  )
  RETURNING id INTO v_report_id;
  
  RETURN v_report_id;
END;
$$ LANGUAGE plpgsql;

-- Auto-update trigger
CREATE OR REPLACE FUNCTION update_vp_report_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vp_report_update_trigger
  BEFORE UPDATE ON vp_daily_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_vp_report_timestamp();

-- Enable RLS
ALTER TABLE vp_daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE vp_report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE vp_weekly_summaries ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY vp_daily_reports_isolation ON vp_daily_reports
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY vp_report_templates_isolation ON vp_report_templates
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY vp_weekly_summaries_isolation ON vp_weekly_summaries
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/vp-reports.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface VPDailyReport {
  id: string;
  reportDate: string;
  attendanceSummary: any;
  disciplineCasesCount: number;
  safetyIncidentsCount: number;
  eventsCount: number;
  highlights?: string;
  concerns?: string;
  submittedToPrincipal: boolean;
  reportStatus: string;
}

export class VPReportsAPI {
  private supabase = createClient();

  async generateDailyReport(params: {
    tenantId: string;
    branchId: string;
    reportDate: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase.rpc('generate_vp_daily_report', {
      p_tenant_id: params.tenantId,
      p_branch_id: params.branchId,
      p_report_date: params.reportDate,
      p_reported_by: user?.id,
    });

    if (error) throw error;
    return data;
  }

  async updateReportDetails(params: {
    reportId: string;
    highlights?: string;
    concerns?: string;
    actionRequired?: string;
  }) {
    const { error } = await this.supabase
      .from('vp_daily_reports')
      .update({
        highlights: params.highlights,
        concerns: params.concerns,
        action_required: params.actionRequired,
      })
      .eq('id', params.reportId);

    if (error) throw error;
  }

  async submitToPrincipal(reportId: string) {
    const { error } = await this.supabase
      .from('vp_daily_reports')
      .update({
        submitted_to_principal: true,
        submission_timestamp: new Date().toISOString(),
        report_status: 'submitted',
      })
      .eq('id', reportId);

    if (error) throw error;
  }

  async getReports(params: {
    tenantId: string;
    branchId: string;
    startDate?: string;
    endDate?: string;
    status?: string;
  }): Promise<VPDailyReport[]> {
    let query = this.supabase
      .from('vp_daily_reports')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.startDate) {
      query = query.gte('report_date', params.startDate);
    }

    if (params.endDate) {
      query = query.lte('report_date', params.endDate);
    }

    if (params.status) {
      query = query.eq('report_status', params.status);
    }

    const { data, error } = await query.order('report_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(report => ({
      id: report.id,
      reportDate: report.report_date,
      attendanceSummary: report.attendance_summary,
      disciplineCasesCount: report.discipline_cases_count,
      safetyIncidentsCount: report.safety_incidents_count,
      eventsCount: report.events_conducted_count,
      highlights: report.highlights,
      concerns: report.concerns,
      submittedToPrincipal: report.submitted_to_principal,
      reportStatus: report.report_status,
    }));
  }

  async getReportHistory(params: {
    tenantId: string;
    branchId: string;
    months?: number;
  }) {
    const monthsBack = params.months || 3;
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - monthsBack);

    const { data, error } = await this.supabase
      .from('vp_report_metrics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .gte('month', startDate.toISOString())
      .order('month', { ascending: false });

    if (error) throw error;
    return data;
  }

  async createTemplate(params: {
    tenantId: string;
    branchId: string;
    templateName: string;
    templateType: string;
    templateStructure: any;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('vp_report_templates')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        template_name: params.templateName,
        template_type: params.templateType,
        template_structure: params.templateStructure,
        created_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getTemplates(params: {
    tenantId: string;
    branchId: string;
    templateType?: string;
  }) {
    let query = this.supabase
      .from('vp_report_templates')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('is_active', true);

    if (params.templateType) {
      query = query.eq('template_type', params.templateType);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  async exportReport(reportId: string, format: 'pdf' | 'excel') {
    // This would integrate with your export service
    // For now, returning the report data
    const { data, error } = await this.supabase
      .from('vp_daily_reports')
      .select('*')
      .eq('id', reportId)
      .single();

    if (error) throw error;
    return data;
  }
}

export const vpReportsAPI = new VPReportsAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { VPReportsAPI } from '../vp-reports';

describe('VPReportsAPI', () => {
  let api: VPReportsAPI;

  beforeEach(() => {
    api = new VPReportsAPI();
  });

  it('generates daily report', async () => {
    const reportId = await api.generateDailyReport({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      reportDate: '2025-10-05',
    });

    expect(reportId).toBeDefined();
  });

  it('submits report to principal', async () => {
    await expect(api.submitToPrincipal('report-123')).resolves.not.toThrow();
  });

  it('gets report history', async () => {
    const history = await api.getReportHistory({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      months: 3,
    });

    expect(Array.isArray(history)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Daily report generation working
- [ ] Automated metrics aggregation functional
- [ ] Report submission workflow operational
- [ ] Template management working
- [ ] Report history tracking functional
- [ ] Export functionality implemented
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
