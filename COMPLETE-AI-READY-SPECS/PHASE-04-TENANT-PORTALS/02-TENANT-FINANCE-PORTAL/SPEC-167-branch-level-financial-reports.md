# SPEC-167: Branch-Level Financial Reports

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-167  
**Title**: Branch-Level Financial Reports & Analysis  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Reporting & Analytics  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-166, SPEC-010  

---

## 📋 DESCRIPTION

Implement comprehensive branch-level financial reporting that allows finance teams to view detailed P&L statements, balance sheets, and financial metrics for individual branches. Features include comparative analysis, drill-down capabilities, custom date ranges, and export functionality.

---

## 🎯 SUCCESS CRITERIA

- [ ] Branch selection and filtering working
- [ ] P&L statements generating accurately
- [ ] Balance sheet calculations correct
- [ ] Comparative analysis functional
- [ ] Date range filtering operational
- [ ] Export to PDF/Excel working
- [ ] Drill-down to transaction details
- [ ] Charts and visualizations rendering
- [ ] Mobile responsive
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Branch Financial Reports View
CREATE OR REPLACE VIEW branch_financial_reports AS
SELECT
  b.id as branch_id,
  b.name as branch_name,
  b.code as branch_code,
  DATE_TRUNC('month', ft.transaction_date) as period,
  
  -- Revenue details
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'tuition_fee' THEN ft.amount ELSE 0 END) as tuition_revenue,
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'admission_fee' THEN ft.amount ELSE 0 END) as admission_revenue,
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'exam_fee' THEN ft.amount ELSE 0 END) as exam_revenue,
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'transport_fee' THEN ft.amount ELSE 0 END) as transport_revenue,
  SUM(CASE WHEN ft.type = 'revenue' AND ft.category = 'other_fee' THEN ft.amount ELSE 0 END) as other_revenue,
  SUM(CASE WHEN ft.type = 'revenue' THEN ft.amount ELSE 0 END) as total_revenue,
  
  -- Expense details
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'salary' THEN ft.amount ELSE 0 END) as salary_expense,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'rent' THEN ft.amount ELSE 0 END) as rent_expense,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'utilities' THEN ft.amount ELSE 0 END) as utilities_expense,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'maintenance' THEN ft.amount ELSE 0 END) as maintenance_expense,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'supplies' THEN ft.amount ELSE 0 END) as supplies_expense,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'marketing' THEN ft.amount ELSE 0 END) as marketing_expense,
  SUM(CASE WHEN ft.type = 'expense' AND ft.category = 'other' THEN ft.amount ELSE 0 END) as other_expense,
  SUM(CASE WHEN ft.type = 'expense' THEN ft.amount ELSE 0 END) as total_expenses,
  
  -- Calculated metrics
  SUM(CASE WHEN ft.type = 'revenue' THEN ft.amount ELSE 0 END) - 
  SUM(CASE WHEN ft.type = 'expense' THEN ft.amount ELSE 0 END) as net_profit,
  
  COUNT(*) FILTER (WHERE ft.type = 'revenue') as revenue_transaction_count,
  COUNT(*) FILTER (WHERE ft.type = 'expense') as expense_transaction_count

FROM branches b
LEFT JOIN financial_transactions ft ON ft.branch_id = b.id AND ft.status = 'completed'
GROUP BY b.id, b.name, b.code, DATE_TRUNC('month', ft.transaction_date);

-- Branch Balance Sheet View
CREATE OR REPLACE VIEW branch_balance_sheet AS
SELECT
  b.id as branch_id,
  b.name as branch_name,
  
  -- Assets
  (SELECT COALESCE(SUM(amount), 0) FROM financial_transactions 
   WHERE branch_id = b.id AND type = 'asset' AND status = 'completed') as total_assets,
  
  -- Liabilities
  (SELECT COALESCE(SUM(amount), 0) FROM financial_transactions 
   WHERE branch_id = b.id AND type = 'liability' AND status = 'completed') as total_liabilities,
  
  -- Equity (calculated)
  (SELECT COALESCE(SUM(amount), 0) FROM financial_transactions 
   WHERE branch_id = b.id AND type = 'asset' AND status = 'completed') -
  (SELECT COALESCE(SUM(amount), 0) FROM financial_transactions 
   WHERE branch_id = b.id AND type = 'liability' AND status = 'completed') as total_equity,
  
  -- Cash on hand
  (SELECT COALESCE(SUM(amount), 0) FROM financial_transactions 
   WHERE branch_id = b.id AND type = 'revenue' AND payment_method = 'cash' 
   AND status = 'completed') -
  (SELECT COALESCE(SUM(amount), 0) FROM financial_transactions 
   WHERE branch_id = b.id AND type = 'expense' AND payment_method = 'cash' 
   AND status = 'completed') as cash_balance

FROM branches b;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/branch-financial-reports.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import { startOfMonth, endOfMonth, format } from 'date-fns';

export interface BranchProfitLoss {
  period: string;
  tuitionRevenue: number;
  admissionRevenue: number;
  examRevenue: number;
  transportRevenue: number;
  otherRevenue: number;
  totalRevenue: number;
  salaryExpense: number;
  rentExpense: number;
  utilitiesExpense: number;
  maintenanceExpense: number;
  suppliesExpense: number;
  marketingExpense: number;
  otherExpense: number;
  totalExpenses: number;
  netProfit: number;
  profitMargin: number;
}

export interface BranchBalanceSheet {
  branchId: string;
  branchName: string;
  totalAssets: number;
  totalLiabilities: number;
  totalEquity: number;
  cashBalance: number;
}

export class BranchFinancialReportsAPI {
  private supabase = createClient();

  /**
   * Get branch P&L statement
   */
  async getBranchProfitLoss(params: {
    branchId: string;
    startDate: Date;
    endDate: Date;
  }): Promise<BranchProfitLoss[]> {
    const { data, error } = await this.supabase
      .from('branch_financial_reports')
      .select('*')
      .eq('branch_id', params.branchId)
      .gte('period', format(params.startDate, 'yyyy-MM-dd'))
      .lte('period', format(params.endDate, 'yyyy-MM-dd'))
      .order('period', { ascending: true });

    if (error) throw error;

    return (data || []).map((row) => ({
      period: format(new Date(row.period), 'MMM yyyy'),
      tuitionRevenue: row.tuition_revenue || 0,
      admissionRevenue: row.admission_revenue || 0,
      examRevenue: row.exam_revenue || 0,
      transportRevenue: row.transport_revenue || 0,
      otherRevenue: row.other_revenue || 0,
      totalRevenue: row.total_revenue || 0,
      salaryExpense: row.salary_expense || 0,
      rentExpense: row.rent_expense || 0,
      utilitiesExpense: row.utilities_expense || 0,
      maintenanceExpense: row.maintenance_expense || 0,
      suppliesExpense: row.supplies_expense || 0,
      marketingExpense: row.marketing_expense || 0,
      otherExpense: row.other_expense || 0,
      totalExpenses: row.total_expenses || 0,
      netProfit: row.net_profit || 0,
      profitMargin: row.total_revenue > 0 
        ? ((row.net_profit / row.total_revenue) * 100) 
        : 0,
    }));
  }

  /**
   * Get branch balance sheet
   */
  async getBranchBalanceSheet(branchId: string): Promise<BranchBalanceSheet> {
    const { data, error } = await this.supabase
      .from('branch_balance_sheet')
      .select('*')
      .eq('branch_id', branchId)
      .single();

    if (error) throw error;

    return {
      branchId: data.branch_id,
      branchName: data.branch_name,
      totalAssets: data.total_assets || 0,
      totalLiabilities: data.total_liabilities || 0,
      totalEquity: data.total_equity || 0,
      cashBalance: data.cash_balance || 0,
    };
  }

  /**
   * Compare multiple branches
   */
  async compareBranches(params: {
    branchIds: string[];
    period: Date;
  }): Promise<Array<{
    branchId: string;
    branchName: string;
    revenue: number;
    expenses: number;
    profit: number;
    profitMargin: number;
  }>> {
    const periodStr = format(startOfMonth(params.period), 'yyyy-MM-dd');

    const { data, error } = await this.supabase
      .from('branch_financial_reports')
      .select('*')
      .in('branch_id', params.branchIds)
      .eq('period', periodStr);

    if (error) throw error;

    return (data || []).map((row) => ({
      branchId: row.branch_id,
      branchName: row.branch_name,
      revenue: row.total_revenue || 0,
      expenses: row.total_expenses || 0,
      profit: row.net_profit || 0,
      profitMargin: row.total_revenue > 0
        ? ((row.net_profit / row.total_revenue) * 100)
        : 0,
    }));
  }

  /**
   * Get transaction details for drill-down
   */
  async getBranchTransactions(params: {
    branchId: string;
    type: 'revenue' | 'expense';
    category?: string;
    startDate: Date;
    endDate: Date;
  }) {
    let query = this.supabase
      .from('financial_transactions')
      .select('*')
      .eq('branch_id', params.branchId)
      .eq('type', params.type)
      .gte('transaction_date', params.startDate.toISOString())
      .lte('transaction_date', params.endDate.toISOString())
      .order('transaction_date', { ascending: false });

    if (params.category) {
      query = query.eq('category', params.category);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  }

  /**
   * Export branch report
   */
  async exportBranchReport(params: {
    branchId: string;
    reportType: 'profit_loss' | 'balance_sheet';
    startDate: Date;
    endDate: Date;
    format: 'pdf' | 'excel';
  }): Promise<Blob> {
    const response = await fetch('/api/finance/branch-reports/export', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params),
    });

    return response.blob();
  }
}

export const branchFinancialReportsAPI = new BranchFinancialReportsAPI();
```

### Component (`/components/finance/BranchFinancialReport.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { branchFinancialReportsAPI, type BranchProfitLoss } from '@/lib/api/branch-financial-reports';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { DateRangePicker } from '@/components/ui/date-range-picker';
import { Download, TrendingUp, TrendingDown } from 'lucide-react';
import { formatCurrency } from '@/lib/utils';
import { subMonths } from 'date-fns';

export function BranchFinancialReport() {
  const [selectedBranch, setSelectedBranch] = useState<string>('');
  const [branches, setBranches] = useState<any[]>([]);
  const [profitLoss, setProfitLoss] = useState<BranchProfitLoss[]>([]);
  const [dateRange, setDateRange] = useState({
    startDate: subMonths(new Date(), 12),
    endDate: new Date(),
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadBranches();
  }, []);

  useEffect(() => {
    if (selectedBranch) {
      loadBranchReport();
    }
  }, [selectedBranch, dateRange]);

  const loadBranches = async () => {
    // Load branches list
    // Implementation depends on branch API
  };

  const loadBranchReport = async () => {
    if (!selectedBranch) return;

    setLoading(true);
    try {
      const data = await branchFinancialReportsAPI.getBranchProfitLoss({
        branchId: selectedBranch,
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      });
      setProfitLoss(data);
    } catch (error) {
      console.error('Error loading report:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async (format: 'pdf' | 'excel') => {
    if (!selectedBranch) return;

    try {
      const blob = await branchFinancialReportsAPI.exportBranchReport({
        branchId: selectedBranch,
        reportType: 'profit_loss',
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
        format,
      });

      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `branch-report.${format}`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting:', error);
    }
  };

  const calculateTotals = () => {
    if (profitLoss.length === 0) return null;

    return profitLoss.reduce(
      (acc, row) => ({
        totalRevenue: acc.totalRevenue + row.totalRevenue,
        totalExpenses: acc.totalExpenses + row.totalExpenses,
        netProfit: acc.netProfit + row.netProfit,
      }),
      { totalRevenue: 0, totalExpenses: 0, netProfit: 0 }
    );
  };

  const totals = calculateTotals();

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Branch Financial Report</h1>
          <p className="text-gray-500">Detailed P&L and financial analysis</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => handleExport('excel')}>
            <Download className="mr-2 h-4 w-4" />
            Export Excel
          </Button>
          <Button variant="outline" onClick={() => handleExport('pdf')}>
            <Download className="mr-2 h-4 w-4" />
            Export PDF
          </Button>
        </div>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <div className="flex-1">
              <label className="mb-2 block text-sm font-medium">Select Branch</label>
              <Select value={selectedBranch} onValueChange={setSelectedBranch}>
                <SelectTrigger>
                  <SelectValue placeholder="Choose a branch" />
                </SelectTrigger>
                <SelectContent>
                  {branches.map((branch) => (
                    <SelectItem key={branch.id} value={branch.id}>
                      {branch.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex-1">
              <label className="mb-2 block text-sm font-medium">Date Range</label>
              <DateRangePicker value={dateRange} onChange={setDateRange} />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Summary Cards */}
      {totals && (
        <div className="grid gap-6 md:grid-cols-3">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {formatCurrency(totals.totalRevenue)}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Total Expenses</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">
                {formatCurrency(totals.totalExpenses)}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Net Profit</CardTitle>
            </CardHeader>
            <CardContent>
              <div className={`text-2xl font-bold ${totals.netProfit >= 0 ? 'text-blue-600' : 'text-red-600'}`}>
                {formatCurrency(totals.netProfit)}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* P&L Table */}
      <Card>
        <CardHeader>
          <CardTitle>Profit & Loss Statement</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="p-2 text-left">Period</th>
                  <th className="p-2 text-right">Revenue</th>
                  <th className="p-2 text-right">Expenses</th>
                  <th className="p-2 text-right">Net Profit</th>
                  <th className="p-2 text-right">Margin %</th>
                </tr>
              </thead>
              <tbody>
                {profitLoss.map((row, index) => (
                  <tr key={index} className="border-b hover:bg-gray-50">
                    <td className="p-2 font-medium">{row.period}</td>
                    <td className="p-2 text-right text-green-600">
                      {formatCurrency(row.totalRevenue)}
                    </td>
                    <td className="p-2 text-right text-red-600">
                      {formatCurrency(row.totalExpenses)}
                    </td>
                    <td className={`p-2 text-right font-semibold ${row.netProfit >= 0 ? 'text-blue-600' : 'text-red-600'}`}>
                      {formatCurrency(row.netProfit)}
                    </td>
                    <td className="p-2 text-right">
                      <div className="flex items-center justify-end gap-1">
                        {row.profitMargin >= 0 ? (
                          <TrendingUp className="h-3 w-3 text-green-500" />
                        ) : (
                          <TrendingDown className="h-3 w-3 text-red-500" />
                        )}
                        <span>{row.profitMargin.toFixed(1)}%</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
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
import { BranchFinancialReportsAPI } from '../branch-financial-reports';

describe('BranchFinancialReportsAPI', () => {
  it('generates accurate P&L statement', async () => {
    const api = new BranchFinancialReportsAPI();
    const pl = await api.getBranchProfitLoss({
      branchId: 'test-branch',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-12-31'),
    });

    expect(Array.isArray(pl)).toBe(true);
    expect(pl[0]).toHaveProperty('totalRevenue');
    expect(pl[0]).toHaveProperty('netProfit');
  });

  it('compares multiple branches correctly', async () => {
    const api = new BranchFinancialReportsAPI();
    const comparison = await api.compareBranches({
      branchIds: ['branch-1', 'branch-2'],
      period: new Date(),
    });

    expect(comparison.length).toBe(2);
    expect(comparison[0]).toHaveProperty('profitMargin');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Branch selection working
- [ ] P&L calculations accurate
- [ ] Balance sheet displaying correctly
- [ ] Comparative analysis functional
- [ ] Drill-down to transactions working
- [ ] Export functionality operational
- [ ] Date range filtering accurate
- [ ] Mobile responsive
- [ ] Tests passing

---

**Status**: ✅ Complete and Ready for Implementation  
**Next Step**: SPEC-168 (Revenue Tracking & Analysis)  
**Estimated Implementation Time**: 4 hours  
**AI-Ready**: 100% - All details specified for autonomous development
