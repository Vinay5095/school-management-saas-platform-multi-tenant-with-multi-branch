# SPEC-183: Training & Development

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-183  
**Title**: Training & Development Management  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Learning & Development  
**Priority**: MEDIUM  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-179, SPEC-182  

---

## 📋 DESCRIPTION

Complete Learning Management System with training program management, course catalog, enrollment tracking, trainer management, training calendars, feedback collection, certification tracking, and skill development paths.

---

## 🎯 SUCCESS CRITERIA

- [ ] Training catalog operational
- [ ] Enrollment management working
- [ ] Attendance tracking functional
- [ ] Certification tracking enabled
- [ ] Feedback collection working
- [ ] Training analytics available
- [ ] Learning paths created
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Training Programs
CREATE TABLE IF NOT EXISTS training_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Program details
  program_name VARCHAR(200) NOT NULL,
  program_code VARCHAR(50) UNIQUE NOT NULL,
  program_category VARCHAR(100), -- technical, soft_skills, compliance, leadership, orientation
  
  -- Description
  description TEXT,
  learning_objectives TEXT,
  
  -- Duration
  duration_hours NUMERIC(5,2) NOT NULL,
  
  -- Delivery
  delivery_mode VARCHAR(50) NOT NULL, -- classroom, online, hybrid, on_the_job
  
  -- Target audience
  target_roles VARCHAR(100)[],
  target_departments VARCHAR(100)[],
  min_experience_years INTEGER,
  
  -- Prerequisites
  prerequisites TEXT,
  
  -- Certification
  provides_certification BOOLEAN DEFAULT false,
  certification_name VARCHAR(200),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_mandatory BOOLEAN DEFAULT false,
  
  -- Trainer
  default_trainer_id UUID REFERENCES staff(id),
  
  -- Resources
  course_materials JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON training_programs(tenant_id);
CREATE INDEX ON training_programs(program_category);

-- Training Sessions
CREATE TABLE IF NOT EXISTS training_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id UUID NOT NULL REFERENCES training_programs(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Session details
  session_name VARCHAR(200) NOT NULL,
  session_code VARCHAR(50) UNIQUE NOT NULL,
  
  -- Schedule
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  session_times JSONB, -- Array of {day, start_time, end_time}
  
  -- Venue
  venue_type VARCHAR(50), -- physical, virtual, hybrid
  venue_location TEXT,
  meeting_link TEXT,
  
  -- Capacity
  max_participants INTEGER,
  min_participants INTEGER DEFAULT 5,
  
  -- Trainer
  trainer_id UUID NOT NULL REFERENCES staff(id),
  co_trainers UUID[],
  
  -- Status
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, ongoing, completed, cancelled
  
  -- Registration
  registration_deadline DATE,
  
  -- Cost
  cost_per_participant NUMERIC(10,2),
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled'))
);

CREATE INDEX ON training_sessions(program_id);
CREATE INDEX ON training_sessions(tenant_id, status);
CREATE INDEX ON training_sessions(start_date);

-- Training Enrollments
CREATE TABLE IF NOT EXISTS training_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES training_sessions(id),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Enrollment details
  enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  enrollment_type VARCHAR(50) DEFAULT 'self', -- self, manager_nominated, hr_assigned, mandatory
  
  -- Status
  status VARCHAR(50) DEFAULT 'enrolled', -- enrolled, waitlisted, confirmed, completed, cancelled, no_show
  
  -- Attendance
  attendance_percentage NUMERIC(5,2),
  sessions_attended INTEGER DEFAULT 0,
  total_sessions INTEGER,
  
  -- Assessment
  pre_assessment_score NUMERIC(5,2),
  post_assessment_score NUMERIC(5,2),
  
  -- Completion
  completed_at TIMESTAMP WITH TIME ZONE,
  certificate_issued BOOLEAN DEFAULT false,
  certificate_url TEXT,
  
  -- Feedback
  feedback_submitted BOOLEAN DEFAULT false,
  training_rating INTEGER,
  trainer_rating INTEGER,
  feedback_comments TEXT,
  
  -- Nominated by
  nominated_by UUID REFERENCES auth.users(id),
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('enrolled', 'waitlisted', 'confirmed', 'completed', 'cancelled', 'no_show')),
  UNIQUE(session_id, employee_id)
);

CREATE INDEX ON training_enrollments(session_id);
CREATE INDEX ON training_enrollments(employee_id);
CREATE INDEX ON training_enrollments(status);

-- Attendance Records
CREATE TABLE IF NOT EXISTS training_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id UUID NOT NULL REFERENCES training_enrollments(id),
  session_id UUID NOT NULL REFERENCES training_sessions(id),
  employee_id UUID NOT NULL REFERENCES staff(id),
  
  -- Attendance details
  attendance_date DATE NOT NULL,
  session_time_slot TIME,
  
  -- Status
  status VARCHAR(50) DEFAULT 'present', -- present, absent, late, excused
  
  -- Duration
  check_in_time TIME,
  check_out_time TIME,
  duration_minutes INTEGER,
  
  notes TEXT,
  marked_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('present', 'absent', 'late', 'excused'))
);

CREATE INDEX ON training_attendance(enrollment_id);
CREATE INDEX ON training_attendance(attendance_date);

-- Learning Paths
CREATE TABLE IF NOT EXISTS learning_paths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Path details
  path_name VARCHAR(200) NOT NULL,
  path_description TEXT,
  
  -- Target
  target_role VARCHAR(100),
  skill_level VARCHAR(50), -- beginner, intermediate, advanced, expert
  
  -- Duration
  estimated_duration_hours NUMERIC(6,2),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON learning_paths(tenant_id);

-- Learning Path Programs
CREATE TABLE IF NOT EXISTS learning_path_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learning_path_id UUID NOT NULL REFERENCES learning_paths(id) ON DELETE CASCADE,
  program_id UUID NOT NULL REFERENCES training_programs(id),
  
  -- Sequence
  sequence_order INTEGER NOT NULL,
  is_mandatory BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(learning_path_id, program_id)
);

CREATE INDEX ON learning_path_programs(learning_path_id);

-- Employee Learning Paths
CREATE TABLE IF NOT EXISTS employee_learning_paths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  learning_path_id UUID NOT NULL REFERENCES learning_paths(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Assignment
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  target_completion_date DATE,
  
  -- Progress
  status VARCHAR(50) DEFAULT 'in_progress', -- not_started, in_progress, completed
  completion_percentage INTEGER DEFAULT 0,
  
  -- Completion
  completed_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('not_started', 'in_progress', 'completed'))
);

CREATE INDEX ON employee_learning_paths(employee_id);

-- Training Budget
CREATE TABLE IF NOT EXISTS training_budget (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  department VARCHAR(100),
  branch_id UUID REFERENCES branches(id),
  
  -- Period
  fiscal_year INTEGER NOT NULL,
  
  -- Budget
  allocated_amount NUMERIC(15,2) NOT NULL,
  spent_amount NUMERIC(15,2) DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON training_budget(tenant_id, fiscal_year);

-- Function to update attendance percentage
CREATE OR REPLACE FUNCTION update_attendance_percentage()
RETURNS TRIGGER AS $$
DECLARE
  v_total_sessions INTEGER;
  v_attended_sessions INTEGER;
  v_percentage NUMERIC;
BEGIN
  -- Count total attendance records
  SELECT COUNT(*) INTO v_total_sessions
  FROM training_attendance
  WHERE enrollment_id = NEW.enrollment_id;
  
  -- Count present records
  SELECT COUNT(*) INTO v_attended_sessions
  FROM training_attendance
  WHERE enrollment_id = NEW.enrollment_id
  AND status = 'present';
  
  -- Calculate percentage
  v_percentage := CASE 
    WHEN v_total_sessions = 0 THEN 0
    ELSE ROUND((v_attended_sessions::NUMERIC / v_total_sessions) * 100, 2)
  END;
  
  -- Update enrollment
  UPDATE training_enrollments
  SET 
    attendance_percentage = v_percentage,
    sessions_attended = v_attended_sessions,
    total_sessions = v_total_sessions
  WHERE id = NEW.enrollment_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_attendance_percentage
  AFTER INSERT OR UPDATE ON training_attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_attendance_percentage();

-- Function to get training effectiveness
CREATE OR REPLACE FUNCTION get_training_effectiveness(
  p_tenant_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  program_name VARCHAR,
  total_participants BIGINT,
  completion_rate NUMERIC,
  avg_rating NUMERIC,
  avg_improvement NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    tp.program_name,
    COUNT(DISTINCT te.employee_id) as total_participants,
    ROUND(
      (COUNT(CASE WHEN te.status = 'completed' THEN 1 END)::NUMERIC / 
       COUNT(*)::NUMERIC) * 100,
      2
    ) as completion_rate,
    ROUND(AVG(te.training_rating), 2) as avg_rating,
    ROUND(AVG(te.post_assessment_score - te.pre_assessment_score), 2) as avg_improvement
  FROM training_programs tp
  JOIN training_sessions ts ON ts.program_id = tp.id
  JOIN training_enrollments te ON te.session_id = ts.id
  WHERE tp.tenant_id = p_tenant_id
  AND ts.start_date BETWEEN p_start_date AND p_end_date
  GROUP BY tp.id, tp.program_name
  ORDER BY completion_rate DESC;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE training_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_path_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_learning_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_budget ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/training.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface TrainingProgram {
  id: string;
  programName: string;
  programCode: string;
  programCategory: string;
  durationHours: number;
  deliveryMode: string;
  isActive: boolean;
}

export interface TrainingSession {
  id: string;
  sessionName: string;
  startDate: string;
  endDate: string;
  status: string;
  maxParticipants: number;
  enrolledCount?: number;
}

export class TrainingAPI {
  private supabase = createClient();

  async createTrainingProgram(params: {
    tenantId: string;
    programName: string;
    programCategory: string;
    description: string;
    durationHours: number;
    deliveryMode: string;
    targetRoles?: string[];
    isMandatory?: boolean;
  }): Promise<TrainingProgram> {
    const programCode = `TRG-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('training_programs')
      .insert({
        tenant_id: params.tenantId,
        program_name: params.programName,
        program_code: programCode,
        program_category: params.programCategory,
        description: params.description,
        duration_hours: params.durationHours,
        delivery_mode: params.deliveryMode,
        target_roles: params.targetRoles,
        is_mandatory: params.isMandatory || false,
        is_active: true,
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      programName: data.program_name,
      programCode: data.program_code,
      programCategory: data.program_category,
      durationHours: data.duration_hours,
      deliveryMode: data.delivery_mode,
      isActive: data.is_active,
    };
  }

  async scheduleTrainingSession(params: {
    programId: string;
    tenantId: string;
    sessionName: string;
    startDate: Date;
    endDate: Date;
    trainerId: string;
    maxParticipants: number;
    venueType: string;
    venueLocation?: string;
    meetingLink?: string;
  }): Promise<TrainingSession> {
    const sessionCode = `SES-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('training_sessions')
      .insert({
        program_id: params.programId,
        tenant_id: params.tenantId,
        session_name: params.sessionName,
        session_code: sessionCode,
        start_date: params.startDate.toISOString().split('T')[0],
        end_date: params.endDate.toISOString().split('T')[0],
        trainer_id: params.trainerId,
        max_participants: params.maxParticipants,
        venue_type: params.venueType,
        venue_location: params.venueLocation,
        meeting_link: params.meetingLink,
        status: 'scheduled',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      sessionName: data.session_name,
      startDate: data.start_date,
      endDate: data.end_date,
      status: data.status,
      maxParticipants: data.max_participants,
    };
  }

  async enrollInTraining(params: {
    sessionId: string;
    employeeId: string;
    tenantId: string;
    enrollmentType?: string;
  }) {
    const { data, error } = await this.supabase
      .from('training_enrollments')
      .insert({
        session_id: params.sessionId,
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        enrollment_type: params.enrollmentType || 'self',
        status: 'enrolled',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async markAttendance(params: {
    enrollmentId: string;
    sessionId: string;
    employeeId: string;
    attendanceDate: Date;
    status: string;
    checkInTime?: string;
    checkOutTime?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('training_attendance')
      .insert({
        enrollment_id: params.enrollmentId,
        session_id: params.sessionId,
        employee_id: params.employeeId,
        attendance_date: params.attendanceDate.toISOString().split('T')[0],
        status: params.status,
        check_in_time: params.checkInTime,
        check_out_time: params.checkOutTime,
        marked_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async submitTrainingFeedback(params: {
    enrollmentId: string;
    trainingRating: number;
    trainerRating: number;
    feedbackComments: string;
  }) {
    const { error } = await this.supabase
      .from('training_enrollments')
      .update({
        feedback_submitted: true,
        training_rating: params.trainingRating,
        trainer_rating: params.trainerRating,
        feedback_comments: params.feedbackComments,
      })
      .eq('id', params.enrollmentId);

    if (error) throw error;
  }

  async completeTraining(params: {
    enrollmentId: string;
    postAssessmentScore?: number;
    certificateUrl?: string;
  }) {
    const { error } = await this.supabase
      .from('training_enrollments')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        post_assessment_score: params.postAssessmentScore,
        certificate_issued: !!params.certificateUrl,
        certificate_url: params.certificateUrl,
      })
      .eq('id', params.enrollmentId);

    if (error) throw error;
  }

  async getUpcomingTrainingSessions(tenantId: string): Promise<TrainingSession[]> {
    const { data, error } = await this.supabase
      .from('training_sessions')
      .select(`
        *,
        enrollments:training_enrollments(count)
      `)
      .eq('tenant_id', tenantId)
      .gte('start_date', new Date().toISOString().split('T')[0])
      .eq('status', 'scheduled')
      .order('start_date');

    if (error) throw error;

    return (data || []).map(session => ({
      id: session.id,
      sessionName: session.session_name,
      startDate: session.start_date,
      endDate: session.end_date,
      status: session.status,
      maxParticipants: session.max_participants,
      enrolledCount: session.enrollments?.[0]?.count || 0,
    }));
  }

  async getEmployeeTrainingHistory(employeeId: string) {
    const { data, error } = await this.supabase
      .from('training_enrollments')
      .select(`
        *,
        session:training_sessions(
          session_name,
          start_date,
          end_date,
          program:training_programs(program_name, program_category)
        )
      `)
      .eq('employee_id', employeeId)
      .order('enrollment_date', { ascending: false });

    if (error) throw error;

    return data.map(enrollment => ({
      id: enrollment.id,
      programName: enrollment.session.program.program_name,
      programCategory: enrollment.session.program.program_category,
      sessionName: enrollment.session.session_name,
      startDate: enrollment.session.start_date,
      status: enrollment.status,
      attendancePercentage: enrollment.attendance_percentage,
      trainingRating: enrollment.training_rating,
      certificateIssued: enrollment.certificate_issued,
    }));
  }

  async getTrainingEffectiveness(params: {
    tenantId: string;
    startDate: Date;
    endDate: Date;
  }) {
    const { data, error } = await this.supabase.rpc(
      'get_training_effectiveness',
      {
        p_tenant_id: params.tenantId,
        p_start_date: params.startDate.toISOString().split('T')[0],
        p_end_date: params.endDate.toISOString().split('T')[0],
      }
    );

    if (error) throw error;

    return data.map((item: any) => ({
      programName: item.program_name,
      totalParticipants: item.total_participants,
      completionRate: item.completion_rate,
      avgRating: item.avg_rating,
      avgImprovement: item.avg_improvement,
    }));
  }

  async createLearningPath(params: {
    tenantId: string;
    pathName: string;
    pathDescription: string;
    targetRole: string;
    programIds: string[];
  }) {
    // Create learning path
    const { data: path, error: pathError } = await this.supabase
      .from('learning_paths')
      .insert({
        tenant_id: params.tenantId,
        path_name: params.pathName,
        path_description: params.pathDescription,
        target_role: params.targetRole,
        is_active: true,
      })
      .select()
      .single();

    if (pathError) throw pathError;

    // Add programs to path
    const pathPrograms = params.programIds.map((programId, index) => ({
      learning_path_id: path.id,
      program_id: programId,
      sequence_order: index + 1,
      is_mandatory: true,
    }));

    const { error: programsError } = await this.supabase
      .from('learning_path_programs')
      .insert(pathPrograms);

    if (programsError) throw programsError;

    return path;
  }
}

export const trainingAPI = new TrainingAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { TrainingAPI } from '../training';

describe('TrainingAPI', () => {
  it('creates training program', async () => {
    const api = new TrainingAPI();
    const program = await api.createTrainingProgram({
      tenantId: 'test-tenant',
      programName: 'Leadership Training',
      programCategory: 'leadership',
      description: 'Develop leadership skills',
      durationHours: 16,
      deliveryMode: 'classroom',
    });

    expect(program).toHaveProperty('id');
    expect(program.programName).toBe('Leadership Training');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Training catalog working
- [ ] Session scheduling operational
- [ ] Enrollment management functional
- [ ] Attendance tracking working
- [ ] Feedback collection enabled
- [ ] Learning paths created
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-184 (Leave Management)  
**Time**: 4 hours  
**AI-Ready**: 100%
