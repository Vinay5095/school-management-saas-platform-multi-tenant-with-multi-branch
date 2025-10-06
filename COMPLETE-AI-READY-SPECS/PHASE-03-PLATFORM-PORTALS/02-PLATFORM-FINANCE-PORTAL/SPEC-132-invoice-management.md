# SPEC-132: Invoice Management System
## Automated Invoice Generation and Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-131, SPEC-123, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive invoice management system for generating, sending, tracking, and managing invoices for all tenant subscriptions with automated billing cycles and payment reconciliation.

### Key Features
- ✅ Automated invoice generation
- ✅ Manual invoice creation
- ✅ Invoice PDF generation
- ✅ Email invoice delivery
- ✅ Payment tracking
- ✅ Invoice status management
- ✅ Credit notes and refunds
- ✅ Tax calculation
- ✅ Invoice history and search
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Invoices table
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  invoice_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled', 'refunded')) DEFAULT 'draft',
  billing_type TEXT NOT NULL CHECK (billing_type IN ('subscription', 'one_time', 'usage', 'addon')),
  
  -- Customer information
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  billing_address JSONB NOT NULL,
  
  -- Financial details
  subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Dates
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  paid_at TIMESTAMPTZ,
  
  -- Invoice details
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  notes TEXT,
  terms TEXT,
  
  -- PDF and delivery
  pdf_url TEXT,
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  
  -- Metadata
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Invoice line items table
CREATE TABLE invoice_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
  unit_price DECIMAL(12, 2) NOT NULL,
  total_price DECIMAL(12, 2) NOT NULL,
  tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- Invoice payments table
CREATE TABLE invoice_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payment_transactions(id) ON DELETE SET NULL,
  amount DECIMAL(12, 2) NOT NULL,
  payment_method TEXT NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reference_number TEXT,
  notes TEXT
);

-- Invoice templates table
CREATE TABLE invoice_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  template_type TEXT NOT NULL CHECK (template_type IN ('subscription', 'one_time', 'usage')),
  html_template TEXT NOT NULL,
  css_styles TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_invoices_tenant_status ON invoices(tenant_id, status);
CREATE INDEX idx_invoices_subscription ON invoices(subscription_id);
CREATE INDEX idx_invoices_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_due_date ON invoices(due_date) WHERE status != 'paid';
CREATE INDEX idx_invoice_line_items_invoice ON invoice_line_items(invoice_id);
CREATE INDEX idx_invoice_payments_invoice ON invoice_payments(invoice_id);

-- Function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  current_year INTEGER := EXTRACT(YEAR FROM NOW());
  sequence_num INTEGER;
  invoice_num TEXT;
BEGIN
  -- Get next sequence number for the year
  SELECT COALESCE(MAX(
    CASE 
      WHEN invoice_number ~ ('^INV-' || current_year || '-[0-9]+$')
      THEN CAST(SPLIT_PART(invoice_number, '-', 3) AS INTEGER)
      ELSE 0
    END
  ), 0) + 1
  INTO sequence_num
  FROM invoices;
  
  -- Format: INV-YYYY-NNNN
  invoice_num := 'INV-' || current_year || '-' || LPAD(sequence_num::TEXT, 4, '0');
  
  RETURN invoice_num;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate invoice number
CREATE OR REPLACE FUNCTION set_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
    NEW.invoice_number := generate_invoice_number();
  END IF;
  
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_invoice_number
  BEFORE INSERT OR UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION set_invoice_number();
```

---

## 🔌 API ENDPOINTS

### POST /api/platform/invoices
**Create new invoice**
```typescript
interface CreateInvoiceRequest {
  tenantId: string;
  subscriptionId?: string;
  billingType: 'subscription' | 'one_time' | 'usage' | 'addon';
  customerInfo: {
    name: string;
    email: string;
    billingAddress: {
      line1: string;
      line2?: string;
      city: string;
      state: string;
      postalCode: string;
      country: string;
    };
  };
  lineItems: Array<{
    description: string;
    quantity: number;
    unitPrice: number;
    taxRate?: number;
  }>;
  dueDate: string;
  notes?: string;
  terms?: string;
  autoSend?: boolean;
}

interface CreateInvoiceResponse {
  id: string;
  invoiceNumber: string;
  status: string;
  totalAmount: number;
  dueDate: string;
  pdfUrl?: string;
}
```

### GET /api/platform/invoices
**List invoices with filtering**
```typescript
interface ListInvoicesRequest {
  page?: number;
  limit?: number;
  status?: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled' | 'refunded';
  tenantId?: string;
  subscriptionId?: string;
  dateFrom?: string;
  dateTo?: string;
  search?: string;
  sortBy?: 'created_at' | 'due_date' | 'total_amount' | 'invoice_number';
  sortOrder?: 'asc' | 'desc';
}

interface ListInvoicesResponse {
  invoices: Array<{
    id: string;
    invoiceNumber: string;
    tenantName: string;
    customerName: string;
    customerEmail: string;
    status: string;
    totalAmount: number;
    currency: string;
    issueDate: string;
    dueDate: string;
    paidAt?: string;
    overdueDays?: number;
  }>;
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  summary: {
    totalAmount: number;
    paidAmount: number;
    outstandingAmount: number;
    overdueAmount: number;
  };
}
```

### GET /api/platform/invoices/:id
**Get invoice details**
```typescript
interface GetInvoiceResponse {
  id: string;
  invoiceNumber: string;
  status: string;
  billingType: string;
  tenant: {
    id: string;
    name: string;
    email: string;
  };
  customer: {
    name: string;
    email: string;
    billingAddress: AddressInfo;
  };
  amounts: {
    subtotal: number;
    taxAmount: number;
    discountAmount: number;
    totalAmount: number;
    paidAmount: number;
    balanceDue: number;
    currency: string;
  };
  dates: {
    issueDate: string;
    dueDate: string;
    paidAt?: string;
    sentAt?: string;
    viewedAt?: string;
  };
  lineItems: Array<{
    id: string;
    description: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
    taxRate: number;
  }>;
  payments: Array<{
    id: string;
    amount: number;
    paymentMethod: string;
    paymentDate: string;
    referenceNumber: string;
  }>;
  notes?: string;
  terms?: string;
  pdfUrl?: string;
}
```

### POST /api/platform/invoices/:id/send
**Send invoice via email**
```typescript
interface SendInvoiceRequest {
  emailTemplate?: string;
  customMessage?: string;
  ccEmails?: string[];
  attachPdf?: boolean;
}

interface SendInvoiceResponse {
  success: boolean;
  sentAt: string;
  emailId: string;
}
```

### POST /api/platform/invoices/:id/generate-pdf
**Generate invoice PDF**
```typescript
interface GeneratePdfRequest {
  templateId?: string;
  includePaymentLink?: boolean;
}

interface GeneratePdfResponse {
  pdfUrl: string;
  expiresAt: string;
}
```

### POST /api/platform/invoices/:id/record-payment
**Record manual payment**
```typescript
interface RecordPaymentRequest {
  amount: number;
  paymentMethod: string;
  paymentDate: string;
  referenceNumber?: string;
  notes?: string;
}

interface RecordPaymentResponse {
  paymentId: string;
  invoiceStatus: string;
  remainingBalance: number;
}
```

### PUT /api/platform/invoices/:id
**Update invoice**
```typescript
interface UpdateInvoiceRequest {
  customerInfo?: {
    name?: string;
    email?: string;
    billingAddress?: AddressInfo;
  };
  lineItems?: Array<LineItem>;
  dueDate?: string;
  notes?: string;
  terms?: string;
}

interface UpdateInvoiceResponse {
  success: boolean;
  invoice: GetInvoiceResponse;
}
```

### POST /api/platform/invoices/:id/cancel
**Cancel invoice**
```typescript
interface CancelInvoiceRequest {
  reason?: string;
}

interface CancelInvoiceResponse {
  success: boolean;
  cancelledAt: string;
}
```

---

## 🎨 REACT COMPONENTS

### InvoiceManagementDashboard
**Main invoice management interface**
```typescript
interface InvoiceManagementDashboardProps {
  initialData?: ListInvoicesResponse;
}

const InvoiceManagementDashboard: React.FC<InvoiceManagementDashboardProps> = ({
  initialData
}) => {
  const [invoices, setInvoices] = useState<ListInvoicesResponse | null>(initialData || null);
  const [loading, setLoading] = useState(!initialData);
  const [selectedInvoice, setSelectedInvoice] = useState<string | null>(null);
  const [filters, setFilters] = useState({
    status: undefined as string | undefined,
    tenantId: undefined as string | undefined,
    dateFrom: undefined as string | undefined,
    dateTo: undefined as string | undefined,
    search: '',
    page: 1,
    limit: 20,
    sortBy: 'created_at' as const,
    sortOrder: 'desc' as const
  });

  const fetchInvoices = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== '') {
          params.append(key, value.toString());
        }
      });

      const response = await fetch(`/api/platform/invoices?${params}`);
      if (response.ok) {
        const data = await response.json();
        setInvoices(data);
      } else {
        toast.error('Failed to fetch invoices');
      }
    } catch (error) {
      toast.error('Error loading invoices');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    if (!initialData) {
      fetchInvoices();
    }
  }, [fetchInvoices, initialData]);

  const handleCreateInvoice = () => {
    // Open create invoice modal
    setSelectedInvoice('new');
  };

  const handleSendInvoice = async (invoiceId: string) => {
    try {
      const response = await fetch(`/api/platform/invoices/${invoiceId}/send`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ attachPdf: true })
      });

      if (response.ok) {
        toast.success('Invoice sent successfully');
        fetchInvoices();
      } else {
        toast.error('Failed to send invoice');
      }
    } catch (error) {
      toast.error('Error sending invoice');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return 'bg-green-100 text-green-800';
      case 'sent': return 'bg-blue-100 text-blue-800';
      case 'overdue': return 'bg-red-100 text-red-800';
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'cancelled': return 'bg-yellow-100 text-yellow-800';
      case 'refunded': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Invoice Management</h1>
          <p className="text-sm text-gray-500">
            Manage invoices, payments, and billing for all tenants
          </p>
        </div>
        
        <Button onClick={handleCreateInvoice}>
          <Plus className="h-4 w-4 mr-2" />
          Create Invoice
        </Button>
      </div>

      {/* Summary Cards */}
      {invoices && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatsCard
            title="Total Amount"
            value={`$${invoices.summary.totalAmount.toLocaleString()}`}
            icon={DollarSign}
            trend={{
              value: 12.5,
              label: "vs last month",
              isPositive: true
            }}
          />
          <StatsCard
            title="Paid Amount"
            value={`$${invoices.summary.paidAmount.toLocaleString()}`}
            icon={CheckCircle}
            className="text-green-600"
          />
          <StatsCard
            title="Outstanding"
            value={`$${invoices.summary.outstandingAmount.toLocaleString()}`}
            icon={Clock}
            className="text-blue-600"
          />
          <StatsCard
            title="Overdue"
            value={`$${invoices.summary.overdueAmount.toLocaleString()}`}
            icon={AlertTriangle}
            className="text-red-600"
          />
        </div>
      )}

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Filters</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
                  <SelectItem value="draft">Draft</SelectItem>
                  <SelectItem value="sent">Sent</SelectItem>
                  <SelectItem value="paid">Paid</SelectItem>
                  <SelectItem value="overdue">Overdue</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                  <SelectItem value="refunded">Refunded</SelectItem>
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
                placeholder="Invoice number, customer..."
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

      {/* Invoices Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Invoice #</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Tenant</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Issue Date</TableHead>
                <TableHead>Due Date</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 8 }).map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton className="h-4 w-full" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : invoices?.invoices.map((invoice) => (
                <TableRow key={invoice.id}>
                  <TableCell>
                    <div className="font-medium">{invoice.invoiceNumber}</div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <p className="font-medium">{invoice.customerName}</p>
                      <p className="text-sm text-gray-500">{invoice.customerEmail}</p>
                    </div>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm">{invoice.tenantName}</span>
                  </TableCell>
                  <TableCell>
                    <span className="font-medium">
                      {invoice.currency} {invoice.totalAmount.toLocaleString()}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Badge className={getStatusColor(invoice.status)}>
                      {invoice.status.charAt(0).toUpperCase() + invoice.status.slice(1)}
                    </Badge>
                    {invoice.overdueDays && invoice.overdueDays > 0 && (
                      <div className="text-xs text-red-600 mt-1">
                        {invoice.overdueDays} days overdue
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    {format(new Date(invoice.issueDate), 'MMM dd, yyyy')}
                  </TableCell>
                  <TableCell>
                    {format(new Date(invoice.dueDate), 'MMM dd, yyyy')}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end space-x-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setSelectedInvoice(invoice.id)}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      
                      {invoice.status === 'draft' && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleSendInvoice(invoice.id)}
                        >
                          <Send className="h-4 w-4 mr-1" />
                          Send
                        </Button>
                      )}
                      
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem>
                            <FileText className="h-4 w-4 mr-2" />
                            View PDF
                          </DropdownMenuItem>
                          <DropdownMenuItem>
                            <Download className="h-4 w-4 mr-2" />
                            Download
                          </DropdownMenuItem>
                          <DropdownMenuItem>
                            <Copy className="h-4 w-4 mr-2" />
                            Duplicate
                          </DropdownMenuItem>
                          {invoice.status === 'sent' && (
                            <DropdownMenuItem>
                              <CreditCard className="h-4 w-4 mr-2" />
                              Record Payment
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          <DropdownMenuItem className="text-red-600">
                            <Trash2 className="h-4 w-4 mr-2" />
                            Cancel Invoice
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {invoices && (
            <div className="px-6 py-4 border-t">
              <TablePagination
                pagination={invoices.pagination}
                onPageChange={(page) => setFilters(prev => ({ ...prev, page }))}
                onLimitChange={(limit) => setFilters(prev => ({ ...prev, limit, page: 1 }))}
              />
            </div>
          )}
        </CardContent>
      </Card>

      {/* Invoice Details Modal */}
      {selectedInvoice && selectedInvoice !== 'new' && (
        <InvoiceDetailsModal
          invoiceId={selectedInvoice}
          onClose={() => setSelectedInvoice(null)}
          onUpdate={fetchInvoices}
        />
      )}

      {/* Create Invoice Modal */}
      {selectedInvoice === 'new' && (
        <CreateInvoiceModal
          onClose={() => setSelectedInvoice(null)}
          onSuccess={() => {
            setSelectedInvoice(null);
            fetchInvoices();
          }}
        />
      )}
    </div>
  );
};
```

### InvoiceDetailsModal
**Detailed invoice view and management**
```typescript
interface InvoiceDetailsModalProps {
  invoiceId: string;
  onClose: () => void;
  onUpdate: () => void;
}

const InvoiceDetailsModal: React.FC<InvoiceDetailsModalProps> = ({
  invoiceId,
  onClose,
  onUpdate
}) => {
  const [invoice, setInvoice] = useState<GetInvoiceResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);

  const fetchInvoiceDetails = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/platform/invoices/${invoiceId}`);
      if (response.ok) {
        const data = await response.json();
        setInvoice(data);
      } else {
        toast.error('Failed to fetch invoice details');
      }
    } catch (error) {
      toast.error('Error loading invoice details');
    } finally {
      setLoading(false);
    }
  }, [invoiceId]);

  useEffect(() => {
    fetchInvoiceDetails();
  }, [fetchInvoiceDetails]);

  const handleSendInvoice = async () => {
    try {
      const response = await fetch(`/api/platform/invoices/${invoiceId}/send`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ attachPdf: true })
      });

      if (response.ok) {
        toast.success('Invoice sent successfully');
        fetchInvoiceDetails();
        onUpdate();
      } else {
        toast.error('Failed to send invoice');
      }
    } catch (error) {
      toast.error('Error sending invoice');
    }
  };

  const handleGeneratePdf = async () => {
    try {
      const response = await fetch(`/api/platform/invoices/${invoiceId}/generate-pdf`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ includePaymentLink: true })
      });

      if (response.ok) {
        const data = await response.json();
        window.open(data.pdfUrl, '_blank');
      } else {
        toast.error('Failed to generate PDF');
      }
    } catch (error) {
      toast.error('Error generating PDF');
    }
  };

  if (loading || !invoice) {
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
      case 'paid': return 'bg-green-100 text-green-800';
      case 'sent': return 'bg-blue-100 text-blue-800';
      case 'overdue': return 'bg-red-100 text-red-800';
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'cancelled': return 'bg-yellow-100 text-yellow-800';
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
                Invoice {invoice.invoiceNumber}
              </DialogTitle>
              <div className="flex items-center space-x-4 mt-2">
                <Badge className={getStatusColor(invoice.status)}>
                  {invoice.status.charAt(0).toUpperCase() + invoice.status.slice(1)}
                </Badge>
                <span className="text-sm text-gray-500">
                  Issued: {format(new Date(invoice.dates.issueDate), 'MMM dd, yyyy')}
                </span>
                <span className="text-sm text-gray-500">
                  Due: {format(new Date(invoice.dates.dueDate), 'MMM dd, yyyy')}
                </span>
              </div>
            </div>
            
            <div className="flex items-center space-x-2">
              {invoice.status === 'draft' && (
                <Button onClick={handleSendInvoice} size="sm">
                  <Send className="h-4 w-4 mr-2" />
                  Send Invoice
                </Button>
              )}
              
              <Button onClick={handleGeneratePdf} variant="outline" size="sm">
                <FileText className="h-4 w-4 mr-2" />
                View PDF
              </Button>
              
              {invoice.status === 'sent' && (
                <Button 
                  onClick={() => setShowPaymentModal(true)} 
                  variant="outline" 
                  size="sm"
                >
                  <CreditCard className="h-4 w-4 mr-2" />
                  Record Payment
                </Button>
              )}
              
              {invoice.status === 'draft' && (
                <Button 
                  onClick={() => setShowEditModal(true)} 
                  variant="outline" 
                  size="sm"
                >
                  <Edit className="h-4 w-4 mr-2" />
                  Edit
                </Button>
              )}
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Customer and Tenant Info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Bill To</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-1">
                  <p className="font-medium">{invoice.customer.name}</p>
                  <p className="text-sm text-gray-600">{invoice.customer.email}</p>
                  <div className="text-sm text-gray-600">
                    <p>{invoice.customer.billingAddress.line1}</p>
                    {invoice.customer.billingAddress.line2 && (
                      <p>{invoice.customer.billingAddress.line2}</p>
                    )}
                    <p>
                      {invoice.customer.billingAddress.city}, {invoice.customer.billingAddress.state} {invoice.customer.billingAddress.postalCode}
                    </p>
                    <p>{invoice.customer.billingAddress.country}</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Tenant</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-1">
                  <p className="font-medium">{invoice.tenant.name}</p>
                  <p className="text-sm text-gray-600">{invoice.tenant.email}</p>
                  <p className="text-sm text-gray-600">ID: {invoice.tenant.id}</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Line Items */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Line Items</CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Description</TableHead>
                    <TableHead className="text-right">Qty</TableHead>
                    <TableHead className="text-right">Unit Price</TableHead>
                    <TableHead className="text-right">Tax</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {invoice.lineItems.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>{item.description}</TableCell>
                      <TableCell className="text-right">{item.quantity}</TableCell>
                      <TableCell className="text-right">
                        {invoice.amounts.currency} {item.unitPrice.toLocaleString()}
                      </TableCell>
                      <TableCell className="text-right">{item.taxRate}%</TableCell>
                      <TableCell className="text-right font-medium">
                        {invoice.amounts.currency} {item.totalPrice.toLocaleString()}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          {/* Amount Summary */}
          <div className="flex justify-end">
            <Card className="w-80">
              <CardContent className="p-4">
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span>Subtotal:</span>
                    <span>{invoice.amounts.currency} {invoice.amounts.subtotal.toLocaleString()}</span>
                  </div>
                  {invoice.amounts.discountAmount > 0 && (
                    <div className="flex justify-between text-green-600">
                      <span>Discount:</span>
                      <span>-{invoice.amounts.currency} {invoice.amounts.discountAmount.toLocaleString()}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span>Tax:</span>
                    <span>{invoice.amounts.currency} {invoice.amounts.taxAmount.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between font-bold border-t pt-2">
                    <span>Total:</span>
                    <span>{invoice.amounts.currency} {invoice.amounts.totalAmount.toLocaleString()}</span>
                  </div>
                  {invoice.amounts.paidAmount > 0 && (
                    <div className="flex justify-between text-green-600">
                      <span>Paid:</span>
                      <span>-{invoice.amounts.currency} {invoice.amounts.paidAmount.toLocaleString()}</span>
                    </div>
                  )}
                  {invoice.amounts.balanceDue > 0 && (
                    <div className="flex justify-between font-bold text-red-600 border-t pt-2">
                      <span>Balance Due:</span>
                      <span>{invoice.amounts.currency} {invoice.amounts.balanceDue.toLocaleString()}</span>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Payments History */}
          {invoice.payments.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Payment History</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Date</TableHead>
                      <TableHead>Amount</TableHead>
                      <TableHead>Method</TableHead>
                      <TableHead>Reference</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {invoice.payments.map((payment) => (
                      <TableRow key={payment.id}>
                        <TableCell>
                          {format(new Date(payment.paymentDate), 'MMM dd, yyyy')}
                        </TableCell>
                        <TableCell className="font-medium">
                          {invoice.amounts.currency} {payment.amount.toLocaleString()}
                        </TableCell>
                        <TableCell>{payment.paymentMethod}</TableCell>
                        <TableCell>{payment.referenceNumber}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* Notes and Terms */}
          {(invoice.notes || invoice.terms) && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {invoice.notes && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-sm">Notes</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-gray-600">{invoice.notes}</p>
                  </CardContent>
                </Card>
              )}

              {invoice.terms && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-sm">Terms & Conditions</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-gray-600">{invoice.terms}</p>
                  </CardContent>
                </Card>
              )}
            </div>
          )}
        </div>

        {/* Record Payment Modal */}
        {showPaymentModal && (
          <RecordPaymentModal
            invoiceId={invoice.id}
            balanceDue={invoice.amounts.balanceDue}
            currency={invoice.amounts.currency}
            onClose={() => setShowPaymentModal(false)}
            onSuccess={() => {
              setShowPaymentModal(false);
              fetchInvoiceDetails();
              onUpdate();
            }}
          />
        )}

        {/* Edit Invoice Modal */}
        {showEditModal && (
          <EditInvoiceModal
            invoice={invoice}
            onClose={() => setShowEditModal(false)}
            onSuccess={() => {
              setShowEditModal(false);
              fetchInvoiceDetails();
              onUpdate();
            }}
          />
        )}
      </DialogContent>
    </Dialog>
  );
};
```

### CreateInvoiceModal
**Create new invoice interface**
```typescript
interface CreateInvoiceModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

const CreateInvoiceModal: React.FC<CreateInvoiceModalProps> = ({
  onClose,
  onSuccess
}) => {
  const [loading, setLoading] = useState(false);
  const [tenants, setTenants] = useState<Array<{ id: string; name: string; email: string }>>([]);
  const [selectedTenant, setSelectedTenant] = useState<string>('');
  
  const form = useForm<CreateInvoiceRequest>({
    resolver: zodResolver(createInvoiceSchema),
    defaultValues: {
      lineItems: [{
        description: '',
        quantity: 1,
        unitPrice: 0,
        taxRate: 0
      }],
      billingType: 'one_time',
      dueDate: format(addDays(new Date(), 30), 'yyyy-MM-dd'),
      autoSend: false
    }
  });

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'lineItems'
  });

  useEffect(() => {
    // Fetch tenants for dropdown
    const fetchTenants = async () => {
      try {
        const response = await fetch('/api/platform/tenants');
        if (response.ok) {
          const data = await response.json();
          setTenants(data.tenants);
        }
      } catch (error) {
        console.error('Failed to fetch tenants:', error);
      }
    };

    fetchTenants();
  }, []);

  const onSubmit = async (data: CreateInvoiceRequest) => {
    setLoading(true);
    try {
      const response = await fetch('/api/platform/invoices', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });

      if (response.ok) {
        toast.success('Invoice created successfully');
        onSuccess();
      } else {
        const error = await response.json();
        toast.error(error.message || 'Failed to create invoice');
      }
    } catch (error) {
      toast.error('Error creating invoice');
    } finally {
      setLoading(false);
    }
  };

  const calculateTotal = () => {
    const lineItems = form.watch('lineItems');
    return lineItems.reduce((total, item) => {
      const itemTotal = item.quantity * item.unitPrice;
      const taxAmount = itemTotal * (item.taxRate / 100);
      return total + itemTotal + taxAmount;
    }, 0);
  };

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Invoice</DialogTitle>
          <DialogDescription>
            Create a new invoice for a tenant
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Basic Information */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="tenantId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Tenant *</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select tenant" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {tenants.map((tenant) => (
                          <SelectItem key={tenant.id} value={tenant.id}>
                            {tenant.name} ({tenant.email})
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="billingType"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Billing Type *</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="subscription">Subscription</SelectItem>
                        <SelectItem value="one_time">One-time</SelectItem>
                        <SelectItem value="usage">Usage-based</SelectItem>
                        <SelectItem value="addon">Add-on</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="dueDate"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Due Date *</FormLabel>
                    <FormControl>
                      <Input type="date" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="autoSend"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-center justify-between rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <FormLabel className="text-base">
                        Auto Send
                      </FormLabel>
                      <FormDescription>
                        Automatically send invoice after creation
                      </FormDescription>
                    </div>
                    <FormControl>
                      <Switch
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                  </FormItem>
                )}
              />
            </div>

            {/* Customer Information */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Customer Information</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="customerInfo.name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Customer Name *</FormLabel>
                      <FormControl>
                        <Input placeholder="Enter customer name" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="customerInfo.email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email *</FormLabel>
                      <FormControl>
                        <Input type="email" placeholder="customer@example.com" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="customerInfo.billingAddress.line1"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Address Line 1 *</FormLabel>
                      <FormControl>
                        <Input placeholder="Street address" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="customerInfo.billingAddress.line2"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Address Line 2</FormLabel>
                      <FormControl>
                        <Input placeholder="Apartment, suite, etc." {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="customerInfo.billingAddress.city"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>City *</FormLabel>
                      <FormControl>
                        <Input placeholder="City" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="customerInfo.billingAddress.state"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>State/Province *</FormLabel>
                      <FormControl>
                        <Input placeholder="State or Province" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="customerInfo.billingAddress.postalCode"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Postal Code *</FormLabel>
                      <FormControl>
                        <Input placeholder="Postal code" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="customerInfo.billingAddress.country"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Country *</FormLabel>
                      <FormControl>
                        <Input placeholder="Country" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </div>

            {/* Line Items */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium">Line Items</h3>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => append({ description: '', quantity: 1, unitPrice: 0, taxRate: 0 })}
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Add Item
                </Button>
              </div>

              <div className="space-y-4">
                {fields.map((field, index) => (
                  <Card key={field.id}>
                    <CardContent className="p-4">
                      <div className="grid grid-cols-1 md:grid-cols-5 gap-4 items-end">
                        <FormField
                          control={form.control}
                          name={`lineItems.${index}.description`}
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Description *</FormLabel>
                              <FormControl>
                                <Input placeholder="Item description" {...field} />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`lineItems.${index}.quantity`}
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Qty *</FormLabel>
                              <FormControl>
                                <Input
                                  type="number"
                                  min="0"
                                  step="0.01"
                                  {...field}
                                  onChange={(e) => field.onChange(parseFloat(e.target.value) || 0)}
                                />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`lineItems.${index}.unitPrice`}
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Unit Price *</FormLabel>
                              <FormControl>
                                <Input
                                  type="number"
                                  min="0"
                                  step="0.01"
                                  {...field}
                                  onChange={(e) => field.onChange(parseFloat(e.target.value) || 0)}
                                />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`lineItems.${index}.taxRate`}
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Tax %</FormLabel>
                              <FormControl>
                                <Input
                                  type="number"
                                  min="0"
                                  max="100"
                                  step="0.01"
                                  {...field}
                                  onChange={(e) => field.onChange(parseFloat(e.target.value) || 0)}
                                />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />

                        <div className="flex items-center space-x-2">
                          <span className="text-sm font-medium">
                            ${((form.watch(`lineItems.${index}.quantity`) || 0) * 
                               (form.watch(`lineItems.${index}.unitPrice`) || 0) * 
                               (1 + (form.watch(`lineItems.${index}.taxRate`) || 0) / 100)).toFixed(2)}
                          </span>
                          {fields.length > 1 && (
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              onClick={() => remove(index)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>

              <div className="flex justify-end">
                <div className="text-right">
                  <p className="text-lg font-semibold">
                    Total: ${calculateTotal().toFixed(2)}
                  </p>
                </div>
              </div>
            </div>

            {/* Notes and Terms */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Notes</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Additional notes for the invoice"
                        className="resize-none"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="terms"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Terms & Conditions</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Payment terms and conditions"
                        className="resize-none"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <DialogFooter>
              <Button type="button" variant="outline" onClick={onClose}>
                Cancel
              </Button>
              <Button type="submit" disabled={loading}>
                {loading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Create Invoice
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
};
```

---

## 🔒 SECURITY & VALIDATION

### Access Control
```typescript
// Middleware for platform admin access
export const requirePlatformFinanceAccess = async (
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
CREATE POLICY "Platform finance staff can manage all invoices" ON invoices
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
export const createInvoiceSchema = z.object({
  tenantId: z.string().uuid(),
  subscriptionId: z.string().uuid().optional(),
  billingType: z.enum(['subscription', 'one_time', 'usage', 'addon']),
  customerInfo: z.object({
    name: z.string().min(1).max(100),
    email: z.string().email(),
    billingAddress: z.object({
      line1: z.string().min(1).max(200),
      line2: z.string().max(200).optional(),
      city: z.string().min(1).max(100),
      state: z.string().min(1).max(100),
      postalCode: z.string().min(1).max(20),
      country: z.string().min(1).max(100)
    })
  }),
  lineItems: z.array(z.object({
    description: z.string().min(1).max(500),
    quantity: z.number().min(0.01),
    unitPrice: z.number().min(0),
    taxRate: z.number().min(0).max(100).optional().default(0)
  })).min(1),
  dueDate: z.string().datetime(),
  notes: z.string().max(1000).optional(),
  terms: z.string().max(2000).optional(),
  autoSend: z.boolean().optional().default(false)
});
```

---

## ⚡ PERFORMANCE OPTIMIZATION

### Caching Strategy
```typescript
// Redis cache for invoice data
const CACHE_KEYS = {
  INVOICE_LIST: (filters: string) => `invoices:list:${filters}`,
  INVOICE_DETAILS: (id: string) => `invoices:details:${id}`,
  INVOICE_PDF: (id: string) => `invoices:pdf:${id}`
};

// Cache invoice list for 5 minutes
export async function getCachedInvoiceList(cacheKey: string) {
  try {
    const cached = await redis.get(cacheKey);
    return cached ? JSON.parse(cached) : null;
  } catch (error) {
    console.warn('Cache miss for invoice list:', error);
    return null;
  }
}
```

### Database Optimization
```sql
-- Optimized query for invoice dashboard
CREATE OR REPLACE VIEW invoice_dashboard_summary AS
SELECT 
  COUNT(*) as total_invoices,
  SUM(total_amount) as total_amount,
  SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END) as paid_amount,
  SUM(CASE WHEN status IN ('sent', 'overdue') THEN total_amount ELSE 0 END) as outstanding_amount,
  SUM(CASE WHEN status = 'overdue' THEN total_amount ELSE 0 END) as overdue_amount,
  AVG(CASE WHEN status = 'paid' AND paid_at IS NOT NULL 
           THEN EXTRACT(DAY FROM paid_at - issue_date) END) as avg_payment_days
FROM invoices 
WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE);
```

---

## 🧪 TESTING SPECIFICATIONS

### Unit Tests
```typescript
describe('Invoice Management', () => {
  test('creates invoice with correct calculations', async () => {
    const invoice = await createInvoice({
      lineItems: [
        { description: 'Service 1', quantity: 2, unitPrice: 100, taxRate: 10 }
      ]
    });
    
    expect(invoice.subtotal).toBe(200);
    expect(invoice.taxAmount).toBe(20);
    expect(invoice.totalAmount).toBe(220);
  });
  
  test('generates unique invoice numbers', async () => {
    const invoice1 = await createInvoice({});
    const invoice2 = await createInvoice({});
    
    expect(invoice1.invoiceNumber).not.toBe(invoice2.invoiceNumber);
    expect(invoice1.invoiceNumber).toMatch(/^INV-\d{4}-\d{4}$/);
  });
});
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
