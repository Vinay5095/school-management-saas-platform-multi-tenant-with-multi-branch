# SPEC-113: Library Card Component
## Student Library Management and Book Tracking

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: LOW  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: date-fns

---

## 📋 OVERVIEW

### Purpose
A library card component for displaying student library membership, borrowed books, due dates, and library account status.

### Key Features
- ✅ Library membership display
- ✅ Borrowed books list
- ✅ Due date tracking
- ✅ Overdue notifications
- ✅ Book return reminders
- ✅ Borrow limit tracking
- ✅ Fine calculation
- ✅ Book reservation status
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/library-card.tsx
import * as React from 'react'
import {
  Book,
  Calendar,
  AlertCircle,
  CheckCircle,
  Clock,
  User,
  BookOpen,
  Download,
  ExternalLink,
} from 'lucide-react'
import { format, formatDistanceToNow, differenceInDays, isPast } from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type BookStatus = 'borrowed' | 'overdue' | 'reserved' | 'returned'

export interface BorrowedBook {
  id: string
  title: string
  author: string
  isbn: string
  borrowDate: Date
  dueDate: Date
  returnDate?: Date
  status: BookStatus
  coverUrl?: string
  fine?: number
  renewalCount: number
  maxRenewals: number
}

export interface LibraryMembership {
  membershipId: string
  validFrom: Date
  validUntil: Date
  isActive: boolean
}

export interface LibraryData {
  studentId: string
  studentName: string
  rollNumber: string
  className: string
  section: string
  membership: LibraryMembership
  borrowedBooks: BorrowedBook[]
  maxBorrowLimit: number
  totalFines: number
  booksReserved: number
}

export interface LibraryCardProps {
  /**
   * Library data
   */
  data: LibraryData

  /**
   * Show detailed book info
   */
  showDetails?: boolean

  /**
   * On renew book
   */
  onRenewBook?: (bookId: string) => void

  /**
   * On return book
   */
  onReturnBook?: (bookId: string) => void

  /**
   * On pay fine
   */
  onPayFine?: () => void

  /**
   * On view book details
   */
  onViewBook?: (bookId: string) => void

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// BOOK STATUS BADGE
// ========================================

function getBookStatusConfig(status: BookStatus) {
  const configs = {
    borrowed: {
      label: 'Borrowed',
      icon: BookOpen,
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400',
    },
    overdue: {
      label: 'Overdue',
      icon: AlertCircle,
      className: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400',
    },
    reserved: {
      label: 'Reserved',
      icon: Clock,
      className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400',
    },
    returned: {
      label: 'Returned',
      icon: CheckCircle,
      className: 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400',
    },
  }
  return configs[status]
}

// ========================================
// LIBRARY MEMBERSHIP INFO
// ========================================

interface MembershipInfoProps {
  membership: LibraryMembership
  studentName: string
  rollNumber: string
  className: string
  section: string
}

function MembershipInfo({
  membership,
  studentName,
  rollNumber,
  className,
  section,
}: MembershipInfoProps) {
  const daysUntilExpiry = differenceInDays(membership.validUntil, new Date())
  const isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry > 0
  const isExpired = !membership.isActive || daysUntilExpiry < 0

  return (
    <div className="space-y-3">
      <div className="flex items-start justify-between">
        <div>
          <h3 className="font-semibold">{studentName}</h3>
          <p className="text-sm text-muted-foreground">
            {rollNumber} | {className} - {section}
          </p>
        </div>
        <Badge
          className={cn(
            membership.isActive && !isExpired
              ? 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400'
              : 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400'
          )}
        >
          {membership.isActive && !isExpired ? 'Active' : 'Inactive'}
        </Badge>
      </div>

      <div className="p-3 bg-muted/50 rounded-lg space-y-2">
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Member ID:</span>
          <span className="font-mono">{membership.membershipId}</span>
        </div>
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Valid Until:</span>
          <span className={cn(isExpiringSoon && 'text-orange-600', isExpired && 'text-red-600')}>
            {format(membership.validUntil, 'MMM dd, yyyy')}
          </span>
        </div>
      </div>

      {isExpiringSoon && !isExpired && (
        <div className="flex items-center gap-2 p-2 bg-orange-50 dark:bg-orange-950 rounded text-sm text-orange-700 dark:text-orange-300">
          <AlertCircle className="h-4 w-4" />
          <span>Membership expires in {daysUntilExpiry} days</span>
        </div>
      )}

      {isExpired && (
        <div className="flex items-center gap-2 p-2 bg-red-50 dark:bg-red-950 rounded text-sm text-red-700 dark:text-red-300">
          <AlertCircle className="h-4 w-4" />
          <span>Membership expired. Please renew.</span>
        </div>
      )}
    </div>
  )
}

// ========================================
// BORROW LIMIT INDICATOR
// ========================================

interface BorrowLimitProps {
  current: number
  max: number
  fines: number
  onPayFine?: () => void
}

function BorrowLimit({ current, max, fines, onPayFine }: BorrowLimitProps) {
  const percentage = (current / max) * 100
  const isAtLimit = current >= max

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-sm font-medium">Books Borrowed</span>
        <span className="text-sm font-bold">
          {current} / {max}
        </span>
      </div>
      <Progress value={percentage} className="h-2" />
      {isAtLimit && (
        <p className="text-xs text-orange-600">
          You've reached your borrow limit. Return books to borrow more.
        </p>
      )}

      {fines > 0 && (
        <div className="p-3 bg-red-50 dark:bg-red-950 rounded-lg">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-red-700 dark:text-red-300">
              Outstanding Fines
            </span>
            <span className="text-lg font-bold text-red-700 dark:text-red-300">
              ${fines.toFixed(2)}
            </span>
          </div>
          {onPayFine && (
            <Button
              variant="destructive"
              size="sm"
              className="w-full"
              onClick={onPayFine}
            >
              Pay Fine Now
            </Button>
          )}
        </div>
      )}
    </div>
  )
}

// ========================================
// BOOK ITEM
// ========================================

interface BookItemProps {
  book: BorrowedBook
  showDetails?: boolean
  onRenewBook?: (bookId: string) => void
  onReturnBook?: (bookId: string) => void
  onViewBook?: (bookId: string) => void
}

function BookItem({
  book,
  showDetails = true,
  onRenewBook,
  onReturnBook,
  onViewBook,
}: BookItemProps) {
  const statusConfig = getBookStatusConfig(book.status)
  const StatusIcon = statusConfig.icon
  const daysUntilDue = differenceInDays(book.dueDate, new Date())
  const isOverdue = book.status === 'overdue' || (isPast(book.dueDate) && !book.returnDate)
  const isDueSoon = daysUntilDue <= 3 && daysUntilDue >= 0
  const canRenew = book.renewalCount < book.maxRenewals && !isOverdue

  return (
    <Card
      className={cn(
        'border-l-4',
        isOverdue && 'border-l-red-500',
        isDueSoon && !isOverdue && 'border-l-orange-500',
        !isOverdue && !isDueSoon && 'border-l-blue-500'
      )}
    >
      <CardContent className="p-4">
        <div className="flex gap-3">
          {/* Book cover */}
          {book.coverUrl ? (
            <img
              src={book.coverUrl}
              alt={book.title}
              className="w-16 h-20 object-cover rounded"
            />
          ) : (
            <div className="w-16 h-20 bg-muted rounded flex items-center justify-center">
              <Book className="h-8 w-8 text-muted-foreground" />
            </div>
          )}

          {/* Book info */}
          <div className="flex-1 space-y-2">
            <div>
              <h4 className="font-medium">{book.title}</h4>
              <p className="text-sm text-muted-foreground">{book.author}</p>
              {showDetails && (
                <p className="text-xs text-muted-foreground mt-1">ISBN: {book.isbn}</p>
              )}
            </div>

            <div className="flex items-center gap-2">
              <Badge className={statusConfig.className}>
                <StatusIcon className="h-3 w-3 mr-1" />
                {statusConfig.label}
              </Badge>
              {book.renewalCount > 0 && (
                <span className="text-xs text-muted-foreground">
                  Renewed {book.renewalCount}x
                </span>
              )}
            </div>

            {/* Dates */}
            <div className="text-sm space-y-1">
              <div className="flex items-center gap-2 text-muted-foreground">
                <Calendar className="h-3 w-3" />
                <span>Borrowed: {format(book.borrowDate, 'MMM dd, yyyy')}</span>
              </div>
              <div
                className={cn(
                  'flex items-center gap-2',
                  isOverdue && 'text-red-600',
                  isDueSoon && !isOverdue && 'text-orange-600'
                )}
              >
                <Clock className="h-3 w-3" />
                <span>
                  {isOverdue
                    ? `Overdue by ${Math.abs(daysUntilDue)} days`
                    : isDueSoon
                    ? `Due in ${daysUntilDue} days`
                    : `Due: ${format(book.dueDate, 'MMM dd, yyyy')}`}
                </span>
              </div>
              {book.returnDate && (
                <div className="flex items-center gap-2 text-green-600">
                  <CheckCircle className="h-3 w-3" />
                  <span>Returned: {format(book.returnDate, 'MMM dd, yyyy')}</span>
                </div>
              )}
            </div>

            {/* Fine */}
            {book.fine && book.fine > 0 && (
              <div className="text-sm font-medium text-red-600">
                Fine: ${book.fine.toFixed(2)}
              </div>
            )}

            {/* Actions */}
            {!book.returnDate && (
              <div className="flex gap-2 pt-2">
                {onViewBook && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onViewBook(book.id)}
                  >
                    <ExternalLink className="h-3 w-3 mr-1" />
                    Details
                  </Button>
                )}
                {canRenew && onRenewBook && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onRenewBook(book.id)}
                  >
                    Renew
                  </Button>
                )}
                {onReturnBook && (
                  <Button
                    variant="default"
                    size="sm"
                    onClick={() => onReturnBook(book.id)}
                  >
                    Return
                  </Button>
                )}
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

// ========================================
// LIBRARY CARD COMPONENT
// ========================================

/**
 * Library Card Component
 * 
 * Student library membership and borrowed books display.
 */
export function LibraryCard({
  data,
  showDetails = true,
  onRenewBook,
  onReturnBook,
  onPayFine,
  onViewBook,
  className,
}: LibraryCardProps) {
  const activeBorrows = data.borrowedBooks.filter((b) => !b.returnDate)
  const overdueBooks = activeBorrows.filter(
    (b) => b.status === 'overdue' || isPast(b.dueDate)
  )

  return (
    <Card className={className}>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Book className="h-5 w-5" />
          Library Card
        </CardTitle>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* Membership info */}
        <MembershipInfo
          membership={data.membership}
          studentName={data.studentName}
          rollNumber={data.rollNumber}
          className={data.className}
          section={data.section}
        />

        {/* Borrow limit */}
        <BorrowLimit
          current={activeBorrows.length}
          max={data.maxBorrowLimit}
          fines={data.totalFines}
          onPayFine={onPayFine}
        />

        {/* Overdue warning */}
        {overdueBooks.length > 0 && (
          <div className="flex items-start gap-2 p-3 bg-red-50 dark:bg-red-950 rounded-lg">
            <AlertCircle className="h-5 w-5 text-red-600 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-red-700 dark:text-red-300">
                {overdueBooks.length} {overdueBooks.length === 1 ? 'book is' : 'books are'}{' '}
                overdue
              </p>
              <p className="text-xs text-red-600 dark:text-red-400 mt-1">
                Please return overdue books to avoid additional fines.
              </p>
            </div>
          </div>
        )}

        {/* Borrowed books */}
        <div>
          <h3 className="text-lg font-semibold mb-3">
            Borrowed Books ({activeBorrows.length})
          </h3>
          {activeBorrows.length > 0 ? (
            <div className="space-y-3">
              {activeBorrows.map((book) => (
                <BookItem
                  key={book.id}
                  book={book}
                  showDetails={showDetails}
                  onRenewBook={onRenewBook}
                  onReturnBook={onReturnBook}
                  onViewBook={onViewBook}
                />
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              <BookOpen className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No books currently borrowed</p>
            </div>
          )}
        </div>

        {/* Reserved books info */}
        {data.booksReserved > 0 && (
          <div className="p-3 bg-blue-50 dark:bg-blue-950 rounded-lg">
            <p className="text-sm text-blue-700 dark:text-blue-300">
              You have {data.booksReserved} {data.booksReserved === 1 ? 'book' : 'books'}{' '}
              reserved. Visit the library to collect.
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Library Card

```typescript
import { LibraryCard } from '@/components/academic/library-card'

function StudentLibrary() {
  const libraryData = {
    studentId: '1',
    studentName: 'John Doe',
    rollNumber: '2024-10-001',
    className: 'Grade 10',
    section: 'A',
    membership: {
      membershipId: 'LIB-2024-001',
      validFrom: new Date('2024-09-01'),
      validUntil: new Date('2025-08-31'),
      isActive: true,
    },
    borrowedBooks: [
      {
        id: '1',
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        isbn: '978-0-06-112008-4',
        borrowDate: new Date('2024-11-01'),
        dueDate: new Date('2024-11-15'),
        status: 'borrowed' as const,
        renewalCount: 0,
        maxRenewals: 2,
      },
      {
        id: '2',
        title: '1984',
        author: 'George Orwell',
        isbn: '978-0-452-28423-4',
        borrowDate: new Date('2024-10-20'),
        dueDate: new Date('2024-11-03'),
        status: 'overdue' as const,
        fine: 5.0,
        renewalCount: 1,
        maxRenewals: 2,
      },
    ],
    maxBorrowLimit: 5,
    totalFines: 5.0,
    booksReserved: 1,
  }

  return (
    <LibraryCard
      data={libraryData}
      onRenewBook={(id) => console.log('Renew book', id)}
      onReturnBook={(id) => console.log('Return book', id)}
      onPayFine={() => console.log('Pay fine')}
      onViewBook={(id) => console.log('View book', id)}
    />
  )
}
```

### Compact View

```typescript
function QuickLibraryView() {
  return (
    <LibraryCard
      data={libraryData}
      showDetails={false}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('LibraryCard', () => {
  const mockLibraryData = {
    studentId: '1',
    studentName: 'John Doe',
    rollNumber: '2024-10-001',
    className: 'Grade 10',
    section: 'A',
    membership: {
      membershipId: 'LIB-001',
      validFrom: new Date('2024-01-01'),
      validUntil: new Date('2025-12-31'),
      isActive: true,
    },
    borrowedBooks: [],
    maxBorrowLimit: 5,
    totalFines: 0,
    booksReserved: 0,
  }

  it('renders library card', () => {
    render(<LibraryCard data={mockLibraryData} />)
    expect(screen.getByText('Library Card')).toBeInTheDocument()
  })

  it('shows borrowed books', () => {
    const dataWithBooks = {
      ...mockLibraryData,
      borrowedBooks: [
        {
          id: '1',
          title: 'Test Book',
          author: 'Test Author',
          isbn: '123',
          borrowDate: new Date(),
          dueDate: new Date(),
          status: 'borrowed' as const,
          renewalCount: 0,
          maxRenewals: 2,
        },
      ],
    }
    render(<LibraryCard data={dataWithBooks} />)
    expect(screen.getByText('Test Book')).toBeInTheDocument()
  })

  it('calls onRenewBook when renew clicked', () => {
    const onRenewBook = jest.fn()
    const dataWithBooks = {
      ...mockLibraryData,
      borrowedBooks: [
        {
          id: '1',
          title: 'Test Book',
          author: 'Test Author',
          isbn: '123',
          borrowDate: new Date(),
          dueDate: new Date(Date.now() + 86400000),
          status: 'borrowed' as const,
          renewalCount: 0,
          maxRenewals: 2,
        },
      ],
    }
    render(<LibraryCard data={dataWithBooks} onRenewBook={onRenewBook} />)
    fireEvent.click(screen.getByText('Renew'))
    expect(onRenewBook).toHaveBeenCalledWith('1')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML for book listings
- ✅ ARIA labels for status badges
- ✅ Keyboard navigation for actions
- ✅ Screen reader friendly dates

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create library-card.tsx
- [ ] Implement membership display
- [ ] Add borrowed books list
- [ ] Add overdue tracking
- [ ] Implement fine calculation
- [ ] Add renew/return functionality
- [ ] Write tests
- [ ] Document usage

---

## 📦 BUNDLE SIZE

- **Component**: ~2.5KB
- **With dependencies**: ~6KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
