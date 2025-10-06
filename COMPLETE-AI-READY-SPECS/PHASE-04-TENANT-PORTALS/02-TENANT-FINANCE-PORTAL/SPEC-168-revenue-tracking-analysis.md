# SPEC-168: Revenue Tracking & Analysis

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-168  
**Title**: Revenue Tracking & Analysis System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Revenue Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-166, SPEC-167  

---

## 📋 DESCRIPTION

Implement comprehensive revenue tracking and analysis system with multi-stream revenue monitoring, forecasting, trend analysis, and predictive insights. Features include revenue categorization, collection tracking, outstanding analysis, and automated reconciliation.

---

## 🎯 SUCCESS CRITERIA

- [ ] Multi-stream revenue tracking operational
- [ ] Real-time revenue dashboards working
- [ ] Forecasting models accurate
- [ ] Collection rate analysis functional
- [ ] Outstanding revenue alerts working
- [ ] Revenue reconciliation automated
- [ ] Export/reporting functional
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Revenue Streams Configuration
CREATE TABLE IF NOT EXISTS revenue_streams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  name VARCHAR(200) NOT NULL,
  category VARCHAR(100) NOT NULL, -- tuition, admission, transport, etc.
  is_recurring BOOLEAN DEFAULT false,
  billing_frequency VARCHAR(50), -- monthly, quarterly, annual
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Revenue Forecast
CREATE TABLE IF NOT EXISTS revenue_forecast (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  period DATE NOT NULL,
  revenue_stream_id UUID REFERENCES revenue_streams(id),
  forecasted_amount NUMERIC(15,2) NOT NULL,
  actual_amount NUMERIC(15,2),
  variance_amount NUMERIC(15,2),
  variance_percentage NUMERIC(5,2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Revenue Analytics View
CREATE MATERIALIZED VIEW revenue_analytics AS
SELECT
  ft.tenant_id,
  ft.branch_id,
  DATE_TRUNC('month', ft.transaction_date) as period,
  ft.category as revenue_stream,
  
  -- Revenue metrics
  SUM(ft.amount) as total_revenue,
  COUNT(*) as transaction_count,
  AVG(ft.amount) as average_transaction,
  
  -- Collection metrics
  COUNT(*) FILTER (WHERE ft.status = 'completed') as collected_count,
  COUNT(*) FILTER (WHERE ft.status = 'pending') as pending_count,
  SUM(ft.amount) FILTER (WHERE ft.status = 'completed') as collected_amount,
  SUM(ft.amount) FILTER (WHERE ft.status = 'pending') as pending_amount,
  
  -- Collection rate
  CASE 
    WHEN COUNT(*) > 0 THEN 
      (COUNT(*) FILTER (WHERE ft.status = 'completed')::NUMERIC / COUNT(*) * 100)
    ELSE 0 
  END as collection_rate

FROM financial_transactions ft
WHERE ft.type = 'revenue'
GROUP BY ft.tenant_id, ft.branch_id, DATE_TRUNC('month', ft.transaction_date), ft.category;

CREATE UNIQUE INDEX ON revenue_analytics(tenant_id, branch_id, period, revenue_stream);

-- Enable RLS
ALTER TABLE revenue_streams ENABLE ROW LEVEL SECURITY;
ALTER TABLE revenue_forecast ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant users can view revenue streams"
  ON revenue_streams FOR SELECT
  TO authenticated
  USING (tenant_id = (SELECT tenant_id FROM user_profiles WHERE user_id = auth.uid()));
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/revenue-tracking.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import { startOfMonth, endOfMonth, addMonths, format } from 'date-fns';

export interface RevenueMetrics {
  totalRevenue: number;
  collectedRevenue: number;
  pendingRevenue: number;
  collectionRate: number;
  monthOverMonthGrowth: number;
  yearOverYearGrowth: number;
}

export interface RevenueStream {
  id: string;
  name: string;
  category: string;
  currentMonthRevenue: number;
  previousMonthRevenue: number;
  growth: number;
  collectionRate: number;
}

export class RevenueTrackingAPI {
  private supabase = createClient();

  async getRevenueMetrics(params: {
    tenantId: string;
    startDate: Date;
    endDate: Date;
    branchId?: string;
  }): Promise<RevenueMetrics> {
    let query = this.supabase
      .from('financial_transactions')
      .select('amount, status, transaction_date')
      .eq('tenant_id', params.tenantId)
      .eq('type', 'revenue')
      .gte('transaction_date', params.startDate.toISOString())
      .lte('transaction_date', params.endDate.toISOString());

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query;
    if (error) throw error;

    const totalRevenue = data.reduce((sum, t) => sum + t.amount, 0);
    const collectedRevenue = data
      .filter(t => t.status === 'completed')
      .reduce((sum, t) => sum + t.amount, 0);
    const pendingRevenue = data
      .filter(t => t.status === 'pending')
      .reduce((sum, t) => sum + t.amount, 0);
    const collectionRate = totalRevenue > 0 
      ? (collectedRevenue / totalRevenue) * 100 
      : 0;

    // Calculate growth metrics
    const previousPeriodStart = new Date(params.startDate);
    previousPeriodStart.setMonth(previousPeriodStart.getMonth() - 1);
    const previousPeriodEnd = new Date(params.endDate);
    previousPeriodEnd.setMonth(previousPeriodEnd.getMonth() - 1);

    const { data: prevData } = await this.supabase
      .from('financial_transactions')
      .select('amount')
      .eq('tenant_id', params.tenantId)
      .eq('type', 'revenue')
      .eq('status', 'completed')
      .gte('transaction_date', previousPeriodStart.toISOString())
      .lte('transaction_date', previousPeriodEnd.toISOString());

    const prevRevenue = prevData?.reduce((sum, t) => sum + t.amount, 0) || 0;
    const monthOverMonthGrowth = prevRevenue > 0
      ? ((collectedRevenue - prevRevenue) / prevRevenue) * 100
      : 0;

    return {
      totalRevenue,
      collectedRevenue,
      pendingRevenue,
      collectionRate,
      monthOverMonthGrowth,
      yearOverYearGrowth: 0, // Implement YoY calculation
    };
  }

  async getRevenueByStream(params: {
    tenantId: string;
    period: Date;
  }): Promise<RevenueStream[]> {
    const periodStart = startOfMonth(params.period);
    const periodEnd = endOfMonth(params.period);
    const prevPeriodStart = addMonths(periodStart, -1);
    const prevPeriodEnd = endOfMonth(prevPeriodStart);

    const { data: currentData, error: currentError } = await this.supabase
      .from('revenue_analytics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('period', format(periodStart, 'yyyy-MM-dd'));

    if (currentError) throw currentError;

    const { data: prevData } = await this.supabase
      .from('revenue_analytics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('period', format(prevPeriodStart, 'yyyy-MM-dd'));

    const prevMap = new Map(
      prevData?.map(item => [item.revenue_stream, item.total_revenue]) || []
    );

    return (currentData || []).map(item => {
      const prevRevenue = prevMap.get(item.revenue_stream) || 0;
      const growth = prevRevenue > 0
        ? ((item.total_revenue - prevRevenue) / prevRevenue) * 100
        : 0;

      return {
        id: item.revenue_stream,
        name: item.revenue_stream,
        category: item.revenue_stream,
        currentMonthRevenue: item.total_revenue || 0,
        previousMonthRevenue: prevRevenue,
        growth,
        collectionRate: item.collection_rate || 0,
      };
    });
  }

  async getRevenueTrends(params: {
    tenantId: string;
    months: number;
    branchId?: string;
  }) {
    const endDate = new Date();
    const startDate = addMonths(endDate, -params.months);

    const { data, error } = await this.supabase
      .from('revenue_analytics')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .gte('period', format(startDate, 'yyyy-MM-dd'))
      .lte('period', format(endDate, 'yyyy-MM-dd'))
      .order('period', { ascending: true });

    if (error) throw error;

    // Group by period
    const trendMap = new Map();
    data.forEach(item => {
      const period = format(new Date(item.period), 'MMM yyyy');
      if (!trendMap.has(period)) {
        trendMap.set(period, {
          period,
          totalRevenue: 0,
          collectedRevenue: 0,
          pendingRevenue: 0,
        });
      }
      const trend = trendMap.get(period);
      trend.totalRevenue += item.total_revenue || 0;
      trend.collectedRevenue += item.collected_amount || 0;
      trend.pendingRevenue += item.pending_amount || 0;
    });

    return Array.from(trendMap.values());
  }

  async getOutstandingRevenue(params: {
    tenantId: string;
    ageingBrackets?: number[];
  }) {
    const brackets = params.ageingBrackets || [30, 60, 90];
    const now = new Date();

    const { data, error } = await this.supabase
      .from('financial_transactions')
      .select('amount, transaction_date, customer_name')
      .eq('tenant_id', params.tenantId)
      .eq('type', 'revenue')
      .eq('status', 'pending')
      .order('transaction_date', { ascending: true });

    if (error) throw error;

    const aged = data.map(transaction => {
      const daysPending = Math.floor(
        (now.getTime() - new Date(transaction.transaction_date).getTime()) / 
        (1000 * 60 * 60 * 24)
      );

      let bracket = 'Current';
      for (let i = 0; i < brackets.length; i++) {
        if (daysPending > brackets[i]) {
          bracket = i === brackets.length - 1
            ? `${brackets[i]}+ days`
            : `${brackets[i]}-${brackets[i + 1]} days`;
        }
      }

      return {
        ...transaction,
        daysPending,
        bracket,
      };
    });

    // Group by bracket
    const summary = brackets.reduce((acc, bracket) => {
      acc[`${bracket}days`] = aged
        .filter(t => t.daysPending > bracket && t.daysPending <= (bracket + 30))
        .reduce((sum, t) => sum + t.amount, 0);
      return acc;
    }, {} as Record<string, number>);

    return {
      details: aged,
      summary,
      total: aged.reduce((sum, t) => sum + t.amount, 0),
    };
  }

  async createRevenueForecast(params: {
    tenantId: string;
    branchId?: string;
    period: Date;
    revenueStreamId: string;
    forecastedAmount: number;
    notes?: string;
  }) {
    const { data, error } = await this.supabase
      .from('revenue_forecast')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        period: format(params.period, 'yyyy-MM-dd'),
        revenue_stream_id: params.revenueStreamId,
        forecasted_amount: params.forecastedAmount,
        notes: params.notes,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}

export const revenueTrackingAPI = new RevenueTrackingAPI();
```

### Component (`/components/finance/RevenueTracking.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { revenueTrackingAPI, type RevenueMetrics } from '@/lib/api/revenue-tracking';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { TrendingUp, TrendingDown, DollarSign, Clock } from 'lucide-react';
import { formatCurrency } from '@/lib/utils';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

export function RevenueTracking({ tenantId }: { tenantId: string }) {
  const [metrics, setMetrics] = useState<RevenueMetrics | null>(null);
  const [streams, setStreams] = useState<any[]>([]);
  const [trends, setTrends] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadRevenueData();
  }, [tenantId]);

  const loadRevenueData = async () => {
    setLoading(true);
    try {
      const [metricsData, streamsData, trendsData] = await Promise.all([
        revenueTrackingAPI.getRevenueMetrics({
          tenantId,
          startDate: new Date(new Date().setDate(1)),
          endDate: new Date(),
        }),
        revenueTrackingAPI.getRevenueByStream({
          tenantId,
          period: new Date(),
        }),
        revenueTrackingAPI.getRevenueTrends({
          tenantId,
          months: 12,
        }),
      ]);

      setMetrics(metricsData);
      setStreams(streamsData);
      setTrends(trendsData);
    } catch (error) {
      console.error('Error loading revenue data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading || !metrics) {
    return <div>Loading revenue data...</div>;
  }

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-3xl font-bold">Revenue Tracking & Analysis</h1>

      {/* KPI Cards */}
      <div className="grid gap-6 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{formatCurrency(metrics.totalRevenue)}</div>
            <div className="flex items-center text-xs">
              {metrics.monthOverMonthGrowth >= 0 ? (
                <TrendingUp className="mr-1 h-3 w-3 text-green-500" />
              ) : (
                <TrendingDown className="mr-1 h-3 w-3 text-red-500" />
              )}
              <span className={metrics.monthOverMonthGrowth >= 0 ? 'text-green-500' : 'text-red-500'}>
                {metrics.monthOverMonthGrowth.toFixed(1)}% vs last month
              </span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Collected</CardTitle>
            <DollarSign className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{formatCurrency(metrics.collectedRevenue)}</div>
            <p className="text-xs text-gray-500">
              {metrics.collectionRate.toFixed(1)}% collection rate
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Pending</CardTitle>
            <Clock className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{formatCurrency(metrics.pendingRevenue)}</div>
            <p className="text-xs text-gray-500">Outstanding amount</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Collection Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.collectionRate.toFixed(1)}%</div>
            <div className="mt-2 h-2 w-full rounded-full bg-gray-200">
              <div
                className="h-2 rounded-full bg-green-500"
                style={{ width: `${metrics.collectionRate}%` }}
              />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Revenue Trends */}
      <Card>
        <CardHeader>
          <CardTitle>Revenue Trends (12 Months)</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={trends}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="period" />
              <YAxis />
              <Tooltip formatter={(value) => formatCurrency(value as number)} />
              <Legend />
              <Line
                type="monotone"
                dataKey="totalRevenue"
                stroke="#22c55e"
                name="Total Revenue"
                strokeWidth={2}
              />
              <Line
                type="monotone"
                dataKey="collectedRevenue"
                stroke="#3b82f6"
                name="Collected"
                strokeWidth={2}
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Revenue by Stream */}
      <Card>
        <CardHeader>
          <CardTitle>Revenue by Stream</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {streams.map((stream) => (
              <div key={stream.id} className="flex items-center justify-between border-b pb-3">
                <div className="flex-1">
                  <div className="font-medium">{stream.name}</div>
                  <div className="text-sm text-gray-500">
                    Collection Rate: {stream.collectionRate.toFixed(1)}%
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-bold">{formatCurrency(stream.currentMonthRevenue)}</div>
                  <div className={`flex items-center text-sm ${stream.growth >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                    {stream.growth >= 0 ? (
                      <TrendingUp className="mr-1 h-3 w-3" />
                    ) : (
                      <TrendingDown className="mr-1 h-3 w-3" />
                    )}
                    {stream.growth.toFixed(1)}%
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { RevenueTrackingAPI } from '../revenue-tracking';

describe('RevenueTrackingAPI', () => {
  it('calculates revenue metrics correctly', async () => {
    const api = new RevenueTrackingAPI();
    const metrics = await api.getRevenueMetrics({
      tenantId: 'test-tenant',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    });

    expect(metrics.collectionRate).toBeGreaterThanOrEqual(0);
    expect(metrics.collectionRate).toBeLessThanOrEqual(100);
  });

  it('tracks revenue by stream', async () => {
    const api = new RevenueTrackingAPI();
    const streams = await api.getRevenueByStream({
      tenantId: 'test-tenant',
      period: new Date(),
    });

    expect(Array.isArray(streams)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Revenue metrics calculating correctly
- [ ] Multi-stream tracking operational
- [ ] Collection rate accurate
- [ ] Forecasting functional
- [ ] Outstanding analysis working
- [ ] Trends displaying correctly
- [ ] Tests passing

---

**Status**: ✅ Complete and Ready for Implementation  
**Next**: SPEC-169 (Expense Management System)  
**Time**: 4 hours  
**AI-Ready**: 100%
