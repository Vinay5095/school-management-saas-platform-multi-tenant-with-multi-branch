# SPEC-054: Checkbox Component
## Accessible Checkbox with Group Support

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 3 hours  
> **Dependencies**: Radix UI Checkbox, React Hook Form, Zod

---

## 📋 OVERVIEW

### Purpose
A fully accessible checkbox component supporting:
- Single checkbox
- Checkbox groups
- Indeterminate state
- Custom labels and descriptions
- Form integration

### Key Features
- ✅ Checked/unchecked/indeterminate states
- ✅ Checkbox groups with "select all"
- ✅ Custom styling variants
- ✅ Disabled state
- ✅ Error handling
- ✅ Keyboard navigation
- ✅ WCAG 2.1 AA compliant
- ✅ React Hook Form integration

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/checkbox.tsx
'use client'

import * as React from 'react'
import * as CheckboxPrimitive from '@radix-ui/react-checkbox'
import { Check, Minus } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface CheckboxProps
  extends React.ComponentPropsWithoutRef<typeof CheckboxPrimitive.Root> {
  label?: string
  description?: string
  error?: string
  indeterminate?: boolean
}

export interface CheckboxGroupOption {
  value: string
  label: string
  description?: string
  disabled?: boolean
}

export interface CheckboxGroupProps {
  options: CheckboxGroupOption[]
  value?: string[]
  defaultValue?: string[]
  onValueChange?: (value: string[]) => void
  label?: string
  description?: string
  error?: string
  disabled?: boolean
  required?: boolean
  orientation?: 'horizontal' | 'vertical'
  selectAll?: boolean
  selectAllLabel?: string
  className?: string
}

// ========================================
// SINGLE CHECKBOX
// ========================================

const Checkbox = React.forwardRef<
  React.ElementRef<typeof CheckboxPrimitive.Root>,
  CheckboxProps
>(({ className, label, description, error, indeterminate, ...props }, ref) => {
  return (
    <div className="space-y-1">
      <div className="flex items-start gap-3">
        <CheckboxPrimitive.Root
          ref={ref}
          className={cn(
            'peer h-4 w-4 shrink-0 rounded-sm border border-primary ring-offset-background',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
            'disabled:cursor-not-allowed disabled:opacity-50',
            'data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground',
            error && 'border-error-500 focus-visible:ring-error-500',
            className
          )}
          {...props}
        >
          <CheckboxPrimitive.Indicator
            className={cn('flex items-center justify-center text-current')}
          >
            {indeterminate ? (
              <Minus className="h-4 w-4" />
            ) : (
              <Check className="h-4 w-4" />
            )}
          </CheckboxPrimitive.Indicator>
        </CheckboxPrimitive.Root>

        {(label || description) && (
          <div className="grid gap-1.5 leading-none">
            {label && (
              <label
                htmlFor={props.id}
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                {label}
                {props.required && <span className="text-error-500 ml-1">*</span>}
              </label>
            )}
            {description && (
              <p className="text-sm text-muted-foreground">{description}</p>
            )}
          </div>
        )}
      </div>

      {error && (
        <p className="text-sm text-error-500" role="alert">
          {error}
        </p>
      )}
    </div>
  )
})

Checkbox.displayName = CheckboxPrimitive.Root.displayName

// ========================================
// CHECKBOX GROUP
// ========================================

const CheckboxGroup = React.forwardRef<HTMLDivElement, CheckboxGroupProps>(
  (
    {
      options,
      value,
      defaultValue = [],
      onValueChange,
      label,
      description,
      error,
      disabled = false,
      required = false,
      orientation = 'vertical',
      selectAll = false,
      selectAllLabel = 'Select All',
      className,
    },
    ref
  ) => {
    const [internalValue, setInternalValue] = React.useState<string[]>(defaultValue)
    const currentValue = value !== undefined ? value : internalValue

    // Handle individual checkbox change
    const handleCheckboxChange = (optionValue: string, checked: boolean) => {
      const newValue = checked
        ? [...currentValue, optionValue]
        : currentValue.filter(v => v !== optionValue)

      setInternalValue(newValue)
      onValueChange?.(newValue)
    }

    // Handle select all
    const handleSelectAll = (checked: boolean) => {
      const newValue = checked
        ? options.filter(opt => !opt.disabled).map(opt => opt.value)
        : []

      setInternalValue(newValue)
      onValueChange?.(newValue)
    }

    // Check if all are selected
    const allSelected = options
      .filter(opt => !opt.disabled)
      .every(opt => currentValue.includes(opt.value))

    // Check if some are selected
    const someSelected = currentValue.length > 0 && !allSelected

    return (
      <div ref={ref} className={cn('space-y-3', className)}>
        {/* Group Label */}
        {label && (
          <div className="space-y-1">
            <label className="text-sm font-medium leading-none">
              {label}
              {required && <span className="text-error-500 ml-1">*</span>}
            </label>
            {description && (
              <p className="text-sm text-muted-foreground">{description}</p>
            )}
          </div>
        )}

        {/* Select All */}
        {selectAll && (
          <Checkbox
            checked={allSelected}
            indeterminate={someSelected}
            onCheckedChange={handleSelectAll}
            label={selectAllLabel}
            disabled={disabled}
          />
        )}

        {/* Options */}
        <div
          className={cn(
            'space-y-3',
            orientation === 'horizontal' && 'flex flex-wrap gap-4 space-y-0'
          )}
          role="group"
          aria-label={label}
        >
          {options.map((option) => (
            <Checkbox
              key={option.value}
              id={option.value}
              checked={currentValue.includes(option.value)}
              onCheckedChange={(checked) =>
                handleCheckboxChange(option.value, checked as boolean)
              }
              label={option.label}
              description={option.description}
              disabled={disabled || option.disabled}
            />
          ))}
        </div>

        {/* Error */}
        {error && (
          <p className="text-sm text-error-500" role="alert">
            {error}
          </p>
        )}
      </div>
    )
  }
)

CheckboxGroup.displayName = 'CheckboxGroup'

export { Checkbox, CheckboxGroup }
```

---

## ✅ TESTING

```typescript
// src/components/ui/__tests__/checkbox.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Checkbox, CheckboxGroup } from '../checkbox'

describe('Checkbox Component', () => {
  describe('Single Checkbox', () => {
    it('renders correctly', () => {
      render(<Checkbox label="Accept terms" />)
      expect(screen.getByText('Accept terms')).toBeInTheDocument()
    })

    it('toggles checked state', async () => {
      const handleChange = jest.fn()
      render(<Checkbox label="Test" onCheckedChange={handleChange} />)
      
      const checkbox = screen.getByRole('checkbox')
      await userEvent.click(checkbox)
      
      expect(handleChange).toHaveBeenCalledWith(true)
    })

    it('shows indeterminate state', () => {
      render(<Checkbox label="Test" indeterminate checked />)
      expect(screen.getByRole('checkbox')).toHaveAttribute('data-state', 'checked')
    })

    it('respects disabled state', () => {
      render(<Checkbox label="Test" disabled />)
      expect(screen.getByRole('checkbox')).toBeDisabled()
    })

    it('shows error message', () => {
      render(<Checkbox label="Test" error="This field is required" />)
      expect(screen.getByRole('alert')).toHaveTextContent('This field is required')
    })

    it('shows description', () => {
      render(<Checkbox label="Test" description="Additional info" />)
      expect(screen.getByText('Additional info')).toBeInTheDocument()
    })
  })

  describe('CheckboxGroup', () => {
    const options = [
      { value: '1', label: 'Option 1' },
      { value: '2', label: 'Option 2' },
      { value: '3', label: 'Option 3' },
    ]

    it('renders all options', () => {
      render(<CheckboxGroup options={options} />)
      
      expect(screen.getByText('Option 1')).toBeInTheDocument()
      expect(screen.getByText('Option 2')).toBeInTheDocument()
      expect(screen.getByText('Option 3')).toBeInTheDocument()
    })

    it('handles multiple selections', async () => {
      const handleChange = jest.fn()
      render(<CheckboxGroup options={options} onValueChange={handleChange} />)
      
      const checkboxes = screen.getAllByRole('checkbox')
      await userEvent.click(checkboxes[0])
      expect(handleChange).toHaveBeenCalledWith(['1'])
      
      await userEvent.click(checkboxes[1])
      expect(handleChange).toHaveBeenCalledWith(['1', '2'])
    })

    it('handles select all', async () => {
      const handleChange = jest.fn()
      render(
        <CheckboxGroup
          options={options}
          selectAll
          onValueChange={handleChange}
        />
      )
      
      const selectAllCheckbox = screen.getByText('Select All')
      await userEvent.click(selectAllCheckbox)
      
      expect(handleChange).toHaveBeenCalledWith(['1', '2', '3'])
    })

    it('shows indeterminate state for select all', () => {
      render(
        <CheckboxGroup
          options={options}
          selectAll
          defaultValue={['1']}
        />
      )
      
      const selectAllCheckbox = screen.getAllByRole('checkbox')[0]
      expect(selectAllCheckbox).toHaveAttribute('data-state', 'indeterminate')
    })

    it('renders horizontally', () => {
      const { container } = render(
        <CheckboxGroup options={options} orientation="horizontal" />
      )
      
      const group = container.querySelector('[role="group"]')
      expect(group).toHaveClass('flex')
    })
  })

  describe('Accessibility', () => {
    it('supports keyboard navigation', async () => {
      render(<Checkbox label="Test" />)
      const checkbox = screen.getByRole('checkbox')
      
      checkbox.focus()
      await userEvent.keyboard(' ')
      
      expect(checkbox).toBeChecked()
    })

    it('has proper ARIA attributes', () => {
      render(
        <CheckboxGroup
          options={[{ value: '1', label: 'Option 1' }]}
          label="Select options"
        />
      )
      
      const group = screen.getByRole('group')
      expect(group).toHaveAttribute('aria-label', 'Select options')
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Checkbox

```typescript
import { Checkbox } from '@/components/ui/checkbox'

function TermsCheckbox() {
  return (
    <Checkbox
      label="I agree to the terms and conditions"
      description="You must agree to continue"
      required
    />
  )
}
```

### Checkbox Group

```typescript
function SubjectSelection() {
  return (
    <CheckboxGroup
      label="Select subjects"
      description="Choose all subjects you want to enroll in"
      options={[
        { value: 'math', label: 'Mathematics' },
        { value: 'science', label: 'Science' },
        { value: 'english', label: 'English' },
        { value: 'history', label: 'History', disabled: true },
      ]}
      selectAll
      onValueChange={(values) => console.log(values)}
    />
  )
}
```

### With React Hook Form

```typescript
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  terms: z.boolean().refine(val => val === true, 'You must accept terms'),
  interests: z.array(z.string()).min(1, 'Select at least one'),
})

function FormWithCheckbox() {
  const { control, handleSubmit } = useForm({
    resolver: zodResolver(schema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="terms"
        control={control}
        render={({ field, fieldState }) => (
          <Checkbox
            checked={field.value}
            onCheckedChange={field.onChange}
            label="Accept terms"
            error={fieldState.error?.message}
          />
        )}
      />

      <Controller
        name="interests"
        control={control}
        render={({ field, fieldState }) => (
          <CheckboxGroup
            value={field.value}
            onValueChange={field.onChange}
            options={interestOptions}
            error={fieldState.error?.message}
          />
        )}
      />
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

- ✅ WCAG 2.1 AA compliant
- ✅ Keyboard navigation (Space to toggle)
- ✅ Screen reader support
- ✅ Proper checkbox role
- ✅ Focus indicators
- ✅ Error announcements

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-checkbox
- [ ] Create checkbox.tsx component
- [ ] Implement single checkbox
- [ ] Implement checkbox group
- [ ] Add indeterminate state
- [ ] Add select all feature
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
