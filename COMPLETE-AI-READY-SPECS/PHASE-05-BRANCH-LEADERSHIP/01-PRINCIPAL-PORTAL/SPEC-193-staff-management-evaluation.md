# SPEC-193: Staff Management & Evaluation

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-193  
**Title**: Staff Management & Evaluation System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Principal Portal  
**Category**: Staff Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-191, SPEC-182  

---

## 📋 DESCRIPTION

Comprehensive staff oversight system for principals to monitor employee performance, conduct evaluations, track professional development, manage assignments, and review performance metrics across all staff members.

---

## 🎯 SUCCESS CRITERIA

- [ ] Staff directory functional
- [ ] Performance reviews accessible
- [ ] Evaluation workflows working
- [ ] Professional development tracking
- [ ] Assignment management operational
- [ ] Performance analytics displaying
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Principal Staff Oversight
CREATE TABLE IF NOT EXISTS principal_staff_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  employee_id UUID NOT NULL REFERENCES employees(id),
  principal_id UUID NOT NULL REFERENCES auth.users(id),
  
  note_type VARCHAR(50), -- observation, concern, commendation, meeting_note
  note_title VARCHAR(200),
  note_content TEXT NOT NULL,
  
  is_confidential BOOLEAN DEFAULT true,
  
  related_evaluation_id UUID,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON principal_staff_notes(tenant_id, branch_id, employee_id);

-- Staff Assignment Reviews
CREATE TABLE IF NOT EXISTS staff_assignment_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  review_period_start DATE NOT NULL,
  review_period_end DATE NOT NULL,
  
  assignments_reviewed INTEGER DEFAULT 0,
  changes_recommended INTEGER DEFAULT 0,
  
  review_summary TEXT,
  recommendations JSONB,
  
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Staff Performance Overview
CREATE MATERIALIZED VIEW staff_performance_overview AS
SELECT
  e.tenant_id,
  e.branch_id,
  e.id as employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.employee_code,
  e.department,
  e.designation,
  
  -- Performance
  AVG(pr.overall_rating) as avg_rating,
  COUNT(pr.id) as total_reviews,
  
  -- Attendance
  (COUNT(CASE WHEN sa.status = 'present' THEN 1 END)::FLOAT / NULLIF(COUNT(sa.id), 0) * 100) as attendance_rate,
  
  -- Training
  COUNT(DISTINCT te.id) as training_completed,
  
  -- Latest review
  MAX(pr.review_date) as last_review_date,
  
  NOW() as last_calculated_at
  
FROM employees e
LEFT JOIN performance_reviews pr ON e.id = pr.employee_id
LEFT JOIN staff_attendance sa ON e.id = sa.employee_id AND sa.attendance_date >= CURRENT_DATE - INTERVAL '90 days'
LEFT JOIN training_enrollments te ON e.id = te.employee_id AND te.completion_status = 'completed'
WHERE e.status = 'active'
GROUP BY e.tenant_id, e.branch_id, e.id, e.first_name, e.last_name, e.employee_code, e.department, e.designation;

CREATE INDEX ON staff_performance_overview(tenant_id, branch_id);

-- Enable RLS
ALTER TABLE principal_staff_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_assignment_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY principal_staff_notes_isolation ON principal_staff_notes
  FOR ALL USING (tenant_id = current_setting('app.current_tenant_id')::UUID);
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/staff-management.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface StaffPerformance {
  employeeId: string;
  employeeName: string;
  employeeCode: string;
  department: string;
  designation: string;
  avgRating: number;
  totalReviews: number;
  attendanceRate: number;
  trainingCompleted: number;
  lastReviewDate?: string;
}

export class StaffManagementAPI {
  private supabase = createClient();

  async getStaffPerformanceOverview(params: {
    tenantId: string;
    branchId: string;
    department?: string;
  }): Promise<StaffPerformance[]> {
    let query = this.supabase
      .from('staff_performance_overview')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.department) {
      query = query.eq('department', params.department);
    }

    const { data, error } = await query.order('avg_rating', { ascending: false });

    if (error) throw error;

    return (data || []).map(item => ({
      employeeId: item.employee_id,
      employeeName: item.employee_name,
      employeeCode: item.employee_code,
      department: item.department,
      designation: item.designation,
      avgRating: item.avg_rating || 0,
      totalReviews: item.total_reviews || 0,
      attendanceRate: item.attendance_rate || 0,
      trainingCompleted: item.training_completed || 0,
      lastReviewDate: item.last_review_date,
    }));
  }

  async addStaffNote(params: {
    tenantId: string;
    branchId: string;
    employeeId: string;
    noteType: string;
    noteTitle: string;
    noteContent: string;
    isConfidential?: boolean;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('principal_staff_notes')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        employee_id: params.employeeId,
        principal_id: user?.id,
        note_type: params.noteType,
        note_title: params.noteTitle,
        note_content: params.noteContent,
        is_confidential: params.isConfidential ?? true,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getStaffNotes(params: {
    employeeId: string;
  }) {
    const { data, error } = await this.supabase
      .from('principal_staff_notes')
      .select('*')
      .eq('employee_id', params.employeeId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  async getPerformanceReviews(params: {
    tenantId: string;
    branchId: string;
    employeeId?: string;
    status?: string;
  }) {
    let query = this.supabase
      .from('performance_reviews')
      .select('*, employee:employees(first_name, last_name)')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.employeeId) {
      query = query.eq('employee_id', params.employeeId);
    }

    if (params.status) {
      query = query.eq('status', params.status);
    }

    const { data, error } = await query.order('review_date', { ascending: false });

    if (error) throw error;
    return data;
  }
}

export const staffManagementAPI = new StaffManagementAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { StaffManagementAPI } from '../staff-management';

describe('StaffManagementAPI', () => {
  it('fetches staff performance overview', async () => {
    const api = new StaffManagementAPI();
    const staff = await api.getStaffPerformanceOverview({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(staff)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Staff performance overview working
- [ ] Notes system functional
- [ ] Performance reviews accessible
- [ ] Analytics displaying correctly
- [ ] Tests passing

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%
