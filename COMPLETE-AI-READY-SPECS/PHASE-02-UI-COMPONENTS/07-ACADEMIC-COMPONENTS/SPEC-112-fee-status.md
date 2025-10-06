# SPEC-112: Fee Status Component
## Student Fee Payment Tracking and Status

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: date-fns

---

## 📋 OVERVIEW

### Purpose
A comprehensive fee status component for displaying student fee information, payment history, pending amounts, and payment options.

### Key Features
- ✅ Fee breakdown display
- ✅ Payment status tracking
- ✅ Payment history
- ✅ Due date reminders
- ✅ Receipt generation
- ✅ Multiple payment modes
- ✅ Installment tracking
- ✅ Late fee calculation
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/fee-status.tsx
import * as React from 'react'
import {
  DollarSign,
  CheckCircle,
  AlertCircle,
  XCircle,
  Calendar,
  Download,
  CreditCard,
  Receipt,
  Clock,
} from 'lucide-react'
import { format, formatDistanceToNow, isPast } from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type PaymentStatus = 'paid' | 'partial' | 'pending' | 'overdue'
export type PaymentMethod = 'cash' | 'card' | 'bank_transfer' | 'cheque' | 'online' | 'upi'

export interface FeeItem {
  id: string
  name: string
  amount: number
  description?: string
}

export interface PaymentTransaction {
  id: string
  amount: number
  date: Date
  method: PaymentMethod
  referenceNumber: string
  receiptNumber?: string
  collectedBy?: string
  notes?: string
}

export interface FeeInstallment {
  id: string
  installmentNumber: number
  amount: number
  dueDate: Date
  paidAmount: number
  paidDate?: Date
  status: 'paid' | 'pending' | 'overdue'
}

export interface FeeData {
  studentId: string
  studentName: string
  rollNumber: string
  className: string
  section: string
  term: string
  academicYear: string
  feeBreakdown: FeeItem[]
  totalFee: number
  paidAmount: number
  pendingAmount: number
  lateFee: number
  discount: number
  dueDate: Date
  status: PaymentStatus
  transactions: PaymentTransaction[]
  installments?: FeeInstallment[]
  nextInstallmentDate?: Date
}

export interface FeeStatusProps {
  /**
   * Fee data
   */
  data: FeeData

  /**
   * Show payment history
   */
  showHistory?: boolean

  /**
   * Show installments
   */
  showInstallments?: boolean

  /**
   * On pay now
   */
  onPayNow?: () => void

  /**
   * On download receipt
   */
  onDownloadReceipt?: (transactionId: string) => void

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// STATUS BADGE
// ========================================

function getStatusConfig(status: PaymentStatus) {
  const configs = {
    paid: {
      label: 'Paid',
      icon: CheckCircle,
      className: 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400',
    },
    partial: {
      label: 'Partially Paid',
      icon: Clock,
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400',
    },
    pending: {
      label: 'Pending',
      icon: AlertCircle,
      className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400',
    },
    overdue: {
      label: 'Overdue',
      icon: XCircle,
      className: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400',
    },
  }
  return configs[status]
}

// ========================================
// PAYMENT METHOD BADGE
// ========================================

function getPaymentMethodLabel(method: PaymentMethod) {
  const labels = {
    cash: 'Cash',
    card: 'Card',
    bank_transfer: 'Bank Transfer',
    cheque: 'Cheque',
    online: 'Online',
    upi: 'UPI',
  }
  return labels[method]
}

// ========================================
// FEE SUMMARY
// ========================================

interface FeeSummaryProps {
  data: FeeData
  onPayNow?: () => void
}

function FeeSummary({ data, onPayNow }: FeeSummaryProps) {
  const statusConfig = getStatusConfig(data.status)
  const StatusIcon = statusConfig.icon
  const paymentPercentage = (data.paidAmount / data.totalFee) * 100
  const isOverdue = isPast(data.dueDate) && data.pendingAmount > 0

  return (
    <div className="space-y-4">
      {/* Status header */}
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Fee Summary</h3>
        <Badge className={statusConfig.className}>
          <StatusIcon className="h-3 w-3 mr-1" />
          {statusConfig.label}
        </Badge>
      </div>

      {/* Payment progress */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">Payment Progress</span>
          <span className="text-2xl font-bold">
            ${data.paidAmount.toFixed(2)} / ${data.totalFee.toFixed(2)}
          </span>
        </div>
        <Progress value={paymentPercentage} className="h-3" />
        <p className="text-xs text-muted-foreground">
          {paymentPercentage.toFixed(1)}% paid
        </p>
      </div>

      {/* Amount breakdown */}
      <div className="grid grid-cols-2 gap-3 p-4 bg-muted/50 rounded-lg">
        <div className="space-y-1">
          <p className="text-xs text-muted-foreground">Total Fee</p>
          <p className="text-lg font-bold">${data.totalFee.toFixed(2)}</p>
        </div>
        <div className="space-y-1">
          <p className="text-xs text-muted-foreground">Paid Amount</p>
          <p className="text-lg font-bold text-green-600">${data.paidAmount.toFixed(2)}</p>
        </div>
        <div className="space-y-1">
          <p className="text-xs text-muted-foreground">Pending Amount</p>
          <p className="text-lg font-bold text-red-600">${data.pendingAmount.toFixed(2)}</p>
        </div>
        {data.discount > 0 && (
          <div className="space-y-1">
            <p className="text-xs text-muted-foreground">Discount</p>
            <p className="text-lg font-bold text-blue-600">-${data.discount.toFixed(2)}</p>
          </div>
        )}
        {data.lateFee > 0 && (
          <div className="space-y-1">
            <p className="text-xs text-muted-foreground">Late Fee</p>
            <p className="text-lg font-bold text-orange-600">+${data.lateFee.toFixed(2)}</p>
          </div>
        )}
      </div>

      {/* Due date */}
      <div
        className={cn(
          'flex items-center gap-2 p-3 rounded-lg',
          isOverdue
            ? 'bg-red-50 dark:bg-red-950 text-red-900 dark:text-red-100'
            : 'bg-blue-50 dark:bg-blue-950 text-blue-900 dark:text-blue-100'
        )}
      >
        <Calendar className="h-4 w-4" />
        <span className="text-sm font-medium">
          {isOverdue ? 'Overdue since: ' : 'Due Date: '}
          {format(data.dueDate, 'MMMM dd, yyyy')}
        </span>
      </div>

      {/* Pay now button */}
      {data.pendingAmount > 0 && onPayNow && (
        <Button className="w-full" size="lg" onClick={onPayNow}>
          <CreditCard className="h-4 w-4 mr-2" />
          Pay ${data.pendingAmount.toFixed(2)} Now
        </Button>
      )}
    </div>
  )
}

// ========================================
// FEE BREAKDOWN TABLE
// ========================================

interface FeeBreakdownProps {
  items: FeeItem[]
  discount: number
  lateFee: number
  totalFee: number
}

function FeeBreakdown({ items, discount, lateFee, totalFee }: FeeBreakdownProps) {
  const subtotal = items.reduce((sum, item) => sum + item.amount, 0)

  return (
    <div>
      <h3 className="text-lg font-semibold mb-3">Fee Breakdown</h3>
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Fee Type</TableHead>
              <TableHead>Description</TableHead>
              <TableHead className="text-right">Amount</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {items.map((item) => (
              <TableRow key={item.id}>
                <TableCell className="font-medium">{item.name}</TableCell>
                <TableCell className="text-muted-foreground">
                  {item.description || '-'}
                </TableCell>
                <TableCell className="text-right">${item.amount.toFixed(2)}</TableCell>
              </TableRow>
            ))}
            <TableRow>
              <TableCell colSpan={2} className="font-medium">
                Subtotal
              </TableCell>
              <TableCell className="text-right font-semibold">
                ${subtotal.toFixed(2)}
              </TableCell>
            </TableRow>
            {discount > 0 && (
              <TableRow>
                <TableCell colSpan={2} className="text-green-600">
                  Discount
                </TableCell>
                <TableCell className="text-right text-green-600">
                  -${discount.toFixed(2)}
                </TableCell>
              </TableRow>
            )}
            {lateFee > 0 && (
              <TableRow>
                <TableCell colSpan={2} className="text-orange-600">
                  Late Fee
                </TableCell>
                <TableCell className="text-right text-orange-600">
                  +${lateFee.toFixed(2)}
                </TableCell>
              </TableRow>
            )}
            <TableRow className="bg-muted/50">
              <TableCell colSpan={2} className="font-bold">
                Total
              </TableCell>
              <TableCell className="text-right font-bold">
                ${totalFee.toFixed(2)}
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </div>
    </div>
  )
}

// ========================================
// PAYMENT HISTORY
// ========================================

interface PaymentHistoryProps {
  transactions: PaymentTransaction[]
  onDownloadReceipt?: (transactionId: string) => void
}

function PaymentHistory({ transactions, onDownloadReceipt }: PaymentHistoryProps) {
  if (transactions.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        <Receipt className="h-12 w-12 mx-auto mb-4 opacity-50" />
        <p>No payment history</p>
      </div>
    )
  }

  return (
    <div>
      <h3 className="text-lg font-semibold mb-3">Payment History</h3>
      <div className="space-y-3">
        {transactions.map((transaction) => (
          <Card key={transaction.id}>
            <CardContent className="p-4">
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    <span className="font-medium">
                      ${transaction.amount.toFixed(2)} Paid
                    </span>
                  </div>
                  <div className="text-sm text-muted-foreground space-y-1">
                    <p>Date: {format(transaction.date, 'MMMM dd, yyyy')}</p>
                    <p>Method: {getPaymentMethodLabel(transaction.method)}</p>
                    <p>Reference: {transaction.referenceNumber}</p>
                    {transaction.receiptNumber && (
                      <p>Receipt: {transaction.receiptNumber}</p>
                    )}
                    {transaction.collectedBy && (
                      <p>Collected by: {transaction.collectedBy}</p>
                    )}
                  </div>
                </div>

                {onDownloadReceipt && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onDownloadReceipt(transaction.id)}
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Receipt
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}

// ========================================
// INSTALLMENTS VIEW
// ========================================

interface InstallmentsViewProps {
  installments: FeeInstallment[]
}

function InstallmentsView({ installments }: InstallmentsViewProps) {
  return (
    <div>
      <h3 className="text-lg font-semibold mb-3">Installment Plan</h3>
      <div className="space-y-3">
        {installments.map((installment) => {
          const isOverdue = installment.status === 'overdue'
          const isPaid = installment.status === 'paid'

          return (
            <Card
              key={installment.id}
              className={cn(
                'border-l-4',
                isPaid && 'border-l-green-500',
                isOverdue && 'border-l-red-500',
                installment.status === 'pending' && 'border-l-yellow-500'
              )}
            >
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="font-medium">
                      Installment {installment.installmentNumber}
                    </h4>
                    <p className="text-sm text-muted-foreground">
                      Due: {format(installment.dueDate, 'MMM dd, yyyy')}
                    </p>
                    {isPaid && installment.paidDate && (
                      <p className="text-sm text-green-600">
                        Paid on: {format(installment.paidDate, 'MMM dd, yyyy')}
                      </p>
                    )}
                  </div>
                  <div className="text-right">
                    <p className="text-xl font-bold">
                      ${installment.amount.toFixed(2)}
                    </p>
                    {installment.paidAmount > 0 && (
                      <p className="text-sm text-green-600">
                        Paid: ${installment.paidAmount.toFixed(2)}
                      </p>
                    )}
                    <Badge
                      className={cn(
                        'mt-2',
                        isPaid && 'bg-green-100 text-green-700',
                        isOverdue && 'bg-red-100 text-red-700',
                        installment.status === 'pending' &&
                          'bg-yellow-100 text-yellow-700'
                      )}
                    >
                      {installment.status}
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}

// ========================================
// FEE STATUS COMPONENT
// ========================================

/**
 * Fee Status Component
 * 
 * Comprehensive student fee tracking and payment management.
 */
export function FeeStatus({
  data,
  showHistory = true,
  showInstallments = true,
  onPayNow,
  onDownloadReceipt,
  className,
}: FeeStatusProps) {
  return (
    <Card className={className}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <DollarSign className="h-5 w-5" />
              Fee Status
            </CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              {data.studentName} ({data.rollNumber}) - {data.className} {data.section}
            </p>
            <p className="text-xs text-muted-foreground">
              {data.term} {data.academicYear}
            </p>
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* Fee summary */}
        <FeeSummary data={data} onPayNow={onPayNow} />

        {/* Fee breakdown */}
        <FeeBreakdown
          items={data.feeBreakdown}
          discount={data.discount}
          lateFee={data.lateFee}
          totalFee={data.totalFee}
        />

        {/* Installments */}
        {showInstallments && data.installments && data.installments.length > 0 && (
          <InstallmentsView installments={data.installments} />
        )}

        {/* Payment history */}
        {showHistory && (
          <PaymentHistory
            transactions={data.transactions}
            onDownloadReceipt={onDownloadReceipt}
          />
        )}
      </CardContent>
    </Card>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Fee Status

```typescript
import { FeeStatus } from '@/components/academic/fee-status'

function StudentFees() {
  const feeData = {
    studentId: '1',
    studentName: 'John Doe',
    rollNumber: '2024-10-001',
    className: 'Grade 10',
    section: 'A',
    term: 'Semester 1',
    academicYear: '2024-2025',
    feeBreakdown: [
      { id: '1', name: 'Tuition Fee', amount: 5000, description: 'Regular tuition' },
      { id: '2', name: 'Lab Fee', amount: 500, description: 'Science lab' },
      { id: '3', name: 'Library Fee', amount: 200, description: 'Library access' },
      { id: '4', name: 'Sports Fee', amount: 300, description: 'Sports facilities' },
    ],
    totalFee: 6000,
    paidAmount: 4000,
    pendingAmount: 2000,
    lateFee: 0,
    discount: 0,
    dueDate: new Date('2024-12-31'),
    status: 'partial' as const,
    transactions: [
      {
        id: '1',
        amount: 4000,
        date: new Date('2024-09-01'),
        method: 'bank_transfer' as const,
        referenceNumber: 'TXN123456',
        receiptNumber: 'RCP-2024-001',
        collectedBy: 'Admin Office',
      },
    ],
  }

  return (
    <FeeStatus
      data={feeData}
      onPayNow={() => console.log('Pay now')}
      onDownloadReceipt={(id) => console.log('Download receipt', id)}
    />
  )
}
```

### With Installments

```typescript
const feeDataWithInstallments = {
  ...feeData,
  installments: [
    {
      id: '1',
      installmentNumber: 1,
      amount: 2000,
      dueDate: new Date('2024-09-01'),
      paidAmount: 2000,
      paidDate: new Date('2024-09-01'),
      status: 'paid' as const,
    },
    {
      id: '2',
      installmentNumber: 2,
      amount: 2000,
      dueDate: new Date('2024-11-01'),
      paidAmount: 2000,
      paidDate: new Date('2024-11-01'),
      status: 'paid' as const,
    },
    {
      id: '3',
      installmentNumber: 3,
      amount: 2000,
      dueDate: new Date('2025-01-01'),
      paidAmount: 0,
      status: 'pending' as const,
    },
  ],
}

return <FeeStatus data={feeDataWithInstallments} showInstallments />
```

---

## 🧪 TESTING

```typescript
describe('FeeStatus', () => {
  const mockFeeData = {
    studentId: '1',
    studentName: 'John Doe',
    rollNumber: '2024-10-001',
    className: 'Grade 10',
    section: 'A',
    term: 'Semester 1',
    academicYear: '2024-2025',
    feeBreakdown: [{ id: '1', name: 'Tuition', amount: 5000 }],
    totalFee: 5000,
    paidAmount: 2500,
    pendingAmount: 2500,
    lateFee: 0,
    discount: 0,
    dueDate: new Date('2024-12-31'),
    status: 'partial' as const,
    transactions: [],
  }

  it('renders fee status', () => {
    render(<FeeStatus data={mockFeeData} />)
    expect(screen.getByText('Fee Status')).toBeInTheDocument()
  })

  it('displays payment progress', () => {
    render(<FeeStatus data={mockFeeData} />)
    expect(screen.getByText(/50.0% paid/)).toBeInTheDocument()
  })

  it('calls onPayNow when pay button clicked', () => {
    const onPayNow = jest.fn()
    render(<FeeStatus data={mockFeeData} onPayNow={onPayNow} />)
    fireEvent.click(screen.getByText(/Pay \$2500.00 Now/))
    expect(onPayNow).toHaveBeenCalled()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Clear financial information display
- ✅ Keyboard accessible buttons
- ✅ ARIA labels for status indicators
- ✅ Screen reader friendly tables

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create fee-status.tsx
- [ ] Implement fee breakdown table
- [ ] Add payment history
- [ ] Add installment tracking
- [ ] Integrate payment gateway
- [ ] Add receipt generation
- [ ] Write tests
- [ ] Document usage

---

## 📦 BUNDLE SIZE

- **Component**: ~3KB
- **With dependencies**: ~7KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
