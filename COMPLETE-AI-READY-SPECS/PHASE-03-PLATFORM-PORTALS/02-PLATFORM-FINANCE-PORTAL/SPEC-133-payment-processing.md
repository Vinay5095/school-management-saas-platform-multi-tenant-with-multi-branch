# SPEC-133: Payment Processing and Gateway Integration
## Stripe Integration and Payment Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 6-7 hours  
> **Dependencies**: SPEC-131, SPEC-132, Phase 1

---

## 📋 OVERVIEW

### Purpose
Complete payment processing system with Stripe integration for handling subscription payments, one-time charges, refunds, and payment method management.

### Key Features
- ✅ Stripe payment integration
- ✅ Subscription payment automation
- ✅ Payment method management
- ✅ Refund processing
- ✅ Failed payment retry logic
- ✅ Payment webhooks handling
- ✅ 3D Secure support
- ✅ Multi-currency support
- ✅ Payment analytics
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Payment transactions table
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  
  -- Stripe IDs
  stripe_payment_intent_id TEXT UNIQUE,
  stripe_charge_id TEXT,
  stripe_customer_id TEXT,
  
  -- Transaction details
  amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded')) DEFAULT 'pending',
  payment_method TEXT NOT NULL CHECK (payment_method IN ('card', 'bank_transfer', 'digital_wallet', 'cryptocurrency')),
  
  -- Payment method details
  payment_method_details JSONB DEFAULT '{}'::jsonb,
  
  -- Transaction metadata
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  
  -- Failure information
  failure_code TEXT,
  failure_message TEXT,
  
  -- Timestamps
  attempted_at TIMESTAMPTZ,
  succeeded_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payment methods table (stored payment methods)
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  stripe_payment_method_id TEXT NOT NULL UNIQUE,
  stripe_customer_id TEXT NOT NULL,
  
  -- Payment method details
  type TEXT NOT NULL CHECK (type IN ('card', 'bank_account', 'digital_wallet')),
  brand TEXT,
  last_four TEXT,
  exp_month INTEGER,
  exp_year INTEGER,
  
  -- Status and preferences
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metadata
  billing_details JSONB DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payment retries table (for failed payment retry logic)
CREATE TABLE payment_retries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 3,
  next_retry_at TIMESTAMPTZ,
  retry_schedule JSONB DEFAULT '[]'::jsonb, -- [1, 3, 7] days
  status TEXT NOT NULL CHECK (status IN ('scheduled', 'processing', 'completed', 'exhausted')) DEFAULT 'scheduled',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Stripe webhook events table
CREATE TABLE stripe_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_event_id TEXT NOT NULL UNIQUE,
  event_type TEXT NOT NULL,
  event_data JSONB NOT NULL,
  processed BOOLEAN DEFAULT FALSE,
  processing_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Refunds table
CREATE TABLE refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
  stripe_refund_id TEXT UNIQUE,
  amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL,
  reason TEXT CHECK (reason IN ('duplicate', 'fraudulent', 'requested_by_customer', 'expired_uncaptured_charge')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'succeeded', 'failed', 'cancelled')) DEFAULT 'pending',
  failure_reason TEXT,
  receipt_number TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_payment_transactions_tenant ON payment_transactions(tenant_id, created_at DESC);
CREATE INDEX idx_payment_transactions_invoice ON payment_transactions(invoice_id);
CREATE INDEX idx_payment_transactions_stripe_intent ON payment_transactions(stripe_payment_intent_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status, created_at DESC);
CREATE INDEX idx_payment_methods_tenant ON payment_methods(tenant_id, is_default DESC);
CREATE INDEX idx_payment_methods_stripe_customer ON payment_methods(stripe_customer_id);
CREATE INDEX idx_payment_retries_next_retry ON payment_retries(next_retry_at) WHERE status = 'scheduled';
CREATE INDEX idx_stripe_webhook_events_processed ON stripe_webhook_events(processed, created_at);

-- Function to calculate next retry date
CREATE OR REPLACE FUNCTION calculate_next_retry_date(
  p_retry_count INTEGER,
  p_retry_schedule JSONB DEFAULT '[1, 3, 7]'::jsonb
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  retry_days INTEGER;
  schedule_array INTEGER[];
BEGIN
  -- Convert JSONB to array
  SELECT array_agg((value::text)::integer)
  INTO schedule_array
  FROM jsonb_array_elements(p_retry_schedule);
  
  -- Get retry days based on count
  IF p_retry_count <= array_length(schedule_array, 1) THEN
    retry_days := schedule_array[p_retry_count];
  ELSE
    retry_days := schedule_array[array_length(schedule_array, 1)];
  END IF;
  
  RETURN NOW() + INTERVAL '1 day' * retry_days;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update payment retry schedule
CREATE OR REPLACE FUNCTION update_payment_retry_schedule()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'scheduled' AND OLD.retry_count != NEW.retry_count THEN
    NEW.next_retry_at := calculate_next_retry_date(NEW.retry_count);
  END IF;
  
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_payment_retry_schedule
  BEFORE UPDATE ON payment_retries
  FOR EACH ROW
  EXECUTE FUNCTION update_payment_retry_schedule();
```

---

## 🔌 API ENDPOINTS

### POST /api/platform/payments/create-intent
**Create Stripe payment intent**
```typescript
interface CreatePaymentIntentRequest {
  tenantId: string;
  amount: number;
  currency?: string;
  invoiceId?: string;
  subscriptionId?: string;
  paymentMethodId?: string;
  customerId?: string;
  description?: string;
  automaticPaymentMethods?: boolean;
  captureMethod?: 'automatic' | 'manual';
  confirmationMethod?: 'automatic' | 'manual';
  metadata?: Record<string, string>;
}

interface CreatePaymentIntentResponse {
  paymentIntentId: string;
  clientSecret: string;
  status: string;
  amount: number;
  currency: string;
  nextAction?: {
    type: string;
    redirectUrl?: string;
  };
}
```

### POST /api/platform/payments/confirm-intent
**Confirm payment intent**
```typescript
interface ConfirmPaymentIntentRequest {
  paymentIntentId: string;
  paymentMethodId?: string;
  returnUrl?: string;
}

interface ConfirmPaymentIntentResponse {
  status: string;
  paymentTransaction: {
    id: string;
    status: string;
    amount: number;
    currency: string;
  };
  nextAction?: {
    type: string;
    redirectUrl?: string;
  };
}
```

### GET /api/platform/payments
**List payment transactions**
```typescript
interface ListPaymentsRequest {
  page?: number;
  limit?: number;
  tenantId?: string;
  status?: 'pending' | 'processing' | 'succeeded' | 'failed' | 'cancelled' | 'refunded';
  paymentMethod?: string;
  dateFrom?: string;
  dateTo?: string;
  search?: string;
  sortBy?: 'created_at' | 'amount' | 'status';
  sortOrder?: 'asc' | 'desc';
}

interface ListPaymentsResponse {
  payments: Array<{
    id: string;
    tenantName: string;
    amount: number;
    currency: string;
    status: string;
    paymentMethod: string;
    paymentMethodDetails: {
      brand?: string;
      lastFour?: string;
      type: string;
    };
    description?: string;
    invoiceNumber?: string;
    createdAt: string;
    succeededAt?: string;
    failedAt?: string;
    failureMessage?: string;
  }>;
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  summary: {
    totalAmount: number;
    successfulAmount: number;
    failedAmount: number;
    pendingAmount: number;
    successRate: number;
  };
}
```

### GET /api/platform/payments/:id
**Get payment details**
```typescript
interface GetPaymentResponse {
  id: string;
  tenantId: string;
  tenantName: string;
  invoiceId?: string;
  invoiceNumber?: string;
  subscriptionId?: string;
  stripePaymentIntentId: string;
  stripeChargeId?: string;
  amount: number;
  currency: string;
  status: string;
  paymentMethod: string;
  paymentMethodDetails: {
    type: string;
    brand?: string;
    lastFour?: string;
    expMonth?: number;
    expYear?: number;
    billingDetails?: {
      name?: string;
      email?: string;
      address?: any;
    };
  };
  description?: string;
  metadata: Record<string, any>;
  failureCode?: string;
  failureMessage?: string;
  timeline: Array<{
    status: string;
    timestamp: string;
    description: string;
  }>;
  refunds: Array<{
    id: string;
    amount: number;
    reason: string;
    status: string;
    createdAt: string;
  }>;
}
```

### POST /api/platform/payments/:id/refund
**Process refund**
```typescript
interface ProcessRefundRequest {
  amount?: number; // Partial refund amount, full if not specified
  reason?: 'duplicate' | 'fraudulent' | 'requested_by_customer';
  refundApplicationFee?: boolean;
  reverseTransfer?: boolean;
  metadata?: Record<string, string>;
}

interface ProcessRefundResponse {
  refundId: string;
  amount: number;
  status: string;
  expectedArrival: string;
}
```

### POST /api/platform/payments/retry-failed
**Retry failed payments**
```typescript
interface RetryFailedPaymentsRequest {
  tenantIds?: string[];
  paymentIds?: string[];
  maxRetryCount?: number;
}

interface RetryFailedPaymentsResponse {
  retriesScheduled: number;
  errors: Array<{
    paymentId: string;
    error: string;
  }>;
}
```

### GET /api/platform/payment-methods
**List stored payment methods**
```typescript
interface ListPaymentMethodsRequest {
  tenantId?: string;
  type?: 'card' | 'bank_account' | 'digital_wallet';
  isActive?: boolean;
}

interface ListPaymentMethodsResponse {
  paymentMethods: Array<{
    id: string;
    tenantId: string;
    tenantName: string;
    type: string;
    brand?: string;
    lastFour?: string;
    expMonth?: number;
    expYear?: number;
    isDefault: boolean;
    isActive: boolean;
    billingDetails: any;
    createdAt: string;
  }>;
}
```

### POST /api/platform/webhooks/stripe
**Handle Stripe webhooks**
```typescript
interface StripeWebhookEvent {
  id: string;
  object: 'event';
  type: string;
  data: {
    object: any;
    previous_attributes?: any;
  };
  created: number;
  livemode: boolean;
  pending_webhooks: number;
  request: {
    id: string;
    idempotency_key?: string;
  };
}

// Webhook handler processes various Stripe events:
// - payment_intent.succeeded
// - payment_intent.payment_failed
// - charge.dispute.created
// - invoice.payment_succeeded
// - invoice.payment_failed
// - customer.subscription.updated
// - setup_intent.succeeded
```

---

## 🎨 REACT COMPONENTS

### PaymentProcessingDashboard
**Main payment processing interface**
```typescript
interface PaymentProcessingDashboardProps {
  initialData?: ListPaymentsResponse;
}

const PaymentProcessingDashboard: React.FC<PaymentProcessingDashboardProps> = ({
  initialData
}) => {
  const [payments, setPayments] = useState<ListPaymentsResponse | null>(initialData || null);
  const [loading, setLoading] = useState(!initialData);
  const [selectedPayment, setSelectedPayment] = useState<string | null>(null);
  const [filters, setFilters] = useState({
    status: undefined as string | undefined,
    tenantId: undefined as string | undefined,
    paymentMethod: undefined as string | undefined,
    dateFrom: undefined as string | undefined,
    dateTo: undefined as string | undefined,
    search: '',
    page: 1,
    limit: 20,
    sortBy: 'created_at' as const,
    sortOrder: 'desc' as const
  });

  const fetchPayments = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== '') {
          params.append(key, value.toString());
        }
      });

      const response = await fetch(`/api/platform/payments?${params}`);
      if (response.ok) {
        const data = await response.json();
        setPayments(data);
      } else {
        toast.error('Failed to fetch payments');
      }
    } catch (error) {
      toast.error('Error loading payments');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    if (!initialData) {
      fetchPayments();
    }
  }, [fetchPayments, initialData]);

  const handleRetryFailedPayments = async () => {
    try {
      const response = await fetch('/api/platform/payments/retry-failed', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        const result = await response.json();
        toast.success(`${result.retriesScheduled} payments scheduled for retry`);
        fetchPayments();
      } else {
        toast.error('Failed to schedule payment retries');
      }
    } catch (error) {
      toast.error('Error scheduling payment retries');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'succeeded': return 'bg-green-100 text-green-800';
      case 'processing': return 'bg-blue-100 text-blue-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'failed': return 'bg-red-100 text-red-800';
      case 'cancelled': return 'bg-gray-100 text-gray-800';
      case 'refunded': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPaymentMethodIcon = (method: string, brand?: string) => {
    if (method === 'card') {
      switch (brand?.toLowerCase()) {
        case 'visa': return '💳';
        case 'mastercard': return '💳';
        case 'amex': return '💳';
        default: return '💳';
      }
    }
    switch (method) {
      case 'bank_transfer': return '🏦';
      case 'digital_wallet': return '📱';
      default: return '💳';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Payment Processing</h1>
          <p className="text-sm text-gray-500">
            Monitor and manage payment transactions across all tenants
          </p>
        </div>
        
        <div className="flex items-center space-x-2">
          <Button onClick={handleRetryFailedPayments} variant="outline">
            <RefreshCw className="h-4 w-4 mr-2" />
            Retry Failed
          </Button>
          <Button onClick={() => window.location.reload()}>
            <RotateCcw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      {payments && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <StatsCard
            title="Total Volume"
            value={`$${payments.summary.totalAmount.toLocaleString()}`}
            icon={DollarSign}
            trend={{
              value: 15.2,
              label: "vs last month",
              isPositive: true
            }}
          />
          <StatsCard
            title="Successful"
            value={`$${payments.summary.successfulAmount.toLocaleString()}`}
            icon={CheckCircle}
            className="text-green-600"
          />
          <StatsCard
            title="Failed"
            value={`$${payments.summary.failedAmount.toLocaleString()}`}
            icon={XCircle}
            className="text-red-600"
          />
          <StatsCard
            title="Pending"
            value={`$${payments.summary.pendingAmount.toLocaleString()}`}
            icon={Clock}
            className="text-yellow-600"
          />
          <StatsCard
            title="Success Rate"
            value={`${payments.summary.successRate.toFixed(1)}%`}
            icon={TrendingUp}
            className="text-blue-600"
          />
        </div>
      )}

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Filters</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <div>
              <Label>Status</Label>
              <Select
                value={filters.status || 'all'}
                onValueChange={(value) => setFilters(prev => ({
                  ...prev,
                  status: value === 'all' ? undefined : value,
                  page: 1
                }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="All Statuses" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Statuses</SelectItem>
                  <SelectItem value="succeeded">Succeeded</SelectItem>
                  <SelectItem value="processing">Processing</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="failed">Failed</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                  <SelectItem value="refunded">Refunded</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label>Payment Method</Label>
              <Select
                value={filters.paymentMethod || 'all'}
                onValueChange={(value) => setFilters(prev => ({
                  ...prev,
                  paymentMethod: value === 'all' ? undefined : value,
                  page: 1
                }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="All Methods" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Methods</SelectItem>
                  <SelectItem value="card">Credit/Debit Card</SelectItem>
                  <SelectItem value="bank_transfer">Bank Transfer</SelectItem>
                  <SelectItem value="digital_wallet">Digital Wallet</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label>Date From</Label>
              <Input
                type="date"
                value={filters.dateFrom || ''}
                onChange={(e) => setFilters(prev => ({
                  ...prev,
                  dateFrom: e.target.value || undefined,
                  page: 1
                }))}
              />
            </div>

            <div>
              <Label>Date To</Label>
              <Input
                type="date"
                value={filters.dateTo || ''}
                onChange={(e) => setFilters(prev => ({
                  ...prev,
                  dateTo: e.target.value || undefined,
                  page: 1
                }))}
              />
            </div>

            <div>
              <Label>Search</Label>
              <Input
                placeholder="Transaction ID, tenant..."
                value={filters.search}
                onChange={(e) => setFilters(prev => ({
                  ...prev,
                  search: e.target.value,
                  page: 1
                }))}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Payments Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Transaction</TableHead>
                <TableHead>Tenant</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Payment Method</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Date</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                Array.from({ length: 10 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 7 }).map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton className="h-4 w-full" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : payments?.payments.map((payment) => (
                <TableRow key={payment.id}>
                  <TableCell>
                    <div className="space-y-1">
                      <p className="font-medium text-sm">{payment.id.slice(0, 8)}...</p>
                      {payment.invoiceNumber && (
                        <p className="text-xs text-gray-500">Invoice: {payment.invoiceNumber}</p>
                      )}
                      {payment.description && (
                        <p className="text-xs text-gray-500">{payment.description}</p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm font-medium">{payment.tenantName}</span>
                  </TableCell>
                  <TableCell>
                    <span className="font-medium">
                      {payment.currency} {payment.amount.toLocaleString()}
                    </span>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center space-x-2">
                      <span>{getPaymentMethodIcon(payment.paymentMethod, payment.paymentMethodDetails.brand)}</span>
                      <div>
                        <p className="text-sm font-medium">
                          {payment.paymentMethodDetails.brand?.toUpperCase() || payment.paymentMethodDetails.type}
                        </p>
                        {payment.paymentMethodDetails.lastFour && (
                          <p className="text-xs text-gray-500">
                            •••• {payment.paymentMethodDetails.lastFour}
                          </p>
                        )}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge className={getStatusColor(payment.status)}>
                      {payment.status.charAt(0).toUpperCase() + payment.status.slice(1)}
                    </Badge>
                    {payment.status === 'failed' && payment.failureMessage && (
                      <p className="text-xs text-red-600 mt-1" title={payment.failureMessage}>
                        {payment.failureMessage.substring(0, 50)}...
                      </p>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      <p>{format(new Date(payment.createdAt), 'MMM dd, yyyy')}</p>
                      <p className="text-xs text-gray-500">
                        {format(new Date(payment.createdAt), 'HH:mm:ss')}
                      </p>
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end space-x-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setSelectedPayment(payment.id)}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem>
                            <FileText className="h-4 w-4 mr-2" />
                            View Details
                          </DropdownMenuItem>
                          {payment.status === 'succeeded' && (
                            <DropdownMenuItem>
                              <RotateCcw className="h-4 w-4 mr-2" />
                              Process Refund
                            </DropdownMenuItem>
                          )}
                          {payment.status === 'failed' && (
                            <DropdownMenuItem>
                              <RefreshCw className="h-4 w-4 mr-2" />
                              Retry Payment
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuItem>
                            <ExternalLink className="h-4 w-4 mr-2" />
                            View in Stripe
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {payments && (
            <div className="px-6 py-4 border-t">
              <TablePagination
                pagination={payments.pagination}
                onPageChange={(page) => setFilters(prev => ({ ...prev, page }))}
                onLimitChange={(limit) => setFilters(prev => ({ ...prev, limit, page: 1 }))}
              />
            </div>
          )}
        </CardContent>
      </Card>

      {/* Payment Details Modal */}
      {selectedPayment && (
        <PaymentDetailsModal
          paymentId={selectedPayment}
          onClose={() => setSelectedPayment(null)}
          onUpdate={fetchPayments}
        />
      )}
    </div>
  );
};
```

### PaymentDetailsModal
**Detailed payment transaction view**
```typescript
interface PaymentDetailsModalProps {
  paymentId: string;
  onClose: () => void;
  onUpdate: () => void;
}

const PaymentDetailsModal: React.FC<PaymentDetailsModalProps> = ({
  paymentId,
  onClose,
  onUpdate
}) => {
  const [payment, setPayment] = useState<GetPaymentResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [showRefundModal, setShowRefundModal] = useState(false);

  const fetchPaymentDetails = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/platform/payments/${paymentId}`);
      if (response.ok) {
        const data = await response.json();
        setPayment(data);
      } else {
        toast.error('Failed to fetch payment details');
      }
    } catch (error) {
      toast.error('Error loading payment details');
    } finally {
      setLoading(false);
    }
  }, [paymentId]);

  useEffect(() => {
    fetchPaymentDetails();
  }, [fetchPaymentDetails]);

  const handleRefund = async (refundData: ProcessRefundRequest) => {
    try {
      const response = await fetch(`/api/platform/payments/${paymentId}/refund`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(refundData)
      });

      if (response.ok) {
        toast.success('Refund processed successfully');
        fetchPaymentDetails();
        onUpdate();
      } else {
        const error = await response.json();
        toast.error(error.message || 'Failed to process refund');
      }
    } catch (error) {
      toast.error('Error processing refund');
    }
  };

  if (loading || !payment) {
    return (
      <Dialog open onOpenChange={onClose}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <div className="p-6">
            <Skeleton className="h-8 w-64 mb-4" />
            <div className="space-y-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'succeeded': return 'bg-green-100 text-green-800';
      case 'processing': return 'bg-blue-100 text-blue-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'failed': return 'bg-red-100 text-red-800';
      case 'cancelled': return 'bg-gray-100 text-gray-800';
      case 'refunded': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle className="text-xl">
                Payment Transaction
              </DialogTitle>
              <div className="flex items-center space-x-4 mt-2">
                <Badge className={getStatusColor(payment.status)}>
                  {payment status.charAt(0).toUpperCase() + payment.status.slice(1)}
                </Badge>
                <span className="text-sm text-gray-500">
                  ID: {payment.id}
                </span>
              </div>
            </div>
            
            <div className="flex items-center space-x-2">
              {payment.status === 'succeeded' && (
                <Button 
                  onClick={() => setShowRefundModal(true)} 
                  variant="outline" 
                  size="sm"
                >
                  <RotateCcw className="h-4 w-4 mr-2" />
                  Process Refund
                </Button>
              )}
              
              <Button 
                onClick={() => window.open(`https://dashboard.stripe.com/payments/${payment.stripePaymentIntentId}`, '_blank')} 
                variant="outline" 
                size="sm"
              >
                <ExternalLink className="h-4 w-4 mr-2" />
                View in Stripe
              </Button>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Payment Summary */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Amount</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {payment.currency} {payment.amount.toLocaleString()}
                </div>
                {payment.invoiceNumber && (
                  <p className="text-sm text-gray-500 mt-1">
                    Invoice: {payment.invoiceNumber}
                  </p>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Customer</CardTitle>
              </CardHeader>
              <CardContent>
                <div>
                  <p className="font-medium">{payment.tenantName}</p>
                  <p className="text-sm text-gray-600">ID: {payment.tenantId}</p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Payment Method</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-1">
                  <p className="font-medium">
                    {payment.paymentMethodDetails.brand?.toUpperCase() || payment.paymentMethodDetails.type}
                  </p>
                  {payment.paymentMethodDetails.lastFour && (
                    <p className="text-sm text-gray-600">
                      •••• •••• •••• {payment.paymentMethodDetails.lastFour}
                    </p>
                  )}
                  {payment.paymentMethodDetails.expMonth && payment.paymentMethodDetails.expYear && (
                    <p className="text-sm text-gray-600">
                      Expires {String(payment.paymentMethodDetails.expMonth).padStart(2, '0')}/{payment.paymentMethodDetails.expYear}
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Transaction Timeline */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Transaction Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {payment.timeline.map((event, index) => (
                  <div key={index} className="flex items-start space-x-3">
                    <div className={`w-3 h-3 rounded-full mt-1 ${
                      event.status === 'succeeded' ? 'bg-green-500' :
                      event.status === 'failed' ? 'bg-red-500' :
                      event.status === 'processing' ? 'bg-blue-500' :
                      'bg-gray-400'
                    }`} />
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <p className="font-medium capitalize">{event.status.replace('_', ' ')}</p>
                        <span className="text-sm text-gray-500">
                          {format(new Date(event.timestamp), 'MMM dd, yyyy HH:mm:ss')}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600">{event.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Failure Information */}
          {payment.status === 'failed' && (payment.failureCode || payment.failureMessage) && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm text-red-600">Failure Details</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {payment.failureCode && (
                    <div>
                      <span className="font-medium">Error Code: </span>
                      <span className="text-red-600">{payment.failureCode}</span>
                    </div>
                  )}
                  {payment.failureMessage && (
                    <div>
                      <span className="font-medium">Error Message: </span>
                      <span className="text-red-600">{payment.failureMessage}</span>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Refunds */}
          {payment.refunds.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Refunds</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Refund ID</TableHead>
                      <TableHead>Amount</TableHead>
                      <TableHead>Reason</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Date</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {payment.refunds.map((refund) => (
                      <TableRow key={refund.id}>
                        <TableCell className="font-mono text-sm">
                          {refund.id.slice(0, 8)}...
                        </TableCell>
                        <TableCell>
                          {payment.currency} {refund.amount.toLocaleString()}
                        </TableCell>
                        <TableCell className="capitalize">
                          {refund.reason.replace('_', ' ')}
                        </TableCell>
                        <TableCell>
                          <Badge className={getStatusColor(refund.status)}>
                            {refund.status}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {format(new Date(refund.createdAt), 'MMM dd, yyyy')}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* Technical Details */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Technical Details</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="font-medium">Payment Intent ID: </span>
                  <span className="font-mono">{payment.stripePaymentIntentId}</span>
                </div>
                {payment.stripeChargeId && (
                  <div>
                    <span className="font-medium">Charge ID: </span>
                    <span className="font-mono">{payment.stripeChargeId}</span>
                  </div>
                )}
                <div>
                  <span className="font-medium">Payment Method: </span>
                  <span>{payment.paymentMethod}</span>
                </div>
                <div>
                  <span className="font-medium">Currency: </span>
                  <span>{payment.currency}</span>
                </div>
              </div>
              
              {Object.keys(payment.metadata).length > 0 && (
                <div className="mt-4">
                  <h4 className="font-medium mb-2">Metadata</h4>
                  <div className="bg-gray-50 rounded p-3 font-mono text-sm">
                    <pre>{JSON.stringify(payment.metadata, null, 2)}</pre>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Process Refund Modal */}
        {showRefundModal && (
          <ProcessRefundModal
            paymentId={payment.id}
            maxAmount={payment.amount}
            currency={payment.currency}
            onClose={() => setShowRefundModal(false)}
            onSuccess={(refundData) => {
              setShowRefundModal(false);
              handleRefund(refundData);
            }}
          />
        )}
      </DialogContent>
    </Dialog>
  );
};
```

---

## 🔒 SECURITY & VALIDATION

### Stripe Configuration
```typescript
// Stripe configuration
export const stripeConfig = {
  publishableKey: process.env.STRIPE_PUBLISHABLE_KEY!,
  secretKey: process.env.STRIPE_SECRET_KEY!,
  webhookSecret: process.env.STRIPE_WEBHOOK_SECRET!,
  apiVersion: '2023-10-16' as const
};

// Initialize Stripe
const stripe = new Stripe(stripeConfig.secretKey, {
  apiVersion: stripeConfig.apiVersion,
  typescript: true
});
```

### Webhook Security
```typescript
// Verify Stripe webhook signature
export function verifyStripeWebhook(
  payload: string | Buffer,
  signature: string
): Stripe.Event {
  try {
    return stripe.webhooks.constructEvent(
      payload,
      signature,
      stripeConfig.webhookSecret
    );
  } catch (error) {
    throw new Error(`Webhook signature verification failed: ${error.message}`);
  }
}
```

### Input Validation
```typescript
export const createPaymentIntentSchema = z.object({
  tenantId: z.string().uuid(),
  amount: z.number().min(50).max(999999999), // $0.50 to $9,999,999.99
  currency: z.string().length(3).toUpperCase().default('USD'),
  invoiceId: z.string().uuid().optional(),
  subscriptionId: z.string().uuid().optional(),
  paymentMethodId: z.string().optional(),
  description: z.string().max(500).optional(),
  metadata: z.record(z.string()).optional()
});
```

---

## ⚡ PERFORMANCE OPTIMIZATION

### Caching Strategy
```typescript
// Cache payment data
const CACHE_KEYS = {
  PAYMENT_LIST: (filters: string) => `payments:list:${filters}`,
  PAYMENT_DETAILS: (id: string) => `payments:details:${id}`,
  PAYMENT_METHODS: (tenantId: string) => `payments:methods:${tenantId}`
};
```

### Webhook Processing
```typescript
// Idempotent webhook processing
export async function processStripeWebhook(event: Stripe.Event) {
  // Check if event already processed
  const existing = await db.stripe_webhook_events.findUnique({
    where: { stripe_event_id: event.id }
  });

  if (existing?.processed) {
    return { success: true, message: 'Event already processed' };
  }

  try {
    // Process event based on type
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentIntentSucceeded(event.data.object as Stripe.PaymentIntent);
        break;
      case 'payment_intent.payment_failed':
        await handlePaymentIntentFailed(event.data.object as Stripe.PaymentIntent);
        break;
      // ... other event types
    }

    // Mark as processed
    await db.stripe_webhook_events.upsert({
      where: { stripe_event_id: event.id },
      update: { processed: true, processed_at: new Date() },
      create: {
        stripe_event_id: event.id,
        event_type: event.type,
        event_data: event as any,
        processed: true,
        processed_at: new Date()
      }
    });

    return { success: true };
  } catch (error) {
    // Log error but don't mark as processed
    await db.stripe_webhook_events.upsert({
      where: { stripe_event_id: event.id },
      update: { 
        processing_error: error.message,
        processed: false
      },
      create: {
        stripe_event_id: event.id,
        event_type: event.type,
        event_data: event as any,
        processed: false,
        processing_error: error.message
      }
    });

    throw error;
  }
}
```

---

## 🧪 TESTING SPECIFICATIONS

### Unit Tests
```typescript
describe('Payment Processing', () => {
  test('creates payment intent with correct amount', async () => {
    const intent = await createPaymentIntent({
      tenantId: 'test-tenant',
      amount: 2000, // $20.00
      currency: 'USD'
    });
    
    expect(intent.amount).toBe(2000);
    expect(intent.currency).toBe('usd');
  });
  
  test('handles failed payment correctly', async () => {
    const failedPayment = await simulateFailedPayment({
      paymentIntentId: 'pi_test_failed'
    });
    
    expect(failedPayment.status).toBe('failed');
    expect(failedPayment.failureCode).toBeDefined();
  });
});
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: CRITICAL
