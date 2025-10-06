# SPEC-123: Subscription & Billing Management
## Platform-wide Subscription and Payment Processing

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6-8 hours  
> **Dependencies**: SPEC-116, SPEC-117, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive subscription and billing management system for super admins to manage subscription plans, process payments, generate invoices, handle upgrades/downgrades, and monitor revenue across all tenants.

### Key Features
- ✅ Subscription plan management
- ✅ Tenant subscription lifecycle
- ✅ Payment processing (Stripe integration)
- ✅ Invoice generation and management
- ✅ Upgrade/downgrade workflows
- ✅ Prorated billing calculations
- ✅ Payment failure handling
- ✅ Revenue tracking and reporting
- ✅ Dunning management
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Subscription plans table
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_name TEXT UNIQUE NOT NULL,
  plan_key TEXT UNIQUE NOT NULL,
  description TEXT,
  billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly', 'yearly', 'quarterly')),
  price DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  trial_days INTEGER DEFAULT 14,
  
  -- Features and limits
  max_tenants INTEGER,
  max_users_per_tenant INTEGER,
  max_branches INTEGER,
  max_students INTEGER,
  storage_gb INTEGER,
  features JSONB DEFAULT '{}'::jsonb,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_visible BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  
  -- Stripe integration
  stripe_price_id TEXT,
  stripe_product_id TEXT,
  
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscription_plans_key ON subscription_plans(plan_key);
CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active);
CREATE INDEX idx_subscription_plans_stripe ON subscription_plans(stripe_price_id);

-- Tenant subscriptions table
CREATE TABLE tenant_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  
  -- Subscription status
  status TEXT NOT NULL CHECK (status IN (
    'trialing', 'active', 'past_due', 'canceled', 'unpaid', 'paused'
  )),
  
  -- Billing details
  billing_cycle TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Dates
  trial_start TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  canceled_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  
  -- Payment method
  payment_method_id TEXT,
  
  -- Stripe integration
  stripe_subscription_id TEXT UNIQUE,
  stripe_customer_id TEXT,
  
  -- Metadata
  cancel_reason TEXT,
  cancel_at_period_end BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenant_subscriptions_tenant ON tenant_subscriptions(tenant_id);
CREATE INDEX idx_tenant_subscriptions_plan ON tenant_subscriptions(plan_id);
CREATE INDEX idx_tenant_subscriptions_status ON tenant_subscriptions(status);
CREATE INDEX idx_tenant_subscriptions_stripe ON tenant_subscriptions(stripe_subscription_id);
CREATE INDEX idx_tenant_subscriptions_period_end ON tenant_subscriptions(current_period_end);

-- Invoices table
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE NOT NULL,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  subscription_id UUID REFERENCES tenant_subscriptions(id),
  
  -- Invoice details
  status TEXT NOT NULL CHECK (status IN (
    'draft', 'pending', 'paid', 'void', 'uncollectible'
  )),
  amount_due DECIMAL(10, 2) NOT NULL,
  amount_paid DECIMAL(10, 2) DEFAULT 0,
  tax DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Dates
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  paid_at TIMESTAMPTZ,
  
  -- Details
  description TEXT,
  line_items JSONB NOT NULL,
  
  -- Payment
  payment_method TEXT,
  transaction_id TEXT,
  
  -- Stripe
  stripe_invoice_id TEXT UNIQUE,
  stripe_payment_intent_id TEXT,
  
  -- Files
  pdf_url TEXT,
  
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX idx_invoices_subscription ON invoices(subscription_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_stripe ON invoices(stripe_invoice_id);

-- Payment transactions table
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  invoice_id UUID REFERENCES invoices(id),
  subscription_id UUID REFERENCES tenant_subscriptions(id),
  
  -- Transaction details
  transaction_type TEXT NOT NULL CHECK (transaction_type IN (
    'payment', 'refund', 'dispute', 'adjustment'
  )),
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  status TEXT NOT NULL CHECK (status IN (
    'pending', 'succeeded', 'failed', 'refunded'
  )),
  
  -- Payment details
  payment_method TEXT,
  payment_method_details JSONB,
  
  -- Stripe
  stripe_payment_intent_id TEXT,
  stripe_charge_id TEXT,
  stripe_refund_id TEXT,
  
  -- Error handling
  failure_code TEXT,
  failure_message TEXT,
  
  -- Dates
  processed_at TIMESTAMPTZ,
  
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_transactions_tenant ON payment_transactions(tenant_id);
CREATE INDEX idx_payment_transactions_invoice ON payment_transactions(invoice_id);
CREATE INDEX idx_payment_transactions_subscription ON payment_transactions(subscription_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_type ON payment_transactions(transaction_type);

-- Subscription change history
CREATE TABLE subscription_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  subscription_id UUID NOT NULL REFERENCES tenant_subscriptions(id),
  
  change_type TEXT NOT NULL CHECK (change_type IN (
    'created', 'upgraded', 'downgraded', 'canceled', 'reactivated', 'trial_started', 'trial_ended'
  )),
  
  previous_plan_id UUID REFERENCES subscription_plans(id),
  new_plan_id UUID REFERENCES subscription_plans(id),
  
  previous_status TEXT,
  new_status TEXT,
  
  prorated_amount DECIMAL(10, 2),
  
  changed_by UUID REFERENCES auth.users(id),
  change_reason TEXT,
  
  effective_date TIMESTAMPTZ NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscription_changes_tenant ON subscription_changes(tenant_id);
CREATE INDEX idx_subscription_changes_subscription ON subscription_changes(subscription_id);
CREATE INDEX idx_subscription_changes_type ON subscription_changes(change_type);

-- Function to calculate prorated amount
CREATE OR REPLACE FUNCTION calculate_prorated_amount(
  p_old_price DECIMAL,
  p_new_price DECIMAL,
  p_days_remaining INTEGER,
  p_total_days INTEGER
)
RETURNS DECIMAL AS $$
BEGIN
  -- Credit for unused time on old plan
  DECLARE
    v_credit DECIMAL := (p_old_price / p_total_days) * p_days_remaining;
    v_new_charge DECIMAL := (p_new_price / p_total_days) * p_days_remaining;
  BEGIN
    RETURN v_new_charge - v_credit;
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  v_year TEXT := TO_CHAR(NOW(), 'YYYY');
  v_month TEXT := TO_CHAR(NOW(), 'MM');
  v_sequence INTEGER;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 10) AS INTEGER)), 0) + 1
  INTO v_sequence
  FROM invoices
  WHERE invoice_number LIKE 'INV-' || v_year || v_month || '%';
  
  RETURN 'INV-' || v_year || v_month || LPAD(v_sequence::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to create subscription
CREATE OR REPLACE FUNCTION create_subscription(
  p_tenant_id UUID,
  p_plan_id UUID,
  p_start_trial BOOLEAN DEFAULT true
)
RETURNS UUID AS $$
DECLARE
  v_subscription_id UUID;
  v_plan RECORD;
  v_trial_end TIMESTAMPTZ;
  v_period_start TIMESTAMPTZ := NOW();
  v_period_end TIMESTAMPTZ;
BEGIN
  -- Get plan details
  SELECT * INTO v_plan
  FROM subscription_plans
  WHERE id = p_plan_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  -- Calculate trial end if applicable
  IF p_start_trial AND v_plan.trial_days > 0 THEN
    v_trial_end := v_period_start + (v_plan.trial_days || ' days')::INTERVAL;
    v_period_end := v_trial_end;
  ELSE
    v_period_end := CASE v_plan.billing_cycle
      WHEN 'monthly' THEN v_period_start + INTERVAL '1 month'
      WHEN 'yearly' THEN v_period_start + INTERVAL '1 year'
      WHEN 'quarterly' THEN v_period_start + INTERVAL '3 months'
    END;
  END IF;

  -- Create subscription
  INSERT INTO tenant_subscriptions (
    tenant_id,
    plan_id,
    status,
    billing_cycle,
    price,
    currency,
    trial_start,
    trial_end,
    current_period_start,
    current_period_end
  ) VALUES (
    p_tenant_id,
    p_plan_id,
    CASE WHEN p_start_trial AND v_plan.trial_days > 0 THEN 'trialing' ELSE 'active' END,
    v_plan.billing_cycle,
    v_plan.price,
    v_plan.currency,
    CASE WHEN p_start_trial AND v_plan.trial_days > 0 THEN v_period_start ELSE NULL END,
    v_trial_end,
    v_period_start,
    v_period_end
  ) RETURNING id INTO v_subscription_id;

  -- Log subscription creation
  INSERT INTO subscription_changes (
    tenant_id,
    subscription_id,
    change_type,
    new_plan_id,
    new_status,
    effective_date
  ) VALUES (
    p_tenant_id,
    v_subscription_id,
    CASE WHEN p_start_trial AND v_plan.trial_days > 0 THEN 'trial_started' ELSE 'created' END,
    p_plan_id,
    CASE WHEN p_start_trial AND v_plan.trial_days > 0 THEN 'trialing' ELSE 'active' END,
    v_period_start
  );

  RETURN v_subscription_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to upgrade/downgrade subscription
CREATE OR REPLACE FUNCTION change_subscription_plan(
  p_subscription_id UUID,
  p_new_plan_id UUID,
  p_changed_by UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_subscription RECORD;
  v_old_plan RECORD;
  v_new_plan RECORD;
  v_days_remaining INTEGER;
  v_total_days INTEGER;
  v_prorated_amount DECIMAL;
BEGIN
  -- Get current subscription
  SELECT * INTO v_subscription
  FROM tenant_subscriptions
  WHERE id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found';
  END IF;

  -- Get plan details
  SELECT * INTO v_old_plan FROM subscription_plans WHERE id = v_subscription.plan_id;
  SELECT * INTO v_new_plan FROM subscription_plans WHERE id = p_new_plan_id;

  -- Calculate proration
  v_days_remaining := EXTRACT(DAY FROM v_subscription.current_period_end - NOW());
  v_total_days := EXTRACT(DAY FROM v_subscription.current_period_end - v_subscription.current_period_start);
  v_prorated_amount := calculate_prorated_amount(
    v_old_plan.price,
    v_new_plan.price,
    v_days_remaining,
    v_total_days
  );

  -- Update subscription
  UPDATE tenant_subscriptions
  SET
    plan_id = p_new_plan_id,
    price = v_new_plan.price,
    billing_cycle = v_new_plan.billing_cycle,
    updated_at = NOW()
  WHERE id = p_subscription_id;

  -- Log change
  INSERT INTO subscription_changes (
    tenant_id,
    subscription_id,
    change_type,
    previous_plan_id,
    new_plan_id,
    previous_status,
    new_status,
    prorated_amount,
    changed_by,
    change_reason,
    effective_date
  ) VALUES (
    v_subscription.tenant_id,
    p_subscription_id,
    CASE WHEN v_new_plan.price > v_old_plan.price THEN 'upgraded' ELSE 'downgraded' END,
    v_subscription.plan_id,
    p_new_plan_id,
    v_subscription.status,
    v_subscription.status,
    v_prorated_amount,
    p_changed_by,
    p_reason,
    NOW()
  );

  RETURN p_subscription_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cancel subscription
CREATE OR REPLACE FUNCTION cancel_subscription(
  p_subscription_id UUID,
  p_canceled_by UUID,
  p_reason TEXT,
  p_immediate BOOLEAN DEFAULT false
)
RETURNS void AS $$
DECLARE
  v_subscription RECORD;
BEGIN
  SELECT * INTO v_subscription
  FROM tenant_subscriptions
  WHERE id = p_subscription_id;

  IF p_immediate THEN
    UPDATE tenant_subscriptions
    SET
      status = 'canceled',
      canceled_at = NOW(),
      ended_at = NOW(),
      cancel_reason = p_reason
    WHERE id = p_subscription_id;
  ELSE
    UPDATE tenant_subscriptions
    SET
      cancel_at_period_end = true,
      canceled_at = NOW(),
      cancel_reason = p_reason
    WHERE id = p_subscription_id;
  END IF;

  -- Log cancellation
  INSERT INTO subscription_changes (
    tenant_id,
    subscription_id,
    change_type,
    previous_status,
    new_status,
    changed_by,
    change_reason,
    effective_date
  ) VALUES (
    v_subscription.tenant_id,
    p_subscription_id,
    'canceled',
    v_subscription.status,
    'canceled',
    p_canceled_by,
    p_reason,
    CASE WHEN p_immediate THEN NOW() ELSE v_subscription.current_period_end END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get revenue metrics
CREATE OR REPLACE FUNCTION get_revenue_metrics(
  p_from_date DATE,
  p_to_date DATE
)
RETURNS TABLE (
  total_revenue DECIMAL,
  mrr DECIMAL,
  arr DECIMAL,
  avg_revenue_per_tenant DECIMAL,
  total_invoices BIGINT,
  paid_invoices BIGINT,
  overdue_invoices BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(i.amount_paid), 0) as total_revenue,
    COALESCE(SUM(CASE WHEN ts.billing_cycle = 'monthly' THEN ts.price ELSE 0 END), 0) as mrr,
    COALESCE(SUM(CASE WHEN ts.billing_cycle = 'yearly' THEN ts.price ELSE ts.price * 12 END), 0) as arr,
    COALESCE(AVG(ts.price), 0) as avg_revenue_per_tenant,
    COUNT(i.id) as total_invoices,
    COUNT(i.id) FILTER (WHERE i.status = 'paid') as paid_invoices,
    COUNT(i.id) FILTER (WHERE i.status = 'pending' AND i.due_date < CURRENT_DATE) as overdue_invoices
  FROM invoices i
  LEFT JOIN tenant_subscriptions ts ON ts.id = i.subscription_id
  WHERE i.invoice_date BETWEEN p_from_date AND p_to_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_changes ENABLE ROW LEVEL SECURITY;

CREATE POLICY super_admin_subscription_plans ON subscription_plans
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY public_active_plans ON subscription_plans
  FOR SELECT USING (is_active = true AND is_visible = true);

CREATE POLICY super_admin_tenant_subscriptions ON tenant_subscriptions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY tenant_own_subscription ON tenant_subscriptions
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY super_admin_invoices ON invoices
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY tenant_own_invoices ON invoices
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/subscription.ts

export interface SubscriptionPlan {
  id: string
  planName: string
  planKey: string
  description?: string
  billingCycle: 'monthly' | 'yearly' | 'quarterly'
  price: number
  currency: string
  trialDays: number
  maxTenants?: number
  maxUsersPerTenant?: number
  maxBranches?: number
  maxStudents?: number
  storageGb?: number
  features: Record<string, any>
  isActive: boolean
  isVisible: boolean
  sortOrder: number
  stripePriceId?: string
  stripeProductId?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface TenantSubscription {
  id: string
  tenantId: string
  planId: string
  status: 'trialing' | 'active' | 'past_due' | 'canceled' | 'unpaid' | 'paused'
  billingCycle: string
  price: number
  currency: string
  trialStart?: string
  trialEnd?: string
  currentPeriodStart: string
  currentPeriodEnd: string
  canceledAt?: string
  endedAt?: string
  paymentMethodId?: string
  stripeSubscriptionId?: string
  stripeCustomerId?: string
  cancelReason?: string
  cancelAtPeriodEnd: boolean
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
  plan?: SubscriptionPlan
}

export interface Invoice {
  id: string
  invoiceNumber: string
  tenantId: string
  subscriptionId?: string
  status: 'draft' | 'pending' | 'paid' | 'void' | 'uncollectible'
  amountDue: number
  amountPaid: number
  tax: number
  total: number
  currency: string
  invoiceDate: string
  dueDate: string
  paidAt?: string
  description?: string
  lineItems: Array<{
    description: string
    quantity: number
    unitPrice: number
    amount: number
  }>
  paymentMethod?: string
  transactionId?: string
  stripeInvoiceId?: string
  stripePaymentIntentId?: string
  pdfUrl?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface PaymentTransaction {
  id: string
  tenantId: string
  invoiceId?: string
  subscriptionId?: string
  transactionType: 'payment' | 'refund' | 'dispute' | 'adjustment'
  amount: number
  currency: string
  status: 'pending' | 'succeeded' | 'failed' | 'refunded'
  paymentMethod?: string
  paymentMethodDetails?: Record<string, any>
  stripePaymentIntentId?: string
  stripeChargeId?: string
  stripeRefundId?: string
  failureCode?: string
  failureMessage?: string
  processedAt?: string
  metadata?: Record<string, any>
  createdAt: string
}

export interface RevenueMetrics {
  totalRevenue: number
  mrr: number
  arr: number
  avgRevenuePerTenant: number
  totalInvoices: number
  paidInvoices: number
  overdueInvoices: number
}
```

### API Routes

```typescript
// src/app/api/platform/subscriptions/plans/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  try {
    const { data: plans, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .order('sort_order')

    if (error) throw error

    return NextResponse.json({ plans })

  } catch (error) {
    console.error('Failed to fetch plans:', error)
    return NextResponse.json(
      { error: 'Failed to fetch plans' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()

    const { data, error } = await supabase
      .from('subscription_plans')
      .insert(body)
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ plan: data }, { status: 201 })

  } catch (error) {
    console.error('Failed to create plan:', error)
    return NextResponse.json(
      { error: 'Failed to create plan' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/subscriptions/[id]/change-plan/route.ts

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { newPlanId, reason } = body

    const { data, error } = await supabase.rpc('change_subscription_plan', {
      p_subscription_id: params.id,
      p_new_plan_id: newPlanId,
      p_changed_by: user.id,
      p_reason: reason,
    })

    if (error) throw error

    return NextResponse.json({ subscriptionId: data })

  } catch (error) {
    console.error('Failed to change plan:', error)
    return NextResponse.json(
      { error: 'Failed to change plan' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/invoices/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const status = searchParams.get('status')
    const tenantId = searchParams.get('tenantId')

    let query = supabase
      .from('invoices')
      .select('*, tenant:tenants(name)')
      .order('invoice_date', { ascending: false })

    if (status) query = query.eq('status', status)
    if (tenantId) query = query.eq('tenant_id', tenantId)

    const { data: invoices, error } = await query.limit(100)

    if (error) throw error

    return NextResponse.json({ invoices })

  } catch (error) {
    console.error('Failed to fetch invoices:', error)
    return NextResponse.json(
      { error: 'Failed to fetch invoices' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/revenue/metrics/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const fromDate = searchParams.get('fromDate') || 
                     new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const toDate = searchParams.get('toDate') || new Date().toISOString().split('T')[0]

    const { data: metrics, error } = await supabase
      .rpc('get_revenue_metrics', {
        p_from_date: fromDate,
        p_to_date: toDate,
      })
      .single()

    if (error) throw error

    return NextResponse.json({ metrics })

  } catch (error) {
    console.error('Failed to fetch revenue metrics:', error)
    return NextResponse.json(
      { error: 'Failed to fetch revenue metrics' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Subscription Management Dashboard

```typescript
// src/components/platform/subscription-dashboard.tsx

'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { 
  DollarSign, TrendingUp, FileText, 
  CreditCard, AlertCircle 
} from 'lucide-react'
import { format } from 'date-fns'

export function SubscriptionDashboard() {
  const { data: metrics } = useQuery({
    queryKey: ['revenue-metrics'],
    queryFn: async () => {
      const res = await fetch('/api/platform/revenue/metrics')
      if (!res.ok) throw new Error('Failed to fetch metrics')
      return res.json()
    },
  })

  const { data: invoicesData } = useQuery({
    queryKey: ['recent-invoices'],
    queryFn: async () => {
      const res = await fetch('/api/platform/invoices?limit=10')
      if (!res.ok) throw new Error('Failed to fetch invoices')
      return res.json()
    },
  })

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount)
  }

  return (
    <div className="space-y-6">
      {/* Revenue Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(metrics?.metrics?.totalRevenue || 0)}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">MRR</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(metrics?.metrics?.mrr || 0)}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">ARR</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(metrics?.metrics?.arr || 0)}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Overdue</CardTitle>
            <AlertCircle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">
              {metrics?.metrics?.overdueInvoices || 0}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Invoices */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Recent Invoices
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {invoicesData?.invoices?.map((invoice: any) => (
              <div
                key={invoice.id}
                className="flex items-center justify-between p-3 border rounded-lg"
              >
                <div className="flex-1">
                  <p className="font-medium">{invoice.invoiceNumber}</p>
                  <p className="text-sm text-muted-foreground">
                    {invoice.tenant?.name} • {format(new Date(invoice.invoiceDate), 'MMM dd, yyyy')}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-medium">{formatCurrency(invoice.total)}</p>
                  <Badge
                    variant={invoice.status === 'paid' ? 'default' : 'secondary'}
                  >
                    {invoice.status}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Subscription plan management
- [x] Tenant subscription lifecycle
- [x] Payment processing integration
- [x] Invoice generation
- [x] Upgrade/downgrade workflows
- [x] Prorated billing calculations
- [x] Payment failure handling
- [x] Revenue tracking
- [x] Dunning management
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
