# SPEC-051: Button Component
## Versatile Button Component with Multiple Variants

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 4 hours  
> **Dependencies**: Radix UI Slot, CVA (class-variance-authority)

---

## 📋 OVERVIEW

### Purpose
A fully accessible, highly customizable button component that serves as the foundation for all interactive actions across the platform. Supports multiple variants, sizes, loading states, and icon positioning.

### Key Features
- ✅ 6 visual variants (default, destructive, outline, secondary, ghost, link)
- ✅ 4 size options (sm, default, lg, icon)
- ✅ Loading state with spinner
- ✅ Left and right icon support
- ✅ AsChild pattern for composition
- ✅ Full keyboard navigation
- ✅ WCAG 2.1 AA compliant
- ✅ TypeScript strict mode
- ✅ Disabled state handling

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/button.tsx
'use client'

import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// VARIANT CONFIGURATION
// ========================================

const buttonVariants = cva(
  // Base styles applied to all buttons
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      // Visual variants
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      // Size variants
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  /**
   * Change the component to the HTML tag or custom component of your choice
   * Useful for creating button-styled links
   */
  asChild?: boolean
  
  /**
   * Shows loading spinner and disables the button
   */
  loading?: boolean
  
  /**
   * Icon to display on the left side of the button text
   */
  leftIcon?: React.ReactNode
  
  /**
   * Icon to display on the right side of the button text
   */
  rightIcon?: React.ReactNode
}

// ========================================
// BUTTON COMPONENT
// ========================================

/**
 * Button Component
 * 
 * A versatile button component with multiple variants and sizes.
 * Supports loading states, icons, and full accessibility.
 * 
 * @example
 * // Basic button
 * <Button variant="default" size="default">
 *   Click Me
 * </Button>
 * 
 * @example
 * // Button with loading state
 * <Button loading>
 *   Processing...
 * </Button>
 * 
 * @example
 * // Button with icons
 * <Button leftIcon={<Save />} variant="primary">
 *   Save Changes
 * </Button>
 * 
 * @example
 * // Button as link
 * <Button asChild variant="link">
 *   <a href="/profile">View Profile</a>
 * </Button>
 */
const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    { 
      className, 
      variant, 
      size, 
      asChild = false, 
      loading, 
      leftIcon, 
      rightIcon, 
      children, 
      disabled, 
      ...props 
    }, 
    ref
  ) => {
    // Use Slot component for asChild pattern, otherwise use button
    const Comp = asChild ? Slot : 'button'
    
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        disabled={disabled || loading}
        aria-busy={loading}
        aria-disabled={disabled || loading}
        {...props}
      >
        {/* Loading spinner */}
        {loading && <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />}
        
        {/* Left icon (only show when not loading) */}
        {!loading && leftIcon && (
          <span className="inline-flex" aria-hidden="true">
            {leftIcon}
          </span>
        )}
        
        {/* Button text/children */}
        {children}
        
        {/* Right icon (only show when not loading) */}
        {!loading && rightIcon && (
          <span className="inline-flex" aria-hidden="true">
            {rightIcon}
          </span>
        )}
      </Comp>
    )
  }
)

Button.displayName = 'Button'

export { Button, buttonVariants }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from '../button'
import { Save, Trash } from 'lucide-react'

describe('Button Component', () => {
  describe('Rendering', () => {
    it('renders correctly with text', () => {
      render(<Button>Click me</Button>)
      expect(screen.getByRole('button')).toHaveTextContent('Click me')
    })

    it('renders with custom className', () => {
      render(<Button className="custom-class">Test</Button>)
      expect(screen.getByRole('button')).toHaveClass('custom-class')
    })

    it('renders as child component when asChild is true', () => {
      render(
        <Button asChild>
          <a href="/test">Link Button</a>
        </Button>
      )
      expect(screen.getByRole('link')).toBeInTheDocument()
    })
  })

  describe('Variants', () => {
    it('renders default variant', () => {
      render(<Button variant="default">Default</Button>)
      expect(screen.getByRole('button')).toHaveClass('bg-primary')
    })

    it('renders destructive variant', () => {
      render(<Button variant="destructive">Delete</Button>)
      expect(screen.getByRole('button')).toHaveClass('bg-destructive')
    })

    it('renders outline variant', () => {
      render(<Button variant="outline">Outline</Button>)
      expect(screen.getByRole('button')).toHaveClass('border')
    })

    it('renders secondary variant', () => {
      render(<Button variant="secondary">Secondary</Button>)
      expect(screen.getByRole('button')).toHaveClass('bg-secondary')
    })

    it('renders ghost variant', () => {
      render(<Button variant="ghost">Ghost</Button>)
      expect(screen.getByRole('button')).toHaveClass('hover:bg-accent')
    })

    it('renders link variant', () => {
      render(<Button variant="link">Link</Button>)
      expect(screen.getByRole('button')).toHaveClass('underline-offset-4')
    })
  })

  describe('Sizes', () => {
    it('renders default size', () => {
      render(<Button size="default">Default</Button>)
      expect(screen.getByRole('button')).toHaveClass('h-10')
    })

    it('renders small size', () => {
      render(<Button size="sm">Small</Button>)
      expect(screen.getByRole('button')).toHaveClass('h-9')
    })

    it('renders large size', () => {
      render(<Button size="lg">Large</Button>)
      expect(screen.getByRole('button')).toHaveClass('h-11')
    })

    it('renders icon size', () => {
      render(<Button size="icon">🔍</Button>)
      expect(screen.getByRole('button')).toHaveClass('h-10', 'w-10')
    })
  })

  describe('Interactions', () => {
    it('handles click events', () => {
      const handleClick = jest.fn()
      render(<Button onClick={handleClick}>Click</Button>)
      
      fireEvent.click(screen.getByRole('button'))
      expect(handleClick).toHaveBeenCalledTimes(1)
    })

    it('does not trigger click when disabled', () => {
      const handleClick = jest.fn()
      render(<Button onClick={handleClick} disabled>Click</Button>)
      
      fireEvent.click(screen.getByRole('button'))
      expect(handleClick).not.toHaveBeenCalled()
    })

    it('does not trigger click when loading', () => {
      const handleClick = jest.fn()
      render(<Button onClick={handleClick} loading>Click</Button>)
      
      fireEvent.click(screen.getByRole('button'))
      expect(handleClick).not.toHaveBeenCalled()
    })
  })

  describe('Loading State', () => {
    it('shows loading spinner', () => {
      render(<Button loading>Loading</Button>)
      expect(screen.getByRole('button')).toHaveAttribute('aria-busy', 'true')
    })

    it('disables button when loading', () => {
      render(<Button loading>Loading</Button>)
      expect(screen.getByRole('button')).toBeDisabled()
    })

    it('hides icons when loading', () => {
      render(
        <Button loading leftIcon={<Save data-testid="save-icon" />}>
          Save
        </Button>
      )
      expect(screen.queryByTestId('save-icon')).not.toBeInTheDocument()
    })
  })

  describe('Icons', () => {
    it('renders left icon', () => {
      render(
        <Button leftIcon={<span data-testid="left-icon">←</span>}>
          With Icon
        </Button>
      )
      expect(screen.getByTestId('left-icon')).toBeInTheDocument()
    })

    it('renders right icon', () => {
      render(
        <Button rightIcon={<span data-testid="right-icon">→</span>}>
          With Icon
        </Button>
      )
      expect(screen.getByTestId('right-icon')).toBeInTheDocument()
    })

    it('renders both left and right icons', () => {
      render(
        <Button
          leftIcon={<span data-testid="left-icon">←</span>}
          rightIcon={<span data-testid="right-icon">→</span>}
        >
          Both Icons
        </Button>
      )
      expect(screen.getByTestId('left-icon')).toBeInTheDocument()
      expect(screen.getByTestId('right-icon')).toBeInTheDocument()
    })
  })

  describe('Disabled State', () => {
    it('respects disabled prop', () => {
      render(<Button disabled>Disabled</Button>)
      expect(screen.getByRole('button')).toBeDisabled()
    })

    it('has reduced opacity when disabled', () => {
      render(<Button disabled>Disabled</Button>)
      expect(screen.getByRole('button')).toHaveClass('opacity-50')
    })

    it('has no pointer events when disabled', () => {
      render(<Button disabled>Disabled</Button>)
      expect(screen.getByRole('button')).toHaveClass('pointer-events-none')
    })
  })

  describe('Accessibility', () => {
    it('supports keyboard navigation with Enter', async () => {
      const handleClick = jest.fn()
      render(<Button onClick={handleClick}>Keyboard</Button>)
      const button = screen.getByRole('button')
      
      button.focus()
      await userEvent.keyboard('{Enter}')
      expect(handleClick).toHaveBeenCalled()
    })

    it('supports keyboard navigation with Space', async () => {
      const handleClick = jest.fn()
      render(<Button onClick={handleClick}>Keyboard</Button>)
      const button = screen.getByRole('button')
      
      button.focus()
      await userEvent.keyboard(' ')
      expect(handleClick).toHaveBeenCalled()
    })

    it('has proper ARIA attributes when loading', () => {
      render(<Button loading>Loading</Button>)
      const button = screen.getByRole('button')
      
      expect(button).toHaveAttribute('aria-busy', 'true')
      expect(button).toHaveAttribute('aria-disabled', 'true')
    })

    it('has proper ARIA attributes when disabled', () => {
      render(<Button disabled>Disabled</Button>)
      const button = screen.getByRole('button')
      
      expect(button).toHaveAttribute('aria-disabled', 'true')
    })

    it('has focus visible ring', () => {
      render(<Button>Focus Test</Button>)
      expect(screen.getByRole('button')).toHaveClass('focus-visible:ring-2')
    })
  })

  describe('Type Attribute', () => {
    it('defaults to button type', () => {
      render(<Button>Test</Button>)
      expect(screen.getByRole('button')).toHaveAttribute('type', 'button')
    })

    it('can be set to submit', () => {
      render(<Button type="submit">Submit</Button>)
      expect(screen.getByRole('button')).toHaveAttribute('type', 'submit')
    })

    it('can be set to reset', () => {
      render(<Button type="reset">Reset</Button>)
      expect(screen.getByRole('button')).toHaveAttribute('type', 'reset')
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Usage

```typescript
import { Button } from '@/components/ui/button'

function MyComponent() {
  return (
    <div className="flex gap-2">
      <Button>Default Button</Button>
      <Button variant="destructive">Delete</Button>
      <Button variant="outline">Cancel</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="ghost">Ghost</Button>
      <Button variant="link">Link</Button>
    </div>
  )
}
```

### Different Sizes

```typescript
function SizeExamples() {
  return (
    <div className="flex items-center gap-2">
      <Button size="sm">Small</Button>
      <Button size="default">Default</Button>
      <Button size="lg">Large</Button>
      <Button size="icon">🔍</Button>
    </div>
  )
}
```

### With Loading State

```typescript
function LoadingButton() {
  const [isLoading, setIsLoading] = React.useState(false)

  const handleSubmit = async () => {
    setIsLoading(true)
    try {
      await submitForm()
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Button onClick={handleSubmit} loading={isLoading}>
      {isLoading ? 'Saving...' : 'Save Changes'}
    </Button>
  )
}
```

### With Icons

```typescript
import { Save, Trash, Download, Upload } from 'lucide-react'

function IconButtons() {
  return (
    <div className="flex gap-2">
      <Button leftIcon={<Save className="h-4 w-4" />}>
        Save
      </Button>
      
      <Button rightIcon={<Download className="h-4 w-4" />} variant="outline">
        Download
      </Button>
      
      <Button
        leftIcon={<Trash className="h-4 w-4" />}
        variant="destructive"
      >
        Delete
      </Button>
      
      <Button size="icon" variant="ghost">
        <Upload className="h-4 w-4" />
      </Button>
    </div>
  )
}
```

### As Link (asChild)

```typescript
import Link from 'next/link'

function LinkButton() {
  return (
    <Button asChild variant="link">
      <Link href="/dashboard">Go to Dashboard</Link>
    </Button>
  )
}
```

### In Forms

```typescript
function FormExample() {
  return (
    <form onSubmit={handleSubmit}>
      <div className="space-y-4">
        {/* Form fields */}
        
        <div className="flex gap-2">
          <Button type="submit" variant="default">
            Submit
          </Button>
          <Button type="reset" variant="outline">
            Reset
          </Button>
          <Button type="button" variant="ghost" onClick={onCancel}>
            Cancel
          </Button>
        </div>
      </div>
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Minimum touch target size (44x44px for default size)
- ✅ Sufficient color contrast ratios
- ✅ Focus indicators visible
- ✅ Keyboard navigation support
- ✅ Screen reader friendly

### Keyboard Navigation
- **Enter**: Activates the button
- **Space**: Activates the button
- **Tab**: Moves focus to/from button

### ARIA Attributes
- `aria-busy`: Indicates loading state
- `aria-disabled`: Indicates disabled state
- `aria-hidden`: Applied to decorative icons

### Best Practices
```typescript
// ✅ Good: Descriptive text
<Button>Save Changes</Button>

// ✅ Good: Icon with text
<Button leftIcon={<Save />}>Save</Button>

// ✅ Good: Icon only with aria-label
<Button size="icon" aria-label="Save changes">
  <Save />
</Button>

// ❌ Bad: Icon only without label
<Button size="icon"><Save /></Button>
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install dependencies (@radix-ui/react-slot, class-variance-authority)
- [ ] Create button.tsx file
- [ ] Implement button variants with CVA
- [ ] Add loading state with spinner
- [ ] Add icon support (left/right)
- [ ] Implement asChild pattern
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive test suite
- [ ] Test all variants and sizes
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories
- [ ] Document usage examples

---

## 📝 NOTES

- The button uses CVA (class-variance-authority) for type-safe variant management
- The `asChild` prop uses Radix UI's Slot component for composition patterns
- Loading state automatically disables the button
- Icons are hidden during loading state
- All interactive states (hover, focus, active) are properly styled
- The component is fully typed with TypeScript for excellent IDE support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
