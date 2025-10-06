# SPEC-103: Status Message Components
## Success, Warning, Info Message Components

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
Reusable status message components for displaying success, warning, and informational messages throughout the application.

### Key Features
- ✅ Multiple variants (success, warning, info)
- ✅ Inline and block layouts
- ✅ Icon support
- ✅ Dismissible
- ✅ Custom actions
- ✅ Auto-dismiss
- ✅ Animations
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/status-message.tsx
import * as React from 'react'
import { CheckCircle2, AlertTriangle, Info, X } from 'lucide-react'
import { cva, type VariantProps } from 'class-variance-authority'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

// ========================================
// VARIANTS
// ========================================

const statusMessageVariants = cva(
  'flex gap-3 p-4 rounded-lg border transition-all',
  {
    variants: {
      variant: {
        success: 'bg-green-50 border-green-200 text-green-900 dark:bg-green-950 dark:border-green-800 dark:text-green-100',
        warning: 'bg-yellow-50 border-yellow-200 text-yellow-900 dark:bg-yellow-950 dark:border-yellow-800 dark:text-yellow-100',
        info: 'bg-blue-50 border-blue-200 text-blue-900 dark:bg-blue-950 dark:border-blue-800 dark:text-blue-100',
      },
      layout: {
        inline: 'items-center',
        block: 'items-start',
      },
    },
    defaultVariants: {
      variant: 'info',
      layout: 'inline',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface StatusMessageProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof statusMessageVariants> {
  /**
   * Message title
   */
  title?: string

  /**
   * Message content
   */
  message: string | React.ReactNode

  /**
   * Show icon
   */
  showIcon?: boolean

  /**
   * Custom icon
   */
  icon?: React.ReactNode

  /**
   * Dismissible
   */
  dismissible?: boolean

  /**
   * On dismiss callback
   */
  onDismiss?: () => void

  /**
   * Auto dismiss after ms (0 = no auto dismiss)
   */
  autoDismiss?: number

  /**
   * Custom actions
   */
  actions?: React.ReactNode
}

// ========================================
// STATUS MESSAGE COMPONENT
// ========================================

/**
 * Status Message Component
 * 
 * Displays success, warning, or informational messages.
 */
export const StatusMessage = React.forwardRef<
  HTMLDivElement,
  StatusMessageProps
>(
  (
    {
      variant = 'info',
      layout = 'inline',
      title,
      message,
      showIcon = true,
      icon,
      dismissible = false,
      onDismiss,
      autoDismiss = 0,
      actions,
      className,
      ...props
    },
    ref
  ) => {
    const [isVisible, setIsVisible] = React.useState(true)

    // Auto dismiss
    React.useEffect(() => {
      if (autoDismiss > 0) {
        const timer = setTimeout(() => {
          handleDismiss()
        }, autoDismiss)
        return () => clearTimeout(timer)
      }
    }, [autoDismiss])

    const handleDismiss = () => {
      setIsVisible(false)
      onDismiss?.()
    }

    if (!isVisible) return null

    // Default icons
    const defaultIcon = {
      success: <CheckCircle2 className="h-5 w-5" />,
      warning: <AlertTriangle className="h-5 w-5" />,
      info: <Info className="h-5 w-5" />,
    }[variant]

    return (
      <div
        ref={ref}
        className={cn(statusMessageVariants({ variant, layout }), className)}
        role="alert"
        {...props}
      >
        {/* Icon */}
        {showIcon && (
          <div className="flex-shrink-0">
            {icon || defaultIcon}
          </div>
        )}

        {/* Content */}
        <div className="flex-1 min-w-0">
          {title && (
            <h4 className="text-sm font-semibold mb-1">{title}</h4>
          )}
          <div className="text-sm">{message}</div>
          {actions && (
            <div className="mt-3 flex gap-2">
              {actions}
            </div>
          )}
        </div>

        {/* Dismiss button */}
        {dismissible && (
          <button
            type="button"
            onClick={handleDismiss}
            className="flex-shrink-0 opacity-70 hover:opacity-100 transition-opacity"
            aria-label="Dismiss"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
    )
  }
)

StatusMessage.displayName = 'StatusMessage'

// ========================================
// SUCCESS MESSAGE
// ========================================

export interface SuccessMessageProps
  extends Omit<StatusMessageProps, 'variant'> {}

/**
 * Success Message Component
 */
export const SuccessMessage = React.forwardRef<
  HTMLDivElement,
  SuccessMessageProps
>((props, ref) => {
  return <StatusMessage ref={ref} variant="success" {...props} />
})

SuccessMessage.displayName = 'SuccessMessage'

// ========================================
// WARNING MESSAGE
// ========================================

export interface WarningMessageProps
  extends Omit<StatusMessageProps, 'variant'> {}

/**
 * Warning Message Component
 */
export const WarningMessage = React.forwardRef<
  HTMLDivElement,
  WarningMessageProps
>((props, ref) => {
  return <StatusMessage ref={ref} variant="warning" {...props} />
})

WarningMessage.displayName = 'WarningMessage'

// ========================================
// INFO MESSAGE
// ========================================

export interface InfoMessageProps
  extends Omit<StatusMessageProps, 'variant'> {}

/**
 * Info Message Component
 */
export const InfoMessage = React.forwardRef<
  HTMLDivElement,
  InfoMessageProps
>((props, ref) => {
  return <StatusMessage ref={ref} variant="info" {...props} />
})

InfoMessage.displayName = 'InfoMessage'

// ========================================
// MESSAGE LIST
// ========================================

export interface MessageListProps {
  /**
   * Messages to display
   */
  messages: Array<{
    id: string
    variant: 'success' | 'warning' | 'info'
    message: string
    title?: string
  }>

  /**
   * On dismiss message
   */
  onDismiss?: (id: string) => void

  /**
   * Additional classname
   */
  className?: string
}

/**
 * Message List Component
 * 
 * Displays multiple status messages in a list.
 */
export function MessageList({
  messages,
  onDismiss,
  className,
}: MessageListProps) {
  return (
    <div className={cn('space-y-3', className)}>
      {messages.map((msg) => (
        <StatusMessage
          key={msg.id}
          variant={msg.variant}
          title={msg.title}
          message={msg.message}
          dismissible={!!onDismiss}
          onDismiss={() => onDismiss?.(msg.id)}
        />
      ))}
    </div>
  )
}

// ========================================
// USE STATUS MESSAGE HOOK
// ========================================

export interface UseStatusMessageReturn {
  messages: MessageListProps['messages']
  showSuccess: (message: string, title?: string) => void
  showWarning: (message: string, title?: string) => void
  showInfo: (message: string, title?: string) => void
  dismiss: (id: string) => void
  clear: () => void
}

/**
 * Use Status Message Hook
 * 
 * Manages multiple status messages.
 */
export function useStatusMessage(): UseStatusMessageReturn {
  const [messages, setMessages] = React.useState<
    MessageListProps['messages']
  >([])

  const addMessage = React.useCallback(
    (variant: 'success' | 'warning' | 'info', message: string, title?: string) => {
      const id = `${Date.now()}-${Math.random()}`
      setMessages((prev) => [...prev, { id, variant, message, title }])
    },
    []
  )

  const showSuccess = React.useCallback(
    (message: string, title?: string) => addMessage('success', message, title),
    [addMessage]
  )

  const showWarning = React.useCallback(
    (message: string, title?: string) => addMessage('warning', message, title),
    [addMessage]
  )

  const showInfo = React.useCallback(
    (message: string, title?: string) => addMessage('info', message, title),
    [addMessage]
  )

  const dismiss = React.useCallback((id: string) => {
    setMessages((prev) => prev.filter((msg) => msg.id !== id))
  }, [])

  const clear = React.useCallback(() => {
    setMessages([])
  }, [])

  return {
    messages,
    showSuccess,
    showWarning,
    showInfo,
    dismiss,
    clear,
  }
}
```

---

## 📚 USAGE EXAMPLES

### Success Message

```typescript
import { SuccessMessage } from '@/components/ui/status-message'

function FormSuccess() {
  return (
    <SuccessMessage
      title="Success!"
      message="Your data has been saved successfully."
    />
  )
}
```

### Warning Message

```typescript
import { WarningMessage } from '@/components/ui/status-message'

function WarningExample() {
  return (
    <WarningMessage
      title="Warning"
      message="Your session will expire in 5 minutes. Please save your work."
      dismissible
    />
  )
}
```

### Info Message

```typescript
import { InfoMessage } from '@/components/ui/status-message'

function InfoExample() {
  return (
    <InfoMessage
      message="You can now access advanced features in your dashboard."
    />
  )
}
```

### With Actions

```typescript
import { SuccessMessage } from '@/components/ui/status-message'
import { Button } from '@/components/ui/button'

function MessageWithActions() {
  return (
    <SuccessMessage
      title="Payment Successful"
      message="Your payment has been processed."
      actions={
        <>
          <Button size="sm" variant="ghost">
            View Receipt
          </Button>
          <Button size="sm">
            Download Invoice
          </Button>
        </>
      }
    />
  )
}
```

### Block Layout

```typescript
import { WarningMessage } from '@/components/ui/status-message'

function BlockMessage() {
  return (
    <WarningMessage
      layout="block"
      title="Important Update"
      message={
        <div className="space-y-2">
          <p>The following changes will take effect immediately:</p>
          <ul className="list-disc list-inside">
            <li>New password requirements</li>
            <li>Updated privacy policy</li>
            <li>Enhanced security features</li>
          </ul>
        </div>
      }
    />
  )
}
```

### Auto Dismiss

```typescript
import { SuccessMessage } from '@/components/ui/status-message'

function AutoDismissMessage() {
  return (
    <SuccessMessage
      message="Changes saved!"
      autoDismiss={3000} // Dismiss after 3 seconds
    />
  )
}
```

### Dismissible Message

```typescript
import { InfoMessage } from '@/components/ui/status-message'

function DismissibleMessage() {
  const handleDismiss = () => {
    console.log('Message dismissed')
  }

  return (
    <InfoMessage
      message="This is a dismissible message."
      dismissible
      onDismiss={handleDismiss}
    />
  )
}
```

### Custom Icon

```typescript
import { StatusMessage } from '@/components/ui/status-message'
import { Sparkles } from 'lucide-react'

function CustomIconMessage() {
  return (
    <StatusMessage
      variant="success"
      icon={<Sparkles className="h-5 w-5" />}
      title="New Feature!"
      message="Check out our latest update."
    />
  )
}
```

### Message List

```typescript
import { MessageList } from '@/components/ui/status-message'

function MultipleMessages() {
  const messages = [
    { id: '1', variant: 'success', message: 'Profile updated' },
    { id: '2', variant: 'warning', message: 'Password expires soon' },
    { id: '3', variant: 'info', message: 'New feature available' },
  ]

  const handleDismiss = (id: string) => {
    console.log('Dismissed:', id)
  }

  return <MessageList messages={messages} onDismiss={handleDismiss} />
}
```

### Using Hook

```typescript
import { useStatusMessage, MessageList } from '@/components/ui/status-message'

function FormWithMessages() {
  const { messages, showSuccess, showWarning, showInfo, dismiss } =
    useStatusMessage()

  const handleSubmit = async () => {
    try {
      await submitForm()
      showSuccess('Form submitted successfully!', 'Success')
    } catch (error) {
      showWarning('Failed to submit form.', 'Error')
    }
  }

  return (
    <div className="space-y-4">
      <MessageList messages={messages} onDismiss={dismiss} />
      <form onSubmit={handleSubmit}>
        {/* Form fields */}
        <button type="submit">Submit</button>
      </form>
    </div>
  )
}
```

### School Management Examples

```typescript
// Student Enrollment Success
function EnrollmentSuccess() {
  return (
    <SuccessMessage
      title="Enrollment Complete"
      message="The student has been successfully enrolled in Grade 10A."
      actions={
        <>
          <Button size="sm" variant="ghost" onClick={() => window.print()}>
            Print Confirmation
          </Button>
          <Button size="sm" onClick={() => navigate('/students')}>
            View All Students
          </Button>
        </>
      }
    />
  )
}

// Attendance Warning
function AttendanceWarning() {
  return (
    <WarningMessage
      title="Low Attendance Alert"
      message="Student John Doe has attended only 65% of classes this month. Minimum requirement is 75%."
      actions={
        <Button size="sm" onClick={() => navigate('/attendance/report')}>
          View Attendance Report
        </Button>
      }
    />
  )
}

// Grade Submission Info
function GradeSubmissionInfo() {
  return (
    <InfoMessage
      title="Grade Submission Deadline"
      message="All grades must be submitted by December 15th, 2024. Students and parents will be notified automatically."
      dismissible
    />
  )
}

// Fee Payment Success
function FeePaymentSuccess() {
  return (
    <SuccessMessage
      title="Payment Received"
      message="Fee payment of $500 has been received for Semester 1, 2024."
      actions={
        <>
          <Button size="sm" variant="ghost" onClick={() => window.print()}>
            Print Receipt
          </Button>
          <Button size="sm">
            Email Receipt
          </Button>
        </>
      }
    />
  )
}

// Exam Schedule Info
function ExamScheduleInfo() {
  return (
    <InfoMessage
      layout="block"
      title="Upcoming Examinations"
      message={
        <div className="space-y-2">
          <p>Final examinations will begin on January 10, 2025:</p>
          <ul className="list-disc list-inside mt-2">
            <li>Math: January 10, 9:00 AM</li>
            <li>Science: January 12, 9:00 AM</li>
            <li>English: January 14, 9:00 AM</li>
          </ul>
        </div>
      }
      actions={
        <Button size="sm">
          Download Full Schedule
        </Button>
      }
    />
  )
}

// Multi-Message Dashboard
function DashboardMessages() {
  const { messages, showSuccess, showWarning, showInfo, dismiss, clear } =
    useStatusMessage()

  React.useEffect(() => {
    // Show initial messages
    showInfo('Welcome back! You have 3 pending approvals.')
    
    // Check for warnings
    if (hasLowAttendance) {
      showWarning('2 students have attendance below 75%')
    }

    // Show success if applicable
    if (recentActions.length > 0) {
      showSuccess('All grade submissions completed successfully')
    }
  }, [])

  return (
    <div className="space-y-4">
      {messages.length > 0 && (
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-sm font-medium">Notifications</h3>
          <Button size="sm" variant="ghost" onClick={clear}>
            Clear All
          </Button>
        </div>
      )}
      <MessageList messages={messages} onDismiss={dismiss} />
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('StatusMessage', () => {
  it('renders success message', () => {
    render(
      <StatusMessage variant="success" message="Success message" />
    )
    expect(screen.getByText('Success message')).toBeInTheDocument()
  })

  it('renders with title', () => {
    render(
      <StatusMessage
        title="Title"
        message="Message"
      />
    )
    expect(screen.getByText('Title')).toBeInTheDocument()
    expect(screen.getByText('Message')).toBeInTheDocument()
  })

  it('shows default icon', () => {
    render(
      <StatusMessage variant="success" message="Test" />
    )
    expect(document.querySelector('svg')).toBeInTheDocument()
  })

  it('hides icon when showIcon is false', () => {
    render(
      <StatusMessage message="Test" showIcon={false} />
    )
    expect(document.querySelector('svg')).not.toBeInTheDocument()
  })

  it('renders custom icon', () => {
    render(
      <StatusMessage
        message="Test"
        icon={<div data-testid="custom-icon">Custom</div>}
      />
    )
    expect(screen.getByTestId('custom-icon')).toBeInTheDocument()
  })

  it('is dismissible', () => {
    const onDismiss = jest.fn()
    render(
      <StatusMessage
        message="Test"
        dismissible
        onDismiss={onDismiss}
      />
    )

    const dismissButton = screen.getByLabelText('Dismiss')
    fireEvent.click(dismissButton)

    expect(onDismiss).toHaveBeenCalled()
  })

  it('auto dismisses after specified time', () => {
    jest.useFakeTimers()
    const onDismiss = jest.fn()

    render(
      <StatusMessage
        message="Test"
        autoDismiss={1000}
        onDismiss={onDismiss}
      />
    )

    jest.advanceTimersByTime(1000)

    expect(onDismiss).toHaveBeenCalled()
    jest.useRealTimers()
  })

  it('renders custom actions', () => {
    render(
      <StatusMessage
        message="Test"
        actions={<button>Action</button>}
      />
    )
    expect(screen.getByText('Action')).toBeInTheDocument()
  })
})

describe('useStatusMessage', () => {
  it('adds success message', () => {
    function TestComponent() {
      const { messages, showSuccess } = useStatusMessage()
      return (
        <>
          <button onClick={() => showSuccess('Success!')}>
            Show
          </button>
          <MessageList messages={messages} />
        </>
      )
    }

    render(<TestComponent />)
    fireEvent.click(screen.getByText('Show'))

    expect(screen.getByText('Success!')).toBeInTheDocument()
  })

  it('dismisses message', () => {
    function TestComponent() {
      const { messages, showInfo, dismiss } = useStatusMessage()
      return (
        <>
          <button onClick={() => showInfo('Info')}>Show</button>
          <MessageList messages={messages} onDismiss={dismiss} />
        </>
      )
    }

    render(<TestComponent />)
    fireEvent.click(screen.getByText('Show'))

    const dismissButton = screen.getByLabelText('Dismiss')
    fireEvent.click(dismissButton)

    expect(screen.queryByText('Info')).not.toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ role="alert" for screen readers
- ✅ Keyboard accessible dismiss button
- ✅ Focus management
- ✅ Clear, descriptive content
- ✅ Sufficient color contrast
- ✅ Icon + text for clarity

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install CVA: `npm install class-variance-authority`
- [ ] Create status-message.tsx
- [ ] Implement StatusMessage component
- [ ] Add variant styles (success, warning, info)
- [ ] Add inline/block layouts
- [ ] Implement dismissible functionality
- [ ] Add auto-dismiss feature
- [ ] Create SuccessMessage, WarningMessage, InfoMessage shortcuts
- [ ] Implement MessageList component
- [ ] Create useStatusMessage hook
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With CVA**: ~3KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
