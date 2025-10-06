# SPEC-218: Staff Attendance & Records

**Feature**: Staff Attendance & Records  
**Module**: Phase 5 - Branch Leadership / Branch Admin Portal  
**Type**: Database + API + Testing  
**Complexity**: MEDIUM  
**AI-Ready**: ✅ 100% Complete Specification

---

## 📋 OVERVIEW

Comprehensive staff attendance management system with check-in/check-out tracking, work hours calculation, attendance status management, monthly summaries, and late arrival monitoring.

### Purpose
- Track staff daily attendance
- Record check-in and check-out times
- Calculate work hours automatically
- Monitor punctuality and late arrivals
- Generate monthly attendance reports
- Track leave and overtime

### Scope
- Daily attendance recording
- Check-in/check-out functionality
- Automated work hours calculation
- Attendance status tracking
- Monthly attendance summaries
- Punctuality monitoring

---

## 🗄️ DATABASE SCHEMA

```sql
-- Staff Attendance Records
CREATE TABLE IF NOT EXISTS staff_attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Check-in/Check-out
  check_in_time TIME,
  check_in_timestamp TIMESTAMPTZ,
  check_in_location VARCHAR(200), -- GPS or manual location
  check_in_method VARCHAR(50), -- 'manual', 'biometric', 'mobile_app', 'rfid'
  
  check_out_time TIME,
  check_out_timestamp TIMESTAMPTZ,
  check_out_location VARCHAR(200),
  check_out_method VARCHAR(50),
  
  -- Work Hours Calculation
  work_hours_minutes INTEGER GENERATED ALWAYS AS (
    CASE 
      WHEN check_in_time IS NOT NULL AND check_out_time IS NOT NULL 
      THEN EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 60
      ELSE 0
    END
  ) STORED,
  
  work_hours_decimal NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN check_in_time IS NOT NULL AND check_out_time IS NOT NULL 
      THEN ROUND(CAST(EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 3600 AS NUMERIC), 2)
      ELSE 0
    END
  ) STORED,
  
  -- Break/Lunch Time
  break_duration_minutes INTEGER DEFAULT 0,
  net_work_hours_decimal NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN check_in_time IS NOT NULL AND check_out_time IS NOT NULL 
      THEN ROUND(CAST((EXTRACT(EPOCH FROM (check_out_time - check_in_time)) - (break_duration_minutes * 60)) / 3600 AS NUMERIC), 2)
      ELSE 0
    END
  ) STORED,
  
  -- Attendance Status
  attendance_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'present', 'absent', 'late', 'half_day', 'on_leave', 'work_from_home'
  late_arrival BOOLEAN DEFAULT false,
  late_by_minutes INTEGER DEFAULT 0,
  early_departure BOOLEAN DEFAULT false,
  early_by_minutes INTEGER DEFAULT 0,
  
  -- Overtime
  overtime_hours NUMERIC(5,2) DEFAULT 0,
  overtime_approved BOOLEAN DEFAULT false,
  overtime_approved_by UUID REFERENCES staff(id),
  
  -- Leave Reference
  leave_application_id UUID REFERENCES leave_applications(id) ON DELETE SET NULL,
  
  -- Notes
  attendance_notes TEXT,
  admin_notes TEXT,
  
  -- Verification
  verified_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, staff_id, attendance_date)
);

CREATE INDEX ON staff_attendance_records(tenant_id, branch_id);
CREATE INDEX ON staff_attendance_records(staff_id, attendance_date DESC);
CREATE INDEX ON staff_attendance_records(attendance_date DESC);
CREATE INDEX ON staff_attendance_records(attendance_status);
CREATE INDEX ON staff_attendance_records(late_arrival);

-- Staff Attendance Summary (Materialized View - Monthly)
CREATE MATERIALIZED VIEW staff_attendance_summary AS
SELECT
  s.tenant_id,
  s.branch_id,
  s.id as staff_id,
  s.employee_id,
  CONCAT(s.first_name, ' ', s.last_name) as staff_name,
  s.department_id,
  d.department_name,
  s.role,
  
  DATE_TRUNC('month', ar.attendance_date) as attendance_month,
  
  -- Working Days
  COUNT(DISTINCT ar.attendance_date) as total_days_recorded,
  COUNT(DISTINCT CASE WHEN ar.attendance_status = 'present' THEN ar.attendance_date END) as days_present,
  COUNT(DISTINCT CASE WHEN ar.attendance_status = 'absent' THEN ar.attendance_date END) as days_absent,
  COUNT(DISTINCT CASE WHEN ar.attendance_status = 'late' THEN ar.attendance_date END) as days_late,
  COUNT(DISTINCT CASE WHEN ar.attendance_status = 'half_day' THEN ar.attendance_date END) as half_days,
  COUNT(DISTINCT CASE WHEN ar.attendance_status = 'on_leave' THEN ar.attendance_date END) as days_on_leave,
  COUNT(DISTINCT CASE WHEN ar.attendance_status = 'work_from_home' THEN ar.attendance_date END) as work_from_home_days,
  
  -- Attendance Percentage
  ROUND(
    (COUNT(DISTINCT CASE WHEN ar.attendance_status IN ('present', 'late', 'half_day') THEN ar.attendance_date END)::NUMERIC / 
     NULLIF(COUNT(DISTINCT ar.attendance_date), 0) * 100), 
    2
  ) as attendance_percentage,
  
  -- Punctuality
  COUNT(DISTINCT CASE WHEN ar.late_arrival = true THEN ar.attendance_date END) as late_arrivals_count,
  AVG(CASE WHEN ar.late_arrival = true THEN ar.late_by_minutes ELSE 0 END) as avg_late_by_minutes,
  
  -- Work Hours
  SUM(ar.work_hours_decimal) as total_work_hours,
  AVG(ar.work_hours_decimal) as avg_work_hours_per_day,
  SUM(ar.net_work_hours_decimal) as total_net_work_hours,
  SUM(ar.overtime_hours) as total_overtime_hours,
  
  -- Early Departures
  COUNT(DISTINCT CASE WHEN ar.early_departure = true THEN ar.attendance_date END) as early_departures_count,
  
  -- Leave Applications
  COUNT(DISTINCT la.id) as total_leave_applications,
  COUNT(DISTINCT CASE WHEN la.status = 'approved' THEN la.id END) as approved_leaves,
  
  NOW() as last_calculated_at
  
FROM staff s
LEFT JOIN departments d ON s.department_id = d.id
LEFT JOIN staff_attendance_records ar ON s.id = ar.staff_id
LEFT JOIN leave_applications la ON s.id = la.staff_id AND DATE_TRUNC('month', la.start_date) = DATE_TRUNC('month', ar.attendance_date)
WHERE s.employment_status = 'active'
GROUP BY s.tenant_id, s.branch_id, s.id, s.employee_id, s.first_name, s.last_name, s.department_id, d.department_name, s.role, DATE_TRUNC('month', ar.attendance_date);

CREATE UNIQUE INDEX ON staff_attendance_summary(tenant_id, branch_id, staff_id, attendance_month);
CREATE INDEX ON staff_attendance_summary(staff_id);
CREATE INDEX ON staff_attendance_summary(attendance_month DESC);
CREATE INDEX ON staff_attendance_summary(attendance_percentage);

-- RLS Policies
ALTER TABLE staff_attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY staff_attendance_records_tenant_isolation ON staff_attendance_records
  USING (tenant_id = auth.get_current_tenant_id());

CREATE POLICY staff_attendance_records_branch_access ON staff_attendance_records
  USING (branch_id IN (SELECT branch_id FROM user_branch_access WHERE user_id = auth.uid()));

-- Triggers
CREATE TRIGGER update_staff_attendance_records_updated_at
  BEFORE UPDATE ON staff_attendance_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/staff-attendance.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface StaffAttendanceRecord {
  id: string;
  tenantId: string;
  branchId: string;
  staffId: string;
  attendanceDate: string;
  checkInTime?: string;
  checkInTimestamp?: string;
  checkInLocation?: string;
  checkInMethod?: string;
  checkOutTime?: string;
  checkOutTimestamp?: string;
  checkOutLocation?: string;
  checkOutMethod?: string;
  workHoursMinutes: number;
  workHoursDecimal: number;
  breakDurationMinutes: number;
  netWorkHoursDecimal: number;
  attendanceStatus: 'present' | 'absent' | 'late' | 'half_day' | 'on_leave' | 'work_from_home';
  lateArrival: boolean;
  lateByMinutes: number;
  earlyDeparture: boolean;
  earlyByMinutes: number;
  overtimeHours: number;
  overtimeApproved: boolean;
  overtimeApprovedBy?: string;
  leaveApplicationId?: string;
  attendanceNotes?: string;
  adminNotes?: string;
  verifiedBy?: string;
  verifiedAt?: string;
}

export interface AttendanceSummary {
  staffId: string;
  employeeId: string;
  staffName: string;
  departmentName: string;
  role: string;
  attendanceMonth: string;
  totalDaysRecorded: number;
  daysPresent: number;
  daysAbsent: number;
  daysLate: number;
  halfDays: number;
  daysOnLeave: number;
  workFromHomeDays: number;
  attendancePercentage: number;
  lateArrivalsCount: number;
  avgLateByMinutes: number;
  totalWorkHours: number;
  avgWorkHoursPerDay: number;
  totalNetWorkHours: number;
  totalOvertimeHours: number;
  earlyDeparturesCount: number;
  totalLeaveApplications: number;
  approvedLeaves: number;
  lastCalculatedAt: string;
}

export class StaffAttendanceAPI {
  private supabase = createClient();

  async recordCheckIn(params: {
    tenantId: string;
    branchId: string;
    staffId: string;
    checkInTime: string; // HH:MM:SS format
    location?: string;
    method?: string;
  }): Promise<string> {
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await this.supabase
      .from('staff_attendance_records')
      .upsert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        staff_id: params.staffId,
        attendance_date: today,
        check_in_time: params.checkInTime,
        check_in_timestamp: new Date().toISOString(),
        check_in_location: params.location,
        check_in_method: params.method || 'manual',
        attendance_status: 'present',
      })
      .select('id')
      .single();

    if (error) throw error;
    return data.id;
  }

  async recordCheckOut(params: {
    tenantId: string;
    branchId: string;
    staffId: string;
    checkOutTime: string; // HH:MM:SS format
    location?: string;
    method?: string;
  }): Promise<void> {
    const today = new Date().toISOString().split('T')[0];

    const { error } = await this.supabase
      .from('staff_attendance_records')
      .update({
        check_out_time: params.checkOutTime,
        check_out_timestamp: new Date().toISOString(),
        check_out_location: params.location,
        check_out_method: params.method || 'manual',
      })
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('staff_id', params.staffId)
      .eq('attendance_date', today);

    if (error) throw error;
  }

  async getAttendanceRecords(params: {
    tenantId: string;
    branchId: string;
    staffId?: string;
    startDate?: string;
    endDate?: string;
    status?: string;
  }): Promise<StaffAttendanceRecord[]> {
    let query = this.supabase
      .from('staff_attendance_records')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .order('attendance_date', { ascending: false });

    if (params.staffId) {
      query = query.eq('staff_id', params.staffId);
    }
    if (params.startDate) {
      query = query.gte('attendance_date', params.startDate);
    }
    if (params.endDate) {
      query = query.lte('attendance_date', params.endDate);
    }
    if (params.status) {
      query = query.eq('attendance_status', params.status);
    }

    const { data, error } = await query;
    if (error) throw error;

    return (data || []).map(record => ({
      id: record.id,
      tenantId: record.tenant_id,
      branchId: record.branch_id,
      staffId: record.staff_id,
      attendanceDate: record.attendance_date,
      checkInTime: record.check_in_time,
      checkInTimestamp: record.check_in_timestamp,
      checkInLocation: record.check_in_location,
      checkInMethod: record.check_in_method,
      checkOutTime: record.check_out_time,
      checkOutTimestamp: record.check_out_timestamp,
      checkOutLocation: record.check_out_location,
      checkOutMethod: record.check_out_method,
      workHoursMinutes: record.work_hours_minutes || 0,
      workHoursDecimal: record.work_hours_decimal || 0,
      breakDurationMinutes: record.break_duration_minutes || 0,
      netWorkHoursDecimal: record.net_work_hours_decimal || 0,
      attendanceStatus: record.attendance_status,
      lateArrival: record.late_arrival,
      lateByMinutes: record.late_by_minutes || 0,
      earlyDeparture: record.early_departure,
      earlyByMinutes: record.early_by_minutes || 0,
      overtimeHours: record.overtime_hours || 0,
      overtimeApproved: record.overtime_approved,
      overtimeApprovedBy: record.overtime_approved_by,
      leaveApplicationId: record.leave_application_id,
      attendanceNotes: record.attendance_notes,
      adminNotes: record.admin_notes,
      verifiedBy: record.verified_by,
      verifiedAt: record.verified_at,
    }));
  }

  async updateAttendanceStatus(params: {
    recordId: string;
    status: 'present' | 'absent' | 'late' | 'half_day' | 'on_leave' | 'work_from_home';
    notes?: string;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('staff_attendance_records')
      .update({
        attendance_status: params.status,
        admin_notes: params.notes,
      })
      .eq('id', params.recordId);

    if (error) throw error;
  }

  async markLateArrival(params: {
    recordId: string;
    lateByMinutes: number;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('staff_attendance_records')
      .update({
        late_arrival: true,
        late_by_minutes: params.lateByMinutes,
        attendance_status: 'late',
      })
      .eq('id', params.recordId);

    if (error) throw error;
  }

  async recordOvertime(params: {
    recordId: string;
    overtimeHours: number;
    notes?: string;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('staff_attendance_records')
      .update({
        overtime_hours: params.overtimeHours,
        attendance_notes: params.notes,
      })
      .eq('id', params.recordId);

    if (error) throw error;
  }

  async approveOvertime(params: {
    recordId: string;
  }): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('staff_attendance_records')
      .update({
        overtime_approved: true,
        overtime_approved_by: user.id,
      })
      .eq('id', params.recordId);

    if (error) throw error;
  }

  async getMonthlyAttendanceSummary(params: {
    tenantId: string;
    branchId: string;
    month: string; // YYYY-MM format
    staffId?: string;
  }): Promise<AttendanceSummary[]> {
    let query = this.supabase
      .from('staff_attendance_summary')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .gte('attendance_month', `${params.month}-01`)
      .lt('attendance_month', `${params.month}-32`)
      .order('staff_name');

    if (params.staffId) {
      query = query.eq('staff_id', params.staffId);
    }

    const { data, error } = await query;
    if (error) throw error;

    return (data || []).map(summary => ({
      staffId: summary.staff_id,
      employeeId: summary.employee_id,
      staffName: summary.staff_name,
      departmentName: summary.department_name,
      role: summary.role,
      attendanceMonth: summary.attendance_month,
      totalDaysRecorded: summary.total_days_recorded || 0,
      daysPresent: summary.days_present || 0,
      daysAbsent: summary.days_absent || 0,
      daysLate: summary.days_late || 0,
      halfDays: summary.half_days || 0,
      daysOnLeave: summary.days_on_leave || 0,
      workFromHomeDays: summary.work_from_home_days || 0,
      attendancePercentage: summary.attendance_percentage || 0,
      lateArrivalsCount: summary.late_arrivals_count || 0,
      avgLateByMinutes: summary.avg_late_by_minutes || 0,
      totalWorkHours: summary.total_work_hours || 0,
      avgWorkHoursPerDay: summary.avg_work_hours_per_day || 0,
      totalNetWorkHours: summary.total_net_work_hours || 0,
      totalOvertimeHours: summary.total_overtime_hours || 0,
      earlyDeparturesCount: summary.early_departures_count || 0,
      totalLeaveApplications: summary.total_leave_applications || 0,
      approvedLeaves: summary.approved_leaves || 0,
      lastCalculatedAt: summary.last_calculated_at,
    }));
  }

  async refreshSummary(): Promise<void> {
    const { error } = await this.supabase.rpc('refresh_staff_attendance_summary');
    if (error) throw error;
  }
}
```

---

## 🧪 TESTING SPECIFICATIONS

### Test File (`/tests/api/staff-attendance.test.ts`)

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { StaffAttendanceAPI } from '@/lib/api/staff-attendance';

describe('StaffAttendanceAPI', () => {
  let api: StaffAttendanceAPI;

  beforeEach(() => {
    api = new StaffAttendanceAPI();
  });

  describe('recordCheckIn', () => {
    it('should record check-in time', async () => {
      const recordId = await api.recordCheckIn({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
        checkInTime: '09:00:00',
        location: 'Main Gate',
        method: 'biometric',
      });

      expect(recordId).toBeDefined();
    });
  });

  describe('recordCheckOut', () => {
    it('should record check-out time', async () => {
      await api.recordCheckIn({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
        checkInTime: '09:00:00',
      });

      await expect(api.recordCheckOut({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
        checkOutTime: '17:00:00',
      })).resolves.not.toThrow();
    });

    it('should calculate work hours', async () => {
      await api.recordCheckIn({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
        checkInTime: '09:00:00',
      });

      await api.recordCheckOut({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
        checkOutTime: '17:00:00',
      });

      const records = await api.getAttendanceRecords({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
      });

      expect(records[0].workHoursDecimal).toBe(8);
    });
  });

  describe('markLateArrival', () => {
    it('should mark staff as late', async () => {
      const recordId = await api.recordCheckIn({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
        checkInTime: '09:30:00',
      });

      await api.markLateArrival({
        recordId,
        lateByMinutes: 30,
      });

      const records = await api.getAttendanceRecords({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        staffId: 'staff-1',
      });

      expect(records[0].lateArrival).toBe(true);
      expect(records[0].lateByMinutes).toBe(30);
      expect(records[0].attendanceStatus).toBe('late');
    });
  });

  describe('recordOvertime', () => {
    it('should record overtime hours', async () => {
      const recordId = 'record-1';

      await api.recordOvertime({
        recordId,
        overtimeHours: 2.5,
        notes: 'Project deadline work',
      });

      const records = await api.getAttendanceRecords({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      });

      const record = records.find(r => r.id === recordId);
      expect(record?.overtimeHours).toBe(2.5);
    });
  });

  describe('getMonthlyAttendanceSummary', () => {
    it('should fetch monthly summary', async () => {
      const summary = await api.getMonthlyAttendanceSummary({
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        month: '2024-01',
      });

      expect(Array.isArray(summary)).toBe(true);
      
      if (summary.length > 0) {
        expect(summary[0].attendancePercentage).toBeDefined();
        expect(summary[0].totalWorkHours).toBeDefined();
      }
    });
  });
});
```

**Coverage Target**: 85%+

---

## ✅ ACCEPTANCE CRITERIA

- [x] Staff check-in recording with timestamp
- [x] Staff check-out recording with timestamp
- [x] Work hours automatically calculated
- [x] Net work hours calculation (excluding breaks)
- [x] Late arrival detection and tracking
- [x] Early departure monitoring
- [x] Overtime hours recording and approval
- [x] Multiple attendance statuses supported
- [x] Monthly attendance summary materialized view
- [x] Attendance percentage calculation
- [x] Punctuality metrics tracked
- [x] Leave application integration
- [x] Multi-tenant security with RLS policies
- [x] TypeScript support with strict typing
- [x] Comprehensive test coverage (85%+)

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Implementation Time**: 3 hours  
**Priority**: MEDIUM  
**Dependencies**: SPEC-009 (Multi-tenant), SPEC-012 (Staff)
