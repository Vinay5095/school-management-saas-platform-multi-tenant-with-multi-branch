# SPEC-206: Student Activities Oversight

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-206  
**Title**: Student Activities Oversight System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Student Activities  
**Priority**: MEDIUM  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-201  

---

## 📋 DESCRIPTION

Comprehensive student activities management system enabling vice principals to track student participation in extracurricular activities, monitor achievements, manage activity schedules, assess student engagement levels, and generate activity reports.

---

## 🎯 SUCCESS CRITERIA

- [ ] Activity participation tracking operational
- [ ] Achievement recording functional
- [ ] Supervision scheduling working
- [ ] Engagement metrics calculating
- [ ] Activity reports generating
- [ ] Certificate management functional
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Student Activity Participation
CREATE TABLE IF NOT EXISTS student_activity_participation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  student_id UUID NOT NULL REFERENCES students(id),
  activity_id UUID NOT NULL REFERENCES school_activities(id),
  
  activity_type VARCHAR(100), -- sports, cultural, academic, community_service, club
  activity_name VARCHAR(200),
  
  -- Participation details
  role VARCHAR(100), -- participant, organizer, team_captain, president, member, volunteer
  participation_level VARCHAR(50), -- member, active_member, leader, captain, president
  
  join_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  
  -- Performance
  hours_contributed NUMERIC(6,2) DEFAULT 0,
  events_participated INTEGER DEFAULT 0,
  performance_rating INTEGER CHECK (performance_rating BETWEEN 1 AND 5),
  
  -- Achievements
  achievements JSONB DEFAULT '[]', -- [{achievement_name, date, level, description}]
  certificates_earned JSONB DEFAULT '[]', -- [{certificate_name, issue_date, certificate_url}]
  awards_won JSONB DEFAULT '[]', -- [{award_name, award_date, level, description}]
  
  -- Impact
  impact_description TEXT,
  skills_developed JSONB DEFAULT '[]', -- [skill1, skill2, skill3]
  
  -- Evaluation
  supervisor_feedback TEXT,
  peer_feedback TEXT,
  self_assessment TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON student_activity_participation(tenant_id, branch_id);
CREATE INDEX ON student_activity_participation(student_id, is_active);
CREATE INDEX ON student_activity_participation(activity_id, activity_type);

-- Activity Supervision Schedule
CREATE TABLE IF NOT EXISTS activity_supervision_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  activity_id UUID NOT NULL REFERENCES school_activities(id),
  activity_name VARCHAR(200),
  activity_type VARCHAR(100),
  
  supervisor_id UUID NOT NULL REFERENCES staff(id),
  supervisor_name VARCHAR(200),
  supervisor_role VARCHAR(100), -- primary, assistant, advisor
  
  schedule_day VARCHAR(20), -- monday, tuesday, etc.
  time_slot TIME,
  duration_minutes INTEGER DEFAULT 60,
  
  venue VARCHAR(200),
  
  supervision_notes TEXT,
  attendance_required BOOLEAN DEFAULT true,
  
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled, rescheduled
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON activity_supervision_schedule(tenant_id, branch_id);
CREATE INDEX ON activity_supervision_schedule(supervisor_id, schedule_day);
CREATE INDEX ON activity_supervision_schedule(activity_id);

-- VP Activity Reports (Materialized View)
CREATE MATERIALIZED VIEW vp_activity_reports AS
SELECT
  sap.tenant_id,
  sap.branch_id,
  sap.activity_type,
  sap.activity_name,
  
  COUNT(DISTINCT sap.student_id) as total_students,
  COUNT(DISTINCT CASE WHEN sap.is_active THEN sap.student_id END) as active_students,
  
  AVG(sap.performance_rating) as avg_performance_rating,
  SUM(sap.hours_contributed) as total_hours_contributed,
  SUM(sap.events_participated) as total_events,
  
  COUNT(DISTINCT CASE WHEN jsonb_array_length(sap.achievements) > 0 THEN sap.student_id END) as students_with_achievements,
  COUNT(DISTINCT CASE WHEN jsonb_array_length(sap.certificates_earned) > 0 THEN sap.student_id END) as students_with_certificates,
  
  NOW() as last_calculated_at
  
FROM student_activity_participation sap
GROUP BY sap.tenant_id, sap.branch_id, sap.activity_type, sap.activity_name;

CREATE INDEX ON vp_activity_reports(tenant_id, branch_id);

-- Student Engagement Summary (Materialized View)
CREATE MATERIALIZED VIEW student_engagement_summary AS
SELECT
  s.id as student_id,
  s.tenant_id,
  s.branch_id,
  CONCAT(s.first_name, ' ', s.last_name) as student_name,
  c.grade_level,
  
  COUNT(DISTINCT sap.activity_id) as activities_count,
  COUNT(DISTINCT sap.activity_type) as activity_types_count,
  
  SUM(sap.hours_contributed) as total_hours_contributed,
  SUM(sap.events_participated) as total_events_participated,
  
  AVG(sap.performance_rating) as avg_performance_rating,
  
  SUM(jsonb_array_length(sap.achievements)) as total_achievements,
  SUM(jsonb_array_length(sap.certificates_earned)) as total_certificates,
  SUM(jsonb_array_length(sap.awards_won)) as total_awards,
  
  CASE
    WHEN COUNT(DISTINCT sap.activity_id) >= 5 THEN 'highly_engaged'
    WHEN COUNT(DISTINCT sap.activity_id) >= 3 THEN 'moderately_engaged'
    WHEN COUNT(DISTINCT sap.activity_id) >= 1 THEN 'minimally_engaged'
    ELSE 'not_engaged'
  END as engagement_level,
  
  NOW() as last_calculated_at
  
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id AND e.status = 'active'
LEFT JOIN classes c ON e.class_id = c.id
LEFT JOIN student_activity_participation sap ON s.id = sap.student_id
WHERE s.status = 'active'
GROUP BY s.id, s.tenant_id, s.branch_id, s.first_name, s.last_name, c.grade_level;

CREATE INDEX ON student_engagement_summary(tenant_id, branch_id, engagement_level);

-- Auto-update triggers
CREATE OR REPLACE FUNCTION update_activity_participation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER activity_participation_update_trigger
  BEFORE UPDATE ON student_activity_participation
  FOR EACH ROW
  EXECUTE FUNCTION update_activity_participation_timestamp();

-- Enable RLS
ALTER TABLE student_activity_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_supervision_schedule ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY student_activity_participation_isolation ON student_activity_participation
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY activity_supervision_schedule_isolation ON activity_supervision_schedule
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/student-activities.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface ActivityParticipation {
  id: string;
  studentId: string;
  activityName: string;
  activityType: string;
  role: string;
  participationLevel: string;
  hoursContributed: number;
  performanceRating?: number;
  achievements: any[];
}

export interface StudentEngagement {
  studentId: string;
  studentName: string;
  gradeLevel: string;
  activitiesCount: number;
  totalHoursContributed: number;
  totalAchievements: number;
  engagementLevel: string;
}

export class StudentActivitiesAPI {
  private supabase = createClient();

  async recordParticipation(params: {
    tenantId: string;
    branchId: string;
    studentId: string;
    activityId: string;
    activityType: string;
    activityName: string;
    role: string;
    participationLevel: string;
  }) {
    const { data, error } = await this.supabase
      .from('student_activity_participation')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        student_id: params.studentId,
        activity_id: params.activityId,
        activity_type: params.activityType,
        activity_name: params.activityName,
        role: params.role,
        participation_level: params.participationLevel,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateAchievements(params: {
    participationId: string;
    achievements: any[];
  }) {
    const { error } = await this.supabase
      .from('student_activity_participation')
      .update({
        achievements: params.achievements,
      })
      .eq('id', params.participationId);

    if (error) throw error;
  }

  async getStudentActivities(studentId: string): Promise<ActivityParticipation[]> {
    const { data, error } = await this.supabase
      .from('student_activity_participation')
      .select('*')
      .eq('student_id', studentId)
      .eq('is_active', true)
      .order('join_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(p => ({
      id: p.id,
      studentId: p.student_id,
      activityName: p.activity_name,
      activityType: p.activity_type,
      role: p.role,
      participationLevel: p.participation_level,
      hoursContributed: p.hours_contributed,
      performanceRating: p.performance_rating,
      achievements: p.achievements || [],
    }));
  }

  async getActivityStats(params: {
    tenantId: string;
    branchId: string;
    activityType?: string;
  }) {
    let query = this.supabase
      .from('vp_activity_reports')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.activityType) {
      query = query.eq('activity_type', params.activityType);
    }

    const { data, error } = await query.order('total_students', { ascending: false });

    if (error) throw error;
    return data;
  }

  async getStudentEngagement(params: {
    tenantId: string;
    branchId: string;
    engagementLevel?: string;
  }): Promise<StudentEngagement[]> {
    let query = this.supabase
      .from('student_engagement_summary')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.engagementLevel) {
      query = query.eq('engagement_level', params.engagementLevel);
    }

    const { data, error } = await query.order('total_achievements', { ascending: false });

    if (error) throw error;

    return (data || []).map((eng: any) => ({
      studentId: eng.student_id,
      studentName: eng.student_name,
      gradeLevel: eng.grade_level,
      activitiesCount: eng.activities_count,
      totalHoursContributed: eng.total_hours_contributed,
      totalAchievements: eng.total_achievements,
      engagementLevel: eng.engagement_level,
    }));
  }

  async scheduleSupervision(params: {
    tenantId: string;
    branchId: string;
    activityId: string;
    activityName: string;
    supervisorId: string;
    supervisorName: string;
    scheduleDay: string;
    timeSlot: string;
  }) {
    const { data, error } = await this.supabase
      .from('activity_supervision_schedule')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        activity_id: params.activityId,
        activity_name: params.activityName,
        supervisor_id: params.supervisorId,
        supervisor_name: params.supervisorName,
        schedule_day: params.scheduleDay,
        time_slot: params.timeSlot,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getSupervisionSchedule(params: {
    tenantId: string;
    branchId: string;
    supervisorId?: string;
  }) {
    let query = this.supabase
      .from('activity_supervision_schedule')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.supervisorId) {
      query = query.eq('supervisor_id', params.supervisorId);
    }

    const { data, error } = await query.order('schedule_day');

    if (error) throw error;
    return data;
  }
}

export const studentActivitiesAPI = new StudentActivitiesAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { StudentActivitiesAPI } from '../student-activities';

describe('StudentActivitiesAPI', () => {
  let api: StudentActivitiesAPI;

  beforeEach(() => {
    api = new StudentActivitiesAPI();
  });

  it('records student participation', async () => {
    const participation = await api.recordParticipation({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      studentId: 'student-123',
      activityId: 'activity-456',
      activityType: 'sports',
      activityName: 'Basketball',
      role: 'team_captain',
      participationLevel: 'leader',
    });

    expect(participation).toHaveProperty('id');
  });

  it('tracks student engagement', async () => {
    const engagement = await api.getStudentEngagement({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      engagementLevel: 'highly_engaged',
    });

    expect(Array.isArray(engagement)).toBe(true);
  });

  it('gets activity statistics', async () => {
    const stats = await api.getActivityStats({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(stats)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Activity participation tracking working
- [ ] Achievement recording functional
- [ ] Engagement metrics calculating
- [ ] Supervision scheduling operational
- [ ] Activity reports generating
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
