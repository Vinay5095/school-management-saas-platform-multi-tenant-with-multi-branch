# SPEC-202: Daily Attendance Monitoring System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-202  
**Title**: Daily Attendance Monitoring System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Attendance Management  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-201  

---

## 📋 DESCRIPTION

Real-time attendance tracking system enabling vice principals to monitor class-wise attendance status, identify absentees, track late arrivals, detect chronic absence patterns, and trigger automated parent notifications.

---

## 🎯 SUCCESS CRITERIA

- [ ] Real-time attendance data displaying
- [ ] Class-wise attendance breakdown working
- [ ] Absentee alerts generating
- [ ] Late arrival tracking functional
- [ ] Parent notifications automated
- [ ] Attendance patterns detected
- [ ] Export functionality working
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- VP Attendance Alerts
CREATE TABLE IF NOT EXISTS vp_attendance_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  alert_date DATE DEFAULT CURRENT_DATE,
  alert_type VARCHAR(50), -- chronic_absence, late_arrival, pattern_detected, unexplained_absence
  
  student_id UUID REFERENCES students(id),
  student_name VARCHAR(200),
  grade_level VARCHAR(20),
  
  alert_details TEXT,
  absence_count INTEGER,
  consecutive_absences INTEGER,
  
  severity VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
  
  status VARCHAR(50) DEFAULT 'active', -- active, investigating, resolved, false_positive
  
  parent_notified BOOLEAN DEFAULT false,
  parent_notified_at TIMESTAMP WITH TIME ZONE,
  
  action_taken TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON vp_attendance_alerts(tenant_id, branch_id, alert_date);
CREATE INDEX ON vp_attendance_alerts(student_id, status);
CREATE INDEX ON vp_attendance_alerts(severity, status);

-- Class Attendance Summary (Materialized View)
CREATE MATERIALIZED VIEW class_attendance_summary AS
SELECT
  a.tenant_id,
  a.branch_id,
  c.id as class_id,
  c.class_name,
  c.grade_level,
  a.attendance_date,
  
  COUNT(DISTINCT e.student_id) as total_students,
  COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.student_id END) as students_present,
  COUNT(DISTINCT CASE WHEN a.status = 'absent' THEN a.student_id END) as students_absent,
  COUNT(DISTINCT CASE WHEN a.status = 'late' THEN a.student_id END) as students_late,
  
  (COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.student_id END)::FLOAT / 
   NULLIF(COUNT(DISTINCT e.student_id), 0) * 100) as attendance_percentage,
  
  NOW() as last_calculated_at
  
FROM classes c
JOIN enrollments e ON c.id = e.class_id AND e.status = 'active'
LEFT JOIN attendance_records a ON e.student_id = a.student_id 
  AND a.class_id = c.id 
  AND a.attendance_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY a.tenant_id, a.branch_id, c.id, c.class_name, c.grade_level, a.attendance_date;

CREATE INDEX ON class_attendance_summary(tenant_id, branch_id, attendance_date);
CREATE INDEX ON class_attendance_summary(class_id);

-- Late Arrival Records
CREATE TABLE IF NOT EXISTS late_arrival_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  student_id UUID NOT NULL REFERENCES students(id),
  arrival_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  scheduled_time TIME NOT NULL,
  actual_arrival_time TIME NOT NULL,
  minutes_late INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (actual_arrival_time - scheduled_time)) / 60
  ) STORED,
  
  reason TEXT,
  excuse_provided BOOLEAN DEFAULT false,
  excuse_verified BOOLEAN DEFAULT false,
  
  recorded_by UUID REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON late_arrival_records(tenant_id, branch_id, arrival_date);
CREATE INDEX ON late_arrival_records(student_id, arrival_date DESC);

-- Function to detect chronic absenteeism
CREATE OR REPLACE FUNCTION detect_chronic_absenteeism(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_days_to_check INTEGER DEFAULT 30,
  p_absence_threshold INTEGER DEFAULT 5
)
RETURNS TABLE (
  student_id UUID,
  student_name VARCHAR,
  grade_level VARCHAR,
  total_absences BIGINT,
  consecutive_absences BIGINT,
  attendance_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id as student_id,
    CONCAT(s.first_name, ' ', s.last_name) as student_name,
    c.grade_level,
    COUNT(CASE WHEN a.status = 'absent' THEN 1 END) as total_absences,
    (
      SELECT COUNT(*)
      FROM (
        SELECT a2.attendance_date,
               a2.status,
               LAG(a2.status) OVER (ORDER BY a2.attendance_date) as prev_status
        FROM attendance_records a2
        WHERE a2.student_id = s.id
          AND a2.attendance_date >= CURRENT_DATE - p_days_to_check
        ORDER BY a2.attendance_date DESC
      ) sub
      WHERE status = 'absent' AND (prev_status = 'absent' OR prev_status IS NULL)
    ) as consecutive_absences,
    (COUNT(CASE WHEN a.status = 'present' THEN 1 END)::FLOAT / 
     NULLIF(COUNT(a.id), 0) * 100) as attendance_rate
  FROM students s
  JOIN enrollments e ON s.id = e.student_id
  JOIN classes c ON e.class_id = c.id
  LEFT JOIN attendance_records a ON s.id = a.student_id 
    AND a.attendance_date >= CURRENT_DATE - p_days_to_check
  WHERE s.tenant_id = p_tenant_id
    AND s.branch_id = p_branch_id
    AND s.status = 'active'
  GROUP BY s.id, s.first_name, s.last_name, c.grade_level
  HAVING COUNT(CASE WHEN a.status = 'absent' THEN 1 END) >= p_absence_threshold
  ORDER BY total_absences DESC;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create attendance alert
CREATE OR REPLACE FUNCTION create_attendance_alert()
RETURNS TRIGGER AS $$
DECLARE
  v_absence_count INTEGER;
  v_consecutive_count INTEGER;
BEGIN
  -- Check if student has been absent frequently
  SELECT COUNT(*) INTO v_absence_count
  FROM attendance_records
  WHERE student_id = NEW.student_id
    AND attendance_date >= CURRENT_DATE - INTERVAL '30 days'
    AND status = 'absent';
  
  -- Check consecutive absences
  SELECT COUNT(*) INTO v_consecutive_count
  FROM (
    SELECT attendance_date
    FROM attendance_records
    WHERE student_id = NEW.student_id
      AND attendance_date >= CURRENT_DATE - INTERVAL '7 days'
      AND status = 'absent'
    ORDER BY attendance_date DESC
  ) sub;
  
  -- Create alert if threshold exceeded
  IF NEW.status = 'absent' AND (v_absence_count >= 5 OR v_consecutive_count >= 3) THEN
    INSERT INTO vp_attendance_alerts (
      tenant_id,
      branch_id,
      alert_type,
      student_id,
      absence_count,
      consecutive_absences,
      severity,
      alert_details
    )
    VALUES (
      NEW.tenant_id,
      NEW.branch_id,
      CASE 
        WHEN v_consecutive_count >= 3 THEN 'chronic_absence'
        ELSE 'pattern_detected'
      END,
      NEW.student_id,
      v_absence_count,
      v_consecutive_count,
      CASE 
        WHEN v_consecutive_count >= 5 OR v_absence_count >= 10 THEN 'critical'
        WHEN v_consecutive_count >= 3 OR v_absence_count >= 7 THEN 'high'
        ELSE 'medium'
      END,
      'Student has ' || v_absence_count || ' absences in last 30 days with ' || 
      v_consecutive_count || ' consecutive absences'
    )
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER attendance_alert_trigger
  AFTER INSERT ON attendance_records
  FOR EACH ROW
  EXECUTE FUNCTION create_attendance_alert();

-- Enable RLS
ALTER TABLE vp_attendance_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE late_arrival_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY vp_attendance_alerts_isolation ON vp_attendance_alerts
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY late_arrival_records_isolation ON late_arrival_records
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/attendance-monitoring.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface AttendanceAlert {
  id: string;
  alertType: string;
  studentId: string;
  studentName: string;
  gradeLevel: string;
  absenceCount: number;
  consecutiveAbsences: number;
  severity: string;
  status: string;
  parentNotified: boolean;
}

export interface ClassAttendance {
  classId: string;
  className: string;
  gradeLevel: string;
  totalStudents: number;
  studentsPresent: number;
  studentsAbsent: number;
  studentsLate: number;
  attendancePercentage: number;
}

export interface ChronicAbsentee {
  studentId: string;
  studentName: string;
  gradeLevel: string;
  totalAbsences: number;
  consecutiveAbsences: number;
  attendanceRate: number;
}

export class AttendanceMonitoringAPI {
  private supabase = createClient();

  async getAttendanceAlerts(params: {
    tenantId: string;
    branchId: string;
    status?: string;
    severity?: string;
  }): Promise<AttendanceAlert[]> {
    let query = this.supabase
      .from('vp_attendance_alerts')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.status) {
      query = query.eq('status', params.status);
    }

    if (params.severity) {
      query = query.eq('severity', params.severity);
    }

    const { data, error } = await query.order('alert_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(alert => ({
      id: alert.id,
      alertType: alert.alert_type,
      studentId: alert.student_id,
      studentName: alert.student_name,
      gradeLevel: alert.grade_level,
      absenceCount: alert.absence_count,
      consecutiveAbsences: alert.consecutive_absences,
      severity: alert.severity,
      status: alert.status,
      parentNotified: alert.parent_notified,
    }));
  }

  async getClassAttendance(params: {
    tenantId: string;
    branchId: string;
    date?: Date;
  }): Promise<ClassAttendance[]> {
    const attendanceDate = params.date || new Date();

    const { data, error } = await this.supabase
      .from('class_attendance_summary')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('attendance_date', attendanceDate.toISOString().split('T')[0])
      .order('attendance_percentage', { ascending: false });

    if (error) throw error;

    return (data || []).map(item => ({
      classId: item.class_id,
      className: item.class_name,
      gradeLevel: item.grade_level,
      totalStudents: item.total_students,
      studentsPresent: item.students_present,
      studentsAbsent: item.students_absent,
      studentsLate: item.students_late,
      attendancePercentage: item.attendance_percentage || 0,
    }));
  }

  async getChronicAbsentees(params: {
    tenantId: string;
    branchId: string;
    daysToCheck?: number;
    absenceThreshold?: number;
  }): Promise<ChronicAbsentee[]> {
    const { data, error } = await this.supabase.rpc('detect_chronic_absenteeism', {
      p_tenant_id: params.tenantId,
      p_branch_id: params.branchId,
      p_days_to_check: params.daysToCheck || 30,
      p_absence_threshold: params.absenceThreshold || 5,
    });

    if (error) throw error;

    return (data || []).map((item: any) => ({
      studentId: item.student_id,
      studentName: item.student_name,
      gradeLevel: item.grade_level,
      totalAbsences: item.total_absences,
      consecutiveAbsences: item.consecutive_absences,
      attendanceRate: item.attendance_rate || 0,
    }));
  }

  async recordLateArrival(params: {
    tenantId: string;
    branchId: string;
    studentId: string;
    scheduledTime: string;
    actualArrivalTime: string;
    reason?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('late_arrival_records')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        student_id: params.studentId,
        scheduled_time: params.scheduledTime,
        actual_arrival_time: params.actualArrivalTime,
        reason: params.reason,
        recorded_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async resolveAlert(params: {
    alertId: string;
    actionTaken: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('vp_attendance_alerts')
      .update({
        status: 'resolved',
        action_taken: params.actionTaken,
        resolved_at: new Date().toISOString(),
        resolved_by: user?.id,
      })
      .eq('id', params.alertId);

    if (error) throw error;
  }

  async notifyParent(params: {
    alertId: string;
  }) {
    const { error } = await this.supabase
      .from('vp_attendance_alerts')
      .update({
        parent_notified: true,
        parent_notified_at: new Date().toISOString(),
      })
      .eq('id', params.alertId);

    if (error) throw error;
  }

  async getAttendanceTrends(params: {
    tenantId: string;
    branchId: string;
    days?: number;
  }) {
    const daysBack = params.days || 30;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysBack);

    const { data, error } = await this.supabase
      .from('class_attendance_summary')
      .select('attendance_date, attendance_percentage')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .gte('attendance_date', startDate.toISOString().split('T')[0])
      .order('attendance_date');

    if (error) throw error;

    // Group by date and calculate average
    const trends = data.reduce((acc: any[], item) => {
      const date = item.attendance_date;
      const existing = acc.find(t => t.date === date);
      if (existing) {
        existing.totalPercentage += item.attendance_percentage;
        existing.count += 1;
      } else {
        acc.push({
          date,
          totalPercentage: item.attendance_percentage,
          count: 1,
        });
      }
      return acc;
    }, []);

    return trends.map(t => ({
      date: t.date,
      averageAttendance: t.totalPercentage / t.count,
    }));
  }
}

export const attendanceMonitoringAPI = new AttendanceMonitoringAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { AttendanceMonitoringAPI } from '../attendance-monitoring';

describe('AttendanceMonitoringAPI', () => {
  let api: AttendanceMonitoringAPI;

  beforeEach(() => {
    api = new AttendanceMonitoringAPI();
  });

  it('fetches attendance alerts', async () => {
    const alerts = await api.getAttendanceAlerts({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(alerts)).toBe(true);
  });

  it('identifies chronic absentees', async () => {
    const absentees = await api.getChronicAbsentees({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      absenceThreshold: 5,
    });

    expect(Array.isArray(absentees)).toBe(true);
  });

  it('records late arrival', async () => {
    const record = await api.recordLateArrival({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      studentId: 'test-student',
      scheduledTime: '08:00:00',
      actualArrivalTime: '08:30:00',
      reason: 'Traffic',
    });

    expect(record).toHaveProperty('id');
  });

  it('gets class attendance summary', async () => {
    const attendance = await api.getClassAttendance({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(attendance)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Attendance alerts displaying correctly
- [ ] Class-wise attendance summary accurate
- [ ] Chronic absenteeism detection working
- [ ] Late arrival tracking functional
- [ ] Parent notifications automated
- [ ] Alert resolution workflow operational
- [ ] Attendance trends rendering
- [ ] Export functionality working
- [ ] Real-time updates functioning
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
