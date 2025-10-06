# SPEC-199: Budget Oversight & Financial Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-199  
**Title**: Budget Oversight & Financial Management  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Principal Portal  
**Category**: Financial Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-191, SPEC-170  

---

## 📋 DESCRIPTION

Financial oversight dashboard for principals to monitor school budget, approve expenses, track revenue/expenditure, review financial forecasts, and ensure fiscal responsibility across all departments.

---

## 🗄️ DATABASE SCHEMA

```sql
-- Branch Budget Overview (Materialized View)
CREATE MATERIALIZED VIEW branch_budget_overview AS
SELECT
  b.tenant_id,
  b.id as branch_id,
  b.academic_year,
  
  SUM(CASE WHEN ba.allocation_type = 'revenue' THEN ba.allocated_amount ELSE 0 END) as total_revenue_budget,
  SUM(CASE WHEN ba.allocation_type = 'expense' THEN ba.allocated_amount ELSE 0 END) as total_expense_budget,
  
  SUM(CASE WHEN e.transaction_type = 'income' THEN e.amount ELSE 0 END) as actual_revenue,
  SUM(CASE WHEN e.transaction_type = 'expense' THEN e.amount ELSE 0 END) as actual_expenses,
  
  -- Variance
  SUM(CASE WHEN ba.allocation_type = 'revenue' THEN ba.allocated_amount ELSE 0 END) - 
  SUM(CASE WHEN e.transaction_type = 'income' THEN e.amount ELSE 0 END) as revenue_variance,
  
  SUM(CASE WHEN ba.allocation_type = 'expense' THEN ba.allocated_amount ELSE 0 END) - 
  SUM(CASE WHEN e.transaction_type = 'expense' THEN e.amount ELSE 0 END) as expense_variance,
  
  NOW() as last_calculated_at
  
FROM budget_allocations ba
LEFT JOIN expenses e ON ba.branch_id = e.branch_id AND ba.academic_year = e.fiscal_year
JOIN branches b ON ba.branch_id = b.id
GROUP BY b.tenant_id, b.id, b.academic_year;

CREATE UNIQUE INDEX ON branch_budget_overview(tenant_id, branch_id, academic_year);

-- Expense Approval Tracking
CREATE TABLE IF NOT EXISTS expense_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID NOT NULL REFERENCES expenses(id),
  
  approval_level VARCHAR(50), -- department_head, finance, principal
  approver_id UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  approval_notes TEXT,
  
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON expense_approvals(expense_id, approval_level);

-- Enable RLS
ALTER TABLE expense_approvals ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/budget-oversight.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface BudgetOverview {
  totalRevenueBudget: number;
  totalExpenseBudget: number;
  actualRevenue: number;
  actualExpenses: number;
  revenueVariance: number;
  expenseVariance: number;
}

export class BudgetOversightAPI {
  private supabase = createClient();

  async getBudgetOverview(params: {
    tenantId: string;
    branchId: string;
    academicYear: string;
  }): Promise<BudgetOverview> {
    const { data, error } = await this.supabase
      .from('branch_budget_overview')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('academic_year', params.academicYear)
      .single();

    if (error) throw error;

    return {
      totalRevenueBudget: data.total_revenue_budget || 0,
      totalExpenseBudget: data.total_expense_budget || 0,
      actualRevenue: data.actual_revenue || 0,
      actualExpenses: data.actual_expenses || 0,
      revenueVariance: data.revenue_variance || 0,
      expenseVariance: data.expense_variance || 0,
    };
  }

  async getPendingExpenseApprovals(params: {
    tenantId: string;
    branchId: string;
  }) {
    const { data, error } = await this.supabase
      .from('expense_approvals')
      .select('*, expense:expenses(*)')
      .eq('approval_level', 'principal')
      .eq('status', 'pending');

    if (error) throw error;
    return data;
  }

  async approveExpense(params: {
    expenseId: string;
    approvalNotes?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('expense_approvals')
      .update({
        status: 'approved',
        approver_id: user?.id,
        approved_at: new Date().toISOString(),
        approval_notes: params.approvalNotes,
      })
      .eq('expense_id', params.expenseId)
      .eq('approval_level', 'principal');

    if (error) throw error;
  }
}

export const budgetOversightAPI = new BudgetOversightAPI();
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Budget overview displaying
- [ ] Expense approvals working
- [ ] Variance tracking functional
- [ ] Financial reports generating
- [ ] Tests passing

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%
