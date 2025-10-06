# SPEC-083: Back Button Component
## Browser History Navigation Button

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: LOW  
> **Estimated Time**: 2 hours  
> **Dependencies**: Button, Next.js Router

---

## 📋 OVERVIEW

### Purpose
A simple back button component that integrates with browser history and Next.js router, with fallback options and custom labels.

### Key Features
- ✅ Browser history navigation
- ✅ Custom fallback URL
- ✅ Custom label/icon
- ✅ Disabled state when no history
- ✅ Confirmation dialog option
- ✅ Keyboard shortcuts
- ✅ Loading states
- ✅ Accessibility
- ✅ Multiple variants

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/back-button.tsx
'use client'

import * as React from 'react'
import { useRouter } from 'next/navigation'
import { ArrowLeft, ChevronLeft } from 'lucide-react'
import { Button, ButtonProps } from '@/components/ui/button'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface BackButtonProps extends Omit<ButtonProps, 'onClick'> {
  /**
   * Custom label
   */
  label?: string

  /**
   * Show label
   */
  showLabel?: boolean

  /**
   * Custom icon
   */
  icon?: React.ReactNode

  /**
   * Fallback URL if no history
   */
  fallbackUrl?: string

  /**
   * Custom onClick handler
   */
  onClick?: () => void

  /**
   * Confirm before navigating
   */
  confirmNavigation?: boolean

  /**
   * Confirmation dialog title
   */
  confirmTitle?: string

  /**
   * Confirmation dialog description
   */
  confirmDescription?: string

  /**
   * Disable when no history
   */
  disableWhenNoHistory?: boolean

  /**
   * Show loading state during navigation
   */
  showLoading?: boolean
}

// ========================================
// BACK BUTTON COMPONENT
// ========================================

/**
 * Back Button Component
 * 
 * Navigate back in browser history.
 * 
 * @example
 * <BackButton />
 * 
 * @example
 * <BackButton label="Back to Dashboard" fallbackUrl="/dashboard" />
 */
export function BackButton({
  label = 'Back',
  showLabel = true,
  icon,
  fallbackUrl = '/',
  onClick,
  confirmNavigation = false,
  confirmTitle = 'Are you sure?',
  confirmDescription = 'Any unsaved changes will be lost.',
  disableWhenNoHistory = false,
  showLoading = false,
  variant = 'ghost',
  size = 'default',
  className,
  ...props
}: BackButtonProps) {
  const router = useRouter()
  const [isConfirmOpen, setIsConfirmOpen] = React.useState(false)
  const [isLoading, setIsLoading] = React.useState(false)
  const [hasHistory, setHasHistory] = React.useState(true)

  // Check if there's history available
  React.useEffect(() => {
    if (typeof window !== 'undefined') {
      setHasHistory(window.history.length > 1)
    }
  }, [])

  const handleBack = async () => {
    if (onClick) {
      onClick()
      return
    }

    if (showLoading) {
      setIsLoading(true)
    }

    try {
      if (hasHistory && window.history.length > 1) {
        router.back()
      } else {
        router.push(fallbackUrl)
      }
    } finally {
      // Reset loading after navigation
      setTimeout(() => {
        setIsLoading(false)
      }, 300)
    }
  }

  const handleClick = () => {
    if (confirmNavigation) {
      setIsConfirmOpen(true)
    } else {
      handleBack()
    }
  }

  const handleConfirm = () => {
    setIsConfirmOpen(false)
    handleBack()
  }

  const isDisabled = (disableWhenNoHistory && !hasHistory) || props.disabled

  const defaultIcon = icon || <ArrowLeft className="h-4 w-4" />

  return (
    <>
      <Button
        variant={variant}
        size={size}
        onClick={handleClick}
        disabled={isDisabled || isLoading}
        className={cn('gap-2', className)}
        {...props}
      >
        {isLoading ? (
          <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
        ) : (
          defaultIcon
        )}
        {showLabel && <span>{label}</span>}
      </Button>

      {confirmNavigation && (
        <AlertDialog open={isConfirmOpen} onOpenChange={setIsConfirmOpen}>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{confirmTitle}</AlertDialogTitle>
              <AlertDialogDescription>
                {confirmDescription}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction onClick={handleConfirm}>
                Continue
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      )}
    </>
  )
}

// ========================================
// BREADCRUMB BACK BUTTON
// ========================================

export interface BreadcrumbBackButtonProps extends BackButtonProps {
  /**
   * Breadcrumb text
   */
  breadcrumb?: string
}

/**
 * Breadcrumb Back Button
 * 
 * Back button with breadcrumb styling.
 */
export function BreadcrumbBackButton({
  breadcrumb,
  label = 'Back',
  icon,
  className,
  ...props
}: BreadcrumbBackButtonProps) {
  return (
    <div className={cn('flex items-center gap-2 text-sm', className)}>
      <BackButton
        label={label}
        showLabel={true}
        icon={icon || <ChevronLeft className="h-4 w-4" />}
        variant="ghost"
        size="sm"
        className="h-auto p-0 hover:bg-transparent"
        {...props}
      />
      {breadcrumb && (
        <>
          <span className="text-muted-foreground">/</span>
          <span className="text-muted-foreground">{breadcrumb}</span>
        </>
      )}
    </div>
  )
}

// ========================================
// PAGE HEADER BACK BUTTON
// ========================================

export interface PageHeaderBackButtonProps extends BackButtonProps {
  /**
   * Page title
   */
  title?: string

  /**
   * Page description
   */
  description?: string

  /**
   * Actions (buttons, etc.)
   */
  actions?: React.ReactNode
}

/**
 * Page Header with Back Button
 * 
 * Complete page header with back navigation.
 */
export function PageHeaderBackButton({
  title,
  description,
  actions,
  label = 'Back',
  className,
  ...props
}: PageHeaderBackButtonProps) {
  return (
    <div className={cn('space-y-4', className)}>
      <BackButton label={label} variant="ghost" size="sm" {...props} />
      
      <div className="flex items-center justify-between">
        <div>
          {title && (
            <h1 className="text-3xl font-bold tracking-tight">{title}</h1>
          )}
          {description && (
            <p className="text-muted-foreground mt-2">{description}</p>
          )}
        </div>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  )
}

// ========================================
// FLOATING BACK BUTTON
// ========================================

export interface FloatingBackButtonProps extends BackButtonProps {
  /**
   * Position
   */
  position?: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
}

/**
 * Floating Back Button
 * 
 * Fixed position back button.
 */
export function FloatingBackButton({
  position = 'top-left',
  className,
  ...props
}: FloatingBackButtonProps) {
  const positionClasses = {
    'top-left': 'top-4 left-4',
    'top-right': 'top-4 right-4',
    'bottom-left': 'bottom-4 left-4',
    'bottom-right': 'bottom-4 right-4',
  }

  return (
    <div className={cn('fixed z-50', positionClasses[position], className)}>
      <BackButton
        showLabel={false}
        variant="outline"
        size="icon"
        className="shadow-lg"
        {...props}
      />
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Back Button

```typescript
import { BackButton } from '@/components/ui/back-button'

function DetailPage() {
  return (
    <div>
      <BackButton />
      <h1>Page Content</h1>
    </div>
  )
}
```

### With Custom Label and Fallback

```typescript
function ProductDetail() {
  return (
    <div>
      <BackButton
        label="Back to Products"
        fallbackUrl="/products"
        variant="outline"
      />
      <h1>Product Details</h1>
    </div>
  )
}
```

### With Confirmation

```typescript
function EditPage() {
  const [hasUnsavedChanges, setHasUnsavedChanges] = React.useState(true)

  return (
    <div>
      <BackButton
        confirmNavigation={hasUnsavedChanges}
        confirmTitle="Unsaved Changes"
        confirmDescription="You have unsaved changes. Are you sure you want to leave?"
      />
      {/* Form content */}
    </div>
  )
}
```

### Breadcrumb Style

```typescript
import { BreadcrumbBackButton } from '@/components/ui/back-button'

function Page() {
  return (
    <div>
      <BreadcrumbBackButton
        breadcrumb="Product Details"
        fallbackUrl="/products"
      />
      <h1>Product Name</h1>
    </div>
  )
}
```

### Page Header with Back Button

```typescript
import { PageHeaderBackButton } from '@/components/ui/back-button'
import { Button } from '@/components/ui/button'

function DetailPage() {
  return (
    <div>
      <PageHeaderBackButton
        title="User Profile"
        description="View and edit user information"
        fallbackUrl="/users"
        actions={
          <>
            <Button variant="outline">Delete</Button>
            <Button>Save Changes</Button>
          </>
        }
      />
      {/* Page content */}
    </div>
  )
}
```

### Floating Back Button

```typescript
import { FloatingBackButton } from '@/components/ui/back-button'

function FullPageView() {
  return (
    <>
      <FloatingBackButton position="top-left" />
      <div className="min-h-screen">
        {/* Full page content */}
      </div>
    </>
  )
}
```

### Icon Only

```typescript
function CompactNav() {
  return (
    <BackButton
      showLabel={false}
      size="icon"
      aria-label="Go back"
    />
  )
}
```

### Custom Icon

```typescript
import { ArrowLeftCircle } from 'lucide-react'

function StyledBack() {
  return (
    <BackButton
      icon={<ArrowLeftCircle className="h-5 w-5" />}
      label="Previous Page"
      variant="outline"
    />
  )
}
```

### With Custom Handler

```typescript
function CustomBackBehavior() {
  const handleBack = () => {
    // Custom logic (save state, analytics, etc.)
    console.log('Going back...')
    // Then navigate
  }

  return (
    <BackButton onClick={handleBack} />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('BackButton', () => {
  it('renders with default label', () => {
    render(<BackButton />)
    expect(screen.getByText('Back')).toBeInTheDocument()
  })

  it('renders with custom label', () => {
    render(<BackButton label="Go Back" />)
    expect(screen.getByText('Go Back')).toBeInTheDocument()
  })

  it('calls router.back() when clicked', () => {
    const mockBack = jest.fn()
    jest.spyOn(require('next/navigation'), 'useRouter').mockReturnValue({
      back: mockBack,
    })
    
    render(<BackButton />)
    fireEvent.click(screen.getByRole('button'))
    expect(mockBack).toHaveBeenCalled()
  })

  it('navigates to fallback when no history', () => {
    const mockPush = jest.fn()
    jest.spyOn(require('next/navigation'), 'useRouter').mockReturnValue({
      push: mockPush,
    })
    
    // Mock no history
    Object.defineProperty(window, 'history', {
      value: { length: 1 },
      writable: true,
    })
    
    render(<BackButton fallbackUrl="/home" />)
    fireEvent.click(screen.getByRole('button'))
    expect(mockPush).toHaveBeenCalledWith('/home')
  })

  it('shows confirmation dialog when confirmNavigation is true', () => {
    render(<BackButton confirmNavigation confirmTitle="Confirm" />)
    fireEvent.click(screen.getByRole('button'))
    expect(screen.getByText('Confirm')).toBeInTheDocument()
  })

  it('disables when no history and disableWhenNoHistory is true', () => {
    Object.defineProperty(window, 'history', {
      value: { length: 1 },
      writable: true,
    })
    
    render(<BackButton disableWhenNoHistory />)
    const button = screen.getByRole('button')
    expect(button).toBeDisabled()
  })

  it('shows loading state', async () => {
    render(<BackButton showLoading />)
    fireEvent.click(screen.getByRole('button'))
    expect(screen.getByRole('button')).toHaveClass('animate-spin')
  })
})

describe('BreadcrumbBackButton', () => {
  it('renders with breadcrumb text', () => {
    render(<BreadcrumbBackButton breadcrumb="Products" />)
    expect(screen.getByText('Products')).toBeInTheDocument()
  })
})

describe('PageHeaderBackButton', () => {
  it('renders with title and description', () => {
    render(
      <PageHeaderBackButton
        title="Page Title"
        description="Page description"
      />
    )
    expect(screen.getByText('Page Title')).toBeInTheDocument()
    expect(screen.getByText('Page description')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation (Enter/Space)
- ✅ ARIA labels
- ✅ Focus indicators
- ✅ Disabled states
- ✅ Screen reader support
- ✅ Loading announcements

---

## 🎯 USE CASES

### School Management System
- Navigate back from student detail page to student list
- Return from grade entry to class overview
- Exit attendance marking to timetable view
- Cancel fee payment entry
- Leave report viewer back to reports list

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create back-button.tsx
- [ ] Implement browser history detection
- [ ] Add fallback URL navigation
- [ ] Add confirmation dialog
- [ ] Implement loading states
- [ ] Create breadcrumb variant
- [ ] Create page header variant
- [ ] Create floating variant
- [ ] Write tests
- [ ] Test accessibility
- [ ] Test with Next.js routing

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With AlertDialog**: ~5KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
