# SPEC-067: Modal/Dialog Component
## Accessible Modal Dialog with Radix UI

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Dependencies**: Radix UI Dialog

---

## 📋 OVERVIEW

### Purpose
A modal dialog component built on Radix UI Dialog that displays content in a layer above the main application, blocking interaction with the underlying content until dismissed.

### Key Features
- ✅ Radix UI Dialog primitives
- ✅ Multiple size options
- ✅ Position variants (center, top, bottom)
- ✅ Overlay backdrop with blur
- ✅ Focus trap and restoration
- ✅ Keyboard navigation (Esc to close)
- ✅ Portal rendering
- ✅ Smooth animations
- ✅ Scroll lock
- ✅ Custom close button
- ✅ Nested modals support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/modal.tsx
'use client'

import * as React from 'react'
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// VARIANT DEFINITIONS
// ========================================

const modalVariants = cva(
  'fixed z-50 gap-4 bg-background p-6 shadow-lg transition ease-in-out data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:duration-500',
  {
    variants: {
      size: {
        sm: 'max-w-sm',
        md: 'max-w-md',
        lg: 'max-w-lg',
        xl: 'max-w-xl',
        '2xl': 'max-w-2xl',
        '3xl': 'max-w-3xl',
        '4xl': 'max-w-4xl',
        full: 'max-w-full w-full h-full',
      },
      position: {
        center: 'left-[50%] top-[50%] translate-x-[-50%] translate-y-[-50%] rounded-lg',
        top: 'inset-x-0 top-0 rounded-b-lg data-[state=closed]:slide-out-to-top data-[state=open]:slide-in-from-top',
        bottom: 'inset-x-0 bottom-0 rounded-t-lg data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom',
      },
    },
    defaultVariants: {
      size: 'md',
      position: 'center',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ModalProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Root>,
    VariantProps<typeof modalVariants> {
  /**
   * Whether the modal is open
   */
  open?: boolean

  /**
   * Callback when modal open state changes
   */
  onOpenChange?: (open: boolean) => void

  /**
   * Modal content
   */
  children: React.ReactNode
}

export interface ModalContentProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content>,
    VariantProps<typeof modalVariants> {
  /**
   * Show close button
   */
  showClose?: boolean

  /**
   * Close on overlay click
   */
  closeOnOverlay?: boolean

  /**
   * Close on escape key
   */
  closeOnEscape?: boolean

  /**
   * Additional overlay classes
   */
  overlayClassName?: string
}

export interface ModalHeaderProps
  extends React.HTMLAttributes<HTMLDivElement> {}

export interface ModalTitleProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Title> {}

export interface ModalDescriptionProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Description> {}

export interface ModalFooterProps
  extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Footer layout
   */
  justify?: 'start' | 'center' | 'end' | 'between'
}

// ========================================
// MODAL ROOT
// ========================================

/**
 * Modal Component
 * 
 * Root modal component that manages open state.
 * 
 * @example
 * <Modal open={isOpen} onOpenChange={setIsOpen}>
 *   <ModalContent>
 *     <ModalHeader>
 *       <ModalTitle>Modal Title</ModalTitle>
 *     </ModalHeader>
 *   </ModalContent>
 * </Modal>
 */
const Modal = DialogPrimitive.Root

// ========================================
// MODAL TRIGGER
// ========================================

/**
 * ModalTrigger Component
 * 
 * Button that opens the modal.
 */
const ModalTrigger = DialogPrimitive.Trigger

// ========================================
// MODAL PORTAL
// ========================================

/**
 * ModalPortal Component
 * 
 * Portal for rendering modal outside of DOM hierarchy.
 */
const ModalPortal = DialogPrimitive.Portal

// ========================================
// MODAL OVERLAY
// ========================================

/**
 * ModalOverlay Component
 * 
 * Semi-transparent backdrop behind the modal.
 */
const ModalOverlay = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Overlay>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Overlay>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Overlay
    ref={ref}
    className={cn(
      'fixed inset-0 z-50 bg-background/80 backdrop-blur-sm',
      'data-[state=open]:animate-in data-[state=closed]:animate-out',
      'data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
      className
    )}
    {...props}
  />
))
ModalOverlay.displayName = DialogPrimitive.Overlay.displayName

// ========================================
// MODAL CONTENT
// ========================================

/**
 * ModalContent Component
 * 
 * Main content container for the modal.
 */
const ModalContent = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Content>,
  ModalContentProps
>(
  (
    {
      className,
      children,
      size,
      position,
      showClose = true,
      closeOnOverlay = true,
      closeOnEscape = true,
      overlayClassName,
      ...props
    },
    ref
  ) => (
    <ModalPortal>
      <ModalOverlay className={overlayClassName} />
      <DialogPrimitive.Content
        ref={ref}
        className={cn(modalVariants({ size, position }), className)}
        onPointerDownOutside={
          !closeOnOverlay ? (e) => e.preventDefault() : undefined
        }
        onEscapeKeyDown={
          !closeOnEscape ? (e) => e.preventDefault() : undefined
        }
        {...props}
      >
        {children}
        {showClose && (
          <DialogPrimitive.Close className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground">
            <X className="h-4 w-4" />
            <span className="sr-only">Close</span>
          </DialogPrimitive.Close>
        )}
      </DialogPrimitive.Content>
    </ModalPortal>
  )
)
ModalContent.displayName = DialogPrimitive.Content.displayName

// ========================================
// MODAL HEADER
// ========================================

/**
 * ModalHeader Component
 * 
 * Header section of the modal.
 */
const ModalHeader = React.forwardRef<HTMLDivElement, ModalHeaderProps>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn('flex flex-col space-y-1.5 text-center sm:text-left', className)}
      {...props}
    />
  )
)
ModalHeader.displayName = 'ModalHeader'

// ========================================
// MODAL TITLE
// ========================================

/**
 * ModalTitle Component
 * 
 * Title of the modal.
 */
const ModalTitle = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Title>,
  ModalTitleProps
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Title
    ref={ref}
    className={cn('text-lg font-semibold leading-none tracking-tight', className)}
    {...props}
  />
))
ModalTitle.displayName = DialogPrimitive.Title.displayName

// ========================================
// MODAL DESCRIPTION
// ========================================

/**
 * ModalDescription Component
 * 
 * Description text for the modal.
 */
const ModalDescription = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Description>,
  ModalDescriptionProps
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Description
    ref={ref}
    className={cn('text-sm text-muted-foreground', className)}
    {...props}
  />
))
ModalDescription.displayName = DialogPrimitive.Description.displayName

// ========================================
// MODAL BODY
// ========================================

export interface ModalBodyProps extends React.HTMLAttributes<HTMLDivElement> {}

/**
 * ModalBody Component
 * 
 * Main content area of the modal.
 */
const ModalBody = React.forwardRef<HTMLDivElement, ModalBodyProps>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('py-4', className)} {...props} />
  )
)
ModalBody.displayName = 'ModalBody'

// ========================================
// MODAL FOOTER
// ========================================

const footerJustifyMap = {
  start: 'justify-start',
  center: 'justify-center',
  end: 'justify-end',
  between: 'justify-between',
}

/**
 * ModalFooter Component
 * 
 * Footer section for actions.
 */
const ModalFooter = React.forwardRef<HTMLDivElement, ModalFooterProps>(
  ({ className, justify = 'end', ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        'flex items-center gap-2',
        footerJustifyMap[justify],
        className
      )}
      {...props}
    />
  )
)
ModalFooter.displayName = 'ModalFooter'

// ========================================
// MODAL CLOSE
// ========================================

/**
 * ModalClose Component
 * 
 * Button to close the modal programmatically.
 */
const ModalClose = DialogPrimitive.Close

// ========================================
// EXPORTS
// ========================================

export {
  Modal,
  ModalTrigger,
  ModalContent,
  ModalHeader,
  ModalTitle,
  ModalDescription,
  ModalBody,
  ModalFooter,
  ModalClose,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Modal

```typescript
import {
  Modal,
  ModalContent,
  ModalHeader,
  ModalTitle,
  ModalDescription,
  ModalBody,
  ModalFooter,
  ModalClose,
} from '@/components/ui/modal'
import { Button } from '@/components/ui/button'

function BasicModal() {
  const [open, setOpen] = React.useState(false)

  return (
    <Modal open={open} onOpenChange={setOpen}>
      <ModalTrigger asChild>
        <Button>Open Modal</Button>
      </ModalTrigger>
      <ModalContent>
        <ModalHeader>
          <ModalTitle>Modal Title</ModalTitle>
          <ModalDescription>
            This is a description of the modal content.
          </ModalDescription>
        </ModalHeader>
        <ModalBody>
          <p>Modal content goes here.</p>
        </ModalBody>
        <ModalFooter>
          <ModalClose asChild>
            <Button variant="outline">Cancel</Button>
          </ModalClose>
          <Button>Confirm</Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}
```

### Different Sizes

```typescript
function ModalSizes() {
  const [size, setSize] = React.useState<'sm' | 'md' | 'lg' | 'xl'>('md')
  const [open, setOpen] = React.useState(false)

  return (
    <>
      <div className="flex gap-2">
        <Button onClick={() => { setSize('sm'); setOpen(true) }}>Small</Button>
        <Button onClick={() => { setSize('md'); setOpen(true) }}>Medium</Button>
        <Button onClick={() => { setSize('lg'); setOpen(true) }}>Large</Button>
        <Button onClick={() => { setSize('xl'); setOpen(true) }}>Extra Large</Button>
      </div>

      <Modal open={open} onOpenChange={setOpen}>
        <ModalContent size={size}>
          <ModalHeader>
            <ModalTitle>{size.toUpperCase()} Modal</ModalTitle>
          </ModalHeader>
          <ModalBody>
            <p>This is a {size} sized modal.</p>
          </ModalBody>
        </ModalContent>
      </Modal>
    </>
  )
}
```

### Position Variants

```typescript
function PositionedModals() {
  return (
    <>
      {/* Center Modal (Default) */}
      <Modal>
        <ModalTrigger asChild>
          <Button>Center Modal</Button>
        </ModalTrigger>
        <ModalContent position="center">
          <ModalHeader>
            <ModalTitle>Centered Modal</ModalTitle>
          </ModalHeader>
          <ModalBody>Content appears in the center of the screen.</ModalBody>
        </ModalContent>
      </Modal>

      {/* Top Modal */}
      <Modal>
        <ModalTrigger asChild>
          <Button>Top Modal</Button>
        </ModalTrigger>
        <ModalContent position="top">
          <ModalHeader>
            <ModalTitle>Top Modal</ModalTitle>
          </ModalHeader>
          <ModalBody>Content slides from the top.</ModalBody>
        </ModalContent>
      </Modal>

      {/* Bottom Modal */}
      <Modal>
        <ModalTrigger asChild>
          <Button>Bottom Modal</Button>
        </ModalTrigger>
        <ModalContent position="bottom">
          <ModalHeader>
            <ModalTitle>Bottom Modal</ModalTitle>
          </ModalHeader>
          <ModalBody>Content slides from the bottom.</ModalBody>
        </ModalContent>
      </Modal>
    </>
  )
}
```

### Form in Modal

```typescript
import { FormField } from '@/components/ui/form-field'
import { Form } from '@/components/ui/form'
import { useForm } from 'react-hook-form'
import { z } from 'zod'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
})

function FormModal() {
  const [open, setOpen] = React.useState(false)
  const form = useForm({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: any) => {
    console.log(data)
    setOpen(false)
  }

  return (
    <Modal open={open} onOpenChange={setOpen}>
      <ModalTrigger asChild>
        <Button>Add User</Button>
      </ModalTrigger>
      <ModalContent>
        <Form form={form} onSubmit={onSubmit}>
          <ModalHeader>
            <ModalTitle>Add New User</ModalTitle>
            <ModalDescription>
              Enter the user details below.
            </ModalDescription>
          </ModalHeader>
          <ModalBody className="space-y-4">
            <FormField name="name" label="Name" required />
            <FormField name="email" type="email" label="Email" required />
          </ModalBody>
          <ModalFooter>
            <ModalClose asChild>
              <Button type="button" variant="outline">Cancel</Button>
            </ModalClose>
            <Button type="submit">Save</Button>
          </ModalFooter>
        </Form>
      </ModalContent>
    </Modal>
  )
}
```

### Confirmation Modal

```typescript
function DeleteConfirmation() {
  const [open, setOpen] = React.useState(false)
  const [isDeleting, setIsDeleting] = React.useState(false)

  const handleDelete = async () => {
    setIsDeleting(true)
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000))
    setIsDeleting(false)
    setOpen(false)
  }

  return (
    <Modal open={open} onOpenChange={setOpen}>
      <ModalTrigger asChild>
        <Button variant="destructive">Delete Account</Button>
      </ModalTrigger>
      <ModalContent size="sm" closeOnOverlay={false}>
        <ModalHeader>
          <ModalTitle>Are you sure?</ModalTitle>
          <ModalDescription>
            This action cannot be undone. This will permanently delete your account.
          </ModalDescription>
        </ModalHeader>
        <ModalFooter>
          <ModalClose asChild>
            <Button variant="outline" disabled={isDeleting}>
              Cancel
            </Button>
          </ModalClose>
          <Button
            variant="destructive"
            onClick={handleDelete}
            disabled={isDeleting}
          >
            {isDeleting ? 'Deleting...' : 'Delete'}
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}
```

### Scrollable Content

```typescript
function ScrollableModal() {
  return (
    <Modal>
      <ModalTrigger asChild>
        <Button>Long Content</Button>
      </ModalTrigger>
      <ModalContent size="lg">
        <ModalHeader>
          <ModalTitle>Terms and Conditions</ModalTitle>
        </ModalHeader>
        <ModalBody className="max-h-[60vh] overflow-y-auto">
          <div className="space-y-4 pr-4">
            {Array.from({ length: 20 }).map((_, i) => (
              <p key={i}>
                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
              </p>
            ))}
          </div>
        </ModalBody>
        <ModalFooter>
          <ModalClose asChild>
            <Button>I Agree</Button>
          </ModalClose>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}
```

---

## 🧪 TESTING

```typescript
// src/components/ui/__tests__/modal.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { Modal, ModalTrigger, ModalContent, ModalTitle } from '../modal'

describe('Modal', () => {
  it('opens modal when trigger is clicked', () => {
    render(
      <Modal>
        <ModalTrigger>Open</ModalTrigger>
        <ModalContent>
          <ModalTitle>Test Modal</ModalTitle>
        </ModalContent>
      </Modal>
    )

    fireEvent.click(screen.getByText('Open'))
    expect(screen.getByText('Test Modal')).toBeInTheDocument()
  })

  it('closes modal on escape key', async () => {
    render(
      <Modal defaultOpen>
        <ModalContent closeOnEscape>
          <ModalTitle>Test Modal</ModalTitle>
        </ModalContent>
      </Modal>
    )

    fireEvent.keyDown(document, { key: 'Escape' })
    await waitFor(() => {
      expect(screen.queryByText('Test Modal')).not.toBeInTheDocument()
    })
  })

  it('prevents closing on overlay click when specified', () => {
    render(
      <Modal defaultOpen>
        <ModalContent closeOnOverlay={false}>
          <ModalTitle>Test Modal</ModalTitle>
        </ModalContent>
      </Modal>
    )

    const overlay = document.querySelector('[data-radix-dialog-overlay]')
    if (overlay) fireEvent.click(overlay)
    
    expect(screen.getByText('Test Modal')).toBeInTheDocument()
  })

  it('applies size variants', () => {
    const { container } = render(
      <Modal defaultOpen>
        <ModalContent size="lg">
          <ModalTitle>Large Modal</ModalTitle>
        </ModalContent>
      </Modal>
    )

    const content = container.querySelector('[role="dialog"]')
    expect(content).toHaveClass('max-w-lg')
  })
})
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Focus trap within modal
- ✅ Focus restoration on close
- ✅ Escape key to close
- ✅ ARIA labels and roles
- ✅ Keyboard navigation
- ✅ Screen reader announcements

### Best Practices
- Always provide ModalTitle for screen readers
- Use ModalDescription for context
- Ensure focusable elements are keyboard accessible
- Test with screen readers

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-dialog
- [ ] Create modal.tsx file
- [ ] Implement Modal root component
- [ ] Implement ModalTrigger
- [ ] Implement ModalContent with variants
- [ ] Implement ModalOverlay
- [ ] Implement ModalHeader/Title/Description
- [ ] Implement ModalBody
- [ ] Implement ModalFooter
- [ ] Implement ModalClose
- [ ] Add size and position variants
- [ ] Add focus management
- [ ] Add keyboard support
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
