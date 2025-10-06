# SPEC-191: Principal Dashboard & Analytics

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-191  
**Title**: Principal Dashboard & Analytics  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Principal Portal  
**Category**: Dashboard & Analytics  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-151, SPEC-186  

---

## 📋 DESCRIPTION

Comprehensive dashboard providing principals with real-time insights into school performance, including student enrollment, academic metrics, staff statistics, attendance trends, financial overview, and recent activities. Features drill-down analytics and customizable widgets.

---

## 🎯 SUCCESS CRITERIA

- [ ] Real-time metrics operational
- [ ] Interactive charts rendering
- [ ] Drill-down analytics working
- [ ] Widget customization functional
- [ ] Export functionality working
- [ ] Mobile responsive
- [ ] Performance optimized
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Principal Dashboard Widgets
CREATE TABLE IF NOT EXISTS principal_dashboard_widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  principal_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Widget configuration
  widget_type VARCHAR(100) NOT NULL, -- enrollment, attendance, academic, financial, staff, events
  widget_title VARCHAR(200),
  widget_position INTEGER NOT NULL DEFAULT 0,
  
  -- Display
  is_visible BOOLEAN DEFAULT true,
  size VARCHAR(20) DEFAULT 'medium', -- small, medium, large, full
  
  -- Configuration
  config_data JSONB DEFAULT '{}',
  
  -- Refresh
  refresh_interval INTEGER DEFAULT 300, -- seconds
  last_refreshed_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_size CHECK (size IN ('small', 'medium', 'large', 'full'))
);

CREATE INDEX ON principal_dashboard_widgets(tenant_id, branch_id, principal_id);
CREATE INDEX ON principal_dashboard_widgets(widget_type);

-- School Performance Metrics (Materialized View)
CREATE MATERIALIZED VIEW school_performance_metrics AS
SELECT
  s.tenant_id,
  s.branch_id,
  
  -- Enrollment metrics
  COUNT(DISTINCT s.id) as total_students,
  COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.id END) as active_students,
  COUNT(DISTINCT CASE WHEN s.gender = 'male' THEN s.id END) as male_students,
  COUNT(DISTINCT CASE WHEN s.gender = 'female' THEN s.id END) as female_students,
  
  -- Academic metrics
  AVG(CASE WHEN g.grade_percentage IS NOT NULL THEN g.grade_percentage END) as avg_grade_percentage,
  COUNT(DISTINCT CASE WHEN g.grade_percentage >= 90 THEN s.id END) as excellent_performers,
  COUNT(DISTINCT CASE WHEN g.grade_percentage < 50 THEN s.id END) as struggling_students,
  
  -- Attendance metrics
  AVG(CASE WHEN a.status = 'present' THEN 100 ELSE 0 END) as avg_attendance_rate,
  COUNT(DISTINCT CASE WHEN a.created_at >= CURRENT_DATE - INTERVAL '7 days' AND a.status = 'absent' THEN s.id END) as recent_absentees,
  
  -- Discipline metrics
  COUNT(DISTINCT dc.id) as total_discipline_cases,
  COUNT(DISTINCT CASE WHEN dc.severity = 'high' OR dc.severity = 'critical' THEN dc.id END) as serious_incidents,
  
  -- Last updated
  NOW() as last_calculated_at
  
FROM students s
LEFT JOIN grades g ON s.id = g.student_id
LEFT JOIN attendance_records a ON s.id = a.student_id AND a.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN discipline_cases dc ON s.id = dc.student_id AND dc.created_at >= CURRENT_DATE - INTERVAL '30 days'
WHERE s.status = 'active'
GROUP BY s.tenant_id, s.branch_id;

CREATE UNIQUE INDEX ON school_performance_metrics(tenant_id, branch_id);

-- Staff Overview Metrics (Materialized View)
CREATE MATERIALIZED VIEW staff_overview_metrics AS
SELECT
  e.tenant_id,
  e.branch_id,
  
  -- Staff counts
  COUNT(DISTINCT e.id) as total_staff,
  COUNT(DISTINCT CASE WHEN e.employment_type = 'full_time' THEN e.id END) as full_time_staff,
  COUNT(DISTINCT CASE WHEN e.employment_type = 'part_time' THEN e.id END) as part_time_staff,
  COUNT(DISTINCT CASE WHEN e.department = 'academic' THEN e.id END) as academic_staff,
  COUNT(DISTINCT CASE WHEN e.department = 'administrative' THEN e.id END) as administrative_staff,
  
  -- Performance metrics
  AVG(pr.overall_rating) as avg_staff_rating,
  COUNT(DISTINCT CASE WHEN pr.overall_rating >= 4.5 THEN e.id END) as outstanding_performers,
  
  -- Attendance
  AVG(CASE WHEN sa.status = 'present' THEN 100 ELSE 0 END) as staff_attendance_rate,
  
  -- Leave metrics
  COUNT(DISTINCT la.id) FILTER (WHERE la.status = 'pending') as pending_leave_requests,
  
  NOW() as last_calculated_at
  
FROM employees e
LEFT JOIN performance_reviews pr ON e.id = pr.employee_id AND pr.review_period_end >= CURRENT_DATE - INTERVAL '12 months'
LEFT JOIN staff_attendance sa ON e.id = sa.employee_id AND sa.attendance_date >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN leave_applications la ON e.id = la.employee_id
WHERE e.status = 'active'
GROUP BY e.tenant_id, e.branch_id;

CREATE UNIQUE INDEX ON staff_overview_metrics(tenant_id, branch_id);

-- Function to refresh dashboard metrics
CREATE OR REPLACE FUNCTION refresh_principal_dashboard_metrics()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY school_performance_metrics;
  REFRESH MATERIALIZED VIEW CONCURRENTLY staff_overview_metrics;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update widget refresh time
CREATE OR REPLACE FUNCTION update_widget_refresh_time()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_refreshed_at := NOW();
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_widget_refresh_trigger
  BEFORE UPDATE ON principal_dashboard_widgets
  FOR EACH ROW
  WHEN (OLD.config_data IS DISTINCT FROM NEW.config_data)
  EXECUTE FUNCTION update_widget_refresh_time();

-- Enable RLS
ALTER TABLE principal_dashboard_widgets ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY principal_dashboard_widgets_isolation ON principal_dashboard_widgets
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND principal_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/principal-dashboard.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface SchoolMetrics {
  totalStudents: number;
  activeStudents: number;
  maleStudents: number;
  femaleStudents: number;
  avgGradePercentage: number;
  excellentPerformers: number;
  strugglingStudents: number;
  avgAttendanceRate: number;
  recentAbsentees: number;
  totalDisciplineCases: number;
  seriousIncidents: number;
}

export interface StaffMetrics {
  totalStaff: number;
  fullTimeStaff: number;
  partTimeStaff: number;
  academicStaff: number;
  administrativeStaff: number;
  avgStaffRating: number;
  outstandingPerformers: number;
  staffAttendanceRate: number;
  pendingLeaveRequests: number;
}

export interface DashboardWidget {
  id: string;
  widgetType: string;
  widgetTitle?: string;
  widgetPosition: number;
  isVisible: boolean;
  size: 'small' | 'medium' | 'large' | 'full';
  configData: Record<string, any>;
  lastRefreshedAt?: string;
}

export class PrincipalDashboardAPI {
  private supabase = createClient();

  async getSchoolMetrics(params: {
    tenantId: string;
    branchId: string;
  }): Promise<SchoolMetrics> {
    const { data, error } = await this.supabase
      .from('school_performance_metrics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .single();

    if (error) throw error;

    return {
      totalStudents: data.total_students || 0,
      activeStudents: data.active_students || 0,
      maleStudents: data.male_students || 0,
      femaleStudents: data.female_students || 0,
      avgGradePercentage: data.avg_grade_percentage || 0,
      excellentPerformers: data.excellent_performers || 0,
      strugglingStudents: data.struggling_students || 0,
      avgAttendanceRate: data.avg_attendance_rate || 0,
      recentAbsentees: data.recent_absentees || 0,
      totalDisciplineCases: data.total_discipline_cases || 0,
      seriousIncidents: data.serious_incidents || 0,
    };
  }

  async getStaffMetrics(params: {
    tenantId: string;
    branchId: string;
  }): Promise<StaffMetrics> {
    const { data, error } = await this.supabase
      .from('staff_overview_metrics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .single();

    if (error) throw error;

    return {
      totalStaff: data.total_staff || 0,
      fullTimeStaff: data.full_time_staff || 0,
      partTimeStaff: data.part_time_staff || 0,
      academicStaff: data.academic_staff || 0,
      administrativeStaff: data.administrative_staff || 0,
      avgStaffRating: data.avg_staff_rating || 0,
      outstandingPerformers: data.outstanding_performers || 0,
      staffAttendanceRate: data.staff_attendance_rate || 0,
      pendingLeaveRequests: data.pending_leave_requests || 0,
    };
  }

  async getDashboardWidgets(): Promise<DashboardWidget[]> {
    const { data, error } = await this.supabase
      .from('principal_dashboard_widgets')
      .select('*')
      .eq('is_visible', true)
      .order('widget_position');

    if (error) throw error;

    return (data || []).map(widget => ({
      id: widget.id,
      widgetType: widget.widget_type,
      widgetTitle: widget.widget_title,
      widgetPosition: widget.widget_position,
      isVisible: widget.is_visible,
      size: widget.size,
      configData: widget.config_data || {},
      lastRefreshedAt: widget.last_refreshed_at,
    }));
  }

  async updateWidgetPosition(params: {
    widgetId: string;
    newPosition: number;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('principal_dashboard_widgets')
      .update({ widget_position: params.newPosition })
      .eq('id', params.widgetId);

    if (error) throw error;
  }

  async updateWidgetVisibility(params: {
    widgetId: string;
    isVisible: boolean;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('principal_dashboard_widgets')
      .update({ is_visible: params.isVisible })
      .eq('id', params.widgetId);

    if (error) throw error;
  }

  async refreshMetrics(): Promise<void> {
    const { error } = await this.supabase.rpc('refresh_principal_dashboard_metrics');
    if (error) throw error;
  }

  async getEnrollmentTrend(params: {
    tenantId: string;
    branchId: string;
    months?: number;
  }) {
    const monthsBack = params.months || 12;
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - monthsBack);

    const { data, error } = await this.supabase
      .from('students')
      .select('created_at, status')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .gte('created_at', startDate.toISOString());

    if (error) throw error;

    // Group by month
    const trend = data.reduce((acc: any[], student) => {
      const month = new Date(student.created_at).toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short' 
      });
      const existing = acc.find(item => item.month === month);
      if (existing) {
        existing.count += 1;
      } else {
        acc.push({ month, count: 1 });
      }
      return acc;
    }, []);

    return trend.sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());
  }

  async getRecentActivities(params: {
    tenantId: string;
    branchId: string;
    limit?: number;
  }) {
    const { data, error } = await this.supabase
      .from('activity_logs')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .order('created_at', { ascending: false })
      .limit(params.limit || 10);

    if (error) throw error;
    return data;
  }
}

export const principalDashboardAPI = new PrincipalDashboardAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { PrincipalDashboardAPI } from '../principal-dashboard';

describe('PrincipalDashboardAPI', () => {
  it('fetches school metrics', async () => {
    const api = new PrincipalDashboardAPI();
    const metrics = await api.getSchoolMetrics({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(metrics).toHaveProperty('totalStudents');
    expect(metrics).toHaveProperty('avgAttendanceRate');
  });

  it('fetches staff metrics', async () => {
    const api = new PrincipalDashboardAPI();
    const metrics = await api.getStaffMetrics({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(metrics).toHaveProperty('totalStaff');
    expect(metrics).toHaveProperty('avgStaffRating');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] School metrics displaying correctly
- [ ] Staff metrics accurate
- [ ] Enrollment trends rendering
- [ ] Recent activities showing
- [ ] Widget customization working
- [ ] Refresh functionality operational
- [ ] Export features working
- [ ] Performance optimized
- [ ] Tests passing

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
