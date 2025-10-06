# SPEC-222: Attendance Marking System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-222  
**Title**: Attendance Marking System  
**Phase**: Phase 6 - Academic Staff Portals  
**Portal**: Teacher Portal  
**Category**: Attendance Management  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 8 hours  
**Dependencies**: SPEC-221, SPEC-011  

---

## 📋 DESCRIPTION

Comprehensive attendance marking system allowing teachers to mark attendance for their classes (daily or period-wise), track attendance history, generate reports, handle late arrivals, early departures, and manage leave requests with bulk operations and quick-mark features.

---

## 🎯 SUCCESS CRITERIA

- [ ] Daily and period-wise attendance marking functional
- [ ] Bulk mark (all present/absent) working
- [ ] Quick student search operational
- [ ] Attendance history viewable
- [ ] Late/early departure recording functional
- [ ] Leave request integration working
- [ ] Real-time validation operational
- [ ] Mobile-friendly interface
- [ ] Offline mode support
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Enhanced Attendance Records
CREATE TABLE IF NOT EXISTS attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Student and class
  student_id UUID NOT NULL REFERENCES students(id),
  class_id UUID NOT NULL REFERENCES classes(id),
  section_id UUID REFERENCES sections(id),
  subject_id UUID REFERENCES subjects(id),
  
  -- Teacher and session
  teacher_id UUID NOT NULL REFERENCES auth.users(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  
  -- Attendance details
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  period_number INTEGER, -- NULL for full-day attendance
  time_slot VARCHAR(50), -- 'morning', 'afternoon', 'period_1', etc.
  
  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'present',
  
  -- Time tracking
  check_in_time TIME,
  check_out_time TIME,
  is_late BOOLEAN DEFAULT false,
  late_duration INTEGER, -- minutes late
  is_early_departure BOOLEAN DEFAULT false,
  
  -- Notes
  remarks TEXT,
  leave_type VARCHAR(50), -- 'sick', 'casual', 'authorized', 'unauthorized'
  leave_reason TEXT,
  leave_document_url TEXT,
  
  -- Approval workflow (for leave)
  requires_approval BOOLEAN DEFAULT false,
  approval_status VARCHAR(20), -- 'pending', 'approved', 'rejected'
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  marked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modified_by UUID REFERENCES auth.users(id),
  modification_reason TEXT,
  
  -- Device info (for audit)
  device_type VARCHAR(50),
  ip_address INET,
  location JSONB, -- {lat, lng, accuracy}
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (
    status IN ('present', 'absent', 'late', 'excused', 'on_leave', 'medical_leave', 'half_day')
  ),
  CONSTRAINT valid_approval_status CHECK (
    approval_status IN ('pending', 'approved', 'rejected')
  ),
  CONSTRAINT unique_attendance_record UNIQUE (
    tenant_id, student_id, attendance_date, period_number, subject_id
  )
);

CREATE INDEX ON attendance_records(tenant_id, branch_id);
CREATE INDEX ON attendance_records(student_id, attendance_date DESC);
CREATE INDEX ON attendance_records(class_id, attendance_date DESC);
CREATE INDEX ON attendance_records(teacher_id, attendance_date DESC);
CREATE INDEX ON attendance_records(attendance_date DESC);
CREATE INDEX ON attendance_records(status);
CREATE INDEX ON attendance_records(period_number) WHERE period_number IS NOT NULL;

-- Attendance Templates (for quick marking)
CREATE TABLE IF NOT EXISTS attendance_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  teacher_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Template details
  template_name VARCHAR(200) NOT NULL,
  class_id UUID NOT NULL REFERENCES classes(id),
  
  -- Configuration
  default_status VARCHAR(20) DEFAULT 'present',
  student_overrides JSONB DEFAULT '{}', -- {student_id: status}
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON attendance_templates(tenant_id, branch_id, teacher_id);
CREATE INDEX ON attendance_templates(class_id);

-- Attendance Statistics (Materialized View)
CREATE MATERIALIZED VIEW attendance_statistics AS
SELECT
  ar.tenant_id,
  ar.branch_id,
  ar.student_id,
  ar.class_id,
  ar.academic_year_id,
  
  -- Date ranges
  DATE_TRUNC('month', ar.attendance_date) as month,
  DATE_TRUNC('week', ar.attendance_date) as week,
  
  -- Counts
  COUNT(*) as total_days,
  COUNT(*) FILTER (WHERE ar.status = 'present') as present_days,
  COUNT(*) FILTER (WHERE ar.status = 'absent') as absent_days,
  COUNT(*) FILTER (WHERE ar.status = 'late') as late_days,
  COUNT(*) FILTER (WHERE ar.status LIKE '%leave%') as leave_days,
  COUNT(*) FILTER (WHERE ar.status = 'excused') as excused_days,
  
  -- Percentages
  ROUND(
    (COUNT(*) FILTER (WHERE ar.status = 'present')::NUMERIC / 
     NULLIF(COUNT(*), 0) * 100), 2
  ) as attendance_percentage,
  
  -- Streaks
  MAX(ar.attendance_date) FILTER (WHERE ar.status = 'present') as last_present_date,
  MAX(ar.attendance_date) FILTER (WHERE ar.status = 'absent') as last_absent_date,
  
  -- Last updated
  NOW() as last_calculated_at
  
FROM attendance_records ar
WHERE ar.attendance_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
  ar.tenant_id, 
  ar.branch_id, 
  ar.student_id, 
  ar.class_id, 
  ar.academic_year_id,
  DATE_TRUNC('month', ar.attendance_date),
  DATE_TRUNC('week', ar.attendance_date);

CREATE INDEX ON attendance_statistics(tenant_id, branch_id, student_id);
CREATE INDEX ON attendance_statistics(class_id, month);
CREATE INDEX ON attendance_statistics(attendance_percentage);

-- Function: Bulk mark attendance
CREATE OR REPLACE FUNCTION bulk_mark_attendance(
  p_class_id UUID,
  p_attendance_date DATE,
  p_period_number INTEGER DEFAULT NULL,
  p_subject_id UUID DEFAULT NULL,
  p_default_status VARCHAR DEFAULT 'present',
  p_student_overrides JSONB DEFAULT '{}'
)
RETURNS TABLE (
  success BOOLEAN,
  records_created INTEGER,
  records_updated INTEGER,
  message TEXT
) AS $$
DECLARE
  v_tenant_id UUID;
  v_branch_id UUID;
  v_teacher_id UUID;
  v_academic_year_id UUID;
  v_student RECORD;
  v_student_status VARCHAR;
  v_records_created INTEGER := 0;
  v_records_updated INTEGER := 0;
BEGIN
  -- Get context
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  v_teacher_id := auth.uid();
  
  -- Get current academic year
  SELECT id INTO v_academic_year_id
  FROM academic_years
  WHERE tenant_id = v_tenant_id
  AND is_current = true
  LIMIT 1;
  
  -- Validate class assignment
  IF NOT EXISTS (
    SELECT 1 FROM class_teachers ct
    WHERE ct.class_id = p_class_id
    AND ct.teacher_id = v_teacher_id
    AND ct.status = 'active'
  ) THEN
    RETURN QUERY SELECT false, 0, 0, 'Teacher not assigned to this class';
    RETURN;
  END IF;
  
  -- Get all students in class
  FOR v_student IN
    SELECT s.id as student_id
    FROM students s
    JOIN student_class_assignments sca ON s.id = sca.student_id
    WHERE sca.class_id = p_class_id
    AND sca.status = 'active'
    AND s.status = 'active'
  LOOP
    -- Get status for this student (override or default)
    v_student_status := COALESCE(
      p_student_overrides->>v_student.student_id::TEXT,
      p_default_status
    );
    
    -- Insert or update attendance
    INSERT INTO attendance_records (
      tenant_id, branch_id, student_id, class_id, subject_id,
      teacher_id, academic_year_id, attendance_date, period_number,
      status, marked_at
    ) VALUES (
      v_tenant_id, v_branch_id, v_student.student_id, p_class_id, p_subject_id,
      v_teacher_id, v_academic_year_id, p_attendance_date, p_period_number,
      v_student_status, NOW()
    )
    ON CONFLICT (tenant_id, student_id, attendance_date, period_number, subject_id)
    DO UPDATE SET
      status = EXCLUDED.status,
      modified_at = NOW(),
      modified_by = v_teacher_id,
      updated_at = NOW()
    RETURNING (xmax = 0) INTO success;
    
    IF success THEN
      v_records_created := v_records_created + 1;
    ELSE
      v_records_updated := v_records_updated + 1;
    END IF;
  END LOOP;
  
  -- Refresh statistics
  REFRESH MATERIALIZED VIEW CONCURRENTLY attendance_statistics;
  
  RETURN QUERY SELECT 
    true, 
    v_records_created, 
    v_records_updated, 
    FORMAT('Marked attendance for %s students', v_records_created + v_records_updated);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get attendance summary for class
CREATE OR REPLACE FUNCTION get_class_attendance_summary(
  p_class_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  total_students INTEGER,
  total_days INTEGER,
  avg_attendance_rate NUMERIC,
  present_count INTEGER,
  absent_count INTEGER,
  late_count INTEGER,
  leave_count INTEGER,
  trend JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(DISTINCT ar.student_id)::INTEGER as total_students,
    COUNT(DISTINCT ar.attendance_date)::INTEGER as total_days,
    ROUND(AVG(
      CASE WHEN ar.status = 'present' THEN 100.0 ELSE 0 END
    ), 2) as avg_attendance_rate,
    COUNT(*) FILTER (WHERE ar.status = 'present')::INTEGER as present_count,
    COUNT(*) FILTER (WHERE ar.status = 'absent')::INTEGER as absent_count,
    COUNT(*) FILTER (WHERE ar.status = 'late')::INTEGER as late_count,
    COUNT(*) FILTER (WHERE ar.status LIKE '%leave%')::INTEGER as leave_count,
    jsonb_agg(
      jsonb_build_object(
        'date', ar.attendance_date,
        'rate', ROUND(
          COUNT(*) FILTER (WHERE ar.status = 'present')::NUMERIC / 
          NULLIF(COUNT(*), 0) * 100, 2
        )
      ) ORDER BY ar.attendance_date
    ) as trend
  FROM attendance_records ar
  WHERE ar.class_id = p_class_id
  AND ar.attendance_date BETWEEN p_start_date AND p_end_date
  GROUP BY ar.class_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-calculate late status
CREATE OR REPLACE FUNCTION calculate_late_status()
RETURNS TRIGGER AS $$
DECLARE
  v_school_start_time TIME;
  v_period_start_time TIME;
BEGIN
  -- Get school start time (from settings or default)
  v_school_start_time := '08:00:00'::TIME;
  
  -- If check-in time is provided
  IF NEW.check_in_time IS NOT NULL THEN
    -- For full-day attendance
    IF NEW.period_number IS NULL THEN
      IF NEW.check_in_time > v_school_start_time THEN
        NEW.is_late := true;
        NEW.late_duration := EXTRACT(EPOCH FROM (NEW.check_in_time - v_school_start_time))/60;
        IF NEW.status = 'present' THEN
          NEW.status := 'late';
        END IF;
      END IF;
    ELSE
      -- For period-wise, get period start time from timetable
      SELECT ts.start_time INTO v_period_start_time
      FROM timetable_slots ts
      WHERE ts.class_id = NEW.class_id
      AND ts.period_number = NEW.period_number
      AND ts.day_of_week = EXTRACT(DOW FROM NEW.attendance_date)
      LIMIT 1;
      
      IF v_period_start_time IS NOT NULL AND NEW.check_in_time > v_period_start_time THEN
        NEW.is_late := true;
        NEW.late_duration := EXTRACT(EPOCH FROM (NEW.check_in_time - v_period_start_time))/60;
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_late_status_trigger
  BEFORE INSERT OR UPDATE ON attendance_records
  FOR EACH ROW
  EXECUTE FUNCTION calculate_late_status();

-- Enable RLS
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY attendance_records_teacher_access ON attendance_records
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND (
      teacher_id = auth.uid()
      OR
      EXISTS (
        SELECT 1 FROM class_teachers ct
        WHERE ct.class_id = attendance_records.class_id
        AND ct.teacher_id = auth.uid()
        AND ct.status = 'active'
      )
    )
  );

CREATE POLICY attendance_templates_isolation ON attendance_templates
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND teacher_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/attendance.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface AttendanceRecord {
  id: string;
  tenantId: string;
  branchId: string;
  studentId: string;
  classId: string;
  sectionId?: string;
  subjectId?: string;
  teacherId: string;
  academicYearId: string;
  attendanceDate: string;
  periodNumber?: number;
  timeSlot?: string;
  status: 'present' | 'absent' | 'late' | 'excused' | 'on_leave' | 'medical_leave' | 'half_day';
  checkInTime?: string;
  checkOutTime?: string;
  isLate: boolean;
  lateDuration?: number;
  isEarlyDeparture: boolean;
  remarks?: string;
  leaveType?: string;
  leaveReason?: string;
  leaveDocumentUrl?: string;
  requiresApproval: boolean;
  approvalStatus?: 'pending' | 'approved' | 'rejected';
  approvedBy?: string;
  approvedAt?: string;
  markedAt: string;
  modifiedAt?: string;
  modifiedBy?: string;
  modificationReason?: string;
  deviceType?: string;
  ipAddress?: string;
  location?: { lat: number; lng: number; accuracy: number };
  createdAt: string;
  updatedAt: string;
}

export interface AttendanceMarkRequest {
  studentId: string;
  status: AttendanceRecord['status'];
  checkInTime?: string;
  remarks?: string;
  leaveType?: string;
  leaveReason?: string;
}

export interface BulkAttendanceRequest {
  classId: string;
  attendanceDate: string;
  periodNumber?: number;
  subjectId?: string;
  defaultStatus: AttendanceRecord['status'];
  studentOverrides?: Record<string, AttendanceRecord['status']>;
}

export interface AttendanceSummary {
  totalStudents: number;
  totalDays: number;
  avgAttendanceRate: number;
  presentCount: number;
  absentCount: number;
  lateCount: number;
  leaveCount: number;
  trend: Array<{ date: string; rate: number }>;
}

export interface StudentAttendance {
  studentId: string;
  studentName: string;
  rollNumber: string;
  photo?: string;
  status: AttendanceRecord['status'];
  checkInTime?: string;
  remarks?: string;
  isLate: boolean;
  lateDuration?: number;
  attendanceHistory: Array<{
    date: string;
    status: AttendanceRecord['status'];
  }>;
}

class AttendanceAPI {
  private supabase = createClient();

  /**
   * Get attendance for a class on a specific date
   */
  async getClassAttendance(
    classId: string,
    date: string,
    periodNumber?: number
  ): Promise<StudentAttendance[]> {
    // First, get all students in the class
    const { data: students, error: studentsError } = await this.supabase
      .from('students')
      .select(`
        id,
        first_name,
        last_name,
        roll_number,
        photo_url,
        student_class_assignments!inner(class_id, status)
      `)
      .eq('student_class_assignments.class_id', classId)
      .eq('student_class_assignments.status', 'active')
      .order('roll_number', { ascending: true });

    if (studentsError) throw studentsError;

    // Get attendance records for this date
    const query = this.supabase
      .from('attendance_records')
      .select('*')
      .eq('class_id', classId)
      .eq('attendance_date', date);

    if (periodNumber) {
      query.eq('period_number', periodNumber);
    }

    const { data: records, error: recordsError } = await query;
    if (recordsError) throw recordsError;

    // Create a map of attendance records
    const recordsMap = new Map(
      records?.map((r) => [r.student_id, r]) || []
    );

    // Combine student data with attendance records
    return students.map((student) => {
      const record = recordsMap.get(student.id);
      return {
        studentId: student.id,
        studentName: `${student.first_name} ${student.last_name}`,
        rollNumber: student.roll_number,
        photo: student.photo_url,
        status: record?.status || 'present',
        checkInTime: record?.check_in_time,
        remarks: record?.remarks,
        isLate: record?.is_late || false,
        lateDuration: record?.late_duration,
        attendanceHistory: [], // Load separately if needed
      };
    });
  }

  /**
   * Mark attendance for a single student
   */
  async markAttendance(
    classId: string,
    date: string,
    studentId: string,
    data: AttendanceMarkRequest,
    periodNumber?: number,
    subjectId?: string
  ): Promise<AttendanceRecord> {
    const { data: record, error } = await this.supabase
      .from('attendance_records')
      .upsert({
        class_id: classId,
        attendance_date: date,
        student_id: studentId,
        period_number: periodNumber,
        subject_id: subjectId,
        status: data.status,
        check_in_time: data.checkInTime,
        remarks: data.remarks,
        leave_type: data.leaveType,
        leave_reason: data.leaveReason,
        marked_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapRecord(record);
  }

  /**
   * Bulk mark attendance for entire class
   */
  async bulkMarkAttendance(data: BulkAttendanceRequest): Promise<{
    success: boolean;
    recordsCreated: number;
    recordsUpdated: number;
    message: string;
  }> {
    const { data: result, error } = await this.supabase.rpc(
      'bulk_mark_attendance',
      {
        p_class_id: data.classId,
        p_attendance_date: data.attendanceDate,
        p_period_number: data.periodNumber,
        p_subject_id: data.subjectId,
        p_default_status: data.defaultStatus,
        p_student_overrides: data.studentOverrides || {},
      }
    );

    if (error) throw error;
    return result[0];
  }

  /**
   * Quick mark all present
   */
  async markAllPresent(
    classId: string,
    date: string,
    periodNumber?: number,
    subjectId?: string
  ): Promise<any> {
    return this.bulkMarkAttendance({
      classId,
      attendanceDate: date,
      periodNumber,
      subjectId,
      defaultStatus: 'present',
    });
  }

  /**
   * Quick mark all absent
   */
  async markAllAbsent(
    classId: string,
    date: string,
    periodNumber?: number,
    subjectId?: string
  ): Promise<any> {
    return this.bulkMarkAttendance({
      classId,
      attendanceDate: date,
      periodNumber,
      subjectId,
      defaultStatus: 'absent',
    });
  }

  /**
   * Get attendance summary for a class
   */
  async getAttendanceSummary(
    classId: string,
    startDate: string,
    endDate: string
  ): Promise<AttendanceSummary> {
    const { data, error } = await this.supabase.rpc(
      'get_class_attendance_summary',
      {
        p_class_id: classId,
        p_start_date: startDate,
        p_end_date: endDate,
      }
    );

    if (error) throw error;
    return data[0];
  }

  /**
   * Get attendance history for a student
   */
  async getStudentAttendanceHistory(
    studentId: string,
    startDate: string,
    endDate: string
  ): Promise<AttendanceRecord[]> {
    const { data, error } = await this.supabase
      .from('attendance_records')
      .select('*')
      .eq('student_id', studentId)
      .gte('attendance_date', startDate)
      .lte('attendance_date', endDate)
      .order('attendance_date', { ascending: false });

    if (error) throw error;
    return data.map(this.mapRecord);
  }

  /**
   * Update attendance record
   */
  async updateAttendance(
    recordId: string,
    updates: Partial<AttendanceMarkRequest>,
    reason?: string
  ): Promise<AttendanceRecord> {
    const { data, error } = await this.supabase
      .from('attendance_records')
      .update({
        ...updates,
        modified_at: new Date().toISOString(),
        modification_reason: reason,
      })
      .eq('id', recordId)
      .select()
      .single();

    if (error) throw error;
    return this.mapRecord(data);
  }

  /**
   * Delete attendance record
   */
  async deleteAttendance(recordId: string): Promise<void> {
    const { error } = await this.supabase
      .from('attendance_records')
      .delete()
      .eq('id', recordId);

    if (error) throw error;
  }

  // Helper mapping functions
  private mapRecord(item: any): AttendanceRecord {
    return {
      id: item.id,
      tenantId: item.tenant_id,
      branchId: item.branch_id,
      studentId: item.student_id,
      classId: item.class_id,
      sectionId: item.section_id,
      subjectId: item.subject_id,
      teacherId: item.teacher_id,
      academicYearId: item.academic_year_id,
      attendanceDate: item.attendance_date,
      periodNumber: item.period_number,
      timeSlot: item.time_slot,
      status: item.status,
      checkInTime: item.check_in_time,
      checkOutTime: item.check_out_time,
      isLate: item.is_late,
      lateDuration: item.late_duration,
      isEarlyDeparture: item.is_early_departure,
      remarks: item.remarks,
      leaveType: item.leave_type,
      leaveReason: item.leave_reason,
      leaveDocumentUrl: item.leave_document_url,
      requiresApproval: item.requires_approval,
      approvalStatus: item.approval_status,
      approvedBy: item.approved_by,
      approvedAt: item.approved_at,
      markedAt: item.marked_at,
      modifiedAt: item.modified_at,
      modifiedBy: item.modified_by,
      modificationReason: item.modification_reason,
      deviceType: item.device_type,
      ipAddress: item.ip_address,
      location: item.location,
      createdAt: item.created_at,
      updatedAt: item.updated_at,
    };
  }
}

export const attendanceAPI = new AttendanceAPI();
```

---

### React Component (`/components/teacher/AttendanceMarking.tsx`)

```typescript
'use client';

import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Alert, AlertDescription } from '@/components/ui/alert';
import {
  CheckCircle2, XCircle, Clock, Search, Users, Calendar,
  ChevronDown, Save, AlertCircle, Download
} from 'lucide-react';
import { attendanceAPI, StudentAttendance } from '@/lib/api/attendance';

interface AttendanceMarkingProps {
  classId: string;
  className: string;
  date: string;
  periodNumber?: number;
  subjectId?: string;
  onComplete?: () => void;
}

export function AttendanceMarking({
  classId,
  className,
  date,
  periodNumber,
  subjectId,
  onComplete,
}: AttendanceMarkingProps) {
  const [students, setStudents] = useState<StudentAttendance[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStudent, setSelectedStudent] = useState<StudentAttendance | null>(null);

  useEffect(() => {
    loadAttendance();
  }, [classId, date, periodNumber]);

  const loadAttendance = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await attendanceAPI.getClassAttendance(classId, date, periodNumber);
      setStudents(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load attendance');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = (studentId: string, status: StudentAttendance['status']) => {
    setStudents(prev =>
      prev.map(s => (s.studentId === studentId ? { ...s, status } : s))
    );
  };

  const handleMarkAllPresent = async () => {
    try {
      setSaving(true);
      await attendanceAPI.markAllPresent(classId, date, periodNumber, subjectId);
      await loadAttendance();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to mark all present');
    } finally {
      setSaving(false);
    }
  };

  const handleSaveAttendance = async () => {
    try {
      setSaving(true);
      setError(null);

      // Prepare overrides (only students not marked as present)
      const overrides: Record<string, string> = {};
      students.forEach(s => {
        if (s.status !== 'present') {
          overrides[s.studentId] = s.status;
        }
      });

      await attendanceAPI.bulkMarkAttendance({
        classId,
        attendanceDate: date,
        periodNumber,
        subjectId,
        defaultStatus: 'present',
        studentOverrides: overrides,
      });

      onComplete?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save attendance');
    } finally {
      setSaving(false);
    }
  };

  const filteredStudents = students.filter(s =>
    s.studentName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.rollNumber.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const stats = {
    total: students.length,
    present: students.filter(s => s.status === 'present').length,
    absent: students.filter(s => s.status === 'absent').length,
    late: students.filter(s => s.status === 'late').length,
  };

  if (loading) {
    return <div className="flex items-center justify-center h-64">Loading attendance...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">Mark Attendance</h2>
          <p className="text-muted-foreground">
            {className} · {new Date(date).toLocaleDateString()} 
            {periodNumber && ` · Period ${periodNumber}`}
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleMarkAllPresent} disabled={saving}>
            <CheckCircle2 className="h-4 w-4 mr-2" />
            Mark All Present
          </Button>
          <Button onClick={handleSaveAttendance} disabled={saving}>
            <Save className="h-4 w-4 mr-2" />
            Save Attendance
          </Button>
        </div>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <StatCard label="Total" value={stats.total} icon={Users} />
        <StatCard label="Present" value={stats.present} icon={CheckCircle2} variant="success" />
        <StatCard label="Absent" value={stats.absent} icon={XCircle} variant="danger" />
        <StatCard label="Late" value={stats.late} icon={Clock} variant="warning" />
      </div>

      {/* Search */}
      <div className="flex items-center gap-2">
        <Search className="h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search by name or roll number..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="max-w-sm"
        />
      </div>

      {/* Student List */}
      <div className="space-y-2">
        {filteredStudents.map((student) => (
          <StudentAttendanceRow
            key={student.studentId}
            student={student}
            onStatusChange={handleStatusChange}
            onEdit={() => setSelectedStudent(student)}
          />
        ))}
      </div>

      {/* Edit Dialog */}
      {selectedStudent && (
        <EditAttendanceDialog
          student={selectedStudent}
          open={!!selectedStudent}
          onClose={() => setSelectedStudent(null)}
          onSave={() => {
            setSelectedStudent(null);
            loadAttendance();
          }}
        />
      )}
    </div>
  );
}

// Stat Card
interface StatCardProps {
  label: string;
  value: number;
  icon: React.ElementType;
  variant?: 'default' | 'success' | 'danger' | 'warning';
}

function StatCard({ label, value, icon: Icon, variant = 'default' }: StatCardProps) {
  const colors = {
    default: 'text-blue-600',
    success: 'text-green-600',
    danger: 'text-red-600',
    warning: 'text-orange-600',
  };

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-muted-foreground">{label}</p>
            <p className="text-2xl font-bold">{value}</p>
          </div>
          <Icon className={`h-8 w-8 ${colors[variant]}`} />
        </div>
      </CardContent>
    </Card>
  );
}

// Student Row
interface StudentAttendanceRowProps {
  student: StudentAttendance;
  onStatusChange: (studentId: string, status: StudentAttendance['status']) => void;
  onEdit: () => void;
}

function StudentAttendanceRow({ student, onStatusChange, onEdit }: StudentAttendanceRowProps) {
  const statusColors = {
    present: 'bg-green-100 text-green-800',
    absent: 'bg-red-100 text-red-800',
    late: 'bg-orange-100 text-orange-800',
    excused: 'bg-blue-100 text-blue-800',
    on_leave: 'bg-purple-100 text-purple-800',
    medical_leave: 'bg-pink-100 text-pink-800',
    half_day: 'bg-yellow-100 text-yellow-800',
  };

  return (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Avatar>
              <AvatarImage src={student.photo} />
              <AvatarFallback>{student.studentName[0]}</AvatarFallback>
            </Avatar>
            <div>
              <h4 className="font-semibold">{student.studentName}</h4>
              <p className="text-sm text-muted-foreground">Roll No: {student.rollNumber}</p>
            </div>
            {student.isLate && (
              <Badge variant="outline">
                <Clock className="h-3 w-3 mr-1" />
                {student.lateDuration}min late
              </Badge>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Select
              value={student.status}
              onValueChange={(value) => onStatusChange(student.studentId, value as StudentAttendance['status'])}
            >
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="present">Present</SelectItem>
                <SelectItem value="absent">Absent</SelectItem>
                <SelectItem value="late">Late</SelectItem>
                <SelectItem value="excused">Excused</SelectItem>
                <SelectItem value="on_leave">On Leave</SelectItem>
                <SelectItem value="medical_leave">Medical Leave</SelectItem>
                <SelectItem value="half_day">Half Day</SelectItem>
              </SelectContent>
            </Select>
            <Button variant="ghost" size="sm" onClick={onEdit}>
              <ChevronDown className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// Edit Dialog
interface EditAttendanceDialogProps {
  student: StudentAttendance;
  open: boolean;
  onClose: () => void;
  onSave: () => void;
}

function EditAttendanceDialog({ student, open, onClose, onSave }: EditAttendanceDialogProps) {
  const [remarks, setRemarks] = useState(student.remarks || '');
  const [leaveReason, setLeaveReason] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    try {
      setSaving(true);
      // Save logic here
      onSave();
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit Attendance - {student.studentName}</DialogTitle>
          <DialogDescription>Update attendance details and add remarks</DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium">Remarks</label>
            <Textarea
              value={remarks}
              onChange={(e) => setRemarks(e.target.value)}
              placeholder="Add any notes..."
            />
          </div>
          {student.status.includes('leave') && (
            <div>
              <label className="text-sm font-medium">Leave Reason</label>
              <Textarea
                value={leaveReason}
                onChange={(e) => setLeaveReason(e.target.value)}
                placeholder="Reason for leave..."
              />
            </div>
          )}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={saving}>
              Save Changes
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
```

---

## 🧪 TESTING

### Unit Tests

```typescript
import { describe, it, expect } from 'vitest';
import { attendanceAPI } from '@/lib/api/attendance';

describe('Attendance API', () => {
  it('should mark attendance for a student', async () => {
    const record = await attendanceAPI.markAttendance(
      'class-id',
      '2025-10-05',
      'student-id',
      { studentId: 'student-id', status: 'present' }
    );
    
    expect(record).toBeDefined();
    expect(record.status).toBe('present');
  });

  it('should bulk mark all present', async () => {
    const result = await attendanceAPI.markAllPresent('class-id', '2025-10-05');
    
    expect(result.success).toBe(true);
    expect(result.recordsCreated).toBeGreaterThan(0);
  });

  it('should get attendance summary', async () => {
    const summary = await attendanceAPI.getAttendanceSummary(
      'class-id',
      '2025-09-01',
      '2025-10-05'
    );
    
    expect(summary).toBeDefined();
    expect(summary.avgAttendanceRate).toBeGreaterThanOrEqual(0);
  });
});
```

---

## ✅ DEFINITION OF DONE

- [ ] Database schema created and migrated
- [ ] RLS policies implemented
- [ ] Bulk marking function working
- [ ] API client complete
- [ ] UI components built
- [ ] Quick mark features operational
- [ ] Mobile responsive
- [ ] Tests passing (85%+)
- [ ] Documentation complete

---

**Status**: ✅ READY FOR AUTONOMOUS AI AGENT DEVELOPMENT  
**Last Updated**: 2025-10-05
