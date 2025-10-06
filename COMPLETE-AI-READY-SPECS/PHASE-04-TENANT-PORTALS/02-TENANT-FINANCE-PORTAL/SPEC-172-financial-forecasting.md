# SPEC-172: Financial Forecasting System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-172  
**Title**: Financial Forecasting & Predictive Analytics  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Financial Planning  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-168, SPEC-171  

---

## 📋 DESCRIPTION

Advanced financial forecasting system using historical data, trends, and predictive models. Features revenue/expense forecasting, cash flow projections, scenario planning, what-if analysis, and confidence intervals for data-driven financial decision making.

---

## 🎯 SUCCESS CRITERIA

- [ ] Revenue forecasting operational
- [ ] Expense prediction working
- [ ] Cash flow projection accurate
- [ ] Scenario planning functional
- [ ] What-if analysis available
- [ ] Confidence intervals calculated
- [ ] Export/visualization working
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Financial Forecasts
CREATE TABLE IF NOT EXISTS financial_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Forecast details
  forecast_name VARCHAR(200) NOT NULL,
  forecast_type VARCHAR(50) NOT NULL, -- revenue, expense, cash_flow, comprehensive
  forecast_period VARCHAR(20) NOT NULL, -- monthly, quarterly, yearly
  
  -- Time range
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  -- Model configuration
  model_type VARCHAR(50) DEFAULT 'linear_regression', -- linear_regression, moving_average, exponential_smoothing
  use_historical_data BOOLEAN DEFAULT true,
  historical_months INTEGER DEFAULT 12,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft',
  
  -- Metadata
  assumptions JSONB,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_forecast_type CHECK (forecast_type IN ('revenue', 'expense', 'cash_flow', 'comprehensive')),
  CONSTRAINT valid_dates CHECK (end_date > start_date)
);

-- Forecast Data Points
CREATE TABLE IF NOT EXISTS forecast_data_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_id UUID NOT NULL REFERENCES financial_forecasts(id) ON DELETE CASCADE,
  
  -- Period
  period_date DATE NOT NULL,
  period_label VARCHAR(50), -- "Q1 2025", "Jan 2025", etc.
  
  -- Forecasted values
  forecasted_amount NUMERIC(15,2) NOT NULL,
  lower_bound NUMERIC(15,2), -- Confidence interval lower
  upper_bound NUMERIC(15,2), -- Confidence interval upper
  confidence_level NUMERIC(5,2) DEFAULT 95, -- 95%
  
  -- Comparison
  actual_amount NUMERIC(15,2), -- Filled when period completes
  variance_amount NUMERIC(15,2),
  variance_percentage NUMERIC(5,2),
  
  -- Breakdown (optional)
  breakdown JSONB, -- {"tuition": 50000, "fees": 10000, ...}
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(forecast_id, period_date)
);

CREATE INDEX ON forecast_data_points(forecast_id, period_date);

-- Forecast Scenarios (What-if Analysis)
CREATE TABLE IF NOT EXISTS forecast_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  scenario_name VARCHAR(200) NOT NULL,
  description TEXT,
  
  -- Scenario type
  scenario_type VARCHAR(50) NOT NULL, -- optimistic, pessimistic, realistic, custom
  
  -- Adjustments
  revenue_adjustment_percentage NUMERIC(5,2) DEFAULT 0, -- +10%, -5%, etc.
  expense_adjustment_percentage NUMERIC(5,2) DEFAULT 0,
  growth_rate_adjustment NUMERIC(5,2) DEFAULT 0,
  
  -- Custom assumptions
  assumptions JSONB,
  
  is_baseline BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, scenario_name)
);

-- Scenario Results
CREATE TABLE IF NOT EXISTS scenario_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID NOT NULL REFERENCES forecast_scenarios(id) ON DELETE CASCADE,
  period_date DATE NOT NULL,
  
  -- Projected values
  revenue NUMERIC(15,2),
  expenses NUMERIC(15,2),
  net_income NUMERIC(15,2),
  cash_flow NUMERIC(15,2),
  
  -- Cumulative
  cumulative_revenue NUMERIC(15,2),
  cumulative_expenses NUMERIC(15,2),
  cumulative_net_income NUMERIC(15,2),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(scenario_id, period_date)
);

-- Historical Trend Analysis View
CREATE OR REPLACE VIEW historical_financial_trends AS
SELECT
  tenant_id,
  branch_id,
  DATE_TRUNC('month', transaction_date) as month,
  SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) as total_revenue,
  SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) as total_expenses,
  SUM(CASE WHEN transaction_type = 'income' THEN amount 
           WHEN transaction_type = 'expense' THEN -amount 
           ELSE 0 END) as net_income,
  COUNT(*) as transaction_count
FROM financial_transactions
WHERE transaction_date >= CURRENT_DATE - INTERVAL '24 months'
GROUP BY tenant_id, branch_id, DATE_TRUNC('month', transaction_date)
ORDER BY month DESC;

-- Function to calculate moving average forecast
CREATE OR REPLACE FUNCTION calculate_moving_average_forecast(
  p_tenant_id UUID,
  p_branch_id UUID,
  p_periods INTEGER DEFAULT 3,
  p_forecast_months INTEGER DEFAULT 12
)
RETURNS TABLE (
  forecast_date DATE,
  forecasted_amount NUMERIC,
  lower_bound NUMERIC,
  upper_bound NUMERIC
) AS $$
DECLARE
  v_avg NUMERIC;
  v_stddev NUMERIC;
  v_start_date DATE;
BEGIN
  -- Get historical average and standard deviation
  SELECT 
    AVG(total_revenue),
    STDDEV(total_revenue)
  INTO v_avg, v_stddev
  FROM (
    SELECT total_revenue 
    FROM historical_financial_trends
    WHERE tenant_id = p_tenant_id
    AND (branch_id = p_branch_id OR p_branch_id IS NULL)
    ORDER BY month DESC
    LIMIT p_periods
  ) recent;
  
  v_start_date := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';
  
  -- Generate forecast points
  FOR i IN 0..p_forecast_months-1 LOOP
    forecast_date := v_start_date + (i || ' months')::INTERVAL;
    forecasted_amount := v_avg;
    lower_bound := v_avg - (1.96 * v_stddev); -- 95% confidence
    upper_bound := v_avg + (1.96 * v_stddev);
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to apply scenario adjustments
CREATE OR REPLACE FUNCTION apply_scenario_adjustments(
  p_base_amount NUMERIC,
  p_scenario_id UUID
)
RETURNS NUMERIC AS $$
DECLARE
  v_adjustment NUMERIC;
BEGIN
  SELECT revenue_adjustment_percentage INTO v_adjustment
  FROM forecast_scenarios
  WHERE id = p_scenario_id;
  
  RETURN p_base_amount * (1 + v_adjustment / 100);
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE financial_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE forecast_data_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE forecast_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_results ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/financial-forecasting.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface Forecast {
  id: string;
  forecastName: string;
  forecastType: string;
  forecastPeriod: string;
  startDate: string;
  endDate: string;
  status: string;
}

export interface ForecastDataPoint {
  periodDate: string;
  periodLabel: string;
  forecastedAmount: number;
  lowerBound: number;
  upperBound: number;
  actualAmount?: number;
  variancePercentage?: number;
}

export interface Scenario {
  id: string;
  scenarioName: string;
  scenarioType: string;
  revenueAdjustment: number;
  expenseAdjustment: number;
}

export interface ScenarioResult {
  periodDate: string;
  revenue: number;
  expenses: number;
  netIncome: number;
  cashFlow: number;
}

export class FinancialForecastingAPI {
  private supabase = createClient();

  async createForecast(params: {
    tenantId: string;
    branchId?: string;
    forecastName: string;
    forecastType: string;
    forecastPeriod: string;
    startDate: Date;
    endDate: Date;
    modelType?: string;
    assumptions?: any;
  }): Promise<Forecast> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('financial_forecasts')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        forecast_name: params.forecastName,
        forecast_type: params.forecastType,
        forecast_period: params.forecastPeriod,
        start_date: params.startDate.toISOString().split('T')[0],
        end_date: params.endDate.toISOString().split('T')[0],
        model_type: params.modelType || 'moving_average',
        assumptions: params.assumptions,
        created_by: user?.id,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapForecast(data);
  }

  async generateForecastDataPoints(params: {
    forecastId: string;
    tenantId: string;
    branchId?: string;
    forecastMonths: number;
  }): Promise<ForecastDataPoint[]> {
    // Call moving average function
    const { data, error } = await this.supabase.rpc('calculate_moving_average_forecast', {
      p_tenant_id: params.tenantId,
      p_branch_id: params.branchId,
      p_periods: 3,
      p_forecast_months: params.forecastMonths,
    });

    if (error) throw error;

    // Insert forecast data points
    const dataPoints = data.map((point: any, index: number) => ({
      forecast_id: params.forecastId,
      period_date: point.forecast_date,
      period_label: this.formatPeriodLabel(new Date(point.forecast_date)),
      forecasted_amount: point.forecasted_amount,
      lower_bound: point.lower_bound,
      upper_bound: point.upper_bound,
      confidence_level: 95,
    }));

    const { error: insertError } = await this.supabase
      .from('forecast_data_points')
      .insert(dataPoints);

    if (insertError) throw insertError;

    return dataPoints.map(this.mapDataPoint);
  }

  async getForecastDataPoints(forecastId: string): Promise<ForecastDataPoint[]> {
    const { data, error } = await this.supabase
      .from('forecast_data_points')
      .select('*')
      .eq('forecast_id', forecastId)
      .order('period_date');

    if (error) throw error;
    return (data || []).map(this.mapDataPoint);
  }

  async createScenario(params: {
    tenantId: string;
    scenarioName: string;
    scenarioType: string;
    revenueAdjustment?: number;
    expenseAdjustment?: number;
    growthRateAdjustment?: number;
    assumptions?: any;
  }): Promise<Scenario> {
    const { data, error } = await this.supabase
      .from('forecast_scenarios')
      .insert({
        tenant_id: params.tenantId,
        scenario_name: params.scenarioName,
        scenario_type: params.scenarioType,
        revenue_adjustment_percentage: params.revenueAdjustment || 0,
        expense_adjustment_percentage: params.expenseAdjustment || 0,
        growth_rate_adjustment: params.growthRateAdjustment || 0,
        assumptions: params.assumptions,
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapScenario(data);
  }

  async generateScenarioResults(params: {
    scenarioId: string;
    baseRevenueForecast: ForecastDataPoint[];
    baseExpenseForecast: ForecastDataPoint[];
  }): Promise<ScenarioResult[]> {
    const { data: scenario } = await this.supabase
      .from('forecast_scenarios')
      .select('*')
      .eq('id', params.scenarioId)
      .single();

    if (!scenario) throw new Error('Scenario not found');

    const results = params.baseRevenueForecast.map((revPoint, index) => {
      const expPoint = params.baseExpenseForecast[index];
      
      const adjustedRevenue = revPoint.forecastedAmount * (1 + scenario.revenue_adjustment_percentage / 100);
      const adjustedExpenses = expPoint.forecastedAmount * (1 + scenario.expense_adjustment_percentage / 100);
      
      return {
        scenario_id: params.scenarioId,
        period_date: revPoint.periodDate,
        revenue: adjustedRevenue,
        expenses: adjustedExpenses,
        net_income: adjustedRevenue - adjustedExpenses,
        cash_flow: adjustedRevenue - adjustedExpenses, // Simplified
      };
    });

    // Calculate cumulative values
    let cumulativeRevenue = 0;
    let cumulativeExpenses = 0;
    let cumulativeNetIncome = 0;

    const resultsWithCumulative = results.map(result => {
      cumulativeRevenue += result.revenue;
      cumulativeExpenses += result.expenses;
      cumulativeNetIncome += result.net_income;

      return {
        ...result,
        cumulative_revenue: cumulativeRevenue,
        cumulative_expenses: cumulativeExpenses,
        cumulative_net_income: cumulativeNetIncome,
      };
    });

    const { error } = await this.supabase
      .from('scenario_results')
      .insert(resultsWithCumulative);

    if (error) throw error;

    return resultsWithCumulative.map(this.mapScenarioResult);
  }

  async getScenarioResults(scenarioId: string): Promise<ScenarioResult[]> {
    const { data, error } = await this.supabase
      .from('scenario_results')
      .select('*')
      .eq('scenario_id', scenarioId)
      .order('period_date');

    if (error) throw error;
    return (data || []).map(this.mapScenarioResult);
  }

  async compareScenarios(scenarioIds: string[]) {
    const results = await Promise.all(
      scenarioIds.map(id => this.getScenarioResults(id))
    );

    return results;
  }

  async getHistoricalTrends(params: {
    tenantId: string;
    branchId?: string;
    months?: number;
  }) {
    let query = this.supabase
      .from('historical_financial_trends')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .order('month', { ascending: false });

    if (params.branchId) {
      query = query.eq('branch_id', params.branchId);
    }

    if (params.months) {
      query = query.limit(params.months);
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map(item => ({
      month: item.month,
      revenue: item.total_revenue,
      expenses: item.total_expenses,
      netIncome: item.net_income,
      transactionCount: item.transaction_count,
    }));
  }

  async updateActualValues(params: {
    forecastId: string;
    periodDate: string;
    actualAmount: number;
  }): Promise<void> {
    const { data: forecast } = await this.supabase
      .from('forecast_data_points')
      .select('forecasted_amount')
      .eq('forecast_id', params.forecastId)
      .eq('period_date', params.periodDate)
      .single();

    if (!forecast) throw new Error('Forecast data point not found');

    const variance = params.actualAmount - forecast.forecasted_amount;
    const variancePercentage = (variance / forecast.forecasted_amount) * 100;

    const { error } = await this.supabase
      .from('forecast_data_points')
      .update({
        actual_amount: params.actualAmount,
        variance_amount: variance,
        variance_percentage: variancePercentage,
      })
      .eq('forecast_id', params.forecastId)
      .eq('period_date', params.periodDate);

    if (error) throw error;
  }

  private formatPeriodLabel(date: Date): string {
    const month = date.toLocaleString('default', { month: 'short' });
    const year = date.getFullYear();
    return `${month} ${year}`;
  }

  private mapForecast(data: any): Forecast {
    return {
      id: data.id,
      forecastName: data.forecast_name,
      forecastType: data.forecast_type,
      forecastPeriod: data.forecast_period,
      startDate: data.start_date,
      endDate: data.end_date,
      status: data.status,
    };
  }

  private mapDataPoint(data: any): ForecastDataPoint {
    return {
      periodDate: data.period_date,
      periodLabel: data.period_label,
      forecastedAmount: data.forecasted_amount,
      lowerBound: data.lower_bound,
      upperBound: data.upper_bound,
      actualAmount: data.actual_amount,
      variancePercentage: data.variance_percentage,
    };
  }

  private mapScenario(data: any): Scenario {
    return {
      id: data.id,
      scenarioName: data.scenario_name,
      scenarioType: data.scenario_type,
      revenueAdjustment: data.revenue_adjustment_percentage,
      expenseAdjustment: data.expense_adjustment_percentage,
    };
  }

  private mapScenarioResult(data: any): ScenarioResult {
    return {
      periodDate: data.period_date,
      revenue: data.revenue,
      expenses: data.expenses,
      netIncome: data.net_income,
      cashFlow: data.cash_flow,
    };
  }
}

export const financialForecastingAPI = new FinancialForecastingAPI();
```

### Component (`/components/finance/FinancialForecasting.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { financialForecastingAPI } from '@/lib/api/financial-forecasting';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatCurrency } from '@/lib/utils';
import { TrendingUp, TrendingDown } from 'lucide-react';
import {
  LineChart,
  Line,
  Area,
  AreaChart,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

export function FinancialForecasting({ tenantId }: { tenantId: string }) {
  const [forecast, setForecast] = useState<any>(null);
  const [dataPoints, setDataPoints] = useState<any[]>([]);
  const [scenarios, setScenarios] = useState<any[]>([]);
  const [selectedScenarios, setSelectedScenarios] = useState<string[]>([]);

  const createForecast = async () => {
    const newForecast = await financialForecastingAPI.createForecast({
      tenantId,
      forecastName: '2025 Revenue Forecast',
      forecastType: 'revenue',
      forecastPeriod: 'monthly',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-12-31'),
    });

    const points = await financialForecastingAPI.generateForecastDataPoints({
      forecastId: newForecast.id,
      tenantId,
      forecastMonths: 12,
    });

    setForecast(newForecast);
    setDataPoints(points);
  };

  const chartData = dataPoints.map(point => ({
    month: point.periodLabel,
    forecast: point.forecastedAmount,
    lower: point.lowerBound,
    upper: point.upperBound,
    actual: point.actualAmount,
  }));

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Financial Forecasting</h1>
        <Button onClick={createForecast}>Create Forecast</Button>
      </div>

      {dataPoints.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Revenue Forecast - Next 12 Months</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={400}>
              <AreaChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis tickFormatter={(value) => formatCurrency(value)} />
                <Tooltip formatter={(value: number) => formatCurrency(value)} />
                <Legend />
                <Area
                  type="monotone"
                  dataKey="upper"
                  stackId="1"
                  stroke="#93c5fd"
                  fill="#dbeafe"
                  name="Upper Bound"
                />
                <Area
                  type="monotone"
                  dataKey="forecast"
                  stackId="2"
                  stroke="#3b82f6"
                  fill="#3b82f6"
                  name="Forecast"
                />
                <Area
                  type="monotone"
                  dataKey="lower"
                  stackId="3"
                  stroke="#93c5fd"
                  fill="#dbeafe"
                  name="Lower Bound"
                />
                {chartData.some(d => d.actual) && (
                  <Line
                    type="monotone"
                    dataKey="actual"
                    stroke="#10b981"
                    strokeWidth={2}
                    name="Actual"
                    dot={{ r: 4 }}
                  />
                )}
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { FinancialForecastingAPI } from '../financial-forecasting';

describe('FinancialForecastingAPI', () => {
  it('creates forecast correctly', async () => {
    const api = new FinancialForecastingAPI();
    const forecast = await api.createForecast({
      tenantId: 'test-tenant',
      forecastName: 'Q1 2025',
      forecastType: 'revenue',
      forecastPeriod: 'monthly',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-03-31'),
    });

    expect(forecast).toHaveProperty('id');
  });

  it('generates forecast data points', async () => {
    const api = new FinancialForecastingAPI();
    const points = await api.generateForecastDataPoints({
      forecastId: 'forecast-1',
      tenantId: 'tenant-1',
      forecastMonths: 12,
    });

    expect(points.length).toBe(12);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Forecasting algorithms working
- [ ] Confidence intervals accurate
- [ ] Scenario planning functional
- [ ] Historical trends loaded
- [ ] Variance tracking operational
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-173 (Payroll Processing)  
**Time**: 4 hours  
**AI-Ready**: 100%
