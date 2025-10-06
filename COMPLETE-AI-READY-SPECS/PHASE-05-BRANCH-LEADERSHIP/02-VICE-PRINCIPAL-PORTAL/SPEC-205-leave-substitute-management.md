# SPEC-205: Leave & Substitute Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-205  
**Title**: Leave & Substitute Management System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Staff Operations  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-184  

---

## 📋 DESCRIPTION

Comprehensive substitute teacher management system enabling vice principals to track teacher absences, assign substitute teachers, manage period coverage, monitor substitute performance, and maintain coverage quality across all classes.

---

## 🎯 SUCCESS CRITERIA

- [ ] Substitute assignment workflow operational
- [ ] Period coverage tracking working
- [ ] Teacher matching functional
- [ ] Performance tracking active
- [ ] Coverage reports generating
- [ ] Real-time availability checking
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Substitute Assignments
CREATE TABLE IF NOT EXISTS substitute_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Absent teacher
  absent_teacher_id UUID NOT NULL REFERENCES staff(id),
  absence_reason VARCHAR(100), -- sick_leave, personal_leave, training, emergency
  leave_application_id UUID REFERENCES leave_applications(id),
  
  -- Substitute teacher
  substitute_teacher_id UUID REFERENCES staff(id),
  assignment_status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, declined, completed, cancelled
  
  -- Assignment details
  assignment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  start_time TIME,
  end_time TIME,
  
  -- Class coverage
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  grade_level VARCHAR(20),
  period_number INTEGER,
  
  -- Instructions
  lesson_plan_provided BOOLEAN DEFAULT false,
  lesson_plan_url TEXT,
  special_instructions TEXT,
  
  -- Completion
  completed BOOLEAN DEFAULT false,
  completion_notes TEXT,
  student_feedback TEXT,
  
  -- Performance
  performance_rating INTEGER CHECK (performance_rating BETWEEN 1 AND 5),
  punctuality_rating INTEGER CHECK (punctuality_rating BETWEEN 1 AND 5),
  effectiveness_rating INTEGER CHECK (effectiveness_rating BETWEEN 1 AND 5),
  
  -- Compensation
  compensation_type VARCHAR(50), -- regular_pay, overtime, extra_duty_allowance
  compensation_amount NUMERIC(10,2),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON substitute_assignments(tenant_id, branch_id, assignment_date);
CREATE INDEX ON substitute_assignments(absent_teacher_id, assignment_date);
CREATE INDEX ON substitute_assignments(substitute_teacher_id, assignment_status);
CREATE INDEX ON substitute_assignments(class_id, assignment_date);

-- Teacher Availability
CREATE TABLE IF NOT EXISTS substitute_teacher_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  teacher_id UUID NOT NULL REFERENCES staff(id),
  
  availability_date DATE NOT NULL,
  
  -- Time slots
  available_periods JSONB DEFAULT '[]', -- [{period_number, start_time, end_time, available}]
  
  -- Subjects
  preferred_subjects JSONB DEFAULT '[]', -- [{subject_id, subject_name, proficiency_level}]
  max_periods_per_day INTEGER DEFAULT 8,
  
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, teacher_id, availability_date)
);

CREATE INDEX ON substitute_teacher_availability(tenant_id, branch_id, availability_date);
CREATE INDEX ON substitute_teacher_availability(teacher_id, availability_date);

-- Substitute Performance Summary
CREATE MATERIALIZED VIEW substitute_performance_summary AS
SELECT
  sa.tenant_id,
  sa.branch_id,
  sa.substitute_teacher_id as teacher_id,
  s.full_name as teacher_name,
  
  COUNT(*) as total_assignments,
  COUNT(CASE WHEN sa.assignment_status = 'completed' THEN 1 END) as completed_assignments,
  COUNT(CASE WHEN sa.assignment_status = 'declined' THEN 1 END) as declined_assignments,
  
  AVG(sa.performance_rating) as avg_performance_rating,
  AVG(sa.punctuality_rating) as avg_punctuality_rating,
  AVG(sa.effectiveness_rating) as avg_effectiveness_rating,
  
  COUNT(DISTINCT sa.class_id) as unique_classes_covered,
  COUNT(DISTINCT sa.subject_id) as unique_subjects_covered,
  
  SUM(sa.compensation_amount) as total_compensation,
  
  NOW() as last_calculated_at
  
FROM substitute_assignments sa
JOIN staff s ON sa.substitute_teacher_id = s.id
WHERE sa.assignment_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY sa.tenant_id, sa.branch_id, sa.substitute_teacher_id, s.full_name;

CREATE INDEX ON substitute_performance_summary(tenant_id, branch_id);
CREATE INDEX ON substitute_performance_summary(teacher_id);

-- Coverage Gap Analysis View
CREATE MATERIALIZED VIEW coverage_gap_analysis AS
SELECT
  la.tenant_id,
  la.branch_id,
  la.staff_id as absent_teacher_id,
  s.full_name as teacher_name,
  la.from_date,
  la.to_date,
  la.status as leave_status,
  
  COUNT(DISTINCT tt.id) as total_periods_affected,
  COUNT(DISTINCT sa.id) as periods_with_substitute,
  (COUNT(DISTINCT tt.id) - COUNT(DISTINCT sa.id)) as uncovered_periods,
  
  CASE 
    WHEN COUNT(DISTINCT tt.id) = 0 THEN 100
    ELSE (COUNT(DISTINCT sa.id)::FLOAT / COUNT(DISTINCT tt.id) * 100)
  END as coverage_percentage,
  
  NOW() as last_calculated_at
  
FROM leave_applications la
JOIN staff s ON la.employee_id = s.id
LEFT JOIN timetable_entries tt ON s.id = tt.teacher_id 
  AND tt.day_of_week BETWEEN EXTRACT(DOW FROM la.from_date) AND EXTRACT(DOW FROM la.to_date)
LEFT JOIN substitute_assignments sa ON la.staff_id = sa.absent_teacher_id
  AND sa.assignment_date BETWEEN la.from_date AND la.to_date
  AND sa.assignment_status IN ('confirmed', 'completed')
WHERE la.status = 'approved'
  AND la.from_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY la.tenant_id, la.branch_id, la.staff_id, s.full_name, la.from_date, la.to_date, la.status;

CREATE INDEX ON coverage_gap_analysis(tenant_id, branch_id);

-- Function to find available substitutes
CREATE OR REPLACE FUNCTION find_available_substitutes(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_date DATE,
  p_period_number INTEGER,
  p_subject_id UUID DEFAULT NULL
)
RETURNS TABLE (
  teacher_id UUID,
  teacher_name VARCHAR,
  periods_available INTEGER,
  subject_match BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id as teacher_id,
    s.full_name as teacher_name,
    8 - COALESCE(assigned_count.count, 0) as periods_available,
    CASE 
      WHEN p_subject_id IS NULL THEN true
      WHEN sta.preferred_subjects::jsonb @> jsonb_build_array(jsonb_build_object('subject_id', p_subject_id::text)) THEN true
      ELSE false
    END as subject_match
  FROM staff s
  LEFT JOIN substitute_teacher_availability sta ON s.id = sta.teacher_id 
    AND sta.availability_date = p_date
  LEFT JOIN (
    SELECT substitute_teacher_id, COUNT(*) as count
    FROM substitute_assignments
    WHERE assignment_date = p_date
      AND assignment_status IN ('confirmed', 'completed')
    GROUP BY substitute_teacher_id
  ) assigned_count ON s.id = assigned_count.substitute_teacher_id
  WHERE s.tenant_id = p_tenant_id
    AND s.branch_id = p_branch_id
    AND s.status = 'active'
    AND s.staff_type = 'teaching'
    AND (8 - COALESCE(assigned_count.count, 0)) > 0
  ORDER BY subject_match DESC, periods_available DESC;
END;
$$ LANGUAGE plpgsql;

-- Auto-update triggers
CREATE OR REPLACE FUNCTION update_substitute_assignment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER substitute_assignment_update_trigger
  BEFORE UPDATE ON substitute_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_substitute_assignment_timestamp();

-- Enable RLS
ALTER TABLE substitute_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE substitute_teacher_availability ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY substitute_assignments_isolation ON substitute_assignments
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY substitute_availability_isolation ON substitute_teacher_availability
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/substitute-management.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface SubstituteAssignment {
  id: string;
  absentTeacherId: string;
  substituteTeacherId?: string;
  assignmentDate: string;
  assignmentStatus: string;
  className?: string;
  subjectName?: string;
  periodNumber?: number;
  performanceRating?: number;
}

export interface AvailableSubstitute {
  teacherId: string;
  teacherName: string;
  periodsAvailable: number;
  subjectMatch: boolean;
}

export class SubstituteManagementAPI {
  private supabase = createClient();

  async createAssignment(params: {
    tenantId: string;
    branchId: string;
    absentTeacherId: string;
    absenceReason: string;
    assignmentDate: string;
    classId?: string;
    subjectId?: string;
    periodNumber?: number;
    specialInstructions?: string;
  }) {
    const { data, error } = await this.supabase
      .from('substitute_assignments')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        absent_teacher_id: params.absentTeacherId,
        absence_reason: params.absenceReason,
        assignment_date: params.assignmentDate,
        class_id: params.classId,
        subject_id: params.subjectId,
        period_number: params.periodNumber,
        special_instructions: params.specialInstructions,
        assignment_status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async assignSubstitute(params: {
    assignmentId: string;
    substituteTeacherId: string;
  }) {
    const { error } = await this.supabase
      .from('substitute_assignments')
      .update({
        substitute_teacher_id: params.substituteTeacherId,
        assignment_status: 'confirmed',
      })
      .eq('id', params.assignmentId);

    if (error) throw error;
  }

  async getAssignments(params: {
    tenantId: string;
    branchId: string;
    date?: string;
    status?: string;
  }): Promise<SubstituteAssignment[]> {
    let query = this.supabase
      .from('substitute_assignments')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.date) {
      query = query.eq('assignment_date', params.date);
    }

    if (params.status) {
      query = query.eq('assignment_status', params.status);
    }

    const { data, error } = await query.order('assignment_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(a => ({
      id: a.id,
      absentTeacherId: a.absent_teacher_id,
      substituteTeacherId: a.substitute_teacher_id,
      assignmentDate: a.assignment_date,
      assignmentStatus: a.assignment_status,
      className: a.class_name,
      subjectName: a.subject_name,
      periodNumber: a.period_number,
      performanceRating: a.performance_rating,
    }));
  }

  async findAvailableSubstitutes(params: {
    tenantId: string;
    branchId: string;
    date: string;
    periodNumber: number;
    subjectId?: string;
  }): Promise<AvailableSubstitute[]> {
    const { data, error } = await this.supabase.rpc('find_available_substitutes', {
      p_tenant_id: params.tenantId,
      p_branch_id: params.branchId,
      p_date: params.date,
      p_period_number: params.periodNumber,
      p_subject_id: params.subjectId,
    });

    if (error) throw error;

    return (data || []).map((sub: any) => ({
      teacherId: sub.teacher_id,
      teacherName: sub.teacher_name,
      periodsAvailable: sub.periods_available,
      subjectMatch: sub.subject_match,
    }));
  }

  async completeAssignment(params: {
    assignmentId: string;
    completionNotes?: string;
    performanceRating?: number;
  }) {
    const { error } = await this.supabase
      .from('substitute_assignments')
      .update({
        completed: true,
        assignment_status: 'completed',
        completion_notes: params.completionNotes,
        performance_rating: params.performanceRating,
      })
      .eq('id', params.assignmentId);

    if (error) throw error;
  }

  async getSubstitutePerformance(params: {
    tenantId: string;
    branchId: string;
    teacherId?: string;
  }) {
    let query = this.supabase
      .from('substitute_performance_summary')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.teacherId) {
      query = query.eq('teacher_id', params.teacherId);
    }

    const { data, error } = await query.order('avg_performance_rating', { ascending: false });

    if (error) throw error;
    return data;
  }

  async getCoverageGaps(params: {
    tenantId: string;
    branchId: string;
  }) {
    const { data, error } = await this.supabase
      .from('coverage_gap_analysis')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .lt('coverage_percentage', 100)
      .order('coverage_percentage');

    if (error) throw error;
    return data;
  }
}

export const substituteManagementAPI = new SubstituteManagementAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { SubstituteManagementAPI } from '../substitute-management';

describe('SubstituteManagementAPI', () => {
  let api: SubstituteManagementAPI;

  beforeEach(() => {
    api = new SubstituteManagementAPI();
  });

  it('creates substitute assignment', async () => {
    const assignment = await api.createAssignment({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      absentTeacherId: 'teacher-123',
      absenceReason: 'sick_leave',
      assignmentDate: '2025-10-10',
      periodNumber: 3,
    });

    expect(assignment).toHaveProperty('id');
  });

  it('finds available substitutes', async () => {
    const substitutes = await api.findAvailableSubstitutes({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      date: '2025-10-10',
      periodNumber: 3,
    });

    expect(Array.isArray(substitutes)).toBe(true);
  });

  it('tracks substitute performance', async () => {
    const performance = await api.getSubstitutePerformance({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(performance)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Substitute assignment workflow operational
- [ ] Available teacher search working
- [ ] Assignment confirmation functional
- [ ] Performance tracking active
- [ ] Coverage analysis accurate
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
