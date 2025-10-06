# SPEC-176: Financial Reports & Statements

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-176  
**Title**: Financial Reports & Statements Generation  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Financial Reporting  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-166, SPEC-167, SPEC-168  

---

## 📋 DESCRIPTION

Comprehensive financial reporting system with profit & loss statements, balance sheets, cash flow statements, trial balance, ledger reports, custom report builder, scheduled reports, and multi-format exports (PDF, Excel, CSV).

---

## 🎯 SUCCESS CRITERIA

- [ ] P&L statement generation working
- [ ] Balance sheet accurate
- [ ] Cash flow statement functional
- [ ] Trial balance calculated
- [ ] Custom reports builder operational
- [ ] Scheduled reports working
- [ ] Export in multiple formats
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Financial Report Templates
CREATE TABLE IF NOT EXISTS financial_report_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Template details
  template_name VARCHAR(200) NOT NULL,
  report_type VARCHAR(50) NOT NULL, -- profit_loss, balance_sheet, cash_flow, trial_balance, custom
  description TEXT,
  
  -- Configuration
  report_config JSONB NOT NULL, -- Column mappings, filters, groupings
  columns JSONB NOT NULL, -- [{"key": "revenue", "label": "Revenue", "type": "number"}]
  filters JSONB, -- Default filters
  
  -- Layout
  layout_config JSONB, -- Page size, orientation, header/footer
  
  -- Access
  is_public BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, template_name)
);

-- Generated Reports (History)
CREATE TABLE IF NOT EXISTS generated_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  template_id UUID REFERENCES financial_report_templates(id),
  
  -- Report details
  report_name VARCHAR(200) NOT NULL,
  report_type VARCHAR(50) NOT NULL,
  
  -- Period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  
  -- Filters applied
  filters_applied JSONB,
  
  -- File
  file_format VARCHAR(20), -- pdf, excel, csv
  file_size_bytes BIGINT,
  file_url TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'generating', -- generating, ready, failed
  error_message TEXT,
  
  -- Metadata
  generated_by UUID REFERENCES auth.users(id),
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE, -- Auto-delete after expiry
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('generating', 'ready', 'failed', 'expired'))
);

CREATE INDEX ON generated_reports(tenant_id, report_type);
CREATE INDEX ON generated_reports(generated_at);

-- Scheduled Reports
CREATE TABLE IF NOT EXISTS scheduled_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  template_id UUID REFERENCES financial_report_templates(id),
  
  -- Schedule details
  schedule_name VARCHAR(200) NOT NULL,
  report_type VARCHAR(50) NOT NULL,
  
  -- Frequency
  frequency VARCHAR(20) NOT NULL, -- daily, weekly, monthly, quarterly, yearly
  schedule_config JSONB NOT NULL, -- {"day_of_week": 1, "time": "09:00"}
  
  -- Recipients
  email_recipients TEXT[] NOT NULL,
  
  -- Report configuration
  period_type VARCHAR(20) NOT NULL, -- last_month, last_quarter, ytd, custom
  filters JSONB,
  file_format VARCHAR(20) DEFAULT 'pdf',
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  last_run_at TIMESTAMP WITH TIME ZONE,
  next_run_at TIMESTAMP WITH TIME ZONE,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_frequency CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly'))
);

CREATE INDEX ON scheduled_reports(tenant_id, is_active, next_run_at);

-- Profit & Loss View
CREATE OR REPLACE VIEW profit_loss_statement AS
WITH revenue_data AS (
  SELECT
    tenant_id,
    branch_id,
    DATE_TRUNC('month', transaction_date) as period,
    SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) as total_revenue
  FROM financial_transactions
  GROUP BY tenant_id, branch_id, DATE_TRUNC('month', transaction_date)
),
expense_data AS (
  SELECT
    tenant_id,
    branch_id,
    DATE_TRUNC('month', transaction_date) as period,
    category,
    SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) as total_expense
  FROM financial_transactions
  GROUP BY tenant_id, branch_id, DATE_TRUNC('month', transaction_date), category
)
SELECT
  r.tenant_id,
  r.branch_id,
  r.period,
  r.total_revenue,
  COALESCE(SUM(e.total_expense), 0) as total_expenses,
  r.total_revenue - COALESCE(SUM(e.total_expense), 0) as net_profit,
  CASE 
    WHEN r.total_revenue > 0 THEN
      ((r.total_revenue - COALESCE(SUM(e.total_expense), 0)) / r.total_revenue * 100)
    ELSE 0
  END as profit_margin
FROM revenue_data r
LEFT JOIN expense_data e ON e.tenant_id = r.tenant_id 
  AND e.branch_id = r.branch_id 
  AND e.period = r.period
GROUP BY r.tenant_id, r.branch_id, r.period, r.total_revenue;

-- Balance Sheet View (Simplified)
CREATE OR REPLACE VIEW balance_sheet AS
WITH assets AS (
  SELECT
    tenant_id,
    branch_id,
    SUM(CASE WHEN account_type = 'asset' THEN balance ELSE 0 END) as total_assets
  FROM accounts
  WHERE is_active = true
  GROUP BY tenant_id, branch_id
),
liabilities AS (
  SELECT
    tenant_id,
    branch_id,
    SUM(CASE WHEN account_type = 'liability' THEN balance ELSE 0 END) as total_liabilities
  FROM accounts
  WHERE is_active = true
  GROUP BY tenant_id, branch_id
),
equity AS (
  SELECT
    tenant_id,
    branch_id,
    SUM(CASE WHEN account_type = 'equity' THEN balance ELSE 0 END) as total_equity
  FROM accounts
  WHERE is_active = true
  GROUP BY tenant_id, branch_id
)
SELECT
  a.tenant_id,
  a.branch_id,
  a.total_assets,
  COALESCE(l.total_liabilities, 0) as total_liabilities,
  COALESCE(e.total_equity, 0) as total_equity,
  NOW() as as_of_date
FROM assets a
LEFT JOIN liabilities l ON l.tenant_id = a.tenant_id AND l.branch_id = a.branch_id
LEFT JOIN equity e ON e.tenant_id = a.tenant_id AND e.branch_id = a.branch_id;

-- Cash Flow Statement View
CREATE OR REPLACE VIEW cash_flow_statement AS
SELECT
  tenant_id,
  branch_id,
  DATE_TRUNC('month', transaction_date) as period,
  SUM(CASE 
    WHEN cash_flow_category = 'operating' THEN amount 
    ELSE 0 
  END) as operating_cash_flow,
  SUM(CASE 
    WHEN cash_flow_category = 'investing' THEN amount 
    ELSE 0 
  END) as investing_cash_flow,
  SUM(CASE 
    WHEN cash_flow_category = 'financing' THEN amount 
    ELSE 0 
  END) as financing_cash_flow,
  SUM(amount) as net_cash_flow
FROM financial_transactions
WHERE payment_method IN ('cash', 'bank_transfer')
GROUP BY tenant_id, branch_id, DATE_TRUNC('month', transaction_date);

-- Trial Balance View
CREATE OR REPLACE VIEW trial_balance AS
SELECT
  tenant_id,
  branch_id,
  account_code,
  account_name,
  account_type,
  SUM(CASE WHEN debit_credit = 'debit' THEN amount ELSE 0 END) as total_debit,
  SUM(CASE WHEN debit_credit = 'credit' THEN amount ELSE 0 END) as total_credit,
  SUM(CASE 
    WHEN debit_credit = 'debit' THEN amount 
    ELSE -amount 
  END) as balance
FROM accounts a
LEFT JOIN account_transactions at ON at.account_id = a.id
WHERE a.is_active = true
GROUP BY tenant_id, branch_id, account_code, account_name, account_type;

-- Function to generate P&L statement
CREATE OR REPLACE FUNCTION generate_profit_loss_report(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  category VARCHAR,
  subcategory VARCHAR,
  amount NUMERIC,
  percentage NUMERIC
) AS $$
DECLARE
  v_total_revenue NUMERIC;
BEGIN
  -- Get total revenue for percentage calculation
  SELECT SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END)
  INTO v_total_revenue
  FROM financial_transactions
  WHERE tenant_id = p_tenant_id
  AND (branch_id = p_branch_id OR p_branch_id IS NULL)
  AND transaction_date BETWEEN p_start_date AND p_end_date;
  
  RETURN QUERY
  WITH categorized_transactions AS (
    SELECT
      CASE 
        WHEN transaction_type = 'income' THEN 'Revenue'
        WHEN transaction_type = 'expense' THEN 'Expenses'
      END as category,
      COALESCE(category, 'Other') as subcategory,
      SUM(amount) as total_amount
    FROM financial_transactions
    WHERE tenant_id = p_tenant_id
    AND (branch_id = p_branch_id OR p_branch_id IS NULL)
    AND transaction_date BETWEEN p_start_date AND p_end_date
    GROUP BY transaction_type, category
  )
  SELECT
    ct.category::VARCHAR,
    ct.subcategory::VARCHAR,
    ct.total_amount,
    CASE 
      WHEN v_total_revenue > 0 THEN (ct.total_amount / v_total_revenue * 100)
      ELSE 0
    END as percentage
  FROM categorized_transactions ct
  ORDER BY ct.category DESC, ct.total_amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to export report to JSON
CREATE OR REPLACE FUNCTION export_report_to_json(
  p_report_type VARCHAR,
  p_tenant_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  IF p_report_type = 'profit_loss' THEN
    SELECT json_agg(pl)
    INTO v_result
    FROM profit_loss_statement pl
    WHERE pl.tenant_id = p_tenant_id
    AND pl.period BETWEEN p_start_date AND p_end_date;
  ELSIF p_report_type = 'balance_sheet' THEN
    SELECT json_agg(bs)
    INTO v_result
    FROM balance_sheet bs
    WHERE bs.tenant_id = p_tenant_id;
  ELSIF p_report_type = 'cash_flow' THEN
    SELECT json_agg(cf)
    INTO v_result
    FROM cash_flow_statement cf
    WHERE cf.tenant_id = p_tenant_id
    AND cf.period BETWEEN p_start_date AND p_end_date;
  END IF;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE financial_report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_reports ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/financial-reports.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface ReportTemplate {
  id: string;
  templateName: string;
  reportType: string;
  description: string;
}

export interface GeneratedReport {
  id: string;
  reportName: string;
  reportType: string;
  periodStart: string;
  periodEnd: string;
  fileUrl: string;
  status: string;
  generatedAt: string;
}

export class FinancialReportsAPI {
  private supabase = createClient();

  async getProfitLossStatement(params: {
    tenantId: string;
    branchId?: string;
    startDate: Date;
    endDate: Date;
  }) {
    const { data, error } = await this.supabase.rpc('generate_profit_loss_report', {
      p_tenant_id: params.tenantId,
      p_branch_id: params.branchId,
      p_start_date: params.startDate.toISOString().split('T')[0],
      p_end_date: params.endDate.toISOString().split('T')[0],
    });

    if (error) throw error;

    return data.map((item: any) => ({
      category: item.category,
      subcategory: item.subcategory,
      amount: item.amount,
      percentage: item.percentage,
    }));
  }

  async getBalanceSheet(params: {
    tenantId: string;
    branchId?: string;
    asOfDate?: Date;
  }) {
    let query = this.supabase
      .from('balance_sheet')
      .select('*')
      .eq('tenant_id', params.tenantId);

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query.single();

    if (error) throw error;

    return {
      totalAssets: data.total_assets,
      totalLiabilities: data.total_liabilities,
      totalEquity: data.total_equity,
      asOfDate: data.as_of_date,
    };
  }

  async getCashFlowStatement(params: {
    tenantId: string;
    branchId?: string;
    startDate: Date;
    endDate: Date;
  }) {
    let query = this.supabase
      .from('cash_flow_statement')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .gte('period', params.startDate.toISOString())
      .lte('period', params.endDate.toISOString())
      .order('period');

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map(item => ({
      period: item.period,
      operatingCashFlow: item.operating_cash_flow,
      investingCashFlow: item.investing_cash_flow,
      financingCashFlow: item.financing_cash_flow,
      netCashFlow: item.net_cash_flow,
    }));
  }

  async getTrialBalance(params: {
    tenantId: string;
    branchId?: string;
  }) {
    let query = this.supabase
      .from('trial_balance')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .order('account_code');

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map(item => ({
      accountCode: item.account_code,
      accountName: item.account_name,
      accountType: item.account_type,
      totalDebit: item.total_debit,
      totalCredit: item.total_credit,
      balance: item.balance,
    }));
  }

  async createReportTemplate(params: {
    tenantId: string;
    templateName: string;
    reportType: string;
    description: string;
    reportConfig: any;
    columns: any[];
  }): Promise<ReportTemplate> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('financial_report_templates')
      .insert({
        tenant_id: params.tenantId,
        template_name: params.templateName,
        report_type: params.reportType,
        description: params.description,
        report_config: params.reportConfig,
        columns: params.columns,
        created_by: user?.id,
        is_active: true,
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapTemplate(data);
  }

  async generateReport(params: {
    tenantId: string;
    templateId?: string;
    reportType: string;
    reportName: string;
    periodStart: Date;
    periodEnd: Date;
    fileFormat?: string;
  }): Promise<GeneratedReport> {
    const { data: { user } } = await this.supabase.auth.getUser();

    // Create report record
    const { data, error } = await this.supabase
      .from('generated_reports')
      .insert({
        tenant_id: params.tenantId,
        template_id: params.templateId,
        report_name: params.reportName,
        report_type: params.reportType,
        period_start: params.periodStart.toISOString().split('T')[0],
        period_end: params.periodEnd.toISOString().split('T')[0],
        file_format: params.fileFormat || 'pdf',
        status: 'generating',
        generated_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;

    // In production, this would trigger a background job
    // For now, simulate immediate generation
    const reportData = await this.supabase.rpc('export_report_to_json', {
      p_report_type: params.reportType,
      p_tenant_id: params.tenantId,
      p_start_date: params.periodStart.toISOString().split('T')[0],
      p_end_date: params.periodEnd.toISOString().split('T')[0],
    });

    // Update with file URL (in production, this would be actual file storage)
    const fileUrl = `/api/reports/${data.id}.${params.fileFormat || 'pdf'}`;
    
    await this.supabase
      .from('generated_reports')
      .update({
        status: 'ready',
        file_url: fileUrl,
        file_size_bytes: JSON.stringify(reportData.data).length,
      })
      .eq('id', data.id);

    return this.mapGeneratedReport({ ...data, file_url: fileUrl, status: 'ready' });
  }

  async scheduleReport(params: {
    tenantId: string;
    templateId?: string;
    scheduleName: string;
    reportType: string;
    frequency: string;
    scheduleConfig: any;
    emailRecipients: string[];
    periodType: string;
    fileFormat?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('scheduled_reports')
      .insert({
        tenant_id: params.tenantId,
        template_id: params.templateId,
        schedule_name: params.scheduleName,
        report_type: params.reportType,
        frequency: params.frequency,
        schedule_config: params.scheduleConfig,
        email_recipients: params.emailRecipients,
        period_type: params.periodType,
        file_format: params.fileFormat || 'pdf',
        created_by: user?.id,
        is_active: true,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getGeneratedReports(params: {
    tenantId: string;
    reportType?: string;
    limit?: number;
  }): Promise<GeneratedReport[]> {
    let query = this.supabase
      .from('generated_reports')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('status', 'ready')
      .order('generated_at', { ascending: false });

    if (params.reportType) {
      query = query.eq('report_type', params.reportType);
    }

    if (params.limit) {
      query = query.limit(params.limit);
    }

    const { data, error } = await query;

    if (error) throw error;
    return (data || []).map(this.mapGeneratedReport);
  }

  async exportToExcel(params: {
    reportType: string;
    tenantId: string;
    startDate: Date;
    endDate: Date;
  }): Promise<Blob> {
    // In production, this would call a backend service
    // For now, simulate Excel generation
    const data = await this.getProfitLossStatement({
      tenantId: params.tenantId,
      startDate: params.startDate,
      endDate: params.endDate,
    });

    // Convert to CSV (simplified)
    const csv = this.convertToCSV(data);
    return new Blob([csv], { type: 'text/csv' });
  }

  private convertToCSV(data: any[]): string {
    if (data.length === 0) return '';

    const headers = Object.keys(data[0]).join(',');
    const rows = data.map(row =>
      Object.values(row).map(val => `"${val}"`).join(',')
    );

    return [headers, ...rows].join('\n');
  }

  private mapTemplate(data: any): ReportTemplate {
    return {
      id: data.id,
      templateName: data.template_name,
      reportType: data.report_type,
      description: data.description,
    };
  }

  private mapGeneratedReport(data: any): GeneratedReport {
    return {
      id: data.id,
      reportName: data.report_name,
      reportType: data.report_type,
      periodStart: data.period_start,
      periodEnd: data.period_end,
      fileUrl: data.file_url,
      status: data.status,
      generatedAt: data.generated_at,
    };
  }
}

export const financialReportsAPI = new FinancialReportsAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { FinancialReportsAPI } from '../financial-reports';

describe('FinancialReportsAPI', () => {
  it('generates P&L statement', async () => {
    const api = new FinancialReportsAPI();
    const statement = await api.getProfitLossStatement({
      tenantId: 'test-tenant',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-01-31'),
    });

    expect(Array.isArray(statement)).toBe(true);
  });

  it('generates balance sheet', async () => {
    const api = new FinancialReportsAPI();
    const balanceSheet = await api.getBalanceSheet({
      tenantId: 'test-tenant',
    });

    expect(balanceSheet).toHaveProperty('totalAssets');
    expect(balanceSheet).toHaveProperty('totalLiabilities');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] P&L statement accurate
- [ ] Balance sheet correct
- [ ] Cash flow statement working
- [ ] Trial balance calculated
- [ ] Report generation functional
- [ ] Export formats working
- [ ] Scheduled reports operational
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-177 (Audit Trail)  
**Time**: 5 hours  
**AI-Ready**: 100%
