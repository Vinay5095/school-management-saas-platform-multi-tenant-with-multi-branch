# SPEC-159: Organization Analytics and Reporting
## Comprehensive Analytics Dashboard and Report Generation

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 7-8 hours  
> **Dependencies**: SPEC-151, SPEC-152, Phase 1, Phase 2, Phase 3

---

## 📋 OVERVIEW

### Purpose
Advanced analytics and reporting system providing deep insights into organizational performance, trends, and metrics across all branches with customizable reports and data export capabilities.

### Key Features
- ✅ Multi-dimensional analytics dashboard
- ✅ Customizable report builder
- ✅ Real-time and historical data analysis
- ✅ Branch comparison analytics
- ✅ Financial performance metrics
- ✅ Academic performance tracking
- ✅ Staff performance analytics
- ✅ Student enrollment trends
- ✅ Predictive analytics
- ✅ Export to PDF/Excel/CSV
- ✅ Scheduled report delivery
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Report templates table
CREATE TABLE report_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('financial', 'academic', 'operational', 'hr', 'student', 'custom')),
  report_type TEXT NOT NULL CHECK (report_type IN ('summary', 'detailed', 'comparison', 'trend', 'forecast')),
  data_sources TEXT[] NOT NULL,
  filters JSONB DEFAULT '{}'::jsonb,
  columns JSONB NOT NULL,
  charts JSONB DEFAULT '[]'::jsonb,
  grouping JSONB DEFAULT '{}'::jsonb,
  sorting JSONB DEFAULT '{}'::jsonb,
  is_public BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, name)
);

CREATE INDEX idx_report_templates_tenant ON report_templates(tenant_id);
CREATE INDEX idx_report_templates_category ON report_templates(category);
CREATE INDEX idx_report_templates_created_by ON report_templates(created_by);

-- Generated reports table
CREATE TABLE generated_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  template_id UUID REFERENCES report_templates(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  report_type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('generating', 'completed', 'failed')) DEFAULT 'generating',
  parameters JSONB DEFAULT '{}'::jsonb,
  file_path TEXT,
  file_format TEXT CHECK (file_format IN ('pdf', 'excel', 'csv', 'json')),
  file_size INTEGER,
  generated_by UUID REFERENCES auth.users(id),
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  download_count INTEGER DEFAULT 0,
  last_downloaded_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_generated_reports_tenant ON generated_reports(tenant_id);
CREATE INDEX idx_generated_reports_template ON generated_reports(template_id);
CREATE INDEX idx_generated_reports_status ON generated_reports(status);
CREATE INDEX idx_generated_reports_generated_at ON generated_reports(generated_at DESC);
CREATE INDEX idx_generated_reports_expires ON generated_reports(expires_at) WHERE expires_at IS NOT NULL;

-- Scheduled reports table
CREATE TABLE scheduled_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES report_templates(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  schedule_type TEXT NOT NULL CHECK (schedule_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'annual', 'custom')),
  cron_expression TEXT,
  parameters JSONB DEFAULT '{}'::jsonb,
  recipients UUID[] NOT NULL,
  email_subject TEXT,
  email_body TEXT,
  file_formats TEXT[] DEFAULT ARRAY['pdf']::TEXT[],
  is_active BOOLEAN DEFAULT true,
  last_run_at TIMESTAMPTZ,
  next_run_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scheduled_reports_tenant ON scheduled_reports(tenant_id);
CREATE INDEX idx_scheduled_reports_template ON scheduled_reports(template_id);
CREATE INDEX idx_scheduled_reports_next_run ON scheduled_reports(next_run_at) WHERE is_active = true;
CREATE INDEX idx_scheduled_reports_active ON scheduled_reports(is_active);

-- Analytics metrics cache table
CREATE TABLE analytics_metrics_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  metric_type TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  time_period TEXT NOT NULL CHECK (time_period IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
  metric_value JSONB NOT NULL,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, metric_type, metric_name, time_period, period_start, branch_id)
);

CREATE INDEX idx_analytics_cache_tenant ON analytics_metrics_cache(tenant_id);
CREATE INDEX idx_analytics_cache_type ON analytics_metrics_cache(metric_type);
CREATE INDEX idx_analytics_cache_period ON analytics_metrics_cache(period_start DESC, period_end DESC);
CREATE INDEX idx_analytics_cache_branch ON analytics_metrics_cache(branch_id);

-- Dashboard widgets table
CREATE TABLE dashboard_widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  widget_type TEXT NOT NULL,
  title TEXT NOT NULL,
  configuration JSONB NOT NULL,
  position JSONB DEFAULT '{"x": 0, "y": 0, "w": 4, "h": 3}'::jsonb,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dashboard_widgets_tenant ON dashboard_widgets(tenant_id);
CREATE INDEX idx_dashboard_widgets_user ON dashboard_widgets(user_id);
CREATE INDEX idx_dashboard_widgets_visible ON dashboard_widgets(is_visible);

-- Function to calculate enrollment trends
CREATE OR REPLACE FUNCTION calculate_enrollment_trends(
  p_tenant_id UUID,
  p_branch_id UUID DEFAULT NULL,
  p_days_back INTEGER DEFAULT 365
)
RETURNS TABLE (
  period DATE,
  new_enrollments INTEGER,
  total_enrolled INTEGER,
  dropouts INTEGER,
  net_change INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      CURRENT_DATE - p_days_back,
      CURRENT_DATE,
      '1 day'::INTERVAL
    )::DATE as period_date
  ),
  daily_enrollments AS (
    SELECT
      DATE(created_at) as enrollment_date,
      COUNT(*) as new_count
    FROM students
    WHERE tenant_id = p_tenant_id
      AND (p_branch_id IS NULL OR branch_id = p_branch_id)
      AND created_at >= CURRENT_DATE - p_days_back
    GROUP BY DATE(created_at)
  ),
  daily_dropouts AS (
    SELECT
      DATE(updated_at) as dropout_date,
      COUNT(*) as dropout_count
    FROM students
    WHERE tenant_id = p_tenant_id
      AND (p_branch_id IS NULL OR branch_id = p_branch_id)
      AND status = 'withdrawn'
      AND updated_at >= CURRENT_DATE - p_days_back
    GROUP BY DATE(updated_at)
  ),
  running_totals AS (
    SELECT
      ds.period_date,
      COALESCE(de.new_count, 0) as new_enrollments,
      COALESCE(dd.dropout_count, 0) as dropouts,
      SUM(COALESCE(de.new_count, 0) - COALESCE(dd.dropout_count, 0)) 
        OVER (ORDER BY ds.period_date) as running_total
    FROM date_series ds
    LEFT JOIN daily_enrollments de ON de.enrollment_date = ds.period_date
    LEFT JOIN daily_dropouts dd ON dd.dropout_date = ds.period_date
  )
  SELECT
    rt.period_date::DATE,
    rt.new_enrollments::INTEGER,
    rt.running_total::INTEGER,
    rt.dropouts::INTEGER,
    (rt.new_enrollments - rt.dropouts)::INTEGER
  FROM running_totals rt
  ORDER BY rt.period_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate revenue trends
CREATE OR REPLACE FUNCTION calculate_revenue_trends(
  p_tenant_id UUID,
  p_branch_id UUID DEFAULT NULL,
  p_months_back INTEGER DEFAULT 12
)
RETURNS TABLE (
  period TEXT,
  expected_revenue DECIMAL(12, 2),
  collected_revenue DECIMAL(12, 2),
  pending_revenue DECIMAL(12, 2),
  collection_rate DECIMAL(5, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    TO_CHAR(DATE_TRUNC('month', ft.payment_date), 'YYYY-MM') as period,
    SUM(ft.amount)::DECIMAL(12, 2) as expected_revenue,
    SUM(CASE WHEN ft.status = 'paid' THEN ft.amount ELSE 0 END)::DECIMAL(12, 2) as collected_revenue,
    SUM(CASE WHEN ft.status = 'pending' THEN ft.amount ELSE 0 END)::DECIMAL(12, 2) as pending_revenue,
    (SUM(CASE WHEN ft.status = 'paid' THEN ft.amount ELSE 0 END) / 
     NULLIF(SUM(ft.amount), 0) * 100)::DECIMAL(5, 2) as collection_rate
  FROM fee_transactions ft
  WHERE ft.tenant_id = p_tenant_id
    AND (p_branch_id IS NULL OR ft.branch_id = p_branch_id)
    AND ft.payment_date >= DATE_TRUNC('month', CURRENT_DATE) - (p_months_back || ' months')::INTERVAL
  GROUP BY DATE_TRUNC('month', ft.payment_date)
  ORDER BY period DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate staff performance metrics
CREATE OR REPLACE FUNCTION calculate_staff_metrics(
  p_tenant_id UUID,
  p_branch_id UUID DEFAULT NULL
)
RETURNS TABLE (
  branch_name TEXT,
  total_staff INTEGER,
  teaching_staff INTEGER,
  non_teaching_staff INTEGER,
  staff_student_ratio DECIMAL(5, 2),
  avg_experience_years DECIMAL(5, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.name,
    COUNT(e.id)::INTEGER,
    COUNT(CASE WHEN e.department = 'teaching' THEN 1 END)::INTEGER,
    COUNT(CASE WHEN e.department != 'teaching' THEN 1 END)::INTEGER,
    (COUNT(s.id)::DECIMAL / NULLIF(COUNT(CASE WHEN e.department = 'teaching' THEN 1 END), 0))::DECIMAL(5, 2),
    AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)))::DECIMAL(5, 2)
  FROM branches b
  LEFT JOIN employees e ON e.branch_id = b.id AND e.status = 'active' AND e.deleted_at IS NULL
  LEFT JOIN students s ON s.branch_id = b.id AND s.status = 'active' AND s.deleted_at IS NULL
  WHERE b.tenant_id = p_tenant_id
    AND (p_branch_id IS NULL OR b.id = p_branch_id)
    AND b.deleted_at IS NULL
  GROUP BY b.id, b.name
  ORDER BY b.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate academic performance metrics
CREATE OR REPLACE FUNCTION calculate_academic_metrics(
  p_tenant_id UUID,
  p_branch_id UUID DEFAULT NULL,
  p_academic_year TEXT DEFAULT NULL
)
RETURNS TABLE (
  branch_name TEXT,
  total_students INTEGER,
  avg_attendance DECIMAL(5, 2),
  avg_grade DECIMAL(5, 2),
  pass_rate DECIMAL(5, 2),
  dropout_rate DECIMAL(5, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.name,
    COUNT(DISTINCT s.id)::INTEGER,
    AVG(att.attendance_percentage)::DECIMAL(5, 2),
    AVG(gr.grade_value)::DECIMAL(5, 2),
    (COUNT(DISTINCT CASE WHEN gr.grade_value >= 50 THEN s.id END)::DECIMAL / 
     NULLIF(COUNT(DISTINCT s.id), 0) * 100)::DECIMAL(5, 2),
    (COUNT(DISTINCT CASE WHEN s.status = 'withdrawn' THEN s.id END)::DECIMAL / 
     NULLIF(COUNT(DISTINCT s.id), 0) * 100)::DECIMAL(5, 2)
  FROM branches b
  LEFT JOIN students s ON s.branch_id = b.id AND s.deleted_at IS NULL
  LEFT JOIN (
    SELECT
      student_id,
      AVG((present_count::DECIMAL / NULLIF(total_count, 0)) * 100) as attendance_percentage
    FROM daily_attendance
    WHERE deleted_at IS NULL
    GROUP BY student_id
  ) att ON att.student_id = s.id
  LEFT JOIN (
    SELECT
      student_id,
      AVG(marks) as grade_value
    FROM student_marks
    WHERE deleted_at IS NULL
    GROUP BY student_id
  ) gr ON gr.student_id = s.id
  WHERE b.tenant_id = p_tenant_id
    AND (p_branch_id IS NULL OR b.id = p_branch_id)
    AND b.deleted_at IS NULL
  GROUP BY b.id, b.name
  ORDER BY b.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cache analytics metrics
CREATE OR REPLACE FUNCTION cache_analytics_metrics()
RETURNS void AS $$
DECLARE
  v_tenant RECORD;
  v_branch RECORD;
  v_period_start DATE;
  v_period_end DATE;
BEGIN
  -- Cache monthly metrics for all tenants
  FOR v_tenant IN SELECT id FROM tenants WHERE deleted_at IS NULL LOOP
    -- Set date range for current month
    v_period_start := DATE_TRUNC('month', CURRENT_DATE);
    v_period_end := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day';

    -- Cache organization-level metrics
    INSERT INTO analytics_metrics_cache (
      tenant_id,
      metric_type,
      metric_name,
      time_period,
      period_start,
      period_end,
      metric_value
    ) VALUES (
      v_tenant.id,
      'enrollment',
      'total_students',
      'monthly',
      v_period_start,
      v_period_end,
      jsonb_build_object(
        'total', (SELECT COUNT(*) FROM students WHERE tenant_id = v_tenant.id AND deleted_at IS NULL),
        'active', (SELECT COUNT(*) FROM students WHERE tenant_id = v_tenant.id AND status = 'active' AND deleted_at IS NULL)
      )
    )
    ON CONFLICT (tenant_id, metric_type, metric_name, time_period, period_start, branch_id) 
    DO UPDATE SET
      metric_value = EXCLUDED.metric_value,
      calculated_at = NOW();

    -- Cache branch-level metrics
    FOR v_branch IN SELECT id FROM branches WHERE tenant_id = v_tenant.id AND deleted_at IS NULL LOOP
      INSERT INTO analytics_metrics_cache (
        tenant_id,
        metric_type,
        metric_name,
        time_period,
        period_start,
        period_end,
        branch_id,
        metric_value
      ) VALUES (
        v_tenant.id,
        'enrollment',
        'total_students',
        'monthly',
        v_period_start,
        v_period_end,
        v_branch.id,
        jsonb_build_object(
          'total', (SELECT COUNT(*) FROM students WHERE branch_id = v_branch.id AND deleted_at IS NULL),
          'active', (SELECT COUNT(*) FROM students WHERE branch_id = v_branch.id AND status = 'active' AND deleted_at IS NULL)
        )
      )
      ON CONFLICT (tenant_id, metric_type, metric_name, time_period, period_start, branch_id) 
      DO UPDATE SET
        metric_value = EXCLUDED.metric_value,
        calculated_at = NOW();
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule daily analytics caching
SELECT cron.schedule(
  'cache-analytics-metrics',
  '0 3 * * *', -- Run at 3 AM daily
  'SELECT cache_analytics_metrics()'
);

-- RLS Policies
ALTER TABLE report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_metrics_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_widgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_admin_report_templates ON report_templates
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_generated_reports ON generated_reports
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_admin_scheduled_reports ON scheduled_reports
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_analytics_cache ON analytics_metrics_cache
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY user_dashboard_widgets ON dashboard_widgets
  FOR ALL USING (
    user_id = auth.uid()
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/analytics.ts

export interface ReportTemplate {
  id: string
  tenantId: string
  name: string
  description?: string
  category: 'financial' | 'academic' | 'operational' | 'hr' | 'student' | 'custom'
  reportType: 'summary' | 'detailed' | 'comparison' | 'trend' | 'forecast'
  dataSources: string[]
  filters: Record<string, any>
  columns: Array<{
    key: string
    label: string
    type: string
    format?: string
  }>
  charts?: Array<{
    type: string
    dataKey: string
    config: Record<string, any>
  }>
  grouping?: Record<string, any>
  sorting?: Record<string, any>
  isPublic: boolean
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface GeneratedReport {
  id: string
  tenantId: string
  templateId?: string
  title: string
  description?: string
  reportType: string
  status: 'generating' | 'completed' | 'failed'
  parameters: Record<string, any>
  filePath?: string
  fileFormat?: 'pdf' | 'excel' | 'csv' | 'json'
  fileSize?: number
  generatedBy?: string
  generatedAt: string
  expiresAt?: string
  downloadCount: number
  lastDownloadedAt?: string
  metadata?: Record<string, any>
}

export interface ScheduledReport {
  id: string
  tenantId: string
  templateId: string
  name: string
  description?: string
  scheduleType: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'annual' | 'custom'
  cronExpression?: string
  parameters: Record<string, any>
  recipients: string[]
  emailSubject?: string
  emailBody?: string
  fileFormats: string[]
  isActive: boolean
  lastRunAt?: string
  nextRunAt?: string
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface AnalyticsDashboardData {
  enrollmentTrends: Array<{
    period: string
    newEnrollments: number
    totalEnrolled: number
    dropouts: number
    netChange: number
  }>
  revenueTrends: Array<{
    period: string
    expectedRevenue: number
    collectedRevenue: number
    pendingRevenue: number
    collectionRate: number
  }>
  staffMetrics: Array<{
    branchName: string
    totalStaff: number
    teachingStaff: number
    nonTeachingStaff: number
    staffStudentRatio: number
    avgExperienceYears: number
  }>
  academicMetrics: Array<{
    branchName: string
    totalStudents: number
    avgAttendance: number
    avgGrade: number
    passRate: number
    dropoutRate: number
  }>
  summary: {
    totalStudents: number
    totalRevenue: number
    totalStaff: number
    avgAttendance: number
  }
}

export interface DashboardWidget {
  id: string
  tenantId: string
  userId: string
  widgetType: string
  title: string
  configuration: Record<string, any>
  position: {
    x: number
    y: number
    w: number
    h: number
  }
  isVisible: boolean
  createdAt: string
  updatedAt: string
}
```

### API Routes

```typescript
// src/app/api/tenant/analytics/dashboard/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const branchId = searchParams.get('branch_id')
  const daysBack = parseInt(searchParams.get('days_back') || '365')
  const monthsBack = parseInt(searchParams.get('months_back') || '12')

  try {
    // Get enrollment trends
    const { data: enrollmentTrends } = await supabase.rpc(
      'calculate_enrollment_trends',
      {
        p_tenant_id: profile.tenant_id,
        p_branch_id: branchId,
        p_days_back: daysBack,
      }
    )

    // Get revenue trends
    const { data: revenueTrends } = await supabase.rpc(
      'calculate_revenue_trends',
      {
        p_tenant_id: profile.tenant_id,
        p_branch_id: branchId,
        p_months_back: monthsBack,
      }
    )

    // Get staff metrics
    const { data: staffMetrics } = await supabase.rpc(
      'calculate_staff_metrics',
      {
        p_tenant_id: profile.tenant_id,
        p_branch_id: branchId,
      }
    )

    // Get academic metrics
    const { data: academicMetrics } = await supabase.rpc(
      'calculate_academic_metrics',
      {
        p_tenant_id: profile.tenant_id,
        p_branch_id: branchId,
      }
    )

    // Calculate summary
    const summary = {
      totalStudents: academicMetrics?.reduce((sum, m) => sum + m.total_students, 0) || 0,
      totalRevenue: revenueTrends?.reduce((sum, r) => sum + parseFloat(r.collected_revenue || '0'), 0) || 0,
      totalStaff: staffMetrics?.reduce((sum, m) => sum + m.total_staff, 0) || 0,
      avgAttendance: academicMetrics?.length > 0
        ? academicMetrics.reduce((sum, m) => sum + parseFloat(m.avg_attendance || '0'), 0) / academicMetrics.length
        : 0,
    }

    return NextResponse.json({
      enrollmentTrends: enrollmentTrends || [],
      revenueTrends: revenueTrends || [],
      staffMetrics: staffMetrics || [],
      academicMetrics: academicMetrics || [],
      summary,
    })

  } catch (error) {
    console.error('Failed to fetch analytics:', error)
    return NextResponse.json(
      { error: 'Failed to fetch analytics' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/analytics/reports/generate/route.ts

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const body = await request.json()
    const { templateId, parameters, fileFormat = 'pdf' } = body

    // Get template
    const { data: template, error: templateError } = await supabase
      .from('report_templates')
      .select('*')
      .eq('id', templateId)
      .single()

    if (templateError) throw templateError

    // Create report record
    const { data: report, error: reportError } = await supabase
      .from('generated_reports')
      .insert({
        tenant_id: profile.tenant_id,
        template_id: templateId,
        title: template.name,
        description: template.description,
        report_type: template.report_type,
        status: 'generating',
        parameters,
        file_format: fileFormat,
        generated_by: user.id,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
      })
      .select()
      .single()

    if (reportError) throw reportError

    // Queue report generation job (background process)
    // This would typically be handled by a job queue system
    // For now, we'll just return the report ID
    
    return NextResponse.json({ report }, { status: 202 })

  } catch (error) {
    console.error('Failed to generate report:', error)
    return NextResponse.json(
      { error: 'Failed to generate report' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Analytics Dashboard Page

```typescript
// src/app/tenant/analytics/page.tsx

'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { 
  BarChart, Bar, LineChart, Line, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer, PieChart, Pie, Cell
} from 'recharts'
import { 
  TrendingUp, Users, DollarSign, GraduationCap,
  Download, Calendar, Filter 
} from 'lucide-react'
import { BranchSelector } from '@/components/analytics/branch-selector'
import { DateRangePicker } from '@/components/analytics/date-range-picker'
import { ExportReportDialog } from '@/components/analytics/export-report-dialog'

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8']

export default function AnalyticsDashboard() {
  const [selectedBranch, setSelectedBranch] = useState<string | null>(null)
  const [dateRange, setDateRange] = useState({ days: 365, months: 12 })
  const [isExportOpen, setIsExportOpen] = useState(false)

  const { data, isLoading } = useQuery({
    queryKey: ['analytics-dashboard', selectedBranch, dateRange],
    queryFn: async () => {
      const params = new URLSearchParams({
        days_back: dateRange.days.toString(),
        months_back: dateRange.months.toString(),
      })
      if (selectedBranch) {
        params.append('branch_id', selectedBranch)
      }
      const res = await fetch(`/api/tenant/analytics/dashboard?${params}`)
      if (!res.ok) throw new Error('Failed to fetch analytics')
      return res.json()
    },
  })

  if (isLoading) {
    return <div>Loading analytics...</div>
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Analytics & Reports</h1>
          <p className="text-muted-foreground">
            Comprehensive insights and performance metrics
          </p>
        </div>
        <div className="flex gap-2">
          <BranchSelector
            value={selectedBranch}
            onChange={setSelectedBranch}
          />
          <Button variant="outline" onClick={() => setIsExportOpen(true)}>
            <Download className="h-4 w-4 mr-2" />
            Export Report
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Students</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data.summary.totalStudents.toLocaleString()}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${data.summary.totalRevenue.toLocaleString()}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Staff</CardTitle>
            <GraduationCap className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data.summary.totalStaff.toLocaleString()}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Attendance</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data.summary.avgAttendance.toFixed(1)}%
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <Tabs defaultValue="enrollment" className="space-y-4">
        <TabsList>
          <TabsTrigger value="enrollment">Enrollment</TabsTrigger>
          <TabsTrigger value="revenue">Revenue</TabsTrigger>
          <TabsTrigger value="academic">Academic</TabsTrigger>
          <TabsTrigger value="staff">Staff</TabsTrigger>
        </TabsList>

        <TabsContent value="enrollment" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Enrollment Trends</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <AreaChart data={data.enrollmentTrends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="period" 
                    tickFormatter={(val) => new Date(val).toLocaleDateString()}
                  />
                  <YAxis />
                  <Tooltip 
                    labelFormatter={(val) => new Date(val).toLocaleDateString()}
                  />
                  <Legend />
                  <Area 
                    type="monotone" 
                    dataKey="total_enrolled" 
                    stackId="1"
                    stroke="#8884d8" 
                    fill="#8884d8"
                    name="Total Enrolled"
                  />
                  <Area 
                    type="monotone" 
                    dataKey="new_enrollments" 
                    stackId="2"
                    stroke="#82ca9d" 
                    fill="#82ca9d"
                    name="New Enrollments"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="revenue" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Revenue Trends</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={data.revenueTrends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="period" />
                  <YAxis tickFormatter={(val) => `$${(val / 1000).toFixed(0)}k`} />
                  <Tooltip 
                    formatter={(val: number) => `$${val.toLocaleString()}`}
                  />
                  <Legend />
                  <Bar dataKey="collected_revenue" fill="#82ca9d" name="Collected" />
                  <Bar dataKey="pending_revenue" fill="#ffc658" name="Pending" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="academic" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Academic Performance by Branch</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={data.academicMetrics}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="branch_name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="avg_attendance" fill="#8884d8" name="Attendance %" />
                  <Bar dataKey="pass_rate" fill="#82ca9d" name="Pass Rate %" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="staff" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Staff Distribution by Branch</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={data.staffMetrics}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="branch_name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="teaching_staff" fill="#0088FE" name="Teaching" />
                  <Bar dataKey="non_teaching_staff" fill="#00C49F" name="Non-Teaching" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Export Dialog */}
      <ExportReportDialog
        open={isExportOpen}
        onOpenChange={setIsExportOpen}
        data={data}
      />
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Multi-dimensional analytics dashboard
- [x] Enrollment trends visualization
- [x] Revenue analytics and trends
- [x] Academic performance metrics
- [x] Staff analytics
- [x] Branch comparison
- [x] Customizable reports
- [x] Export to multiple formats
- [x] Scheduled report delivery
- [x] Real-time and historical data
- [x] Responsive design
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
