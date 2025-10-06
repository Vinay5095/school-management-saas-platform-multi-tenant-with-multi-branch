# SPEC-134: Subscription Billing Automation
## Automated Billing Cycles and Dunning Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-133, SPEC-123, Phase 1

---

## 📋 OVERVIEW

### Purpose
Automated subscription billing system with intelligent dunning management, retry logic, and automated communication for failed payments.

### Key Features
- ✅ Automated billing cycles
- ✅ Prorated billing for upgrades/downgrades
- ✅ Dunning management (failed payment recovery)
- ✅ Automated retry schedule
- ✅ Payment reminder emails
- ✅ Grace period management
- ✅ Subscription pause/resume
- ✅ Billing history tracking
- ✅ Usage-based billing support
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Billing cycles table
CREATE TABLE billing_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Cycle details
  cycle_number INTEGER NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  billing_date DATE NOT NULL,
  due_date DATE NOT NULL,
  
  -- Amounts
  subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0,
  prorations DECIMAL(12, 2) NOT NULL DEFAULT 0,
  credits_applied DECIMAL(12, 2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(12, 2) NOT NULL,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('draft', 'finalized', 'paid', 'failed', 'cancelled')) DEFAULT 'draft',
  
  -- Processing
  processed_at TIMESTAMPTZ,
  invoice_id UUID REFERENCES invoices(id),
  payment_transaction_id UUID REFERENCES payment_transactions(id),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Dunning management table
CREATE TABLE dunning_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  billing_cycle_id UUID REFERENCES billing_cycles(id) ON DELETE CASCADE,
  
  -- Campaign details
  campaign_type TEXT NOT NULL CHECK (campaign_type IN ('payment_failed', 'subscription_past_due', 'voluntary_churn')),
  current_step INTEGER NOT NULL DEFAULT 1,
  max_steps INTEGER NOT NULL DEFAULT 4,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'completed', 'cancelled')) DEFAULT 'active',
  
  -- Outcomes
  resolution_type TEXT CHECK (resolution_type IN ('payment_received', 'subscription_cancelled', 'manual_intervention', 'exhausted')),
  resolved_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Usage billing table
CREATE TABLE usage_billing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  billing_cycle_id UUID REFERENCES billing_cycles(id),
  
  -- Usage details
  usage_type TEXT NOT NULL, -- 'students', 'api_calls', 'storage_gb', etc.
  usage_amount DECIMAL(15, 6) NOT NULL,
  unit_price DECIMAL(12, 6) NOT NULL,
  total_charge DECIMAL(12, 2) NOT NULL,
  
  -- Billing period
  usage_period_start TIMESTAMPTZ NOT NULL,
  usage_period_end TIMESTAMPTZ NOT NULL,
  
  -- Metadata
  usage_data JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Function to process billing cycle
CREATE OR REPLACE FUNCTION process_billing_cycle(p_subscription_id UUID)
RETURNS UUID AS $$
DECLARE
  v_billing_cycle_id UUID;
  v_subscription RECORD;
  v_cycle_number INTEGER;
  v_total_amount DECIMAL(12, 2) := 0;
BEGIN
  -- Get subscription details
  SELECT * INTO v_subscription
  FROM subscriptions
  WHERE id = p_subscription_id AND status = 'active';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Active subscription not found';
  END IF;
  
  -- Calculate cycle details and create billing cycle
  -- Implementation details...
  
  RETURN v_billing_cycle_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔌 API ENDPOINTS

### POST /api/platform/billing/process-cycle
**Process billing cycle for subscription**
```typescript
interface ProcessBillingCycleRequest {
  subscriptionId: string;
  billingDate?: string;
  dryRun?: boolean;
}

interface ProcessBillingCycleResponse {
  billingCycleId: string;
  cycleNumber: number;
  totalAmount: number;
  billingDate: string;
  dueDate: string;
  invoiceId?: string;
}
```

### GET /api/platform/billing/cycles
**List billing cycles**
```typescript
interface ListBillingCyclesResponse {
  cycles: Array<{
    id: string;
    subscriptionId: string;
    tenantName: string;
    cycleNumber: number;
    periodStart: string;
    periodEnd: string;
    billingDate: string;
    dueDate: string;
    totalAmount: number;
    status: string;
    overdueDays?: number;
  }>;
  pagination: PaginationInfo;
}
```

### POST /api/platform/billing/dunning/start-campaign
**Start dunning campaign**
```typescript
interface StartDunningCampaignRequest {
  subscriptionId: string;
  campaignType: 'payment_failed' | 'subscription_past_due' | 'voluntary_churn';
  billingCycleId?: string;
}

interface StartDunningCampaignResponse {
  campaignId: string;
  stepsScheduled: number;
  firstStepDate: string;
}
```

---

## 🎨 REACT COMPONENTS

### SubscriptionBillingDashboard
**Main subscription billing management interface**
```typescript
const SubscriptionBillingDashboard: React.FC = () => {
  const [cycles, setCycles] = useState<ListBillingCyclesResponse | null>(null);
  const [loading, setLoading] = useState(true);
  
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Subscription Billing</h1>
          <p className="text-sm text-gray-500">
            Automated billing cycles and dunning management
          </p>
        </div>
        
        <Button onClick={handleProcessBilling}>
          <Play className="h-4 w-4 mr-2" />
          Process Billing
        </Button>
      </div>
      
      {/* Billing cycles table and dunning management */}
    </div>
  );
};
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
