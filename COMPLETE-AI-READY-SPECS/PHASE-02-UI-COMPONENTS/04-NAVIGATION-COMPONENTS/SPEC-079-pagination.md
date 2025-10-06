# SPEC-079: Pagination Component
## Data Pagination with Page Numbers and Size Selector

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4 hours  
> **Dependencies**: Button, Select

---

## 📋 OVERVIEW

### Purpose
A flexible pagination component for navigating through large datasets with page numbers, previous/next buttons, jump to page, and page size selector.

### Key Features
- ✅ Page number display
- ✅ Previous/Next navigation
- ✅ First/Last page buttons
- ✅ Ellipsis for long ranges
- ✅ Page size selector
- ✅ Jump to specific page
- ✅ Total items count
- ✅ Customizable sibling count
- ✅ Compact/full variants
- ✅ Keyboard navigation

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/pagination.tsx
'use client'

import * as React from 'react'
import {
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  MoreHorizontal,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface PaginationProps {
  /**
   * Current page (1-indexed)
   */
  currentPage: number

  /**
   * Total number of pages
   */
  totalPages: number

  /**
   * Page change callback
   */
  onPageChange: (page: number) => void

  /**
   * Number of sibling pages to show
   */
  siblingCount?: number

  /**
   * Show first/last buttons
   */
  showFirstLast?: boolean

  /**
   * Show page size selector
   */
  showPageSize?: boolean

  /**
   * Page size options
   */
  pageSizeOptions?: number[]

  /**
   * Current page size
   */
  pageSize?: number

  /**
   * Page size change callback
   */
  onPageSizeChange?: (size: number) => void

  /**
   * Total items count
   */
  totalItems?: number

  /**
   * Show jump to page input
   */
  showJumpToPage?: boolean

  /**
   * Variant
   */
  variant?: 'default' | 'compact'

  /**
   * Size
   */
  size?: 'sm' | 'md' | 'lg'

  /**
   * Disabled state
   */
  disabled?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// HELPER FUNCTIONS
// ========================================

interface PageRange {
  pages: (number | 'ellipsis')[]
}

function generatePagination(
  currentPage: number,
  totalPages: number,
  siblingCount: number = 1
): PageRange {
  const totalPageNumbers = siblingCount + 5 // first, last, current, 2 siblings, 2 ellipsis

  // If total pages less than total page numbers, show all
  if (totalPages <= totalPageNumbers) {
    return {
      pages: Array.from({ length: totalPages }, (_, i) => i + 1),
    }
  }

  const leftSiblingIndex = Math.max(currentPage - siblingCount, 1)
  const rightSiblingIndex = Math.min(currentPage + siblingCount, totalPages)

  const shouldShowLeftEllipsis = leftSiblingIndex > 2
  const shouldShowRightEllipsis = rightSiblingIndex < totalPages - 1

  const firstPageIndex = 1
  const lastPageIndex = totalPages

  // No ellipsis on either side
  if (!shouldShowLeftEllipsis && shouldShowRightEllipsis) {
    const leftItemCount = 3 + 2 * siblingCount
    const leftRange = Array.from({ length: leftItemCount }, (_, i) => i + 1)
    return { pages: [...leftRange, 'ellipsis', totalPages] }
  }

  // No ellipsis on right side
  if (shouldShowLeftEllipsis && !shouldShowRightEllipsis) {
    const rightItemCount = 3 + 2 * siblingCount
    const rightRange = Array.from(
      { length: rightItemCount },
      (_, i) => totalPages - rightItemCount + i + 1
    )
    return { pages: [firstPageIndex, 'ellipsis', ...rightRange] }
  }

  // Ellipsis on both sides
  const middleRange = Array.from(
    { length: rightSiblingIndex - leftSiblingIndex + 1 },
    (_, i) => leftSiblingIndex + i
  )
  return {
    pages: [firstPageIndex, 'ellipsis', ...middleRange, 'ellipsis', lastPageIndex],
  }
}

// ========================================
// PAGINATION COMPONENT
// ========================================

/**
 * Pagination Component
 * 
 * Navigate through paginated data.
 * 
 * @example
 * <Pagination
 *   currentPage={page}
 *   totalPages={totalPages}
 *   onPageChange={setPage}
 *   showPageSize
 *   pageSize={pageSize}
 *   onPageSizeChange={setPageSize}
 * />
 */
export function Pagination({
  currentPage,
  totalPages,
  onPageChange,
  siblingCount = 1,
  showFirstLast = true,
  showPageSize = false,
  pageSizeOptions = [10, 20, 50, 100],
  pageSize = 10,
  onPageSizeChange,
  totalItems,
  showJumpToPage = false,
  variant = 'default',
  size = 'md',
  disabled = false,
  className,
}: PaginationProps) {
  const [jumpValue, setJumpValue] = React.useState('')

  const { pages } = generatePagination(currentPage, totalPages, siblingCount)

  const isFirstPage = currentPage === 1
  const isLastPage = currentPage === totalPages

  const handleJumpToPage = (e: React.FormEvent) => {
    e.preventDefault()
    const page = parseInt(jumpValue, 10)
    if (page >= 1 && page <= totalPages) {
      onPageChange(page)
      setJumpValue('')
    }
  }

  const startItem = (currentPage - 1) * pageSize + 1
  const endItem = Math.min(currentPage * pageSize, totalItems || pageSize * totalPages)

  const sizeClasses = {
    sm: 'h-8',
    md: 'h-9',
    lg: 'h-10',
  }

  if (variant === 'compact') {
    return (
      <div className={cn('flex items-center gap-2', className)}>
        <Button
          variant="outline"
          size="sm"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={disabled || isFirstPage}
        >
          <ChevronLeft className="h-4 w-4" />
          Previous
        </Button>
        <span className="text-sm text-muted-foreground whitespace-nowrap">
          Page {currentPage} of {totalPages}
        </span>
        <Button
          variant="outline"
          size="sm"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={disabled || isLastPage}
        >
          Next
          <ChevronRight className="h-4 w-4 ml-1" />
        </Button>
      </div>
    )
  }

  return (
    <div className={cn('flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between', className)}>
      {/* Info & Page Size */}
      <div className="flex items-center gap-4">
        {totalItems !== undefined && (
          <span className="text-sm text-muted-foreground">
            Showing {startItem} to {endItem} of {totalItems} items
          </span>
        )}
        {showPageSize && onPageSizeChange && (
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">Rows per page:</span>
            <Select
              value={String(pageSize)}
              onValueChange={(value) => onPageSizeChange(Number(value))}
              disabled={disabled}
            >
              <SelectTrigger className="w-20">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {pageSizeOptions.map((option) => (
                  <SelectItem key={option} value={String(option)}>
                    {option}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        )}
      </div>

      {/* Pagination Controls */}
      <div className="flex items-center gap-2">
        {/* Jump to Page */}
        {showJumpToPage && (
          <form onSubmit={handleJumpToPage} className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">Go to:</span>
            <Input
              type="number"
              min={1}
              max={totalPages}
              value={jumpValue}
              onChange={(e) => setJumpValue(e.target.value)}
              className="w-16 h-9"
              disabled={disabled}
            />
          </form>
        )}

        <nav aria-label="Pagination" className="flex items-center gap-1">
          {/* First Page */}
          {showFirstLast && (
            <Button
              variant="outline"
              size="icon"
              className={sizeClasses[size]}
              onClick={() => onPageChange(1)}
              disabled={disabled || isFirstPage}
              aria-label="Go to first page"
            >
              <ChevronsLeft className="h-4 w-4" />
            </Button>
          )}

          {/* Previous Page */}
          <Button
            variant="outline"
            size="icon"
            className={sizeClasses[size]}
            onClick={() => onPageChange(currentPage - 1)}
            disabled={disabled || isFirstPage}
            aria-label="Go to previous page"
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>

          {/* Page Numbers */}
          {pages.map((page, index) => {
            if (page === 'ellipsis') {
              return (
                <Button
                  key={`ellipsis-${index}`}
                  variant="ghost"
                  size="icon"
                  className={cn(sizeClasses[size], 'cursor-default')}
                  disabled
                  aria-label="More pages"
                >
                  <MoreHorizontal className="h-4 w-4" />
                </Button>
              )
            }

            const isActive = page === currentPage

            return (
              <Button
                key={page}
                variant={isActive ? 'default' : 'outline'}
                size="icon"
                className={sizeClasses[size]}
                onClick={() => onPageChange(page)}
                disabled={disabled}
                aria-label={`Go to page ${page}`}
                aria-current={isActive ? 'page' : undefined}
              >
                {page}
              </Button>
            )
          })}

          {/* Next Page */}
          <Button
            variant="outline"
            size="icon"
            className={sizeClasses[size]}
            onClick={() => onPageChange(currentPage + 1)}
            disabled={disabled || isLastPage}
            aria-label="Go to next page"
          >
            <ChevronRight className="h-4 w-4" />
          </Button>

          {/* Last Page */}
          {showFirstLast && (
            <Button
              variant="outline"
              size="icon"
              className={sizeClasses[size]}
              onClick={() => onPageChange(totalPages)}
              disabled={disabled || isLastPage}
              aria-label="Go to last page"
            >
              <ChevronsRight className="h-4 w-4" />
            </Button>
          )}
        </nav>
      </div>
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Pagination

```typescript
import { Pagination } from '@/components/ui/pagination'

function DataList() {
  const [page, setPage] = React.useState(1)
  const totalPages = 10

  return (
    <>
      <div>{/* Your data list */}</div>
      <Pagination
        currentPage={page}
        totalPages={totalPages}
        onPageChange={setPage}
      />
    </>
  )
}
```

### With Page Size Selector

```typescript
function DataTable() {
  const [page, setPage] = React.useState(1)
  const [pageSize, setPageSize] = React.useState(20)
  const totalItems = 1000

  const totalPages = Math.ceil(totalItems / pageSize)

  return (
    <Pagination
      currentPage={page}
      totalPages={totalPages}
      onPageChange={setPage}
      showPageSize
      pageSize={pageSize}
      onPageSizeChange={(size) => {
        setPageSize(size)
        setPage(1) // Reset to first page
      }}
      totalItems={totalItems}
    />
  )
}
```

### Compact Variant

```typescript
function MobilePagination() {
  return (
    <Pagination
      currentPage={page}
      totalPages={totalPages}
      onPageChange={setPage}
      variant="compact"
    />
  )
}
```

### Full-Featured Pagination

```typescript
function AdvancedPagination() {
  return (
    <Pagination
      currentPage={page}
      totalPages={totalPages}
      onPageChange={setPage}
      siblingCount={2}
      showFirstLast
      showPageSize
      pageSizeOptions={[10, 25, 50, 100]}
      pageSize={pageSize}
      onPageSizeChange={setPageSize}
      totalItems={totalItems}
      showJumpToPage
      size="lg"
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Pagination', () => {
  it('renders page numbers', () => {
    render(
      <Pagination currentPage={1} totalPages={5} onPageChange={jest.fn()} />
    )
    expect(screen.getByText('1')).toBeInTheDocument()
    expect(screen.getByText('5')).toBeInTheDocument()
  })

  it('calls onPageChange when page is clicked', () => {
    const onPageChange = jest.fn()
    render(
      <Pagination currentPage={1} totalPages={5} onPageChange={onPageChange} />
    )
    fireEvent.click(screen.getByText('2'))
    expect(onPageChange).toHaveBeenCalledWith(2)
  })

  it('disables previous button on first page', () => {
    render(
      <Pagination currentPage={1} totalPages={5} onPageChange={jest.fn()} />
    )
    const prevButton = screen.getByLabelText('Go to previous page')
    expect(prevButton).toBeDisabled()
  })

  it('shows ellipsis for long ranges', () => {
    render(
      <Pagination currentPage={5} totalPages={20} onPageChange={jest.fn()} />
    )
    const ellipsis = screen.getAllByLabelText('More pages')
    expect(ellipsis.length).toBeGreaterThan(0)
  })

  it('handles page size change', () => {
    const onPageSizeChange = jest.fn()
    render(
      <Pagination
        currentPage={1}
        totalPages={5}
        onPageChange={jest.fn()}
        showPageSize
        pageSize={10}
        onPageSizeChange={onPageSizeChange}
      />
    )
    // Interact with page size selector
    expect(onPageSizeChange).toHaveBeenCalled()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic navigation
- ✅ ARIA labels
- ✅ Current page indicator
- ✅ Keyboard navigation
- ✅ Focus indicators
- ✅ Disabled states

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create pagination.tsx
- [ ] Implement page number generation
- [ ] Add ellipsis logic
- [ ] Add first/last buttons
- [ ] Add page size selector
- [ ] Add jump to page
- [ ] Add compact variant
- [ ] Write tests
- [ ] Test accessibility
- [ ] Test with various ranges

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
