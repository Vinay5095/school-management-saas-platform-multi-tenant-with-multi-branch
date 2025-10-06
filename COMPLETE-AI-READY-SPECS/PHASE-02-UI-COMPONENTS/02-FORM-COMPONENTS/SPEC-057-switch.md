# SPEC-057: Switch Component
## Toggle Switch Component

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4 hours  
> **Dependencies**: Radix UI Switch

---

## 📋 OVERVIEW

### Purpose
An accessible toggle switch component for binary on/off states. Perfect for settings, preferences, and feature toggles with smooth animations and comprehensive accessibility.

### Key Features
- ✅ Smooth toggle animation
- ✅ Label and description support
- ✅ Disabled state handling
- ✅ Multiple sizes (sm, default, lg)
- ✅ Error state display
- ✅ Keyboard navigation (Space, Enter)
- ✅ React Hook Form integration
- ✅ WCAG 2.1 AA compliant
- ✅ Custom thumb indicator

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/switch.tsx
'use client'

import * as React from 'react'
import * as SwitchPrimitives from '@radix-ui/react-switch'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// VARIANT CONFIGURATION
// ========================================

const switchVariants = cva(
  'peer inline-flex shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input',
  {
    variants: {
      size: {
        sm: 'h-4 w-7',
        default: 'h-6 w-11',
        lg: 'h-7 w-14',
      },
    },
    defaultVariants: {
      size: 'default',
    },
  }
)

const switchThumbVariants = cva(
  'pointer-events-none block rounded-full bg-background shadow-lg ring-0 transition-transform',
  {
    variants: {
      size: {
        sm: 'h-3 w-3 data-[state=checked]:translate-x-3 data-[state=unchecked]:translate-x-0',
        default: 'h-5 w-5 data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0',
        lg: 'h-6 w-6 data-[state=checked]:translate-x-7 data-[state=unchecked]:translate-x-0',
      },
    },
    defaultVariants: {
      size: 'default',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface SwitchProps
  extends Omit<
      React.ComponentPropsWithoutRef<typeof SwitchPrimitives.Root>,
      'asChild'
    >,
    VariantProps<typeof switchVariants> {
  /**
   * Label text for the switch
   */
  label?: string
  
  /**
   * Description text shown below the label
   */
  description?: string
  
  /**
   * Error message to display
   */
  error?: string
  
  /**
   * Position of the label relative to the switch
   */
  labelPosition?: 'left' | 'right'
  
  /**
   * Additional CSS classes for the wrapper
   */
  wrapperClassName?: string
}

// ========================================
// SWITCH COMPONENT
// ========================================

/**
 * Switch Component
 * 
 * An accessible toggle switch for binary on/off states.
 * Supports labels, descriptions, and multiple sizes.
 * 
 * @example
 * // Basic switch
 * <Switch checked={isEnabled} onCheckedChange={setIsEnabled} />
 * 
 * @example
 * // Switch with label
 * <Switch
 *   label="Enable notifications"
 *   description="Receive updates about your account"
 *   checked={notifications}
 *   onCheckedChange={setNotifications}
 * />
 * 
 * @example
 * // Different sizes
 * <Switch size="sm" />
 * <Switch size="default" />
 * <Switch size="lg" />
 */
const Switch = React.forwardRef<
  React.ElementRef<typeof SwitchPrimitives.Root>,
  SwitchProps
>(
  (
    {
      className,
      size,
      label,
      description,
      error,
      labelPosition = 'right',
      wrapperClassName,
      id,
      disabled,
      ...props
    },
    ref
  ) => {
    const switchId = id || React.useId()
    const errorId = `${switchId}-error`
    const descriptionId = `${switchId}-description`

    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    const switchElement = (
      <SwitchPrimitives.Root
        id={switchId}
        ref={ref}
        disabled={disabled}
        className={cn(switchVariants({ size }), className)}
        aria-describedby={ariaDescribedBy}
        aria-invalid={error ? 'true' : 'false'}
        {...props}
      >
        <SwitchPrimitives.Thumb className={cn(switchThumbVariants({ size }))} />
      </SwitchPrimitives.Root>
    )

    // Return just the switch if no label
    if (!label && !description && !error) {
      return switchElement
    }

    // Return switch with label/description
    return (
      <div className={cn('space-y-2', wrapperClassName)}>
        <div
          className={cn(
            'flex items-center gap-3',
            labelPosition === 'left' && 'flex-row-reverse justify-end',
            disabled && 'opacity-50 cursor-not-allowed'
          )}
        >
          {switchElement}
          
          {(label || description) && (
            <div className="flex-1 space-y-1">
              {label && (
                <label
                  htmlFor={switchId}
                  className={cn(
                    'text-sm font-medium leading-none cursor-pointer',
                    'peer-disabled:cursor-not-allowed peer-disabled:opacity-70'
                  )}
                >
                  {label}
                </label>
              )}
              {description && (
                <p id={descriptionId} className="text-sm text-muted-foreground">
                  {description}
                </p>
              )}
            </div>
          )}
        </div>

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

Switch.displayName = SwitchPrimitives.Root.displayName

export { Switch, switchVariants }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/switch.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Switch } from '../switch'

describe('Switch Component', () => {
  describe('Rendering', () => {
    it('renders correctly', () => {
      render(<Switch />)
      expect(screen.getByRole('switch')).toBeInTheDocument()
    })

    it('renders with label', () => {
      render(<Switch label="Enable feature" />)
      expect(screen.getByText('Enable feature')).toBeInTheDocument()
    })

    it('renders with description', () => {
      render(<Switch description="This is a description" />)
      expect(screen.getByText('This is a description')).toBeInTheDocument()
    })

    it('renders with both label and description', () => {
      render(
        <Switch
          label="Feature Toggle"
          description="Enable or disable this feature"
        />
      )
      expect(screen.getByText('Feature Toggle')).toBeInTheDocument()
      expect(screen.getByText('Enable or disable this feature')).toBeInTheDocument()
    })
  })

  describe('Sizes', () => {
    it('renders default size', () => {
      render(<Switch size="default" />)
      expect(screen.getByRole('switch')).toHaveClass('h-6', 'w-11')
    })

    it('renders small size', () => {
      render(<Switch size="sm" />)
      expect(screen.getByRole('switch')).toHaveClass('h-4', 'w-7')
    })

    it('renders large size', () => {
      render(<Switch size="lg" />)
      expect(screen.getByRole('switch')).toHaveClass('h-7', 'w-14')
    })
  })

  describe('Label Position', () => {
    it('renders label on the right by default', () => {
      const { container } = render(<Switch label="Right Label" />)
      const wrapper = container.firstChild as HTMLElement
      
      expect(wrapper.querySelector('.flex')).not.toHaveClass('flex-row-reverse')
    })

    it('renders label on the left when specified', () => {
      const { container } = render(
        <Switch label="Left Label" labelPosition="left" />
      )
      const wrapper = container.querySelector('.flex')
      
      expect(wrapper).toHaveClass('flex-row-reverse')
    })
  })

  describe('Checked State', () => {
    it('is unchecked by default', () => {
      render(<Switch />)
      expect(screen.getByRole('switch')).not.toBeChecked()
    })

    it('respects checked prop', () => {
      render(<Switch checked />)
      expect(screen.getByRole('switch')).toBeChecked()
    })

    it('shows checked state visually', () => {
      render(<Switch checked />)
      expect(screen.getByRole('switch')).toHaveAttribute('data-state', 'checked')
    })

    it('shows unchecked state visually', () => {
      render(<Switch checked={false} />)
      expect(screen.getByRole('switch')).toHaveAttribute('data-state', 'unchecked')
    })
  })

  describe('Interactions', () => {
    it('toggles on click', () => {
      const handleChange = jest.fn()
      render(<Switch onCheckedChange={handleChange} />)
      
      fireEvent.click(screen.getByRole('switch'))
      expect(handleChange).toHaveBeenCalledWith(true)
    })

    it('toggles from checked to unchecked', () => {
      const handleChange = jest.fn()
      render(<Switch checked onCheckedChange={handleChange} />)
      
      fireEvent.click(screen.getByRole('switch'))
      expect(handleChange).toHaveBeenCalledWith(false)
    })

    it('can be toggled by clicking label', () => {
      const handleChange = jest.fn()
      render(<Switch label="Toggle me" onCheckedChange={handleChange} />)
      
      fireEvent.click(screen.getByText('Toggle me'))
      expect(handleChange).toHaveBeenCalledWith(true)
    })

    it('does not toggle when disabled', () => {
      const handleChange = jest.fn()
      render(<Switch disabled onCheckedChange={handleChange} />)
      
      fireEvent.click(screen.getByRole('switch'))
      expect(handleChange).not.toHaveBeenCalled()
    })
  })

  describe('Keyboard Navigation', () => {
    it('can be focused with Tab', async () => {
      render(<Switch />)
      const switchElement = screen.getByRole('switch')
      
      await userEvent.tab()
      expect(switchElement).toHaveFocus()
    })

    it('toggles with Space key', async () => {
      const handleChange = jest.fn()
      render(<Switch onCheckedChange={handleChange} />)
      const switchElement = screen.getByRole('switch')
      
      switchElement.focus()
      await userEvent.keyboard(' ')
      expect(handleChange).toHaveBeenCalledWith(true)
    })

    it('toggles with Enter key', async () => {
      const handleChange = jest.fn()
      render(<Switch onCheckedChange={handleChange} />)
      const switchElement = screen.getByRole('switch')
      
      switchElement.focus()
      await userEvent.keyboard('{Enter}')
      expect(handleChange).toHaveBeenCalledWith(true)
    })

    it('does not toggle with other keys', async () => {
      const handleChange = jest.fn()
      render(<Switch onCheckedChange={handleChange} />)
      const switchElement = screen.getByRole('switch')
      
      switchElement.focus()
      await userEvent.keyboard('a')
      expect(handleChange).not.toHaveBeenCalled()
    })
  })

  describe('Disabled State', () => {
    it('respects disabled prop', () => {
      render(<Switch disabled />)
      expect(screen.getByRole('switch')).toBeDisabled()
    })

    it('applies disabled styling', () => {
      render(<Switch disabled />)
      expect(screen.getByRole('switch')).toHaveClass('opacity-50', 'cursor-not-allowed')
    })

    it('applies disabled styling to wrapper when label present', () => {
      const { container } = render(<Switch label="Disabled" disabled />)
      const wrapper = container.querySelector('.flex')
      
      expect(wrapper).toHaveClass('opacity-50', 'cursor-not-allowed')
    })
  })

  describe('Error Handling', () => {
    it('displays error message', () => {
      render(<Switch error="This field is required" />)
      expect(screen.getByRole('alert')).toHaveTextContent('This field is required')
    })

    it('sets aria-invalid when error present', () => {
      render(<Switch error="Error" />)
      expect(screen.getByRole('switch')).toHaveAttribute('aria-invalid', 'true')
    })

    it('links error with switch via aria-describedby', () => {
      render(<Switch error="Error message" />)
      const switchElement = screen.getByRole('switch')
      const describedBy = switchElement.getAttribute('aria-describedby')
      
      expect(describedBy).toBeTruthy()
      expect(screen.getByRole('alert')).toHaveAttribute('id', expect.stringContaining('-error'))
    })
  })

  describe('Accessibility', () => {
    it('has proper role', () => {
      render(<Switch />)
      expect(screen.getByRole('switch')).toBeInTheDocument()
    })

    it('links label with switch', () => {
      render(<Switch label="Feature" />)
      const switchElement = screen.getByRole('switch')
      const label = screen.getByText('Feature')
      
      expect(switchElement.id).toBe(label.getAttribute('for'))
    })

    it('includes description in aria-describedby', () => {
      render(<Switch description="Helper text" />)
      const switchElement = screen.getByRole('switch')
      const describedBy = switchElement.getAttribute('aria-describedby')
      
      expect(describedBy).toBeTruthy()
      expect(screen.getByText('Helper text')).toHaveAttribute(
        'id',
        expect.stringContaining('-description')
      )
    })

    it('has focus visible ring', () => {
      render(<Switch />)
      expect(screen.getByRole('switch')).toHaveClass('focus-visible:ring-2')
    })

    it('announces state changes to screen readers', () => {
      const { rerender } = render(<Switch checked={false} />)
      expect(screen.getByRole('switch')).toHaveAttribute('aria-checked', 'false')
      
      rerender(<Switch checked={true} />)
      expect(screen.getByRole('switch')).toHaveAttribute('aria-checked', 'true')
    })
  })

  describe('Custom className', () => {
    it('applies custom className to switch', () => {
      render(<Switch className="custom-switch" />)
      expect(screen.getByRole('switch')).toHaveClass('custom-switch')
    })

    it('applies custom className to wrapper', () => {
      const { container } = render(
        <Switch label="Test" wrapperClassName="custom-wrapper" />
      )
      expect(container.firstChild).toHaveClass('custom-wrapper')
    })
  })

  describe('Controlled vs Uncontrolled', () => {
    it('works as uncontrolled component', () => {
      render(<Switch defaultChecked />)
      expect(screen.getByRole('switch')).toBeChecked()
    })

    it('works as controlled component', () => {
      const { rerender } = render(<Switch checked={false} />)
      expect(screen.getByRole('switch')).not.toBeChecked()
      
      rerender(<Switch checked={true} />)
      expect(screen.getByRole('switch')).toBeChecked()
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Switch

```typescript
import { Switch } from '@/components/ui/switch'

function BasicExample() {
  const [enabled, setEnabled] = React.useState(false)

  return (
    <Switch
      checked={enabled}
      onCheckedChange={setEnabled}
    />
  )
}
```

### With Label and Description

```typescript
function NotificationSwitch() {
  const [notifications, setNotifications] = React.useState(true)

  return (
    <Switch
      label="Enable notifications"
      description="Receive updates about your account activity"
      checked={notifications}
      onCheckedChange={setNotifications}
    />
  )
}
```

### Different Sizes

```typescript
function SizeExamples() {
  return (
    <div className="space-y-4">
      <Switch size="sm" label="Small switch" />
      <Switch size="default" label="Default switch" />
      <Switch size="lg" label="Large switch" />
    </div>
  )
}
```

### Label on Left

```typescript
function LeftLabelSwitch() {
  const [darkMode, setDarkMode] = React.useState(false)

  return (
    <Switch
      label="Dark Mode"
      labelPosition="left"
      checked={darkMode}
      onCheckedChange={setDarkMode}
    />
  )
}
```

### Settings Panel

```typescript
function SettingsPanel() {
  const [settings, setSettings] = React.useState({
    emailNotifications: true,
    pushNotifications: false,
    smsNotifications: false,
    marketingEmails: true,
  })

  const updateSetting = (key: string, value: boolean) => {
    setSettings(prev => ({ ...prev, [key]: value }))
  }

  return (
    <div className="space-y-4">
      <Switch
        label="Email Notifications"
        description="Receive notifications via email"
        checked={settings.emailNotifications}
        onCheckedChange={(checked) => updateSetting('emailNotifications', checked)}
      />
      
      <Switch
        label="Push Notifications"
        description="Receive push notifications on your device"
        checked={settings.pushNotifications}
        onCheckedChange={(checked) => updateSetting('pushNotifications', checked)}
      />
      
      <Switch
        label="SMS Notifications"
        description="Receive notifications via SMS"
        checked={settings.smsNotifications}
        onCheckedChange={(checked) => updateSetting('smsNotifications', checked)}
      />
      
      <Switch
        label="Marketing Emails"
        description="Receive promotional and marketing content"
        checked={settings.marketingEmails}
        onCheckedChange={(checked) => updateSetting('marketingEmails', checked)}
      />
    </div>
  )
}
```

### Disabled State

```typescript
function DisabledSwitch() {
  return (
    <Switch
      label="Premium Feature"
      description="Upgrade to access this feature"
      disabled
      checked={false}
    />
  )
}
```

### With Error State

```typescript
function ErrorExample() {
  const [agreed, setAgreed] = React.useState(false)
  const [error, setError] = React.useState('')

  const handleSubmit = () => {
    if (!agreed) {
      setError('You must agree to the terms')
      return
    }
    setError('')
    // Submit logic
  }

  return (
    <div className="space-y-4">
      <Switch
        label="I agree to the terms and conditions"
        checked={agreed}
        onCheckedChange={(checked) => {
          setAgreed(checked)
          setError('')
        }}
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
  acceptTerms: z.boolean().refine((val) => val === true, {
    message: 'You must accept the terms and conditions',
  }),
  newsletter: z.boolean().optional(),
})

function PreferencesForm() {
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      acceptTerms: false,
      newsletter: false,
    },
  })

  return (
    <form onSubmit={handleSubmit(console.log)} className="space-y-4">
      <Controller
        name="acceptTerms"
        control={control}
        render={({ field }) => (
          <Switch
            label="Accept terms and conditions"
            description="You must accept our terms to continue"
            checked={field.value}
            onCheckedChange={field.onChange}
            error={errors.acceptTerms?.message}
          />
        )}
      />
      
      <Controller
        name="newsletter"
        control={control}
        render={({ field }) => (
          <Switch
            label="Subscribe to newsletter"
            description="Receive our weekly newsletter"
            checked={field.value}
            onCheckedChange={field.onChange}
          />
        )}
      />
      
      <Button type="submit">Save Preferences</Button>
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
- **Tab**: Moves focus to switch
- **Space**: Toggles the switch
- **Enter**: Toggles the switch

### ARIA Attributes
- `role="switch"`: Indicates toggle switch role
- `aria-checked`: Indicates current state
- `aria-describedby`: Links to description and error
- `aria-invalid`: Indicates error state

### Best Practices
```typescript
// ✅ Good: With descriptive label
<Switch label="Enable dark mode" />

// ✅ Good: With label and description
<Switch
  label="Two-factor authentication"
  description="Add an extra layer of security"
/>

// ❌ Bad: No label or accessible name
<Switch />
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-switch
- [ ] Create switch.tsx file
- [ ] Implement Switch component with Radix UI
- [ ] Add size variants (sm, default, lg)
- [ ] Add label and description support
- [ ] Add label positioning (left/right)
- [ ] Add error handling
- [ ] Style with Tailwind CSS
- [ ] Add smooth animations
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories
- [ ] Document usage examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
