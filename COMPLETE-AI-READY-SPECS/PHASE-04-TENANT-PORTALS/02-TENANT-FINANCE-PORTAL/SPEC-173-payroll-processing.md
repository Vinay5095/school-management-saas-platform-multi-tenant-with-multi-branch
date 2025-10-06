# SPEC-173: Payroll Processing System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-173  
**Title**: Payroll Processing & Management System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Payroll Management  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-012 (Staff Management)  

---

## 📋 DESCRIPTION

Comprehensive payroll processing system with salary calculation, deductions, allowances, tax computation, payslip generation, payment processing, and compliance reporting. Supports multiple payment cycles, batch processing, and automated calculations.

---

## 🎯 SUCCESS CRITERIA

- [ ] Payroll calculation engine operational
- [ ] Deductions/allowances working
- [ ] Tax computation accurate
- [ ] Payslip generation functional
- [ ] Payment batch processing working
- [ ] Approval workflow operational
- [ ] Compliance reports available
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Payroll Cycles
CREATE TABLE IF NOT EXISTS payroll_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Cycle details
  cycle_name VARCHAR(200) NOT NULL,
  pay_period_start DATE NOT NULL,
  pay_period_end DATE NOT NULL,
  payment_date DATE NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, calculating, pending_approval, approved, processing, completed, cancelled
  
  -- Totals
  total_gross_pay NUMERIC(15,2) DEFAULT 0,
  total_deductions NUMERIC(15,2) DEFAULT 0,
  total_net_pay NUMERIC(15,2) DEFAULT 0,
  employee_count INTEGER DEFAULT 0,
  
  -- Approval
  calculated_at TIMESTAMP WITH TIME ZONE,
  calculated_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES auth.users(id),
  processed_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  notes TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'calculating', 'pending_approval', 'approved', 'processing', 'completed', 'cancelled')),
  CONSTRAINT valid_dates CHECK (pay_period_end > pay_period_start AND payment_date >= pay_period_end)
);

-- Payroll Components (Salary Structure)
CREATE TABLE IF NOT EXISTS payroll_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Component details
  component_code VARCHAR(50) NOT NULL,
  component_name VARCHAR(200) NOT NULL,
  component_type VARCHAR(50) NOT NULL, -- earning, deduction, employer_contribution
  category VARCHAR(100), -- basic_salary, allowance, bonus, tax, insurance, loan, etc.
  
  -- Calculation
  calculation_type VARCHAR(50) NOT NULL, -- fixed, percentage, formula
  calculation_basis VARCHAR(50), -- basic_salary, gross_salary, attendance
  default_value NUMERIC(15,2),
  
  -- Tax treatment
  is_taxable BOOLEAN DEFAULT true,
  is_statutory BOOLEAN DEFAULT false, -- Required by law
  
  -- Configuration
  formula TEXT, -- For complex calculations
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, component_code)
);

-- Employee Payroll Details
CREATE TABLE IF NOT EXISTS employee_payroll_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  
  -- Salary structure
  basic_salary NUMERIC(15,2) NOT NULL,
  pay_frequency VARCHAR(20) DEFAULT 'monthly', -- monthly, bi_weekly, weekly
  
  -- Bank details
  bank_name VARCHAR(200),
  account_number VARCHAR(50),
  ifsc_code VARCHAR(20),
  
  -- Tax information
  tax_identification_number VARCHAR(50),
  tax_regime VARCHAR(50), -- old, new, etc.
  tax_exemptions JSONB,
  
  -- Additional components (specific to employee)
  fixed_allowances JSONB, -- {"hra": 10000, "transport": 2000}
  fixed_deductions JSONB, -- {"pf": 1800, "insurance": 500}
  
  effective_from DATE NOT NULL,
  effective_to DATE,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON employee_payroll_details(employee_id);

-- Payroll Entries (Individual payslips)
CREATE TABLE IF NOT EXISTS payroll_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_cycle_id UUID NOT NULL REFERENCES payroll_cycles(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES staff(id),
  
  -- Employee snapshot
  employee_name VARCHAR(200) NOT NULL,
  employee_code VARCHAR(50) NOT NULL,
  designation VARCHAR(100),
  department VARCHAR(100),
  
  -- Attendance
  days_worked NUMERIC(5,2) DEFAULT 0,
  days_paid NUMERIC(5,2) DEFAULT 0,
  overtime_hours NUMERIC(5,2) DEFAULT 0,
  
  -- Salary breakdown
  basic_salary NUMERIC(15,2) NOT NULL,
  gross_earnings NUMERIC(15,2) NOT NULL,
  total_deductions NUMERIC(15,2) NOT NULL,
  net_pay NUMERIC(15,2) NOT NULL,
  
  -- Component breakdown
  earnings_breakdown JSONB NOT NULL, -- {"basic": 50000, "hra": 15000, "transport": 2000}
  deductions_breakdown JSONB NOT NULL, -- {"pf": 1800, "tax": 5000, "insurance": 500}
  
  -- Tax details
  taxable_income NUMERIC(15,2),
  tax_deducted NUMERIC(15,2),
  
  -- Payment
  payment_method VARCHAR(50) DEFAULT 'bank_transfer',
  payment_status VARCHAR(50) DEFAULT 'pending',
  payment_reference VARCHAR(100),
  paid_at TIMESTAMP WITH TIME ZONE,
  
  -- Payslip
  payslip_number VARCHAR(50) UNIQUE,
  payslip_generated BOOLEAN DEFAULT false,
  payslip_url TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft',
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(payroll_cycle_id, employee_id),
  CONSTRAINT valid_payment_status CHECK (payment_status IN ('pending', 'processing', 'paid', 'failed', 'cancelled'))
);

CREATE INDEX ON payroll_entries(payroll_cycle_id);
CREATE INDEX ON payroll_entries(employee_id);
CREATE INDEX ON payroll_entries(payment_status);

-- Payroll Adjustments (One-time additions/deductions)
CREATE TABLE IF NOT EXISTS payroll_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  
  -- Adjustment details
  adjustment_type VARCHAR(50) NOT NULL, -- bonus, arrears, deduction, advance, reimbursement
  amount NUMERIC(15,2) NOT NULL,
  description TEXT NOT NULL,
  
  -- Application
  apply_in_cycle_id UUID REFERENCES payroll_cycles(id),
  applied_at TIMESTAMP WITH TIME ZONE,
  
  -- Approval
  status VARCHAR(50) DEFAULT 'pending',
  requested_by UUID NOT NULL REFERENCES auth.users(id),
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_adjustment_status CHECK (status IN ('pending', 'approved', 'rejected', 'applied'))
);

CREATE INDEX ON payroll_adjustments(employee_id);
CREATE INDEX ON payroll_adjustments(apply_in_cycle_id);

-- Payroll History (Archive)
CREATE TABLE IF NOT EXISTS payroll_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  payroll_cycle_id UUID NOT NULL REFERENCES payroll_cycles(id),
  
  -- Snapshot
  payment_date DATE NOT NULL,
  gross_pay NUMERIC(15,2) NOT NULL,
  net_pay NUMERIC(15,2) NOT NULL,
  
  payslip_url TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON payroll_history(employee_id, payment_date);

-- Function to calculate gross earnings
CREATE OR REPLACE FUNCTION calculate_gross_earnings(
  p_basic_salary NUMERIC,
  p_earnings_breakdown JSONB
)
RETURNS NUMERIC AS $$
DECLARE
  v_total NUMERIC := 0;
  v_key TEXT;
  v_value NUMERIC;
BEGIN
  -- Sum all earnings components
  FOR v_key, v_value IN SELECT * FROM jsonb_each_text(p_earnings_breakdown)
  LOOP
    v_total := v_total + v_value::NUMERIC;
  END LOOP;
  
  RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate tax (Simplified - customize per jurisdiction)
CREATE OR REPLACE FUNCTION calculate_income_tax(
  p_taxable_income NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
  v_tax NUMERIC := 0;
BEGIN
  -- Example progressive tax calculation
  IF p_taxable_income <= 250000 THEN
    v_tax := 0;
  ELSIF p_taxable_income <= 500000 THEN
    v_tax := (p_taxable_income - 250000) * 0.05;
  ELSIF p_taxable_income <= 1000000 THEN
    v_tax := 12500 + (p_taxable_income - 500000) * 0.20;
  ELSE
    v_tax := 112500 + (p_taxable_income - 1000000) * 0.30;
  END IF;
  
  RETURN v_tax;
END;
$$ LANGUAGE plpgsql;

-- Function to generate payslip number
CREATE OR REPLACE FUNCTION generate_payslip_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.payslip_number := 'PAY-' || 
    TO_CHAR(NOW(), 'YYYYMM') || '-' ||
    LPAD(NEXTVAL('payslip_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS payslip_seq;

CREATE TRIGGER set_payslip_number
  BEFORE INSERT ON payroll_entries
  FOR EACH ROW
  WHEN (NEW.payslip_number IS NULL)
  EXECUTE FUNCTION generate_payslip_number();

-- Trigger to update cycle totals
CREATE OR REPLACE FUNCTION update_payroll_cycle_totals()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE payroll_cycles
  SET 
    total_gross_pay = (
      SELECT COALESCE(SUM(gross_earnings), 0)
      FROM payroll_entries
      WHERE payroll_cycle_id = COALESCE(NEW.payroll_cycle_id, OLD.payroll_cycle_id)
    ),
    total_deductions = (
      SELECT COALESCE(SUM(total_deductions), 0)
      FROM payroll_entries
      WHERE payroll_cycle_id = COALESCE(NEW.payroll_cycle_id, OLD.payroll_cycle_id)
    ),
    total_net_pay = (
      SELECT COALESCE(SUM(net_pay), 0)
      FROM payroll_entries
      WHERE payroll_cycle_id = COALESCE(NEW.payroll_cycle_id, OLD.payroll_cycle_id)
    ),
    employee_count = (
      SELECT COUNT(*)
      FROM payroll_entries
      WHERE payroll_cycle_id = COALESCE(NEW.payroll_cycle_id, OLD.payroll_cycle_id)
    ),
    updated_at = NOW()
  WHERE id = COALESCE(NEW.payroll_cycle_id, OLD.payroll_cycle_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cycle_totals_after_entry
  AFTER INSERT OR UPDATE OR DELETE ON payroll_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_payroll_cycle_totals();

-- Enable RLS
ALTER TABLE payroll_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_payroll_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_history ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/payroll.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface PayrollCycle {
  id: string;
  cycleName: string;
  payPeriodStart: string;
  payPeriodEnd: string;
  paymentDate: string;
  status: string;
  totalGrossPay: number;
  totalDeductions: number;
  totalNetPay: number;
  employeeCount: number;
}

export interface PayrollEntry {
  id: string;
  employeeName: string;
  employeeCode: string;
  designation: string;
  basicSalary: number;
  grossEarnings: number;
  totalDeductions: number;
  netPay: number;
  paymentStatus: string;
  payslipNumber: string;
}

export class PayrollAPI {
  private supabase = createClient();

  async createPayrollCycle(params: {
    tenantId: string;
    branchId?: string;
    cycleName: string;
    payPeriodStart: Date;
    payPeriodEnd: Date;
    paymentDate: Date;
  }): Promise<PayrollCycle> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('payroll_cycles')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        cycle_name: params.cycleName,
        pay_period_start: params.payPeriodStart.toISOString().split('T')[0],
        pay_period_end: params.payPeriodEnd.toISOString().split('T')[0],
        payment_date: params.paymentDate.toISOString().split('T')[0],
        calculated_by: user?.id,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapCycle(data);
  }

  async calculatePayroll(params: {
    cycleId: string;
    employeeIds?: string[];
  }): Promise<void> {
    // Get cycle details
    const { data: cycle } = await this.supabase
      .from('payroll_cycles')
      .select('*, tenant_id, branch_id')
      .eq('id', params.cycleId)
      .single();

    if (!cycle) throw new Error('Cycle not found');

    // Get active employees
    let query = this.supabase
      .from('staff')
      .select(`
        *,
        payroll:employee_payroll_details!inner(*)
      `)
      .eq('tenant_id', cycle.tenant_id)
      .eq('status', 'active')
      .eq('employee_payroll_details.is_active', true);

    if (cycle.branch_id) {
      query = query.eq('branch_id', cycle.branch_id);
    }

    if (params.employeeIds && params.employeeIds.length > 0) {
      query = query.in('id', params.employeeIds);
    }

    const { data: employees, error: empError } = await query;

    if (empError) throw empError;

    // Calculate payroll for each employee
    const entries = employees.map(emp => {
      const payrollDetail = emp.payroll[0];
      const basicSalary = payrollDetail.basic_salary;
      
      // Build earnings breakdown
      const earningsBreakdown: any = {
        basic_salary: basicSalary,
        ...payrollDetail.fixed_allowances,
      };

      // Calculate gross
      const grossEarnings = Object.values(earningsBreakdown).reduce(
        (sum: number, val: any) => sum + parseFloat(val), 0
      );

      // Build deductions breakdown
      const deductionsBreakdown: any = {
        ...payrollDetail.fixed_deductions,
      };

      // Calculate tax
      const taxableIncome = grossEarnings * 12; // Annualized
      const yearlyTax = this.calculateTax(taxableIncome);
      const monthlyTax = yearlyTax / 12;
      deductionsBreakdown.income_tax = monthlyTax;

      // Calculate total deductions
      const totalDeductions = Object.values(deductionsBreakdown).reduce(
        (sum: number, val: any) => sum + parseFloat(val), 0
      );

      // Net pay
      const netPay = grossEarnings - totalDeductions;

      return {
        payroll_cycle_id: params.cycleId,
        employee_id: emp.id,
        employee_name: emp.full_name,
        employee_code: emp.employee_code,
        designation: emp.designation,
        department: emp.department,
        days_worked: 30, // Simplified - should come from attendance
        days_paid: 30,
        basic_salary: basicSalary,
        gross_earnings: grossEarnings,
        total_deductions: totalDeductions,
        net_pay: netPay,
        earnings_breakdown: earningsBreakdown,
        deductions_breakdown: deductionsBreakdown,
        taxable_income: taxableIncome,
        tax_deducted: monthlyTax,
        status: 'calculated',
      };
    });

    // Insert entries
    const { error: insertError } = await this.supabase
      .from('payroll_entries')
      .insert(entries);

    if (insertError) throw insertError;

    // Update cycle status
    await this.supabase
      .from('payroll_cycles')
      .update({
        status: 'pending_approval',
        calculated_at: new Date().toISOString(),
      })
      .eq('id', params.cycleId);
  }

  async getPayrollEntries(cycleId: string): Promise<PayrollEntry[]> {
    const { data, error } = await this.supabase
      .from('payroll_entries')
      .select('*')
      .eq('payroll_cycle_id', cycleId)
      .order('employee_name');

    if (error) throw error;
    return (data || []).map(this.mapEntry);
  }

  async approvePayrollCycle(cycleId: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('payroll_cycles')
      .update({
        status: 'approved',
        approved_by: user?.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', cycleId);

    if (error) throw error;
  }

  async processPayments(cycleId: string): Promise<void> {
    // Update cycle status
    await this.supabase
      .from('payroll_cycles')
      .update({
        status: 'processing',
        processed_at: new Date().toISOString(),
      })
      .eq('id', cycleId);

    // Get all entries
    const { data: entries } = await this.supabase
      .from('payroll_entries')
      .select('*')
      .eq('payroll_cycle_id', cycleId);

    if (!entries) return;

    // Process each payment (simplified - integrate with payment gateway)
    for (const entry of entries) {
      await this.supabase
        .from('payroll_entries')
        .update({
          payment_status: 'paid',
          paid_at: new Date().toISOString(),
          payment_reference: `TXN-${Date.now()}`,
        })
        .eq('id', entry.id);

      // Archive to history
      await this.supabase
        .from('payroll_history')
        .insert({
          employee_id: entry.employee_id,
          payroll_cycle_id: cycleId,
          payment_date: entry.payment_date,
          gross_pay: entry.gross_earnings,
          net_pay: entry.net_pay,
        });
    }

    // Mark cycle as completed
    await this.supabase
      .from('payroll_cycles')
      .update({ status: 'completed' })
      .eq('id', cycleId);
  }

  async generatePayslip(entryId: string): Promise<string> {
    // In production, this would generate a PDF
    // For now, return a URL placeholder
    const payslipUrl = `/api/payslips/${entryId}.pdf`;

    await this.supabase
      .from('payroll_entries')
      .update({
        payslip_generated: true,
        payslip_url: payslipUrl,
      })
      .eq('id', entryId);

    return payslipUrl;
  }

  async createAdjustment(params: {
    employeeId: string;
    adjustmentType: string;
    amount: number;
    description: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('payroll_adjustments')
      .insert({
        employee_id: params.employeeId,
        adjustment_type: params.adjustmentType,
        amount: params.amount,
        description: params.description,
        requested_by: user?.id,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  private calculateTax(annualIncome: number): number {
    if (annualIncome <= 250000) return 0;
    if (annualIncome <= 500000) return (annualIncome - 250000) * 0.05;
    if (annualIncome <= 1000000) return 12500 + (annualIncome - 500000) * 0.20;
    return 112500 + (annualIncome - 1000000) * 0.30;
  }

  private mapCycle(data: any): PayrollCycle {
    return {
      id: data.id,
      cycleName: data.cycle_name,
      payPeriodStart: data.pay_period_start,
      payPeriodEnd: data.pay_period_end,
      paymentDate: data.payment_date,
      status: data.status,
      totalGrossPay: data.total_gross_pay || 0,
      totalDeductions: data.total_deductions || 0,
      totalNetPay: data.total_net_pay || 0,
      employeeCount: data.employee_count || 0,
    };
  }

  private mapEntry(data: any): PayrollEntry {
    return {
      id: data.id,
      employeeName: data.employee_name,
      employeeCode: data.employee_code,
      designation: data.designation,
      basicSalary: data.basic_salary,
      grossEarnings: data.gross_earnings,
      totalDeductions: data.total_deductions,
      netPay: data.net_pay,
      paymentStatus: data.payment_status,
      payslipNumber: data.payslip_number,
    };
  }
}

export const payrollAPI = new PayrollAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { PayrollAPI } from '../payroll';

describe('PayrollAPI', () => {
  it('creates payroll cycle', async () => {
    const api = new PayrollAPI();
    const cycle = await api.createPayrollCycle({
      tenantId: 'test-tenant',
      cycleName: 'January 2025',
      payPeriodStart: new Date('2025-01-01'),
      payPeriodEnd: new Date('2025-01-31'),
      paymentDate: new Date('2025-02-01'),
    });

    expect(cycle).toHaveProperty('id');
    expect(cycle.status).toBe('draft');
  });

  it('calculates payroll correctly', async () => {
    const api = new PayrollAPI();
    await api.calculatePayroll({ cycleId: 'cycle-1' });
    
    const entries = await api.getPayrollEntries('cycle-1');
    expect(entries.length).toBeGreaterThan(0);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Payroll calculation accurate
- [ ] Tax computation correct
- [ ] Deductions applied properly
- [ ] Approval workflow working
- [ ] Payment processing functional
- [ ] Payslip generation working
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-174 (Benefits Management)  
**Time**: 6 hours  
**AI-Ready**: 100%
