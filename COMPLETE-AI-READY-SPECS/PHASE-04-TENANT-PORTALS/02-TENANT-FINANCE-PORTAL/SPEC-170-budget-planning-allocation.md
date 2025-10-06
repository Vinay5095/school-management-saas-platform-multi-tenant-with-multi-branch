# SPEC-170: Budget Planning & Allocation

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-170  
**Title**: Budget Planning & Allocation System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Budget Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-166, SPEC-167  

---

## 📋 DESCRIPTION

Implement comprehensive budget planning and allocation system for multi-branch organizations. Features include annual budget creation, branch/department allocation, approval workflows, budget templates, historical analysis, and what-if scenarios.

---

## 🎯 SUCCESS CRITERIA

- [ ] Budget creation wizard functional
- [ ] Branch/department allocation working
- [ ] Approval workflow operational
- [ ] Budget templates available
- [ ] Historical comparison working
- [ ] What-if analysis functional
- [ ] Export/reporting operational
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Annual Budgets
CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  fiscal_year INTEGER NOT NULL,
  budget_name VARCHAR(200) NOT NULL,
  total_budget NUMERIC(15,2) NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, submitted, approved, active, closed
  
  -- Approval
  submitted_by UUID REFERENCES auth.users(id),
  submitted_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Dates
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  -- Metadata
  notes TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'submitted', 'approved', 'active', 'closed', 'rejected')),
  CONSTRAINT valid_dates CHECK (end_date > start_date),
  UNIQUE(tenant_id, fiscal_year)
);

-- Budget Allocations
CREATE TABLE IF NOT EXISTS budget_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  
  -- Allocation target
  branch_id UUID REFERENCES branches(id),
  department VARCHAR(100),
  expense_category_id UUID REFERENCES expense_categories(id),
  
  -- Amounts
  allocated_amount NUMERIC(15,2) NOT NULL,
  spent_amount NUMERIC(15,2) DEFAULT 0,
  committed_amount NUMERIC(15,2) DEFAULT 0, -- Pending approvals
  remaining_amount NUMERIC(15,2) GENERATED ALWAYS AS (allocated_amount - spent_amount - committed_amount) STORED,
  
  -- Period breakdown (optional - for monthly allocation)
  monthly_breakdown JSONB, -- {"jan": 1000, "feb": 1000, ...}
  
  -- Metadata
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT positive_allocation CHECK (allocated_amount >= 0)
);

CREATE INDEX ON budget_allocations(budget_id);
CREATE INDEX ON budget_allocations(branch_id);
CREATE INDEX ON budget_allocations(expense_category_id);

-- Budget Templates
CREATE TABLE IF NOT EXISTS budget_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  template_name VARCHAR(200) NOT NULL,
  description TEXT,
  
  -- Template structure
  allocation_structure JSONB NOT NULL, -- Store allocation percentages/amounts
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, template_name)
);

-- Budget Revisions (Track changes)
CREATE TABLE IF NOT EXISTS budget_revisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  allocation_id UUID REFERENCES budget_allocations(id),
  
  -- Change details
  revision_type VARCHAR(50) NOT NULL, -- increase, decrease, reallocation
  previous_amount NUMERIC(15,2) NOT NULL,
  new_amount NUMERIC(15,2) NOT NULL,
  difference NUMERIC(15,2) GENERATED ALWAYS AS (new_amount - previous_amount) STORED,
  
  -- Approval
  requested_by UUID NOT NULL REFERENCES auth.users(id),
  approved_by UUID REFERENCES auth.users(id),
  status VARCHAR(50) DEFAULT 'pending',
  
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  approved_at TIMESTAMP WITH TIME ZONE
);

-- Function to update spent amounts
CREATE OR REPLACE FUNCTION update_budget_spent_amount()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
    -- Update allocation spent amount
    UPDATE budget_allocations
    SET spent_amount = spent_amount + NEW.total_amount,
        updated_at = NOW()
    WHERE budget_id IN (
      SELECT id FROM budgets 
      WHERE tenant_id = NEW.tenant_id 
      AND status = 'active'
      AND NEW.expense_date BETWEEN start_date AND end_date
    )
    AND branch_id = NEW.branch_id
    AND expense_category_id = NEW.category_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_budget_on_expense
  AFTER UPDATE ON expense_claims
  FOR EACH ROW
  EXECUTE FUNCTION update_budget_spent_amount();

-- Budget utilization view
CREATE OR REPLACE VIEW budget_utilization AS
SELECT
  b.id as budget_id,
  b.tenant_id,
  b.fiscal_year,
  b.budget_name,
  ba.id as allocation_id,
  ba.branch_id,
  ba.department,
  ba.allocated_amount,
  ba.spent_amount,
  ba.committed_amount,
  ba.remaining_amount,
  CASE 
    WHEN ba.allocated_amount > 0 THEN
      (ba.spent_amount / ba.allocated_amount * 100)
    ELSE 0
  END as utilization_percentage,
  CASE
    WHEN ba.remaining_amount < 0 THEN 'over_budget'
    WHEN (ba.spent_amount / ba.allocated_amount * 100) >= 90 THEN 'critical'
    WHEN (ba.spent_amount / ba.allocated_amount * 100) >= 75 THEN 'warning'
    ELSE 'on_track'
  END as status
FROM budgets b
JOIN budget_allocations ba ON ba.budget_id = b.id
WHERE b.status = 'active';

-- Enable RLS
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_revisions ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/budget-planning.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface Budget {
  id: string;
  fiscalYear: number;
  budgetName: string;
  totalBudget: number;
  status: string;
  startDate: string;
  endDate: string;
}

export interface BudgetAllocation {
  id: string;
  branchId?: string;
  branchName?: string;
  department?: string;
  categoryName?: string;
  allocatedAmount: number;
  spentAmount: number;
  committedAmount: number;
  remainingAmount: number;
  utilizationPercentage: number;
  status: string;
}

export class BudgetPlanningAPI {
  private supabase = createClient();

  async createBudget(params: {
    tenantId: string;
    fiscalYear: number;
    budgetName: string;
    totalBudget: number;
    startDate: Date;
    endDate: Date;
    notes?: string;
  }): Promise<Budget> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('budgets')
      .insert({
        tenant_id: params.tenantId,
        fiscal_year: params.fiscalYear,
        budget_name: params.budgetName,
        total_budget: params.totalBudget,
        start_date: params.startDate.toISOString().split('T')[0],
        end_date: params.endDate.toISOString().split('T')[0],
        notes: params.notes,
        submitted_by: user?.id,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapBudget(data);
  }

  async allocateBudget(params: {
    budgetId: string;
    branchId?: string;
    department?: string;
    categoryId?: string;
    allocatedAmount: number;
    monthlyBreakdown?: Record<string, number>;
    notes?: string;
  }): Promise<BudgetAllocation> {
    const { data, error } = await this.supabase
      .from('budget_allocations')
      .insert({
        budget_id: params.budgetId,
        branch_id: params.branchId,
        department: params.department,
        expense_category_id: params.categoryId,
        allocated_amount: params.allocatedAmount,
        monthly_breakdown: params.monthlyBreakdown,
        notes: params.notes,
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapAllocation(data);
  }

  async getBudgetAllocations(budgetId: string): Promise<BudgetAllocation[]> {
    const { data, error } = await this.supabase
      .from('budget_utilization')
      .select('*')
      .eq('budget_id', budgetId);

    if (error) throw error;
    return (data || []).map(this.mapAllocation);
  }

  async submitBudgetForApproval(budgetId: string): Promise<void> {
    const { error } = await this.supabase
      .from('budgets')
      .update({
        status: 'submitted',
        submitted_at: new Date().toISOString(),
      })
      .eq('id', budgetId);

    if (error) throw error;
  }

  async approveBudget(budgetId: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('budgets')
      .update({
        status: 'approved',
        approved_by: user?.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', budgetId);

    if (error) throw error;
  }

  async activateBudget(budgetId: string): Promise<void> {
    const { error } = await this.supabase
      .from('budgets')
      .update({ status: 'active' })
      .eq('id', budgetId);

    if (error) throw error;
  }

  async createBudgetTemplate(params: {
    tenantId: string;
    templateName: string;
    description: string;
    allocationStructure: any;
  }) {
    const { data, error } = await this.supabase
      .from('budget_templates')
      .insert({
        tenant_id: params.tenantId,
        template_name: params.templateName,
        description: params.description,
        allocation_structure: params.allocationStructure,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async applyBudgetTemplate(params: {
    budgetId: string;
    templateId: string;
  }): Promise<void> {
    const { data: template } = await this.supabase
      .from('budget_templates')
      .select('allocation_structure')
      .eq('id', params.templateId)
      .single();

    if (!template) throw new Error('Template not found');

    const { data: budget } = await this.supabase
      .from('budgets')
      .select('total_budget')
      .eq('id', params.budgetId)
      .single();

    if (!budget) throw new Error('Budget not found');

    // Apply template allocations
    const allocations = template.allocation_structure.map((item: any) => ({
      budget_id: params.budgetId,
      branch_id: item.branchId,
      department: item.department,
      expense_category_id: item.categoryId,
      allocated_amount: (budget.total_budget * item.percentage) / 100,
    }));

    const { error } = await this.supabase
      .from('budget_allocations')
      .insert(allocations);

    if (error) throw error;
  }

  async requestBudgetRevision(params: {
    budgetId: string;
    allocationId: string;
    newAmount: number;
    reason: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data: allocation } = await this.supabase
      .from('budget_allocations')
      .select('allocated_amount')
      .eq('id', params.allocationId)
      .single();

    if (!allocation) throw new Error('Allocation not found');

    const { data, error } = await this.supabase
      .from('budget_revisions')
      .insert({
        budget_id: params.budgetId,
        allocation_id: params.allocationId,
        revision_type: params.newAmount > allocation.allocated_amount ? 'increase' : 'decrease',
        previous_amount: allocation.allocated_amount,
        new_amount: params.newAmount,
        requested_by: user?.id,
        reason: params.reason,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getBudgetComparison(params: {
    tenantId: string;
    fiscalYears: number[];
  }) {
    const { data, error } = await this.supabase
      .from('budgets')
      .select(`
        fiscal_year,
        total_budget,
        allocations:budget_allocations(
          allocated_amount,
          spent_amount
        )
      `)
      .eq('tenant_id', params.tenantId)
      .in('fiscal_year', params.fiscalYears)
      .eq('status', 'active');

    if (error) throw error;

    return data.map(budget => ({
      fiscalYear: budget.fiscal_year,
      totalBudget: budget.total_budget,
      totalSpent: budget.allocations.reduce((sum: number, a: any) => sum + a.spent_amount, 0),
      totalAllocated: budget.allocations.reduce((sum: number, a: any) => sum + a.allocated_amount, 0),
    }));
  }

  private mapBudget(data: any): Budget {
    return {
      id: data.id,
      fiscalYear: data.fiscal_year,
      budgetName: data.budget_name,
      totalBudget: data.total_budget,
      status: data.status,
      startDate: data.start_date,
      endDate: data.end_date,
    };
  }

  private mapAllocation(data: any): BudgetAllocation {
    return {
      id: data.id || data.allocation_id,
      branchId: data.branch_id,
      branchName: data.branch_name,
      department: data.department,
      categoryName: data.category_name,
      allocatedAmount: data.allocated_amount,
      spentAmount: data.spent_amount,
      committedAmount: data.committed_amount,
      remainingAmount: data.remaining_amount,
      utilizationPercentage: data.utilization_percentage || 0,
      status: data.status || 'on_track',
    };
  }
}

export const budgetPlanningAPI = new BudgetPlanningAPI();
```

### Component (`/components/finance/BudgetPlanner.tsx`)

```typescript
'use client';

import { useState } from 'react';
import { budgetPlanningAPI } from '@/lib/api/budget-planning';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { formatCurrency } from '@/lib/utils';
import { AlertTriangle, CheckCircle, TrendingUp } from 'lucide-react';

export function BudgetPlanner({ tenantId }: { tenantId: string }) {
  const [budgets, setBudgets] = useState<any[]>([]);
  const [selectedBudget, setSelectedBudget] = useState<any>(null);
  const [allocations, setAllocations] = useState<any[]>([]);

  const createNewBudget = async () => {
    const budget = await budgetPlanningAPI.createBudget({
      tenantId,
      fiscalYear: new Date().getFullYear() + 1,
      budgetName: `FY ${new Date().getFullYear() + 1} Budget`,
      totalBudget: 1000000,
      startDate: new Date(`${new Date().getFullYear() + 1}-01-01`),
      endDate: new Date(`${new Date().getFullYear() + 1}-12-31`),
    });

    setBudgets([...budgets, budget]);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'on_track': return 'text-green-600';
      case 'warning': return 'text-yellow-600';
      case 'critical': return 'text-orange-600';
      case 'over_budget': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'on_track': return <CheckCircle className="h-4 w-4" />;
      case 'warning': return <AlertTriangle className="h-4 w-4" />;
      case 'critical': return <AlertTriangle className="h-4 w-4" />;
      case 'over_budget': return <AlertTriangle className="h-4 w-4" />;
      default: return null;
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Budget Planning & Allocation</h1>
        <Button onClick={createNewBudget}>Create New Budget</Button>
      </div>

      {selectedBudget && allocations.length > 0 && (
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Budget Allocations - {selectedBudget.budgetName}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {allocations.map((allocation) => (
                  <div key={allocation.id} className="rounded-lg border p-4">
                    <div className="flex items-center justify-between mb-2">
                      <div>
                        <div className="font-medium">
                          {allocation.branchName || allocation.department}
                        </div>
                        <div className="text-sm text-gray-500">
                          {allocation.categoryName}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-bold">
                          {formatCurrency(allocation.spentAmount)} / {formatCurrency(allocation.allocatedAmount)}
                        </div>
                        <div className={`flex items-center gap-1 text-sm ${getStatusColor(allocation.status)}`}>
                          {getStatusIcon(allocation.status)}
                          <span>{allocation.utilizationPercentage.toFixed(1)}% utilized</span>
                        </div>
                      </div>
                    </div>
                    <Progress value={allocation.utilizationPercentage} />
                    <div className="mt-2 flex justify-between text-xs text-gray-500">
                      <span>Remaining: {formatCurrency(allocation.remainingAmount)}</span>
                      <span>Committed: {formatCurrency(allocation.committedAmount)}</span>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { BudgetPlanningAPI } from '../budget-planning';

describe('BudgetPlanningAPI', () => {
  it('creates budget correctly', async () => {
    const api = new BudgetPlanningAPI();
    const budget = await api.createBudget({
      tenantId: 'test-tenant',
      fiscalYear: 2025,
      budgetName: 'FY 2025',
      totalBudget: 1000000,
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-12-31'),
    });

    expect(budget).toHaveProperty('id');
    expect(budget.status).toBe('draft');
  });

  it('allocates budget correctly', async () => {
    const api = new BudgetPlanningAPI();
    const allocation = await api.allocateBudget({
      budgetId: 'budget-1',
      branchId: 'branch-1',
      allocatedAmount: 100000,
    });

    expect(allocation.allocatedAmount).toBe(100000);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Budget creation working
- [ ] Allocation system functional
- [ ] Approval workflow operational
- [ ] Templates working
- [ ] Utilization tracking accurate
- [ ] Revision requests working
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-171 (Budget Monitoring)  
**Time**: 5 hours  
**AI-Ready**: 100%
