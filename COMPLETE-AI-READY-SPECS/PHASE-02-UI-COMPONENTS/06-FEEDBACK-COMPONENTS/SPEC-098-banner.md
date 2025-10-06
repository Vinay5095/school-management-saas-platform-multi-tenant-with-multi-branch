# SPEC-098: Banner Component
## Persistent Notification Banners

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: Lucide React (icons), CVA

---

## 📋 OVERVIEW

### Purpose
A banner component for displaying persistent, prominent notifications at the top or bottom of the page, typically used for announcements, warnings, or important system messages.

### Key Features
- ✅ Multiple variants (default, success, warning, error, info)
- ✅ Top and bottom positioning
- ✅ Dismissible with persistence
- ✅ Action buttons
- ✅ Icon support
- ✅ Sticky positioning
- ✅ Animations
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/banner.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import {
  AlertCircle,
  CheckCircle2,
  AlertTriangle,
  Info,
  X,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'

// ========================================
// TYPE DEFINITIONS
// ========================================

const bannerVariants = cva(
  'w-full border-b px-4 py-3 flex items-center gap-3',
  {
    variants: {
      variant: {
        default: 'bg-background text-foreground border-border',
        success: 'bg-green-50 text-green-900 border-green-200 dark:bg-green-950 dark:text-green-100 dark:border-green-800',
        warning: 'bg-yellow-50 text-yellow-900 border-yellow-200 dark:bg-yellow-950 dark:text-yellow-100 dark:border-yellow-800',
        error: 'bg-red-50 text-red-900 border-red-200 dark:bg-red-950 dark:text-red-100 dark:border-red-800',
        info: 'bg-blue-50 text-blue-900 border-blue-200 dark:bg-blue-950 dark:text-blue-100 dark:border-blue-800',
      },
      position: {
        top: '',
        bottom: 'border-t border-b-0',
      },
    },
    defaultVariants: {
      variant: 'default',
      position: 'top',
    },
  }
)

export interface BannerProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof bannerVariants> {
  /**
   * Show default icon
   */
  showIcon?: boolean

  /**
   * Custom icon
   */
  icon?: LucideIcon

  /**
   * Banner message
   */
  message: string | React.ReactNode

  /**
   * Dismissible banner
   */
  dismissible?: boolean

  /**
   * On dismiss callback
   */
  onDismiss?: () => void

  /**
   * Primary action
   */
  action?: {
    label: string
    onClick: () => void
  }

  /**
   * Secondary action
   */
  secondaryAction?: {
    label: string
    onClick: () => void
  }

  /**
   * Sticky position
   */
  sticky?: boolean

  /**
   * Persistence key (localStorage)
   */
  persistKey?: string
}

// ========================================
// BANNER COMPONENT
// ========================================

const Banner = React.forwardRef<HTMLDivElement, BannerProps>(
  (
    {
      className,
      variant = 'default',
      position = 'top',
      showIcon = true,
      icon: CustomIcon,
      message,
      dismissible = true,
      onDismiss,
      action,
      secondaryAction,
      sticky = false,
      persistKey,
      ...props
    },
    ref
  ) => {
    const [visible, setVisible] = React.useState(() => {
      if (!persistKey) return true
      const dismissed = localStorage.getItem(`banner-dismissed-${persistKey}`)
      return dismissed !== 'true'
    })

    const defaultIcons: Record<NonNullable<typeof variant>, LucideIcon> = {
      default: Info,
      success: CheckCircle2,
      warning: AlertTriangle,
      error: AlertCircle,
      info: Info,
    }

    const Icon = CustomIcon || (showIcon ? defaultIcons[variant] : null)

    const handleDismiss = () => {
      setVisible(false)
      if (persistKey) {
        localStorage.setItem(`banner-dismissed-${persistKey}`, 'true')
      }
      onDismiss?.()
    }

    if (!visible) return null

    return (
      <div
        ref={ref}
        role="banner"
        className={cn(
          bannerVariants({ variant, position }),
          sticky && (position === 'top' ? 'sticky top-0' : 'sticky bottom-0'),
          'z-50 transition-all duration-300',
          className
        )}
        {...props}
      >
        {Icon && <Icon className="h-5 w-5 flex-shrink-0" />}
        
        <div className="flex-1 text-sm font-medium">
          {message}
        </div>

        <div className="flex items-center gap-2 flex-shrink-0">
          {action && (
            <Button
              size="sm"
              variant="default"
              onClick={action.onClick}
              className="h-8"
            >
              {action.label}
            </Button>
          )}
          
          {secondaryAction && (
            <Button
              size="sm"
              variant="ghost"
              onClick={secondaryAction.onClick}
              className="h-8"
            >
              {secondaryAction.label}
            </Button>
          )}

          {dismissible && (
            <button
              onClick={handleDismiss}
              className="rounded-sm opacity-70 transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring"
              aria-label="Dismiss banner"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>
    )
  }
)
Banner.displayName = 'Banner'

// ========================================
// BANNER GROUP
// ========================================

export interface BannerGroupProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Position of banner group
   */
  position?: 'top' | 'bottom'

  /**
   * Sticky position
   */
  sticky?: boolean
}

const BannerGroup = React.forwardRef<HTMLDivElement, BannerGroupProps>(
  ({ className, position = 'top', sticky = false, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          'flex flex-col',
          sticky && (position === 'top' ? 'sticky top-0' : 'sticky bottom-0'),
          'z-50',
          className
        )}
        {...props}
      >
        {children}
      </div>
    )
  }
)
BannerGroup.displayName = 'BannerGroup'

export { Banner, BannerGroup, bannerVariants }
```

---

## 📚 USAGE EXAMPLES

### Basic Banners

```typescript
import { Banner } from '@/components/ui/banner'

function BasicBanners() {
  return (
    <div className="space-y-4">
      <Banner
        variant="info"
        message="This is an informational banner."
      />

      <Banner
        variant="success"
        message="Your changes have been saved successfully."
      />

      <Banner
        variant="warning"
        message="Your trial period ends in 3 days."
      />

      <Banner
        variant="error"
        message="Unable to connect to the server."
      />
    </div>
  )
}
```

### Banner with Actions

```typescript
function BannerWithActions() {
  return (
    <Banner
      variant="warning"
      message="Your subscription is about to expire."
      action={{
        label: 'Renew Now',
        onClick: () => console.log('Renew clicked'),
      }}
      secondaryAction={{
        label: 'Learn More',
        onClick: () => console.log('Learn more clicked'),
      }}
    />
  )
}
```

### Sticky Banner

```typescript
function StickyBanner() {
  return (
    <Banner
      variant="info"
      message="We use cookies to improve your experience."
      sticky
      action={{
        label: 'Accept',
        onClick: () => console.log('Accept cookies'),
      }}
    />
  )
}
```

### Persistent Banner

```typescript
function PersistentBanner() {
  return (
    <Banner
      variant="info"
      message="Check out our new features!"
      persistKey="new-features-v2"
      action={{
        label: 'View Features',
        onClick: () => console.log('View features'),
      }}
    />
  )
}
```

### Bottom Banner

```typescript
function BottomBanner() {
  return (
    <Banner
      variant="warning"
      position="bottom"
      message="Unsaved changes. Remember to save your work."
      sticky
      action={{
        label: 'Save Now',
        onClick: () => console.log('Save'),
      }}
    />
  )
}
```

### Banner without Icon

```typescript
function BannerWithoutIcon() {
  return (
    <Banner
      variant="info"
      message="System maintenance scheduled for tonight at 2 AM."
      showIcon={false}
    />
  )
}
```

### Banner with Custom Icon

```typescript
import { Megaphone } from 'lucide-react'

function BannerWithCustomIcon() {
  return (
    <Banner
      variant="info"
      icon={Megaphone}
      message="Big announcement: New pricing plans available!"
      action={{
        label: 'View Plans',
        onClick: () => console.log('View plans'),
      }}
    />
  )
}
```

### Non-Dismissible Banner

```typescript
function NonDismissibleBanner() {
  return (
    <Banner
      variant="error"
      message="Critical system error. Please contact support."
      dismissible={false}
      action={{
        label: 'Contact Support',
        onClick: () => console.log('Contact support'),
      }}
    />
  )
}
```

### Banner Group

```typescript
import { BannerGroup } from '@/components/ui/banner'

function MultipleBanners() {
  return (
    <BannerGroup position="top" sticky>
      <Banner
        variant="error"
        message="Payment failed. Please update your payment method."
        action={{
          label: 'Update',
          onClick: () => console.log('Update payment'),
        }}
      />
      
      <Banner
        variant="warning"
        message="Your trial ends in 3 days."
        action={{
          label: 'Upgrade',
          onClick: () => console.log('Upgrade'),
        }}
      />
    </BannerGroup>
  )
}
```

### Rich Content Banner

```typescript
function RichContentBanner() {
  return (
    <Banner
      variant="info"
      message={
        <span>
          🎉 <strong>Version 2.0 is here!</strong> Check out{' '}
          <a href="/changelog" className="underline">
            what's new
          </a>
          .
        </span>
      }
    />
  )
}
```

### Controlled Banner

```typescript
function ControlledBanner() {
  const [showBanner, setShowBanner] = React.useState(true)

  return (
    <>
      {showBanner && (
        <Banner
          variant="info"
          message="This banner can be controlled externally."
          onDismiss={() => setShowBanner(false)}
        />
      )}
      
      <Button onClick={() => setShowBanner(true)}>
        Show Banner
      </Button>
    </>
  )
}
```

### School Management Banners

```typescript
function SchoolBanners() {
  return (
    <BannerGroup position="top" sticky>
      {/* Exam Schedule */}
      <Banner
        variant="info"
        message="Mid-term examinations start next week. View the complete schedule."
        persistKey="exam-schedule-2024"
        action={{
          label: 'View Schedule',
          onClick: () => console.log('View schedule'),
        }}
      />

      {/* Fee Payment Reminder */}
      <Banner
        variant="warning"
        message="Fee payment deadline is approaching. Pay before March 31st to avoid late fees."
        action={{
          label: 'Pay Now',
          onClick: () => console.log('Pay fees'),
        }}
        secondaryAction={{
          label: 'View Details',
          onClick: () => console.log('View details'),
        }}
      />

      {/* System Maintenance */}
      <Banner
        variant="error"
        message="Student portal will be unavailable for maintenance on Sunday 2-4 AM."
        dismissible={false}
      />
    </BannerGroup>
  )
}
```

### Announcement Banner

```typescript
function AnnouncementBanner() {
  return (
    <Banner
      variant="info"
      message="Join us for the annual sports day on March 15th! Register your child now."
      persistKey="sports-day-2024"
      sticky
      action={{
        label: 'Register',
        onClick: () => console.log('Register'),
      }}
      secondaryAction={{
        label: 'More Info',
        onClick: () => console.log('More info'),
      }}
    />
  )
}
```

### Emergency Banner

```typescript
function EmergencyBanner() {
  return (
    <Banner
      variant="error"
      message="URGENT: School closed today due to weather conditions."
      dismissible={false}
      sticky
      position="top"
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Banner', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('renders with message', () => {
    render(<Banner message="Test message" />)
    expect(screen.getByText('Test message')).toBeInTheDocument()
  })

  it('applies correct variant styles', () => {
    const { rerender } = render(<Banner variant="success" message="Success" />)
    expect(screen.getByRole('banner')).toHaveClass('bg-green-50')

    rerender(<Banner variant="error" message="Error" />)
    expect(screen.getByRole('banner')).toHaveClass('bg-red-50')
  })

  it('shows icon by default', () => {
    render(<Banner variant="info" message="Test" />)
    expect(document.querySelector('.lucide-info')).toBeInTheDocument()
  })

  it('hides icon when showIcon is false', () => {
    render(<Banner variant="info" message="Test" showIcon={false} />)
    expect(document.querySelector('.lucide-info')).not.toBeInTheDocument()
  })

  it('dismisses banner when close button is clicked', () => {
    const onDismiss = jest.fn()
    render(<Banner message="Test" onDismiss={onDismiss} />)

    const dismissButton = screen.getByLabelText('Dismiss banner')
    fireEvent.click(dismissButton)

    expect(onDismiss).toHaveBeenCalled()
    expect(screen.queryByText('Test')).not.toBeInTheDocument()
  })

  it('persists dismissal to localStorage', () => {
    render(<Banner message="Test" persistKey="test-banner" />)

    const dismissButton = screen.getByLabelText('Dismiss banner')
    fireEvent.click(dismissButton)

    expect(localStorage.getItem('banner-dismissed-test-banner')).toBe('true')
  })

  it('checks localStorage on mount', () => {
    localStorage.setItem('banner-dismissed-test-banner', 'true')
    
    render(<Banner message="Test" persistKey="test-banner" />)
    
    expect(screen.queryByText('Test')).not.toBeInTheDocument()
  })

  it('renders action button', () => {
    const onClick = jest.fn()
    render(
      <Banner
        message="Test"
        action={{ label: 'Click me', onClick }}
      />
    )

    const button = screen.getByText('Click me')
    fireEvent.click(button)
    expect(onClick).toHaveBeenCalled()
  })

  it('renders secondary action button', () => {
    const onClick = jest.fn()
    render(
      <Banner
        message="Test"
        secondaryAction={{ label: 'Secondary', onClick }}
      />
    )

    const button = screen.getByText('Secondary')
    fireEvent.click(button)
    expect(onClick).toHaveBeenCalled()
  })

  it('applies sticky class', () => {
    render(<Banner message="Test" sticky position="top" />)
    expect(screen.getByRole('banner')).toHaveClass('sticky', 'top-0')
  })

  it('hides dismiss button when not dismissible', () => {
    render(<Banner message="Test" dismissible={false} />)
    expect(screen.queryByLabelText('Dismiss banner')).not.toBeInTheDocument()
  })
})

describe('BannerGroup', () => {
  it('renders multiple banners', () => {
    render(
      <BannerGroup>
        <Banner message="Banner 1" />
        <Banner message="Banner 2" />
      </BannerGroup>
    )

    expect(screen.getByText('Banner 1')).toBeInTheDocument()
    expect(screen.getByText('Banner 2')).toBeInTheDocument()
  })

  it('applies sticky class to group', () => {
    const { container } = render(
      <BannerGroup sticky position="top">
        <Banner message="Test" />
      </BannerGroup>
    )

    expect(container.firstChild).toHaveClass('sticky', 'top-0')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ `role="banner"` for screen readers
- ✅ Keyboard navigation for dismiss and action buttons
- ✅ Focus indicators
- ✅ ARIA labels for dismiss button
- ✅ Color is not the only indicator (icons included)
- ✅ Sufficient color contrast

---

## 🎨 STYLING NOTES

### Position
- **Top**: Sticky at top of page
- **Bottom**: Sticky at bottom of page

### Z-Index
Banner has `z-50` to appear above most content but below modals.

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Lucide React: `npm install lucide-react`
- [ ] Create banner.tsx
- [ ] Implement Banner component with variants
- [ ] Add dismissible functionality
- [ ] Add localStorage persistence
- [ ] Implement sticky positioning
- [ ] Create BannerGroup component
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With Lucide React**: ~3KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
