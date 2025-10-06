# SPEC-138: Pricing Plans Management
## Dynamic Pricing Configuration and Plan Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-123, Phase 1

---

## 📋 OVERVIEW

### Purpose
Flexible pricing plan management system for creating, editing, and managing subscription plans with features, limits, and pricing tiers.

### Key Features
- ✅ Create/edit pricing plans
- ✅ Feature configuration per plan
- ✅ Usage limits management
- ✅ Multi-tier pricing
- ✅ Custom pricing for enterprises
- ✅ Promotional pricing
- ✅ Plan comparison tool
- ✅ Plan migration workflows
- ✅ Grandfathered plans
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Pricing plans table
CREATE TABLE pricing_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  
  -- Plan configuration
  plan_type TEXT NOT NULL CHECK (plan_type IN ('standard', 'enterprise', 'custom', 'trial')),
  billing_frequency TEXT NOT NULL CHECK (billing_frequency IN ('monthly', 'yearly', 'one_time')),
  
  -- Pricing
  price DECIMAL(12, 2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'USD',
  setup_fee DECIMAL(12, 2) DEFAULT 0,
  
  -- Trial settings
  trial_period_days INTEGER DEFAULT 0,
  trial_price DECIMAL(12, 2) DEFAULT 0,
  
  -- Usage limits
  max_students INTEGER,
  max_staff INTEGER,
  max_branches INTEGER,
  storage_limit_gb INTEGER,
  api_calls_limit INTEGER,
  
  -- Features matrix
  features JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- Availability
  is_active BOOLEAN DEFAULT TRUE,
  is_public BOOLEAN DEFAULT TRUE,
  is_grandfathered BOOLEAN DEFAULT FALSE,
  
  -- Ordering and display
  sort_order INTEGER DEFAULT 0,
  highlight_plan BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  stripe_price_id TEXT,
  stripe_product_id TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Plan features table (for complex feature configurations)
CREATE TABLE plan_features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES pricing_plans(id) ON DELETE CASCADE,
  feature_category TEXT NOT NULL, -- 'academic', 'administrative', 'reporting', etc.
  feature_name TEXT NOT NULL,
  feature_value TEXT, -- 'enabled', 'disabled', '100', 'unlimited', etc.
  feature_config JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Custom pricing table (enterprise/negotiated pricing)
CREATE TABLE custom_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  base_plan_id UUID REFERENCES pricing_plans(id),
  
  -- Custom pricing details
  custom_price DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  billing_frequency TEXT NOT NULL CHECK (billing_frequency IN ('monthly', 'yearly', 'one_time')),
  
  -- Custom limits
  custom_limits JSONB DEFAULT '{}'::jsonb,
  custom_features JSONB DEFAULT '{}'::jsonb,
  
  -- Contract details
  contract_start_date DATE NOT NULL,
  contract_end_date DATE,
  auto_renewal BOOLEAN DEFAULT FALSE,
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('draft', 'approved', 'active', 'expired')) DEFAULT 'draft',
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Plan migrations table (for tracking plan upgrades/downgrades)
CREATE TABLE plan_migrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Migration details
  from_plan_id UUID REFERENCES pricing_plans(id),
  to_plan_id UUID REFERENCES pricing_plans(id),
  migration_type TEXT NOT NULL CHECK (migration_type IN ('upgrade', 'downgrade', 'change')),
  
  -- Pricing changes
  old_price DECIMAL(12, 2),
  new_price DECIMAL(12, 2),
  price_difference DECIMAL(12, 2),
  proration_amount DECIMAL(12, 2) DEFAULT 0,
  
  -- Timing
  effective_date DATE NOT NULL,
  migration_reason TEXT,
  
  -- Processing
  status TEXT NOT NULL CHECK (status IN ('scheduled', 'processing', 'completed', 'failed', 'cancelled')) DEFAULT 'scheduled',
  processed_at TIMESTAMPTZ,
  error_message TEXT,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_pricing_plans_active_public ON pricing_plans(is_active, is_public, sort_order);
CREATE INDEX idx_plan_features_plan_category ON plan_features(plan_id, feature_category);
CREATE INDEX idx_custom_pricing_tenant ON custom_pricing(tenant_id, status);
CREATE INDEX idx_plan_migrations_subscription ON plan_migrations(subscription_id, status);

-- Function to calculate proration for plan changes
CREATE OR REPLACE FUNCTION calculate_proration(
  p_subscription_id UUID,
  p_new_plan_id UUID,
  p_effective_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
  v_subscription RECORD;
  v_current_plan RECORD;
  v_new_plan RECORD;
  v_days_remaining INTEGER;
  v_total_cycle_days INTEGER;
  v_current_daily_rate DECIMAL(12, 4);
  v_new_daily_rate DECIMAL(12, 4);
  v_proration_credit DECIMAL(12, 2);
  v_proration_charge DECIMAL(12, 2);
  v_net_proration DECIMAL(12, 2);
BEGIN
  -- Get subscription details
  SELECT s.*, pp.price as current_price, pp.billing_frequency
  INTO v_subscription
  FROM subscriptions s
  JOIN pricing_plans pp ON s.plan_id = pp.id
  WHERE s.id = p_subscription_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found';
  END IF;
  
  -- Get new plan details
  SELECT * INTO v_new_plan
  FROM pricing_plans
  WHERE id = p_new_plan_id AND is_active = TRUE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'New plan not found or inactive';
  END IF;
  
  -- Calculate days remaining in current cycle
  v_days_remaining := v_subscription.current_period_end::DATE - p_effective_date;
  
  -- Calculate total days in billing cycle
  IF v_subscription.billing_frequency = 'monthly' THEN
    v_total_cycle_days := 30;
  ELSIF v_subscription.billing_frequency = 'yearly' THEN
    v_total_cycle_days := 365;
  END IF;
  
  -- Calculate daily rates
  v_current_daily_rate := v_subscription.current_price / v_total_cycle_days;
  v_new_daily_rate := v_new_plan.price / v_total_cycle_days;
  
  -- Calculate proration amounts
  v_proration_credit := v_current_daily_rate * v_days_remaining;
  v_proration_charge := v_new_daily_rate * v_days_remaining;
  v_net_proration := v_proration_charge - v_proration_credit;
  
  RETURN jsonb_build_object(
    'days_remaining', v_days_remaining,
    'current_daily_rate', v_current_daily_rate,
    'new_daily_rate', v_new_daily_rate,
    'proration_credit', v_proration_credit,
    'proration_charge', v_proration_charge,
    'net_proration', v_net_proration,
    'migration_type', CASE 
      WHEN v_new_plan.price > v_subscription.current_price THEN 'upgrade'
      WHEN v_new_plan.price < v_subscription.current_price THEN 'downgrade'
      ELSE 'change'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔌 API ENDPOINTS

### GET /api/platform/pricing-plans
**List pricing plans**
```typescript
interface ListPricingPlansRequest {
  includeInactive?: boolean;
  includeGrandfathered?: boolean;
  planType?: 'standard' | 'enterprise' | 'custom' | 'trial';
}

interface ListPricingPlansResponse {
  plans: Array<{
    id: string;
    name: string;
    displayName: string;
    description: string;
    planType: string;
    billingFrequency: string;
    price: number;
    currency: string;
    trialPeriodDays: number;
    maxStudents?: number;
    maxStaff?: number;
    maxBranches?: number;
    features: Record<string, any>;
    isActive: boolean;
    isPublic: boolean;
    isGrandfathered: boolean;
    highlightPlan: boolean;
    sortOrder: number;
  }>;
}
```

### POST /api/platform/pricing-plans
**Create pricing plan**
```typescript
interface CreatePricingPlanRequest {
  name: string;
  displayName: string;
  description?: string;
  planType: 'standard' | 'enterprise' | 'custom' | 'trial';
  billingFrequency: 'monthly' | 'yearly' | 'one_time';
  price: number;
  currency?: string;
  setupFee?: number;
  trialPeriodDays?: number;
  maxStudents?: number;
  maxStaff?: number;
  maxBranches?: number;
  features: Record<string, any>;
  isActive?: boolean;
  isPublic?: boolean;
  sortOrder?: number;
  highlightPlan?: boolean;
}

interface CreatePricingPlanResponse {
  id: string;
  stripePriceId?: string;
  stripeProductId?: string;
}
```

### PUT /api/platform/pricing-plans/:id
**Update pricing plan**
```typescript
interface UpdatePricingPlanRequest {
  displayName?: string;
  description?: string;
  price?: number;
  features?: Record<string, any>;
  maxStudents?: number;
  maxStaff?: number;
  maxBranches?: number;
  isActive?: boolean;
  isPublic?: boolean;
  sortOrder?: number;
  highlightPlan?: boolean;
}

interface UpdatePricingPlanResponse {
  success: boolean;
  affectedSubscriptions?: number;
}
```

### POST /api/platform/pricing-plans/migrate
**Migrate subscription to different plan**
```typescript
interface MigratePlanRequest {
  subscriptionId: string;
  toPlanId: string;
  effectiveDate?: string;
  reason?: string;
  prorationPreview?: boolean;
}

interface MigratePlanResponse {
  migrationId?: string;
  proration: {
    daysRemaining: number;
    prorationCredit: number;
    prorationCharge: number;
    netProration: number;
    migrationType: 'upgrade' | 'downgrade' | 'change';
  };
  effectiveDate: string;
  newMonthlyPrice: number;
}
```

### POST /api/platform/custom-pricing
**Create custom pricing for enterprise customer**
```typescript
interface CreateCustomPricingRequest {
  tenantId: string;
  basePlanId?: string;
  customPrice: number;
  currency?: string;
  billingFrequency: 'monthly' | 'yearly';
  customLimits?: Record<string, any>;
  customFeatures?: Record<string, any>;
  contractStartDate: string;
  contractEndDate?: string;
  autoRenewal?: boolean;
}

interface CreateCustomPricingResponse {
  id: string;
  status: 'draft' | 'approved';
  requiresApproval: boolean;
}
```

### GET /api/platform/pricing-plans/comparison
**Get plan comparison matrix**
```typescript
interface PlanComparisonResponse {
  plans: Array<{
    id: string;
    name: string;
    displayName: string;
    price: number;
    currency: string;
    billingFrequency: string;
    highlightPlan: boolean;
  }>;
  featureMatrix: Array<{
    category: string;
    features: Array<{
      name: string;
      description: string;
      planValues: Record<string, string>; // planId -> value
    }>;
  }>;
}
```

---

## 🎨 REACT COMPONENTS

### PricingPlansManagement
**Main pricing plans management interface**
```typescript
const PricingPlansManagement: React.FC = () => {
  const [plans, setPlans] = useState<ListPricingPlansResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedPlan, setSelectedPlan] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const fetchPlans = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/platform/pricing-plans?includeInactive=true');
      if (response.ok) {
        const data = await response.json();
        setPlans(data);
      }
    } catch (error) {
      toast.error('Failed to load pricing plans');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPlans();
  }, [fetchPlans]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Pricing Plans</h1>
          <p className="text-sm text-gray-500">
            Manage subscription plans, features, and pricing
          </p>
        </div>
        
        <div className="flex items-center space-x-2">
          <Button onClick={() => setShowPlanComparison(true)} variant="outline">
            <BarChart3 className="h-4 w-4 mr-2" />
            View Comparison
          </Button>
          <Button onClick={() => setShowCreateModal(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Create Plan
          </Button>
        </div>
      </div>

      {/* Plans Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {plans?.plans.map((plan) => (
          <Card 
            key={plan.id} 
            className={`${
              plan.highlightPlan ? 'ring-2 ring-blue-500 shadow-lg' : 'hover:shadow-md'
            } transition-shadow cursor-pointer`}
            onClick={() => setSelectedPlan(plan.id)}
          >
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div>
                  <CardTitle className="text-lg">{plan.displayName}</CardTitle>
                  <CardDescription className="text-sm">
                    {plan.description}
                  </CardDescription>
                </div>
                
                <div className="flex items-center space-x-1">
                  {plan.highlightPlan && (
                    <Badge variant="secondary" className="text-xs">
                      Popular
                    </Badge>
                  )}
                  {!plan.isActive && (
                    <Badge variant="outline" className="text-xs">
                      Inactive
                    </Badge>
                  )}
                  {plan.isGrandfathered && (
                    <Badge variant="outline" className="text-xs text-orange-600">
                      Legacy
                    </Badge>
                  )}
                </div>
              </div>
            </CardHeader>

            <CardContent className="space-y-4">
              {/* Pricing */}
              <div className="text-center">
                <div className="flex items-baseline justify-center">
                  <span className="text-3xl font-bold">
                    {plan.currency} {plan.price.toLocaleString()}
                  </span>
                  <span className="text-sm text-gray-500 ml-1">
                    /{plan.billingFrequency === 'monthly' ? 'mo' : 'yr'}
                  </span>
                </div>
                
                {plan.trialPeriodDays > 0 && (
                  <p className="text-sm text-green-600 mt-1">
                    {plan.trialPeriodDays} days free trial
                  </p>
                )}
              </div>

              {/* Key Limits */}
              <div className="space-y-2 text-sm">
                {plan.maxStudents && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Students:</span>
                    <span className="font-medium">
                      {plan.maxStudents === -1 ? 'Unlimited' : plan.maxStudents.toLocaleString()}
                    </span>
                  </div>
                )}
                {plan.maxStaff && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Staff:</span>
                    <span className="font-medium">
                      {plan.maxStaff === -1 ? 'Unlimited' : plan.maxStaff.toLocaleString()}
                    </span>
                  </div>
                )}
                {plan.maxBranches && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Branches:</span>
                    <span className="font-medium">
                      {plan.maxBranches === -1 ? 'Unlimited' : plan.maxBranches}
                    </span>
                  </div>
                )}
              </div>

              {/* Key Features */}
              <div className="space-y-1">
                {Object.entries(plan.features)
                  .filter(([key, value]) => value === true || value === 'enabled')
                  .slice(0, 4)
                  .map(([feature, _]) => (
                    <div key={feature} className="flex items-center space-x-2 text-sm">
                      <Check className="h-3 w-3 text-green-500" />
                      <span className="capitalize">
                        {feature.replace(/_/g, ' ')}
                      </span>
                    </div>
                  ))}
                
                {Object.keys(plan.features).length > 4 && (
                  <p className="text-xs text-gray-500 mt-2">
                    +{Object.keys(plan.features).length - 4} more features
                  </p>
                )}
              </div>

              {/* Actions */}
              <div className="pt-2 border-t">
                <div className="flex items-center justify-between text-xs text-gray-500">
                  <span>Type: {plan.planType}</span>
                  <span>Order: {plan.sortOrder}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Create Plan Modal */}
      {showCreateModal && (
        <CreatePricingPlanModal
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => {
            setShowCreateModal(false);
            fetchPlans();
          }}
        />
      )}

      {/* Plan Details Modal */}
      {selectedPlan && (
        <PlanDetailsModal
          planId={selectedPlan}
          onClose={() => setSelectedPlan(null)}
          onUpdate={fetchPlans}
        />
      )}
    </div>
  );
};
```

### PlanComparisonMatrix
**Visual comparison of plans and features**
```typescript
interface PlanComparisonMatrixProps {
  comparison: PlanComparisonResponse;
}

const PlanComparisonMatrix: React.FC<PlanComparisonMatrixProps> = ({
  comparison
}) => {
  return (
    <div className="space-y-6">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">
          Compare Plans
        </h2>
        <p className="text-gray-600">
          Choose the plan that best fits your needs
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full">
          {/* Plan Headers */}
          <thead>
            <tr>
              <th className="text-left p-4 w-64">Features</th>
              {comparison.plans.map((plan) => (
                <th key={plan.id} className="text-center p-4 min-w-48">
                  <div className={`${
                    plan.highlightPlan ? 'bg-blue-50 border border-blue-200' : 'bg-gray-50'
                  } rounded-lg p-4`}>
                    <h3 className="font-bold text-lg">{plan.displayName}</h3>
                    <div className="mt-2">
                      <span className="text-2xl font-bold">
                        {plan.currency} {plan.price}
                      </span>
                      <span className="text-sm text-gray-500">
                        /{plan.billingFrequency === 'monthly' ? 'mo' : 'yr'}
                      </span>
                    </div>
                    {plan.highlightPlan && (
                      <Badge className="mt-2">Most Popular</Badge>
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>

          {/* Feature Rows */}
          <tbody>
            {comparison.featureMatrix.map((category, categoryIndex) => (
              <React.Fragment key={category.category}>
                {/* Category Header */}
                <tr>
                  <td 
                    colSpan={comparison.plans.length + 1} 
                    className="bg-gray-100 p-3 font-semibold text-gray-900 border-t border-gray-200"
                  >
                    {category.category}
                  </td>
                </tr>
                
                {/* Feature Rows */}
                {category.features.map((feature, featureIndex) => (
                  <tr key={`${categoryIndex}-${featureIndex}`} className="border-b border-gray-100">
                    <td className="p-4 font-medium text-gray-900">
                      <div>
                        <span>{feature.name}</span>
                        {feature.description && (
                          <p className="text-xs text-gray-500 mt-1">
                            {feature.description}
                          </p>
                        )}
                      </div>
                    </td>
                    
                    {comparison.plans.map((plan) => (
                      <td key={plan.id} className="p-4 text-center">
                        <FeatureValue 
                          value={feature.planValues[plan.id]} 
                          isHighlight={plan.highlightPlan}
                        />
                      </td>
                    ))}
                  </tr>
                ))}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

const FeatureValue: React.FC<{ value: string; isHighlight?: boolean }> = ({ 
  value, 
  isHighlight 
}) => {
  const getValueDisplay = (val: string) => {
    switch (val) {
      case 'true':
      case 'enabled':
        return <Check className="h-5 w-5 text-green-500 mx-auto" />;
      case 'false':
      case 'disabled':
        return <X className="h-5 w-5 text-gray-300 mx-auto" />;
      case 'unlimited':
        return <span className="text-green-600 font-medium">∞</span>;
      default:
        return <span className="font-medium">{val}</span>;
    }
  };

  return (
    <div className={`${isHighlight ? 'bg-blue-50' : ''} p-2 rounded`}>
      {getValueDisplay(value)}
    </div>
  );
};
```

---

## 🔒 SECURITY & VALIDATION

### Input Validation
```typescript
export const createPricingPlanSchema = z.object({
  name: z.string().min(1).max(100),
  displayName: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  planType: z.enum(['standard', 'enterprise', 'custom', 'trial']),
  billingFrequency: z.enum(['monthly', 'yearly', 'one_time']),
  price: z.number().min(0).max(999999),
  currency: z.string().length(3).default('USD'),
  setupFee: z.number().min(0).optional(),
  trialPeriodDays: z.number().min(0).max(365).optional(),
  maxStudents: z.number().min(-1).optional(), // -1 for unlimited
  maxStaff: z.number().min(-1).optional(),
  maxBranches: z.number().min(-1).optional(),
  features: z.record(z.any()),
  isActive: z.boolean().optional().default(true),
  isPublic: z.boolean().optional().default(true),
  sortOrder: z.number().optional().default(0),
  highlightPlan: z.boolean().optional().default(false)
});
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
