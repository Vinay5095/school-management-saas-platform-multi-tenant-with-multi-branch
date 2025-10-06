# SPEC-127: Analytics and Reporting Dashboard
## Platform Analytics, Custom Reports, and Data Visualization

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 6-7 hours  
> **Dependencies**: SPEC-116, SPEC-117, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive analytics and reporting system providing deep insights into platform performance, tenant behavior, user engagement, financial metrics, and custom report generation capabilities.

### Key Features
- ✅ Real-time analytics dashboard
- ✅ Custom report builder
- ✅ Data visualization tools
- ✅ Scheduled report generation
- ✅ Export functionality (PDF, CSV, Excel)
- ✅ Tenant performance metrics
- ✅ User behavior analytics
- ✅ Financial reporting
- ✅ System performance tracking
- ✅ Interactive charts and graphs
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Custom reports configuration
CREATE TABLE custom_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_name TEXT NOT NULL,
  description TEXT,
  report_type TEXT NOT NULL CHECK (report_type IN (
    'tenant_analytics', 'user_behavior', 'financial', 'system_performance', 
    'custom_query', 'compliance', 'security'
  )),
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  query_template TEXT,
  chart_config JSONB DEFAULT '{}'::jsonb,
  filters JSONB DEFAULT '[]'::jsonb,
  schedule_config JSONB DEFAULT '{}'::jsonb,
  is_scheduled BOOLEAN DEFAULT FALSE,
  is_public BOOLEAN DEFAULT FALSE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Report executions and results
CREATE TABLE report_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES custom_reports(id),
  execution_type TEXT NOT NULL CHECK (execution_type IN ('manual', 'scheduled')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  parameters JSONB DEFAULT '{}'::jsonb,
  result_data JSONB DEFAULT '{}'::jsonb,
  file_path TEXT,
  file_format TEXT CHECK (file_format IN ('json', 'csv', 'pdf', 'xlsx')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  executed_by UUID REFERENCES users(id),
  error_message TEXT
);

-- Analytics snapshots (daily aggregated data)
CREATE TABLE analytics_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_date DATE NOT NULL,
  snapshot_type TEXT NOT NULL CHECK (snapshot_type IN (
    'platform', 'tenant', 'user_behavior', 'financial'
  )),
  target_id UUID, -- tenant_id for tenant-specific snapshots
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Report subscriptions
CREATE TABLE report_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  report_id UUID NOT NULL REFERENCES custom_reports(id),
  delivery_method TEXT NOT NULL CHECK (delivery_method IN ('email', 'dashboard', 'api')),
  delivery_config JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Data visualization presets
CREATE TABLE visualization_presets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  preset_name TEXT UNIQUE NOT NULL,
  chart_type TEXT NOT NULL CHECK (chart_type IN (
    'line', 'bar', 'pie', 'area', 'scatter', 'heatmap', 'table'
  )),
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_default BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_analytics_snapshots_date_type ON analytics_snapshots(snapshot_date, snapshot_type);
CREATE INDEX idx_analytics_snapshots_target ON analytics_snapshots(target_id, snapshot_date);
CREATE INDEX idx_report_executions_report_status ON report_executions(report_id, status);
CREATE INDEX idx_report_subscriptions_user_active ON report_subscriptions(user_id, is_active);

-- Unique constraint for daily snapshots
CREATE UNIQUE INDEX idx_analytics_snapshots_unique ON analytics_snapshots(
  snapshot_date, snapshot_type, COALESCE(target_id, '00000000-0000-0000-0000-000000000000')
);
```

---

## 🎨 UI COMPONENTS

### Analytics Dashboard Component
```tsx
// components/admin/analytics/AnalyticsDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { DatePickerWithRange } from '@/components/ui/date-range-picker';
import { ReportBuilder } from './ReportBuilder';
import { ChartRenderer } from './ChartRenderer';
import { MetricsGrid } from './MetricsGrid';
import { 
  BarChart3, 
  LineChart, 
  PieChart, 
  TrendingUp,
  Download,
  Calendar,
  Filter,
  Plus
} from 'lucide-react';
import { addDays } from 'date-fns';

interface AnalyticsData {
  platformMetrics: {
    totalTenants: number;
    totalUsers: number;
    totalRevenue: number;
    avgSessionDuration: number;
    churnRate: number;
    growthRate: number;
  };
  chartData: {
    tenantGrowth: any[];
    userActivity: any[];
    revenueByMonth: any[];
    topTenants: any[];
  };
  trends: {
    tenantsChange: number;
    usersChange: number;
    revenueChange: number;
  };
}

export function AnalyticsDashboard() {
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({
    from: addDays(new Date(), -30),
    to: new Date()
  });
  const [selectedMetric, setSelectedMetric] = useState('overview');
  const [showReportBuilder, setShowReportBuilder] = useState(false);

  useEffect(() => {
    loadAnalyticsData();
  }, [dateRange]);

  const loadAnalyticsData = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        startDate: dateRange.from.toISOString(),
        endDate: dateRange.to.toISOString()
      });
      
      const response = await fetch(`/api/admin/analytics/dashboard?${params}`);
      const data = await response.json();
      setAnalyticsData(data);
    } catch (error) {
      console.error('Failed to load analytics data:', error);
    } finally {
      setLoading(false);
    }
  };

  const exportReport = async (format: 'csv' | 'pdf' | 'xlsx') => {
    try {
      const params = new URLSearchParams({
        format,
        startDate: dateRange.from.toISOString(),
        endDate: dateRange.to.toISOString(),
        metric: selectedMetric
      });
      
      const response = await fetch(`/api/admin/analytics/export?${params}`);
      const blob = await response.blob();
      
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `analytics-report-${format}.${format}`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (error) {
      console.error('Failed to export report:', error);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-96">Loading analytics data...</div>;
  }

  if (!analyticsData) {
    return <div className="text-center text-gray-500 h-96">Failed to load analytics data</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Analytics & Reporting</h1>
          <p className="text-gray-600">Platform performance metrics and custom reports</p>
        </div>
        <div className="flex gap-2">
          <DatePickerWithRange
            date={dateRange}
            onDateChange={setDateRange}
          />
          <Button variant="outline" onClick={() => setShowReportBuilder(true)}>
            <Plus className="w-4 h-4 mr-2" />
            New Report
          </Button>
          <Select value={selectedMetric} onValueChange={setSelectedMetric}>
            <SelectTrigger className="w-32">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="overview">Overview</SelectItem>
              <SelectItem value="tenants">Tenants</SelectItem>
              <SelectItem value="users">Users</SelectItem>
              <SelectItem value="revenue">Revenue</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" onClick={() => exportReport('pdf')}>
            <Download className="w-4 h-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      <MetricsGrid 
        metrics={analyticsData.platformMetrics} 
        trends={analyticsData.trends}
      />

      {/* Analytics Tabs */}
      <Tabs defaultValue="dashboard">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="dashboard">Dashboard</TabsTrigger>
          <TabsTrigger value="reports">Reports</TabsTrigger>
          <TabsTrigger value="insights">Insights</TabsTrigger>
          <TabsTrigger value="exports">Exports</TabsTrigger>
        </TabsList>

        <TabsContent value="dashboard">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <LineChart className="w-5 h-5" />
                  Tenant Growth Trend
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ChartRenderer
                  type="line"
                  data={analyticsData.chartData.tenantGrowth}
                  config={{
                    xField: 'date',
                    yField: 'count',
                    smooth: true,
                    color: '#3b82f6'
                  }}
                />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <BarChart3 className="w-5 h-5" />
                  User Activity
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ChartRenderer
                  type="bar"
                  data={analyticsData.chartData.userActivity}
                  config={{
                    xField: 'date',
                    yField: 'activeUsers',
                    color: '#10b981'
                  }}
                />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="w-5 h-5" />
                  Revenue by Month
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ChartRenderer
                  type="area"
                  data={analyticsData.chartData.revenueByMonth}
                  config={{
                    xField: 'month',
                    yField: 'revenue',
                    smooth: true,
                    color: '#8b5cf6'
                  }}
                />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <PieChart className="w-5 h-5" />
                  Top Performing Tenants
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ChartRenderer
                  type="pie"
                  data={analyticsData.chartData.topTenants}
                  config={{
                    angleField: 'value',
                    colorField: 'name',
                    radius: 0.8,
                    label: {
                      type: 'outer',
                      content: '{name}: {percentage}'
                    }
                  }}
                />
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="reports">
          <Card>
            <CardHeader>
              <CardTitle>Custom Reports</CardTitle>
              <CardDescription>Create and manage custom analytics reports</CardDescription>
            </CardHeader>
            <CardContent>
              {showReportBuilder ? (
                <ReportBuilder onClose={() => setShowReportBuilder(false)} />
              ) : (
                <div className="space-y-4">
                  <Button onClick={() => setShowReportBuilder(true)}>
                    <Plus className="w-4 h-4 mr-2" />
                    Create New Report
                  </Button>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div className="p-4 border rounded-lg">
                      <h3 className="font-medium">Monthly Tenant Report</h3>
                      <p className="text-sm text-gray-500 mt-1">Comprehensive tenant activity and performance metrics</p>
                      <div className="flex gap-2 mt-3">
                        <Button size="sm">Run</Button>
                        <Button size="sm" variant="outline">Edit</Button>
                      </div>
                    </div>
                    
                    <div className="p-4 border rounded-lg">
                      <h3 className="font-medium">User Engagement Analysis</h3>
                      <p className="text-sm text-gray-500 mt-1">User behavior patterns and engagement metrics</p>
                      <div className="flex gap-2 mt-3">
                        <Button size="sm">Run</Button>
                        <Button size="sm" variant="outline">Edit</Button>
                      </div>
                    </div>
                    
                    <div className="p-4 border rounded-lg">
                      <h3 className="font-medium">Financial Performance</h3>
                      <p className="text-sm text-gray-500 mt-1">Revenue, billing, and financial health metrics</p>
                      <div className="flex gap-2 mt-3">
                        <Button size="sm">Run</Button>
                        <Button size="sm" variant="outline">Edit</Button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="insights">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Platform Insights</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="p-3 bg-blue-50 border-l-4 border-blue-400">
                    <h4 className="font-medium text-blue-800">Growth Trend</h4>
                    <p className="text-sm text-blue-700">Tenant registration increased by 23% this month</p>
                  </div>
                  <div className="p-3 bg-green-50 border-l-4 border-green-400">
                    <h4 className="font-medium text-green-800">User Engagement</h4>
                    <p className="text-sm text-green-700">Daily active users are up 15% compared to last month</p>
                  </div>
                  <div className="p-3 bg-yellow-50 border-l-4 border-yellow-400">
                    <h4 className="font-medium text-yellow-800">Performance Alert</h4>
                    <p className="text-sm text-yellow-700">API response times increased during peak hours</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Recommendations</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="p-3 border rounded">
                    <h4 className="font-medium">Scale Infrastructure</h4>
                    <p className="text-sm text-gray-600">Consider adding more server capacity for peak usage</p>
                  </div>
                  <div className="p-3 border rounded">
                    <h4 className="font-medium">Optimize Onboarding</h4>
                    <p className="text-sm text-gray-600">Improve new tenant setup process based on analytics</p>
                  </div>
                  <div className="p-3 border rounded">
                    <h4 className="font-medium">Feature Usage Analysis</h4>
                    <p className="text-sm text-gray-600">Some features are underutilized - consider UI improvements</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="exports">
          <Card>
            <CardHeader>
              <CardTitle>Export Center</CardTitle>
              <CardDescription>Generate and download reports in various formats</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Button 
                  variant="outline" 
                  className="h-24 flex-col"
                  onClick={() => exportReport('csv')}
                >
                  <Download className="w-6 h-6 mb-2" />
                  Export as CSV
                </Button>
                <Button 
                  variant="outline" 
                  className="h-24 flex-col"
                  onClick={() => exportReport('pdf')}
                >
                  <Download className="w-6 h-6 mb-2" />
                  Export as PDF
                </Button>
                <Button 
                  variant="outline" 
                  className="h-24 flex-col"
                  onClick={() => exportReport('xlsx')}
                >
                  <Download className="w-6 h-6 mb-2" />
                  Export as Excel
                </Button>
              </div>
              
              <div className="mt-6">
                <h3 className="font-medium mb-3">Recent Exports</h3>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-3 border rounded">
                    <div>
                      <div className="font-medium">Platform Overview Report</div>
                      <div className="text-sm text-gray-500">Generated 2 hours ago</div>
                    </div>
                    <Button size="sm" variant="outline">Download</Button>
                  </div>
                  <div className="flex items-center justify-between p-3 border rounded">
                    <div>
                      <div className="font-medium">Tenant Analytics</div>
                      <div className="text-sm text-gray-500">Generated yesterday</div>
                    </div>
                    <Button size="sm" variant="outline">Download</Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

### Chart Renderer Component
```tsx
// components/admin/analytics/ChartRenderer.tsx
'use client';

import React from 'react';
import { Line, Bar, Area, Pie } from '@ant-design/plots';

interface ChartRendererProps {
  type: 'line' | 'bar' | 'area' | 'pie';
  data: any[];
  config: any;
}

export function ChartRenderer({ type, data, config }: ChartRendererProps) {
  const commonConfig = {
    data,
    ...config,
    autoFit: true,
    height: 300,
  };

  switch (type) {
    case 'line':
      return <Line {...commonConfig} />;
    case 'bar':
      return <Bar {...commonConfig} />;
    case 'area':
      return <Area {...commonConfig} />;
    case 'pie':
      return <Pie {...commonConfig} />;
    default:
      return <div>Unsupported chart type</div>;
  }
}
```

### Metrics Grid Component
```tsx
// components/admin/analytics/MetricsGrid.tsx
'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Users, 
  Building, 
  DollarSign, 
  Clock,
  TrendingUp,
  TrendingDown
} from 'lucide-react';

interface MetricsGridProps {
  metrics: {
    totalTenants: number;
    totalUsers: number;
    totalRevenue: number;
    avgSessionDuration: number;
    churnRate: number;
    growthRate: number;
  };
  trends: {
    tenantsChange: number;
    usersChange: number;
    revenueChange: number;
  };
}

export function MetricsGrid({ metrics, trends }: MetricsGridProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours}h ${mins}m`;
  };

  const getTrendIcon = (change: number) => {
    return change >= 0 ? 
      <TrendingUp className="w-3 h-3 text-green-500" /> :
      <TrendingDown className="w-3 h-3 text-red-500" />;
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Tenants</CardTitle>
          <Building className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{metrics.totalTenants.toLocaleString()}</div>
          <div className="flex items-center text-xs text-muted-foreground">
            {getTrendIcon(trends.tenantsChange)}
            {Math.abs(trends.tenantsChange)}% from last month
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Users</CardTitle>
          <Users className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{metrics.totalUsers.toLocaleString()}</div>
          <div className="flex items-center text-xs text-muted-foreground">
            {getTrendIcon(trends.usersChange)}
            {Math.abs(trends.usersChange)}% from last month
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Monthly Revenue</CardTitle>
          <DollarSign className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{formatCurrency(metrics.totalRevenue)}</div>
          <div className="flex items-center text-xs text-muted-foreground">
            {getTrendIcon(trends.revenueChange)}
            {Math.abs(trends.revenueChange)}% from last month
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Avg Session</CardTitle>
          <Clock className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{formatDuration(metrics.avgSessionDuration)}</div>
          <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1">
            <Badge variant={metrics.churnRate < 5 ? 'default' : 'destructive'}>
              {metrics.churnRate}% churn
            </Badge>
            <Badge variant={metrics.growthRate > 0 ? 'default' : 'secondary'}>
              {metrics.growthRate}% growth
            </Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
```

---

## 🔧 API ROUTES

### Analytics Dashboard API
```typescript
// app/api/admin/analytics/dashboard/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';
import { generateAnalyticsData } from '@/lib/analytics/generator';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const endDate = searchParams.get('endDate') || new Date().toISOString();

    // Get platform metrics
    const [tenantCount, userCount] = await Promise.all([
      supabase.from('tenants').select('*', { count: 'exact' }),
      supabase.from('users').select('*', { count: 'exact' })
    ]);

    // Get revenue data (simplified - would come from billing system)
    const monthlyRevenue = 125000; // This would be calculated from actual billing data

    // Generate chart data
    const chartData = await generateAnalyticsData(startDate, endDate);

    // Calculate trends (simplified)
    const trends = {
      tenantsChange: 12.5, // % change from previous period
      usersChange: 8.3,
      revenueChange: 15.2
    };

    const analyticsData = {
      platformMetrics: {
        totalTenants: tenantCount.count || 0,
        totalUsers: userCount.count || 0,
        totalRevenue: monthlyRevenue,
        avgSessionDuration: 45, // minutes
        churnRate: 3.2, // percentage
        growthRate: 12.5 // percentage
      },
      chartData,
      trends
    };

    return NextResponse.json(analyticsData);
  } catch (error) {
    console.error('Failed to fetch analytics dashboard data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch analytics data' },
      { status: 500 }
    );
  }
}
```

### Analytics Export API
```typescript
// app/api/admin/analytics/export/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';
import { generateReport } from '@/lib/reports/generator';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    
    const { searchParams } = new URL(request.url);
    const format = searchParams.get('format') || 'csv';
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');
    const metric = searchParams.get('metric') || 'overview';

    // Generate report based on parameters
    const reportData = await generateReport({
      format: format as 'csv' | 'pdf' | 'xlsx',
      startDate,
      endDate,
      metric,
      type: 'analytics'
    });

    // Set appropriate headers for file download
    const headers = new Headers();
    
    switch (format) {
      case 'csv':
        headers.set('Content-Type', 'text/csv');
        headers.set('Content-Disposition', 'attachment; filename="analytics-report.csv"');
        break;
      case 'pdf':
        headers.set('Content-Type', 'application/pdf');
        headers.set('Content-Disposition', 'attachment; filename="analytics-report.pdf"');
        break;
      case 'xlsx':
        headers.set('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        headers.set('Content-Disposition', 'attachment; filename="analytics-report.xlsx"');
        break;
    }

    return new NextResponse(reportData, { headers });
  } catch (error) {
    console.error('Failed to export analytics report:', error);
    return NextResponse.json(
      { error: 'Failed to export report' },
      { status: 500 }
    );
  }
}
```

---

## ⚙️ ANALYTICS UTILITIES

### Analytics Data Generator
```typescript
// lib/analytics/generator.ts
import { createClient } from '@/lib/supabase/server';
import { eachDayOfInterval, format, parseISO } from 'date-fns';

export async function generateAnalyticsData(startDate: string, endDate: string) {
  const supabase = createClient();
  
  const start = parseISO(startDate);
  const end = parseISO(endDate);
  const days = eachDayOfInterval({ start, end });

  // Generate tenant growth data
  const tenantGrowth = await Promise.all(
    days.map(async (day) => {
      const { count } = await supabase
        .from('tenants')
        .select('*', { count: 'exact' })
        .lte('created_at', day.toISOString());
      
      return {
        date: format(day, 'yyyy-MM-dd'),
        count: count || 0
      };
    })
  );

  // Generate user activity data (simplified)
  const userActivity = days.map(day => ({
    date: format(day, 'yyyy-MM-dd'),
    activeUsers: Math.floor(Math.random() * 500) + 200, // Simplified - would be real data
    newUsers: Math.floor(Math.random() * 50) + 10
  }));

  // Generate revenue by month (simplified)
  const revenueByMonth = [
    { month: 'Jan', revenue: 98000 },
    { month: 'Feb', revenue: 112000 },
    { month: 'Mar', revenue: 125000 },
    { month: 'Apr', revenue: 138000 },
    { month: 'May', revenue: 142000 },
    { month: 'Jun', revenue: 156000 }
  ];

  // Get top tenants by user count
  const { data: topTenants } = await supabase
    .from('tenants')
    .select(`
      name,
      users:users(count)
    `)
    .limit(5);

  const topTenantsData = topTenants?.map(tenant => ({
    name: tenant.name,
    value: tenant.users?.length || 0
  })) || [];

  return {
    tenantGrowth,
    userActivity,
    revenueByMonth,
    topTenants: topTenantsData
  };
}
```

### Report Generator
```typescript
// lib/reports/generator.ts
import { createObjectCsvWriter } from 'csv-writer';
import PDFDocument from 'pdfkit';
import ExcelJS from 'exceljs';
import { createClient } from '@/lib/supabase/server';

interface ReportOptions {
  format: 'csv' | 'pdf' | 'xlsx';
  startDate?: string;
  endDate?: string;
  metric: string;
  type: string;
}

export async function generateReport(options: ReportOptions): Promise<Buffer> {
  const supabase = createClient();
  
  // Get report data based on options
  const reportData = await getReportData(options);
  
  switch (options.format) {
    case 'csv':
      return generateCSVReport(reportData);
    case 'pdf':
      return generatePDFReport(reportData, options);
    case 'xlsx':
      return generateExcelReport(reportData, options);
    default:
      throw new Error('Unsupported format');
  }
}

async function getReportData(options: ReportOptions) {
  const supabase = createClient();
  
  // This would fetch data based on the report type and parameters
  // For now, returning sample data
  return [
    { date: '2025-01-01', tenants: 150, users: 2500, revenue: 125000 },
    { date: '2025-01-02', tenants: 152, users: 2520, revenue: 127000 },
    { date: '2025-01-03', tenants: 155, users: 2580, revenue: 129000 }
  ];
}

async function generateCSVReport(data: any[]): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const csvWriter = createObjectCsvWriter({
      path: '/tmp/report.csv',
      header: Object.keys(data[0] || {}).map(key => ({ id: key, title: key }))
    });
    
    csvWriter.writeRecords(data)
      .then(() => {
        // Read and return the file as buffer
        const fs = require('fs');
        const buffer = fs.readFileSync('/tmp/report.csv');
        resolve(buffer);
      })
      .catch(reject);
  });
}

async function generatePDFReport(data: any[], options: ReportOptions): Promise<Buffer> {
  return new Promise((resolve) => {
    const doc = new PDFDocument();
    const buffers: Buffer[] = [];
    
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => {
      const pdfData = Buffer.concat(buffers);
      resolve(pdfData);
    });
    
    // Create PDF content
    doc.fontSize(20).text('Analytics Report', 100, 100);
    doc.fontSize(14).text(`Report Type: ${options.metric}`, 100, 140);
    doc.fontSize(12).text(`Generated: ${new Date().toLocaleDateString()}`, 100, 160);
    
    // Add data table (simplified)
    let y = 200;
    data.forEach((row, index) => {
      if (index === 0) {
        // Headers
        let x = 100;
        Object.keys(row).forEach(key => {
          doc.text(key, x, y);
          x += 100;
        });
        y += 20;
      }
      
      let x = 100;
      Object.values(row).forEach(value => {
        doc.text(String(value), x, y);
        x += 100;
      });
      y += 20;
    });
    
    doc.end();
  });
}

async function generateExcelReport(data: any[], options: ReportOptions): Promise<Buffer> {
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Analytics Report');
  
  // Add headers
  if (data.length > 0) {
    const headers = Object.keys(data[0]);
    worksheet.addRow(headers);
    
    // Add data rows
    data.forEach(row => {
      worksheet.addRow(Object.values(row));
    });
  }
  
  // Style the headers
  worksheet.getRow(1).font = { bold: true };
  worksheet.getRow(1).fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFE0E0E0' }
  };
  
  // Auto-fit columns
  worksheet.columns.forEach(column => {
    column.width = 15;
  });
  
  const buffer = await workbook.xlsx.writeBuffer();
  return Buffer.from(buffer);
}
```

---

## 📋 TESTING REQUIREMENTS

### Analytics Dashboard Tests
```typescript
// __tests__/admin/analytics/AnalyticsDashboard.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { AnalyticsDashboard } from '@/components/admin/analytics/AnalyticsDashboard';

const mockAnalyticsData = {
  platformMetrics: {
    totalTenants: 150,
    totalUsers: 2500,
    totalRevenue: 125000,
    avgSessionDuration: 45,
    churnRate: 3.2,
    growthRate: 12.5
  },
  chartData: {
    tenantGrowth: [
      { date: '2025-01-01', count: 148 },
      { date: '2025-01-02', count: 150 }
    ],
    userActivity: [
      { date: '2025-01-01', activeUsers: 400 },
      { date: '2025-01-02', activeUsers: 420 }
    ],
    revenueByMonth: [
      { month: 'Jan', revenue: 125000 }
    ],
    topTenants: [
      { name: 'Tenant A', value: 100 }
    ]
  },
  trends: {
    tenantsChange: 12.5,
    usersChange: 8.3,
    revenueChange: 15.2
  }
};

describe('AnalyticsDashboard', () => {
  beforeEach(() => {
    global.fetch = jest.fn().mockResolvedValue({
      json: () => Promise.resolve(mockAnalyticsData)
    });
  });

  it('renders analytics dashboard', async () => {
    render(<AnalyticsDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Analytics & Reporting')).toBeInTheDocument();
    });
  });

  it('displays platform metrics', async () => {
    render(<AnalyticsDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('150')).toBeInTheDocument(); // Total tenants
      expect(screen.getByText('2,500')).toBeInTheDocument(); // Total users
      expect(screen.getByText('$125,000.00')).toBeInTheDocument(); // Revenue
    });
  });

  it('shows trend indicators', async () => {
    render(<AnalyticsDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText(/12.5% from last month/)).toBeInTheDocument();
    });
  });
});
```

---

## 🔐 PERMISSIONS & ROLES

### Required Permissions
- **Super Admin**: Full access to all analytics and reporting features
- **Platform Analyst**: View analytics, create and run custom reports
- **Read-Only Admin**: View pre-built reports and dashboards

### Role-based Access Control
```sql
-- Analytics and reporting permissions
INSERT INTO role_permissions (role_name, permission) VALUES
('super_admin', 'analytics:view_all'),
('super_admin', 'analytics:create_reports'),
('super_admin', 'analytics:export_data'),
('super_admin', 'analytics:manage_dashboards'),
('platform_analyst', 'analytics:view_platform'),
('platform_analyst', 'analytics:create_reports'),
('platform_analyst', 'analytics:export_reports'),
('read_only_admin', 'analytics:view_reports');
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM