# SPEC-097: Alert Component
## Inline Message Notifications

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: Lucide React (icons), CVA

---

## 📋 OVERVIEW

### Purpose
An alert component for displaying important inline messages, warnings, errors, and informational content that requires user attention.

### Key Features
- ✅ Multiple variants (default, success, warning, error, info)
- ✅ Dismissible alerts
- ✅ Icon support
- ✅ Title and description
- ✅ Action buttons
- ✅ Custom styling
- ✅ Animations
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/alert.tsx
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

// ========================================
// TYPE DEFINITIONS
// ========================================

const alertVariants = cva(
  'relative w-full rounded-lg border p-4 [&>svg~*]:pl-7 [&>svg+div]:translate-y-[-3px] [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg]:text-foreground',
  {
    variants: {
      variant: {
        default: 'bg-background text-foreground',
        success: 'border-green-500/50 bg-green-50 text-green-900 dark:border-green-500 dark:bg-green-950 dark:text-green-100 [&>svg]:text-green-600 dark:[&>svg]:text-green-400',
        warning: 'border-yellow-500/50 bg-yellow-50 text-yellow-900 dark:border-yellow-500 dark:bg-yellow-950 dark:text-yellow-100 [&>svg]:text-yellow-600 dark:[&>svg]:text-yellow-400',
        error: 'border-red-500/50 bg-red-50 text-red-900 dark:border-red-500 dark:bg-red-950 dark:text-red-100 [&>svg]:text-red-600 dark:[&>svg]:text-red-400',
        info: 'border-blue-500/50 bg-blue-50 text-blue-900 dark:border-blue-500 dark:bg-blue-950 dark:text-blue-100 [&>svg]:text-blue-600 dark:[&>svg]:text-blue-400',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
)

export interface AlertProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof alertVariants> {
  /**
   * Show default icon
   */
  showIcon?: boolean

  /**
   * Custom icon
   */
  icon?: LucideIcon

  /**
   * Dismissible alert
   */
  dismissible?: boolean

  /**
   * On dismiss callback
   */
  onDismiss?: () => void

  /**
   * Alert title
   */
  title?: string

  /**
   * Alert description
   */
  description?: string | React.ReactNode

  /**
   * Action buttons
   */
  actions?: React.ReactNode
}

// ========================================
// ALERT COMPONENT
// ========================================

const Alert = React.forwardRef<HTMLDivElement, AlertProps>(
  (
    {
      className,
      variant = 'default',
      showIcon = true,
      icon: CustomIcon,
      dismissible = false,
      onDismiss,
      title,
      description,
      actions,
      children,
      ...props
    },
    ref
  ) => {
    const [visible, setVisible] = React.useState(true)

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
      onDismiss?.()
    }

    if (!visible) return null

    return (
      <div
        ref={ref}
        role="alert"
        className={cn(
          alertVariants({ variant }),
          'transition-all duration-300',
          className
        )}
        {...props}
      >
        {Icon && <Icon className="h-4 w-4" />}
        
        <div className="flex-1">
          {title && <AlertTitle>{title}</AlertTitle>}
          {description && <AlertDescription>{description}</AlertDescription>}
          {children}
          {actions && <div className="mt-3">{actions}</div>}
        </div>

        {dismissible && (
          <button
            onClick={handleDismiss}
            className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
            aria-label="Close alert"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
    )
  }
)
Alert.displayName = 'Alert'

// ========================================
// ALERT TITLE
// ========================================

const AlertTitle = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
  <h5
    ref={ref}
    className={cn('mb-1 font-semibold leading-none tracking-tight', className)}
    {...props}
  />
))
AlertTitle.displayName = 'AlertTitle'

// ========================================
// ALERT DESCRIPTION
// ========================================

const AlertDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('text-sm [&_p]:leading-relaxed', className)}
    {...props}
  />
))
AlertDescription.displayName = 'AlertDescription'

// ========================================
// ALERT ACTIONS
// ========================================

export interface AlertActionsProps extends React.HTMLAttributes<HTMLDivElement> {}

const AlertActions = React.forwardRef<HTMLDivElement, AlertActionsProps>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn('flex items-center gap-2 mt-3', className)}
      {...props}
    />
  )
)
AlertActions.displayName = 'AlertActions'

export { Alert, AlertTitle, AlertDescription, AlertActions, alertVariants }
```

---

## 📚 USAGE EXAMPLES

### Basic Alerts

```typescript
import { Alert, AlertTitle, AlertDescription } from '@/components/ui/alert'

function BasicAlerts() {
  return (
    <div className="space-y-4">
      <Alert variant="default">
        <AlertTitle>Default Alert</AlertTitle>
        <AlertDescription>
          This is a default alert message.
        </AlertDescription>
      </Alert>

      <Alert variant="success">
        <AlertTitle>Success!</AlertTitle>
        <AlertDescription>
          Your changes have been saved successfully.
        </AlertDescription>
      </Alert>

      <Alert variant="warning">
        <AlertTitle>Warning</AlertTitle>
        <AlertDescription>
          Please review your information before proceeding.
        </AlertDescription>
      </Alert>

      <Alert variant="error">
        <AlertTitle>Error</AlertTitle>
        <AlertDescription>
          An error occurred while processing your request.
        </AlertDescription>
      </Alert>

      <Alert variant="info">
        <AlertTitle>Information</AlertTitle>
        <AlertDescription>
          This feature is currently in beta.
        </AlertDescription>
      </Alert>
    </div>
  )
}
```

### Simple Alert (using props)

```typescript
function SimpleAlert() {
  return (
    <div className="space-y-4">
      <Alert
        variant="success"
        title="Success"
        description="Your profile has been updated."
      />
      
      <Alert
        variant="error"
        title="Error"
        description="Failed to connect to the server."
      />
    </div>
  )
}
```

### Dismissible Alert

```typescript
function DismissibleAlert() {
  return (
    <Alert
      variant="info"
      title="New Update Available"
      description="Version 2.0 is now available. Click here to learn more."
      dismissible
      onDismiss={() => console.log('Alert dismissed')}
    />
  )
}
```

### Alert with Actions

```typescript
import { Button } from '@/components/ui/button'
import { AlertActions } from '@/components/ui/alert'

function AlertWithActions() {
  return (
    <Alert variant="warning">
      <AlertTitle>Unsaved Changes</AlertTitle>
      <AlertDescription>
        You have unsaved changes. Do you want to save them before leaving?
      </AlertDescription>
      <AlertActions>
        <Button size="sm" variant="default">
          Save Changes
        </Button>
        <Button size="sm" variant="outline">
          Discard
        </Button>
      </AlertActions>
    </Alert>
  )
}
```

### Alert without Icon

```typescript
function AlertWithoutIcon() {
  return (
    <Alert
      variant="info"
      showIcon={false}
      title="Did you know?"
      description="You can customize your dashboard layout by dragging widgets."
    />
  )
}
```

### Alert with Custom Icon

```typescript
import { Rocket } from 'lucide-react'

function AlertWithCustomIcon() {
  return (
    <Alert
      variant="info"
      icon={Rocket}
      title="New Feature!"
      description="Check out our new rocket-powered search."
    />
  )
}
```

### Alert with Rich Content

```typescript
function RichContentAlert() {
  return (
    <Alert variant="info">
      <AlertTitle>Getting Started</AlertTitle>
      <AlertDescription>
        <p className="mb-2">Welcome to your dashboard! Here are some tips:</p>
        <ul className="list-disc list-inside space-y-1">
          <li>Navigate using the sidebar</li>
          <li>Click on cards to view details</li>
          <li>Use the search bar to find anything</li>
        </ul>
      </AlertDescription>
    </Alert>
  )
}
```

### Controlled Dismissible Alert

```typescript
function ControlledAlert() {
  const [showAlert, setShowAlert] = React.useState(true)

  if (!showAlert) return null

  return (
    <Alert
      variant="warning"
      title="Cookie Policy"
      description="We use cookies to improve your experience."
      dismissible
      onDismiss={() => setShowAlert(false)}
    />
  )
}
```

### Alert with Link

```typescript
import Link from 'next/link'

function AlertWithLink() {
  return (
    <Alert variant="info">
      <AlertTitle>Update Available</AlertTitle>
      <AlertDescription>
        A new version is available.{' '}
        <Link href="/updates" className="font-medium underline">
          View release notes
        </Link>
      </AlertDescription>
    </Alert>
  )
}
```

### Form Validation Alert

```typescript
function FormValidationAlert({ errors }: { errors: string[] }) {
  if (errors.length === 0) return null

  return (
    <Alert variant="error">
      <AlertTitle>Please fix the following errors:</AlertTitle>
      <AlertDescription>
        <ul className="list-disc list-inside space-y-1 mt-2">
          {errors.map((error, index) => (
            <li key={index}>{error}</li>
          ))}
        </ul>
      </AlertDescription>
    </Alert>
  )
}
```

### Inline Alert in Form

```typescript
function FormWithAlert() {
  const [error, setError] = React.useState<string | null>(null)

  return (
    <form className="space-y-4">
      {error && (
        <Alert
          variant="error"
          description={error}
          dismissible
          onDismiss={() => setError(null)}
        />
      )}
      
      <Input placeholder="Email" />
      <Input type="password" placeholder="Password" />
      <Button type="submit">Sign In</Button>
    </form>
  )
}
```

### Alert with Loading State

```typescript
function LoadingAlert() {
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    setTimeout(() => setLoading(false), 3000)
  }, [])

  if (loading) {
    return (
      <Alert variant="info">
        <AlertTitle>Processing...</AlertTitle>
        <AlertDescription>
          Please wait while we process your request.
        </AlertDescription>
      </Alert>
    )
  }

  return (
    <Alert variant="success">
      <AlertTitle>Complete!</AlertTitle>
      <AlertDescription>
        Your request has been processed successfully.
      </AlertDescription>
    </Alert>
  )
}
```

### School Management Alerts

```typescript
function SchoolAlerts() {
  return (
    <div className="space-y-4">
      {/* Attendance Warning */}
      <Alert variant="warning">
        <AlertTitle>Low Attendance Alert</AlertTitle>
        <AlertDescription>
          Class 10-A has attendance below 80% this week. Please take necessary action.
        </AlertDescription>
        <AlertActions>
          <Button size="sm">View Details</Button>
          <Button size="sm" variant="outline">Send Notice</Button>
        </AlertActions>
      </Alert>

      {/* Grade Submission Reminder */}
      <Alert variant="info">
        <AlertTitle>Grade Submission Reminder</AlertTitle>
        <AlertDescription>
          Mid-term grades are due in 3 days. Please submit grades for all assigned classes.
        </AlertDescription>
        <AlertActions>
          <Button size="sm">Submit Grades</Button>
        </AlertActions>
      </Alert>

      {/* Fee Payment Success */}
      <Alert variant="success">
        <AlertTitle>Payment Received</AlertTitle>
        <AlertDescription>
          Fee payment of $500 received from John Doe (Student ID: 12345).
        </AlertDescription>
      </Alert>

      {/* System Maintenance */}
      <Alert variant="warning" dismissible>
        <AlertTitle>Scheduled Maintenance</AlertTitle>
        <AlertDescription>
          The system will be under maintenance on Sunday, 2 AM - 4 AM EST.
        </AlertDescription>
      </Alert>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Alert', () => {
  it('renders with title and description', () => {
    render(
      <Alert title="Test Title" description="Test Description" />
    )
    expect(screen.getByText('Test Title')).toBeInTheDocument()
    expect(screen.getByText('Test Description')).toBeInTheDocument()
  })

  it('applies correct variant styles', () => {
    const { rerender } = render(<Alert variant="success" title="Success" />)
    expect(screen.getByRole('alert')).toHaveClass('border-green-500/50')

    rerender(<Alert variant="error" title="Error" />)
    expect(screen.getByRole('alert')).toHaveClass('border-red-500/50')
  })

  it('shows icon by default', () => {
    render(<Alert variant="success" title="Success" />)
    expect(document.querySelector('.lucide-check-circle-2')).toBeInTheDocument()
  })

  it('hides icon when showIcon is false', () => {
    render(<Alert variant="success" title="Success" showIcon={false} />)
    expect(document.querySelector('.lucide-check-circle-2')).not.toBeInTheDocument()
  })

  it('renders custom icon', () => {
    const CustomIcon = () => <span data-testid="custom-icon">Icon</span>
    render(<Alert icon={CustomIcon} title="Test" />)
    expect(screen.getByTestId('custom-icon')).toBeInTheDocument()
  })

  it('dismisses alert when close button is clicked', () => {
    const onDismiss = jest.fn()
    render(
      <Alert
        title="Test"
        dismissible
        onDismiss={onDismiss}
      />
    )

    const closeButton = screen.getByLabelText('Close alert')
    fireEvent.click(closeButton)

    expect(onDismiss).toHaveBeenCalled()
    expect(screen.queryByText('Test')).not.toBeInTheDocument()
  })

  it('renders actions', () => {
    render(
      <Alert title="Test">
        <AlertActions>
          <button>Action 1</button>
          <button>Action 2</button>
        </AlertActions>
      </Alert>
    )
    expect(screen.getByText('Action 1')).toBeInTheDocument()
    expect(screen.getByText('Action 2')).toBeInTheDocument()
  })

  it('renders children', () => {
    render(
      <Alert title="Test">
        <div>Custom content</div>
      </Alert>
    )
    expect(screen.getByText('Custom content')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ `role="alert"` for screen readers
- ✅ Semantic HTML structure
- ✅ Keyboard navigation for dismissible alerts
- ✅ Focus management on close button
- ✅ Color is not the only indicator (icons included)
- ✅ Sufficient color contrast

---

## 🎨 STYLING NOTES

### Variant Colors
```css
/* Success: Green */
--alert-success-bg: hsl(142 52% 96%)
--alert-success-border: hsl(142 71% 45%)
--alert-success-text: hsl(142 71% 20%)

/* Warning: Yellow */
--alert-warning-bg: hsl(48 96% 96%)
--alert-warning-border: hsl(48 96% 53%)
--alert-warning-text: hsl(48 96% 20%)

/* Error: Red */
--alert-error-bg: hsl(0 84% 96%)
--alert-error-border: hsl(0 84% 60%)
--alert-error-text: hsl(0 84% 20%)

/* Info: Blue */
--alert-info-bg: hsl(217 91% 96%)
--alert-info-border: hsl(217 91% 60%)
--alert-info-text: hsl(217 91% 20%)
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Lucide React: `npm install lucide-react`
- [ ] Create alert.tsx
- [ ] Implement Alert component with variants
- [ ] Add AlertTitle component
- [ ] Add AlertDescription component
- [ ] Add AlertActions component
- [ ] Implement dismissible functionality
- [ ] Add icon support (default and custom)
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
