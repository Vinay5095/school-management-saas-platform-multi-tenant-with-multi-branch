# SPEC-166: Consolidated Finance Dashboard

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-166  
**Title**: Consolidated Multi-Branch Finance Dashboard  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Dashboard & Analytics  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-010 (Core Tables), Phase 1 Database  

---

## 📋 DESCRIPTION

Implement a comprehensive consolidated finance dashboard that provides real-time financial overview across all branches of an organization. Features include KPI cards, revenue/expense trends, branch comparison charts, cash flow analysis, and budget tracking with drill-down capabilities.

---

## 🎯 SUCCESS CRITERIA

- [ ] Real-time financial KPIs displaying correctly
- [ ] Multi-branch data consolidation working
- [ ] Interactive charts rendering with accurate data
- [ ] Drill-down functionality operational
- [ ] Date range filtering working
- [ ] Branch comparison charts functional
- [ ] Export functionality operational
- [ ] Mobile responsive design
- [ ] Real-time updates via subscriptions
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

### Financial Summary Views

```sql
-- ==============================================
-- CONSOLIDATED FINANCIAL VIEWS
-- ==============================================

-- Consolidated Financial Summary (Materialized View)
CREATE MATERIALIZED VIEW IF NOT EXISTS consolidated_financial_summary AS
SELECT
  ft.tenant_id,
  DATE_TRUNC('month', ft.transaction_date) as period,
  
  -- Revenue metrics
  SUM(CASE WHEN ft.type = 'revenue' THEN ft.amount ELSE 0 END) as total_revenue,
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'tuition_fee' THEN ft.amount ELSE 0 END) as tuition_revenue,
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'other_fee' THEN ft.amount ELSE 0 END) as other_revenue,
  
  -- Expense metrics
  SUM(CASE WHEN ft.type = 'expense' THEN ft.amount ELSE 0 END) as total_expenses,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'salary' THEN ft.amount ELSE 0 END) as salary_expenses,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'operational' THEN ft.amount ELSE 0 END) as operational_expenses,
  
  -- Net profit
  SUM(CASE WHEN ft.type = 'revenue' THEN ft.amount ELSE 0 END) - 
  SUM(CASE WHEN ft.type = 'expense' THEN ft.amount ELSE 0 END) as net_profit,
  
  -- Transaction counts
  COUNT(*) FILTER (WHERE ft.type = 'revenue') as revenue_transaction_count,
  COUNT(*) FILTER (WHERE ft.type = 'expense') as expense_transaction_count
  
FROM financial_transactions ft
WHERE ft.status = 'completed'
GROUP BY ft.tenant_id, DATE_TRUNC('month', ft.transaction_date);

CREATE UNIQUE INDEX ON consolidated_financial_summary(tenant_id, period);

-- Branch Financial Summary
CREATE MATERIALIZED VIEW IF NOT EXISTS branch_financial_summary AS
SELECT
  ft.tenant_id,
  ft.branch_id,
  b.name as branch_name,
  DATE_TRUNC('month', ft.transaction_date) as period,
  
  SUM(CASE WHEN ft.type = 'revenue' THEN ft.amount ELSE 0 END) as revenue,
  SUM(CASE WHEN ft.type = 'expense' THEN ft.amount ELSE 0 END) as expenses,
  SUM(CASE WHEN ft.type = 'revenue' THEN ft.amount ELSE 0 END) - 
  SUM(CASE WHEN ft.type = 'expense' THEN ft.amount ELSE 0 END) as profit
  
FROM financial_transactions ft
JOIN branches b ON b.id = ft.branch_id
WHERE ft.status = 'completed'
GROUP BY ft.tenant_id, ft.branch_id, b.name, DATE_TRUNC('month', ft.transaction_date);

CREATE INDEX ON branch_financial_summary(tenant_id, period);
CREATE INDEX ON branch_financial_summary(branch_id, period);

-- Financial KPIs (Real-time View)
CREATE OR REPLACE VIEW financial_kpis AS
SELECT
  tenant_id,
  
  -- Current month metrics
  (SELECT SUM(amount) FROM financial_transactions 
   WHERE type = 'revenue' 
   AND status = 'completed'
   AND transaction_date >= DATE_TRUNC('month', CURRENT_DATE)
   AND tenant_id = ft.tenant_id) as current_month_revenue,
   
  (SELECT SUM(amount) FROM financial_transactions 
   WHERE type = 'expense' 
   AND status = 'completed'
   AND transaction_date >= DATE_TRUNC('month', CURRENT_DATE)
   AND tenant_id = ft.tenant_id) as current_month_expenses,
   
  -- Year to date metrics
  (SELECT SUM(amount) FROM financial_transactions 
   WHERE type = 'revenue' 
   AND status = 'completed'
   AND transaction_date >= DATE_TRUNC('year', CURRENT_DATE)
   AND tenant_id = ft.tenant_id) as ytd_revenue,
   
  (SELECT SUM(amount) FROM financial_transactions 
   WHERE type = 'expense' 
   AND status = 'completed'
   AND transaction_date >= DATE_TRUNC('year', CURRENT_DATE)
   AND tenant_id = ft.tenant_id) as ytd_expenses,
   
  -- Outstanding amounts
  (SELECT SUM(amount) FROM financial_transactions 
   WHERE type = 'revenue' 
   AND status = 'pending'
   AND tenant_id = ft.tenant_id) as outstanding_receivables,
   
  (SELECT SUM(amount) FROM financial_transactions 
   WHERE type = 'expense' 
   AND status = 'pending'
   AND tenant_id = ft.tenant_id) as outstanding_payables

FROM financial_transactions ft
GROUP BY tenant_id;

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION refresh_financial_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY consolidated_financial_summary;
  REFRESH MATERIALIZED VIEW CONCURRENTLY branch_financial_summary;
END;
$$ LANGUAGE plpgsql;

-- Trigger to refresh views (can be called via cron or after transactions)
CREATE OR REPLACE FUNCTION trigger_refresh_financial_views()
RETURNS TRIGGER AS $$
BEGIN
  -- Queue refresh job (implement with background job system)
  PERFORM refresh_financial_views();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

---

## 💻 IMPLEMENTATION

### 1. Finance Dashboard API (`/lib/api/finance-dashboard.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import { startOfMonth, endOfMonth, subMonths, format } from 'date-fns';

export interface FinancialKPIs {
  currentMonthRevenue: number;
  currentMonthExpenses: number;
  currentMonthProfit: number;
  ytdRevenue: number;
  ytdExpenses: number;
  ytdProfit: number;
  outstandingReceivables: number;
  outstandingPayables: number;
  profitMargin: number;
  revenueGrowth: number;
}

export interface BranchFinancial {
  branchId: string;
  branchName: string;
  revenue: number;
  expenses: number;
  profit: number;
  profitMargin: number;
}

export class FinanceDashboardAPI {
  private supabase = createClient();

  /**
   * Get consolidated financial KPIs
   */
  async getFinancialKPIs(tenantId: string): Promise<FinancialKPIs> {
    const { data, error } = await this.supabase
      .from('financial_kpis')
      .select('*')
      .eq('tenant_id', tenantId)
      .single();

    if (error) throw error;

    const currentMonthProfit = (data.current_month_revenue || 0) - (data.current_month_expenses || 0);
    const ytdProfit = (data.ytd_revenue || 0) - (data.ytd_expenses || 0);
    const profitMargin = data.ytd_revenue > 0 
      ? (ytdProfit / data.ytd_revenue) * 100 
      : 0;

    // Calculate revenue growth (current month vs last month)
    const lastMonth = subMonths(new Date(), 1);
    const { data: lastMonthData } = await this.supabase
      .from('consolidated_financial_summary')
      .select('total_revenue')
      .eq('tenant_id', tenantId)
      .eq('period', format(startOfMonth(lastMonth), 'yyyy-MM-dd'))
      .single();

    const lastMonthRevenue = lastMonthData?.total_revenue || 0;
    const revenueGrowth = lastMonthRevenue > 0
      ? ((data.current_month_revenue - lastMonthRevenue) / lastMonthRevenue) * 100
      : 0;

    return {
      currentMonthRevenue: data.current_month_revenue || 0,
      currentMonthExpenses: data.current_month_expenses || 0,
      currentMonthProfit,
      ytdRevenue: data.ytd_revenue || 0,
      ytdExpenses: data.ytd_expenses || 0,
      ytdProfit,
      outstandingReceivables: data.outstanding_receivables || 0,
      outstandingPayables: data.outstanding_payables || 0,
      profitMargin,
      revenueGrowth,
    };
  }

  /**
   * Get revenue and expense trends
   */
  async getFinancialTrends(params: {
    tenantId: string;
    months?: number;
  }): Promise<Array<{
    period: string;
    revenue: number;
    expenses: number;
    profit: number;
  }>> {
    const months = params.months || 12;
    const startDate = subMonths(new Date(), months);

    const { data, error } = await this.supabase
      .from('consolidated_financial_summary')
      .select('period, total_revenue, total_expenses, net_profit')
      .eq('tenant_id', params.tenantId)
      .gte('period', format(startDate, 'yyyy-MM-dd'))
      .order('period', { ascending: true });

    if (error) throw error;

    return data.map((row) => ({
      period: format(new Date(row.period), 'MMM yyyy'),
      revenue: row.total_revenue || 0,
      expenses: row.total_expenses || 0,
      profit: row.net_profit || 0,
    }));
  }

  /**
   * Get branch-wise financial comparison
   */
  async getBranchComparison(params: {
    tenantId: string;
    period?: Date;
  }): Promise<BranchFinancial[]> {
    const period = params.period || new Date();
    const periodStart = format(startOfMonth(period), 'yyyy-MM-dd');

    const { data, error } = await this.supabase
      .from('branch_financial_summary')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('period', periodStart)
      .order('profit', { ascending: false });

    if (error) throw error;

    return data.map((row) => ({
      branchId: row.branch_id,
      branchName: row.branch_name,
      revenue: row.revenue || 0,
      expenses: row.expenses || 0,
      profit: row.profit || 0,
      profitMargin: row.revenue > 0 ? (row.profit / row.revenue) * 100 : 0,
    }));
  }

  /**
   * Get revenue breakdown by category
   */
  async getRevenueBreakdown(params: {
    tenantId: string;
    startDate: Date;
    endDate: Date;
  }): Promise<Array<{ category: string; amount: number; percentage: number }>> {
    const { data, error } = await this.supabase
      .from('financial_transactions')
      .select('category, amount')
      .eq('tenant_id', params.tenantId)
      .eq('type', 'revenue')
      .eq('status', 'completed')
      .gte('transaction_date', params.startDate.toISOString())
      .lte('transaction_date', params.endDate.toISOString());

    if (error) throw error;

    // Group by category
    const breakdown = data.reduce((acc, transaction) => {
      const category = transaction.category || 'Other';
      acc[category] = (acc[category] || 0) + transaction.amount;
      return acc;
    }, {} as Record<string, number>);

    const total = Object.values(breakdown).reduce((sum, amt) => sum + amt, 0);

    return Object.entries(breakdown).map(([category, amount]) => ({
      category,
      amount,
      percentage: total > 0 ? (amount / total) * 100 : 0,
    }));
  }

  /**
   * Get expense breakdown by category
   */
  async getExpenseBreakdown(params: {
    tenantId: string;
    startDate: Date;
    endDate: Date;
  }): Promise<Array<{ category: string; amount: number; percentage: number }>> {
    const { data, error } = await this.supabase
      .from('financial_transactions')
      .select('category, amount')
      .eq('tenant_id', params.tenantId)
      .eq('type', 'expense')
      .eq('status', 'completed')
      .gte('transaction_date', params.startDate.toISOString())
      .lte('transaction_date', params.endDate.toISOString());

    if (error) throw error;

    const breakdown = data.reduce((acc, transaction) => {
      const category = transaction.category || 'Other';
      acc[category] = (acc[category] || 0) + transaction.amount;
      return acc;
    }, {} as Record<string, number>);

    const total = Object.values(breakdown).reduce((sum, amt) => sum + amt, 0);

    return Object.entries(breakdown).map(([category, amount]) => ({
      category,
      amount,
      percentage: total > 0 ? (amount / total) * 100 : 0,
    }));
  }

  /**
   * Get cash flow summary
   */
  async getCashFlowSummary(params: {
    tenantId: string;
    months?: number;
  }): Promise<Array<{
    period: string;
    inflow: number;
    outflow: number;
    netCashFlow: number;
  }>> {
    const months = params.months || 6;
    const startDate = subMonths(new Date(), months);

    const { data, error } = await this.supabase
      .from('consolidated_financial_summary')
      .select('period, total_revenue, total_expenses')
      .eq('tenant_id', params.tenantId)
      .gte('period', format(startDate, 'yyyy-MM-dd'))
      .order('period', { ascending: true });

    if (error) throw error;

    return data.map((row) => ({
      period: format(new Date(row.period), 'MMM yyyy'),
      inflow: row.total_revenue || 0,
      outflow: row.total_expenses || 0,
      netCashFlow: (row.total_revenue || 0) - (row.total_expenses || 0),
    }));
  }

  /**
   * Subscribe to real-time financial updates
   */
  subscribeToFinancialUpdates(
    tenantId: string,
    callback: () => void
  ) {
    const channel = this.supabase
      .channel(`financial-updates:${tenantId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'financial_transactions',
          filter: `tenant_id=eq.${tenantId}`,
        },
        () => {
          callback();
        }
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }

  /**
   * Export dashboard data
   */
  async exportDashboardData(params: {
    tenantId: string;
    format: 'csv' | 'pdf' | 'excel';
  }): Promise<Blob> {
    const response = await fetch('/api/finance/dashboard/export', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params),
    });

    return response.blob();
  }
}

export const financeDashboardAPI = new FinanceDashboardAPI();
```

### 2. Dashboard Component (`/components/finance/ConsolidatedDashboard.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { financeDashboardAPI, type FinancialKPIs } from '@/lib/api/finance-dashboard';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { DateRangePicker } from '@/components/ui/date-range-picker';
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Receipt,
  PiggyBank,
  FileText,
  Download,
  RefreshCw,
} from 'lucide-react';
import { formatCurrency } from '@/lib/utils';
import { subMonths } from 'date-fns';

// Chart components
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#FF6B9D'];

export function ConsolidatedDashboard({ tenantId }: { tenantId: string }) {
  const [kpis, setKpis] = useState<FinancialKPIs | null>(null);
  const [trends, setTrends] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [revenueBreakdown, setRevenueBreakdown] = useState<any[]>([]);
  const [expenseBreakdown, setExpenseBreakdown] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({
    startDate: subMonths(new Date(), 12),
    endDate: new Date(),
  });

  useEffect(() => {
    loadDashboardData();

    // Subscribe to real-time updates
    const unsubscribe = financeDashboardAPI.subscribeToFinancialUpdates(
      tenantId,
      () => {
        loadDashboardData();
      }
    );

    return () => {
      unsubscribe();
    };
  }, [tenantId, dateRange]);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      const [kpisData, trendsData, branchesData, revenueData, expenseData] =
        await Promise.all([
          financeDashboardAPI.getFinancialKPIs(tenantId),
          financeDashboardAPI.getFinancialTrends({ tenantId, months: 12 }),
          financeDashboardAPI.getBranchComparison({ tenantId }),
          financeDashboardAPI.getRevenueBreakdown({
            tenantId,
            startDate: dateRange.startDate,
            endDate: dateRange.endDate,
          }),
          financeDashboardAPI.getExpenseBreakdown({
            tenantId,
            startDate: dateRange.startDate,
            endDate: dateRange.endDate,
          }),
        ]);

      setKpis(kpisData);
      setTrends(trendsData);
      setBranches(branchesData);
      setRevenueBreakdown(revenueData);
      setExpenseBreakdown(expenseData);
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async (format: 'csv' | 'pdf' | 'excel') => {
    try {
      const blob = await financeDashboardAPI.exportDashboardData({
        tenantId,
        format,
      });

      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `financial-dashboard.${format}`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting:', error);
    }
  };

  if (loading || !kpis) {
    return <div>Loading dashboard...</div>;
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Financial Dashboard</h1>
          <p className="text-gray-500">Consolidated view across all branches</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => loadDashboardData()}>
            <RefreshCw className="mr-2 h-4 w-4" />
            Refresh
          </Button>
          <Button variant="outline" size="sm" onClick={() => handleExport('excel')}>
            <Download className="mr-2 h-4 w-4" />
            Export
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {/* Current Month Revenue */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Month Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(kpis.currentMonthRevenue)}
            </div>
            <div className="flex items-center text-xs text-gray-500">
              {kpis.revenueGrowth >= 0 ? (
                <>
                  <TrendingUp className="mr-1 h-3 w-3 text-green-500" />
                  <span className="text-green-500">+{kpis.revenueGrowth.toFixed(1)}%</span>
                </>
              ) : (
                <>
                  <TrendingDown className="mr-1 h-3 w-3 text-red-500" />
                  <span className="text-red-500">{kpis.revenueGrowth.toFixed(1)}%</span>
                </>
              )}
              <span className="ml-1">vs last month</span>
            </div>
          </CardContent>
        </Card>

        {/* Current Month Expenses */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Month Expenses</CardTitle>
            <Receipt className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(kpis.currentMonthExpenses)}
            </div>
            <p className="text-xs text-gray-500">
              Profit: {formatCurrency(kpis.currentMonthProfit)}
            </p>
          </CardContent>
        </Card>

        {/* YTD Profit */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Year to Date Profit</CardTitle>
            <PiggyBank className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(kpis.ytdProfit)}
            </div>
            <p className="text-xs text-gray-500">
              Profit Margin: {kpis.profitMargin.toFixed(1)}%
            </p>
          </CardContent>
        </Card>

        {/* Outstanding */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Outstanding Amounts</CardTitle>
            <FileText className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Receivables:</span>
                <span className="font-semibold">
                  {formatCurrency(kpis.outstandingReceivables)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Payables:</span>
                <span className="font-semibold">
                  {formatCurrency(kpis.outstandingPayables)}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row 1 */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Revenue & Expense Trends */}
        <Card>
          <CardHeader>
            <CardTitle>Revenue & Expense Trends</CardTitle>
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
                  dataKey="revenue"
                  stroke="#22c55e"
                  name="Revenue"
                  strokeWidth={2}
                />
                <Line
                  type="monotone"
                  dataKey="expenses"
                  stroke="#ef4444"
                  name="Expenses"
                  strokeWidth={2}
                />
                <Line
                  type="monotone"
                  dataKey="profit"
                  stroke="#3b82f6"
                  name="Profit"
                  strokeWidth={2}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Branch Comparison */}
        <Card>
          <CardHeader>
            <CardTitle>Branch Performance Comparison</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={branches}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="branchName" />
                <YAxis />
                <Tooltip formatter={(value) => formatCurrency(value as number)} />
                <Legend />
                <Bar dataKey="revenue" fill="#22c55e" name="Revenue" />
                <Bar dataKey="expenses" fill="#ef4444" name="Expenses" />
                <Bar dataKey="profit" fill="#3b82f6" name="Profit" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row 2 */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Revenue Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Revenue Breakdown by Category</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={revenueBreakdown}
                  dataKey="amount"
                  nameKey="category"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={(entry) => `${entry.category}: ${entry.percentage.toFixed(1)}%`}
                >
                  {revenueBreakdown.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => formatCurrency(value as number)} />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Expense Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Expense Breakdown by Category</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={expenseBreakdown}
                  dataKey="amount"
                  nameKey="category"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={(entry) => `${entry.category}: ${entry.percentage.toFixed(1)}%`}
                >
                  {expenseBreakdown.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => formatCurrency(value as number)} />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { FinanceDashboardAPI } from '../finance-dashboard';

describe('FinanceDashboardAPI', () => {
  it('calculates KPIs correctly', async () => {
    const api = new FinanceDashboardAPI();
    const kpis = await api.getFinancialKPIs('test-tenant-id');
    
    expect(kpis).toHaveProperty('currentMonthRevenue');
    expect(kpis).toHaveProperty('ytdProfit');
    expect(kpis.profitMargin).toBeGreaterThanOrEqual(0);
  });

  it('consolidates multi-branch data correctly', async () => {
    const api = new FinanceDashboardAPI();
    const branches = await api.getBranchComparison({
      tenantId: 'test-tenant-id',
    });
    
    expect(Array.isArray(branches)).toBe(true);
    expect(branches[0]).toHaveProperty('branchName');
    expect(branches[0]).toHaveProperty('profit');
  });

  it('generates financial trends', async () => {
    const api = new FinanceDashboardAPI();
    const trends = await api.getFinancialTrends({
      tenantId: 'test-tenant-id',
      months: 6,
    });
    
    expect(trends.length).toBeLessThanOrEqual(6);
    expect(trends[0]).toHaveProperty('period');
    expect(trends[0]).toHaveProperty('revenue');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] KPI cards displaying real-time data
- [ ] All charts rendering correctly
- [ ] Multi-branch consolidation accurate
- [ ] Date range filtering working
- [ ] Real-time updates via subscriptions
- [ ] Export functionality operational
- [ ] Drill-down to branch details working
- [ ] Mobile responsive
- [ ] Performance optimized for large datasets
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ Complete and Ready for Implementation  
**Next Step**: SPEC-167 (Branch-Level Financial Reports)  
**Estimated Implementation Time**: 5 hours  
**AI-Ready**: 100% - All details specified for autonomous development
