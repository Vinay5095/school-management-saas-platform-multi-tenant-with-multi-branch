# SPEC-068: Drawer Component
## Slide-out Panel with Radix UI Sheet

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5 hours  
> **Dependencies**: Radix UI Dialog (Sheet)

---

## 📋 OVERVIEW

### Purpose
A drawer (slide-out panel) component that slides in from the edge of the screen. Commonly used for navigation menus, filters, or additional content without leaving the current page.

### Key Features
- ✅ Slide from all four directions
- ✅ Customizable size
- ✅ Overlay backdrop
- ✅ Focus management
- ✅ Keyboard navigation
- ✅ Smooth animations
- ✅ Nested content support
- ✅ Mobile responsive
- ✅ Portal rendering
- ✅ Scroll lock

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/drawer.tsx
'use client'

import * as React from 'react'
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// VARIANT DEFINITIONS
// ========================================

const drawerVariants = cva(
  'fixed z-50 bg-background shadow-lg transition ease-in-out data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:duration-500',
  {
    variants: {
      side: {
        left: 'inset-y-0 left-0 h-full w-3/4 border-r data-[state=closed]:slide-out-to-left data-[state=open]:slide-in-from-left sm:max-w-sm',
        right: 'inset-y-0 right-0 h-full w-3/4 border-l data-[state=closed]:slide-out-to-right data-[state=open]:slide-in-from-right sm:max-w-sm',
        top: 'inset-x-0 top-0 border-b data-[state=closed]:slide-out-to-top data-[state=open]:slide-in-from-top',
        bottom: 'inset-x-0 bottom-0 border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom',
      },
    },
    defaultVariants: {
      side: 'right',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface DrawerProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Root> {
  /**
   * Whether the drawer is open
   */
  open?: boolean

  /**
   * Callback when drawer open state changes
   */
  onOpenChange?: (open: boolean) => void

  /**
   * Drawer content
   */
  children: React.ReactNode
}

export interface DrawerContentProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content>,
    VariantProps<typeof drawerVariants> {
  /**
   * Show close button
   */
  showClose?: boolean

  /**
   * Close on overlay click
   */
  closeOnOverlay?: boolean

  /**
   * Custom width/height
   */
  size?: string | number

  /**
   * Overlay opacity
   */
  overlayOpacity?: number
}

// ========================================
// DRAWER ROOT
// ========================================

/**
 * Drawer Component
 * 
 * Root drawer component that manages open state.
 * 
 * @example
 * <Drawer open={isOpen} onOpenChange={setIsOpen}>
 *   <DrawerContent>
 *     <DrawerHeader>
 *       <DrawerTitle>Drawer Title</DrawerTitle>
 *     </DrawerHeader>
 *   </DrawerContent>
 * </Drawer>
 */
const Drawer = DialogPrimitive.Root

// ========================================
// DRAWER TRIGGER
// ========================================

/**
 * DrawerTrigger Component
 * 
 * Button that opens the drawer.
 */
const DrawerTrigger = DialogPrimitive.Trigger

// ========================================
// DRAWER PORTAL
// ========================================

const DrawerPortal = DialogPrimitive.Portal

// ========================================
// DRAWER OVERLAY
// ========================================

/**
 * DrawerOverlay Component
 * 
 * Backdrop behind the drawer.
 */
const DrawerOverlay = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Overlay>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Overlay> & {
    opacity?: number
  }
>(({ className, opacity = 80, ...props }, ref) => (
  <DialogPrimitive.Overlay
    ref={ref}
    className={cn(
      'fixed inset-0 z-50 backdrop-blur-sm',
      'data-[state=open]:animate-in data-[state=closed]:animate-out',
      'data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
      className
    )}
    style={{
      backgroundColor: `rgba(0, 0, 0, ${opacity / 100})`,
    }}
    {...props}
  />
))
DrawerOverlay.displayName = DialogPrimitive.Overlay.displayName

// ========================================
// DRAWER CONTENT
// ========================================

/**
 * DrawerContent Component
 * 
 * Main content container for the drawer.
 */
const DrawerContent = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Content>,
  DrawerContentProps
>(
  (
    {
      side = 'right',
      className,
      children,
      showClose = true,
      closeOnOverlay = true,
      size,
      overlayOpacity,
      ...props
    },
    ref
  ) => {
    const sizeStyle = React.useMemo(() => {
      if (!size) return {}
      
      if (side === 'left' || side === 'right') {
        return { width: typeof size === 'number' ? `${size}px` : size, maxWidth: '100%' }
      }
      return { height: typeof size === 'number' ? `${size}px` : size }
    }, [size, side])

    return (
      <DrawerPortal>
        <DrawerOverlay opacity={overlayOpacity} />
        <DialogPrimitive.Content
          ref={ref}
          className={cn(drawerVariants({ side }), className)}
          style={sizeStyle}
          onPointerDownOutside={
            !closeOnOverlay ? (e) => e.preventDefault() : undefined
          }
          {...props}
        >
          {children}
          {showClose && (
            <DialogPrimitive.Close className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none">
              <X className="h-4 w-4" />
              <span className="sr-only">Close</span>
            </DialogPrimitive.Close>
          )}
        </DialogPrimitive.Content>
      </DrawerPortal>
    )
  }
)
DrawerContent.displayName = 'DrawerContent'

// ========================================
// DRAWER HEADER
// ========================================

/**
 * DrawerHeader Component
 */
const DrawerHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex flex-col space-y-2 text-center sm:text-left p-6', className)}
    {...props}
  />
))
DrawerHeader.displayName = 'DrawerHeader'

// ========================================
// DRAWER TITLE
// ========================================

/**
 * DrawerTitle Component
 */
const DrawerTitle = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Title>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Title>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Title
    ref={ref}
    className={cn('text-lg font-semibold leading-none tracking-tight', className)}
    {...props}
  />
))
DrawerTitle.displayName = DialogPrimitive.Title.displayName

// ========================================
// DRAWER DESCRIPTION
// ========================================

/**
 * DrawerDescription Component
 */
const DrawerDescription = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Description>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Description>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Description
    ref={ref}
    className={cn('text-sm text-muted-foreground', className)}
    {...props}
  />
))
DrawerDescription.displayName = DialogPrimitive.Description.displayName

// ========================================
// DRAWER BODY
// ========================================

/**
 * DrawerBody Component
 */
const DrawerBody = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex-1 overflow-y-auto px-6 py-4', className)}
    {...props}
  />
))
DrawerBody.displayName = 'DrawerBody'

// ========================================
// DRAWER FOOTER
// ========================================

/**
 * DrawerFooter Component
 */
const DrawerFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex items-center justify-end gap-2 p-6 border-t', className)}
    {...props}
  />
))
DrawerFooter.displayName = 'DrawerFooter'

// ========================================
// DRAWER CLOSE
// ========================================

/**
 * DrawerClose Component
 */
const DrawerClose = DialogPrimitive.Close

// ========================================
// EXPORTS
// ========================================

export {
  Drawer,
  DrawerTrigger,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerDescription,
  DrawerBody,
  DrawerFooter,
  DrawerClose,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Drawer

```typescript
import {
  Drawer,
  DrawerTrigger,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerDescription,
  DrawerBody,
  DrawerFooter,
  DrawerClose,
} from '@/components/ui/drawer'
import { Button } from '@/components/ui/button'

function BasicDrawer() {
  const [open, setOpen] = React.useState(false)

  return (
    <Drawer open={open} onOpenChange={setOpen}>
      <DrawerTrigger asChild>
        <Button>Open Drawer</Button>
      </DrawerTrigger>
      <DrawerContent>
        <DrawerHeader>
          <DrawerTitle>Drawer Title</DrawerTitle>
          <DrawerDescription>Drawer description goes here</DrawerDescription>
        </DrawerHeader>
        <DrawerBody>
          <p>Drawer content goes here.</p>
        </DrawerBody>
        <DrawerFooter>
          <DrawerClose asChild>
            <Button variant="outline">Close</Button>
          </DrawerClose>
          <Button>Save Changes</Button>
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  )
}
```

### Different Sides

```typescript
function DrawerDirections() {
  return (
    <div className="flex gap-2">
      {/* Left */}
      <Drawer>
        <DrawerTrigger asChild>
          <Button>Left</Button>
        </DrawerTrigger>
        <DrawerContent side="left">
          <DrawerHeader>
            <DrawerTitle>Left Drawer</DrawerTitle>
          </DrawerHeader>
          <DrawerBody>Content from left</DrawerBody>
        </DrawerContent>
      </Drawer>

      {/* Right */}
      <Drawer>
        <DrawerTrigger asChild>
          <Button>Right</Button>
        </DrawerTrigger>
        <DrawerContent side="right">
          <DrawerHeader>
            <DrawerTitle>Right Drawer</DrawerTitle>
          </DrawerHeader>
          <DrawerBody>Content from right</DrawerBody>
        </DrawerContent>
      </Drawer>

      {/* Top */}
      <Drawer>
        <DrawerTrigger asChild>
          <Button>Top</Button>
        </DrawerTrigger>
        <DrawerContent side="top" size="300px">
          <DrawerHeader>
            <DrawerTitle>Top Drawer</DrawerTitle>
          </DrawerHeader>
          <DrawerBody>Content from top</DrawerBody>
        </DrawerContent>
      </Drawer>

      {/* Bottom */}
      <Drawer>
        <DrawerTrigger asChild>
          <Button>Bottom</Button>
        </DrawerTrigger>
        <DrawerContent side="bottom" size="400px">
          <DrawerHeader>
            <DrawerTitle>Bottom Drawer</DrawerTitle>
          </DrawerHeader>
          <DrawerBody>Content from bottom</DrawerBody>
        </DrawerContent>
      </Drawer>
    </div>
  )
}
```

### Navigation Drawer

```typescript
import { Home, Settings, Users, FileText, Menu } from 'lucide-react'

function NavigationDrawer() {
  const [open, setOpen] = React.useState(false)

  const navItems = [
    { icon: Home, label: 'Dashboard', href: '/dashboard' },
    { icon: Users, label: 'Users', href: '/users' },
    { icon: FileText, label: 'Documents', href: '/documents' },
    { icon: Settings, label: 'Settings', href: '/settings' },
  ]

  return (
    <Drawer open={open} onOpenChange={setOpen}>
      <DrawerTrigger asChild>
        <Button variant="ghost" size="icon">
          <Menu className="h-5 w-5" />
        </Button>
      </DrawerTrigger>
      <DrawerContent side="left">
        <DrawerHeader>
          <DrawerTitle>Navigation</DrawerTitle>
        </DrawerHeader>
        <DrawerBody>
          <nav className="flex flex-col gap-2">
            {navItems.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="flex items-center gap-3 px-3 py-2 rounded-md hover:bg-accent transition-colors"
                onClick={() => setOpen(false)}
              >
                <item.icon className="h-5 w-5" />
                <span>{item.label}</span>
              </a>
            ))}
          </nav>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  )
}
```

### Filter Drawer

```typescript
import { FormField } from '@/components/ui/form-field'
import { Form } from '@/components/ui/form'

function FilterDrawer() {
  const [open, setOpen] = React.useState(false)
  const form = useForm()

  const onSubmit = (data: any) => {
    console.log('Filters:', data)
    setOpen(false)
  }

  return (
    <Drawer open={open} onOpenChange={setOpen}>
      <DrawerTrigger asChild>
        <Button variant="outline">
          <FilterIcon className="h-4 w-4 mr-2" />
          Filters
        </Button>
      </DrawerTrigger>
      <DrawerContent side="right" size="400px">
        <Form form={form} onSubmit={onSubmit}>
          <DrawerHeader>
            <DrawerTitle>Filter Options</DrawerTitle>
            <DrawerDescription>
              Refine your search results
            </DrawerDescription>
          </DrawerHeader>
          <DrawerBody className="space-y-4">
            <FormField name="status" type="select" label="Status" />
            <FormField name="category" type="select" label="Category" />
            <FormField name="dateRange" type="dateRange" label="Date Range" />
            <FormField name="minPrice" type="number" label="Min Price" />
            <FormField name="maxPrice" type="number" label="Max Price" />
          </DrawerBody>
          <DrawerFooter>
            <Button type="button" variant="outline" onClick={() => form.reset()}>
              Reset
            </Button>
            <Button type="submit">Apply Filters</Button>
          </DrawerFooter>
        </Form>
      </DrawerContent>
    </Drawer>
  )
}
```

### Custom Size Drawer

```typescript
function CustomSizeDrawer() {
  return (
    <>
      {/* Fixed pixel width */}
      <Drawer>
        <DrawerTrigger asChild>
          <Button>500px Wide</Button>
        </DrawerTrigger>
        <DrawerContent side="right" size={500}>
          <DrawerHeader>
            <DrawerTitle>500px Drawer</DrawerTitle>
          </DrawerHeader>
          <DrawerBody>Fixed 500px width</DrawerBody>
        </DrawerContent>
      </Drawer>

      {/* Percentage width */}
      <Drawer>
        <DrawerTrigger asChild>
          <Button>50% Wide</Button>
        </DrawerTrigger>
        <DrawerContent side="right" size="50%">
          <DrawerHeader>
            <DrawerTitle>50% Drawer</DrawerTitle>
          </DrawerHeader>
          <DrawerBody>50% of screen width</DrawerBody>
        </DrawerContent>
      </Drawer>
    </>
  )
}
```

---

## 🧪 TESTING

```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Drawer, DrawerTrigger, DrawerContent, DrawerTitle } from '../drawer'

describe('Drawer', () => {
  it('opens drawer when trigger is clicked', () => {
    render(
      <Drawer>
        <DrawerTrigger>Open</DrawerTrigger>
        <DrawerContent>
          <DrawerTitle>Test Drawer</DrawerTitle>
        </DrawerContent>
      </Drawer>
    )

    fireEvent.click(screen.getByText('Open'))
    expect(screen.getByText('Test Drawer')).toBeInTheDocument()
  })

  it('applies side variant correctly', () => {
    const { container } = render(
      <Drawer defaultOpen>
        <DrawerContent side="left">
          <DrawerTitle>Left Drawer</DrawerTitle>
        </DrawerContent>
      </Drawer>
    )

    const content = container.querySelector('[role="dialog"]')
    expect(content).toHaveClass('left-0')
  })

  it('applies custom size', () => {
    const { container } = render(
      <Drawer defaultOpen>
        <DrawerContent size="500px">
          <DrawerTitle>Custom Size</DrawerTitle>
        </DrawerContent>
      </Drawer>
    )

    const content = container.querySelector('[role="dialog"]')
    expect(content).toHaveStyle({ width: '500px' })
  })
})
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Focus trap within drawer
- ✅ Escape key to close
- ✅ ARIA labels and roles
- ✅ Keyboard navigation
- ✅ Focus restoration

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create drawer.tsx file
- [ ] Implement Drawer root component
- [ ] Implement DrawerContent with side variants
- [ ] Implement size customization
- [ ] Add all sub-components
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
