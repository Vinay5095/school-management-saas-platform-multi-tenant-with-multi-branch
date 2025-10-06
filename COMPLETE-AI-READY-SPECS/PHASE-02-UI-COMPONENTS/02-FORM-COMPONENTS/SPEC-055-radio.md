# SPEC-055: Radio Component
## Radio Button and Radio Group Components

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5 hours  
> **Dependencies**: Radix UI Radio, React Hook Form

---

## 📋 OVERVIEW

### Purpose
Accessible radio button components for single-choice selection scenarios. Includes both individual Radio component and RadioGroup wrapper for managing collections of radio options.

### Key Features
- ✅ Single and grouped radio buttons
- ✅ Horizontal and vertical layouts
- ✅ Custom labels and descriptions
- ✅ Disabled state support
- ✅ Error state handling
- ✅ Keyboard navigation (Arrow keys)
- ✅ React Hook Form integration
- ✅ WCAG 2.1 AA compliant
- ✅ Custom radio indicators

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/radio.tsx
'use client'

import * as React from 'react'
import * as RadioGroupPrimitive from '@radix-ui/react-radio-group'
import { Circle } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface RadioOption {
  /**
   * Unique value for the radio option
   */
  value: string
  
  /**
   * Label text for the radio option
   */
  label: string
  
  /**
   * Optional description shown below the label
   */
  description?: string
  
  /**
   * Whether this option is disabled
   */
  disabled?: boolean
  
  /**
   * Optional icon to display before the label
   */
  icon?: React.ReactNode
}

export interface RadioGroupProps {
  /**
   * Array of radio options
   */
  options: RadioOption[]
  
  /**
   * Currently selected value
   */
  value?: string
  
  /**
   * Callback fired when value changes
   */
  onValueChange?: (value: string) => void
  
  /**
   * Label for the radio group
   */
  label?: string
  
  /**
   * Description text shown below label
   */
  description?: string
  
  /**
   * Error message to display
   */
  error?: string
  
  /**
   * Layout orientation
   */
  orientation?: 'horizontal' | 'vertical'
  
  /**
   * Whether the field is required
   */
  required?: boolean
  
  /**
   * Disable all radio options
   */
  disabled?: boolean
  
  /**
   * Additional CSS classes
   */
  className?: string
  
  /**
   * Name attribute for form submission
   */
  name?: string
}

// ========================================
// RADIO COMPONENT (Individual)
// ========================================

const Radio = React.forwardRef<
  React.ElementRef<typeof RadioGroupPrimitive.Item>,
  React.ComponentPropsWithoutRef<typeof RadioGroupPrimitive.Item>
>(({ className, ...props }, ref) => {
  return (
    <RadioGroupPrimitive.Item
      ref={ref}
      className={cn(
        'aspect-square h-4 w-4 rounded-full border border-primary text-primary',
        'ring-offset-background focus:outline-none focus-visible:ring-2',
        'focus-visible:ring-ring focus-visible:ring-offset-2',
        'disabled:cursor-not-allowed disabled:opacity-50',
        'transition-all duration-200',
        className
      )}
      {...props}
    >
      <RadioGroupPrimitive.Indicator className="flex items-center justify-center">
        <Circle className="h-2.5 w-2.5 fill-current text-current" />
      </RadioGroupPrimitive.Indicator>
    </RadioGroupPrimitive.Item>
  )
})
Radio.displayName = RadioGroupPrimitive.Item.displayName

// ========================================
// RADIO GROUP COMPONENT
// ========================================

/**
 * RadioGroup Component
 * 
 * A group of radio buttons for single-choice selection.
 * Supports horizontal and vertical layouts, custom descriptions,
 * and full accessibility.
 * 
 * @example
 * // Basic usage
 * <RadioGroup
 *   label="Choose a plan"
 *   options={[
 *     { value: 'free', label: 'Free' },
 *     { value: 'pro', label: 'Pro' },
 *     { value: 'enterprise', label: 'Enterprise' }
 *   ]}
 *   value={plan}
 *   onValueChange={setPlan}
 * />
 * 
 * @example
 * // With descriptions
 * <RadioGroup
 *   label="Notification Preference"
 *   options={[
 *     {
 *       value: 'all',
 *       label: 'All notifications',
 *       description: 'Receive all updates and messages'
 *     },
 *     {
 *       value: 'important',
 *       label: 'Important only',
 *       description: 'Only critical notifications'
 *     }
 *   ]}
 * />
 */
const RadioGroup = React.forwardRef<
  React.ElementRef<typeof RadioGroupPrimitive.Root>,
  RadioGroupProps
>(
  (
    {
      options,
      value,
      onValueChange,
      label,
      description,
      error,
      orientation = 'vertical',
      required,
      disabled,
      className,
      name,
      ...props
    },
    ref
  ) => {
    const groupId = React.useId()
    const errorId = `${groupId}-error`
    const descriptionId = `${groupId}-description`

    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    return (
      <div className={cn('space-y-3', className)}>
        {/* Label and Description */}
        {(label || description) && (
          <div className="space-y-1">
            {label && (
              <label
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                id={`${groupId}-label`}
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

        {/* Radio Group */}
        <RadioGroupPrimitive.Root
          ref={ref}
          value={value}
          onValueChange={onValueChange}
          disabled={disabled}
          name={name}
          aria-labelledby={label ? `${groupId}-label` : undefined}
          aria-describedby={ariaDescribedBy}
          aria-required={required}
          aria-invalid={error ? 'true' : 'false'}
          orientation={orientation}
          className={cn(
            'grid gap-3',
            orientation === 'horizontal' && 'grid-flow-col auto-cols-fr',
            orientation === 'vertical' && 'grid-flow-row'
          )}
          {...props}
        >
          {options.map((option) => (
            <div
              key={option.value}
              className={cn(
                'flex items-start space-x-3 rounded-lg border border-input p-4',
                'transition-colors hover:bg-accent/50',
                value === option.value && 'border-primary bg-accent',
                (disabled || option.disabled) && 'opacity-50 cursor-not-allowed',
                error && 'border-destructive'
              )}
            >
              <Radio
                value={option.value}
                id={`${groupId}-${option.value}`}
                disabled={disabled || option.disabled}
                className="mt-0.5"
              />
              
              <div className="flex-1 space-y-1">
                <label
                  htmlFor={`${groupId}-${option.value}`}
                  className={cn(
                    'text-sm font-medium leading-none cursor-pointer',
                    'peer-disabled:cursor-not-allowed peer-disabled:opacity-70'
                  )}
                >
                  <div className="flex items-center gap-2">
                    {option.icon && (
                      <span className="flex items-center">{option.icon}</span>
                    )}
                    {option.label}
                  </div>
                </label>
                
                {option.description && (
                  <p className="text-sm text-muted-foreground">
                    {option.description}
                  </p>
                )}
              </div>
            </div>
          ))}
        </RadioGroupPrimitive.Root>

        {/* Error Message */}
        {error && (
          <p id={errorId} className="text-sm text-destructive" role="alert">
            {error}
          </p>
        )}
      </div>
    )
  }
)
RadioGroup.displayName = 'RadioGroup'

export { Radio, RadioGroup }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/radio.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { RadioGroup } from '../radio'
import { Star } from 'lucide-react'

const mockOptions = [
  { value: 'option1', label: 'Option 1' },
  { value: 'option2', label: 'Option 2' },
  { value: 'option3', label: 'Option 3' },
]

const mockOptionsWithDescriptions = [
  {
    value: 'basic',
    label: 'Basic Plan',
    description: 'For individuals',
  },
  {
    value: 'pro',
    label: 'Pro Plan',
    description: 'For teams',
  },
]

describe('RadioGroup Component', () => {
  describe('Rendering', () => {
    it('renders all radio options', () => {
      render(<RadioGroup options={mockOptions} />)
      
      expect(screen.getByLabelText('Option 1')).toBeInTheDocument()
      expect(screen.getByLabelText('Option 2')).toBeInTheDocument()
      expect(screen.getByLabelText('Option 3')).toBeInTheDocument()
    })

    it('renders with label', () => {
      render(<RadioGroup label="Choose an option" options={mockOptions} />)
      expect(screen.getByText('Choose an option')).toBeInTheDocument()
    })

    it('renders with description', () => {
      render(
        <RadioGroup
          description="Select one option from the list"
          options={mockOptions}
        />
      )
      expect(screen.getByText('Select one option from the list')).toBeInTheDocument()
    })

    it('shows required indicator', () => {
      render(<RadioGroup label="Required Field" required options={mockOptions} />)
      expect(screen.getByText('*')).toBeInTheDocument()
    })

    it('renders option descriptions', () => {
      render(<RadioGroup options={mockOptionsWithDescriptions} />)
      
      expect(screen.getByText('For individuals')).toBeInTheDocument()
      expect(screen.getByText('For teams')).toBeInTheDocument()
    })

    it('renders option icons', () => {
      const optionsWithIcons = [
        {
          value: 'premium',
          label: 'Premium',
          icon: <Star data-testid="star-icon" />,
        },
      ]
      
      render(<RadioGroup options={optionsWithIcons} />)
      expect(screen.getByTestId('star-icon')).toBeInTheDocument()
    })
  })

  describe('Layout', () => {
    it('renders vertical layout by default', () => {
      const { container } = render(<RadioGroup options={mockOptions} />)
      const group = container.querySelector('[role="radiogroup"]')
      
      expect(group).toHaveClass('grid-flow-row')
    })

    it('renders horizontal layout', () => {
      const { container } = render(
        <RadioGroup options={mockOptions} orientation="horizontal" />
      )
      const group = container.querySelector('[role="radiogroup"]')
      
      expect(group).toHaveClass('grid-flow-col')
    })
  })

  describe('Selection', () => {
    it('handles value selection', () => {
      const handleChange = jest.fn()
      render(
        <RadioGroup
          options={mockOptions}
          onValueChange={handleChange}
        />
      )
      
      fireEvent.click(screen.getByLabelText('Option 2'))
      expect(handleChange).toHaveBeenCalledWith('option2')
    })

    it('shows selected value', () => {
      const { container } = render(
        <RadioGroup options={mockOptions} value="option2" />
      )
      
      const selectedOption = screen.getByLabelText('Option 2')
      expect(selectedOption).toBeChecked()
    })

    it('allows changing selection', () => {
      const handleChange = jest.fn()
      render(
        <RadioGroup
          options={mockOptions}
          value="option1"
          onValueChange={handleChange}
        />
      )
      
      fireEvent.click(screen.getByLabelText('Option 3'))
      expect(handleChange).toHaveBeenCalledWith('option3')
    })
  })

  describe('Keyboard Navigation', () => {
    it('navigates with arrow keys', async () => {
      render(<RadioGroup options={mockOptions} value="option1" />)
      
      const firstOption = screen.getByLabelText('Option 1')
      firstOption.focus()
      
      await userEvent.keyboard('{ArrowDown}')
      expect(screen.getByLabelText('Option 2')).toHaveFocus()
      
      await userEvent.keyboard('{ArrowDown}')
      expect(screen.getByLabelText('Option 3')).toHaveFocus()
    })

    it('wraps around with arrow navigation', async () => {
      render(<RadioGroup options={mockOptions} value="option3" />)
      
      const lastOption = screen.getByLabelText('Option 3')
      lastOption.focus()
      
      await userEvent.keyboard('{ArrowDown}')
      expect(screen.getByLabelText('Option 1')).toHaveFocus()
    })

    it('navigates backwards with arrow up', async () => {
      render(<RadioGroup options={mockOptions} value="option2" />)
      
      const secondOption = screen.getByLabelText('Option 2')
      secondOption.focus()
      
      await userEvent.keyboard('{ArrowUp}')
      expect(screen.getByLabelText('Option 1')).toHaveFocus()
    })

    it('supports horizontal navigation with left/right arrows', async () => {
      render(
        <RadioGroup
          options={mockOptions}
          value="option1"
          orientation="horizontal"
        />
      )
      
      const firstOption = screen.getByLabelText('Option 1')
      firstOption.focus()
      
      await userEvent.keyboard('{ArrowRight}')
      expect(screen.getByLabelText('Option 2')).toHaveFocus()
      
      await userEvent.keyboard('{ArrowLeft}')
      expect(screen.getByLabelText('Option 1')).toHaveFocus()
    })
  })

  describe('Disabled State', () => {
    it('disables all options when group is disabled', () => {
      render(<RadioGroup options={mockOptions} disabled />)
      
      mockOptions.forEach((option) => {
        expect(screen.getByLabelText(option.label)).toBeDisabled()
      })
    })

    it('disables individual options', () => {
      const optionsWithDisabled = [
        { value: '1', label: 'Option 1' },
        { value: '2', label: 'Option 2', disabled: true },
      ]
      
      render(<RadioGroup options={optionsWithDisabled} />)
      
      expect(screen.getByLabelText('Option 1')).not.toBeDisabled()
      expect(screen.getByLabelText('Option 2')).toBeDisabled()
    })

    it('does not trigger onChange when disabled option clicked', () => {
      const handleChange = jest.fn()
      const optionsWithDisabled = [
        { value: '1', label: 'Option 1', disabled: true },
      ]
      
      render(
        <RadioGroup
          options={optionsWithDisabled}
          onValueChange={handleChange}
        />
      )
      
      fireEvent.click(screen.getByLabelText('Option 1'))
      expect(handleChange).not.toHaveBeenCalled()
    })
  })

  describe('Error Handling', () => {
    it('displays error message', () => {
      render(<RadioGroup options={mockOptions} error="Please select an option" />)
      expect(screen.getByRole('alert')).toHaveTextContent('Please select an option')
    })

    it('applies error styling', () => {
      const { container } = render(
        <RadioGroup options={mockOptions} error="Error" />
      )
      
      const borders = container.querySelectorAll('.border-destructive')
      expect(borders.length).toBeGreaterThan(0)
    })

    it('sets aria-invalid when error present', () => {
      const { container } = render(
        <RadioGroup options={mockOptions} error="Error" />
      )
      
      const group = container.querySelector('[role="radiogroup"]')
      expect(group).toHaveAttribute('aria-invalid', 'true')
    })
  })

  describe('Accessibility', () => {
    it('has proper role', () => {
      const { container } = render(<RadioGroup options={mockOptions} />)
      expect(container.querySelector('[role="radiogroup"]')).toBeInTheDocument()
    })

    it('links label with radio group', () => {
      const { container } = render(
        <RadioGroup label="Choose option" options={mockOptions} />
      )
      
      const group = container.querySelector('[role="radiogroup"]')
      const labelId = group?.getAttribute('aria-labelledby')
      
      expect(labelId).toBeTruthy()
      expect(screen.getByText('Choose option')).toHaveAttribute('id', labelId)
    })

    it('links description via aria-describedby', () => {
      const { container } = render(
        <RadioGroup
          description="Helper text"
          options={mockOptions}
        />
      )
      
      const group = container.querySelector('[role="radiogroup"]')
      const describedBy = group?.getAttribute('aria-describedby')
      
      expect(describedBy).toBeTruthy()
      expect(screen.getByText('Helper text')).toHaveAttribute('id', describedBy)
    })

    it('indicates required field', () => {
      const { container } = render(
        <RadioGroup options={mockOptions} required />
      )
      
      const group = container.querySelector('[role="radiogroup"]')
      expect(group).toHaveAttribute('aria-required', 'true')
    })

    it('each radio has unique id', () => {
      render(<RadioGroup options={mockOptions} />)
      
      const radios = screen.getAllByRole('radio')
      const ids = radios.map((radio) => radio.id)
      const uniqueIds = new Set(ids)
      
      expect(uniqueIds.size).toBe(ids.length)
    })

    it('labels are associated with inputs', () => {
      render(<RadioGroup options={mockOptions} />)
      
      mockOptions.forEach((option) => {
        const label = screen.getByText(option.label)
        const radio = screen.getByLabelText(option.label)
        
        expect(label.getAttribute('for')).toBe(radio.id)
      })
    })
  })

  describe('Visual Feedback', () => {
    it('highlights selected option', () => {
      const { container } = render(
        <RadioGroup options={mockOptions} value="option2" />
      )
      
      const selectedContainer = screen.getByLabelText('Option 2').closest('div')
      expect(selectedContainer).toHaveClass('border-primary')
    })

    it('applies hover styles', () => {
      const { container } = render(<RadioGroup options={mockOptions} />)
      
      const optionContainers = container.querySelectorAll('.hover\\:bg-accent\\/50')
      expect(optionContainers.length).toBeGreaterThan(0)
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Radio Group

```typescript
import { RadioGroup } from '@/components/ui/radio'

function PlanSelector() {
  const [plan, setPlan] = React.useState('free')

  return (
    <RadioGroup
      label="Choose a plan"
      options={[
        { value: 'free', label: 'Free' },
        { value: 'pro', label: 'Pro' },
        { value: 'enterprise', label: 'Enterprise' },
      ]}
      value={plan}
      onValueChange={setPlan}
    />
  )
}
```

### With Descriptions

```typescript
function NotificationSettings() {
  const [preference, setPreference] = React.useState('all')

  return (
    <RadioGroup
      label="Notification Preference"
      description="Choose how you want to receive notifications"
      options={[
        {
          value: 'all',
          label: 'All notifications',
          description: 'Receive all updates, messages, and alerts',
        },
        {
          value: 'important',
          label: 'Important only',
          description: 'Only receive critical notifications',
        },
        {
          value: 'none',
          label: 'No notifications',
          description: 'Disable all notifications',
        },
      ]}
      value={preference}
      onValueChange={setPreference}
    />
  )
}
```

### Horizontal Layout

```typescript
function PaymentMethod() {
  const [method, setMethod] = React.useState('card')

  return (
    <RadioGroup
      label="Payment Method"
      orientation="horizontal"
      options={[
        { value: 'card', label: 'Credit Card' },
        { value: 'paypal', label: 'PayPal' },
        { value: 'bank', label: 'Bank Transfer' },
      ]}
      value={method}
      onValueChange={setMethod}
    />
  )
}
```

### With Icons

```typescript
import { CreditCard, Smartphone, Laptop } from 'lucide-react'

function DeviceType() {
  const [device, setDevice] = React.useState('')

  return (
    <RadioGroup
      label="Primary Device"
      options={[
        {
          value: 'mobile',
          label: 'Mobile',
          icon: <Smartphone className="h-4 w-4" />,
          description: 'Smartphone or tablet',
        },
        {
          value: 'desktop',
          label: 'Desktop',
          icon: <Laptop className="h-4 w-4" />,
          description: 'Computer or laptop',
        },
      ]}
      value={device}
      onValueChange={setDevice}
    />
  )
}
```

### With Disabled Options

```typescript
function SubscriptionTier() {
  const [tier, setTier] = React.useState('basic')

  return (
    <RadioGroup
      label="Subscription Tier"
      options={[
        { value: 'basic', label: 'Basic', description: '$9/month' },
        { value: 'pro', label: 'Pro', description: '$29/month' },
        {
          value: 'enterprise',
          label: 'Enterprise',
          description: 'Contact sales',
          disabled: true,
        },
      ]}
      value={tier}
      onValueChange={setTier}
    />
  )
}
```

### With Error State

```typescript
function SurveyQuestion() {
  const [answer, setAnswer] = React.useState('')
  const [error, setError] = React.useState('')

  const handleSubmit = () => {
    if (!answer) {
      setError('Please select an answer')
      return
    }
    setError('')
    // Submit logic
  }

  return (
    <div className="space-y-4">
      <RadioGroup
        label="How satisfied are you?"
        required
        options={[
          { value: '5', label: 'Very Satisfied' },
          { value: '4', label: 'Satisfied' },
          { value: '3', label: 'Neutral' },
          { value: '2', label: 'Dissatisfied' },
          { value: '1', label: 'Very Dissatisfied' },
        ]}
        value={answer}
        onValueChange={setAnswer}
        error={error}
      />
      <Button onClick={handleSubmit}>Submit</Button>
    </div>
  )
}
```

### With React Hook Form

```typescript
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  plan: z.string().min(1, 'Please select a plan'),
})

function PlanForm() {
  const { control, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      plan: '',
    },
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="plan"
        control={control}
        render={({ field }) => (
          <RadioGroup
            label="Select Plan"
            options={[
              { value: 'starter', label: 'Starter' },
              { value: 'professional', label: 'Professional' },
              { value: 'enterprise', label: 'Enterprise' },
            ]}
            value={field.value}
            onValueChange={field.onChange}
            error={errors.plan?.message}
            required
          />
        )}
      />
      <Button type="submit">Continue</Button>
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Minimum touch target size (44x44px)
- ✅ Sufficient color contrast ratios
- ✅ Focus indicators visible
- ✅ Keyboard navigation support
- ✅ Screen reader friendly

### Keyboard Navigation
- **Arrow Down/Right**: Move to next option
- **Arrow Up/Left**: Move to previous option
- **Space**: Select focused option
- **Tab**: Move focus to/from radio group

### ARIA Attributes
- `role="radiogroup"`: Group container
- `role="radio"`: Individual options
- `aria-checked`: Indicates selected state
- `aria-labelledby`: Links to group label
- `aria-describedby`: Links to description/error
- `aria-required`: Indicates required field
- `aria-invalid`: Indicates error state

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-radio-group
- [ ] Create radio.tsx file
- [ ] Implement Radio component with Radix UI
- [ ] Implement RadioGroup wrapper
- [ ] Add support for descriptions
- [ ] Add icon support
- [ ] Add horizontal/vertical layouts
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories
- [ ] Document usage examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
