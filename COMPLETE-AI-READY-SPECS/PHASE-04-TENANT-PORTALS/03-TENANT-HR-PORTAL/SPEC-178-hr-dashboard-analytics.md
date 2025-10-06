# SPEC-178: HR Dashboard & Analytics

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-178  
**Title**: HR Dashboard & Analytics System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: HR Analytics  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-012, SPEC-173  

---

## 📋 DESCRIPTION

Comprehensive HR analytics dashboard with real-time workforce metrics, headcount analysis, turnover rates, recruitment pipeline, performance distribution, training effectiveness, leave trends, and diversity metrics for data-driven HR decision making.

---

## 🎯 SUCCESS CRITERIA

- [ ] Real-time HR metrics displayed
- [ ] Headcount analytics working
- [ ] Turnover analysis functional
- [ ] Recruitment metrics tracked
- [ ] Performance distribution shown
- [ ] Training analytics available
- [ ] Leave trends visualized
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- HR Metrics Summary (Materialized View)
CREATE MATERIALIZED VIEW hr_metrics_summary AS
WITH current_employees AS (
  SELECT
    tenant_id,
    branch_id,
    COUNT(*) as total_employees,
    COUNT(*) FILTER (WHERE employment_type = 'permanent') as permanent_count,
    COUNT(*) FILTER (WHERE employment_type = 'contract') as contract_count,
    COUNT(*) FILTER (WHERE employment_type = 'part_time') as part_time_count,
    COUNT(*) FILTER (WHERE gender = 'male') as male_count,
    COUNT(*) FILTER (WHERE gender = 'female') as female_count,
    AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))) as avg_age,
    AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_joining))) as avg_tenure
  FROM staff
  WHERE status = 'active'
  GROUP BY tenant_id, branch_id
),
turnover_data AS (
  SELECT
    tenant_id,
    branch_id,
    COUNT(*) as exits_last_12_months
  FROM staff
  WHERE status = 'terminated'
  AND exit_date >= CURRENT_DATE - INTERVAL '12 months'
  GROUP BY tenant_id, branch_id
),
recruitment_data AS (
  SELECT
    tenant_id,
    COUNT(*) as open_positions,
    COUNT(*) FILTER (WHERE status = 'interviewing') as in_interview,
    AVG(EXTRACT(DAY FROM COALESCE(hired_date, CURRENT_DATE) - posted_date)) as avg_time_to_hire
  FROM job_openings
  WHERE status IN ('open', 'interviewing')
  GROUP BY tenant_id
)
SELECT
  ce.tenant_id,
  ce.branch_id,
  ce.total_employees,
  ce.permanent_count,
  ce.contract_count,
  ce.part_time_count,
  ce.male_count,
  ce.female_count,
  ce.avg_age,
  ce.avg_tenure,
  COALESCE(td.exits_last_12_months, 0) as exits_last_12_months,
  CASE 
    WHEN ce.total_employees > 0 THEN
      (COALESCE(td.exits_last_12_months, 0)::NUMERIC / ce.total_employees * 100)
    ELSE 0
  END as turnover_rate,
  COALESCE(rd.open_positions, 0) as open_positions,
  COALESCE(rd.avg_time_to_hire, 0) as avg_time_to_hire
FROM current_employees ce
LEFT JOIN turnover_data td ON td.tenant_id = ce.tenant_id AND td.branch_id = ce.branch_id
LEFT JOIN recruitment_data rd ON rd.tenant_id = ce.tenant_id;

CREATE INDEX ON hr_metrics_summary(tenant_id, branch_id);

-- Department-wise Headcount
CREATE OR REPLACE VIEW department_headcount AS
SELECT
  tenant_id,
  branch_id,
  department,
  COUNT(*) as employee_count,
  COUNT(*) FILTER (WHERE employment_type = 'permanent') as permanent_count,
  AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_joining))) as avg_tenure_years
FROM staff
WHERE status = 'active'
GROUP BY tenant_id, branch_id, department;

-- Performance Distribution
CREATE OR REPLACE VIEW performance_distribution AS
SELECT
  tenant_id,
  review_period,
  overall_rating,
  COUNT(*) as employee_count,
  (COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY tenant_id, review_period) * 100) as percentage
FROM performance_reviews
WHERE status = 'completed'
GROUP BY tenant_id, review_period, overall_rating;

-- Monthly Hiring Trend
CREATE OR REPLACE VIEW monthly_hiring_trend AS
SELECT
  tenant_id,
  DATE_TRUNC('month', date_of_joining) as month,
  COUNT(*) as hires_count,
  AVG(EXTRACT(DAY FROM date_of_joining - application_date)) as avg_days_to_hire
FROM staff s
LEFT JOIN job_applications ja ON ja.employee_id = s.id
WHERE s.date_of_joining >= CURRENT_DATE - INTERVAL '24 months'
GROUP BY tenant_id, DATE_TRUNC('month', date_of_joining)
ORDER BY month DESC;

-- Training Effectiveness
CREATE OR REPLACE VIEW training_effectiveness AS
SELECT
  t.tenant_id,
  t.training_name,
  COUNT(DISTINCT te.employee_id) as participants,
  AVG(te.completion_percentage) as avg_completion,
  COUNT(*) FILTER (WHERE te.status = 'completed') as completed_count,
  AVG(tf.rating) as avg_feedback_rating
FROM trainings t
LEFT JOIN training_enrollments te ON te.training_id = t.id
LEFT JOIN training_feedback tf ON tf.enrollment_id = te.id
WHERE t.start_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY t.tenant_id, t.id, t.training_name;

-- Leave Utilization
CREATE OR REPLACE VIEW leave_utilization AS
SELECT
  tenant_id,
  leave_type,
  COUNT(*) as leave_requests,
  SUM(days_count) as total_days,
  AVG(days_count) as avg_days_per_request,
  COUNT(*) FILTER (WHERE status = 'approved') as approved_count,
  COUNT(*) FILTER (WHERE status = 'rejected') as rejected_count
FROM leave_requests
WHERE request_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY tenant_id, leave_type;

-- Function to refresh HR metrics
CREATE OR REPLACE FUNCTION refresh_hr_metrics()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY hr_metrics_summary;
END;
$$ LANGUAGE plpgsql;

-- Function to get department growth
CREATE OR REPLACE FUNCTION get_department_growth(
  p_tenant_id UUID,
  p_months INTEGER DEFAULT 12
)
RETURNS TABLE (
  department VARCHAR,
  current_count BIGINT,
  previous_count BIGINT,
  growth_count BIGINT,
  growth_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH current_data AS (
    SELECT
      department,
      COUNT(*) as employee_count
    FROM staff
    WHERE tenant_id = p_tenant_id
    AND status = 'active'
    GROUP BY department
  ),
  previous_data AS (
    SELECT
      department,
      COUNT(*) as employee_count
    FROM staff
    WHERE tenant_id = p_tenant_id
    AND status = 'active'
    AND date_of_joining <= CURRENT_DATE - (p_months || ' months')::INTERVAL
    GROUP BY department
  )
  SELECT
    cd.department,
    cd.employee_count as current_count,
    COALESCE(pd.employee_count, 0) as previous_count,
    cd.employee_count - COALESCE(pd.employee_count, 0) as growth_count,
    CASE 
      WHEN COALESCE(pd.employee_count, 0) > 0 THEN
        ((cd.employee_count - COALESCE(pd.employee_count, 0))::NUMERIC / pd.employee_count * 100)
      ELSE 0
    END as growth_percentage
  FROM current_data cd
  LEFT JOIN previous_data pd ON pd.department = cd.department;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS (views inherit from base tables)
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/hr-dashboard.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface HRMetrics {
  totalEmployees: number;
  permanentCount: number;
  contractCount: number;
  partTimeCount: number;
  turnoverRate: number;
  avgAge: number;
  avgTenure: number;
  openPositions: number;
  avgTimeToHire: number;
}

export interface DepartmentMetrics {
  department: string;
  employeeCount: number;
  permanentCount: number;
  avgTenure: number;
}

export class HRDashboardAPI {
  private supabase = createClient();

  async getHRMetrics(params: {
    tenantId: string;
    branchId?: string;
  }): Promise<HRMetrics> {
    let query = this.supabase
      .from('hr_metrics_summary')
      .select('*')
      .eq('tenant_id', params.tenantId);

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query.single();

    if (error) throw error;

    return {
      totalEmployees: data.total_employees,
      permanentCount: data.permanent_count,
      contractCount: data.contract_count,
      partTimeCount: data.part_time_count,
      turnoverRate: data.turnover_rate,
      avgAge: data.avg_age,
      avgTenure: data.avg_tenure,
      openPositions: data.open_positions,
      avgTimeToHire: data.avg_time_to_hire,
    };
  }

  async getDepartmentHeadcount(params: {
    tenantId: string;
    branchId?: string;
  }): Promise<DepartmentMetrics[]> {
    let query = this.supabase
      .from('department_headcount')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .order('employee_count', { ascending: false });

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data || []).map(dept => ({
      department: dept.department,
      employeeCount: dept.employee_count,
      permanentCount: dept.permanent_count,
      avgTenure: dept.avg_tenure_years,
    }));
  }

  async getPerformanceDistribution(params: {
    tenantId: string;
    reviewPeriod: string;
  }) {
    const { data, error } = await this.supabase
      .from('performance_distribution')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('review_period', params.reviewPeriod)
      .order('overall_rating', { ascending: false });

    if (error) throw error;

    return data.map(item => ({
      rating: item.overall_rating,
      employeeCount: item.employee_count,
      percentage: item.percentage,
    }));
  }

  async getMonthlyHiringTrend(params: {
    tenantId: string;
    months?: number;
  }) {
    let query = this.supabase
      .from('monthly_hiring_trend')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .order('month', { ascending: true });

    if (params.months) {
      query = query.limit(params.months);
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map(item => ({
      month: item.month,
      hiresCount: item.hires_count,
      avgDaysToHire: item.avg_days_to_hire,
    }));
  }

  async getTrainingEffectiveness(tenantId: string) {
    const { data, error } = await this.supabase
      .from('training_effectiveness')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('participants', { ascending: false });

    if (error) throw error;

    return data.map(item => ({
      trainingName: item.training_name,
      participants: item.participants,
      avgCompletion: item.avg_completion,
      completedCount: item.completed_count,
      avgRating: item.avg_feedback_rating,
    }));
  }

  async getLeaveUtilization(tenantId: string) {
    const { data, error } = await this.supabase
      .from('leave_utilization')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('total_days', { ascending: false });

    if (error) throw error;

    return data.map(item => ({
      leaveType: item.leave_type,
      requestsCount: item.leave_requests,
      totalDays: item.total_days,
      avgDays: item.avg_days_per_request,
      approvedCount: item.approved_count,
      rejectedCount: item.rejected_count,
      approvalRate: (item.approved_count / item.leave_requests) * 100,
    }));
  }

  async getDepartmentGrowth(params: {
    tenantId: string;
    months?: number;
  }) {
    const { data, error } = await this.supabase.rpc('get_department_growth', {
      p_tenant_id: params.tenantId,
      p_months: params.months || 12,
    });

    if (error) throw error;

    return data.map((item: any) => ({
      department: item.department,
      currentCount: item.current_count,
      previousCount: item.previous_count,
      growthCount: item.growth_count,
      growthPercentage: item.growth_percentage,
    }));
  }

  async getDiversityMetrics(params: {
    tenantId: string;
    branchId?: string;
  }) {
    let query = this.supabase
      .from('staff')
      .select('gender, age_group:date_of_birth, employment_type')
      .eq('tenant_id', params.tenantId)
      .eq('status', 'active');

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query;

    if (error) throw error;

    const genderDistribution: Record<string, number> = {};
    const ageDistribution: Record<string, number> = {};

    data.forEach(emp => {
      // Gender distribution
      genderDistribution[emp.gender] = (genderDistribution[emp.gender] || 0) + 1;

      // Age distribution
      const age = new Date().getFullYear() - new Date(emp.age_group).getFullYear();
      const ageGroup = age < 25 ? '<25' : age < 35 ? '25-34' : age < 45 ? '35-44' : age < 55 ? '45-54' : '55+';
      ageDistribution[ageGroup] = (ageDistribution[ageGroup] || 0) + 1;
    });

    return {
      genderDistribution,
      ageDistribution,
      totalEmployees: data.length,
    };
  }

  async refreshMetrics(): Promise<void> {
    const { error } = await this.supabase.rpc('refresh_hr_metrics');
    if (error) throw error;
  }
}

export const hrDashboardAPI = new HRDashboardAPI();
```

### Component (`/components/hr/HRDashboard.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { hrDashboardAPI } from '@/lib/api/hr-dashboard';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { formatNumber } from '@/lib/utils';
import { Users, TrendingUp, Briefcase, Award } from 'lucide-react';
import { BarChart, Bar, PieChart, Pie, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

export function HRDashboard({ tenantId }: { tenantId: string }) {
  const [metrics, setMetrics] = useState<any>(null);
  const [departments, setDepartments] = useState<any[]>([]);
  const [hiringTrend, setHiringTrend] = useState<any[]>([]);
  const [leaveUtilization, setLeaveUtilization] = useState<any[]>([]);

  useEffect(() => {
    loadDashboardData();
  }, [tenantId]);

  const loadDashboardData = async () => {
    const [metricsData, deptData, hiringData, leaveData] = await Promise.all([
      hrDashboardAPI.getHRMetrics({ tenantId }),
      hrDashboardAPI.getDepartmentHeadcount({ tenantId }),
      hrDashboardAPI.getMonthlyHiringTrend({ tenantId, months: 12 }),
      hrDashboardAPI.getLeaveUtilization(tenantId),
    ]);

    setMetrics(metricsData);
    setDepartments(deptData);
    setHiringTrend(hiringData);
    setLeaveUtilization(leaveData);
  };

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-3xl font-bold">HR Dashboard & Analytics</h1>

      {/* Key Metrics */}
      {metrics && (
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Employees</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{formatNumber(metrics.totalEmployees)}</div>
              <p className="text-xs text-muted-foreground">
                {metrics.permanentCount} permanent, {metrics.contractCount} contract
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Turnover Rate</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics.turnoverRate.toFixed(1)}%</div>
              <p className="text-xs text-muted-foreground">Last 12 months</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Open Positions</CardTitle>
              <Briefcase className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics.openPositions}</div>
              <p className="text-xs text-muted-foreground">
                Avg {metrics.avgTimeToHire.toFixed(0)} days to hire
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Avg Tenure</CardTitle>
              <Award className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics.avgTenure.toFixed(1)} years</div>
              <p className="text-xs text-muted-foreground">
                Avg age: {metrics.avgAge.toFixed(0)} years
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Department Headcount */}
      {departments.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Department Headcount</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={departments}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="department" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="employeeCount" fill="#3b82f6" name="Employees" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Hiring Trend */}
      {hiringTrend.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Monthly Hiring Trend</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={hiringTrend}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="hiresCount" stroke="#10b981" name="Hires" />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Leave Utilization */}
      {leaveUtilization.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Leave Utilization by Type</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={leaveUtilization}
                  dataKey="totalDays"
                  nameKey="leaveType"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label
                >
                  {leaveUtilization.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { HRDashboardAPI } from '../hr-dashboard';

describe('HRDashboardAPI', () => {
  it('retrieves HR metrics correctly', async () => {
    const api = new HRDashboardAPI();
    const metrics = await api.getHRMetrics({ tenantId: 'test-tenant' });

    expect(metrics).toHaveProperty('totalEmployees');
    expect(metrics).toHaveProperty('turnoverRate');
  });

  it('calculates department headcount', async () => {
    const api = new HRDashboardAPI();
    const departments = await api.getDepartmentHeadcount({ tenantId: 'test-tenant' });

    expect(Array.isArray(departments)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] HR metrics accurate
- [ ] Department analytics working
- [ ] Hiring trends displayed
- [ ] Performance distribution shown
- [ ] Training analytics available
- [ ] Leave metrics accurate
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-179 (Employee Database)  
**Time**: 4 hours  
**AI-Ready**: 100%
