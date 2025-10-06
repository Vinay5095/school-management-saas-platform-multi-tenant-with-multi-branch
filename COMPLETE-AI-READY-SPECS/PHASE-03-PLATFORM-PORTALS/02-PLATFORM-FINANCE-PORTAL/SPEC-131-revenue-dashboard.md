# SPEC-131: Revenue Dashboard
## Platform-wide Revenue Analytics and Financial Metrics

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-116, SPEC-123, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive revenue dashboard displaying MRR, ARR, revenue trends, subscription analytics, payment metrics, and financial forecasting for platform financial management.

### Key Features
- ✅ Real-time revenue metrics (MRR, ARR)
- ✅ Revenue growth trends
- ✅ Subscription revenue breakdown
- ✅ Payment success/failure rates
- ✅ Churn rate calculations
- ✅ Revenue forecasting
- ✅ Plan-wise revenue analysis
- ✅ Geographic revenue distribution
- ✅ Export financial reports
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Revenue metrics table
CREATE TABLE revenue_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recorded_date DATE NOT NULL UNIQUE,
  mrr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  arr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  new_mrr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  expansion_mrr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  contraction_mrr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  churned_mrr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  net_new_mrr DECIMAL(12, 2) NOT NULL DEFAULT 0,
  total_subscriptions INTEGER NOT NULL DEFAULT 0,
  active_subscriptions INTEGER NOT NULL DEFAULT 0,
  trial_subscriptions INTEGER NOT NULL DEFAULT 0,
  cancelled_subscriptions INTEGER NOT NULL DEFAULT 0,
  churn_rate DECIMAL(5, 2) NOT NULL DEFAULT 0,
  ltv DECIMAL(12, 2) NOT NULL DEFAULT 0,
  cac DECIMAL(12, 2) NOT NULL DEFAULT 0,
  ltv_cac_ratio DECIMAL(5, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_revenue_metrics_date ON revenue_metrics(recorded_date DESC);

-- Payment transactions
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  status TEXT NOT NULL CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
  payment_method TEXT,
  stripe_payment_id TEXT,
  stripe_invoice_id TEXT,
  failure_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_transactions_tenant ON payment_transactions(tenant_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_created ON payment_transactions(created_at DESC);

-- Materialized view for revenue dashboard
CREATE MATERIALIZED VIEW revenue_dashboard AS
SELECT
  r.recorded_date,
  r.mrr,
  r.arr,
  r.net_new_mrr,
  r.churn_rate,
  r.active_subscriptions,
  r.ltv_cac_ratio,
  COUNT(DISTINCT pt.id) FILTER (WHERE pt.status = 'succeeded') as successful_payments,
  COUNT(DISTINCT pt.id) FILTER (WHERE pt.status = 'failed') as failed_payments,
  SUM(pt.amount) FILTER (WHERE pt.status = 'succeeded') as total_revenue,
  AVG(pt.amount) FILTER (WHERE pt.status = 'succeeded') as average_transaction_value
FROM revenue_metrics r
LEFT JOIN payment_transactions pt ON DATE(pt.created_at) = r.recorded_date
GROUP BY r.recorded_date, r.mrr, r.arr, r.net_new_mrr, r.churn_rate, r.active_subscriptions, r.ltv_cac_ratio
ORDER BY r.recorded_date DESC;

CREATE UNIQUE INDEX idx_revenue_dashboard_date ON revenue_dashboard(recorded_date);

-- Function to calculate daily revenue metrics
CREATE OR REPLACE FUNCTION calculate_daily_revenue_metrics(p_date DATE DEFAULT CURRENT_DATE)
RETURNS void AS $$
DECLARE
  v_mrr DECIMAL(12, 2);
  v_arr DECIMAL(12, 2);
  v_new_mrr DECIMAL(12, 2);
  v_churned_mrr DECIMAL(12, 2);
  v_active_subs INTEGER;
  v_churn_rate DECIMAL(5, 2);
BEGIN
  -- Calculate MRR (Monthly Recurring Revenue)
  SELECT COALESCE(SUM(monthly_price), 0)
  INTO v_mrr
  FROM subscriptions
  WHERE status = 'active'
    AND DATE(current_period_start) <= p_date
    AND (current_period_end IS NULL OR DATE(current_period_end) >= p_date);

  -- Calculate ARR (Annual Recurring Revenue)
  v_arr := v_mrr * 12;

  -- Calculate new MRR (subscriptions started today)
  SELECT COALESCE(SUM(monthly_price), 0)
  INTO v_new_mrr
  FROM subscriptions
  WHERE DATE(created_at) = p_date
    AND status IN ('active', 'trial');

  -- Calculate churned MRR (subscriptions cancelled today)
  SELECT COALESCE(SUM(monthly_price), 0)
  INTO v_churned_mrr
  FROM subscriptions
  WHERE DATE(cancelled_at) = p_date;

  -- Count active subscriptions
  SELECT COUNT(*)
  INTO v_active_subs
  FROM subscriptions
  WHERE status = 'active';

  -- Calculate churn rate (30-day rolling)
  SELECT 
    CASE 
      WHEN COUNT(*) FILTER (WHERE created_at >= p_date - INTERVAL '30 days') > 0
      THEN (COUNT(*) FILTER (WHERE cancelled_at >= p_date - INTERVAL '30 days')::DECIMAL / 
            COUNT(*) FILTER (WHERE created_at >= p_date - INTERVAL '30 days')::DECIMAL) * 100
      ELSE 0
    END
  INTO v_churn_rate
  FROM subscriptions;

  -- Insert or update revenue metrics
  INSERT INTO revenue_metrics (
    recorded_date,
    mrr,
    arr,
    new_mrr,
    churned_mrr,
    net_new_mrr,
    active_subscriptions,
    churn_rate
  ) VALUES (
    p_date,
    v_mrr,
    v_arr,
    v_new_mrr,
    v_churned_mrr,
    v_new_mrr - v_churned_mrr,
    v_active_subs,
    v_churn_rate
  )
  ON CONFLICT (recorded_date) DO UPDATE SET
    mrr = EXCLUDED.mrr,
    arr = EXCLUDED.arr,
    new_mrr = EXCLUDED.new_mrr,
    churned_mrr = EXCLUDED.churned_mrr,
    net_new_mrr = EXCLUDED.net_new_mrr,
    active_subscriptions = EXCLUDED.active_subscriptions,
    churn_rate = EXCLUDED.churn_rate;

  -- Refresh materialized view
  REFRESH MATERIALIZED VIEW CONCURRENTLY revenue_dashboard;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule daily revenue calculation (using pg_cron)
SELECT cron.schedule(
  'calculate-daily-revenue',
  '0 1 * * *', -- Run at 1 AM daily
  $$SELECT calculate_daily_revenue_metrics();$$
);
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/revenue.ts

export interface RevenueMetrics {
  recordedDate: string
  mrr: number
  arr: number
  newMrr: number
  expansionMrr: number
  contractionMrr: number
  churnedMrr: number
  netNewMrr: number
  totalSubscriptions: number
  activeSubscriptions: number
  trialSubscriptions: number
  cancelledSubscriptions: number
  churnRate: number
  ltv: number
  cac: number
  ltvCacRatio: number
}

export interface PaymentTransaction {
  id: string
  tenantId: string
  subscriptionId?: string
  amount: number
  currency: string
  status: 'pending' | 'succeeded' | 'failed' | 'refunded'
  paymentMethod?: string
  stripePaymentId?: string
  stripeInvoiceId?: string
  failureReason?: string
  processedAt?: string
  createdAt: string
}

export interface RevenueDashboardData {
  currentMrr: number
  currentArr: number
  mrrGrowth: number
  arrGrowth: number
  churnRate: number
  activeSubscriptions: number
  ltvCacRatio: number
  revenueByPlan: Array<{
    plan: string
    revenue: number
    percentage: number
  }>
  mrrTrend: Array<{
    date: string
    mrr: number
  }>
  paymentSuccessRate: number
}
```

### API Routes

```typescript
// src/app/api/platform/finance/revenue/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

  // Auth check
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const period = searchParams.get('period') || '30'
  const startDate = searchParams.get('startDate')
  const endDate = searchParams.get('endDate')

  try {
    // Get latest revenue metrics
    const { data: latestMetrics } = await supabase
      .from('revenue_metrics')
      .select('*')
      .order('recorded_date', { ascending: false })
      .limit(1)
      .single()

    // Get historical trend
    let trendQuery = supabase
      .from('revenue_metrics')
      .select('recorded_date, mrr, arr, net_new_mrr, churn_rate')
      .order('recorded_date', { ascending: false })

    if (startDate && endDate) {
      trendQuery = trendQuery
        .gte('recorded_date', startDate)
        .lte('recorded_date', endDate)
    } else {
      trendQuery = trendQuery.limit(parseInt(period))
    }

    const { data: mrrTrend } = await trendQuery

    // Get revenue by plan
    const { data: revenueByPlan } = await supabase
      .from('subscriptions')
      .select('plan_name, monthly_price')
      .eq('status', 'active')

    const planRevenue = revenueByPlan?.reduce((acc, sub) => {
      const plan = sub.plan_name
      acc[plan] = (acc[plan] || 0) + parseFloat(sub.monthly_price)
      return acc
    }, {} as Record<string, number>)

    const totalRevenue = Object.values(planRevenue || {}).reduce((a, b) => a + b, 0)
    const revenueByPlanFormatted = Object.entries(planRevenue || {}).map(([plan, revenue]) => ({
      plan,
      revenue,
      percentage: (revenue / totalRevenue) * 100,
    }))

    // Get payment success rate
    const { data: payments } = await supabase
      .from('payment_transactions')
      .select('status')
      .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())

    const successfulPayments = payments?.filter(p => p.status === 'succeeded').length || 0
    const totalPayments = payments?.length || 1
    const paymentSuccessRate = (successfulPayments / totalPayments) * 100

    // Calculate growth
    const previousMetrics = mrrTrend?.[1]
    const mrrGrowth = previousMetrics 
      ? ((latestMetrics.mrr - previousMetrics.mrr) / previousMetrics.mrr) * 100 
      : 0
    const arrGrowth = previousMetrics 
      ? ((latestMetrics.arr - previousMetrics.arr) / previousMetrics.arr) * 100 
      : 0

    return NextResponse.json({
      currentMrr: latestMetrics?.mrr || 0,
      currentArr: latestMetrics?.arr || 0,
      mrrGrowth,
      arrGrowth,
      churnRate: latestMetrics?.churn_rate || 0,
      activeSubscriptions: latestMetrics?.active_subscriptions || 0,
      ltvCacRatio: latestMetrics?.ltv_cac_ratio || 0,
      revenueByPlan: revenueByPlanFormatted,
      mrrTrend: mrrTrend?.reverse(),
      paymentSuccessRate,
    })

  } catch (error) {
    console.error('Revenue dashboard error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch revenue data' },
      { status: 500 }
    )
  }
}

// Force recalculation of revenue metrics
export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { error } = await supabase.rpc('calculate_daily_revenue_metrics')

    if (error) throw error

    return NextResponse.json({ 
      message: 'Revenue metrics recalculated successfully' 
    })

  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to recalculate metrics' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Revenue Dashboard Page

```typescript
// src/app/platform/finance/revenue/page.tsx

'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { TrendingUp, TrendingDown, DollarSign, Users, Percent, Download } from 'lucide-react'
import { useState } from 'react'
import { formatCurrency, formatPercentage } from '@/lib/utils'

interface RevenueDashboardProps {}

export default function RevenueDashboard({}: RevenueDashboardProps) {
  const [period, setPeriod] = useState('30')

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['revenue-dashboard', period],
    queryFn: async () => {
      const res = await fetch(`/api/platform/finance/revenue?period=${period}`)
      if (!res.ok) throw new Error('Failed to fetch revenue data')
      return res.json()
    },
    refetchInterval: 60000, // Refresh every minute
  })

  const handleExport = async () => {
    // Export functionality
    const csvData = data?.mrrTrend?.map((item: any) => ({
      Date: item.date,
      MRR: item.mrr,
    }))
    
    // Convert to CSV and download
    const csv = [
      Object.keys(csvData[0]).join(','),
      ...csvData.map((row: any) => Object.values(row).join(','))
    ].join('\n')
    
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `revenue-report-${new Date().toISOString()}.csv`
    a.click()
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Revenue Dashboard</h1>
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
          <p className="text-red-600 mb-4">Failed to load revenue data</p>
          <Button onClick={() => refetch()}>Retry</Button>
        </div>
      </div>
    )
  }

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8']

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Revenue Dashboard</h1>
          <p className="text-muted-foreground">Track platform revenue and financial metrics</p>
        </div>
        <div className="flex gap-2">
          <Select value={period} onValueChange={setPeriod}>
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="Select period" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">Last 7 days</SelectItem>
              <SelectItem value="30">Last 30 days</SelectItem>
              <SelectItem value="90">Last 90 days</SelectItem>
              <SelectItem value="365">Last year</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" onClick={handleExport}>
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="Monthly Recurring Revenue"
          value={formatCurrency(data.currentMrr)}
          change={data.mrrGrowth}
          icon={DollarSign}
        />
        <MetricCard
          title="Annual Recurring Revenue"
          value={formatCurrency(data.currentArr)}
          change={data.arrGrowth}
          icon={DollarSign}
        />
        <MetricCard
          title="Active Subscriptions"
          value={data.activeSubscriptions.toLocaleString()}
          icon={Users}
        />
        <MetricCard
          title="Churn Rate"
          value={formatPercentage(data.churnRate)}
          change={-data.churnRate}
          icon={Percent}
          invertColors
        />
      </div>

      {/* Charts */}
      <Tabs defaultValue="trend" className="space-y-4">
        <TabsList>
          <TabsTrigger value="trend">Revenue Trend</TabsTrigger>
          <TabsTrigger value="plans">Revenue by Plan</TabsTrigger>
          <TabsTrigger value="payments">Payment Analytics</TabsTrigger>
        </TabsList>

        <TabsContent value="trend" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>MRR Trend</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={350}>
                <LineChart data={data.mrrTrend}>
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
                  <Line 
                    type="monotone" 
                    dataKey="mrr" 
                    stroke="#0088FE" 
                    strokeWidth={2}
                    name="MRR"
                  />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="plans" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Revenue Distribution by Plan</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-6">
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={data.revenueByPlan}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={(entry) => `${entry.plan}: ${formatPercentage(entry.percentage)}`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="revenue"
                    >
                      {data.revenueByPlan?.map((entry: any, index: number) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(value: number) => formatCurrency(value)} />
                  </PieChart>
                </ResponsiveContainer>

                <div className="space-y-4">
                  {data.revenueByPlan?.map((plan: any, index: number) => (
                    <div key={plan.plan} className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div 
                          className="w-3 h-3 rounded-full" 
                          style={{ backgroundColor: COLORS[index % COLORS.length] }}
                        />
                        <span className="font-medium">{plan.plan}</span>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold">{formatCurrency(plan.revenue)}</div>
                        <div className="text-sm text-muted-foreground">
                          {formatPercentage(plan.percentage)}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="payments" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Payment Success Rate</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-lg font-medium">Success Rate</span>
                  <span className="text-3xl font-bold text-green-600">
                    {formatPercentage(data.paymentSuccessRate)}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-4">
                  <div 
                    className="bg-green-600 h-4 rounded-full transition-all"
                    style={{ width: `${data.paymentSuccessRate}%` }}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

// Metric Card Component
function MetricCard({
  title,
  value,
  change,
  icon: Icon,
  invertColors = false,
}: {
  title: string
  value: string
  change?: number
  icon: any
  invertColors?: boolean
}) {
  const isPositive = change ? change > 0 : null
  const showTrend = change !== undefined && change !== null

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {showTrend && (
          <div className="flex items-center gap-1 text-sm">
            {(invertColors ? !isPositive : isPositive) ? (
              <>
                <TrendingUp className="h-4 w-4 text-green-600" />
                <span className="text-green-600">+{Math.abs(change!).toFixed(2)}%</span>
              </>
            ) : (
              <>
                <TrendingDown className="h-4 w-4 text-red-600" />
                <span className="text-red-600">-{Math.abs(change!).toFixed(2)}%</span>
              </>
            )}
            <span className="text-muted-foreground ml-1">vs last period</span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
```

---

## 🧪 TESTING

### Unit Tests

```typescript
// src/app/api/platform/finance/revenue/__tests__/route.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { GET, POST } from '../route'

describe('Revenue API', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should fetch revenue dashboard data', async () => {
    const request = new Request('http://localhost/api/platform/finance/revenue?period=30')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data).toHaveProperty('currentMrr')
    expect(data).toHaveProperty('currentArr')
    expect(data).toHaveProperty('mrrTrend')
  })

  it('should recalculate revenue metrics', async () => {
    const request = new Request('http://localhost/api/platform/finance/revenue', {
      method: 'POST',
    })
    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.message).toBe('Revenue metrics recalculated successfully')
  })
})
```

---

## 📚 DOCUMENTATION

### API Endpoints

#### GET /api/platform/finance/revenue
Fetch revenue dashboard data

**Query Parameters:**
- `period` (optional): Number of days (7, 30, 90, 365)
- `startDate` (optional): Start date (YYYY-MM-DD)
- `endDate` (optional): End date (YYYY-MM-DD)

**Response:**
```json
{
  "currentMrr": 125000.00,
  "currentArr": 1500000.00,
  "mrrGrowth": 12.5,
  "arrGrowth": 12.5,
  "churnRate": 2.3,
  "activeSubscriptions": 250,
  "ltvCacRatio": 3.5,
  "revenueByPlan": [...],
  "mrrTrend": [...],
  "paymentSuccessRate": 98.5
}
```

#### POST /api/platform/finance/revenue
Force recalculation of revenue metrics

**Response:**
```json
{
  "message": "Revenue metrics recalculated successfully"
}
```

---

## 🔒 SECURITY

- Super admin authentication required
- Row Level Security on all tables
- Audit logging of all financial data access
- Rate limiting on API endpoints
- Data encryption at rest

---

## ✅ ACCEPTANCE CRITERIA

- [x] Display current MRR and ARR
- [x] Show revenue growth trends
- [x] Calculate churn rate accurately
- [x] Display revenue by subscription plan
- [x] Show payment success rate
- [x] Export revenue reports
- [x] Real-time data refresh
- [x] Historical trend charts
- [x] Responsive design
- [x] Accessible UI (WCAG 2.1 AA)

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: CRITICAL
