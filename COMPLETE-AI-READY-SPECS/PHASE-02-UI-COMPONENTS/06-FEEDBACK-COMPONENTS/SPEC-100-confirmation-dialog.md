# SPEC-100: Confirmation Dialog Component
## User Confirmation Prompts

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: Radix UI Dialog

---

## 📋 OVERVIEW

### Purpose
A confirmation dialog component for prompting users to confirm destructive or important actions before proceeding.

### Key Features
- ✅ Radix UI Dialog integration
- ✅ Multiple variants (default, danger, warning)
- ✅ Async action support
- ✅ Loading states
- ✅ Custom content
- ✅ Keyboard shortcuts
- ✅ Focus management
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/confirmation-dialog.tsx
import * as React from 'react'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'
import { Button } from '@/components/ui/button'
import { LoadingSpinner } from '@/components/ui/loading-spinner'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ConfirmationDialogProps {
  /**
   * Controlled open state
   */
  open?: boolean

  /**
   * On open change callback
   */
  onOpenChange?: (open: boolean) => void

  /**
   * Trigger element
   */
  trigger?: React.ReactNode

  /**
   * Dialog title
   */
  title: string

  /**
   * Dialog description
   */
  description: string | React.ReactNode

  /**
   * Confirm button text
   */
  confirmText?: string

  /**
   * Cancel button text
   */
  cancelText?: string

  /**
   * On confirm callback (can be async)
   */
  onConfirm: () => void | Promise<void>

  /**
   * On cancel callback
   */
  onCancel?: () => void

  /**
   * Variant
   */
  variant?: 'default' | 'danger' | 'warning'

  /**
   * Disable confirm button
   */
  disabled?: boolean

  /**
   * Show loading state during async operation
   */
  loading?: boolean
}

// ========================================
// CONFIRMATION DIALOG COMPONENT
// ========================================

/**
 * Confirmation Dialog Component
 * 
 * Used to confirm destructive or important actions.
 */
export function ConfirmationDialog({
  open,
  onOpenChange,
  trigger,
  title,
  description,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  onConfirm,
  onCancel,
  variant = 'default',
  disabled = false,
  loading: externalLoading = false,
}: ConfirmationDialogProps) {
  const [internalLoading, setInternalLoading] = React.useState(false)
  const loading = externalLoading || internalLoading

  const handleConfirm = async () => {
    try {
      setInternalLoading(true)
      await onConfirm()
      onOpenChange?.(false)
    } catch (error) {
      console.error('Confirmation action failed:', error)
    } finally {
      setInternalLoading(false)
    }
  }

  const handleCancel = () => {
    onCancel?.()
    onOpenChange?.(false)
  }

  const confirmButtonVariant = variant === 'danger' ? 'destructive' : 'default'

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      {trigger && <AlertDialogTrigger asChild>{trigger}</AlertDialogTrigger>}
      
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          <AlertDialogDescription>{description}</AlertDialogDescription>
        </AlertDialogHeader>
        
        <AlertDialogFooter>
          <AlertDialogCancel onClick={handleCancel} disabled={loading}>
            {cancelText}
          </AlertDialogCancel>
          <Button
            variant={confirmButtonVariant}
            onClick={handleConfirm}
            disabled={disabled || loading}
          >
            {loading && <LoadingSpinner size="sm" className="mr-2" />}
            {confirmText}
          </Button>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

// ========================================
// USE CONFIRMATION HOOK
// ========================================

export interface UseConfirmationOptions {
  title: string
  description: string | React.ReactNode
  confirmText?: string
  cancelText?: string
  variant?: 'default' | 'danger' | 'warning'
}

export interface UseConfirmationReturn {
  confirm: (action: () => void | Promise<void>) => void
  ConfirmationDialog: () => React.ReactElement | null
}

/**
 * Use Confirmation Hook
 * 
 * Programmatic way to show confirmation dialogs.
 */
export function useConfirmation(
  options: UseConfirmationOptions
): UseConfirmationReturn {
  const [open, setOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(false)
  const actionRef = React.useRef<(() => void | Promise<void>) | null>(null)

  const confirm = (action: () => void | Promise<void>) => {
    actionRef.current = action
    setOpen(true)
  }

  const handleConfirm = async () => {
    if (!actionRef.current) return

    try {
      setLoading(true)
      await actionRef.current()
      setOpen(false)
    } catch (error) {
      console.error('Confirmation action failed:', error)
    } finally {
      setLoading(false)
    }
  }

  const DialogComponent = () => {
    if (!open) return null

    return (
      <ConfirmationDialog
        open={open}
        onOpenChange={setOpen}
        title={options.title}
        description={options.description}
        confirmText={options.confirmText}
        cancelText={options.cancelText}
        variant={options.variant}
        onConfirm={handleConfirm}
        loading={loading}
      />
    )
  }

  return {
    confirm,
    ConfirmationDialog: DialogComponent,
  }
}
```

---

## 📚 USAGE EXAMPLES

### Basic Confirmation Dialog

```typescript
import { ConfirmationDialog } from '@/components/ui/confirmation-dialog'

function DeleteButton() {
  const [open, setOpen] = React.useState(false)

  const handleDelete = async () => {
    await deleteItem()
    toast.success('Item deleted')
  }

  return (
    <ConfirmationDialog
      open={open}
      onOpenChange={setOpen}
      trigger={<Button variant="destructive">Delete</Button>}
      title="Delete Item"
      description="Are you sure you want to delete this item? This action cannot be undone."
      confirmText="Delete"
      cancelText="Cancel"
      variant="danger"
      onConfirm={handleDelete}
    />
  )
}
```

### Using the Hook

```typescript
import { useConfirmation } from '@/components/ui/confirmation-dialog'

function UserList() {
  const { confirm, ConfirmationDialog } = useConfirmation({
    title: 'Delete User',
    description: 'Are you sure you want to delete this user? This action cannot be undone.',
    confirmText: 'Delete',
    variant: 'danger',
  })

  const handleDelete = (userId: string) => {
    confirm(async () => {
      await deleteUser(userId)
      toast.success('User deleted')
    })
  }

  return (
    <>
      <ConfirmationDialog />
      {users.map((user) => (
        <div key={user.id}>
          <span>{user.name}</span>
          <Button onClick={() => handleDelete(user.id)}>Delete</Button>
        </div>
      ))}
    </>
  )
}
```

### Warning Dialog

```typescript
function UnsavedChangesDialog({ onLeave }: { onLeave: () => void }) {
  return (
    <ConfirmationDialog
      trigger={<Button variant="outline">Leave Page</Button>}
      title="Unsaved Changes"
      description="You have unsaved changes. Are you sure you want to leave? Your changes will be lost."
      confirmText="Leave"
      cancelText="Stay"
      variant="warning"
      onConfirm={onLeave}
    />
  )
}
```

### Async Confirmation

```typescript
function PublishArticle() {
  const [open, setOpen] = React.useState(false)

  const handlePublish = async () => {
    // This will show loading state automatically
    await publishArticle()
    await refreshData()
    toast.success('Article published')
  }

  return (
    <ConfirmationDialog
      open={open}
      onOpenChange={setOpen}
      trigger={<Button>Publish</Button>}
      title="Publish Article"
      description="Are you sure you want to publish this article? It will be visible to all users."
      confirmText="Publish"
      onConfirm={handlePublish}
    />
  )
}
```

### Custom Content

```typescript
function CustomConfirmation() {
  return (
    <ConfirmationDialog
      trigger={<Button variant="destructive">Delete Account</Button>}
      title="Delete Account"
      description={
        <div className="space-y-3">
          <p>This action is permanent and cannot be undone.</p>
          <p className="font-semibold">This will delete:</p>
          <ul className="list-disc list-inside space-y-1">
            <li>All your data and files</li>
            <li>Your subscription</li>
            <li>All team members</li>
          </ul>
        </div>
      }
      confirmText="Delete Account"
      variant="danger"
      onConfirm={async () => {
        await deleteAccount()
      }}
    />
  )
}
```

### Controlled Dialog

```typescript
function ControlledConfirmation() {
  const [open, setOpen] = React.useState(false)
  const [item, setItem] = React.useState<Item | null>(null)

  const openConfirmation = (itemToDelete: Item) => {
    setItem(itemToDelete)
    setOpen(true)
  }

  return (
    <>
      <ConfirmationDialog
        open={open}
        onOpenChange={setOpen}
        title="Delete Item"
        description={`Are you sure you want to delete "${item?.name}"?`}
        onConfirm={async () => {
          if (item) await deleteItem(item.id)
        }}
      />
      
      {items.map((item) => (
        <Button key={item.id} onClick={() => openConfirmation(item)}>
          Delete {item.name}
        </Button>
      ))}
    </>
  )
}
```

### School Management Confirmations

```typescript
function SchoolConfirmations() {
  const { confirm: confirmDelete, ConfirmationDialog: DeleteDialog } =
    useConfirmation({
      title: 'Delete Student',
      description: 'Are you sure you want to remove this student? All associated records will be archived.',
      confirmText: 'Delete',
      variant: 'danger',
    })

  const { confirm: confirmGrade, ConfirmationDialog: GradeDialog } =
    useConfirmation({
      title: 'Submit Grades',
      description: 'Are you sure you want to submit grades? Students and parents will be notified immediately.',
      confirmText: 'Submit',
      variant: 'default',
    })

  const { confirm: confirmExpel, ConfirmationDialog: ExpelDialog } =
    useConfirmation({
      title: 'Expel Student',
      description: 'This is a serious action. Are you sure you want to expel this student? This requires administrator approval.',
      confirmText: 'Proceed',
      variant: 'danger',
    })

  const deleteStudent = (id: string) => {
    confirmDelete(async () => {
      await api.deleteStudent(id)
      toast.success('Student removed')
    })
  }

  const submitGrades = () => {
    confirmGrade(async () => {
      await api.submitGrades()
      toast.success('Grades submitted')
    })
  }

  return (
    <>
      <DeleteDialog />
      <GradeDialog />
      <ExpelDialog />
      {/* UI */}
    </>
  )
}
```

### With Checkbox Confirmation

```typescript
function CheckboxConfirmation() {
  const [understood, setUnderstood] = React.useState(false)

  return (
    <ConfirmationDialog
      trigger={<Button variant="destructive">Delete All</Button>}
      title="Delete All Data"
      description={
        <div className="space-y-4">
          <p>This will permanently delete all data.</p>
          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              id="understand"
              checked={understood}
              onChange={(e) => setUnderstood(e.target.checked)}
            />
            <label htmlFor="understand">
              I understand this action cannot be undone
            </label>
          </div>
        </div>
      }
      confirmText="Delete All"
      variant="danger"
      disabled={!understood}
      onConfirm={async () => {
        await deleteAllData()
      }}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('ConfirmationDialog', () => {
  it('renders trigger button', () => {
    render(
      <ConfirmationDialog
        trigger={<button>Delete</button>}
        title="Confirm"
        description="Are you sure?"
        onConfirm={jest.fn()}
      />
    )
    expect(screen.getByText('Delete')).toBeInTheDocument()
  })

  it('opens dialog on trigger click', async () => {
    render(
      <ConfirmationDialog
        trigger={<button>Delete</button>}
        title="Confirm Delete"
        description="Are you sure?"
        onConfirm={jest.fn()}
      />
    )

    fireEvent.click(screen.getByText('Delete'))

    await waitFor(() => {
      expect(screen.getByText('Confirm Delete')).toBeInTheDocument()
      expect(screen.getByText('Are you sure?')).toBeInTheDocument()
    })
  })

  it('calls onConfirm when confirmed', async () => {
    const onConfirm = jest.fn()
    
    render(
      <ConfirmationDialog
        open={true}
        title="Confirm"
        description="Are you sure?"
        onConfirm={onConfirm}
      />
    )

    fireEvent.click(screen.getByText('Confirm'))

    await waitFor(() => {
      expect(onConfirm).toHaveBeenCalled()
    })
  })

  it('calls onCancel when cancelled', async () => {
    const onCancel = jest.fn()
    
    render(
      <ConfirmationDialog
        open={true}
        title="Confirm"
        description="Are you sure?"
        onConfirm={jest.fn()}
        onCancel={onCancel}
      />
    )

    fireEvent.click(screen.getByText('Cancel'))

    await waitFor(() => {
      expect(onCancel).toHaveBeenCalled()
    })
  })

  it('shows loading state during async operation', async () => {
    const onConfirm = jest.fn(
      () => new Promise((resolve) => setTimeout(resolve, 100))
    )
    
    render(
      <ConfirmationDialog
        open={true}
        title="Confirm"
        description="Are you sure?"
        onConfirm={onConfirm}
      />
    )

    fireEvent.click(screen.getByText('Confirm'))

    await waitFor(() => {
      expect(document.querySelector('.animate-spin')).toBeInTheDocument()
    })
  })

  it('disables buttons when loading', async () => {
    render(
      <ConfirmationDialog
        open={true}
        title="Confirm"
        description="Are you sure?"
        onConfirm={jest.fn()}
        loading={true}
      />
    )

    expect(screen.getByText('Confirm')).toBeDisabled()
    expect(screen.getByText('Cancel')).toBeDisabled()
  })

  it('applies danger variant styles', () => {
    render(
      <ConfirmationDialog
        open={true}
        title="Delete"
        description="Are you sure?"
        onConfirm={jest.fn()}
        variant="danger"
      />
    )

    const confirmButton = screen.getByText('Confirm')
    expect(confirmButton).toHaveClass('destructive')
  })
})

describe('useConfirmation', () => {
  it('shows dialog when confirm is called', async () => {
    function TestComponent() {
      const { confirm, ConfirmationDialog } = useConfirmation({
        title: 'Test',
        description: 'Test description',
      })

      return (
        <>
          <ConfirmationDialog />
          <button onClick={() => confirm(() => {})}>Show</button>
        </>
      )
    }

    render(<TestComponent />)

    fireEvent.click(screen.getByText('Show'))

    await waitFor(() => {
      expect(screen.getByText('Test')).toBeInTheDocument()
    })
  })

  it('executes action on confirm', async () => {
    const action = jest.fn()
    
    function TestComponent() {
      const { confirm, ConfirmationDialog } = useConfirmation({
        title: 'Test',
        description: 'Test',
      })

      return (
        <>
          <ConfirmationDialog />
          <button onClick={() => confirm(action)}>Show</button>
        </>
      )
    }

    render(<TestComponent />)

    fireEvent.click(screen.getByText('Show'))

    await waitFor(() => {
      expect(screen.getByText('Test')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByText('Confirm'))

    await waitFor(() => {
      expect(action).toHaveBeenCalled()
    })
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Radix UI Dialog for full accessibility
- ✅ Focus trap within dialog
- ✅ ESC key to close
- ✅ Focus management
- ✅ ARIA labels and roles
- ✅ Keyboard navigation

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Radix UI Dialog: `npm install @radix-ui/react-alert-dialog`
- [ ] Create confirmation-dialog.tsx
- [ ] Implement ConfirmationDialog component
- [ ] Add async action support
- [ ] Add loading states
- [ ] Implement useConfirmation hook
- [ ] Add variant support (default, danger, warning)
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With Radix UI**: ~5KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
