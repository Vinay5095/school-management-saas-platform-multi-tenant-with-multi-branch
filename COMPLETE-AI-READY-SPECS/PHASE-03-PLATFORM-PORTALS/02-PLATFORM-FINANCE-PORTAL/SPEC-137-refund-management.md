# SPEC-137: Refund and Credit Management
## Refund Processing and Credit Note System

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 3-4 hours  
> **Dependencies**: SPEC-133, SPEC-132, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive refund management system for processing full and partial refunds, issuing credit notes, and managing account credits.

### Key Features
- ✅ Full and partial refunds
- ✅ Credit note generation
- ✅ Account credit management
- ✅ Refund approval workflow
- ✅ Automated refund processing
- ✅ Refund reason tracking
- ✅ Credit application to invoices
- ✅ Refund analytics
- ✅ Payment reversal handling
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Refund requests table
CREATE TABLE refund_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Refund details
  refund_type TEXT NOT NULL CHECK (refund_type IN ('full', 'partial')),
  original_amount DECIMAL(12, 2) NOT NULL,
  refund_amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Reason and approval
  reason_category TEXT NOT NULL CHECK (reason_category IN ('customer_request', 'billing_error', 'technical_issue', 'dispute', 'cancellation')),
  reason_details TEXT,
  
  -- Approval workflow
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'processed', 'failed')) DEFAULT 'pending',
  requires_approval BOOLEAN DEFAULT TRUE,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  
  -- Processing
  stripe_refund_id TEXT,
  processed_at TIMESTAMPTZ,
  failure_reason TEXT,
  
  -- Audit
  requested_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Credit notes table
CREATE TABLE credit_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
  refund_request_id UUID REFERENCES refund_requests(id) ON DELETE SET NULL,
  
  -- Credit note details
  credit_note_number TEXT NOT NULL UNIQUE,
  credit_amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Reason
  reason TEXT NOT NULL,
  description TEXT,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('draft', 'issued', 'applied', 'cancelled')) DEFAULT 'draft',
  
  -- Dates
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  applied_date DATE,
  
  -- Application
  applied_to_invoice_id UUID REFERENCES invoices(id),
  remaining_credit DECIMAL(12, 2),
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Account credits table (store credit for future use)
CREATE TABLE account_credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  credit_note_id UUID REFERENCES credit_notes(id) ON DELETE CASCADE,
  
  -- Credit details
  credit_amount DECIMAL(12, 2) NOT NULL,
  remaining_amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Expiration
  expires_at DATE,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'exhausted')) DEFAULT 'active',
  
  -- Usage tracking
  last_used_at TIMESTAMPTZ,
  usage_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Credit applications table (track credit usage)
CREATE TABLE credit_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_credit_id UUID NOT NULL REFERENCES account_credits(id) ON DELETE CASCADE,
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  
  -- Application details
  applied_amount DECIMAL(12, 2) NOT NULL,
  application_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Reversal (if credit application is reversed)
  is_reversed BOOLEAN DEFAULT FALSE,
  reversed_at TIMESTAMPTZ,
  reversal_reason TEXT
);

-- Indexes
CREATE INDEX idx_refund_requests_payment ON refund_requests(payment_transaction_id);
CREATE INDEX idx_refund_requests_tenant_status ON refund_requests(tenant_id, status);
CREATE INDEX idx_credit_notes_tenant ON credit_notes(tenant_id, status);
CREATE INDEX idx_credit_notes_number ON credit_notes(credit_note_number);
CREATE INDEX idx_account_credits_tenant ON account_credits(tenant_id, status);
CREATE INDEX idx_credit_applications_credit ON credit_applications(account_credit_id);

-- Function to generate credit note number
CREATE OR REPLACE FUNCTION generate_credit_note_number()
RETURNS TEXT AS $$
DECLARE
  current_year INTEGER := EXTRACT(YEAR FROM NOW());
  sequence_num INTEGER;
  note_number TEXT;
BEGIN
  SELECT COALESCE(MAX(
    CASE 
      WHEN credit_note_number ~ ('^CN-' || current_year || '-[0-9]+$')
      THEN CAST(SPLIT_PART(credit_note_number, '-', 3) AS INTEGER)
      ELSE 0
    END
  ), 0) + 1
  INTO sequence_num
  FROM credit_notes;
  
  note_number := 'CN-' || current_year || '-' || LPAD(sequence_num::TEXT, 4, '0');
  
  RETURN note_number;
END;
$$ LANGUAGE plpgsql;

-- Function to apply credit to invoice
CREATE OR REPLACE FUNCTION apply_credit_to_invoice(
  p_credit_id UUID,
  p_invoice_id UUID,
  p_amount DECIMAL(12, 2) DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_credit RECORD;
  v_invoice RECORD;
  v_application_amount DECIMAL(12, 2);
BEGIN
  -- Get credit details
  SELECT * INTO v_credit
  FROM account_credits
  WHERE id = p_credit_id AND status = 'active';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Active credit not found';
  END IF;
  
  -- Get invoice details
  SELECT * INTO v_invoice
  FROM invoices
  WHERE id = p_invoice_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invoice not found';
  END IF;
  
  -- Determine application amount
  v_application_amount := COALESCE(p_amount, LEAST(v_credit.remaining_amount, v_invoice.total_amount));
  
  IF v_application_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid application amount';
  END IF;
  
  IF v_application_amount > v_credit.remaining_amount THEN
    RAISE EXCEPTION 'Insufficient credit balance';
  END IF;
  
  -- Apply credit
  INSERT INTO credit_applications (
    account_credit_id,
    invoice_id,
    applied_amount
  ) VALUES (
    p_credit_id,
    p_invoice_id,
    v_application_amount
  );
  
  -- Update credit balance
  UPDATE account_credits
  SET 
    remaining_amount = remaining_amount - v_application_amount,
    last_used_at = NOW(),
    usage_count = usage_count + 1,
    status = CASE 
      WHEN remaining_amount - v_application_amount <= 0 THEN 'exhausted'
      ELSE status
    END
  WHERE id = p_credit_id;
  
  -- Update invoice
  UPDATE invoices
  SET 
    total_amount = total_amount - v_application_amount,
    updated_at = NOW()
  WHERE id = p_invoice_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔌 API ENDPOINTS

### POST /api/platform/refunds/create
**Create refund request**
```typescript
interface CreateRefundRequest {
  paymentTransactionId: string;
  refundType: 'full' | 'partial';
  refundAmount?: number; // Required for partial refunds
  reasonCategory: 'customer_request' | 'billing_error' | 'technical_issue' | 'dispute' | 'cancellation';
  reasonDetails?: string;
  createCreditNote?: boolean;
}

interface CreateRefundResponse {
  refundRequestId: string;
  status: 'pending' | 'approved' | 'processed';
  refundAmount: number;
  approvalRequired: boolean;
  creditNoteId?: string;
}
```

### GET /api/platform/refunds
**List refund requests**
```typescript
interface ListRefundsResponse {
  refunds: Array<{
    id: string;
    tenantName: string;
    refundType: string;
    originalAmount: number;
    refundAmount: number;
    status: string;
    reasonCategory: string;
    requestedAt: string;
    approvedAt?: string;
    processedAt?: string;
  }>;
  summary: {
    totalRequests: number;
    pendingApproval: number;
    totalRefunded: number;
    averageProcessingTime: number;
  };
}
```

### POST /api/platform/refunds/:id/approve
**Approve refund request**
```typescript
interface ApproveRefundRequest {
  approved: boolean;
  notes?: string;
  adjustedAmount?: number;
}

interface ApproveRefundResponse {
  success: boolean;
  refundStatus: string;
  processedAmount?: number;
  stripeRefundId?: string;
}
```

### POST /api/platform/credits/create
**Create credit note**
```typescript
interface CreateCreditNoteRequest {
  tenantId: string;
  creditAmount: number;
  reason: string;
  description?: string;
  invoiceId?: string;
  autoApply?: boolean;
  expirationDate?: string;
}

interface CreateCreditNoteResponse {
  creditNoteId: string;
  creditNoteNumber: string;
  accountCreditId?: string;
  appliedToInvoice?: boolean;
}
```

### POST /api/platform/credits/:id/apply
**Apply credit to invoice**
```typescript
interface ApplyCreditRequest {
  invoiceId: string;
  amount?: number; // Partial application
}

interface ApplyCreditResponse {
  success: boolean;
  appliedAmount: number;
  remainingCredit: number;
  invoiceBalance: number;
}
```

---

## 🎨 REACT COMPONENTS

### RefundManagementDashboard
**Main refund and credit management interface**
```typescript
const RefundManagementDashboard: React.FC = () => {
  const [refunds, setRefunds] = useState<ListRefundsResponse | null>(null);
  const [credits, setCredits] = useState<Array<any>>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('refunds');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Refund & Credit Management</h1>
          <p className="text-sm text-gray-500">
            Process refunds and manage account credits
          </p>
        </div>
        
        <div className="flex items-center space-x-2">
          <Button onClick={() => setShowCreateCreditModal(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Create Credit
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      {refunds && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatsCard
            title="Total Requests"
            value={refunds.summary.totalRequests}
            icon={RotateCcw}
            trend={{
              value: -5.2,
              label: "vs last month",
              isPositive: false
            }}
          />
          <StatsCard
            title="Pending Approval"
            value={refunds.summary.pendingApproval}
            icon={Clock}
            className="text-yellow-600"
          />
          <StatsCard
            title="Total Refunded"
            value={`$${refunds.summary.totalRefunded.toLocaleString()}`}
            icon={DollarSign}
            className="text-red-600"
          />
          <StatsCard
            title="Avg Processing Time"
            value={`${refunds.summary.averageProcessingTime}h`}
            icon={Timer}
            className="text-blue-600"
          />
        </div>
      )}

      {/* Tab Navigation */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {[
            { id: 'refunds', name: 'Refund Requests', icon: RotateCcw },
            { id: 'credits', name: 'Credit Notes', icon: FileText },
            { id: 'account-credits', name: 'Account Credits', icon: CreditCard }
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

      {/* Tab Content */}
      <div>
        {activeTab === 'refunds' && <RefundRequestsList refunds={refunds} />}
        {activeTab === 'credits' && <CreditNotesList />}
        {activeTab === 'account-credits' && <AccountCreditsList />}
      </div>
    </div>
  );
};
```

### RefundRequestsList
**List of refund requests with approval workflow**
```typescript
interface RefundRequestsListProps {
  refunds: ListRefundsResponse | null;
}

const RefundRequestsList: React.FC<RefundRequestsListProps> = ({ refunds }) => {
  const [selectedRefund, setSelectedRefund] = useState<string | null>(null);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800';
      case 'processed': return 'bg-blue-100 text-blue-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'rejected': return 'bg-red-100 text-red-800';
      case 'failed': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleApproveRefund = async (refundId: string, approved: boolean) => {
    try {
      const response = await fetch(`/api/platform/refunds/${refundId}/approve`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ approved })
      });

      if (response.ok) {
        toast.success(`Refund ${approved ? 'approved' : 'rejected'} successfully`);
        // Refresh list
      } else {
        toast.error('Failed to update refund status');
      }
    } catch (error) {
      toast.error('Error updating refund status');
    }
  };

  return (
    <Card>
      <CardContent className="p-0">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Refund ID</TableHead>
              <TableHead>Tenant</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Amount</TableHead>
              <TableHead>Reason</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Requested</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {refunds?.refunds.map((refund) => (
              <TableRow key={refund.id}>
                <TableCell>
                  <span className="font-mono text-sm">
                    {refund.id.slice(0, 8)}...
                  </span>
                </TableCell>
                <TableCell>
                  <span className="font-medium">{refund.tenantName}</span>
                </TableCell>
                <TableCell>
                  <Badge variant="outline" className="capitalize">
                    {refund.refundType}
                  </Badge>
                </TableCell>
                <TableCell>
                  <div>
                    <p className="font-medium">${refund.refundAmount.toLocaleString()}</p>
                    <p className="text-xs text-gray-500">
                      of ${refund.originalAmount.toLocaleString()}
                    </p>
                  </div>
                </TableCell>
                <TableCell>
                  <span className="capitalize">
                    {refund.reasonCategory.replace('_', ' ')}
                  </span>
                </TableCell>
                <TableCell>
                  <Badge className={getStatusColor(refund.status)}>
                    {refund.status.charAt(0).toUpperCase() + refund.status.slice(1)}
                  </Badge>
                </TableCell>
                <TableCell>
                  <div className="text-sm">
                    <p>{format(new Date(refund.requestedAt), 'MMM dd, yyyy')}</p>
                    <p className="text-xs text-gray-500">
                      {format(new Date(refund.requestedAt), 'HH:mm:ss')}
                    </p>
                  </div>
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex items-center justify-end space-x-2">
                    {refund.status === 'pending' && (
                      <>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleApproveRefund(refund.id, true)}
                        >
                          <Check className="h-4 w-4 mr-1" />
                          Approve
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleApproveRefund(refund.id, false)}
                        >
                          <X className="h-4 w-4 mr-1" />
                          Reject
                        </Button>
                      </>
                    )}
                    
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedRefund(refund.id)}
                    >
                      <Eye className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
};
```

---

## 🔒 SECURITY & VALIDATION

### Access Control
```typescript
// Middleware for refund management access
export const requireRefundAccess = async (
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

// RLS Policies
CREATE POLICY "Platform finance staff can manage refunds" ON refund_requests
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
export const createRefundRequestSchema = z.object({
  paymentTransactionId: z.string().uuid(),
  refundType: z.enum(['full', 'partial']),
  refundAmount: z.number().min(0.01).optional(),
  reasonCategory: z.enum(['customer_request', 'billing_error', 'technical_issue', 'dispute', 'cancellation']),
  reasonDetails: z.string().max(1000).optional(),
  createCreditNote: z.boolean().optional().default(false)
});
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
