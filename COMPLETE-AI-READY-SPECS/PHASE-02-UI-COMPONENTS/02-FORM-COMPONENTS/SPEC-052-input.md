# SPEC-052: Input Component
## Versatile Input Component with Advanced Features

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 5 hours  
> **Dependencies**: Lucide React icons

---

## 📋 OVERVIEW

### Purpose
A fully accessible, feature-rich input component that handles all text input scenarios across the platform. Includes support for icons, clear button, password visibility toggle, and comprehensive error handling.

### Key Features
- ✅ All HTML input types supported
- ✅ Left and right icon support
- ✅ Clearable input with X button
- ✅ Password visibility toggle
- ✅ Error state and message display
- ✅ Disabled state styling
- ✅ Character counter option
- ✅ Full keyboard navigation
- ✅ WCAG 2.1 AA compliant
- ✅ React Hook Form compatible

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/input.tsx
'use client'

import * as React from 'react'
import { X, Eye, EyeOff } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  /**
   * Error message to display below the input
   */
  error?: string
  
  /**
   * Icon to display on the left side of the input
   */
  leftIcon?: React.ReactNode
  
  /**
   * Icon to display on the right side of the input
   */
  rightIcon?: React.ReactNode
  
  /**
   * Shows a clear button (X) when input has value
   */
  clearable?: boolean
  
  /**
   * Shows eye icon to toggle password visibility (only for type="password")
   */
  showPasswordToggle?: boolean
  
  /**
   * Callback fired when clear button is clicked
   */
  onClear?: () => void
  
  /**
   * Label for the input field
   */
  label?: string
  
  /**
   * Description text shown below label
   */
  description?: string
  
  /**
   * Shows character counter (requires maxLength prop)
   */
  showCharacterCount?: boolean
}

// ========================================
// INPUT COMPONENT
// ========================================

/**
 * Input Component
 * 
 * A versatile input component with support for icons, clear button,
 * password toggle, and error handling.
 * 
 * @example
 * // Basic input
 * <Input placeholder="Enter your name" />
 * 
 * @example
 * // Input with label and error
 * <Input 
 *   label="Email" 
 *   type="email"
 *   error="Invalid email address"
 * />
 * 
 * @example
 * // Password input with toggle
 * <Input 
 *   type="password"
 *   showPasswordToggle
 *   placeholder="Enter password"
 * />
 * 
 * @example
 * // Clearable input with icon
 * <Input
 *   leftIcon={<Search />}
 *   clearable
 *   placeholder="Search..."
 * />
 */
const Input = React.forwardRef<HTMLInputElement, InputProps>(
  (
    { 
      className, 
      type = 'text', 
      error, 
      leftIcon, 
      rightIcon, 
      clearable, 
      showPasswordToggle, 
      onClear, 
      value,
      label,
      description,
      showCharacterCount,
      maxLength,
      required,
      id,
      ...props 
    }, 
    ref
  ) => {
    // State for password visibility
    const [showPassword, setShowPassword] = React.useState(false)
    const [inputType, setInputType] = React.useState(type)
    const [charCount, setCharCount] = React.useState(0)
    
    // Generate unique ID if not provided
    const inputId = id || React.useId()
    const errorId = `${inputId}-error`
    const descriptionId = `${inputId}-description`
    const countId = `${inputId}-count`

    // Update input type when password toggle changes
    React.useEffect(() => {
      if (type === 'password' && showPasswordToggle) {
        setInputType(showPassword ? 'text' : 'password')
      }
    }, [showPassword, type, showPasswordToggle])

    // Update character count
    React.useEffect(() => {
      if (value) {
        setCharCount(String(value).length)
      } else {
        setCharCount(0)
      }
    }, [value])

    // Handle clear button click
    const handleClear = () => {
      onClear?.()
      // Focus input after clearing
      if (ref && 'current' in ref && ref.current) {
        ref.current.focus()
      }
    }

    // Handle password toggle
    const handlePasswordToggle = () => {
      setShowPassword(!showPassword)
    }

    // Determine if we should show any right-side elements
    const hasRightElements = rightIcon || clearable || (type === 'password' && showPasswordToggle)

    // Build aria-describedby string
    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
      showCharacterCount && maxLength && countId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    return (
      <div className="w-full space-y-2">
        {/* Label and Description */}
        {(label || description) && (
          <div className="space-y-1">
            {label && (
              <label
                htmlFor={inputId}
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                {label}
                {required && <span className="text-destructive ml-1">*</span>}
              </label>
            )}
            {description && (
              <p id={descriptionId} className="text-sm text-muted-foreground">
                {description}
              </p>
            )}
          </div>
        )}

        {/* Input Container */}
        <div className="relative w-full">
          {/* Left Icon */}
          {leftIcon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none">
              <span className="flex h-4 w-4 items-center justify-center">
                {leftIcon}
              </span>
            </div>
          )}
          
          {/* Input Field */}
          <input
            id={inputId}
            type={inputType}
            className={cn(
              'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background',
              'file:border-0 file:bg-transparent file:text-sm file:font-medium',
              'placeholder:text-muted-foreground',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
              'disabled:cursor-not-allowed disabled:opacity-50',
              'transition-colors',
              leftIcon && 'pl-10',
              hasRightElements && 'pr-10',
              error && 'border-destructive focus-visible:ring-destructive',
              className
            )}
            ref={ref}
            value={value}
            maxLength={maxLength}
            aria-invalid={error ? 'true' : 'false'}
            aria-describedby={ariaDescribedBy}
            aria-required={required}
            {...props}
          />

          {/* Right Side Elements */}
          {hasRightElements && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1">
              {/* Clear Button */}
              {clearable && value && (
                <button
                  type="button"
                  onClick={handleClear}
                  className="text-muted-foreground hover:text-foreground transition-colors"
                  aria-label="Clear input"
                  tabIndex={-1}
                >
                  <X className="h-4 w-4" />
                </button>
              )}
              
              {/* Password Toggle */}
              {type === 'password' && showPasswordToggle && (
                <button
                  type="button"
                  onClick={handlePasswordToggle}
                  className="text-muted-foreground hover:text-foreground transition-colors"
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                  aria-pressed={showPassword}
                  tabIndex={-1}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              )}
              
              {/* Right Icon (only if not clearable or password toggle) */}
              {rightIcon && !clearable && !(type === 'password' && showPasswordToggle) && (
                <div className="text-muted-foreground pointer-events-none">
                  <span className="flex h-4 w-4 items-center justify-center">
                    {rightIcon}
                  </span>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Error Message and Character Count */}
        <div className="flex justify-between items-start">
          {error && (
            <p id={errorId} className="text-sm text-destructive" role="alert">
              {error}
            </p>
          )}
          
          {showCharacterCount && maxLength && (
            <p
              id={countId}
              className={cn(
                'text-sm text-muted-foreground ml-auto',
                charCount > maxLength && 'text-destructive'
              )}
            >
              {charCount}/{maxLength}
            </p>
          )}
        </div>
      </div>
    )
  }
)

Input.displayName = 'Input'

export { Input }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/input.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Input } from '../input'
import { Search, Mail } from 'lucide-react'

describe('Input Component', () => {
  describe('Rendering', () => {
    it('renders correctly', () => {
      render(<Input placeholder="Enter text" />)
      expect(screen.getByPlaceholderText('Enter text')).toBeInTheDocument()
    })

    it('renders with label', () => {
      render(<Input label="Username" />)
      expect(screen.getByText('Username')).toBeInTheDocument()
    })

    it('renders with description', () => {
      render(<Input description="Enter your email address" />)
      expect(screen.getByText('Enter your email address')).toBeInTheDocument()
    })

    it('shows required indicator', () => {
      render(<Input label="Email" required />)
      expect(screen.getByText('*')).toBeInTheDocument()
    })
  })

  describe('Input Types', () => {
    it('renders text input by default', () => {
      render(<Input />)
      expect(screen.getByRole('textbox')).toHaveAttribute('type', 'text')
    })

    it('renders email input', () => {
      render(<Input type="email" />)
      expect(screen.getByRole('textbox')).toHaveAttribute('type', 'email')
    })

    it('renders password input', () => {
      render(<Input type="password" />)
      const input = screen.getByRole('textbox')
      expect(input).toHaveAttribute('type', 'password')
    })

    it('renders number input', () => {
      render(<Input type="number" />)
      expect(screen.getByRole('spinbutton')).toHaveAttribute('type', 'number')
    })
  })

  describe('Icons', () => {
    it('renders left icon', () => {
      render(<Input leftIcon={<Search data-testid="search-icon" />} />)
      expect(screen.getByTestId('search-icon')).toBeInTheDocument()
    })

    it('renders right icon', () => {
      render(<Input rightIcon={<Mail data-testid="mail-icon" />} />)
      expect(screen.getByTestId('mail-icon')).toBeInTheDocument()
    })

    it('applies correct padding with left icon', () => {
      render(<Input leftIcon={<Search />} />)
      expect(screen.getByRole('textbox')).toHaveClass('pl-10')
    })

    it('applies correct padding with right icon', () => {
      render(<Input rightIcon={<Mail />} />)
      expect(screen.getByRole('textbox')).toHaveClass('pr-10')
    })
  })

  describe('Clearable', () => {
    it('shows clear button when input has value', () => {
      render(<Input clearable value="test" onChange={() => {}} />)
      expect(screen.getByLabelText('Clear input')).toBeInTheDocument()
    })

    it('does not show clear button when input is empty', () => {
      render(<Input clearable value="" onChange={() => {}} />)
      expect(screen.queryByLabelText('Clear input')).not.toBeInTheDocument()
    })

    it('calls onClear when clear button is clicked', () => {
      const handleClear = jest.fn()
      render(<Input clearable value="test" onClear={handleClear} onChange={() => {}} />)
      
      fireEvent.click(screen.getByLabelText('Clear input'))
      expect(handleClear).toHaveBeenCalledTimes(1)
    })

    it('focuses input after clearing', () => {
      const handleClear = jest.fn()
      render(<Input clearable value="test" onClear={handleClear} onChange={() => {}} />)
      
      const input = screen.getByRole('textbox')
      fireEvent.click(screen.getByLabelText('Clear input'))
      
      expect(document.activeElement).toBe(input)
    })
  })

  describe('Password Toggle', () => {
    it('shows password toggle button', () => {
      render(<Input type="password" showPasswordToggle />)
      expect(screen.getByLabelText('Show password')).toBeInTheDocument()
    })

    it('toggles password visibility', async () => {
      render(<Input type="password" showPasswordToggle />)
      const input = screen.getByRole('textbox')
      const toggleButton = screen.getByLabelText('Show password')
      
      expect(input).toHaveAttribute('type', 'password')
      
      await userEvent.click(toggleButton)
      expect(input).toHaveAttribute('type', 'text')
      expect(screen.getByLabelText('Hide password')).toBeInTheDocument()
      
      await userEvent.click(toggleButton)
      expect(input).toHaveAttribute('type', 'password')
    })
  })

  describe('Error Handling', () => {
    it('displays error message', () => {
      render(<Input error="This field is required" />)
      expect(screen.getByRole('alert')).toHaveTextContent('This field is required')
    })

    it('applies error styling', () => {
      render(<Input error="Error" />)
      expect(screen.getByRole('textbox')).toHaveClass('border-destructive')
    })

    it('sets aria-invalid when error present', () => {
      render(<Input error="Error" />)
      expect(screen.getByRole('textbox')).toHaveAttribute('aria-invalid', 'true')
    })

    it('links error message with input via aria-describedby', () => {
      render(<Input error="Error message" />)
      const input = screen.getByRole('textbox')
      const errorId = input.getAttribute('aria-describedby')
      
      expect(errorId).toBeTruthy()
      expect(screen.getByRole('alert')).toHaveAttribute('id', errorId)
    })
  })

  describe('Character Count', () => {
    it('shows character count when enabled', () => {
      render(<Input showCharacterCount maxLength={100} value="test" onChange={() => {}} />)
      expect(screen.getByText('4/100')).toBeInTheDocument()
    })

    it('updates character count as user types', async () => {
      const { rerender } = render(
        <Input showCharacterCount maxLength={100} value="" onChange={() => {}} />
      )
      expect(screen.getByText('0/100')).toBeInTheDocument()
      
      rerender(<Input showCharacterCount maxLength={100} value="hello" onChange={() => {}} />)
      expect(screen.getByText('5/100')).toBeInTheDocument()
    })

    it('shows error color when exceeding max length', () => {
      render(<Input showCharacterCount maxLength={5} value="toolong" onChange={() => {}} />)
      const count = screen.getByText('7/5')
      expect(count).toHaveClass('text-destructive')
    })
  })

  describe('Disabled State', () => {
    it('respects disabled prop', () => {
      render(<Input disabled />)
      expect(screen.getByRole('textbox')).toBeDisabled()
    })

    it('applies disabled styling', () => {
      render(<Input disabled />)
      expect(screen.getByRole('textbox')).toHaveClass('opacity-50', 'cursor-not-allowed')
    })
  })

  describe('Accessibility', () => {
    it('has proper aria-required attribute', () => {
      render(<Input required />)
      expect(screen.getByRole('textbox')).toHaveAttribute('aria-required', 'true')
    })

    it('links label with input', () => {
      render(<Input label="Email" />)
      const input = screen.getByRole('textbox')
      const label = screen.getByText('Email')
      
      expect(input.id).toBe(label.getAttribute('for'))
    })

    it('includes description in aria-describedby', () => {
      render(<Input description="Helper text" />)
      const input = screen.getByRole('textbox')
      const descriptionId = input.getAttribute('aria-describedby')
      
      expect(screen.getByText('Helper text')).toHaveAttribute('id', descriptionId)
    })

    it('supports keyboard navigation', async () => {
      render(<Input />)
      const input = screen.getByRole('textbox')
      
      await userEvent.tab()
      expect(input).toHaveFocus()
    })
  })

  describe('Value Changes', () => {
    it('handles controlled input', async () => {
      const handleChange = jest.fn()
      render(<Input value="test" onChange={handleChange} />)
      
      await userEvent.type(screen.getByRole('textbox'), 'a')
      expect(handleChange).toHaveBeenCalled()
    })

    it('respects maxLength', async () => {
      render(<Input maxLength={5} />)
      const input = screen.getByRole('textbox')
      
      await userEvent.type(input, '123456')
      expect(input).toHaveValue('12345')
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Input

```typescript
import { Input } from '@/components/ui/input'

function BasicExample() {
  return (
    <Input
      label="Full Name"
      placeholder="Enter your full name"
      required
    />
  )
}
```

### With Icons

```typescript
import { Search, Mail, Phone } from 'lucide-react'

function IconExamples() {
  return (
    <div className="space-y-4">
      <Input
        leftIcon={<Search className="h-4 w-4" />}
        placeholder="Search..."
      />
      
      <Input
        leftIcon={<Mail className="h-4 w-4" />}
        type="email"
        placeholder="Email address"
      />
      
      <Input
        leftIcon={<Phone className="h-4 w-4" />}
        type="tel"
        placeholder="Phone number"
      />
    </div>
  )
}
```

### Password Input

```typescript
function PasswordExample() {
  return (
    <Input
      type="password"
      label="Password"
      placeholder="Enter your password"
      showPasswordToggle
      required
    />
  )
}
```

### Clearable Input

```typescript
function SearchInput() {
  const [value, setValue] = React.useState('')

  return (
    <Input
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onClear={() => setValue('')}
      leftIcon={<Search className="h-4 w-4" />}
      clearable
      placeholder="Search..."
    />
  )
}
```

### With Error

```typescript
function FormInput() {
  const [error, setError] = React.useState('')

  const validate = (value: string) => {
    if (!value) {
      setError('This field is required')
    } else if (!value.includes('@')) {
      setError('Invalid email address')
    } else {
      setError('')
    }
  }

  return (
    <Input
      label="Email"
      type="email"
      onChange={(e) => validate(e.target.value)}
      error={error}
      required
    />
  )
}
```

### With Character Count

```typescript
function BioInput() {
  const [value, setValue] = React.useState('')

  return (
    <Input
      label="Bio"
      description="Tell us about yourself"
      value={value}
      onChange={(e) => setValue(e.target.value)}
      maxLength={160}
      showCharacterCount
      placeholder="Write a short bio..."
    />
  )
}
```

### With React Hook Form

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'At least 8 characters'),
})

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Input
        {...register('email')}
        label="Email"
        type="email"
        error={errors.email?.message}
      />
      
      <Input
        {...register('password')}
        label="Password"
        type="password"
        showPasswordToggle
        error={errors.password?.message}
      />
      
      <Button type="submit">Login</Button>
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Sufficient color contrast
- ✅ Focus indicators visible
- ✅ Keyboard navigation support
- ✅ Screen reader friendly
- ✅ Error messages announced

### Keyboard Navigation
- **Tab**: Moves focus to input
- **Shift+Tab**: Moves focus away
- Icons and buttons have `tabIndex={-1}` to keep focus on input

### ARIA Attributes
- `aria-invalid`: Indicates error state
- `aria-describedby`: Links to description and error
- `aria-required`: Indicates required field
- `aria-label`: Applied to icon buttons

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install lucide-react for icons
- [ ] Create input.tsx file
- [ ] Implement base input component
- [ ] Add icon support (left/right)
- [ ] Add clearable functionality
- [ ] Add password toggle
- [ ] Add character counter
- [ ] Add error handling
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
