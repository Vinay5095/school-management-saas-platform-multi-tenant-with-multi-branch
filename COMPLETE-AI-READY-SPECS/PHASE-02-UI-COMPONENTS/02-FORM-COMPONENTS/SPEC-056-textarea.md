# SPEC-056: Textarea Component
## Multi-line Text Input with Auto-resize

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4 hours  
> **Dependencies**: None (native HTML)

---

## 📋 OVERVIEW

### Purpose
A fully accessible, feature-rich textarea component for multi-line text input. Includes auto-resize functionality, character counter, error handling, and comprehensive styling options.

### Key Features
- ✅ Auto-resize based on content
- ✅ Character counter with max length
- ✅ Error state and message display
- ✅ Resizable or fixed height
- ✅ Label and description support
- ✅ Disabled state styling
- ✅ Min/max rows configuration
- ✅ Full keyboard navigation
- ✅ WCAG 2.1 AA compliant
- ✅ React Hook Form compatible

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/textarea.tsx
'use client'

import * as React from 'react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  /**
   * Error message to display below the textarea
   */
  error?: string
  
  /**
   * Label for the textarea field
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
  
  /**
   * Enable auto-resize based on content
   */
  autoResize?: boolean
  
  /**
   * Minimum number of rows (for auto-resize)
   */
  minRows?: number
  
  /**
   * Maximum number of rows (for auto-resize)
   */
  maxRows?: number
  
  /**
   * Whether the field is resizable by the user
   * @default 'vertical'
   */
  resize?: 'none' | 'vertical' | 'horizontal' | 'both'
}

// ========================================
// TEXTAREA COMPONENT
// ========================================

/**
 * Textarea Component
 * 
 * A versatile multi-line text input with auto-resize, character counter,
 * and error handling.
 * 
 * @example
 * // Basic textarea
 * <Textarea placeholder="Enter your message" />
 * 
 * @example
 * // With auto-resize
 * <Textarea 
 *   autoResize 
 *   minRows={3}
 *   maxRows={10}
 *   placeholder="This will grow as you type"
 * />
 * 
 * @example
 * // With character count
 * <Textarea
 *   label="Bio"
 *   maxLength={500}
 *   showCharacterCount
 *   placeholder="Tell us about yourself"
 * />
 */
const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  (
    {
      className,
      error,
      label,
      description,
      showCharacterCount,
      autoResize,
      minRows = 3,
      maxRows,
      resize = 'vertical',
      value,
      onChange,
      required,
      maxLength,
      rows,
      id,
      ...props
    },
    ref
  ) => {
    const textareaRef = React.useRef<HTMLTextAreaElement | null>(null)
    const [charCount, setCharCount] = React.useState(0)
    
    // Generate unique ID if not provided
    const textareaId = id || React.useId()
    const errorId = `${textareaId}-error`
    const descriptionId = `${textareaId}-description`
    const countId = `${textareaId}-count`

    // Update character count
    React.useEffect(() => {
      if (value !== undefined) {
        setCharCount(String(value).length)
      }
    }, [value])

    // Auto-resize functionality
    const adjustHeight = React.useCallback(() => {
      const textarea = textareaRef.current
      if (!textarea || !autoResize) return

      // Reset height to calculate new height
      textarea.style.height = 'auto'

      // Calculate new height
      const newHeight = textarea.scrollHeight
      
      // Apply min/max constraints
      const lineHeight = parseInt(getComputedStyle(textarea).lineHeight)
      const minHeight = minRows * lineHeight
      const maxHeight = maxRows ? maxRows * lineHeight : Infinity

      const constrainedHeight = Math.min(Math.max(newHeight, minHeight), maxHeight)
      
      textarea.style.height = `${constrainedHeight}px`
    }, [autoResize, minRows, maxRows])

    // Adjust height when value changes
    React.useEffect(() => {
      adjustHeight()
    }, [value, adjustHeight])

    // Adjust height on mount
    React.useEffect(() => {
      adjustHeight()
    }, [adjustHeight])

    // Handle change event
    const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      onChange?.(e)
      if (autoResize) {
        adjustHeight()
      }
    }

    // Combine refs
    const setRefs = React.useCallback(
      (node: HTMLTextAreaElement | null) => {
        textareaRef.current = node
        if (typeof ref === 'function') {
          ref(node)
        } else if (ref) {
          ref.current = node
        }
      },
      [ref]
    )

    // Build aria-describedby string
    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
      showCharacterCount && maxLength && countId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    // Determine resize style
    const resizeClass = {
      none: 'resize-none',
      vertical: 'resize-y',
      horizontal: 'resize-x',
      both: 'resize',
    }[resize]

    return (
      <div className="w-full space-y-2">
        {/* Label and Description */}
        {(label || description) && (
          <div className="space-y-1">
            {label && (
              <label
                htmlFor={textareaId}
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

        {/* Textarea Field */}
        <textarea
          id={textareaId}
          ref={setRefs}
          className={cn(
            'flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm',
            'ring-offset-background placeholder:text-muted-foreground',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
            'disabled:cursor-not-allowed disabled:opacity-50',
            'transition-colors',
            error && 'border-destructive focus-visible:ring-destructive',
            autoResize && 'overflow-hidden',
            resizeClass,
            className
          )}
          rows={autoResize ? undefined : (rows || minRows)}
          value={value}
          onChange={handleChange}
          maxLength={maxLength}
          aria-invalid={error ? 'true' : 'false'}
          aria-describedby={ariaDescribedBy}
          aria-required={required}
          {...props}
        />

        {/* Error Message and Character Count */}
        <div className="flex justify-between items-start gap-2">
          {error && (
            <p id={errorId} className="text-sm text-destructive" role="alert">
              {error}
            </p>
          )}
          
          {showCharacterCount && maxLength && (
            <p
              id={countId}
              className={cn(
                'text-sm text-muted-foreground ml-auto shrink-0',
                charCount > maxLength && 'text-destructive',
                charCount > maxLength * 0.9 && charCount <= maxLength && 'text-warning'
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

Textarea.displayName = 'Textarea'

export { Textarea }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/textarea.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Textarea } from '../textarea'

describe('Textarea Component', () => {
  describe('Rendering', () => {
    it('renders correctly', () => {
      render(<Textarea placeholder="Enter text" />)
      expect(screen.getByPlaceholderText('Enter text')).toBeInTheDocument()
    })

    it('renders with label', () => {
      render(<Textarea label="Message" />)
      expect(screen.getByText('Message')).toBeInTheDocument()
    })

    it('renders with description', () => {
      render(<Textarea description="Enter your message here" />)
      expect(screen.getByText('Enter your message here')).toBeInTheDocument()
    })

    it('shows required indicator', () => {
      render(<Textarea label="Required Field" required />)
      expect(screen.getByText('*')).toBeInTheDocument()
    })
  })

  describe('Rows Configuration', () => {
    it('uses default rows when not specified', () => {
      render(<Textarea />)
      const textarea = screen.getByRole('textbox')
      expect(textarea).toHaveAttribute('rows', '3')
    })

    it('respects custom rows prop', () => {
      render(<Textarea rows={5} />)
      expect(screen.getByRole('textbox')).toHaveAttribute('rows', '5')
    })

    it('uses minRows as default rows', () => {
      render(<Textarea minRows={4} />)
      expect(screen.getByRole('textbox')).toHaveAttribute('rows', '4')
    })
  })

  describe('Character Count', () => {
    it('shows character count when enabled', () => {
      render(
        <Textarea
          showCharacterCount
          maxLength={100}
          value="Hello"
          onChange={() => {}}
        />
      )
      expect(screen.getByText('5/100')).toBeInTheDocument()
    })

    it('updates character count as user types', async () => {
      const { rerender } = render(
        <Textarea
          showCharacterCount
          maxLength={100}
          value=""
          onChange={() => {}}
        />
      )
      expect(screen.getByText('0/100')).toBeInTheDocument()

      rerender(
        <Textarea
          showCharacterCount
          maxLength={100}
          value="Hello World"
          onChange={() => {}}
        />
      )
      expect(screen.getByText('11/100')).toBeInTheDocument()
    })

    it('shows error color when exceeding max length', () => {
      render(
        <Textarea
          showCharacterCount
          maxLength={10}
          value="This is too long"
          onChange={() => {}}
        />
      )
      const count = screen.getByText('16/10')
      expect(count).toHaveClass('text-destructive')
    })

    it('does not show character count when disabled', () => {
      render(<Textarea maxLength={100} value="test" onChange={() => {}} />)
      expect(screen.queryByText('4/100')).not.toBeInTheDocument()
    })
  })

  describe('Auto-resize', () => {
    it('enables auto-resize when prop is true', () => {
      render(<Textarea autoResize />)
      expect(screen.getByRole('textbox')).toHaveClass('overflow-hidden')
    })

    it('does not set rows attribute when auto-resize enabled', () => {
      render(<Textarea autoResize />)
      expect(screen.getByRole('textbox')).not.toHaveAttribute('rows')
    })

    it('adjusts height when content changes', async () => {
      const { rerender } = render(
        <Textarea autoResize value="" onChange={() => {}} />
      )
      const textarea = screen.getByRole('textbox') as HTMLTextAreaElement
      const initialHeight = textarea.style.height

      rerender(
        <Textarea
          autoResize
          value="Line 1\nLine 2\nLine 3\nLine 4\nLine 5"
          onChange={() => {}}
        />
      )

      await waitFor(() => {
        expect(textarea.style.height).not.toBe(initialHeight)
      })
    })
  })

  describe('Resize Options', () => {
    it('allows vertical resize by default', () => {
      render(<Textarea />)
      expect(screen.getByRole('textbox')).toHaveClass('resize-y')
    })

    it('disables resize when set to none', () => {
      render(<Textarea resize="none" />)
      expect(screen.getByRole('textbox')).toHaveClass('resize-none')
    })

    it('allows horizontal resize', () => {
      render(<Textarea resize="horizontal" />)
      expect(screen.getByRole('textbox')).toHaveClass('resize-x')
    })

    it('allows both resize directions', () => {
      render(<Textarea resize="both" />)
      expect(screen.getByRole('textbox')).toHaveClass('resize')
    })
  })

  describe('Error Handling', () => {
    it('displays error message', () => {
      render(<Textarea error="This field is required" />)
      expect(screen.getByRole('alert')).toHaveTextContent('This field is required')
    })

    it('applies error styling', () => {
      render(<Textarea error="Error" />)
      expect(screen.getByRole('textbox')).toHaveClass('border-destructive')
    })

    it('sets aria-invalid when error present', () => {
      render(<Textarea error="Error" />)
      expect(screen.getByRole('textbox')).toHaveAttribute('aria-invalid', 'true')
    })

    it('links error message with textarea via aria-describedby', () => {
      render(<Textarea error="Error message" />)
      const textarea = screen.getByRole('textbox')
      const errorId = textarea.getAttribute('aria-describedby')

      expect(errorId).toBeTruthy()
      expect(screen.getByRole('alert')).toHaveAttribute('id', expect.stringContaining('-error'))
    })
  })

  describe('Disabled State', () => {
    it('respects disabled prop', () => {
      render(<Textarea disabled />)
      expect(screen.getByRole('textbox')).toBeDisabled()
    })

    it('applies disabled styling', () => {
      render(<Textarea disabled />)
      expect(screen.getByRole('textbox')).toHaveClass('opacity-50', 'cursor-not-allowed')
    })
  })

  describe('Value Changes', () => {
    it('handles controlled textarea', async () => {
      const handleChange = jest.fn()
      render(<Textarea value="test" onChange={handleChange} />)

      const textarea = screen.getByRole('textbox')
      await userEvent.type(textarea, 'a')

      expect(handleChange).toHaveBeenCalled()
    })

    it('respects maxLength', async () => {
      render(<Textarea maxLength={10} />)
      const textarea = screen.getByRole('textbox') as HTMLTextAreaElement

      await userEvent.type(textarea, '12345678901234')

      expect(textarea.value.length).toBeLessThanOrEqual(10)
    })
  })

  describe('Accessibility', () => {
    it('has proper aria-required attribute', () => {
      render(<Textarea required />)
      expect(screen.getByRole('textbox')).toHaveAttribute('aria-required', 'true')
    })

    it('links label with textarea', () => {
      render(<Textarea label="Message" />)
      const textarea = screen.getByRole('textbox')
      const label = screen.getByText('Message')

      expect(textarea.id).toBe(label.getAttribute('for'))
    })

    it('includes description in aria-describedby', () => {
      render(<Textarea description="Helper text" />)
      const textarea = screen.getByRole('textbox')
      const descriptionId = textarea.getAttribute('aria-describedby')

      expect(descriptionId).toBeTruthy()
      expect(screen.getByText('Helper text')).toHaveAttribute('id', expect.stringContaining('-description'))
    })

    it('supports keyboard navigation', async () => {
      render(<Textarea />)
      const textarea = screen.getByRole('textbox')

      await userEvent.tab()
      expect(textarea).toHaveFocus()
    })

    it('allows text entry via keyboard', async () => {
      render(<Textarea />)
      const textarea = screen.getByRole('textbox')

      await userEvent.type(textarea, 'Hello World')
      expect(textarea).toHaveValue('Hello World')
    })
  })

  describe('Focus Behavior', () => {
    it('shows focus ring on focus', () => {
      render(<Textarea />)
      const textarea = screen.getByRole('textbox')

      expect(textarea).toHaveClass('focus-visible:ring-2')
    })

    it('can be focused programmatically', () => {
      const ref = React.createRef<HTMLTextAreaElement>()
      render(<Textarea ref={ref} />)

      ref.current?.focus()
      expect(ref.current).toHaveFocus()
    })
  })

  describe('Custom className', () => {
    it('applies custom className', () => {
      render(<Textarea className="custom-class" />)
      expect(screen.getByRole('textbox')).toHaveClass('custom-class')
    })

    it('merges custom className with default classes', () => {
      render(<Textarea className="custom-class" />)
      const textarea = screen.getByRole('textbox')

      expect(textarea).toHaveClass('custom-class')
      expect(textarea).toHaveClass('rounded-md')
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Textarea

```typescript
import { Textarea } from '@/components/ui/textarea'

function BasicExample() {
  return (
    <Textarea
      label="Message"
      placeholder="Enter your message"
      rows={4}
    />
  )
}
```

### With Auto-resize

```typescript
function AutoResizeExample() {
  const [value, setValue] = React.useState('')

  return (
    <Textarea
      label="Comment"
      description="Your comment will expand as you type"
      autoResize
      minRows={3}
      maxRows={10}
      value={value}
      onChange={(e) => setValue(e.target.value)}
      placeholder="Start typing..."
    />
  )
}
```

### With Character Count

```typescript
function BioTextarea() {
  const [bio, setBio] = React.useState('')

  return (
    <Textarea
      label="Bio"
      description="Tell us about yourself"
      value={bio}
      onChange={(e) => setBio(e.target.value)}
      maxLength={500}
      showCharacterCount
      autoResize
      minRows={4}
      placeholder="Write your bio here..."
    />
  )
}
```

### With Error State

```typescript
function FeedbackForm() {
  const [feedback, setFeedback] = React.useState('')
  const [error, setError] = React.useState('')

  const handleSubmit = () => {
    if (feedback.length < 10) {
      setError('Feedback must be at least 10 characters')
      return
    }
    setError('')
    // Submit logic
  }

  return (
    <div className="space-y-4">
      <Textarea
        label="Feedback"
        description="Share your thoughts with us"
        value={feedback}
        onChange={(e) => {
          setFeedback(e.target.value)
          setError('')
        }}
        error={error}
        required
        rows={6}
      />
      <Button onClick={handleSubmit}>Submit Feedback</Button>
    </div>
  )
}
```

### Non-resizable

```typescript
function FixedTextarea() {
  return (
    <Textarea
      label="Notes"
      placeholder="Add your notes"
      rows={8}
      resize="none"
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
  description: z.string()
    .min(10, 'Description must be at least 10 characters')
    .max(500, 'Description must not exceed 500 characters'),
})

function DescriptionForm() {
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { description: '' },
  })

  const description = watch('description')

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Textarea
        {...register('description')}
        label="Description"
        description="Provide a detailed description"
        error={errors.description?.message}
        value={description}
        maxLength={500}
        showCharacterCount
        autoResize
        minRows={4}
        maxRows={12}
        required
      />
      <Button type="submit">Save</Button>
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
- **Tab**: Moves focus to textarea
- **Shift+Tab**: Moves focus away
- **All typing keys**: Input text
- **Enter**: New line

### ARIA Attributes
- `aria-invalid`: Indicates error state
- `aria-describedby`: Links to description and error
- `aria-required`: Indicates required field
- `role="alert"`: Applied to error messages

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create textarea.tsx file
- [ ] Implement base textarea component
- [ ] Add auto-resize functionality
- [ ] Add character counter
- [ ] Add resize options
- [ ] Add error handling
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test auto-resize behavior
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories
- [ ] Document usage examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
