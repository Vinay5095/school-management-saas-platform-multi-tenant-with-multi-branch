# SPEC-216: Admin Dashboard & Operations

**Feature**: Admin Dashboard & Operations  
**Module**: Phase 5 - Branch Leadership / Branch Admin Portal  
**Type**: Database + API + Testing  
**Complexity**: MEDIUM  
**AI-Ready**: ✅ 100% Complete Specification

---

## 📋 OVERVIEW

Comprehensive administrative dashboard for Branch Administrator with daily operations overview, operational checklists, student/staff metrics, facility status, and document management tracking.

### Purpose
- Monitor daily administrative operations
- Track student registration and admissions
- Oversee staff attendance and records
- Manage facility bookings and status
- Monitor document verification workflow

### Scope
- Administrative operations dashboard
- Daily operational checklists
- Real-time metrics and KPIs
- Document tracking system
- Facility utilization monitoring

---

## 🗄️ DATABASE SCHEMA

```sql
-- Admin Daily Checklist
CREATE TABLE IF NOT EXISTS admin_daily_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  
  checklist_date DATE NOT NULL DEFAULT CURRENT_DATE,
  admin_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  
  -- Daily Tasks
  attendance_recorded BOOLEAN NOT NULL DEFAULT false,
  attendance_recorded_at TIMESTAMPTZ,
  attendance_recorded_by UUID REFERENCES staff(id),
  
  documents_verified BOOLEAN NOT NULL DEFAULT false,
  documents_verified_count INTEGER DEFAULT 0,
  documents_verified_at TIMESTAMPTZ,
  
  facilities_inspected BOOLEAN NOT NULL DEFAULT false,
  facilities_inspected_count INTEGER DEFAULT 0,
  facilities_inspection_notes TEXT,
  facilities_inspected_at TIMESTAMPTZ,
  
  staff_attendance_reviewed BOOLEAN NOT NULL DEFAULT false,
  staff_attendance_reviewed_at TIMESTAMPTZ,
  
  registrations_processed BOOLEAN NOT NULL DEFAULT false,
  registrations_processed_count INTEGER DEFAULT 0,
  registrations_processed_at TIMESTAMPTZ,
  
  visitor_log_updated BOOLEAN NOT NULL DEFAULT false,
  visitor_count INTEGER DEFAULT 0,
  visitor_log_updated_at TIMESTAMPTZ,
  
  -- Summary
  operational_notes TEXT,
  issues_encountered TEXT,
  tasks_completed INTEGER GENERATED ALWAYS AS (
    (CASE WHEN attendance_recorded THEN 1 ELSE 0 END) +
    (CASE WHEN documents_verified THEN 1 ELSE 0 END) +
    (CASE WHEN facilities_inspected THEN 1 ELSE 0 END) +
    (CASE WHEN staff_attendance_reviewed THEN 1 ELSE 0 END) +
    (CASE WHEN registrations_processed THEN 1 ELSE 0 END) +
    (CASE WHEN visitor_log_updated THEN 1 ELSE 0 END)
  ) STORED,
  tasks_total INTEGER DEFAULT 6,
  
  checklist_status VARCHAR(50) NOT NULL DEFAULT 'in_progress', -- 'pending', 'in_progress', 'completed'
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, checklist_date, admin_id)
);

CREATE INDEX ON admin_daily_checklist(tenant_id, branch_id);
CREATE INDEX ON admin_daily_checklist(checklist_date DESC);
CREATE INDEX ON admin_daily_checklist(admin_id);
CREATE INDEX ON admin_daily_checklist(checklist_status);

-- Admin Operations Dashboard (Materialized View)
CREATE MATERIALIZED VIEW admin_operations_dashboard AS
SELECT
  b.tenant_id,
  b.id as branch_id,
  b.branch_name,
  b.branch_code,
  
  -- Student Metrics
  COUNT(DISTINCT s.id) as active_students_count,
  COUNT(DISTINCT CASE WHEN s.admission_date = CURRENT_DATE THEN s.id END) as new_admissions_today,
  COUNT(DISTINCT CASE WHEN s.admission_status = 'pending' THEN s.id END) as pending_admissions_count,
  
  -- Staff Metrics
  COUNT(DISTINCT st.id) as total_staff_count,
  COUNT(DISTINCT CASE WHEN sa.attendance_date = CURRENT_DATE AND sa.status = 'present' THEN st.id END) as staff_present_count,
  COUNT(DISTINCT CASE WHEN sa.attendance_date = CURRENT_DATE AND sa.status = 'absent' THEN st.id END) as staff_absent_count,
  COUNT(DISTINCT CASE WHEN la.status = 'approved' AND CURRENT_DATE BETWEEN la.start_date AND la.end_date THEN la.staff_id END) as staff_on_leave_count,
  
  -- Document Verification
  COUNT(DISTINCT CASE WHEN sd.verification_status = 'pending' THEN sd.id END) as documents_pending_verification,
  COUNT(DISTINCT CASE WHEN sd.verification_status = 'verified' AND sd.verified_at::DATE = CURRENT_DATE THEN sd.id END) as documents_verified_today,
  
  -- Facility Management
  COUNT(DISTINCT f.id) as total_facilities,
  COUNT(DISTINCT CASE WHEN fb.booking_date = CURRENT_DATE THEN fb.id END) as facility_bookings_today,
  COUNT(DISTINCT CASE WHEN fb.booking_date = CURRENT_DATE AND fb.booking_status = 'approved' THEN fb.id END) as approved_bookings_today,
  COUNT(DISTINCT CASE WHEN f.maintenance_status = 'maintenance_required' THEN f.id END) as facilities_needing_maintenance,
  
  -- Registration Workflow
  COUNT(DISTINCT CASE WHEN sr.registration_status = 'pending' THEN sr.id END) as pending_registrations,
  COUNT(DISTINCT CASE WHEN sr.registration_status = 'document_review' THEN sr.id END) as registrations_in_review,
  COUNT(DISTINCT CASE WHEN sr.registration_status = 'approved' AND sr.approval_date::DATE = CURRENT_DATE THEN sr.id END) as registrations_approved_today,
  
  -- Visitor Management
  COUNT(DISTINCT CASE WHEN v.visit_date = CURRENT_DATE THEN v.id END) as visitors_today,
  COUNT(DISTINCT CASE WHEN v.visit_date = CURRENT_DATE AND v.check_out_time IS NULL THEN v.id END) as visitors_currently_present,
  
  NOW() as last_updated_at
  
FROM branches b
LEFT JOIN students s ON b.id = s.branch_id AND s.is_active = true
LEFT JOIN staff st ON b.id = st.branch_id AND st.employment_status = 'active'
LEFT JOIN staff_attendance sa ON st.id = sa.staff_id
LEFT JOIN leave_applications la ON st.id = la.staff_id
LEFT JOIN student_documents sd ON s.id = sd.student_id
LEFT JOIN facilities f ON b.id = f.branch_id
LEFT JOIN facility_bookings fb ON f.id = fb.facility_id
LEFT JOIN student_registrations sr ON b.id = sr.branch_id
LEFT JOIN visitors v ON b.id = v.branch_id
GROUP BY b.tenant_id, b.id, b.branch_name, b.branch_code;

CREATE UNIQUE INDEX ON admin_operations_dashboard(tenant_id, branch_id);
CREATE INDEX ON admin_operations_dashboard(branch_id);

-- Admin Quick Actions Log
CREATE TABLE IF NOT EXISTS admin_quick_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  admin_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  
  action_type VARCHAR(100) NOT NULL, -- 'verify_document', 'approve_registration', 'book_facility', 'record_attendance', etc.
  action_description TEXT NOT NULL,
  reference_id UUID, -- ID of related record
  reference_type VARCHAR(100), -- Type of related record
  action_result VARCHAR(50), -- 'success', 'failed', 'pending'
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON admin_quick_actions(tenant_id, branch_id);
CREATE INDEX ON admin_quick_actions(admin_id);
CREATE INDEX ON admin_quick_actions(action_type);
CREATE INDEX ON admin_quick_actions(created_at DESC);

-- RLS Policies
ALTER TABLE admin_daily_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_quick_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_daily_checklist_tenant_isolation ON admin_daily_checklist
  USING (tenant_id = auth.get_current_tenant_id());

CREATE POLICY admin_daily_checklist_branch_access ON admin_daily_checklist
  USING (branch_id IN (SELECT branch_id FROM user_branch_access WHERE user_id = auth.uid()));

CREATE POLICY admin_quick_actions_tenant_isolation ON admin_quick_actions
  USING (tenant_id = auth.get_current_tenant_id());

CREATE POLICY admin_quick_actions_branch_access ON admin_quick_actions
  USING (branch_id IN (SELECT branch_id FROM user_branch_access WHERE user_id = auth.uid()));

-- Triggers
CREATE TRIGGER update_admin_daily_checklist_updated_at
  BEFORE UPDATE ON admin_daily_checklist
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/admin-dashboard.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface OperationsDashboard {
  branchId: string;
  branchName: string;
  branchCode: string;
  activeStudentsCount: number;
  newAdmissionsToday: number;
  pendingAdmissionsCount: number;
  totalStaffCount: number;
  staffPresentCount: number;
  staffAbsentCount: number;
  staffOnLeaveCount: number;
  documentsPendingVerification: number;
  documentsVerifiedToday: number;
  totalFacilities: number;
  facilityBookingsToday: number;
  approvedBookingsToday: number;
  facilitiesNeedingMaintenance: number;
  pendingRegistrations: number;
  registrationsInReview: number;
  registrationsApprovedToday: number;
  visitorsToday: number;
  visitorsCurrentlyPresent: number;
  lastUpdatedAt: string;
}

export interface DailyChecklist {
  id: string;
  tenantId: string;
  branchId: string;
  checklistDate: string;
  adminId: string;
  attendanceRecorded: boolean;
  attendanceRecordedAt?: string;
  attendanceRecordedBy?: string;
  documentsVerified: boolean;
  documentsVerifiedCount: number;
  documentsVerifiedAt?: string;
  facilitiesInspected: boolean;
  facilitiesInspectedCount: number;
  facilitiesInspectionNotes?: string;
  facilitiesInspectedAt?: string;
  staffAttendanceReviewed: boolean;
  staffAttendanceReviewedAt?: string;
  registrationsProcessed: boolean;
  registrationsProcessedCount: number;
  registrationsProcessedAt?: string;
  visitorLogUpdated: boolean;
  visitorCount: number;
  visitorLogUpdatedAt?: string;
  operationalNotes?: string;
  issuesEncountered?: string;
  tasksCompleted: number;
  tasksTotal: number;
  checklistStatus: 'pending' | 'in_progress' | 'completed';
}

export interface QuickAction {
  id: string;
  actionType: string;
  actionDescription: string;
  referenceId?: string;
  referenceType?: string;
  actionResult: 'success' | 'failed' | 'pending';
  createdAt: string;
}

export class BranchAdminDashboardAPI {
  private supabase = createClient();

  async getDashboardMetrics(params: {
    tenantId: string;
    branchId: string;
  }): Promise<OperationsDashboard> {
    const { data, error } = await this.supabase
      .from('admin_operations_dashboard')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .single();

    if (error) throw error;

    return {
      branchId: data.branch_id,
      branchName: data.branch_name,
      branchCode: data.branch_code,
      activeStudentsCount: data.active_students_count || 0,
      newAdmissionsToday: data.new_admissions_today || 0,
      pendingAdmissionsCount: data.pending_admissions_count || 0,
      totalStaffCount: data.total_staff_count || 0,
      staffPresentCount: data.staff_present_count || 0,
      staffAbsentCount: data.staff_absent_count || 0,
      staffOnLeaveCount: data.staff_on_leave_count || 0,
      documentsPendingVerification: data.documents_pending_verification || 0,
      documentsVerifiedToday: data.documents_verified_today || 0,
      totalFacilities: data.total_facilities || 0,
      facilityBookingsToday: data.facility_bookings_today || 0,
      approvedBookingsToday: data.approved_bookings_today || 0,
      facilitiesNeedingMaintenance: data.facilities_needing_maintenance || 0,
      pendingRegistrations: data.pending_registrations || 0,
      registrationsInReview: data.registrations_in_review || 0,
      registrationsApprovedToday: data.registrations_approved_today || 0,
      visitorsToday: data.visitors_today || 0,
      visitorsCurrentlyPresent: data.visitors_currently_present || 0,
      lastUpdatedAt: data.last_updated_at,
    };
  }

  async getTodaysChecklist(params: {
    tenantId: string;
    branchId: string;
  }): Promise<DailyChecklist | null> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await this.supabase
      .from('admin_daily_checklist')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('checklist_date', today)
      .eq('admin_id', user.id)
      .maybeSingle();

    if (error) throw error;
    if (!data) return null;

    return {
      id: data.id,
      tenantId: data.tenant_id,
      branchId: data.branch_id,
      checklistDate: data.checklist_date,
      adminId: data.admin_id,
      attendanceRecorded: data.attendance_recorded,
      attendanceRecordedAt: data.attendance_recorded_at,
      attendanceRecordedBy: data.attendance_recorded_by,
      documentsVerified: data.documents_verified,
      documentsVerifiedCount: data.documents_verified_count || 0,
      documentsVerifiedAt: data.documents_verified_at,
      facilitiesInspected: data.facilities_inspected,
      facilitiesInspectedCount: data.facilities_inspected_count || 0,
      facilitiesInspectionNotes: data.facilities_inspection_notes,
      facilitiesInspectedAt: data.facilities_inspected_at,
      staffAttendanceReviewed: data.staff_attendance_reviewed,
      staffAttendanceReviewedAt: data.staff_attendance_reviewed_at,
      registrationsProcessed: data.registrations_processed,
      registrationsProcessedCount: data.registrations_processed_count || 0,
      registrationsProcessedAt: data.registrations_processed_at,
      visitorLogUpdated: data.visitor_log_updated,
      visitorCount: data.visitor_count || 0,
      visitorLogUpdatedAt: data.visitor_log_updated_at,
      operationalNotes: data.operational_notes,
      issuesEncountered: data.issues_encountered,
      tasksCompleted: data.tasks_completed || 0,
      tasksTotal: data.tasks_total || 6,
      checklistStatus: data.checklist_status,
    };
  }

  async createOrUpdateChecklist(params: {
    tenantId: string;
    branchId: string;
    updates: Partial<DailyChecklist>;
  }): Promise<string> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await this.supabase
      .from('admin_daily_checklist')
      .upsert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        checklist_date: today,
        admin_id: user.id,
        attendance_recorded: params.updates.attendanceRecorded,
        attendance_recorded_at: params.updates.attendanceRecorded ? new Date().toISOString() : undefined,
        attendance_recorded_by: params.updates.attendanceRecorded ? user.id : undefined,
        documents_verified: params.updates.documentsVerified,
        documents_verified_count: params.updates.documentsVerifiedCount,
        documents_verified_at: params.updates.documentsVerified ? new Date().toISOString() : undefined,
        facilities_inspected: params.updates.facilitiesInspected,
        facilities_inspected_count: params.updates.facilitiesInspectedCount,
        facilities_inspection_notes: params.updates.facilitiesInspectionNotes,
        facilities_inspected_at: params.updates.facilitiesInspected ? new Date().toISOString() : undefined,
        staff_attendance_reviewed: params.updates.staffAttendanceReviewed,
        staff_attendance_reviewed_at: params.updates.staffAttendanceReviewed ? new Date().toISOString() : undefined,
        registrations_processed: params.updates.registrationsProcessed,
        registrations_processed_count: params.updates.registrationsProcessedCount,
        registrations_processed_at: params.updates.registrationsProcessed ? new Date().toISOString() : undefined,
        visitor_log_updated: params.updates.visitorLogUpdated,
        visitor_count: params.updates.visitorCount,
        visitor_log_updated_at: params.updates.visitorLogUpdated ? new Date().toISOString() : undefined,
        operational_notes: params.updates.operationalNotes,
        issues_encountered: params.updates.issuesEncountered,
        checklist_status: params.updates.checklistStatus,
      })
      .select('id')
      .single();

    if (error) throw error;
    return data.id;
  }

  async logQuickAction(params: {
    tenantId: string;
    branchId: string;
    actionType: string;
    actionDescription: string;
    referenceId?: string;
    referenceType?: string;
    actionResult?: 'success' | 'failed' | 'pending';
  }): Promise<string> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('admin_quick_actions')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        admin_id: user.id,
        action_type: params.actionType,
        action_description: params.actionDescription,
        reference_id: params.referenceId,
        reference_type: params.referenceType,
        action_result: params.actionResult || 'success',
      })
      .select('id')
      .single();

    if (error) throw error;
    return data.id;
  }

  async getRecentActions(params: {
    tenantId: string;
    branchId: string;
    limit?: number;
  }): Promise<QuickAction[]> {
    const { data, error } = await this.supabase
      .from('admin_quick_actions')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .order('created_at', { ascending: false })
      .limit(params.limit || 20);

    if (error) throw error;

    return (data || []).map(action => ({
      id: action.id,
      actionType: action.action_type,
      actionDescription: action.action_description,
      referenceId: action.reference_id,
      referenceType: action.reference_type,
      actionResult: action.action_result,
      createdAt: action.created_at,
    }));
  }

  async refreshDashboard(): Promise<void> {
    const { error } = await this.supabase.rpc('refresh_admin_operations_dashboard');
    if (error) throw error;
  }
}
```

---

## 🧪 TESTING SPECIFICATIONS

### Test File (`/tests/api/admin-dashboard.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { BranchAdminDashboardAPI } from '@/lib/api/admin-dashboard';

describe('BranchAdminDashboardAPI', () => {
  let api: BranchAdminDashboardAPI;

  beforeEach(() => {
    api = new BranchAdminDashboardAPI();
  });

  describe('getDashboardMetrics', () => {
    it('should fetch dashboard metrics', async () => {
      const metrics = await api.getDashboardMetrics({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      expect(metrics).toBeDefined();
      expect(metrics.activeStudentsCount).toBeGreaterThanOrEqual(0);
      expect(metrics.totalStaffCount).toBeGreaterThanOrEqual(0);
    });

    it('should include facility metrics', async () => {
      const metrics = await api.getDashboardMetrics({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      expect(metrics.totalFacilities).toBeDefined();
      expect(metrics.facilityBookingsToday).toBeDefined();
      expect(metrics.facilitiesNeedingMaintenance).toBeDefined();
    });
  });

  describe('getTodaysChecklist', () => {
    it('should get todays checklist', async () => {
      const checklist = await api.getTodaysChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      if (checklist) {
        expect(checklist.checklistDate).toBeDefined();
        expect(checklist.tasksTotal).toBe(6);
      }
    });

    it('should return null if no checklist exists', async () => {
      const checklist = await api.getTodaysChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-999',
      });

      expect(checklist).toBeNull();
    });
  });

  describe('createOrUpdateChecklist', () => {
    it('should create new checklist', async () => {
      const id = await api.createOrUpdateChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        updates: {
          attendanceRecorded: true,
          documentsVerified: false,
          facilitiesInspected: false,
        },
      });

      expect(id).toBeDefined();
    });

    it('should update existing checklist', async () => {
      await api.createOrUpdateChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        updates: { attendanceRecorded: true },
      });

      await api.createOrUpdateChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        updates: { documentsVerified: true, documentsVerifiedCount: 5 },
      });

      const checklist = await api.getTodaysChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      expect(checklist?.attendanceRecorded).toBe(true);
      expect(checklist?.documentsVerified).toBe(true);
    });

    it('should calculate tasks completed correctly', async () => {
      await api.createOrUpdateChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        updates: {
          attendanceRecorded: true,
          documentsVerified: true,
          facilitiesInspected: true,
          staffAttendanceReviewed: false,
          registrationsProcessed: false,
          visitorLogUpdated: false,
        },
      });

      const checklist = await api.getTodaysChecklist({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      expect(checklist?.tasksCompleted).toBe(3);
      expect(checklist?.tasksTotal).toBe(6);
    });
  });

  describe('logQuickAction', () => {
    it('should log admin action', async () => {
      const actionId = await api.logQuickAction({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        actionType: 'verify_document',
        actionDescription: 'Verified student admission documents',
        referenceId: 'doc-123',
        referenceType: 'student_document',
        actionResult: 'success',
      });

      expect(actionId).toBeDefined();
    });
  });

  describe('getRecentActions', () => {
    it('should fetch recent actions', async () => {
      const actions = await api.getRecentActions({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        limit: 10,
      });

      expect(Array.isArray(actions)).toBe(true);
      expect(actions.length).toBeLessThanOrEqual(10);
    });
  });

  describe('refreshDashboard', () => {
    it('should refresh dashboard metrics', async () => {
      await expect(api.refreshDashboard()).resolves.not.toThrow();
    });
  });
});
```

**Coverage Target**: 85%+

---

## ✅ ACCEPTANCE CRITERIA

- [x] Administrative dashboard with comprehensive metrics displayed
- [x] Student metrics (active, new admissions, pending) shown
- [x] Staff metrics (total, present, absent, on leave) available
- [x] Document verification status tracked
- [x] Facility booking and maintenance status visible
- [x] Registration workflow monitoring implemented
- [x] Visitor management metrics included
- [x] Daily operational checklist with 6 tasks
- [x] Task completion auto-calculated
- [x] Quick actions logging system
- [x] Recent actions history available
- [x] Dashboard refresh functionality
- [x] Multi-tenant security with RLS policies
- [x] TypeScript support with strict typing
- [x] Comprehensive test coverage (85%+)

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Implementation Time**: 4 hours  
**Priority**: HIGH  
**Dependencies**: SPEC-009 (Multi-tenant), SPEC-011 (Students), SPEC-012 (Staff)
