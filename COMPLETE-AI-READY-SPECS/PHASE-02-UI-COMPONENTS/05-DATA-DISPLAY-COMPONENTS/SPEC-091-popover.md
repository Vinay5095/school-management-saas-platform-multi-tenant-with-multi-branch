# SPEC-091: Popover Component
## Floating Content Containers

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 3 hours  
> **Dependencies**: Radix UI Popover

---

## 📋 OVERVIEW

### Purpose
A popover component for displaying rich content in a floating container, with smart positioning and accessibility features via Radix UI.

### Key Features
- ✅ Radix UI integration
- ✅ Auto-positioning with collision detection
- ✅ Controlled and uncontrolled modes
- ✅ Close on outside click
- ✅ Modal and non-modal modes
- ✅ Keyboard navigation
- ✅ Portal rendering
- ✅ Custom triggers

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/popover.tsx
import * as React from 'react'
import * as PopoverPrimitive from '@radix-ui/react-popover'
import { cn } from '@/lib/utils'

// ========================================
// POPOVER ROOT
// ========================================

const Popover = PopoverPrimitive.Root

// ========================================
// POPOVER TRIGGER
// ========================================

const PopoverTrigger = PopoverPrimitive.Trigger

// ========================================
// POPOVER ANCHOR
// ========================================

const PopoverAnchor = PopoverPrimitive.Anchor

// ========================================
// POPOVER CONTENT
// ========================================

export interface PopoverContentProps
  extends React.ComponentPropsWithoutRef<typeof PopoverPrimitive.Content> {
  /**
   * Show arrow indicator
   */
  showArrow?: boolean

  /**
   * Portal container
   */
  container?: HTMLElement
}

const PopoverContent = React.forwardRef<
  React.ElementRef<typeof PopoverPrimitive.Content>,
  PopoverContentProps
>(({ className, align = 'center', sideOffset = 4, showArrow = false, ...props }, ref) => (
  <PopoverPrimitive.Portal>
    <PopoverPrimitive.Content
      ref={ref}
      align={align}
      sideOffset={sideOffset}
      className={cn(
        'z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none',
        'data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95',
        'data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95',
        'data-[side=bottom]:slide-in-from-top-2',
        'data-[side=left]:slide-in-from-right-2',
        'data-[side=right]:slide-in-from-left-2',
        'data-[side=top]:slide-in-from-bottom-2',
        className
      )}
      {...props}
    >
      {props.children}
      {showArrow && (
        <PopoverPrimitive.Arrow className="fill-popover" />
      )}
    </PopoverPrimitive.Content>
  </PopoverPrimitive.Portal>
))
PopoverContent.displayName = PopoverPrimitive.Content.displayName

// ========================================
// POPOVER CLOSE
// ========================================

const PopoverClose = PopoverPrimitive.Close

// ========================================
// SIMPLE POPOVER WRAPPER
// ========================================

export interface SimplePopoverProps {
  /**
   * Trigger element
   */
  trigger: React.ReactNode

  /**
   * Popover content
   */
  children: React.ReactNode

  /**
   * Popover side
   */
  side?: 'top' | 'right' | 'bottom' | 'left'

  /**
   * Align popover
   */
  align?: 'start' | 'center' | 'end'

  /**
   * Show arrow
   */
  showArrow?: boolean

  /**
   * Controlled open state
   */
  open?: boolean

  /**
   * Controlled open change
   */
  onOpenChange?: (open: boolean) => void

  /**
   * Additional className for content
   */
  className?: string

  /**
   * Modal mode (trap focus)
   */
  modal?: boolean
}

/**
 * Simple Popover Wrapper
 * 
 * Convenience wrapper for common popover usage.
 */
function SimplePopover({
  trigger,
  children,
  side = 'bottom',
  align = 'center',
  showArrow = false,
  open,
  onOpenChange,
  className,
  modal = false,
}: SimplePopoverProps) {
  return (
    <Popover open={open} onOpenChange={onOpenChange} modal={modal}>
      <PopoverTrigger asChild>{trigger}</PopoverTrigger>
      <PopoverContent
        side={side}
        align={align}
        showArrow={showArrow}
        className={className}
      >
        {children}
      </PopoverContent>
    </Popover>
  )
}

// ========================================
// POPOVER HEADER
// ========================================

export interface PopoverHeaderProps extends React.HTMLAttributes<HTMLDivElement> {}

const PopoverHeader = React.forwardRef<HTMLDivElement, PopoverHeaderProps>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn('mb-3 space-y-1', className)}
      {...props}
    />
  )
)
PopoverHeader.displayName = 'PopoverHeader'

// ========================================
// POPOVER TITLE
// ========================================

export interface PopoverTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {}

const PopoverTitle = React.forwardRef<HTMLHeadingElement, PopoverTitleProps>(
  ({ className, ...props }, ref) => (
    <h4
      ref={ref}
      className={cn('font-semibold leading-none tracking-tight', className)}
      {...props}
    />
  )
)
PopoverTitle.displayName = 'PopoverTitle'

// ========================================
// POPOVER DESCRIPTION
// ========================================

export interface PopoverDescriptionProps extends React.HTMLAttributes<HTMLParagraphElement> {}

const PopoverDescription = React.forwardRef<HTMLParagraphElement, PopoverDescriptionProps>(
  ({ className, ...props }, ref) => (
    <p
      ref={ref}
      className={cn('text-sm text-muted-foreground', className)}
      {...props}
    />
  )
)
PopoverDescription.displayName = 'PopoverDescription'

// ========================================
// POPOVER FOOTER
// ========================================

export interface PopoverFooterProps extends React.HTMLAttributes<HTMLDivElement> {}

const PopoverFooter = React.forwardRef<HTMLDivElement, PopoverFooterProps>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn('mt-3 flex items-center justify-end gap-2', className)}
      {...props}
    />
  )
)
PopoverFooter.displayName = 'PopoverFooter'

export {
  Popover,
  PopoverTrigger,
  PopoverContent,
  PopoverAnchor,
  PopoverClose,
  SimplePopover,
  PopoverHeader,
  PopoverTitle,
  PopoverDescription,
  PopoverFooter,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Popover

```typescript
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'

function BasicPopover() {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline">Open Popover</Button>
      </PopoverTrigger>
      <PopoverContent>
        <p>This is a popover with some content.</p>
      </PopoverContent>
    </Popover>
  )
}
```

### Simple Popover Wrapper

```typescript
import { SimplePopover } from '@/components/ui/popover'

function SimpleExample() {
  return (
    <SimplePopover
      trigger={<Button>Open</Button>}
    >
      <p>Simple popover content</p>
    </SimplePopover>
  )
}
```

### With Header and Footer

```typescript
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
  PopoverHeader,
  PopoverTitle,
  PopoverDescription,
  PopoverFooter,
  PopoverClose,
} from '@/components/ui/popover'

function StructuredPopover() {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button>Open</Button>
      </PopoverTrigger>
      <PopoverContent>
        <PopoverHeader>
          <PopoverTitle>Settings</PopoverTitle>
          <PopoverDescription>
            Manage your account settings
          </PopoverDescription>
        </PopoverHeader>
        
        <div className="space-y-2">
          <p className="text-sm">Content goes here</p>
        </div>
        
        <PopoverFooter>
          <PopoverClose asChild>
            <Button variant="outline">Cancel</Button>
          </PopoverClose>
          <Button>Save</Button>
        </PopoverFooter>
      </PopoverContent>
    </Popover>
  )
}
```

### Different Positions

```typescript
function PopoverPositions() {
  return (
    <div className="flex gap-4">
      <SimplePopover
        trigger={<Button>Top</Button>}
        side="top"
      >
        <p>Top popover</p>
      </SimplePopover>
      
      <SimplePopover
        trigger={<Button>Right</Button>}
        side="right"
      >
        <p>Right popover</p>
      </SimplePopover>
      
      <SimplePopover
        trigger={<Button>Bottom</Button>}
        side="bottom"
      >
        <p>Bottom popover</p>
      </SimplePopover>
      
      <SimplePopover
        trigger={<Button>Left</Button>}
        side="left"
      >
        <p>Left popover</p>
      </SimplePopover>
    </div>
  )
}
```

### Form in Popover

```typescript
function FormPopover() {
  const [email, setEmail] = React.useState('')

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button>Subscribe</Button>
      </PopoverTrigger>
      <PopoverContent className="w-80">
        <PopoverHeader>
          <PopoverTitle>Newsletter</PopoverTitle>
          <PopoverDescription>
            Enter your email to subscribe
          </PopoverDescription>
        </PopoverHeader>
        
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
        </div>
        
        <PopoverFooter>
          <PopoverClose asChild>
            <Button variant="outline">Cancel</Button>
          </PopoverClose>
          <Button onClick={() => console.log('Subscribe:', email)}>
            Subscribe
          </Button>
        </PopoverFooter>
      </PopoverContent>
    </Popover>
  )
}
```

### Controlled Popover

```typescript
function ControlledPopover() {
  const [open, setOpen] = React.useState(false)

  return (
    <div className="space-y-4">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button>Controlled Popover</Button>
        </PopoverTrigger>
        <PopoverContent>
          <PopoverHeader>
            <PopoverTitle>Controlled</PopoverTitle>
          </PopoverHeader>
          <p className="text-sm">This popover is controlled externally.</p>
          <PopoverFooter>
            <Button onClick={() => setOpen(false)}>Close</Button>
          </PopoverFooter>
        </PopoverContent>
      </Popover>
      
      <Button onClick={() => setOpen(!open)}>
        Toggle from outside
      </Button>
    </div>
  )
}
```

### Date Picker Popover

```typescript
import { Calendar } from '@/components/ui/calendar'
import { format } from 'date-fns'

function DatePickerPopover() {
  const [date, setDate] = React.useState<Date>()

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" className="w-[240px] justify-start text-left">
          <CalendarIcon className="mr-2 h-4 w-4" />
          {date ? format(date, 'PPP') : <span>Pick a date</span>}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto p-0" align="start">
        <Calendar
          mode="single"
          selected={date}
          onSelect={setDate}
          initialFocus
        />
      </PopoverContent>
    </Popover>
  )
}
```

### Share Popover

```typescript
function SharePopover() {
  const shareUrl = 'https://example.com/share'

  const copyToClipboard = () => {
    navigator.clipboard.writeText(shareUrl)
  }

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" size="icon">
          <Share2 className="h-4 w-4" />
        </Button>
      </PopoverTrigger>
      <PopoverContent>
        <PopoverHeader>
          <PopoverTitle>Share this page</PopoverTitle>
        </PopoverHeader>
        
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Input value={shareUrl} readOnly />
            <Button size="sm" onClick={copyToClipboard}>
              Copy
            </Button>
          </div>
          
          <div className="flex gap-2">
            <Button variant="outline" size="icon">
              <Twitter className="h-4 w-4" />
            </Button>
            <Button variant="outline" size="icon">
              <Facebook className="h-4 w-4" />
            </Button>
            <Button variant="outline" size="icon">
              <Linkedin className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  )
}
```

### Color Picker Popover

```typescript
function ColorPickerPopover() {
  const [color, setColor] = React.useState('#000000')

  const presetColors = [
    '#FF0000', '#00FF00', '#0000FF',
    '#FFFF00', '#FF00FF', '#00FFFF',
    '#FFA500', '#800080', '#008000',
  ]

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" className="w-[220px] justify-start">
          <div className="flex items-center gap-2">
            <div
              className="h-4 w-4 rounded border"
              style={{ backgroundColor: color }}
            />
            <span>{color}</span>
          </div>
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-64">
        <PopoverHeader>
          <PopoverTitle>Pick a color</PopoverTitle>
        </PopoverHeader>
        
        <div className="space-y-3">
          <Input
            type="color"
            value={color}
            onChange={(e) => setColor(e.target.value)}
            className="h-10 w-full"
          />
          
          <div className="grid grid-cols-3 gap-2">
            {presetColors.map((c) => (
              <button
                key={c}
                className="h-8 rounded border hover:ring-2 ring-primary"
                style={{ backgroundColor: c }}
                onClick={() => setColor(c)}
              />
            ))}
          </div>
        </div>
      </PopoverContent>
    </Popover>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Popover', () => {
  it('opens on trigger click', async () => {
    render(
      <Popover>
        <PopoverTrigger>Open</PopoverTrigger>
        <PopoverContent>Content</PopoverContent>
      </Popover>
    )

    const trigger = screen.getByText('Open')
    fireEvent.click(trigger)

    await waitFor(() => {
      expect(screen.getByText('Content')).toBeInTheDocument()
    })
  })

  it('closes on outside click', async () => {
    render(
      <>
        <Popover>
          <PopoverTrigger>Open</PopoverTrigger>
          <PopoverContent>Content</PopoverContent>
        </Popover>
        <div data-testid="outside">Outside</div>
      </>
    )

    const trigger = screen.getByText('Open')
    fireEvent.click(trigger)

    await waitFor(() => {
      expect(screen.getByText('Content')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('outside'))

    await waitFor(() => {
      expect(screen.queryByText('Content')).not.toBeInTheDocument()
    })
  })

  it('supports controlled mode', async () => {
    const onOpenChange = jest.fn()
    
    render(
      <Popover open={true} onOpenChange={onOpenChange}>
        <PopoverTrigger>Open</PopoverTrigger>
        <PopoverContent>Content</PopoverContent>
      </Popover>
    )

    expect(screen.getByText('Content')).toBeInTheDocument()

    const trigger = screen.getByText('Open')
    fireEvent.click(trigger)

    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('closes with PopoverClose', async () => {
    render(
      <Popover>
        <PopoverTrigger>Open</PopoverTrigger>
        <PopoverContent>
          <PopoverClose>Close</PopoverClose>
        </PopoverContent>
      </Popover>
    )

    fireEvent.click(screen.getByText('Open'))

    await waitFor(() => {
      expect(screen.getByText('Close')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByText('Close'))

    await waitFor(() => {
      expect(screen.queryByText('Close')).not.toBeInTheDocument()
    })
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ ARIA attributes
- ✅ Keyboard navigation (ESC to close)
- ✅ Focus management
- ✅ Focus trap in modal mode
- ✅ Screen reader support
- ✅ Role attributes

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Radix UI Popover: `npm install @radix-ui/react-popover`
- [ ] Create popover.tsx
- [ ] Implement PopoverContent with animations
- [ ] Create SimplePopover wrapper
- [ ] Create PopoverHeader, Title, Description, Footer
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~1.5KB
- **With Radix UI**: ~4KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
