# SPEC-192: Academic Performance Monitoring

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-192  
**Title**: Academic Performance Monitoring System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Principal Portal  
**Category**: Academic Management  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-191  

---

## 📋 DESCRIPTION

Comprehensive academic performance tracking system enabling principals to monitor student achievement across grades, subjects, teachers, and time periods. Features grade distribution analysis, subject performance comparisons, teacher effectiveness metrics, and early warning indicators for at-risk students.

---

## 🎯 SUCCESS CRITERIA

- [ ] Performance metrics calculating
- [ ] Grade distribution charts rendering
- [ ] Subject comparisons working
- [ ] Teacher effectiveness tracking
- [ ] At-risk student identification
- [ ] Trend analysis functional
- [ ] Export capabilities working
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Academic Performance Tracking
CREATE TABLE IF NOT EXISTS academic_performance_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Period
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(50) NOT NULL,
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Overall metrics
  total_students INTEGER NOT NULL,
  avg_gpa NUMERIC(3,2),
  avg_attendance_rate NUMERIC(5,2),
  
  -- Performance distribution
  excellent_count INTEGER DEFAULT 0, -- >= 90%
  good_count INTEGER DEFAULT 0, -- 75-89%
  average_count INTEGER DEFAULT 0, -- 60-74%
  below_average_count INTEGER DEFAULT 0, -- 50-59%
  failing_count INTEGER DEFAULT 0, -- < 50%
  
  -- Subject performance
  subject_performance_data JSONB, -- {subject_id: {avg_score, pass_rate, etc}}
  
  -- Teacher performance
  teacher_performance_data JSONB, -- {teacher_id: {avg_student_score, pass_rate, etc}}
  
  -- Grade level performance
  grade_performance_data JSONB, -- {grade_level: {avg_score, student_count, etc}}
  
  -- At-risk students
  at_risk_student_ids UUID[],
  at_risk_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, academic_year, term, snapshot_date)
);

CREATE INDEX ON academic_performance_snapshots(tenant_id, branch_id, academic_year);
CREATE INDEX ON academic_performance_snapshots(snapshot_date DESC);

-- Subject Performance Analytics (Materialized View)
CREATE MATERIALIZED VIEW subject_performance_analytics AS
SELECT
  g.tenant_id,
  g.branch_id,
  s.id as subject_id,
  s.subject_name,
  s.subject_code,
  c.grade_level,
  
  -- Performance metrics
  COUNT(DISTINCT g.student_id) as total_students,
  AVG(g.grade_percentage) as avg_score,
  STDDEV(g.grade_percentage) as score_std_dev,
  MIN(g.grade_percentage) as min_score,
  MAX(g.grade_percentage) as max_score,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY g.grade_percentage) as median_score,
  
  -- Distribution
  COUNT(CASE WHEN g.grade_percentage >= 90 THEN 1 END) as excellent_count,
  COUNT(CASE WHEN g.grade_percentage >= 75 AND g.grade_percentage < 90 THEN 1 END) as good_count,
  COUNT(CASE WHEN g.grade_percentage >= 60 AND g.grade_percentage < 75 THEN 1 END) as average_count,
  COUNT(CASE WHEN g.grade_percentage < 60 THEN 1 END) as below_average_count,
  
  -- Pass rate
  (COUNT(CASE WHEN g.grade_percentage >= 50 THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0) * 100) as pass_rate,
  
  -- Academic year
  g.academic_year,
  g.term,
  
  NOW() as last_calculated_at
  
FROM grades g
JOIN subjects s ON g.subject_id = s.id
JOIN classes c ON g.class_id = c.id
WHERE g.is_final_grade = true
GROUP BY g.tenant_id, g.branch_id, s.id, s.subject_name, s.subject_code, c.grade_level, g.academic_year, g.term;

CREATE INDEX ON subject_performance_analytics(tenant_id, branch_id, academic_year);
CREATE INDEX ON subject_performance_analytics(subject_id);

-- Teacher Effectiveness Metrics (Materialized View)
CREATE MATERIALIZED VIEW teacher_effectiveness_metrics AS
SELECT
  g.tenant_id,
  g.branch_id,
  t.id as teacher_id,
  t.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as teacher_name,
  s.subject_name,
  
  -- Student outcomes
  COUNT(DISTINCT g.student_id) as students_taught,
  AVG(g.grade_percentage) as avg_student_score,
  (COUNT(CASE WHEN g.grade_percentage >= 50 THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0) * 100) as pass_rate,
  COUNT(CASE WHEN g.grade_percentage >= 90 THEN 1 END) as excellent_performers,
  
  -- Improvement tracking
  AVG(g.grade_percentage - COALESCE(prev_g.grade_percentage, g.grade_percentage)) as avg_improvement,
  
  -- Academic year
  g.academic_year,
  g.term,
  
  NOW() as last_calculated_at
  
FROM grades g
JOIN teachers t ON g.teacher_id = t.id
JOIN employees e ON t.employee_id = e.id
JOIN subjects s ON g.subject_id = s.id
LEFT JOIN grades prev_g ON g.student_id = prev_g.student_id 
  AND g.subject_id = prev_g.subject_id 
  AND prev_g.term = (
    CASE 
      WHEN g.term = 'term_2' THEN 'term_1'
      WHEN g.term = 'term_3' THEN 'term_2'
      ELSE NULL
    END
  )
WHERE g.is_final_grade = true
GROUP BY g.tenant_id, g.branch_id, t.id, t.employee_id, e.first_name, e.last_name, s.subject_name, g.academic_year, g.term;

CREATE INDEX ON teacher_effectiveness_metrics(tenant_id, branch_id, teacher_id);

-- Function to identify at-risk students
CREATE OR REPLACE FUNCTION identify_at_risk_students(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_academic_year VARCHAR DEFAULT NULL,
  p_term VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  student_id UUID,
  student_name VARCHAR,
  avg_grade NUMERIC,
  failing_subjects INTEGER,
  attendance_rate NUMERIC,
  risk_level VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id as student_id,
    CONCAT(s.first_name, ' ', s.last_name) as student_name,
    AVG(g.grade_percentage) as avg_grade,
    COUNT(CASE WHEN g.grade_percentage < 50 THEN 1 END)::INTEGER as failing_subjects,
    (COUNT(CASE WHEN a.status = 'present' THEN 1 END)::FLOAT / NULLIF(COUNT(a.id), 0) * 100) as attendance_rate,
    CASE
      WHEN AVG(g.grade_percentage) < 40 OR COUNT(CASE WHEN g.grade_percentage < 50 THEN 1 END) >= 3 THEN 'critical'
      WHEN AVG(g.grade_percentage) < 50 OR COUNT(CASE WHEN g.grade_percentage < 50 THEN 1 END) >= 2 THEN 'high'
      WHEN AVG(g.grade_percentage) < 60 THEN 'medium'
      ELSE 'low'
    END as risk_level
  FROM students s
  JOIN grades g ON s.id = g.student_id
  LEFT JOIN attendance_records a ON s.id = a.student_id AND a.attendance_date >= CURRENT_DATE - INTERVAL '30 days'
  WHERE s.tenant_id = p_tenant_id
    AND s.branch_id = p_branch_id
    AND s.status = 'active'
    AND (p_academic_year IS NULL OR g.academic_year = p_academic_year)
    AND (p_term IS NULL OR g.term = p_term)
  GROUP BY s.id, s.first_name, s.last_name
  HAVING AVG(g.grade_percentage) < 60 OR COUNT(CASE WHEN g.grade_percentage < 50 THEN 1 END) >= 1
  ORDER BY avg_grade ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to generate academic performance snapshot
CREATE OR REPLACE FUNCTION generate_academic_performance_snapshot(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_academic_year VARCHAR,
  p_term VARCHAR
)
RETURNS UUID AS $$
DECLARE
  v_snapshot_id UUID;
  v_total_students INTEGER;
  v_avg_gpa NUMERIC;
  v_subject_data JSONB;
  v_teacher_data JSONB;
  v_grade_data JSONB;
  v_at_risk_ids UUID[];
BEGIN
  -- Calculate overall metrics
  SELECT 
    COUNT(DISTINCT g.student_id),
    AVG(g.grade_percentage)
  INTO v_total_students, v_avg_gpa
  FROM grades g
  WHERE g.tenant_id = p_tenant_id
    AND g.branch_id = p_branch_id
    AND g.academic_year = p_academic_year
    AND g.term = p_term;
  
  -- Get at-risk student IDs
  SELECT ARRAY_AGG(student_id)
  INTO v_at_risk_ids
  FROM identify_at_risk_students(p_tenant_id, p_branch_id, p_academic_year, p_term)
  WHERE risk_level IN ('high', 'critical');
  
  -- Insert snapshot
  INSERT INTO academic_performance_snapshots (
    tenant_id,
    branch_id,
    academic_year,
    term,
    total_students,
    avg_gpa,
    at_risk_student_ids,
    at_risk_count
  ) VALUES (
    p_tenant_id,
    p_branch_id,
    p_academic_year,
    p_term,
    v_total_students,
    v_avg_gpa,
    v_at_risk_ids,
    COALESCE(array_length(v_at_risk_ids, 1), 0)
  )
  ON CONFLICT (tenant_id, branch_id, academic_year, term, snapshot_date)
  DO UPDATE SET
    total_students = EXCLUDED.total_students,
    avg_gpa = EXCLUDED.avg_gpa,
    at_risk_student_ids = EXCLUDED.at_risk_student_ids,
    at_risk_count = EXCLUDED.at_risk_count
  RETURNING id INTO v_snapshot_id;
  
  RETURN v_snapshot_id;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE academic_performance_snapshots ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY academic_performance_snapshots_isolation ON academic_performance_snapshots
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/academic-performance.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface SubjectPerformance {
  subjectId: string;
  subjectName: string;
  subjectCode: string;
  gradeLevel: string;
  totalStudents: number;
  avgScore: number;
  passRate: number;
  excellentCount: number;
  goodCount: number;
  averageCount: number;
  belowAverageCount: number;
}

export interface TeacherEffectiveness {
  teacherId: string;
  teacherName: string;
  subjectName: string;
  studentsTaught: number;
  avgStudentScore: number;
  passRate: number;
  excellentPerformers: number;
  avgImprovement: number;
}

export interface AtRiskStudent {
  studentId: string;
  studentName: string;
  avgGrade: number;
  failingSubjects: number;
  attendanceRate: number;
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
}

export class AcademicPerformanceAPI {
  private supabase = createClient();

  async getSubjectPerformance(params: {
    tenantId: string;
    branchId: string;
    academicYear: string;
    term?: string;
  }): Promise<SubjectPerformance[]> {
    let query = this.supabase
      .from('subject_performance_analytics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('academic_year', params.academicYear);

    if (params.term) {
      query = query.eq('term', params.term);
    }

    const { data, error } = await query.order('avg_score', { ascending: false });

    if (error) throw error;

    return (data || []).map(item => ({
      subjectId: item.subject_id,
      subjectName: item.subject_name,
      subjectCode: item.subject_code,
      gradeLevel: item.grade_level,
      totalStudents: item.total_students,
      avgScore: item.avg_score,
      passRate: item.pass_rate,
      excellentCount: item.excellent_count,
      goodCount: item.good_count,
      averageCount: item.average_count,
      belowAverageCount: item.below_average_count,
    }));
  }

  async getTeacherEffectiveness(params: {
    tenantId: string;
    branchId: string;
    academicYear: string;
    term?: string;
  }): Promise<TeacherEffectiveness[]> {
    let query = this.supabase
      .from('teacher_effectiveness_metrics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('academic_year', params.academicYear);

    if (params.term) {
      query = query.eq('term', params.term);
    }

    const { data, error } = await query.order('avg_student_score', { ascending: false });

    if (error) throw error;

    return (data || []).map(item => ({
      teacherId: item.teacher_id,
      teacherName: item.teacher_name,
      subjectName: item.subject_name,
      studentsTaught: item.students_taught,
      avgStudentScore: item.avg_student_score,
      passRate: item.pass_rate,
      excellentPerformers: item.excellent_performers,
      avgImprovement: item.avg_improvement || 0,
    }));
  }

  async getAtRiskStudents(params: {
    tenantId: string;
    branchId: string;
    academicYear?: string;
    term?: string;
  }): Promise<AtRiskStudent[]> {
    const { data, error } = await this.supabase.rpc('identify_at_risk_students', {
      p_tenant_id: params.tenantId,
      p_branch_id: params.branchId,
      p_academic_year: params.academicYear,
      p_term: params.term,
    });

    if (error) throw error;

    return (data || []).map((item: any) => ({
      studentId: item.student_id,
      studentName: item.student_name,
      avgGrade: item.avg_grade,
      failingSubjects: item.failing_subjects,
      attendanceRate: item.attendance_rate || 0,
      riskLevel: item.risk_level,
    }));
  }

  async generatePerformanceSnapshot(params: {
    tenantId: string;
    branchId: string;
    academicYear: string;
    term: string;
  }): Promise<string> {
    const { data, error } = await this.supabase.rpc(
      'generate_academic_performance_snapshot',
      {
        p_tenant_id: params.tenantId,
        p_branch_id: params.branchId,
        p_academic_year: params.academicYear,
        p_term: params.term,
      }
    );

    if (error) throw error;
    return data;
  }

  async getPerformanceTrend(params: {
    tenantId: string;
    branchId: string;
    academicYear: string;
  }) {
    const { data, error } = await this.supabase
      .from('academic_performance_snapshots')
      .select('term, avg_gpa, total_students, at_risk_count')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('academic_year', params.academicYear)
      .order('snapshot_date');

    if (error) throw error;
    return data;
  }

  async getGradeDistribution(params: {
    tenantId: string;
    branchId: string;
    academicYear: string;
    term: string;
  }) {
    const { data, error } = await this.supabase
      .from('academic_performance_snapshots')
      .select('excellent_count, good_count, average_count, below_average_count, failing_count')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('academic_year', params.academicYear)
      .eq('term', params.term)
      .single();

    if (error) throw error;

    return {
      excellent: data?.excellent_count || 0,
      good: data?.good_count || 0,
      average: data?.average_count || 0,
      belowAverage: data?.below_average_count || 0,
      failing: data?.failing_count || 0,
    };
  }
}

export const academicPerformanceAPI = new AcademicPerformanceAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { AcademicPerformanceAPI } from '../academic-performance';

describe('AcademicPerformanceAPI', () => {
  it('fetches subject performance', async () => {
    const api = new AcademicPerformanceAPI();
    const performance = await api.getSubjectPerformance({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      academicYear: '2024-2025',
      term: 'term_1',
    });

    expect(Array.isArray(performance)).toBe(true);
  });

  it('identifies at-risk students', async () => {
    const api = new AcademicPerformanceAPI();
    const students = await api.getAtRiskStudents({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(students)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Subject performance analytics working
- [ ] Teacher effectiveness tracking
- [ ] At-risk student identification
- [ ] Grade distribution accurate
- [ ] Performance trends rendering
- [ ] Snapshot generation working
- [ ] Export functionality operational
- [ ] Tests passing

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
