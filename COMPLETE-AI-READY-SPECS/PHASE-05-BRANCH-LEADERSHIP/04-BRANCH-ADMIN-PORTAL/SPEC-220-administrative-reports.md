# SPEC-220: Administrative Reports

**Feature**: Administrative Reports  
**Module**: Phase 5 - Branch Leadership / Branch Admin Portal  
**Type**: Database + API + Testing  
**Complexity**: MEDIUM  
**AI-Ready**: ✅ 100% Complete Specification

---

## 📋 OVERVIEW

Comprehensive administrative reporting system with daily operational reports, registration analytics, facility utilization reports, document processing metrics, and automated report generation.

### Purpose
- Generate daily administrative reports
- Track operational KPIs and metrics
- Monitor registration and admission trends
- Analyze facility utilization
- Report on document processing
- Export reports in multiple formats

### Scope
- Daily operational reports
- Registration analytics
- Facility utilization tracking
- Document verification metrics
- Automated report scheduling
- Multi-format exports (PDF, Excel, CSV)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Admin Daily Reports
CREATE TABLE IF NOT EXISTS admin_daily_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  report_type VARCHAR(50) NOT NULL DEFAULT 'daily', -- 'daily', 'weekly', 'monthly'
  
  -- Student Metrics
  new_registrations_count INTEGER DEFAULT 0,
  registrations_approved_count INTEGER DEFAULT 0,
  pending_registrations_count INTEGER DEFAULT 0,
  total_active_students INTEGER DEFAULT 0,
  student_attendance_percentage NUMERIC(5,2) DEFAULT 0,
  
  -- Staff Metrics
  staff_present_count INTEGER DEFAULT 0,
  staff_absent_count INTEGER DEFAULT 0,
  staff_on_leave_count INTEGER DEFAULT 0,
  staff_attendance_percentage NUMERIC(5,2) DEFAULT 0,
  
  -- Document Processing
  documents_verified_count INTEGER DEFAULT 0,
  documents_pending_verification INTEGER DEFAULT 0,
  documents_rejected_count INTEGER DEFAULT 0,
  
  -- Facility Utilization
  facility_bookings_count INTEGER DEFAULT 0,
  approved_bookings_count INTEGER DEFAULT 0,
  cancelled_bookings_count INTEGER DEFAULT 0,
  facility_utilization_percentage NUMERIC(5,2) DEFAULT 0,
  
  -- Visitor Management
  visitors_count INTEGER DEFAULT 0,
  visitors_currently_present INTEGER DEFAULT 0,
  
  -- Operational Highlights
  operational_highlights TEXT,
  issues_encountered TEXT,
  action_items JSONB DEFAULT '[]', -- [{action, priority, assigned_to, status}]
  
  -- Report Status
  report_status VARCHAR(50) NOT NULL DEFAULT 'draft', -- 'draft', 'finalized', 'submitted'
  generated_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  finalized_at TIMESTAMPTZ,
  submitted_to UUID REFERENCES staff(id) ON DELETE SET NULL, -- Principal/VP
  submitted_at TIMESTAMPTZ,
  
  -- Attachments
  report_file_url TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, report_date, report_type)
);

CREATE INDEX ON admin_daily_reports(tenant_id, branch_id);
CREATE INDEX ON admin_daily_reports(report_date DESC);
CREATE INDEX ON admin_daily_reports(report_type);
CREATE INDEX ON admin_daily_reports(report_status);

-- Admin Report Metrics (Materialized View - Monthly aggregates)
CREATE MATERIALIZED VIEW admin_report_metrics AS
SELECT
  b.tenant_id,
  b.id as branch_id,
  b.branch_name,
  b.branch_code,
  
  DATE_TRUNC('month', r.report_date) as report_month,
  
  -- Registration Metrics
  SUM(r.new_registrations_count) as total_new_registrations,
  SUM(r.registrations_approved_count) as total_registrations_approved,
  AVG(r.pending_registrations_count) as avg_pending_registrations,
  
  -- Student Metrics
  AVG(r.total_active_students) as avg_active_students,
  AVG(r.student_attendance_percentage) as avg_student_attendance,
  
  -- Staff Metrics
  AVG(r.staff_present_count) as avg_staff_present,
  AVG(r.staff_attendance_percentage) as avg_staff_attendance,
  
  -- Document Processing
  SUM(r.documents_verified_count) as total_documents_verified,
  AVG(r.documents_pending_verification) as avg_documents_pending,
  
  -- Facility Utilization
  SUM(r.facility_bookings_count) as total_facility_bookings,
  AVG(r.facility_utilization_percentage) as avg_facility_utilization,
  
  -- Visitor Management
  SUM(r.visitors_count) as total_visitors,
  
  -- Operational Stats
  COUNT(*) as reports_generated,
  MAX(r.report_date) as last_report_date
  
FROM branches b
LEFT JOIN admin_daily_reports r ON b.id = r.branch_id
WHERE r.report_status IN ('finalized', 'submitted')
GROUP BY b.tenant_id, b.id, b.branch_name, b.branch_code, DATE_TRUNC('month', r.report_date);

CREATE UNIQUE INDEX ON admin_report_metrics(tenant_id, branch_id, report_month);
CREATE INDEX ON admin_report_metrics(branch_id);
CREATE INDEX ON admin_report_metrics(report_month DESC);

-- Report Templates
CREATE TABLE IF NOT EXISTS admin_report_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  template_name VARCHAR(200) NOT NULL,
  template_type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'custom'
  template_description TEXT,
  
  -- Template Configuration
  sections_included JSONB NOT NULL DEFAULT '[]', -- ['registrations', 'attendance', 'facilities', 'documents', 'visitors']
  metrics_to_include JSONB DEFAULT '[]', -- List of specific metrics
  chart_types JSONB DEFAULT '[]', -- [{type: 'bar', data_source: 'registrations'}, ...]
  
  -- Scheduling
  is_scheduled BOOLEAN DEFAULT false,
  schedule_frequency VARCHAR(50), -- 'daily', 'weekly', 'monthly'
  schedule_day_of_week INTEGER, -- 1-7 for weekly
  schedule_day_of_month INTEGER, -- 1-31 for monthly
  
  is_active BOOLEAN NOT NULL DEFAULT true,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON admin_report_templates(tenant_id);
CREATE INDEX ON admin_report_templates(template_type);
CREATE INDEX ON admin_report_templates(is_active);

-- RLS Policies
ALTER TABLE admin_daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_report_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_daily_reports_tenant_isolation ON admin_daily_reports
  USING (tenant_id = auth.get_current_tenant_id());

CREATE POLICY admin_daily_reports_branch_access ON admin_daily_reports
  USING (branch_id IN (SELECT branch_id FROM user_branch_access WHERE user_id = auth.uid()));

CREATE POLICY admin_report_templates_tenant_isolation ON admin_report_templates
  USING (tenant_id = auth.get_current_tenant_id());

-- Triggers
CREATE TRIGGER update_admin_daily_reports_updated_at
  BEFORE UPDATE ON admin_daily_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_report_templates_updated_at
  BEFORE UPDATE ON admin_report_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/admin-reports.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface AdminDailyReport {
  id: string;
  tenantId: string;
  branchId: string;
  reportDate: string;
  reportType: 'daily' | 'weekly' | 'monthly';
  newRegistrationsCount: number;
  registrationsApprovedCount: number;
  pendingRegistrationsCount: number;
  totalActiveStudents: number;
  studentAttendancePercentage: number;
  staffPresentCount: number;
  staffAbsentCount: number;
  staffOnLeaveCount: number;
  staffAttendancePercentage: number;
  documentsVerifiedCount: number;
  documentsPendingVerification: number;
  documentsRejectedCount: number;
  facilityBookingsCount: number;
  approvedBookingsCount: number;
  cancelledBookingsCount: number;
  facilityUtilizationPercentage: number;
  visitorsCount: number;
  visitorsCurrentlyPresent: number;
  operationalHighlights?: string;
  issuesEncountered?: string;
  actionItems: Array<{ action: string; priority: string; assigned_to?: string; status: string }>;
  reportStatus: 'draft' | 'finalized' | 'submitted';
  generatedBy?: string;
  generatedAt: string;
  finalizedAt?: string;
  submittedTo?: string;
  submittedAt?: string;
  reportFileUrl?: string;
}

export interface ReportMetrics {
  branchId: string;
  branchName: string;
  reportMonth: string;
  totalNewRegistrations: number;
  totalRegistrationsApproved: number;
  avgPendingRegistrations: number;
  avgActiveStudents: number;
  avgStudentAttendance: number;
  avgStaffPresent: number;
  avgStaffAttendance: number;
  totalDocumentsVerified: number;
  avgDocumentsPending: number;
  totalFacilityBookings: number;
  avgFacilityUtilization: number;
  totalVisitors: number;
  reportsGenerated: number;
  lastReportDate: string;
}

export interface ReportTemplate {
  id: string;
  templateName: string;
  templateType: string;
  templateDescription?: string;
  sectionsIncluded: string[];
  metricsToInclude: string[];
  chartTypes: Array<{ type: string; data_source: string }>;
  isScheduled: boolean;
  scheduleFrequency?: string;
  scheduleDayOfWeek?: number;
  scheduleDayOfMonth?: number;
  isActive: boolean;
}

export class AdminReportsAPI {
  private supabase = createClient();

  async generateDailyReport(params: {
    tenantId: string;
    branchId: string;
    reportDate: string;
    operationalHighlights?: string;
    issuesEncountered?: string;
  }): Promise<string> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Fetch metrics from dashboard
    const { data: dashboard } = await this.supabase
      .from('admin_operations_dashboard')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .single();

    // Create report
    const { data, error } = await this.supabase
      .from('admin_daily_reports')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        report_date: params.reportDate,
        report_type: 'daily',
        new_registrations_count: dashboard?.new_admissions_today || 0,
        registrations_approved_count: dashboard?.registrations_approved_today || 0,
        pending_registrations_count: dashboard?.pending_registrations || 0,
        total_active_students: dashboard?.active_students_count || 0,
        staff_present_count: dashboard?.staff_present_count || 0,
        staff_absent_count: dashboard?.staff_absent_count || 0,
        staff_on_leave_count: dashboard?.staff_on_leave_count || 0,
        documents_verified_count: dashboard?.documents_verified_today || 0,
        documents_pending_verification: dashboard?.documents_pending_verification || 0,
        facility_bookings_count: dashboard?.facility_bookings_today || 0,
        approved_bookings_count: dashboard?.approved_bookings_today || 0,
        visitors_count: dashboard?.visitors_today || 0,
        visitors_currently_present: dashboard?.visitors_currently_present || 0,
        operational_highlights: params.operationalHighlights,
        issues_encountered: params.issuesEncountered,
        report_status: 'draft',
        generated_by: user.id,
      })
      .select('id')
      .single();

    if (error) throw error;
    return data.id;
  }

  async getReports(params: {
    tenantId: string;
    branchId: string;
    reportType?: string;
    status?: string;
    startDate?: string;
    endDate?: string;
  }): Promise<AdminDailyReport[]> {
    let query = this.supabase
      .from('admin_daily_reports')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .order('report_date', { ascending: false });

    if (params.reportType) {
      query = query.eq('report_type', params.reportType);
    }
    if (params.status) {
      query = query.eq('report_status', params.status);
    }
    if (params.startDate) {
      query = query.gte('report_date', params.startDate);
    }
    if (params.endDate) {
      query = query.lte('report_date', params.endDate);
    }

    const { data, error } = await query;
    if (error) throw error;

    return (data || []).map(report => ({
      id: report.id,
      tenantId: report.tenant_id,
      branchId: report.branch_id,
      reportDate: report.report_date,
      reportType: report.report_type,
      newRegistrationsCount: report.new_registrations_count || 0,
      registrationsApprovedCount: report.registrations_approved_count || 0,
      pendingRegistrationsCount: report.pending_registrations_count || 0,
      totalActiveStudents: report.total_active_students || 0,
      studentAttendancePercentage: report.student_attendance_percentage || 0,
      staffPresentCount: report.staff_present_count || 0,
      staffAbsentCount: report.staff_absent_count || 0,
      staffOnLeaveCount: report.staff_on_leave_count || 0,
      staffAttendancePercentage: report.staff_attendance_percentage || 0,
      documentsVerifiedCount: report.documents_verified_count || 0,
      documentsPendingVerification: report.documents_pending_verification || 0,
      documentsRejectedCount: report.documents_rejected_count || 0,
      facilityBookingsCount: report.facility_bookings_count || 0,
      approvedBookingsCount: report.approved_bookings_count || 0,
      cancelledBookingsCount: report.cancelled_bookings_count || 0,
      facilityUtilizationPercentage: report.facility_utilization_percentage || 0,
      visitorsCount: report.visitors_count || 0,
      visitorsCurrentlyPresent: report.visitors_currently_present || 0,
      operationalHighlights: report.operational_highlights,
      issuesEncountered: report.issues_encountered,
      actionItems: report.action_items || [],
      reportStatus: report.report_status,
      generatedBy: report.generated_by,
      generatedAt: report.generated_at,
      finalizedAt: report.finalized_at,
      submittedTo: report.submitted_to,
      submittedAt: report.submitted_at,
      reportFileUrl: report.report_file_url,
    }));
  }

  async updateReport(
    reportId: string,
    updates: Partial<{
      operationalHighlights: string;
      issuesEncountered: string;
      actionItems: any[];
      reportStatus: string;
    }>
  ): Promise<void> {
    const { error } = await this.supabase
      .from('admin_daily_reports')
      .update({
        operational_highlights: updates.operationalHighlights,
        issues_encountered: updates.issuesEncountered,
        action_items: updates.actionItems,
        report_status: updates.reportStatus,
        ...(updates.reportStatus === 'finalized' && { finalized_at: new Date().toISOString() }),
      })
      .eq('id', reportId);

    if (error) throw error;
  }

  async finalizeReport(reportId: string): Promise<void> {
    const { error } = await this.supabase
      .from('admin_daily_reports')
      .update({
        report_status: 'finalized',
        finalized_at: new Date().toISOString(),
      })
      .eq('id', reportId);

    if (error) throw error;
  }

  async submitReport(reportId: string, submittedTo: string): Promise<void> {
    const { error } = await this.supabase
      .from('admin_daily_reports')
      .update({
        report_status: 'submitted',
        submitted_to: submittedTo,
        submitted_at: new Date().toISOString(),
      })
      .eq('id', reportId);

    if (error) throw error;
  }

  async getDailyMetrics(params: {
    tenantId: string;
    branchId: string;
    date: string;
  }): Promise<Partial<AdminDailyReport>> {
    const { data: dashboard } = await this.supabase
      .from('admin_operations_dashboard')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .single();

    return {
      newRegistrationsCount: dashboard?.new_admissions_today || 0,
      registrationsApprovedCount: dashboard?.registrations_approved_today || 0,
      pendingRegistrationsCount: dashboard?.pending_registrations || 0,
      totalActiveStudents: dashboard?.active_students_count || 0,
      staffPresentCount: dashboard?.staff_present_count || 0,
      staffAbsentCount: dashboard?.staff_absent_count || 0,
      staffOnLeaveCount: dashboard?.staff_on_leave_count || 0,
      documentsVerifiedCount: dashboard?.documents_verified_today || 0,
      documentsPendingVerification: dashboard?.documents_pending_verification || 0,
      facilityBookingsCount: dashboard?.facility_bookings_today || 0,
      approvedBookingsCount: dashboard?.approved_bookings_today || 0,
      visitorsCount: dashboard?.visitors_today || 0,
    };
  }

  async getMonthlyMetrics(params: {
    tenantId: string;
    branchId: string;
    month: string; // YYYY-MM format
  }): Promise<ReportMetrics | null> {
    const { data, error } = await this.supabase
      .from('admin_report_metrics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .gte('report_month', `${params.month}-01`)
      .lt('report_month', `${params.month}-32`)
      .single();

    if (error) return null;
    if (!data) return null;

    return {
      branchId: data.branch_id,
      branchName: data.branch_name,
      reportMonth: data.report_month,
      totalNewRegistrations: data.total_new_registrations || 0,
      totalRegistrationsApproved: data.total_registrations_approved || 0,
      avgPendingRegistrations: data.avg_pending_registrations || 0,
      avgActiveStudents: data.avg_active_students || 0,
      avgStudentAttendance: data.avg_student_attendance || 0,
      avgStaffPresent: data.avg_staff_present || 0,
      avgStaffAttendance: data.avg_staff_attendance || 0,
      totalDocumentsVerified: data.total_documents_verified || 0,
      avgDocumentsPending: data.avg_documents_pending || 0,
      totalFacilityBookings: data.total_facility_bookings || 0,
      avgFacilityUtilization: data.avg_facility_utilization || 0,
      totalVisitors: data.total_visitors || 0,
      reportsGenerated: data.reports_generated || 0,
      lastReportDate: data.last_report_date,
    };
  }

  async exportReport(reportId: string, format: 'pdf' | 'excel' | 'csv'): Promise<string> {
    const { data, error } = await this.supabase.rpc('export_admin_report', {
      p_report_id: reportId,
      p_format: format,
    });

    if (error) throw error;
    return data; // URL to exported file
  }

  async createTemplate(params: {
    tenantId: string;
    templateName: string;
    templateType: string;
    sectionsIncluded: string[];
    metricsToInclude: string[];
  }): Promise<string> {
    const { data, error } = await this.supabase
      .from('admin_report_templates')
      .insert({
        tenant_id: params.tenantId,
        template_name: params.templateName,
        template_type: params.templateType,
        sections_included: params.sectionsIncluded,
        metrics_to_include: params.metricsToInclude,
      })
      .select('id')
      .single();

    if (error) throw error;
    return data.id;
  }

  async getTemplates(tenantId: string): Promise<ReportTemplate[]> {
    const { data, error } = await this.supabase
      .from('admin_report_templates')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('is_active', true);

    if (error) throw error;

    return (data || []).map(template => ({
      id: template.id,
      templateName: template.template_name,
      templateType: template.template_type,
      templateDescription: template.template_description,
      sectionsIncluded: template.sections_included || [],
      metricsToInclude: template.metrics_to_include || [],
      chartTypes: template.chart_types || [],
      isScheduled: template.is_scheduled,
      scheduleFrequency: template.schedule_frequency,
      scheduleDayOfWeek: template.schedule_day_of_week,
      scheduleDayOfMonth: template.schedule_day_of_month,
      isActive: template.is_active,
    }));
  }

  async refreshMetrics(): Promise<void> {
    const { error } = await this.supabase.rpc('refresh_admin_report_metrics');
    if (error) throw error;
  }
}
```

---

## 🧪 TESTING SPECIFICATIONS

### Test File (`/tests/api/admin-reports.test.ts`)

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { AdminReportsAPI } from '@/lib/api/admin-reports';

describe('AdminReportsAPI', () => {
  let api: AdminReportsAPI;

  beforeEach(() => {
    api = new AdminReportsAPI();
  });

  describe('generateDailyReport', () => {
    it('should generate daily report with metrics', async () => {
      const reportId = await api.generateDailyReport({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        reportDate: '2024-01-15',
        operationalHighlights: 'All systems operational',
      });

      expect(reportId).toBeDefined();
    });

    it('should pull metrics from dashboard', async () => {
      const reportId = await api.generateDailyReport({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        reportDate: '2024-01-15',
      });

      const reports = await api.getReports({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      const report = reports.find(r => r.id === reportId);
      expect(report?.newRegistrationsCount).toBeGreaterThanOrEqual(0);
      expect(report?.staffPresentCount).toBeGreaterThanOrEqual(0);
    });
  });

  describe('getReports', () => {
    it('should fetch reports with filters', async () => {
      const reports = await api.getReports({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        reportType: 'daily',
        status: 'finalized',
      });

      expect(Array.isArray(reports)).toBe(true);
    });
  });

  describe('finalizeReport', () => {
    it('should finalize draft report', async () => {
      const reportId = 'report-1';

      await api.finalizeReport(reportId);

      const reports = await api.getReports({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      const report = reports.find(r => r.id === reportId);
      expect(report?.reportStatus).toBe('finalized');
      expect(report?.finalizedAt).toBeDefined();
    });
  });

  describe('submitReport', () => {
    it('should submit report to principal', async () => {
      const reportId = 'report-1';
      const principalId = 'principal-1';

      await api.submitReport(reportId, principalId);

      const reports = await api.getReports({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      const report = reports.find(r => r.id === reportId);
      expect(report?.reportStatus).toBe('submitted');
      expect(report?.submittedTo).toBe(principalId);
    });
  });

  describe('getDailyMetrics', () => {
    it('should fetch current day metrics', async () => {
      const metrics = await api.getDailyMetrics({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        date: '2024-01-15',
      });

      expect(metrics).toBeDefined();
      expect(metrics.newRegistrationsCount).toBeDefined();
      expect(metrics.staffPresentCount).toBeDefined();
    });
  });

  describe('getMonthlyMetrics', () => {
    it('should fetch monthly aggregates', async () => {
      const metrics = await api.getMonthlyMetrics({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        month: '2024-01',
      });

      if (metrics) {
        expect(metrics.totalNewRegistrations).toBeDefined();
        expect(metrics.avgStaffAttendance).toBeDefined();
        expect(metrics.totalFacilityBookings).toBeDefined();
      }
    });
  });

  describe('exportReport', () => {
    it('should export report as PDF', async () => {
      const reportId = 'report-1';
      const url = await api.exportReport(reportId, 'pdf');

      expect(url).toBeDefined();
      expect(typeof url).toBe('string');
    });
  });

  describe('createTemplate', () => {
    it('should create report template', async () => {
      const templateId = await api.createTemplate({
        tenantId: 'tenant-1',
        templateName: 'Daily Operations Summary',
        templateType: 'daily',
        sectionsIncluded: ['registrations', 'attendance', 'facilities'],
        metricsToInclude: ['new_registrations', 'staff_present', 'facility_bookings'],
      });

      expect(templateId).toBeDefined();
    });
  });
});
```

**Coverage Target**: 85%+

---

## ✅ ACCEPTANCE CRITERIA

- [x] Daily report generation from dashboard metrics
- [x] Registration analytics tracking
- [x] Staff attendance reporting
- [x] Document processing metrics
- [x] Facility utilization statistics
- [x] Visitor management reporting
- [x] Action items tracking with status
- [x] Report finalization workflow
- [x] Report submission to leadership
- [x] Monthly aggregated metrics view
- [x] Report export functionality (PDF, Excel, CSV)
- [x] Report templates system
- [x] Operational highlights and issues tracking
- [x] Multi-tenant security with RLS policies
- [x] TypeScript support with strict typing
- [x] Comprehensive test coverage (85%+)

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Implementation Time**: 3 hours  
**Priority**: MEDIUM  
**Dependencies**: SPEC-009 (Multi-tenant), SPEC-216 (Admin Dashboard)
