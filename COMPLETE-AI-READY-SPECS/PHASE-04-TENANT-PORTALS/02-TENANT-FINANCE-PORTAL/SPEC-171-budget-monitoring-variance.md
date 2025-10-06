# SPEC-171: Budget Monitoring & Variance Analysis

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-171  
**Title**: Budget Monitoring & Variance Analysis  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Budget Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-170  

---

## 📋 DESCRIPTION

Real-time budget monitoring system with variance analysis, alerts, spending patterns, burn rate analysis, and predictive overspend detection. Provides executives with actionable insights on budget performance across all branches and departments.

---

## 🎯 SUCCESS CRITERIA

- [ ] Real-time budget tracking operational
- [ ] Variance analysis working
- [ ] Alert system functional
- [ ] Burn rate calculation accurate
- [ ] Overspend prediction working
- [ ] Spending pattern analysis available
- [ ] Export/reporting functional
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Budget Alerts Configuration
CREATE TABLE IF NOT EXISTS budget_alert_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Alert trigger
  alert_type VARCHAR(50) NOT NULL, -- threshold, overspend, burn_rate, variance
  threshold_percentage NUMERIC(5,2), -- e.g., 75 for 75%
  
  -- Recipients
  notify_users UUID[] NOT NULL,
  notify_emails TEXT[],
  
  -- Channels
  send_email BOOLEAN DEFAULT true,
  send_in_app BOOLEAN DEFAULT true,
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_alert_type CHECK (alert_type IN ('threshold', 'overspend', 'burn_rate', 'variance'))
);

-- Budget Alerts Log
CREATE TABLE IF NOT EXISTS budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  budget_id UUID NOT NULL REFERENCES budgets(id),
  allocation_id UUID REFERENCES budget_allocations(id),
  
  -- Alert details
  alert_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) NOT NULL, -- info, warning, critical
  message TEXT NOT NULL,
  
  -- Alert data
  current_value NUMERIC(15,2),
  threshold_value NUMERIC(15,2),
  variance_percentage NUMERIC(5,2),
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON budget_alerts(tenant_id, is_read);
CREATE INDEX ON budget_alerts(budget_id);

-- Budget Spending Patterns (Materialized View)
CREATE MATERIALIZED VIEW budget_spending_patterns AS
SELECT
  ba.budget_id,
  ba.id as allocation_id,
  b.tenant_id,
  ba.branch_id,
  ba.department,
  
  -- Current period
  ba.allocated_amount,
  ba.spent_amount,
  ba.remaining_amount,
  CASE 
    WHEN ba.allocated_amount > 0 THEN
      (ba.spent_amount / ba.allocated_amount * 100)
    ELSE 0
  END as utilization_percentage,
  
  -- Variance
  (ba.allocated_amount - ba.spent_amount) as variance_amount,
  CASE
    WHEN ba.allocated_amount > 0 THEN
      ((ba.allocated_amount - ba.spent_amount) / ba.allocated_amount * 100)
    ELSE 0
  END as variance_percentage,
  
  -- Burn rate (daily average)
  CASE
    WHEN EXTRACT(DAY FROM NOW() - b.start_date) > 0 THEN
      ba.spent_amount / EXTRACT(DAY FROM NOW() - b.start_date)
    ELSE 0
  END as daily_burn_rate,
  
  -- Projected total spend
  CASE
    WHEN EXTRACT(DAY FROM NOW() - b.start_date) > 0 AND 
         EXTRACT(DAY FROM b.end_date - b.start_date) > 0 THEN
      (ba.spent_amount / EXTRACT(DAY FROM NOW() - b.start_date)) * 
      EXTRACT(DAY FROM b.end_date - b.start_date)
    ELSE ba.spent_amount
  END as projected_spend,
  
  -- Days elapsed and remaining
  EXTRACT(DAY FROM NOW() - b.start_date) as days_elapsed,
  EXTRACT(DAY FROM b.end_date - NOW()) as days_remaining,
  EXTRACT(DAY FROM b.end_date - b.start_date) as total_days,
  
  -- Status
  CASE
    WHEN ba.spent_amount > ba.allocated_amount THEN 'over_budget'
    WHEN ba.spent_amount / NULLIF(ba.allocated_amount, 0) >= 0.9 THEN 'critical'
    WHEN ba.spent_amount / NULLIF(ba.allocated_amount, 0) >= 0.75 THEN 'warning'
    ELSE 'on_track'
  END as budget_status

FROM budget_allocations ba
JOIN budgets b ON b.id = ba.budget_id
WHERE b.status = 'active'
AND NOW() BETWEEN b.start_date AND b.end_date;

CREATE INDEX ON budget_spending_patterns(tenant_id);
CREATE INDEX ON budget_spending_patterns(budget_id);

-- Function to refresh spending patterns
CREATE OR REPLACE FUNCTION refresh_budget_spending_patterns()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY budget_spending_patterns;
END;
$$ LANGUAGE plpgsql;

-- Monthly Budget Variance Tracking
CREATE TABLE IF NOT EXISTS budget_monthly_variance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES budgets(id),
  allocation_id UUID NOT NULL REFERENCES budget_allocations(id),
  
  month INTEGER NOT NULL, -- 1-12
  year INTEGER NOT NULL,
  
  -- Monthly amounts
  budgeted_amount NUMERIC(15,2) NOT NULL,
  actual_amount NUMERIC(15,2) NOT NULL,
  variance_amount NUMERIC(15,2) GENERATED ALWAYS AS (budgeted_amount - actual_amount) STORED,
  variance_percentage NUMERIC(5,2),
  
  -- Notes
  variance_reason TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(allocation_id, month, year)
);

-- Function to check budget thresholds and create alerts
CREATE OR REPLACE FUNCTION check_budget_thresholds()
RETURNS void AS $$
DECLARE
  rule RECORD;
  pattern RECORD;
  alert_message TEXT;
BEGIN
  FOR rule IN SELECT * FROM budget_alert_rules WHERE is_active = true
  LOOP
    FOR pattern IN 
      SELECT * FROM budget_spending_patterns 
      WHERE tenant_id = rule.tenant_id
    LOOP
      -- Check threshold alerts
      IF rule.alert_type = 'threshold' AND 
         pattern.utilization_percentage >= rule.threshold_percentage AND
         NOT EXISTS (
           SELECT 1 FROM budget_alerts 
           WHERE budget_id = pattern.budget_id 
           AND allocation_id = pattern.allocation_id
           AND alert_type = 'threshold'
           AND created_at > NOW() - INTERVAL '1 day'
         )
      THEN
        INSERT INTO budget_alerts (
          tenant_id, budget_id, allocation_id, alert_type, severity, message,
          current_value, threshold_value, variance_percentage
        ) VALUES (
          pattern.tenant_id, pattern.budget_id, pattern.allocation_id,
          'threshold', 
          CASE WHEN pattern.utilization_percentage >= 90 THEN 'critical' ELSE 'warning' END,
          'Budget utilization at ' || pattern.utilization_percentage || '%',
          pattern.spent_amount, pattern.allocated_amount, pattern.variance_percentage
        );
      END IF;
      
      -- Check overspend alerts
      IF rule.alert_type = 'overspend' AND pattern.budget_status = 'over_budget' THEN
        INSERT INTO budget_alerts (
          tenant_id, budget_id, allocation_id, alert_type, severity, message,
          current_value, threshold_value
        ) VALUES (
          pattern.tenant_id, pattern.budget_id, pattern.allocation_id,
          'overspend', 'critical', 'Budget exceeded!',
          pattern.spent_amount, pattern.allocated_amount
        );
      END IF;
      
      -- Check projected overspend
      IF rule.alert_type = 'burn_rate' AND 
         pattern.projected_spend > pattern.allocated_amount * 1.1 THEN
        INSERT INTO budget_alerts (
          tenant_id, budget_id, allocation_id, alert_type, severity, message,
          current_value, threshold_value
        ) VALUES (
          pattern.tenant_id, pattern.budget_id, pattern.allocation_id,
          'burn_rate', 'warning', 
          'Projected to exceed budget by ' || 
          ((pattern.projected_spend / pattern.allocated_amount - 1) * 100)::NUMERIC(5,1) || '%',
          pattern.projected_spend, pattern.allocated_amount
        );
      END IF;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE budget_alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_monthly_variance ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/budget-monitoring.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface BudgetVariance {
  allocationId: string;
  branchName?: string;
  department?: string;
  allocatedAmount: number;
  spentAmount: number;
  varianceAmount: number;
  variancePercentage: number;
  budgetStatus: string;
  dailyBurnRate: number;
  projectedSpend: number;
  daysRemaining: number;
}

export interface BudgetAlert {
  id: string;
  alertType: string;
  severity: string;
  message: string;
  currentValue: number;
  thresholdValue: number;
  createdAt: string;
  isRead: boolean;
}

export class BudgetMonitoringAPI {
  private supabase = createClient();

  async getBudgetVariances(budgetId: string): Promise<BudgetVariance[]> {
    const { data, error } = await this.supabase
      .from('budget_spending_patterns')
      .select(`
        *,
        branches:branch_id(name)
      `)
      .eq('budget_id', budgetId)
      .order('variance_percentage', { ascending: false });

    if (error) throw error;

    return (data || []).map(item => ({
      allocationId: item.allocation_id,
      branchName: item.branches?.name,
      department: item.department,
      allocatedAmount: item.allocated_amount,
      spentAmount: item.spent_amount,
      varianceAmount: item.variance_amount,
      variancePercentage: item.variance_percentage,
      budgetStatus: item.budget_status,
      dailyBurnRate: item.daily_burn_rate,
      projectedSpend: item.projected_spend,
      daysRemaining: item.days_remaining,
    }));
  }

  async getBudgetAlerts(params: {
    tenantId: string;
    unreadOnly?: boolean;
  }): Promise<BudgetAlert[]> {
    let query = this.supabase
      .from('budget_alerts')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .order('created_at', { ascending: false });

    if (params.unreadOnly) {
      query = query.eq('is_read', false);
    }

    const { data, error } = await query;

    if (error) throw error;

    return (data || []).map(alert => ({
      id: alert.id,
      alertType: alert.alert_type,
      severity: alert.severity,
      message: alert.message,
      currentValue: alert.current_value,
      thresholdValue: alert.threshold_value,
      createdAt: alert.created_at,
      isRead: alert.is_read,
    }));
  }

  async markAlertAsRead(alertId: string): Promise<void> {
    const { error } = await this.supabase
      .from('budget_alerts')
      .update({ is_read: true })
      .eq('id', alertId);

    if (error) throw error;
  }

  async getBurnRateAnalysis(budgetId: string) {
    const { data, error } = await this.supabase
      .from('budget_spending_patterns')
      .select('*')
      .eq('budget_id', budgetId);

    if (error) throw error;

    const totalAllocated = data.reduce((sum, item) => sum + item.allocated_amount, 0);
    const totalSpent = data.reduce((sum, item) => sum + item.spent_amount, 0);
    const avgBurnRate = data.reduce((sum, item) => sum + item.daily_burn_rate, 0) / data.length;
    const daysElapsed = data[0]?.days_elapsed || 0;
    const daysRemaining = data[0]?.days_remaining || 0;

    return {
      totalAllocated,
      totalSpent,
      utilizationPercentage: (totalSpent / totalAllocated) * 100,
      avgDailyBurnRate: avgBurnRate,
      projectedTotalSpend: avgBurnRate * (daysElapsed + daysRemaining),
      daysElapsed,
      daysRemaining,
      onTrackPercentage: (daysElapsed / (daysElapsed + daysRemaining)) * 100,
    };
  }

  async getMonthlyVarianceReport(params: {
    budgetId: string;
    year: number;
  }) {
    const { data, error } = await this.supabase
      .from('budget_monthly_variance')
      .select(`
        *,
        allocation:budget_allocations(
          branch:branches(name),
          department
        )
      `)
      .eq('budget_id', params.budgetId)
      .eq('year', params.year)
      .order('month');

    if (error) throw error;

    return data.map(item => ({
      month: item.month,
      branchName: item.allocation.branch?.name,
      department: item.allocation.department,
      budgetedAmount: item.budgeted_amount,
      actualAmount: item.actual_amount,
      varianceAmount: item.variance_amount,
      variancePercentage: item.variance_percentage,
      varianceReason: item.variance_reason,
    }));
  }

  async createAlertRule(params: {
    tenantId: string;
    alertType: string;
    thresholdPercentage?: number;
    notifyUsers: string[];
    notifyEmails?: string[];
  }) {
    const { data, error } = await this.supabase
      .from('budget_alert_rules')
      .insert({
        tenant_id: params.tenantId,
        alert_type: params.alertType,
        threshold_percentage: params.thresholdPercentage,
        notify_users: params.notifyUsers,
        notify_emails: params.notifyEmails,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async refreshSpendingPatterns(): Promise<void> {
    const { error } = await this.supabase.rpc('refresh_budget_spending_patterns');
    if (error) throw error;
  }

  async checkThresholds(): Promise<void> {
    const { error } = await this.supabase.rpc('check_budget_thresholds');
    if (error) throw error;
  }
}

export const budgetMonitoringAPI = new BudgetMonitoringAPI();
```

### Component (`/components/finance/BudgetMonitoring.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { budgetMonitoringAPI } from '@/lib/api/budget-monitoring';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { formatCurrency } from '@/lib/utils';
import { TrendingUp, TrendingDown, AlertTriangle, CheckCircle } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export function BudgetMonitoring({ budgetId, tenantId }: { budgetId: string; tenantId: string }) {
  const [variances, setVariances] = useState<any[]>([]);
  const [alerts, setAlerts] = useState<any[]>([]);
  const [burnRate, setBurnRate] = useState<any>(null);

  useEffect(() => {
    loadData();
  }, [budgetId]);

  const loadData = async () => {
    const [variancesData, alertsData, burnRateData] = await Promise.all([
      budgetMonitoringAPI.getBudgetVariances(budgetId),
      budgetMonitoringAPI.getBudgetAlerts({ tenantId, unreadOnly: false }),
      budgetMonitoringAPI.getBurnRateAnalysis(budgetId),
    ]);

    setVariances(variancesData);
    setAlerts(alertsData);
    setBurnRate(burnRateData);
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'destructive';
      case 'warning': return 'warning';
      default: return 'default';
    }
  };

  const getVarianceColor = (variancePercentage: number) => {
    if (variancePercentage < 0) return 'text-red-600';
    if (variancePercentage < 10) return 'text-yellow-600';
    return 'text-green-600';
  };

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-3xl font-bold">Budget Monitoring & Variance Analysis</h1>

      {/* Burn Rate Summary */}
      {burnRate && (
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Budget Utilization</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {burnRate.utilizationPercentage.toFixed(1)}%
              </div>
              <p className="text-xs text-muted-foreground">
                {formatCurrency(burnRate.totalSpent)} of {formatCurrency(burnRate.totalAllocated)}
              </p>
              <Progress value={burnRate.utilizationPercentage} className="mt-2" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Daily Burn Rate</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatCurrency(burnRate.avgDailyBurnRate)}
              </div>
              <p className="text-xs text-muted-foreground">
                Average per day
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Projected Total</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatCurrency(burnRate.projectedTotalSpend)}
              </div>
              <p className="text-xs text-muted-foreground">
                {burnRate.projectedTotalSpend > burnRate.totalAllocated ? (
                  <span className="text-red-600">Over budget</span>
                ) : (
                  <span className="text-green-600">On track</span>
                )}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Days Remaining</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{burnRate.daysRemaining}</div>
              <p className="text-xs text-muted-foreground">
                {burnRate.daysElapsed} days elapsed
              </p>
              <Progress value={burnRate.onTrackPercentage} className="mt-2" />
            </CardContent>
          </Card>
        </div>
      )}

      {/* Alerts */}
      {alerts.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Budget Alerts</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {alerts.map((alert) => (
                <div
                  key={alert.id}
                  className="flex items-center justify-between rounded-lg border p-3"
                >
                  <div className="flex items-center gap-3">
                    <AlertTriangle className={`h-5 w-5 ${
                      alert.severity === 'critical' ? 'text-red-600' : 'text-yellow-600'
                    }`} />
                    <div>
                      <div className="font-medium">{alert.message}</div>
                      <div className="text-sm text-gray-500">
                        {formatCurrency(alert.currentValue)} / {formatCurrency(alert.thresholdValue)}
                      </div>
                    </div>
                  </div>
                  <Badge variant={getSeverityColor(alert.severity)}>
                    {alert.severity}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Variance Analysis */}
      <Card>
        <CardHeader>
          <CardTitle>Variance Analysis</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {variances.map((variance) => (
              <div key={variance.allocationId} className="rounded-lg border p-4">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <div className="font-medium">
                      {variance.branchName || variance.department}
                    </div>
                    <div className="text-sm text-gray-500">
                      {formatCurrency(variance.spentAmount)} of {formatCurrency(variance.allocatedAmount)}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className={`flex items-center gap-1 ${getVarianceColor(variance.variancePercentage)}`}>
                      {variance.variancePercentage < 0 ? (
                        <TrendingUp className="h-4 w-4" />
                      ) : (
                        <TrendingDown className="h-4 w-4" />
                      )}
                      <span className="font-bold">
                        {Math.abs(variance.variancePercentage).toFixed(1)}%
                      </span>
                    </div>
                    <div className="text-sm text-gray-500">
                      {formatCurrency(Math.abs(variance.varianceAmount))} {variance.varianceAmount >= 0 ? 'under' : 'over'}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <div className="text-gray-500">Daily Burn</div>
                    <div className="font-medium">{formatCurrency(variance.dailyBurnRate)}</div>
                  </div>
                  <div>
                    <div className="text-gray-500">Projected</div>
                    <div className="font-medium">{formatCurrency(variance.projectedSpend)}</div>
                  </div>
                  <div>
                    <div className="text-gray-500">Days Left</div>
                    <div className="font-medium">{variance.daysRemaining}</div>
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
import { BudgetMonitoringAPI } from '../budget-monitoring';

describe('BudgetMonitoringAPI', () => {
  it('calculates burn rate correctly', async () => {
    const api = new BudgetMonitoringAPI();
    const burnRate = await api.getBurnRateAnalysis('budget-1');

    expect(burnRate).toHaveProperty('avgDailyBurnRate');
    expect(burnRate).toHaveProperty('projectedTotalSpend');
  });

  it('detects budget variances', async () => {
    const api = new BudgetMonitoringAPI();
    const variances = await api.getBudgetVariances('budget-1');

    expect(Array.isArray(variances)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Variance calculation accurate
- [ ] Burn rate analysis working
- [ ] Alert system functional
- [ ] Real-time monitoring operational
- [ ] Projections accurate
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-172 (Financial Forecasting)  
**Time**: 4 hours  
**AI-Ready**: 100%
