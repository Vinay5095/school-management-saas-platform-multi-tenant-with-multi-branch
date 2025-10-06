# SPEC-096: Toast Component
## Notification Messages with Sonner

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: Sonner

---

## 📋 OVERVIEW

### Purpose
A toast notification component using Sonner for displaying temporary, non-intrusive messages to users about actions, errors, and system events.

### Key Features
- ✅ Sonner integration for modern toast notifications
- ✅ Multiple variants (default, success, error, warning, info)
- ✅ Promise-based toasts for async operations
- ✅ Action buttons
- ✅ Custom duration
- ✅ Positioning options
- ✅ Rich content support
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/toast.tsx
import * as React from 'react'
import { Toaster as Sonner, toast as sonnerToast } from 'sonner'
import { useTheme } from 'next-themes'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ToastAction {
  label: string
  onClick: () => void
}

export interface ToastOptions {
  /**
   * Toast title
   */
  title?: string

  /**
   * Toast description
   */
  description?: string | React.ReactNode

  /**
   * Duration in milliseconds (default: 4000)
   */
  duration?: number

  /**
   * Action button
   */
  action?: ToastAction

  /**
   * Cancel button
   */
  cancel?: ToastAction

  /**
   * Toast ID for updates
   */
  id?: string | number

  /**
   * Dismiss on click
   */
  dismissible?: boolean

  /**
   * Custom icon
   */
  icon?: React.ReactNode

  /**
   * Class name
   */
  className?: string
}

export interface PromiseToastOptions<T> {
  loading: string | React.ReactNode
  success: string | ((data: T) => React.ReactNode)
  error: string | ((error: Error) => React.ReactNode)
  duration?: number
}

// ========================================
// TOASTER COMPONENT
// ========================================

export interface ToasterProps {
  /**
   * Position of toasts
   */
  position?:
    | 'top-left'
    | 'top-center'
    | 'top-right'
    | 'bottom-left'
    | 'bottom-center'
    | 'bottom-right'

  /**
   * Theme
   */
  theme?: 'light' | 'dark' | 'system'

  /**
   * Rich colors
   */
  richColors?: boolean

  /**
   * Expand toasts by default
   */
  expand?: boolean

  /**
   * Maximum visible toasts
   */
  visibleToasts?: number

  /**
   * Close button
   */
  closeButton?: boolean

  /**
   * Toast duration (default: 4000ms)
   */
  duration?: number
}

/**
 * Toaster Component
 * 
 * Must be placed in root layout.
 */
export function Toaster({
  position = 'bottom-right',
  theme: propTheme,
  richColors = true,
  expand = false,
  visibleToasts = 5,
  closeButton = true,
  duration = 4000,
}: ToasterProps) {
  const { theme: systemTheme } = useTheme()
  const theme = propTheme || (systemTheme as 'light' | 'dark' | 'system')

  return (
    <Sonner
      position={position}
      theme={theme}
      richColors={richColors}
      expand={expand}
      visibleToasts={visibleToasts}
      closeButton={closeButton}
      duration={duration}
      toastOptions={{
        classNames: {
          toast: 'group toast',
          title: 'text-sm font-semibold',
          description: 'text-sm text-muted-foreground',
          actionButton: 'bg-primary text-primary-foreground',
          cancelButton: 'bg-muted text-muted-foreground',
          closeButton: 'bg-muted text-muted-foreground',
        },
      }}
    />
  )
}

// ========================================
// TOAST FUNCTIONS
// ========================================

/**
 * Show a default toast
 */
export function toast(message: string | React.ReactNode, options?: ToastOptions) {
  return sonnerToast(message, {
    description: options?.description,
    duration: options?.duration,
    action: options?.action
      ? {
          label: options.action.label,
          onClick: options.action.onClick,
        }
      : undefined,
    cancel: options?.cancel
      ? {
          label: options.cancel.label,
          onClick: options.cancel.onClick,
        }
      : undefined,
    id: options?.id,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Show a success toast
 */
toast.success = (message: string | React.ReactNode, options?: ToastOptions) => {
  return sonnerToast.success(message, {
    description: options?.description,
    duration: options?.duration,
    action: options?.action
      ? {
          label: options.action.label,
          onClick: options.action.onClick,
        }
      : undefined,
    cancel: options?.cancel,
    id: options?.id,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Show an error toast
 */
toast.error = (message: string | React.ReactNode, options?: ToastOptions) => {
  return sonnerToast.error(message, {
    description: options?.description,
    duration: options?.duration,
    action: options?.action
      ? {
          label: options.action.label,
          onClick: options.action.onClick,
        }
      : undefined,
    cancel: options?.cancel,
    id: options?.id,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Show a warning toast
 */
toast.warning = (message: string | React.ReactNode, options?: ToastOptions) => {
  return sonnerToast.warning(message, {
    description: options?.description,
    duration: options?.duration,
    action: options?.action
      ? {
          label: options.action.label,
          onClick: options.action.onClick,
        }
      : undefined,
    cancel: options?.cancel,
    id: options?.id,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Show an info toast
 */
toast.info = (message: string | React.ReactNode, options?: ToastOptions) => {
  return sonnerToast.info(message, {
    description: options?.description,
    duration: options?.duration,
    action: options?.action
      ? {
          label: options.action.label,
          onClick: options.action.onClick,
        }
      : undefined,
    cancel: options?.cancel,
    id: options?.id,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Show a loading toast
 */
toast.loading = (message: string | React.ReactNode, options?: ToastOptions) => {
  return sonnerToast.loading(message, {
    description: options?.description,
    duration: options?.duration,
    id: options?.id,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Promise-based toast
 */
toast.promise = <T,>(
  promise: Promise<T>,
  options: PromiseToastOptions<T>
) => {
  return sonnerToast.promise(promise, {
    loading: options.loading,
    success: options.success,
    error: options.error,
    duration: options.duration,
  })
}

/**
 * Update an existing toast
 */
toast.update = (id: string | number, options: ToastOptions) => {
  return sonnerToast(options.description || '', {
    id,
    description: options.description,
    duration: options.duration,
    action: options.action
      ? {
          label: options.action.label,
          onClick: options.action.onClick,
        }
      : undefined,
    cancel: options?.cancel,
    dismissible: options?.dismissible,
    icon: options?.icon,
    className: options?.className,
  })
}

/**
 * Dismiss a toast
 */
toast.dismiss = (id?: string | number) => {
  return sonnerToast.dismiss(id)
}

/**
 * Custom toast with full control
 */
toast.custom = (component: React.ReactNode, options?: ToastOptions) => {
  return sonnerToast.custom(component, {
    duration: options?.duration,
    id: options?.id,
    dismissible: options?.dismissible,
    className: options?.className,
  })
}

export { sonnerToast }
```

---

## 📚 USAGE EXAMPLES

### Setup in Root Layout

```typescript
// app/layout.tsx
import { Toaster } from '@/components/ui/toast'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Toaster />
      </body>
    </html>
  )
}
```

### Basic Toasts

```typescript
import { toast } from '@/components/ui/toast'

function BasicToasts() {
  return (
    <div className="flex gap-2">
      <Button onClick={() => toast('Default toast')}>
        Default
      </Button>
      
      <Button onClick={() => toast.success('Success!')}>
        Success
      </Button>
      
      <Button onClick={() => toast.error('Error occurred')}>
        Error
      </Button>
      
      <Button onClick={() => toast.warning('Warning!')}>
        Warning
      </Button>
      
      <Button onClick={() => toast.info('Info message')}>
        Info
      </Button>
    </div>
  )
}
```

### Toast with Description

```typescript
function ToastWithDescription() {
  return (
    <Button
      onClick={() =>
        toast.success('Changes saved', {
          description: 'Your profile has been updated successfully.',
        })
      }
    >
      Save Changes
    </Button>
  )
}
```

### Toast with Action

```typescript
function ToastWithAction() {
  return (
    <Button
      onClick={() =>
        toast('Event scheduled', {
          description: 'Your meeting is set for tomorrow at 10 AM.',
          action: {
            label: 'View',
            onClick: () => console.log('View clicked'),
          },
        })
      }
    >
      Schedule Event
    </Button>
  )
}
```

### Toast with Cancel

```typescript
function ToastWithCancel() {
  return (
    <Button
      onClick={() =>
        toast('File will be deleted', {
          description: 'This action cannot be undone.',
          action: {
            label: 'Delete',
            onClick: () => console.log('Deleted'),
          },
          cancel: {
            label: 'Cancel',
            onClick: () => console.log('Cancelled'),
          },
        })
      }
    >
      Delete File
    </Button>
  )
}
```

### Loading Toast

```typescript
function LoadingToast() {
  const handleUpload = () => {
    const id = toast.loading('Uploading file...')

    // Simulate upload
    setTimeout(() => {
      toast.success('File uploaded', { id })
    }, 3000)
  }

  return (
    <Button onClick={handleUpload}>
      Upload File
    </Button>
  )
}
```

### Promise-based Toast

```typescript
function PromiseToast() {
  const saveData = async () => {
    await new Promise((resolve) => setTimeout(resolve, 2000))
    return { name: 'John Doe' }
  }

  return (
    <Button
      onClick={() => {
        toast.promise(saveData(), {
          loading: 'Saving...',
          success: (data) => `Saved ${data.name}`,
          error: 'Failed to save',
        })
      }}
    >
      Save Data
    </Button>
  )
}
```

### Update Existing Toast

```typescript
function UpdateToast() {
  const handleProcess = () => {
    const id = toast.loading('Processing...')

    setTimeout(() => {
      toast.update(id, {
        description: 'Step 1 complete',
      })
    }, 1000)

    setTimeout(() => {
      toast.update(id, {
        description: 'Step 2 complete',
      })
    }, 2000)

    setTimeout(() => {
      toast.success('All steps complete!', { id })
    }, 3000)
  }

  return (
    <Button onClick={handleProcess}>
      Start Process
    </Button>
  )
}
```

### Custom Duration

```typescript
function CustomDuration() {
  return (
    <div className="flex gap-2">
      <Button
        onClick={() =>
          toast('Short toast', { duration: 1000 })
        }
      >
        1 second
      </Button>
      
      <Button
        onClick={() =>
          toast('Long toast', { duration: 10000 })
        }
      >
        10 seconds
      </Button>
      
      <Button
        onClick={() =>
          toast('Permanent toast', { duration: Infinity })
        }
      >
        Permanent
      </Button>
    </div>
  )
}
```

### Dismiss Toasts

```typescript
function DismissToasts() {
  return (
    <div className="flex gap-2">
      <Button onClick={() => toast('Toast 1')}>
        Show Toast
      </Button>
      
      <Button onClick={() => toast.dismiss()}>
        Dismiss All
      </Button>
    </div>
  )
}
```

### Custom Toast

```typescript
function CustomToast() {
  return (
    <Button
      onClick={() =>
        toast.custom(
          <div className="flex items-center gap-3 bg-card p-4 rounded-lg shadow-lg">
            <Avatar src="/avatar.jpg" fallback="JD" />
            <div>
              <p className="font-semibold">John Doe</p>
              <p className="text-sm text-muted-foreground">
                Sent you a message
              </p>
            </div>
          </div>
        )
      }
    >
      Custom Toast
    </Button>
  )
}
```

### Form Submission Toast

```typescript
function FormWithToast() {
  const onSubmit = async (data: FormData) => {
    try {
      await saveData(data)
      toast.success('Form submitted', {
        description: 'Your information has been saved.',
      })
    } catch (error) {
      toast.error('Submission failed', {
        description: error.message,
        action: {
          label: 'Retry',
          onClick: () => onSubmit(data),
        },
      })
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {/* Form fields */}
      <Button type="submit">Submit</Button>
    </form>
  )
}
```

### API Request Toast

```typescript
function ApiRequestToast() {
  const deleteUser = async (id: string) => {
    return toast.promise(
      fetch(`/api/users/${id}`, { method: 'DELETE' }),
      {
        loading: 'Deleting user...',
        success: 'User deleted successfully',
        error: 'Failed to delete user',
      }
    )
  }

  return (
    <Button onClick={() => deleteUser('123')}>
      Delete User
    </Button>
  )
}
```

### School Management Toasts

```typescript
function SchoolToasts() {
  const enrollStudent = async () => {
    return toast.promise(
      fetch('/api/students/enroll', { method: 'POST' }),
      {
        loading: 'Enrolling student...',
        success: 'Student enrolled successfully',
        error: 'Enrollment failed',
      }
    )
  }

  const markAttendance = () => {
    toast.success('Attendance marked', {
      description: '32 students present, 3 absent',
      action: {
        label: 'View',
        onClick: () => console.log('View attendance'),
      },
    })
  }

  const submitGrades = () => {
    toast.success('Grades submitted', {
      description: 'All grades have been recorded.',
    })
  }

  return (
    <div className="flex gap-2">
      <Button onClick={enrollStudent}>Enroll Student</Button>
      <Button onClick={markAttendance}>Mark Attendance</Button>
      <Button onClick={submitGrades}>Submit Grades</Button>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Toast', () => {
  beforeEach(() => {
    // Clear all toasts before each test
    toast.dismiss()
  })

  it('shows default toast', () => {
    toast('Test message')
    expect(screen.getByText('Test message')).toBeInTheDocument()
  })

  it('shows success toast', () => {
    toast.success('Success message')
    expect(screen.getByText('Success message')).toBeInTheDocument()
  })

  it('shows error toast', () => {
    toast.error('Error message')
    expect(screen.getByText('Error message')).toBeInTheDocument()
  })

  it('shows toast with description', () => {
    toast('Title', { description: 'Description text' })
    expect(screen.getByText('Title')).toBeInTheDocument()
    expect(screen.getByText('Description text')).toBeInTheDocument()
  })

  it('handles action click', () => {
    const onClick = jest.fn()
    toast('Message', {
      action: { label: 'Click me', onClick },
    })
    fireEvent.click(screen.getByText('Click me'))
    expect(onClick).toHaveBeenCalled()
  })

  it('dismisses toast', async () => {
    toast('Test')
    expect(screen.getByText('Test')).toBeInTheDocument()
    
    toast.dismiss()
    
    await waitFor(() => {
      expect(screen.queryByText('Test')).not.toBeInTheDocument()
    })
  })

  it('handles promise toast', async () => {
    const promise = Promise.resolve('data')
    
    toast.promise(promise, {
      loading: 'Loading...',
      success: 'Success!',
      error: 'Error!',
    })

    expect(screen.getByText('Loading...')).toBeInTheDocument()

    await waitFor(() => {
      expect(screen.getByText('Success!')).toBeInTheDocument()
    })
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ ARIA live region for screen readers
- ✅ Keyboard dismissible (ESC key)
- ✅ Focus management
- ✅ Role="status" for announcements
- ✅ Semantic HTML
- ✅ Color contrast compliance

---

## 🎨 STYLING NOTES

### Position Options
- `top-left`, `top-center`, `top-right`
- `bottom-left`, `bottom-center`, `bottom-right`

### Rich Colors
Enable `richColors` for colored backgrounds based on variant.

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Sonner: `npm install sonner`
- [ ] Create toast.tsx
- [ ] Add Toaster to root layout
- [ ] Implement toast functions (success, error, warning, info, loading)
- [ ] Add promise-based toast support
- [ ] Add toast update functionality
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Sonner**: ~4KB
- **Component wrapper**: ~1KB
- **Total**: ~5KB

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
