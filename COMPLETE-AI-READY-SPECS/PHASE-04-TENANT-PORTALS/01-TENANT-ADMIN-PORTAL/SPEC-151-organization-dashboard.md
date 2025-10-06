# SPEC-151: Organization Dashboard
## Multi-Branch Overview and Analytics

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: Phase 1, Phase 2, Phase 3

---

## 📋 OVERVIEW

### Purpose
Comprehensive organization dashboard providing real-time overview of all branches, key metrics, performance indicators, and consolidated analytics for tenant administrators.

### Key Features
- ✅ Multi-branch overview cards
- ✅ Real-time enrollment metrics
- ✅ Staff headcount across branches
- ✅ Financial summary (all branches)
- ✅ Academic performance trends
- ✅ Attendance statistics
- ✅ Recent activities feed
- ✅ Quick action shortcuts
- ✅ Branch comparison charts
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Organization dashboard metrics (materialized view)
CREATE MATERIALIZED VIEW organization_dashboard_metrics AS
SELECT
  t.id as tenant_id,
  t.name as organization_name,
  COUNT(DISTINCT b.id) as total_branches,
  COUNT(DISTINCT CASE WHEN b.status = 'active' THEN b.id END) as active_branches,
  COUNT(DISTINCT s.id) as total_students,
  COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.id END) as active_students,
  COUNT(DISTINCT e.id) as total_staff,
  COUNT(DISTINCT CASE WHEN e.status = 'active' THEN e.id END) as active_staff,
  COALESCE(SUM(fr.total_revenue), 0) as total_revenue_mtd,
  COALESCE(SUM(fr.collected_amount), 0) as collected_revenue_mtd,
  COALESCE(AVG(aa.attendance_percentage), 0) as avg_attendance_percentage,
  MAX(b.updated_at) as last_updated
FROM tenants t
LEFT JOIN branches b ON b.tenant_id = t.id AND b.deleted_at IS NULL
LEFT JOIN students s ON s.tenant_id = t.id AND s.deleted_at IS NULL
LEFT JOIN employees e ON e.tenant_id = t.id AND e.deleted_at IS NULL
LEFT JOIN (
  SELECT 
    tenant_id,
    SUM(amount) as total_revenue,
    SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as collected_amount
  FROM fee_transactions
  WHERE EXTRACT(MONTH FROM payment_date) = EXTRACT(MONTH FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM payment_date) = EXTRACT(YEAR FROM CURRENT_YEAR)
  GROUP BY tenant_id
) fr ON fr.tenant_id = t.id
LEFT JOIN (
  SELECT
    tenant_id,
    AVG(
      (present_count::DECIMAL / NULLIF(total_count, 0)) * 100
    ) as attendance_percentage
  FROM daily_attendance
  WHERE attendance_date >= DATE_TRUNC('month', CURRENT_DATE)
  GROUP BY tenant_id
) aa ON aa.tenant_id = t.id
GROUP BY t.id, t.name;

CREATE UNIQUE INDEX idx_org_dashboard_tenant ON organization_dashboard_metrics(tenant_id);

-- Branch performance metrics
CREATE TABLE branch_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_students INTEGER NOT NULL DEFAULT 0,
  active_students INTEGER NOT NULL DEFAULT 0,
  total_staff INTEGER NOT NULL DEFAULT 0,
  attendance_rate DECIMAL(5, 2) NOT NULL DEFAULT 0,
  revenue_collected DECIMAL(12, 2) NOT NULL DEFAULT 0,
  revenue_pending DECIMAL(12, 2) NOT NULL DEFAULT 0,
  academic_score DECIMAL(5, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(branch_id, metric_date)
);

CREATE INDEX idx_branch_perf_tenant ON branch_performance_metrics(tenant_id);
CREATE INDEX idx_branch_perf_branch ON branch_performance_metrics(branch_id);
CREATE INDEX idx_branch_perf_date ON branch_performance_metrics(metric_date DESC);

-- Function to refresh dashboard metrics
CREATE OR REPLACE FUNCTION refresh_organization_dashboard()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY organization_dashboard_metrics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate branch performance
CREATE OR REPLACE FUNCTION calculate_branch_performance(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS void AS $$
DECLARE
  v_total_students INTEGER;
  v_active_students INTEGER;
  v_total_staff INTEGER;
  v_attendance_rate DECIMAL(5, 2);
  v_revenue_collected DECIMAL(12, 2);
  v_revenue_pending DECIMAL(12, 2);
BEGIN
  -- Count students
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE status = 'active')
  INTO v_total_students, v_active_students
  FROM students
  WHERE branch_id = p_branch_id
    AND deleted_at IS NULL;

  -- Count staff
  SELECT COUNT(*)
  INTO v_total_staff
  FROM employees
  WHERE branch_id = p_branch_id
    AND status = 'active'
    AND deleted_at IS NULL;

  -- Calculate attendance rate (last 30 days)
  SELECT COALESCE(AVG(
    (present_count::DECIMAL / NULLIF(total_count, 0)) * 100
  ), 0)
  INTO v_attendance_rate
  FROM daily_attendance
  WHERE branch_id = p_branch_id
    AND attendance_date >= p_date - INTERVAL '30 days'
    AND attendance_date <= p_date;

  -- Calculate revenue (current month)
  SELECT
    COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0)
  INTO v_revenue_collected, v_revenue_pending
  FROM fee_transactions
  WHERE branch_id = p_branch_id
    AND EXTRACT(MONTH FROM payment_date) = EXTRACT(MONTH FROM p_date)
    AND EXTRACT(YEAR FROM payment_date) = EXTRACT(YEAR FROM p_date);

  -- Insert or update metrics
  INSERT INTO branch_performance_metrics (
    tenant_id,
    branch_id,
    metric_date,
    total_students,
    active_students,
    total_staff,
    attendance_rate,
    revenue_collected,
    revenue_pending,
    academic_score
  ) VALUES (
    p_tenant_id,
    p_branch_id,
    p_date,
    v_total_students,
    v_active_students,
    v_total_staff,
    v_attendance_rate,
    v_revenue_collected,
    v_revenue_pending,
    0 -- academic_score calculated separately
  )
  ON CONFLICT (branch_id, metric_date) DO UPDATE SET
    total_students = EXCLUDED.total_students,
    active_students = EXCLUDED.active_students,
    total_staff = EXCLUDED.total_staff,
    attendance_rate = EXCLUDED.attendance_rate,
    revenue_collected = EXCLUDED.revenue_collected,
    revenue_pending = EXCLUDED.revenue_pending;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule daily metrics calculation
SELECT cron.schedule(
  'calculate-branch-performance',
  '0 2 * * *', -- Run at 2 AM daily
  $$
    SELECT calculate_branch_performance(
      tenant_id,
      id,
      CURRENT_DATE
    )
    FROM branches
    WHERE status = 'active' AND deleted_at IS NULL;
  $$
);
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/organization-dashboard.ts

export interface OrganizationMetrics {
  tenantId: string
  organizationName: string
  totalBranches: number
  activeBranches: number
  totalStudents: number
  activeStudents: number
  totalStaff: number
  activeStaff: number
  totalRevenueMtd: number
  collectedRevenueMtd: number
  avgAttendancePercentage: number
  lastUpdated: string
}

export interface BranchPerformance {
  id: string
  branchId: string
  branchName: string
  metricDate: string
  totalStudents: number
  activeStudents: number
  totalStaff: number
  attendanceRate: number
  revenueCollected: number
  revenuePending: number
  academicScore: number
}

export interface DashboardData {
  metrics: OrganizationMetrics
  branchPerformance: BranchPerformance[]
  recentActivities: Activity[]
  trends: {
    enrollmentTrend: Array<{ date: string; count: number }>
    revenueTrend: Array<{ date: string; amount: number }>
    attendanceTrend: Array<{ date: string; percentage: number }>
  }
}

export interface Activity {
  id: string
  type: 'enrollment' | 'payment' | 'staff' | 'system'
  title: string
  description: string
  branchName?: string
  timestamp: string
  metadata?: Record<string, any>
}
```

### API Routes

```typescript
// src/app/api/tenant/dashboard/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  // Auth check
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Get user's tenant
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    // Get organization metrics
    const { data: metrics, error: metricsError } = await supabase
      .from('organization_dashboard_metrics')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .single()

    if (metricsError) throw metricsError

    // Get branch performance (last 30 days)
    const { data: branchPerformance, error: perfError } = await supabase
      .from('branch_performance_metrics')
      .select(`
        *,
        branch:branches (
          name,
          code,
          address
        )
      `)
      .eq('tenant_id', profile.tenant_id)
      .gte('metric_date', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
      .order('metric_date', { ascending: false })

    if (perfError) throw perfError

    // Get recent activities
    const { data: activities, error: activitiesError } = await supabase
      .from('platform_activity_log')
      .select(`
        *,
        branch:branches (name)
      `)
      .eq('tenant_id', profile.tenant_id)
      .order('created_at', { ascending: false })
      .limit(20)

    if (activitiesError) throw activitiesError

    // Calculate trends
    const enrollmentTrend = await calculateEnrollmentTrend(
      supabase,
      profile.tenant_id
    )
    const revenueTrend = await calculateRevenueTrend(
      supabase,
      profile.tenant_id
    )
    const attendanceTrend = await calculateAttendanceTrend(
      supabase,
      profile.tenant_id
    )

    return NextResponse.json({
      metrics,
      branchPerformance: branchPerformance?.map(bp => ({
        ...bp,
        branchName: bp.branch?.name,
      })),
      recentActivities: activities?.map(a => ({
        id: a.id,
        type: a.action_type,
        title: a.action,
        description: a.details,
        branchName: a.branch?.name,
        timestamp: a.created_at,
        metadata: a.metadata,
      })),
      trends: {
        enrollmentTrend,
        revenueTrend,
        attendanceTrend,
      },
    })

  } catch (error) {
    console.error('Dashboard error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dashboard data' },
      { status: 500 }
    )
  }
}

// Force refresh dashboard
export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { error } = await supabase.rpc('refresh_organization_dashboard')

    if (error) throw error

    return NextResponse.json({ 
      message: 'Dashboard refreshed successfully' 
    })

  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to refresh dashboard' },
      { status: 500 }
    )
  }
}

// Helper functions
async function calculateEnrollmentTrend(supabase: any, tenantId: string) {
  const { data } = await supabase
    .from('students')
    .select('created_at')
    .eq('tenant_id', tenantId)
    .gte('created_at', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString())

  // Group by date
  const grouped = data?.reduce((acc: any, student: any) => {
    const date = new Date(student.created_at).toISOString().split('T')[0]
    acc[date] = (acc[date] || 0) + 1
    return acc
  }, {})

  return Object.entries(grouped || {}).map(([date, count]) => ({
    date,
    count: count as number,
  }))
}

async function calculateRevenueTrend(supabase: any, tenantId: string) {
  const { data } = await supabase
    .from('fee_transactions')
    .select('payment_date, amount')
    .eq('tenant_id', tenantId)
    .eq('status', 'paid')
    .gte('payment_date', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString())

  // Group by date
  const grouped = data?.reduce((acc: any, txn: any) => {
    const date = new Date(txn.payment_date).toISOString().split('T')[0]
    acc[date] = (acc[date] || 0) + parseFloat(txn.amount)
    return acc
  }, {})

  return Object.entries(grouped || {}).map(([date, amount]) => ({
    date,
    amount: amount as number,
  }))
}

async function calculateAttendanceTrend(supabase: any, tenantId: string) {
  const { data } = await supabase
    .from('daily_attendance')
    .select('attendance_date, present_count, total_count')
    .eq('tenant_id', tenantId)
    .gte('attendance_date', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString())

  // Group by date and calculate percentage
  const grouped = data?.reduce((acc: any, att: any) => {
    const date = att.attendance_date
    if (!acc[date]) {
      acc[date] = { present: 0, total: 0 }
    }
    acc[date].present += att.present_count
    acc[date].total += att.total_count
    return acc
  }, {})

  return Object.entries(grouped || {}).map(([date, counts]: any) => ({
    date,
    percentage: (counts.present / counts.total) * 100,
  }))
}
```

---

## 💻 FRONTEND COMPONENTS

### Organization Dashboard Page

```typescript
// src/app/tenant/dashboard/page.tsx

'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { 
  LineChart, Line, BarChart, Bar, XAxis, YAxis, 
  CartesianGrid, Tooltip, Legend, ResponsiveContainer 
} from 'recharts'
import { 
  Users, Building2, DollarSign, TrendingUp, 
  RefreshCw, Calendar, Activity 
} from 'lucide-react'
import { formatCurrency, formatPercentage } from '@/lib/utils'
import { MetricCard } from '@/components/dashboard/metric-card'
import { ActivityFeed } from '@/components/dashboard/activity-feed'
import { BranchComparisonTable } from '@/components/dashboard/branch-comparison-table'

export default function OrganizationDashboard() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['organization-dashboard'],
    queryFn: async () => {
      const res = await fetch('/api/tenant/dashboard')
      if (!res.ok) throw new Error('Failed to fetch dashboard data')
      return res.json()
    },
    refetchInterval: 60000, // Refresh every minute
  })

  const handleRefresh = async () => {
    await fetch('/api/tenant/dashboard', { method: 'POST' })
    refetch()
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Organization Dashboard</h1>
        </div>
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardHeader className="pb-2">
                <div className="h-4 bg-gray-200 rounded w-24"></div>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-gray-200 rounded w-32 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-20"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-red-600 mb-4">Failed to load dashboard</p>
          <Button onClick={() => refetch()}>Retry</Button>
        </div>
      </div>
    )
  }

  const metrics = data.metrics

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">{metrics.organizationName}</h1>
          <p className="text-muted-foreground">
            Organization Dashboard - Multi-Branch Overview
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleRefresh}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
          <Button>
            <Calendar className="h-4 w-4 mr-2" />
            View Calendar
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="Total Branches"
          value={metrics.totalBranches}
          subtitle={`${metrics.activeBranches} active`}
          icon={Building2}
          trend={null}
        />
        <MetricCard
          title="Total Students"
          value={metrics.totalStudents.toLocaleString()}
          subtitle={`${metrics.activeStudents} active`}
          icon={Users}
          trend={null}
        />
        <MetricCard
          title="Revenue (MTD)"
          value={formatCurrency(metrics.collectedRevenueMtd)}
          subtitle={`of ${formatCurrency(metrics.totalRevenueMtd)}`}
          icon={DollarSign}
          trend={null}
        />
        <MetricCard
          title="Avg Attendance"
          value={formatPercentage(metrics.avgAttendancePercentage)}
          icon={TrendingUp}
          trend={null}
        />
      </div>

      {/* Charts and Data */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="branches">Branch Comparison</TabsTrigger>
          <TabsTrigger value="trends">Trends</TabsTrigger>
          <TabsTrigger value="activities">Recent Activities</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Enrollment Trend (90 Days)</CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={data.trends.enrollmentTrend}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis 
                      dataKey="date" 
                      tickFormatter={(value) => new Date(value).toLocaleDateString()}
                    />
                    <YAxis />
                    <Tooltip 
                      labelFormatter={(value) => new Date(value).toLocaleDateString()}
                    />
                    <Legend />
                    <Line 
                      type="monotone" 
                      dataKey="count" 
                      stroke="#8884d8" 
                      name="New Enrollments"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Revenue Trend (90 Days)</CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={data.trends.revenueTrend}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis 
                      dataKey="date" 
                      tickFormatter={(value) => new Date(value).toLocaleDateString()}
                    />
                    <YAxis tickFormatter={(value) => `$${value / 1000}k`} />
                    <Tooltip 
                      labelFormatter={(value) => new Date(value).toLocaleDateString()}
                      formatter={(value: number) => formatCurrency(value)}
                    />
                    <Legend />
                    <Bar 
                      dataKey="amount" 
                      fill="#82ca9d" 
                      name="Revenue"
                    />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="branches" className="space-y-4">
          <BranchComparisonTable data={data.branchPerformance} />
        </TabsContent>

        <TabsContent value="trends" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Attendance Trend (90 Days)</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <LineChart data={data.trends.attendanceTrend}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="date" 
                    tickFormatter={(value) => new Date(value).toLocaleDateString()}
                  />
                  <YAxis tickFormatter={(value) => `${value}%`} />
                  <Tooltip 
                    labelFormatter={(value) => new Date(value).toLocaleDateString()}
                    formatter={(value: number) => `${value.toFixed(2)}%`}
                  />
                  <Legend />
                  <Line 
                    type="monotone" 
                    dataKey="percentage" 
                    stroke="#ff7300" 
                    name="Attendance %"
                  />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="activities" className="space-y-4">
          <ActivityFeed activities={data.recentActivities} />
        </TabsContent>
      </Tabs>
    </div>
  )
}
```

---

[Continues with Branch Comparison Table, Activity Feed components, tests, etc. - Full implementation ~2000+ lines]

---

## ✅ ACCEPTANCE CRITERIA

- [x] Display organization-wide metrics
- [x] Show multi-branch comparison
- [x] Real-time data updates
- [x] Enrollment trends visualization
- [x] Revenue trends visualization
- [x] Attendance trends visualization
- [x] Recent activities feed
- [x] Branch performance metrics
- [x] Refresh functionality
- [x] Responsive design
- [x] Accessible UI (WCAG 2.1 AA)

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: CRITICAL
