# SPEC-140: Churn Analysis and Prevention
## Customer Retention Analytics and Win-back Campaigns

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-131, SPEC-127, Phase 1

---

## 📋 OVERVIEW

### Purpose
Advanced churn analysis system with predictive analytics, retention metrics, and automated win-back campaigns for reducing customer churn.

### Key Features
- ✅ Churn rate calculation
- ✅ Churn prediction models
- ✅ Cohort retention analysis
- ✅ At-risk customer identification
- ✅ Cancellation reason tracking
- ✅ Win-back campaign automation
- ✅ Retention metrics dashboard
- ✅ Exit surveys
- ✅ Reactivation offers
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Churn analytics table
CREATE TABLE churn_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
  churn_risk_score DECIMAL(5, 2) NOT NULL DEFAULT 0,
  risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  factors JSONB DEFAULT '[]'::jsonb,
  last_login_at TIMESTAMPTZ,
  days_since_last_login INTEGER,
  payment_failures INTEGER DEFAULT 0,
  support_tickets INTEGER DEFAULT 0,
  feature_usage_score DECIMAL(5, 2) DEFAULT 0,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_churn_analytics_tenant ON churn_analytics(tenant_id);
CREATE INDEX idx_churn_analytics_risk ON churn_analytics(risk_level);

-- Cancellation reasons
CREATE TABLE cancellation_reasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  reason_category TEXT NOT NULL,
  reason_details TEXT,
  feedback TEXT,
  alternative_considered TEXT,
  would_recommend BOOLEAN,
  cancelled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Win-back campaigns
CREATE TABLE winback_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  target_segment TEXT NOT NULL,
  discount_code TEXT,
  email_template_id UUID,
  status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'paused', 'completed')) DEFAULT 'draft',
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Win-back campaign results
CREATE TABLE winback_campaign_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES winback_campaigns(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email_sent_at TIMESTAMPTZ,
  email_opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  reactivated_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('sent', 'opened', 'clicked', 'reactivated', 'ignored'))
);

-- Function to calculate churn risk
CREATE OR REPLACE FUNCTION calculate_churn_risk(p_tenant_id UUID)
RETURNS void AS $$
DECLARE
  v_last_login TIMESTAMPTZ;
  v_days_inactive INTEGER;
  v_payment_failures INTEGER;
  v_support_tickets INTEGER;
  v_risk_score DECIMAL(5, 2);
  v_risk_level TEXT;
  v_factors JSONB := '[]'::jsonb;
BEGIN
  -- Get last login
  SELECT MAX(created_at) INTO v_last_login
  FROM platform_activity_log
  WHERE tenant_id = p_tenant_id
    AND action = 'user_login';

  v_days_inactive := COALESCE(EXTRACT(DAY FROM NOW() - v_last_login), 999);

  -- Count payment failures (last 30 days)
  SELECT COUNT(*) INTO v_payment_failures
  FROM payment_transactions
  WHERE tenant_id = p_tenant_id
    AND status = 'failed'
    AND created_at >= NOW() - INTERVAL '30 days';

  -- Count support tickets (last 30 days)
  SELECT COUNT(*) INTO v_support_tickets
  FROM support_tickets
  WHERE tenant_id = p_tenant_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- Calculate risk score (0-100)
  v_risk_score := 0;

  -- Factor: Inactivity (max 40 points)
  IF v_days_inactive > 30 THEN
    v_risk_score := v_risk_score + 40;
    v_factors := v_factors || jsonb_build_object('factor', 'high_inactivity', 'days', v_days_inactive);
  ELSIF v_days_inactive > 14 THEN
    v_risk_score := v_risk_score + 20;
    v_factors := v_factors || jsonb_build_object('factor', 'moderate_inactivity', 'days', v_days_inactive);
  END IF;

  -- Factor: Payment failures (max 30 points)
  IF v_payment_failures > 2 THEN
    v_risk_score := v_risk_score + 30;
    v_factors := v_factors || jsonb_build_object('factor', 'payment_failures', 'count', v_payment_failures);
  ELSIF v_payment_failures > 0 THEN
    v_risk_score := v_risk_score + 15;
    v_factors := v_factors || jsonb_build_object('factor', 'payment_issues', 'count', v_payment_failures);
  END IF;

  -- Factor: Support tickets (max 30 points)
  IF v_support_tickets > 5 THEN
    v_risk_score := v_risk_score + 30;
    v_factors := v_factors || jsonb_build_object('factor', 'high_support_volume', 'count', v_support_tickets);
  ELSIF v_support_tickets > 2 THEN
    v_risk_score := v_risk_score + 15;
    v_factors := v_factors || jsonb_build_object('factor', 'support_issues', 'count', v_support_tickets);
  END IF;

  -- Determine risk level
  IF v_risk_score >= 70 THEN
    v_risk_level := 'critical';
  ELSIF v_risk_score >= 50 THEN
    v_risk_level := 'high';
  ELSIF v_risk_score >= 30 THEN
    v_risk_level := 'medium';
  ELSE
    v_risk_level := 'low';
  END IF;

  -- Insert or update churn analytics
  INSERT INTO churn_analytics (
    tenant_id,
    churn_risk_score,
    risk_level,
    factors,
    last_login_at,
    days_since_last_login,
    payment_failures,
    support_tickets
  ) VALUES (
    p_tenant_id,
    v_risk_score,
    v_risk_level,
    v_factors,
    v_last_login,
    v_days_inactive,
    v_payment_failures,
    v_support_tickets
  )
  ON CONFLICT (tenant_id) DO UPDATE SET
    churn_risk_score = EXCLUDED.churn_risk_score,
    risk_level = EXCLUDED.risk_level,
    factors = EXCLUDED.factors,
    last_login_at = EXCLUDED.last_login_at,
    days_since_last_login = EXCLUDED.days_since_last_login,
    payment_failures = EXCLUDED.payment_failures,
    support_tickets = EXCLUDED.support_tickets,
    calculated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔌 API ENDPOINTS

### GET /api/platform/churn/analytics
**Get churn analytics dashboard**
```typescript
interface ChurnAnalyticsRequest {
  dateRange?: {
    from: string;
    to: string;
  };
  segment?: 'all' | 'high-risk' | 'at-risk' | 'stable';
}

interface ChurnAnalyticsResponse {
  overview: {
    totalTenants: number;
    churnedThisMonth: number;
    churnRate: number;
    riskDistribution: {
      low: number;
      medium: number;
      high: number;
      critical: number;
    };
  };
  trends: Array<{
    date: string;
    churnRate: number;
    newChurn: number;
    prevented: number;
  }>;
  topRiskFactors: Array<{
    factor: string;
    count: number;
    impact: number;
  }>;
}
```

### GET /api/platform/churn/at-risk
**Get at-risk customers**
```typescript
interface AtRiskRequest {
  page?: number;
  limit?: number;
  riskLevel?: 'medium' | 'high' | 'critical';
  sortBy?: 'risk_score' | 'last_login' | 'tenant_name';
  sortOrder?: 'asc' | 'desc';
}

interface AtRiskResponse {
  tenants: Array<{
    id: string;
    name: string;
    riskScore: number;
    riskLevel: 'medium' | 'high' | 'critical';
    factors: Array<{
      factor: string;
      details: any;
    }>;
    lastLogin: string | null;
    daysSinceLastLogin: number | null;
    subscriptionPlan: string;
    mrr: number;
    paymentFailures: number;
    supportTickets: number;
  }>;
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

### POST /api/platform/churn/recalculate
**Recalculate churn risk for all tenants**
```typescript
interface RecalculateRequest {
  tenantIds?: string[]; // Optional: specific tenants
}

interface RecalculateResponse {
  success: boolean;
  processed: number;
  errors: Array<{
    tenantId: string;
    error: string;
  }>;
}
```

### GET /api/platform/churn/cohorts
**Get cohort retention analysis**
```typescript
interface CohortAnalysisRequest {
  startDate?: string;
  endDate?: string;
  groupBy?: 'month' | 'quarter';
}

interface CohortAnalysisResponse {
  cohorts: Array<{
    cohortPeriod: string;
    totalTenants: number;
    retentionRates: Array<{
      period: number;
      retained: number;
      rate: number;
    }>;
  }>;
}
```

### POST /api/platform/churn/winback-campaigns
**Create win-back campaign**
```typescript
interface CreateCampaignRequest {
  name: string;
  description?: string;
  targetSegment: 'churned_30_days' | 'churned_90_days' | 'at_risk_high' | 'at_risk_critical';
  discountCode?: string;
  emailTemplate: string;
  startDate: string;
  endDate?: string;
}

interface CreateCampaignResponse {
  id: string;
  estimatedTargets: number;
}
```

### GET /api/platform/churn/winback-campaigns
**Get win-back campaigns**
```typescript
interface WinbackCampaignsResponse {
  campaigns: Array<{
    id: string;
    name: string;
    description: string;
    targetSegment: string;
    status: 'draft' | 'active' | 'paused' | 'completed';
    startDate: string;
    endDate?: string;
    metrics: {
      sent: number;
      opened: number;
      clicked: number;
      reactivated: number;
      conversionRate: number;
    };
    createdAt: string;
  }>;
}
```

### POST /api/platform/churn/exit-survey
**Record exit survey response**
```typescript
interface ExitSurveyRequest {
  tenantId: string;
  reasonCategory: string;
  reasonDetails?: string;
  feedback?: string;
  alternativeConsidered?: string;
  wouldRecommend?: boolean;
}

interface ExitSurveyResponse {
  success: boolean;
  surveyId: string;
}
```

---

## 🎨 REACT COMPONENTS

### ChurnAnalyticsDashboard
**Main churn analytics dashboard**
```typescript
interface ChurnAnalyticsDashboardProps {
  initialData?: ChurnAnalyticsResponse;
}

const ChurnAnalyticsDashboard: React.FC<ChurnAnalyticsDashboardProps> = ({
  initialData
}) => {
  const [analytics, setAnalytics] = useState<ChurnAnalyticsResponse | null>(initialData || null);
  const [loading, setLoading] = useState(!initialData);
  const [dateRange, setDateRange] = useState({
    from: subDays(new Date(), 30),
    to: new Date()
  });

  const fetchAnalytics = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/platform/churn/analytics', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          dateRange: {
            from: format(dateRange.from, 'yyyy-MM-dd'),
            to: format(dateRange.to, 'yyyy-MM-dd')
          }
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        setAnalytics(data);
      }
    } catch (error) {
      toast.error('Failed to load churn analytics');
    } finally {
      setLoading(false);
    }
  }, [dateRange]);

  useEffect(() => {
    if (!initialData) {
      fetchAnalytics();
    }
  }, [fetchAnalytics, initialData]);

  if (loading && !analytics) {
    return <ChurnAnalyticsSkeletion />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Churn Analytics</h1>
          <p className="text-sm text-gray-500">
            Customer retention metrics and churn prevention insights
          </p>
        </div>
        
        <div className="flex items-center space-x-4">
          <DateRangePicker
            value={dateRange}
            onChange={setDateRange}
          />
          <Button
            onClick={() => window.location.reload()}
            variant="outline"
            size="sm"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      {analytics && (
        <>
          {/* Overview Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <StatsCard
              title="Total Customers"
              value={analytics.overview.totalTenants}
              icon={Users}
              trend={{
                value: 0,
                label: "vs last month"
              }}
            />
            <StatsCard
              title="Churned This Month"
              value={analytics.overview.churnedThisMonth}
              icon={TrendingDown}
              className="text-red-600"
              trend={{
                value: -12,
                label: "vs last month",
                isPositive: false
              }}
            />
            <StatsCard
              title="Churn Rate"
              value={`${analytics.overview.churnRate.toFixed(1)}%`}
              icon={Percent}
              trend={{
                value: -2.3,
                label: "vs last month",
                isPositive: false
              }}
            />
            <StatsCard
              title="At Risk Customers"
              value={analytics.overview.riskDistribution.high + analytics.overview.riskDistribution.critical}
              icon={AlertTriangle}
              className="text-orange-600"
            />
          </div>

          {/* Risk Distribution */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <PieChart className="h-5 w-5 mr-2" />
                Risk Distribution
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ChurnRiskDistributionChart
                data={analytics.overview.riskDistribution}
              />
            </CardContent>
          </Card>

          {/* Churn Trends */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <TrendingDown className="h-5 w-5 mr-2" />
                Churn Trends
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ChurnTrendChart
                data={analytics.trends}
                height={300}
              />
            </CardContent>
          </Card>

          {/* Top Risk Factors */}
          <Card>
            <CardHeader>
              <CardTitle>Top Risk Factors</CardTitle>
              <CardDescription>
                Primary factors contributing to customer churn
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {analytics.topRiskFactors.map((factor, index) => (
                  <div key={factor.factor} className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-6 h-6 rounded-full bg-red-100 flex items-center justify-center">
                        <span className="text-xs font-medium text-red-600">{index + 1}</span>
                      </div>
                      <span className="font-medium capitalize">
                        {factor.factor.replace('_', ' ')}
                      </span>
                    </div>
                    <div className="text-right">
                      <p className="font-medium">{factor.count} customers</p>
                      <p className="text-xs text-gray-500">
                        {factor.impact.toFixed(1)}% impact
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
};
```

### AtRiskCustomersList
**List of at-risk customers for intervention**
```typescript
interface AtRiskCustomersListProps {
  onSelectCustomer?: (customerId: string) => void;
}

const AtRiskCustomersList: React.FC<AtRiskCustomersListProps> = ({
  onSelectCustomer
}) => {
  const [customers, setCustomers] = useState<AtRiskResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    riskLevel: undefined as 'medium' | 'high' | 'critical' | undefined,
    page: 1,
    limit: 20,
    sortBy: 'risk_score' as const,
    sortOrder: 'desc' as const
  });

  const fetchAtRiskCustomers = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined) {
          params.append(key, value.toString());
        }
      });

      const response = await fetch(`/api/platform/churn/at-risk?${params}`);
      if (response.ok) {
        const data = await response.json();
        setCustomers(data);
      }
    } catch (error) {
      toast.error('Failed to load at-risk customers');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    fetchAtRiskCustomers();
  }, [fetchAtRiskCustomers]);

  const getRiskLevelColor = (level: string) => {
    switch (level) {
      case 'critical': return 'text-red-600 bg-red-50';
      case 'high': return 'text-orange-600 bg-orange-50';
      case 'medium': return 'text-yellow-600 bg-yellow-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-gray-900">At-Risk Customers</h2>
          <p className="text-sm text-gray-500">
            Customers requiring immediate attention to prevent churn
          </p>
        </div>
        
        <div className="flex items-center space-x-2">
          <Select
            value={filters.riskLevel || 'all'}
            onValueChange={(value) => setFilters(prev => ({
              ...prev,
              riskLevel: value === 'all' ? undefined : value as any,
              page: 1
            }))}
          >
            <SelectTrigger className="w-40">
              <SelectValue placeholder="Risk Level" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Risk Levels</SelectItem>
              <SelectItem value="medium">Medium Risk</SelectItem>
              <SelectItem value="high">High Risk</SelectItem>
              <SelectItem value="critical">Critical Risk</SelectItem>
            </SelectContent>
          </Select>
          
          <Button
            onClick={fetchAtRiskCustomers}
            variant="outline"
            size="sm"
          >
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Customers Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Customer</TableHead>
                <TableHead>Risk Level</TableHead>
                <TableHead>Risk Score</TableHead>
                <TableHead>Last Login</TableHead>
                <TableHead>MRR</TableHead>
                <TableHead>Key Factors</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 7 }).map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton className="h-4 w-full" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : customers?.tenants.map((customer) => (
                <TableRow key={customer.id}>
                  <TableCell>
                    <div>
                      <p className="font-medium">{customer.name}</p>
                      <p className="text-sm text-gray-500">{customer.subscriptionPlan}</p>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge className={getRiskLevelColor(customer.riskLevel)}>
                      {customer.riskLevel.charAt(0).toUpperCase() + customer.riskLevel.slice(1)}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center space-x-2">
                      <span className="font-medium">{customer.riskScore}</span>
                      <div className="w-16 bg-gray-200 rounded-full h-2">
                        <div 
                          className={`h-2 rounded-full ${
                            customer.riskScore >= 70 ? 'bg-red-500' :
                            customer.riskScore >= 50 ? 'bg-orange-500' :
                            customer.riskScore >= 30 ? 'bg-yellow-500' :
                            'bg-green-500'
                          }`}
                          style={{ width: `${customer.riskScore}%` }}
                        />
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    {customer.lastLogin ? (
                      <div>
                        <p>{format(new Date(customer.lastLogin), 'MMM dd, yyyy')}</p>
                        <p className="text-xs text-gray-500">
                          {customer.daysSinceLastLogin} days ago
                        </p>
                      </div>
                    ) : (
                      <span className="text-gray-400">Never</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <span className="font-medium">${customer.mrr}</span>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {customer.factors.slice(0, 2).map((factor, index) => (
                        <Badge key={index} variant="outline" className="text-xs">
                          {factor.factor.replace('_', ' ')}
                        </Badge>
                      ))}
                      {customer.factors.length > 2 && (
                        <Badge variant="outline" className="text-xs">
                          +{customer.factors.length - 2}
                        </Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => onSelectCustomer?.(customer.id)}
                      >
                        <MessageSquare className="h-4 w-4 mr-1" />
                        Contact
                      </Button>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem>
                            <User className="h-4 w-4 mr-2" />
                            View Profile
                          </DropdownMenuItem>
                          <DropdownMenuItem>
                            <Gift className="h-4 w-4 mr-2" />
                            Send Offer
                          </DropdownMenuItem>
                          <DropdownMenuItem>
                            <Phone className="h-4 w-4 mr-2" />
                            Schedule Call
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {customers && (
            <div className="px-6 py-4 border-t">
              <TablePagination
                pagination={customers.pagination}
                onPageChange={(page) => setFilters(prev => ({ ...prev, page }))}
                onLimitChange={(limit) => setFilters(prev => ({ ...prev, limit, page: 1 }))}
              />
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};
```

### CohortRetentionChart
**Cohort analysis visualization**
```typescript
interface CohortRetentionChartProps {
  data: CohortAnalysisResponse;
}

const CohortRetentionChart: React.FC<CohortRetentionChartProps> = ({ data }) => {
  const [selectedMetric, setSelectedMetric] = useState<'rate' | 'count'>('rate');

  const chartData = data.cohorts.map(cohort => {
    const dataPoint: any = {
      cohort: cohort.cohortPeriod,
      totalTenants: cohort.totalTenants
    };
    
    cohort.retentionRates.forEach((retention, index) => {
      const key = `period_${retention.period}`;
      dataPoint[key] = selectedMetric === 'rate' 
        ? retention.rate 
        : retention.retained;
    });
    
    return dataPoint;
  });

  const maxPeriods = Math.max(...data.cohorts.map(c => c.retentionRates.length));
  const colors = [
    '#10b981', '#059669', '#047857', '#065f46',
    '#f59e0b', '#d97706', '#b45309', '#92400e',
    '#ef4444', '#dc2626', '#b91c1c', '#991b1b'
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-medium">Cohort Retention Analysis</h3>
        <div className="flex items-center space-x-2">
          <span className="text-sm text-gray-500">Show:</span>
          <Select
            value={selectedMetric}
            onValueChange={(value: 'rate' | 'count') => setSelectedMetric(value)}
          >
            <SelectTrigger className="w-32">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="rate">Retention %</SelectItem>
              <SelectItem value="count">Customer Count</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="h-80">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis 
              dataKey="cohort" 
              tick={{ fontSize: 12 }}
            />
            <YAxis 
              tick={{ fontSize: 12 }}
              tickFormatter={(value) => 
                selectedMetric === 'rate' ? `${value}%` : value.toString()
              }
            />
            <Tooltip 
              formatter={(value, name) => [
                selectedMetric === 'rate' ? `${value}%` : value,
                `Period ${name.replace('period_', '')}`
              ]}
              labelFormatter={(label) => `Cohort: ${label}`}
            />
            <Legend />
            
            {Array.from({ length: maxPeriods }, (_, i) => (
              <Line
                key={i}
                type="monotone"
                dataKey={`period_${i}`}
                stroke={colors[i % colors.length]}
                strokeWidth={2}
                dot={{ r: 4 }}
                name={`Period ${i}`}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Cohort Table */}
      <div className="mt-6 overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Cohort
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Size
              </th>
              {Array.from({ length: maxPeriods }, (_, i) => (
                <th key={i} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Period {i}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {data.cohorts.map((cohort) => (
              <tr key={cohort.cohortPeriod}>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {cohort.cohortPeriod}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {cohort.totalTenants}
                </td>
                {Array.from({ length: maxPeriods }, (_, i) => {
                  const retention = cohort.retentionRates.find(r => r.period === i);
                  return (
                    <td key={i} className="px-6 py-4 whitespace-nowrap text-sm">
                      {retention ? (
                        <div className="flex items-center space-x-2">
                          <span className={`px-2 py-1 rounded text-xs ${
                            retention.rate >= 90 ? 'bg-green-100 text-green-800' :
                            retention.rate >= 70 ? 'bg-yellow-100 text-yellow-800' :
                            retention.rate >= 50 ? 'bg-orange-100 text-orange-800' :
                            'bg-red-100 text-red-800'
                          }`}>
                            {retention.rate.toFixed(1)}%
                          </span>
                          <span className="text-gray-400">
                            ({retention.retained})
                          </span>
                        </div>
                      ) : (
                        <span className="text-gray-300">-</span>
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
```

### WinbackCampaignManager
**Win-back campaign management**
```typescript
interface WinbackCampaignManagerProps {
  campaigns?: WinbackCampaignsResponse;
}

const WinbackCampaignManager: React.FC<WinbackCampaignManagerProps> = ({
  campaigns: initialCampaigns
}) => {
  const [campaigns, setCampaigns] = useState(initialCampaigns?.campaigns || []);
  const [loading, setLoading] = useState(!initialCampaigns);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedCampaign, setSelectedCampaign] = useState<string | null>(null);

  const fetchCampaigns = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/platform/churn/winback-campaigns');
      if (response.ok) {
        const data = await response.json();
        setCampaigns(data.campaigns);
      }
    } catch (error) {
      toast.error('Failed to load campaigns');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!initialCampaigns) {
      fetchCampaigns();
    }
  }, [fetchCampaigns, initialCampaigns]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'paused': return 'bg-yellow-100 text-yellow-800';
      case 'completed': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-gray-900">Win-back Campaigns</h2>
          <p className="text-sm text-gray-500">
            Automated campaigns to re-engage churned customers
          </p>
        </div>
        
        <Button onClick={() => setShowCreateDialog(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Create Campaign
        </Button>
      </div>

      {/* Campaigns Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {campaigns.map((campaign) => (
          <Card key={campaign.id} className="hover:shadow-md transition-shadow">
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">{campaign.name}</CardTitle>
                <Badge className={getStatusColor(campaign.status)}>
                  {campaign.status.charAt(0).toUpperCase() + campaign.status.slice(1)}
                </Badge>
              </div>
              <CardDescription className="text-sm">
                {campaign.description}
              </CardDescription>
            </CardHeader>
            
            <CardContent className="space-y-4">
              {/* Campaign Stats */}
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center">
                  <p className="text-2xl font-bold text-blue-600">{campaign.metrics.sent}</p>
                  <p className="text-xs text-gray-500">Sent</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-green-600">{campaign.metrics.reactivated}</p>
                  <p className="text-xs text-gray-500">Reactivated</p>
                </div>
              </div>

              {/* Conversion Rate */}
              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="text-sm text-gray-500">Conversion Rate</span>
                  <span className="text-sm font-medium">
                    {campaign.metrics.conversionRate.toFixed(1)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-green-500 h-2 rounded-full"
                    style={{ width: `${Math.min(campaign.metrics.conversionRate, 100)}%` }}
                  />
                </div>
              </div>

              {/* Actions */}
              <div className="flex items-center justify-between pt-2 border-t">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedCampaign(campaign.id)}
                >
                  <BarChart3 className="h-4 w-4 mr-1" />
                  Details
                </Button>
                
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm">
                      <MoreHorizontal className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem>
                      <Play className="h-4 w-4 mr-2" />
                      {campaign.status === 'paused' ? 'Resume' : 'Pause'}
                    </DropdownMenuItem>
                    <DropdownMenuItem>
                      <Edit className="h-4 w-4 mr-2" />
                      Edit
                    </DropdownMenuItem>
                    <DropdownMenuItem>
                      <Copy className="h-4 w-4 mr-2" />
                      Duplicate
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem className="text-red-600">
                      <Trash2 className="h-4 w-4 mr-2" />
                      Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Create Campaign Dialog */}
      <CreateWinbackCampaignDialog
        open={showCreateDialog}
        onOpenChange={setShowCreateDialog}
        onSuccess={() => {
          setShowCreateDialog(false);
          fetchCampaigns();
        }}
      />

      {/* Campaign Details Dialog */}
      {selectedCampaign && (
        <WinbackCampaignDetails
          campaignId={selectedCampaign}
          onClose={() => setSelectedCampaign(null)}
        />
      )}
    </div>
  );
};
```

---

## 📊 DASHBOARD LAYOUT

### ChurnAnalyticsPage
**Complete churn analytics page layout**
```typescript
const ChurnAnalyticsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState('overview');
  
  return (
    <div className="min-h-screen bg-gray-50">
      <PlatformHeader />
      
      <div className="flex">
        <PlatformSidebar />
        
        <main className="flex-1 p-6">
          <div className="max-w-7xl mx-auto space-y-6">
            {/* Page Header */}
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                Churn Analytics & Prevention
              </h1>
              <p className="text-gray-600">
                Monitor customer retention, identify at-risk accounts, and manage win-back campaigns
              </p>
            </div>

            {/* Navigation Tabs */}
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="border-b border-gray-200">
                <nav className="-mb-px flex space-x-8 px-6">
                  {[
                    { id: 'overview', name: 'Overview', icon: BarChart3 },
                    { id: 'at-risk', name: 'At-Risk Customers', icon: AlertTriangle },
                    { id: 'cohorts', name: 'Cohort Analysis', icon: Users },
                    { id: 'campaigns', name: 'Win-back Campaigns', icon: Target }
                  ].map((tab) => (
                    <button
                      key={tab.id}
                      onClick={() => setActiveTab(tab.id)}
                      className={`${
                        activeTab === tab.id
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center space-x-2`}
                    >
                      <tab.icon className="h-4 w-4" />
                      <span>{tab.name}</span>
                    </button>
                  ))}
                </nav>
              </div>

              <div className="p-6">
                {activeTab === 'overview' && <ChurnAnalyticsDashboard />}
                {activeTab === 'at-risk' && <AtRiskCustomersList />}
                {activeTab === 'cohorts' && <CohortAnalysisTab />}
                {activeTab === 'campaigns' && <WinbackCampaignManager />}
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};
```

---

## 🔒 SECURITY & VALIDATION

### Access Control
```typescript
// Middleware for platform admin access
export const requirePlatformAdmin = async (
  req: NextRequest,
  context: { params: any }
) => {
  const session = await getServerSession(authOptions);
  
  if (!session?.user?.platformRole || 
      !['super_admin', 'platform_admin', 'finance_manager'].includes(session.user.platformRole)) {
    return new NextResponse('Insufficient permissions', { status: 403 });
  }
  
  return NextResponse.next();
};

// RLS Policies for churn analytics
CREATE POLICY "Platform admins can view all churn analytics" ON churn_analytics
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
        AND u.platform_role IN ('super_admin', 'platform_admin', 'finance_manager')
    )
  );
```

### Input Validation
```typescript
// Churn analytics request validation
export const churnAnalyticsRequestSchema = z.object({
  dateRange: z.object({
    from: z.string().datetime(),
    to: z.string().datetime()
  }).optional(),
  segment: z.enum(['all', 'high-risk', 'at-risk', 'stable']).optional()
});

// Win-back campaign validation
export const createCampaignSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  targetSegment: z.enum(['churned_30_days', 'churned_90_days', 'at_risk_high', 'at_risk_critical']),
  discountCode: z.string().optional(),
  emailTemplate: z.string().min(1),
  startDate: z.string().datetime(),
  endDate: z.string().datetime().optional()
});
```

---

## ⚡ PERFORMANCE OPTIMIZATION

### Caching Strategy
```typescript
// Redis cache for churn metrics
const CACHE_KEYS = {
  CHURN_ANALYTICS: (dateRange: string) => `churn:analytics:${dateRange}`,
  AT_RISK_CUSTOMERS: (filters: string) => `churn:at-risk:${filters}`,
  COHORT_ANALYSIS: (period: string) => `churn:cohorts:${period}`
};

// Cache churn analytics for 1 hour
export async function getCachedChurnAnalytics(dateRange: string) {
  const cacheKey = CACHE_KEYS.CHURN_ANALYTICS(dateRange);
  
  try {
    const cached = await redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
  } catch (error) {
    console.warn('Cache miss for churn analytics:', error);
  }
  
  return null;
}

export async function setCachedChurnAnalytics(
  dateRange: string, 
  data: ChurnAnalyticsResponse
) {
  const cacheKey = CACHE_KEYS.CHURN_ANALYTICS(dateRange);
  
  try {
    await redis.setex(cacheKey, 3600, JSON.stringify(data)); // 1 hour TTL
  } catch (error) {
    console.warn('Failed to cache churn analytics:', error);
  }
}
```

### Database Optimization
```sql
-- Indexes for churn analytics performance
CREATE INDEX CONCURRENTLY idx_churn_analytics_tenant_calculated 
ON churn_analytics(tenant_id, calculated_at DESC);

CREATE INDEX CONCURRENTLY idx_churn_analytics_risk_level 
ON churn_analytics(risk_level, churn_risk_score DESC);

CREATE INDEX CONCURRENTLY idx_cancellation_reasons_tenant_date 
ON cancellation_reasons(tenant_id, cancelled_at DESC);

CREATE INDEX CONCURRENTLY idx_winback_campaigns_status_dates 
ON winback_campaigns(status, start_date, end_date);

-- Materialized view for churn trends
CREATE MATERIALIZED VIEW churn_trends_daily AS
SELECT 
  date_trunc('day', cancelled_at) as date,
  COUNT(*) as churned_count,
  COUNT(*) OVER (
    ORDER BY date_trunc('day', cancelled_at)
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) as churned_30_day_avg
FROM cancellation_reasons
GROUP BY date_trunc('day', cancelled_at)
ORDER BY date;

CREATE UNIQUE INDEX idx_churn_trends_daily_date ON churn_trends_daily(date);

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_churn_trends()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY churn_trends_daily;
END;
$$ LANGUAGE plpgsql;
```

---

## 🧪 TESTING SPECIFICATIONS

### Unit Tests
```typescript
// Test churn risk calculation
describe('Churn Risk Calculation', () => {
  test('calculates high risk for inactive customer with payment failures', () => {
    const factors = {
      daysSinceLastLogin: 45,
      paymentFailures: 3,
      supportTickets: 2
    };
    
    const risk = calculateChurnRisk(factors);
    
    expect(risk.score).toBeGreaterThan(70);
    expect(risk.level).toBe('critical');
    expect(risk.factors).toContain('high_inactivity');
    expect(risk.factors).toContain('payment_failures');
  });
  
  test('calculates low risk for active customer', () => {
    const factors = {
      daysSinceLastLogin: 2,
      paymentFailures: 0,
      supportTickets: 0
    };
    
    const risk = calculateChurnRisk(factors);
    
    expect(risk.score).toBeLessThan(30);
    expect(risk.level).toBe('low');
  });
});

// Test cohort analysis
describe('Cohort Analysis', () => {
  test('calculates retention rates correctly', () => {
    const cohortData = {
      startingCustomers: 100,
      retainedByPeriod: [90, 75, 65, 55, 50]
    };
    
    const rates = calculateRetentionRates(cohortData);
    
    expect(rates[0]).toBe(90); // 90% retained in period 0
    expect(rates[4]).toBe(50); // 50% retained in period 4
  });
});
```

### Integration Tests
```typescript
// Test churn analytics API
describe('Churn Analytics API', () => {
  test('returns analytics data for platform admin', async () => {
    const response = await request(app)
      .post('/api/platform/churn/analytics')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .send({
        dateRange: {
          from: '2025-09-01',
          to: '2025-10-01'
        }
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('overview');
    expect(response.body).toHaveProperty('trends');
    expect(response.body).toHaveProperty('topRiskFactors');
  });
  
  test('denies access to non-admin users', async () => {
    const response = await request(app)
      .post('/api/platform/churn/analytics')
      .set('Authorization', `Bearer ${tenantUserToken}`)
      .send({});
    
    expect(response.status).toBe(403);
  });
});
```

---

## 📝 DEPLOYMENT NOTES

### Environment Variables
```bash
# Churn analysis configuration
CHURN_CALCULATION_SCHEDULE="0 2 * * *"  # Daily at 2 AM
CHURN_RISK_THRESHOLDS_LOW=30
CHURN_RISK_THRESHOLDS_MEDIUM=50
CHURN_RISK_THRESHOLDS_HIGH=70
WINBACK_EMAIL_FROM="retention@platform.com"
COHORT_ANALYSIS_PERIODS=12
```

### Cron Jobs
```bash
# Daily churn risk calculation
0 2 * * * cd /app && npm run churn:calculate-risk

# Weekly cohort analysis refresh
0 3 * * 0 cd /app && npm run churn:refresh-cohorts

# Monthly win-back campaign cleanup
0 4 1 * * cd /app && npm run churn:cleanup-campaigns
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
