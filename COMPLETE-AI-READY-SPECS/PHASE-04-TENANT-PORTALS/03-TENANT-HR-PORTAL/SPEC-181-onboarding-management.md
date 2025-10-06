# SPEC-181: Onboarding Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-181  
**Title**: Employee Onboarding Management System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Onboarding  
**Priority**: MEDIUM  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-179, SPEC-180  

---

## 📋 DESCRIPTION

Structured employee onboarding system with pre-joining activities, day-one setup, orientation schedules, document collection, training assignments, buddy program, and progress tracking to ensure smooth integration of new hires.

---

## 🎯 SUCCESS CRITERIA

- [ ] Onboarding workflows operational
- [ ] Task assignments working
- [ ] Document collection functional
- [ ] Training modules assigned
- [ ] Buddy system integrated
- [ ] Progress tracking visible
- [ ] Automated reminders sent
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Onboarding Templates
CREATE TABLE IF NOT EXISTS onboarding_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Template details
  template_name VARCHAR(200) NOT NULL,
  department VARCHAR(100),
  designation VARCHAR(100),
  
  -- Duration
  onboarding_duration_days INTEGER DEFAULT 30,
  
  -- Description
  description TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON onboarding_templates(tenant_id);

-- Onboarding Tasks (Template)
CREATE TABLE IF NOT EXISTS onboarding_task_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES onboarding_templates(id) ON DELETE CASCADE,
  
  -- Task details
  task_name VARCHAR(200) NOT NULL,
  task_description TEXT,
  task_category VARCHAR(50), -- documentation, system_setup, training, orientation, compliance
  
  -- Timeline
  due_day INTEGER NOT NULL, -- Days from joining date (can be negative for pre-joining)
  
  -- Assignment
  assigned_to_role VARCHAR(50), -- hr, it, manager, buddy, employee
  
  -- Requirements
  is_mandatory BOOLEAN DEFAULT true,
  requires_approval BOOLEAN DEFAULT false,
  
  -- Resources
  resources JSONB,
  
  display_order INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON onboarding_task_templates(template_id);

-- Employee Onboarding
CREATE TABLE IF NOT EXISTS employee_onboarding (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  template_id UUID REFERENCES onboarding_templates(id),
  
  -- Joining details
  joining_date DATE NOT NULL,
  onboarding_start_date DATE,
  onboarding_end_date DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'not_started', -- not_started, in_progress, completed, on_hold
  completion_percentage INTEGER DEFAULT 0,
  
  -- Team
  reporting_manager_id UUID REFERENCES staff(id),
  buddy_id UUID REFERENCES staff(id),
  hr_coordinator_id UUID REFERENCES auth.users(id),
  
  -- Feedback
  employee_feedback TEXT,
  employee_rating INTEGER,
  
  -- Completion
  completed_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('not_started', 'in_progress', 'completed', 'on_hold'))
);

CREATE INDEX ON employee_onboarding(employee_id);
CREATE INDEX ON employee_onboarding(tenant_id, status);

-- Onboarding Tasks (Instance)
CREATE TABLE IF NOT EXISTS onboarding_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  onboarding_id UUID NOT NULL REFERENCES employee_onboarding(id) ON DELETE CASCADE,
  template_task_id UUID REFERENCES onboarding_task_templates(id),
  
  -- Task details
  task_name VARCHAR(200) NOT NULL,
  task_description TEXT,
  task_category VARCHAR(50),
  
  -- Assignment
  assigned_to UUID REFERENCES auth.users(id),
  assigned_role VARCHAR(50),
  
  -- Timeline
  due_date DATE NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, skipped
  completed_at TIMESTAMP WITH TIME ZONE,
  completed_by UUID REFERENCES auth.users(id),
  
  -- Approval
  requires_approval BOOLEAN DEFAULT false,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Attachments
  attachments JSONB,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped'))
);

CREATE INDEX ON onboarding_tasks(onboarding_id);
CREATE INDEX ON onboarding_tasks(assigned_to, status);

-- Pre-Joining Documents
CREATE TABLE IF NOT EXISTS pre_joining_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  onboarding_id UUID REFERENCES employee_onboarding(id),
  
  -- Document details
  document_type VARCHAR(100) NOT NULL,
  document_name VARCHAR(200) NOT NULL,
  
  -- File
  file_url TEXT,
  
  -- Status
  is_mandatory BOOLEAN DEFAULT true,
  status VARCHAR(50) DEFAULT 'pending', -- pending, submitted, verified, rejected
  
  -- Verification
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Reminder
  reminder_sent_count INTEGER DEFAULT 0,
  last_reminder_sent TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'submitted', 'verified', 'rejected'))
);

CREATE INDEX ON pre_joining_documents(employee_id);
CREATE INDEX ON pre_joining_documents(onboarding_id, status);

-- Orientation Sessions
CREATE TABLE IF NOT EXISTS orientation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Session details
  session_name VARCHAR(200) NOT NULL,
  session_type VARCHAR(50), -- company_overview, policies, systems, department_intro
  
  -- Scheduling
  session_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  
  -- Venue
  location TEXT,
  meeting_link TEXT,
  
  -- Facilitator
  facilitator_id UUID REFERENCES auth.users(id),
  facilitator_name VARCHAR(200),
  
  -- Resources
  presentation_url TEXT,
  resources JSONB,
  
  -- Status
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON orientation_sessions(tenant_id, session_date);

-- Orientation Attendance
CREATE TABLE IF NOT EXISTS orientation_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES orientation_sessions(id),
  onboarding_id UUID NOT NULL REFERENCES employee_onboarding(id),
  employee_id UUID NOT NULL REFERENCES staff(id),
  
  -- Attendance
  attendance_status VARCHAR(50) DEFAULT 'registered', -- registered, attended, absent, excused
  
  -- Feedback
  session_rating INTEGER,
  feedback TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_attendance CHECK (attendance_status IN ('registered', 'attended', 'absent', 'excused'))
);

CREATE INDEX ON orientation_attendance(session_id);
CREATE INDEX ON orientation_attendance(onboarding_id);

-- Function to create onboarding from template
CREATE OR REPLACE FUNCTION create_onboarding_from_template(
  p_employee_id UUID,
  p_tenant_id UUID,
  p_template_id UUID,
  p_joining_date DATE
)
RETURNS UUID AS $$
DECLARE
  v_onboarding_id UUID;
  v_task RECORD;
BEGIN
  -- Create onboarding record
  INSERT INTO employee_onboarding (
    employee_id,
    tenant_id,
    template_id,
    joining_date,
    onboarding_start_date,
    onboarding_end_date,
    status
  )
  SELECT
    p_employee_id,
    p_tenant_id,
    p_template_id,
    p_joining_date,
    p_joining_date - INTERVAL '7 days',
    p_joining_date + (SELECT onboarding_duration_days FROM onboarding_templates WHERE id = p_template_id) * INTERVAL '1 day',
    'not_started'
  RETURNING id INTO v_onboarding_id;
  
  -- Create tasks from template
  FOR v_task IN 
    SELECT * FROM onboarding_task_templates 
    WHERE template_id = p_template_id
    ORDER BY due_day, display_order
  LOOP
    INSERT INTO onboarding_tasks (
      onboarding_id,
      template_task_id,
      task_name,
      task_description,
      task_category,
      assigned_role,
      due_date,
      requires_approval,
      status
    ) VALUES (
      v_onboarding_id,
      v_task.id,
      v_task.task_name,
      v_task.task_description,
      v_task.task_category,
      v_task.assigned_to_role,
      p_joining_date + (v_task.due_day || ' days')::INTERVAL,
      v_task.requires_approval,
      'pending'
    );
  END LOOP;
  
  RETURN v_onboarding_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate completion percentage
CREATE OR REPLACE FUNCTION update_onboarding_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_total_tasks INTEGER;
  v_completed_tasks INTEGER;
  v_percentage INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_tasks
  FROM onboarding_tasks
  WHERE onboarding_id = NEW.onboarding_id;
  
  SELECT COUNT(*) INTO v_completed_tasks
  FROM onboarding_tasks
  WHERE onboarding_id = NEW.onboarding_id
  AND status = 'completed';
  
  v_percentage := CASE 
    WHEN v_total_tasks = 0 THEN 0
    ELSE ROUND((v_completed_tasks::NUMERIC / v_total_tasks) * 100)
  END;
  
  UPDATE employee_onboarding
  SET 
    completion_percentage = v_percentage,
    status = CASE 
      WHEN v_percentage = 100 THEN 'completed'
      WHEN v_percentage > 0 THEN 'in_progress'
      ELSE 'not_started'
    END,
    completed_at = CASE 
      WHEN v_percentage = 100 THEN NOW()
      ELSE NULL
    END
  WHERE id = NEW.onboarding_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_completion_percentage
  AFTER INSERT OR UPDATE ON onboarding_tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_onboarding_completion();

-- Enable RLS
ALTER TABLE onboarding_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_onboarding ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pre_joining_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE orientation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE orientation_attendance ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/onboarding.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface OnboardingProgram {
  id: string;
  employeeId: string;
  joiningDate: string;
  status: string;
  completionPercentage: number;
  tasksCount?: number;
}

export class OnboardingAPI {
  private supabase = createClient();

  async createOnboarding(params: {
    employeeId: string;
    tenantId: string;
    templateId: string;
    joiningDate: Date;
    reportingManagerId?: string;
    buddyId?: string;
  }): Promise<string> {
    // Create onboarding from template
    const { data, error } = await this.supabase.rpc(
      'create_onboarding_from_template',
      {
        p_employee_id: params.employeeId,
        p_tenant_id: params.tenantId,
        p_template_id: params.templateId,
        p_joining_date: params.joiningDate.toISOString().split('T')[0],
      }
    );

    if (error) throw error;

    // Update team assignments
    await this.supabase
      .from('employee_onboarding')
      .update({
        reporting_manager_id: params.reportingManagerId,
        buddy_id: params.buddyId,
      })
      .eq('id', data);

    return data;
  }

  async getOnboardingStatus(onboardingId: string): Promise<OnboardingProgram> {
    const { data, error } = await this.supabase
      .from('employee_onboarding')
      .select(`
        *,
        tasks:onboarding_tasks(count)
      `)
      .eq('id', onboardingId)
      .single();

    if (error) throw error;

    return {
      id: data.id,
      employeeId: data.employee_id,
      joiningDate: data.joining_date,
      status: data.status,
      completionPercentage: data.completion_percentage,
      tasksCount: data.tasks?.[0]?.count || 0,
    };
  }

  async getOnboardingTasks(onboardingId: string) {
    const { data, error } = await this.supabase
      .from('onboarding_tasks')
      .select('*')
      .eq('onboarding_id', onboardingId)
      .order('due_date');

    if (error) throw error;

    return data.map(task => ({
      id: task.id,
      taskName: task.task_name,
      taskCategory: task.task_category,
      dueDate: task.due_date,
      status: task.status,
      assignedRole: task.assigned_role,
    }));
  }

  async updateTaskStatus(params: {
    taskId: string;
    status: string;
    notes?: string;
  }): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('onboarding_tasks')
      .update({
        status: params.status,
        completed_at: params.status === 'completed' ? new Date().toISOString() : null,
        completed_by: params.status === 'completed' ? user?.id : null,
        notes: params.notes,
      })
      .eq('id', params.taskId);

    if (error) throw error;
  }

  async submitPreJoiningDocument(params: {
    employeeId: string;
    onboardingId: string;
    documentType: string;
    file: File;
  }) {
    // Upload file
    const filePath = `pre-joining/${params.employeeId}/${Date.now()}_${params.file.name}`;
    const { error: uploadError } = await this.supabase.storage
      .from('hr-documents')
      .upload(filePath, params.file);

    if (uploadError) throw uploadError;

    const { data: urlData } = this.supabase.storage
      .from('hr-documents')
      .getPublicUrl(filePath);

    // Update document status
    const { error } = await this.supabase
      .from('pre_joining_documents')
      .update({
        file_url: urlData.publicUrl,
        status: 'submitted',
      })
      .eq('employee_id', params.employeeId)
      .eq('document_type', params.documentType);

    if (error) throw error;
  }

  async scheduleOrientationSession(params: {
    tenantId: string;
    sessionName: string;
    sessionType: string;
    sessionDate: Date;
    startTime: string;
    endTime: string;
    facilitatorId: string;
    meetingLink?: string;
  }) {
    const { data, error } = await this.supabase
      .from('orientation_sessions')
      .insert({
        tenant_id: params.tenantId,
        session_name: params.sessionName,
        session_type: params.sessionType,
        session_date: params.sessionDate.toISOString().split('T')[0],
        start_time: params.startTime,
        end_time: params.endTime,
        facilitator_id: params.facilitatorId,
        meeting_link: params.meetingLink,
        status: 'scheduled',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async registerForOrientation(params: {
    sessionId: string;
    onboardingId: string;
    employeeId: string;
  }) {
    const { error } = await this.supabase
      .from('orientation_attendance')
      .insert({
        session_id: params.sessionId,
        onboarding_id: params.onboardingId,
        employee_id: params.employeeId,
        attendance_status: 'registered',
      });

    if (error) throw error;
  }

  async markOrientationAttendance(params: {
    attendanceId: string;
    status: string;
    rating?: number;
    feedback?: string;
  }) {
    const { error } = await this.supabase
      .from('orientation_attendance')
      .update({
        attendance_status: params.status,
        session_rating: params.rating,
        feedback: params.feedback,
      })
      .eq('id', params.attendanceId);

    if (error) throw error;
  }

  async getActiveOnboardings(tenantId: string) {
    const { data, error } = await this.supabase
      .from('employee_onboarding')
      .select(`
        *,
        employee:staff(full_name, employee_code)
      `)
      .eq('tenant_id', tenantId)
      .in('status', ['not_started', 'in_progress'])
      .order('joining_date', { ascending: false });

    if (error) throw error;

    return data.map(onboarding => ({
      id: onboarding.id,
      employeeName: onboarding.employee.full_name,
      employeeCode: onboarding.employee.employee_code,
      joiningDate: onboarding.joining_date,
      status: onboarding.status,
      completionPercentage: onboarding.completion_percentage,
    }));
  }
}

export const onboardingAPI = new OnboardingAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { OnboardingAPI } from '../onboarding';

describe('OnboardingAPI', () => {
  it('creates onboarding program', async () => {
    const api = new OnboardingAPI();
    const id = await api.createOnboarding({
      employeeId: 'emp-123',
      tenantId: 'test-tenant',
      templateId: 'template-123',
      joiningDate: new Date('2025-01-15'),
    });

    expect(id).toBeTruthy();
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Onboarding workflows created
- [ ] Tasks assigned automatically
- [ ] Document collection working
- [ ] Orientation scheduling operational
- [ ] Progress tracking functional
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-182 (Performance Management)  
**Time**: 4 hours  
**AI-Ready**: 100%
