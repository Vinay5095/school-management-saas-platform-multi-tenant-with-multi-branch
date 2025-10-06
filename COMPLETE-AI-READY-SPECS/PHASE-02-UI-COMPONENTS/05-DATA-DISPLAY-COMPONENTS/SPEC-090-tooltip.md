# SPEC-090: Tooltip Component
## Contextual Information Popups

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: Radix UI Tooltip

---

## 📋 OVERVIEW

### Purpose
A tooltip component for displaying helpful information on hover or focus, built with Radix UI for accessibility and positioning.

### Key Features
- ✅ Radix UI integration for accessibility
- ✅ Multiple trigger modes (hover, focus, click)
- ✅ Auto-positioning with collision detection
- ✅ Customizable delays
- ✅ Arrow indicator
- ✅ Keyboard navigation
- ✅ Portal rendering
- ✅ Controlled and uncontrolled modes

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/tooltip.tsx
import * as React from 'react'
import * as TooltipPrimitive from '@radix-ui/react-tooltip'
import { cn } from '@/lib/utils'

// ========================================
// TOOLTIP PROVIDER
// ========================================

const TooltipProvider = TooltipPrimitive.Provider

// ========================================
// TOOLTIP ROOT
// ========================================

const Tooltip = TooltipPrimitive.Root

// ========================================
// TOOLTIP TRIGGER
// ========================================

const TooltipTrigger = TooltipPrimitive.Trigger

// ========================================
// TOOLTIP CONTENT
// ========================================

export interface TooltipContentProps
  extends React.ComponentPropsWithoutRef<typeof TooltipPrimitive.Content> {
  /**
   * Show arrow indicator
   */
  showArrow?: boolean

  /**
   * Portal container
   */
  container?: HTMLElement
}

const TooltipContent = React.forwardRef<
  React.ElementRef<typeof TooltipPrimitive.Content>,
  TooltipContentProps
>(({ className, sideOffset = 4, showArrow = true, ...props }, ref) => (
  <TooltipPrimitive.Portal>
    <TooltipPrimitive.Content
      ref={ref}
      sideOffset={sideOffset}
      className={cn(
        'z-50 overflow-hidden rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md',
        'animate-in fade-in-0 zoom-in-95',
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
        <TooltipPrimitive.Arrow className="fill-popover" />
      )}
    </TooltipPrimitive.Content>
  </TooltipPrimitive.Portal>
))
TooltipContent.displayName = TooltipPrimitive.Content.displayName

// ========================================
// SIMPLE TOOLTIP WRAPPER
// ========================================

export interface SimpleTooltipProps {
  /**
   * Tooltip content
   */
  content: React.ReactNode

  /**
   * Trigger element
   */
  children: React.ReactNode

  /**
   * Tooltip side
   */
  side?: 'top' | 'right' | 'bottom' | 'left'

  /**
   * Align tooltip
   */
  align?: 'start' | 'center' | 'end'

  /**
   * Delay before showing (ms)
   */
  delayDuration?: number

  /**
   * Show arrow
   */
  showArrow?: boolean

  /**
   * Additional className for content
   */
  className?: string

  /**
   * Disable tooltip
   */
  disabled?: boolean
}

/**
 * Simple Tooltip Wrapper
 * 
 * Convenience wrapper for common tooltip usage.
 */
function SimpleTooltip({
  content,
  children,
  side = 'top',
  align = 'center',
  delayDuration = 200,
  showArrow = true,
  className,
  disabled = false,
}: SimpleTooltipProps) {
  if (disabled) {
    return <>{children}</>
  }

  return (
    <TooltipProvider delayDuration={delayDuration}>
      <Tooltip>
        <TooltipTrigger asChild>{children}</TooltipTrigger>
        <TooltipContent
          side={side}
          align={align}
          showArrow={showArrow}
          className={className}
        >
          {content}
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  )
}

// ========================================
// INFO TOOLTIP
// ========================================

export interface InfoTooltipProps extends Omit<SimpleTooltipProps, 'children'> {
  /**
   * Icon size
   */
  iconSize?: 'sm' | 'md' | 'lg'
}

/**
 * Info Tooltip
 * 
 * Tooltip with info icon trigger.
 */
function InfoTooltip({
  content,
  iconSize = 'sm',
  ...props
}: InfoTooltipProps) {
  const sizeClasses = {
    sm: 'h-3.5 w-3.5',
    md: 'h-4 w-4',
    lg: 'h-5 w-5',
  }

  return (
    <SimpleTooltip content={content} {...props}>
      <button
        type="button"
        className="inline-flex items-center justify-center rounded-full text-muted-foreground hover:text-foreground transition-colors"
        aria-label="More information"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={cn(sizeClasses[iconSize])}
        >
          <circle cx="12" cy="12" r="10" />
          <path d="M12 16v-4" />
          <path d="M12 8h.01" />
        </svg>
      </button>
    </SimpleTooltip>
  )
}

export {
  Tooltip,
  TooltipTrigger,
  TooltipContent,
  TooltipProvider,
  SimpleTooltip,
  InfoTooltip,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Tooltip

```typescript
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip'

function BasicTooltip() {
  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="outline">Hover me</Button>
        </TooltipTrigger>
        <TooltipContent>
          <p>This is a tooltip</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  )
}
```

### Simple Tooltip Wrapper

```typescript
import { SimpleTooltip } from '@/components/ui/tooltip'

function SimpleExample() {
  return (
    <SimpleTooltip content="Click to save your changes">
      <Button>Save</Button>
    </SimpleTooltip>
  )
}
```

### Different Sides

```typescript
function TooltipSides() {
  return (
    <div className="flex gap-4">
      <SimpleTooltip content="Top tooltip" side="top">
        <Button>Top</Button>
      </SimpleTooltip>
      
      <SimpleTooltip content="Right tooltip" side="right">
        <Button>Right</Button>
      </SimpleTooltip>
      
      <SimpleTooltip content="Bottom tooltip" side="bottom">
        <Button>Bottom</Button>
      </SimpleTooltip>
      
      <SimpleTooltip content="Left tooltip" side="left">
        <Button>Left</Button>
      </SimpleTooltip>
    </div>
  )
}
```

### Info Tooltip

```typescript
import { InfoTooltip } from '@/components/ui/tooltip'

function InfoTooltipExample() {
  return (
    <div className="flex items-center gap-2">
      <label>Password</label>
      <InfoTooltip
        content="Password must be at least 8 characters"
        iconSize="sm"
      />
    </div>
  )
}
```

### With Rich Content

```typescript
function RichTooltip() {
  return (
    <SimpleTooltip
      content={
        <div className="space-y-2">
          <p className="font-semibold">Keyboard Shortcuts</p>
          <div className="space-y-1 text-xs">
            <div className="flex justify-between gap-4">
              <span>Save</span>
              <kbd className="px-1 rounded bg-muted">Ctrl+S</kbd>
            </div>
            <div className="flex justify-between gap-4">
              <span>Undo</span>
              <kbd className="px-1 rounded bg-muted">Ctrl+Z</kbd>
            </div>
          </div>
        </div>
      }
      className="max-w-xs"
    >
      <Button variant="ghost" size="icon">
        <HelpCircle className="h-4 w-4" />
      </Button>
    </SimpleTooltip>
  )
}
```

### Custom Delay

```typescript
function CustomDelayTooltip() {
  return (
    <SimpleTooltip
      content="This appears after 500ms"
      delayDuration={500}
    >
      <Button>Hover with delay</Button>
    </SimpleTooltip>
  )
}
```

### Without Arrow

```typescript
function NoArrowTooltip() {
  return (
    <SimpleTooltip
      content="No arrow on this tooltip"
      showArrow={false}
    >
      <Button>No Arrow</Button>
    </SimpleTooltip>
  )
}
```

### Disabled Tooltip

```typescript
function DisabledTooltip() {
  const [disabled, setDisabled] = React.useState(false)

  return (
    <div className="space-y-4">
      <SimpleTooltip
        content="This tooltip can be disabled"
        disabled={disabled}
      >
        <Button>Hover me</Button>
      </SimpleTooltip>
      
      <Button onClick={() => setDisabled(!disabled)}>
        {disabled ? 'Enable' : 'Disable'} Tooltip
      </Button>
    </div>
  )
}
```

### Tooltip on Icon Button

```typescript
function IconButtonTooltip() {
  return (
    <div className="flex gap-2">
      <SimpleTooltip content="Edit">
        <Button variant="ghost" size="icon">
          <Pencil className="h-4 w-4" />
        </Button>
      </SimpleTooltip>
      
      <SimpleTooltip content="Delete">
        <Button variant="ghost" size="icon">
          <Trash2 className="h-4 w-4" />
        </Button>
      </SimpleTooltip>
      
      <SimpleTooltip content="Share">
        <Button variant="ghost" size="icon">
          <Share2 className="h-4 w-4" />
        </Button>
      </SimpleTooltip>
    </div>
  )
}
```

### Form Field Tooltip

```typescript
function FormFieldTooltip() {
  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <Label htmlFor="email">Email</Label>
        <InfoTooltip content="We'll never share your email with anyone" />
      </div>
      <Input id="email" type="email" />
    </div>
  )
}
```

### Controlled Tooltip

```typescript
function ControlledTooltip() {
  const [open, setOpen] = React.useState(false)

  return (
    <div className="space-y-4">
      <TooltipProvider>
        <Tooltip open={open} onOpenChange={setOpen}>
          <TooltipTrigger asChild>
            <Button>Controlled Tooltip</Button>
          </TooltipTrigger>
          <TooltipContent>
            <p>This tooltip is controlled</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
      
      <Button onClick={() => setOpen(!open)}>
        {open ? 'Close' : 'Open'} Tooltip
      </Button>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Tooltip', () => {
  it('renders tooltip on hover', async () => {
    render(
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <button>Trigger</button>
          </TooltipTrigger>
          <TooltipContent>Tooltip content</TooltipContent>
        </Tooltip>
      </TooltipProvider>
    )

    const trigger = screen.getByRole('button', { name: 'Trigger' })
    
    userEvent.hover(trigger)
    
    await waitFor(() => {
      expect(screen.getByText('Tooltip content')).toBeInTheDocument()
    })
  })

  it('hides tooltip on mouse leave', async () => {
    render(
      <SimpleTooltip content="Test tooltip">
        <button>Trigger</button>
      </SimpleTooltip>
    )

    const trigger = screen.getByRole('button')
    
    userEvent.hover(trigger)
    await waitFor(() => {
      expect(screen.getByText('Test tooltip')).toBeInTheDocument()
    })

    userEvent.unhover(trigger)
    await waitFor(() => {
      expect(screen.queryByText('Test tooltip')).not.toBeInTheDocument()
    })
  })

  it('respects delay duration', async () => {
    jest.useFakeTimers()
    
    render(
      <SimpleTooltip content="Delayed tooltip" delayDuration={500}>
        <button>Trigger</button>
      </SimpleTooltip>
    )

    const trigger = screen.getByRole('button')
    userEvent.hover(trigger)

    // Should not appear immediately
    expect(screen.queryByText('Delayed tooltip')).not.toBeInTheDocument()

    // Fast-forward time
    act(() => {
      jest.advanceTimersByTime(500)
    })

    await waitFor(() => {
      expect(screen.getByText('Delayed tooltip')).toBeInTheDocument()
    })

    jest.useRealTimers()
  })

  it('renders without arrow when showArrow is false', async () => {
    render(
      <SimpleTooltip content="No arrow" showArrow={false}>
        <button>Trigger</button>
      </SimpleTooltip>
    )

    const trigger = screen.getByRole('button')
    userEvent.hover(trigger)

    await waitFor(() => {
      const tooltip = screen.getByText('No arrow')
      expect(tooltip.querySelector('[class*="Arrow"]')).not.toBeInTheDocument()
    })
  })

  it('does not render when disabled', () => {
    render(
      <SimpleTooltip content="Should not show" disabled>
        <button>Trigger</button>
      </SimpleTooltip>
    )

    const trigger = screen.getByRole('button')
    userEvent.hover(trigger)

    expect(screen.queryByText('Should not show')).not.toBeInTheDocument()
  })

  it('supports keyboard navigation', async () => {
    render(
      <SimpleTooltip content="Keyboard tooltip">
        <button>Trigger</button>
      </SimpleTooltip>
    )

    const trigger = screen.getByRole('button')
    trigger.focus()

    await waitFor(() => {
      expect(screen.getByText('Keyboard tooltip')).toBeInTheDocument()
    })
  })
})

describe('InfoTooltip', () => {
  it('renders info icon', () => {
    render(<InfoTooltip content="Info" />)
    expect(screen.getByLabelText('More information')).toBeInTheDocument()
  })

  it('shows tooltip on hover', async () => {
    render(<InfoTooltip content="Information tooltip" />)

    const icon = screen.getByLabelText('More information')
    userEvent.hover(icon)

    await waitFor(() => {
      expect(screen.getByText('Information tooltip')).toBeInTheDocument()
    })
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ ARIA labels and descriptions
- ✅ Keyboard navigation (focus trigger)
- ✅ ESC key to close
- ✅ Screen reader support
- ✅ Focus management
- ✅ Role attributes

---

## 🎨 STYLING NOTES

### Animation
```css
/* Tooltip animations are handled via Tailwind */
.animate-in {
  animation: enter 150ms ease-out;
}

.animate-out {
  animation: exit 150ms ease-in;
}
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Radix UI Tooltip: `npm install @radix-ui/react-tooltip`
- [ ] Create tooltip.tsx
- [ ] Implement TooltipContent with animations
- [ ] Create SimpleTooltip wrapper
- [ ] Create InfoTooltip component
- [ ] Add arrow support
- [ ] Implement delay configuration
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~1KB
- **With Radix UI**: ~3KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
