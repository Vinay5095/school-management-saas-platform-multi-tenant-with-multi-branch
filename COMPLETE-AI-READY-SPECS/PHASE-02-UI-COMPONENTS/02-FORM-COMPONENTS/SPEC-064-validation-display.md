# SPEC-064: ValidationDisplay Component
## Validation Messages and Field State Indicators

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 3 hours  
> **Dependencies**: React Hook Form

---

## 📋 OVERVIEW

### Purpose
A component for displaying validation messages, field state indicators, and password strength meters. Provides consistent visual feedback for form validation across the application.

### Key Features
- ✅ Error message display
- ✅ Success indicators
- ✅ Warning messages
- ✅ Info messages
- ✅ Password strength meter
- ✅ Field validation requirements list
- ✅ Real-time validation feedback
- ✅ Animated transitions
- ✅ Icon support
- ✅ Accessible announcements

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/validation-display.tsx
'use client'

import * as React from 'react'
import { CheckCircle2, XCircle, AlertCircle, Info } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type ValidationMessageType = 'error' | 'success' | 'warning' | 'info'

export interface ValidationMessageProps {
  /**
   * Message text
   */
  message: string
  
  /**
   * Message type
   */
  type?: ValidationMessageType
  
  /**
   * Additional CSS classes
   */
  className?: string
}

export interface ValidationListProps {
  /**
   * List of validation requirements
   */
  requirements: ValidationRequirement[]
  
  /**
   * Current value to validate against
   */
  value?: string
  
  /**
   * Additional CSS classes
   */
  className?: string
}

export interface ValidationRequirement {
  /**
   * Requirement label
   */
  label: string
  
  /**
   * Validation function
   */
  validate: (value: string) => boolean
}

export interface PasswordStrengthProps {
  /**
   * Password value
   */
  password: string
  
  /**
   * Show strength label
   */
  showLabel?: boolean
  
  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// VALIDATION MESSAGE COMPONENT
// ========================================

/**
 * ValidationMessage Component
 * 
 * Displays a single validation message with appropriate styling and icon.
 * 
 * @example
 * <ValidationMessage
 *   type="error"
 *   message="Email is required"
 * />
 */
export function ValidationMessage({
  message,
  type = 'error',
  className,
}: ValidationMessageProps) {
  const config = {
    error: {
      icon: XCircle,
      color: 'text-destructive',
      bgColor: 'bg-destructive/10',
    },
    success: {
      icon: CheckCircle2,
      color: 'text-green-600 dark:text-green-400',
      bgColor: 'bg-green-100 dark:bg-green-900/20',
    },
    warning: {
      icon: AlertCircle,
      color: 'text-yellow-600 dark:text-yellow-400',
      bgColor: 'bg-yellow-100 dark:bg-yellow-900/20',
    },
    info: {
      icon: Info,
      color: 'text-blue-600 dark:text-blue-400',
      bgColor: 'bg-blue-100 dark:bg-blue-900/20',
    },
  }

  const { icon: Icon, color, bgColor } = config[type]

  return (
    <div
      className={cn(
        'flex items-start gap-2 rounded-md p-3 text-sm',
        bgColor,
        className
      )}
      role="alert"
      aria-live="polite"
    >
      <Icon className={cn('h-4 w-4 mt-0.5 shrink-0', color)} aria-hidden="true" />
      <p className={cn('flex-1', color)}>{message}</p>
    </div>
  )
}

// ========================================
// VALIDATION LIST COMPONENT
// ========================================

/**
 * ValidationList Component
 * 
 * Displays a list of validation requirements with real-time pass/fail indicators.
 * 
 * @example
 * <ValidationList
 *   requirements={[
 *     { label: 'At least 8 characters', validate: (v) => v.length >= 8 },
 *     { label: 'Contains uppercase letter', validate: (v) => /[A-Z]/.test(v) }
 *   ]}
 *   value={password}
 * />
 */
export function ValidationList({
  requirements,
  value = '',
  className,
}: ValidationListProps) {
  return (
    <ul className={cn('space-y-2', className)} role="list">
      {requirements.map((req, index) => {
        const isValid = req.validate(value)
        const hasValue = value.length > 0

        return (
          <li
            key={index}
            className={cn(
              'flex items-center gap-2 text-sm transition-colors',
              hasValue && isValid && 'text-green-600 dark:text-green-400',
              hasValue && !isValid && 'text-destructive',
              !hasValue && 'text-muted-foreground'
            )}
          >
            {hasValue && isValid ? (
              <CheckCircle2 className="h-4 w-4 shrink-0" aria-hidden="true" />
            ) : (
              <div
                className={cn(
                  'h-4 w-4 rounded-full border-2 shrink-0',
                  hasValue && !isValid
                    ? 'border-destructive'
                    : 'border-muted-foreground'
                )}
                aria-hidden="true"
              />
            )}
            <span>{req.label}</span>
            <span className="sr-only">
              {isValid ? 'Requirement met' : 'Requirement not met'}
            </span>
          </li>
        )
      })}
    </ul>
  )
}

// ========================================
// PASSWORD STRENGTH COMPONENT
// ========================================

/**
 * Calculate password strength (0-4)
 */
function calculatePasswordStrength(password: string): number {
  let strength = 0

  if (password.length >= 8) strength++
  if (password.length >= 12) strength++
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) strength++
  if (/\d/.test(password)) strength++
  if (/[^a-zA-Z0-9]/.test(password)) strength++

  return Math.min(strength, 4)
}

/**
 * PasswordStrength Component
 * 
 * Displays a visual password strength indicator with optional label.
 * 
 * @example
 * <PasswordStrength
 *   password={password}
 *   showLabel
 * />
 */
export function PasswordStrength({
  password,
  showLabel = true,
  className,
}: PasswordStrengthProps) {
  const strength = calculatePasswordStrength(password)

  const strengthConfig = [
    { label: 'Too weak', color: 'bg-destructive', width: '20%' },
    { label: 'Weak', color: 'bg-orange-500', width: '40%' },
    { label: 'Fair', color: 'bg-yellow-500', width: '60%' },
    { label: 'Good', color: 'bg-green-500', width: '80%' },
    { label: 'Strong', color: 'bg-green-600', width: '100%' },
  ]

  const config = strengthConfig[strength]

  if (!password) {
    return null
  }

  return (
    <div className={cn('space-y-2', className)}>
      {/* Strength Bar */}
      <div className="h-2 bg-muted rounded-full overflow-hidden">
        <div
          className={cn(
            'h-full transition-all duration-300 ease-in-out',
            config.color
          )}
          style={{ width: config.width }}
          role="progressbar"
          aria-valuenow={strength}
          aria-valuemin={0}
          aria-valuemax={4}
          aria-label="Password strength"
        />
      </div>

      {/* Strength Label */}
      {showLabel && (
        <p className="text-sm text-muted-foreground">
          Password strength: <span className="font-medium">{config.label}</span>
        </p>
      )}
    </div>
  )
}

// ========================================
// FIELD STATE INDICATOR COMPONENT
// ========================================

export interface FieldStateIndicatorProps {
  /**
   * Whether the field is valid
   */
  isValid?: boolean
  
  /**
   * Whether the field has been touched
   */
  isTouched?: boolean
  
  /**
   * Whether the field is being validated
   */
  isValidating?: boolean
  
  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * FieldStateIndicator Component
 * 
 * Shows an icon indicator for field validation state.
 * 
 * @example
 * <FieldStateIndicator
 *   isValid={!errors.email}
 *   isTouched={touchedFields.email}
 * />
 */
export function FieldStateIndicator({
  isValid,
  isTouched,
  isValidating,
  className,
}: FieldStateIndicatorProps) {
  if (!isTouched) {
    return null
  }

  if (isValidating) {
    return (
      <div
        className={cn('animate-spin h-4 w-4 border-2 border-primary border-t-transparent rounded-full', className)}
        role="status"
        aria-label="Validating"
      />
    )
  }

  if (isValid) {
    return (
      <CheckCircle2
        className={cn('h-4 w-4 text-green-600 dark:text-green-400', className)}
        aria-label="Valid"
      />
    )
  }

  return (
    <XCircle
      className={cn('h-4 w-4 text-destructive', className)}
      aria-label="Invalid"
    />
  )
}

// ========================================
// VALIDATION SUMMARY COMPONENT
// ========================================

export interface ValidationSummaryProps {
  /**
   * List of error messages
   */
  errors: string[]
  
  /**
   * Summary title
   */
  title?: string
  
  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * ValidationSummary Component
 * 
 * Displays a summary of all validation errors, typically at the top of a form.
 * 
 * @example
 * <ValidationSummary
 *   title="Please fix the following errors:"
 *   errors={[
 *     'Email is required',
 *     'Password must be at least 8 characters'
 *   ]}
 * />
 */
export function ValidationSummary({
  errors,
  title = 'Please correct the following errors:',
  className,
}: ValidationSummaryProps) {
  if (errors.length === 0) {
    return null
  }

  return (
    <div
      className={cn(
        'rounded-lg border border-destructive bg-destructive/10 p-4',
        className
      )}
      role="alert"
      aria-live="assertive"
    >
      <div className="flex items-start gap-3">
        <XCircle className="h-5 w-5 text-destructive shrink-0 mt-0.5" aria-hidden="true" />
        <div className="flex-1 space-y-2">
          <p className="font-medium text-destructive">{title}</p>
          <ul className="list-disc list-inside space-y-1 text-sm text-destructive">
            {errors.map((error, index) => (
              <li key={index}>{error}</li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Simple Validation Message

```typescript
import { ValidationMessage } from '@/components/ui/validation-display'

function Example() {
  return (
    <>
      <ValidationMessage type="error" message="This field is required" />
      <ValidationMessage type="success" message="Email verified successfully" />
      <ValidationMessage type="warning" message="Password will expire in 7 days" />
      <ValidationMessage type="info" message="Username can only contain letters and numbers" />
    </>
  )
}
```

### Password Validation Requirements

```typescript
import { ValidationList, PasswordStrength } from '@/components/ui/validation-display'

function PasswordField() {
  const [password, setPassword] = React.useState('')

  const requirements: ValidationRequirement[] = [
    {
      label: 'At least 8 characters',
      validate: (v) => v.length >= 8,
    },
    {
      label: 'Contains uppercase letter',
      validate: (v) => /[A-Z]/.test(v),
    },
    {
      label: 'Contains lowercase letter',
      validate: (v) => /[a-z]/.test(v),
    },
    {
      label: 'Contains number',
      validate: (v) => /\d/.test(v),
    },
    {
      label: 'Contains special character',
      validate: (v) => /[^a-zA-Z0-9]/.test(v),
    },
  ]

  return (
    <div className="space-y-4">
      <Input
        type="password"
        label="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      
      <PasswordStrength password={password} showLabel />
      
      <ValidationList requirements={requirements} value={password} />
    </div>
  )
}
```

### Field State Indicator

```typescript
import { FieldStateIndicator } from '@/components/ui/validation-display'
import { useFormContext } from 'react-hook-form'

function EmailField() {
  const {
    register,
    formState: { errors, touchedFields },
    watch,
  } = useFormContext()

  const email = watch('email')

  return (
    <div className="relative">
      <Input
        {...register('email')}
        type="email"
        label="Email"
        error={errors.email?.message}
      />
      <div className="absolute right-3 top-10">
        <FieldStateIndicator
          isValid={!errors.email}
          isTouched={touchedFields.email}
        />
      </div>
    </div>
  )
}
```

### Validation Summary

```typescript
import { ValidationSummary } from '@/components/ui/validation-display'
import { useFormContext } from 'react-hook-form'

function FormWithSummary() {
  const {
    formState: { errors },
  } = useFormContext()

  const errorMessages = Object.values(errors)
    .map((error) => error?.message)
    .filter(Boolean) as string[]

  return (
    <div className="space-y-6">
      <ValidationSummary errors={errorMessages} />
      
      {/* Form fields */}
    </div>
  )
}
```

### Complete Registration Form Example

```typescript
import {
  ValidationList,
  ValidationMessage,
  PasswordStrength,
  ValidationSummary,
} from '@/components/ui/validation-display'

const passwordRequirements: ValidationRequirement[] = [
  { label: 'At least 8 characters', validate: (v) => v.length >= 8 },
  { label: 'Contains uppercase letter', validate: (v) => /[A-Z]/.test(v) },
  { label: 'Contains lowercase letter', validate: (v) => /[a-z]/.test(v) },
  { label: 'Contains number', validate: (v) => /\d/.test(v) },
  { label: 'Contains special character', validate: (v) => /[^a-zA-Z0-9]/.test(v) },
]

function RegistrationForm() {
  const {
    watch,
    formState: { errors },
  } = useFormContext()

  const password = watch('password')
  const confirmPassword = watch('confirmPassword')

  const errorMessages = Object.values(errors)
    .map((error) => error?.message)
    .filter(Boolean) as string[]

  const allRequirementsMet = passwordRequirements.every((req) =>
    req.validate(password || '')
  )

  const passwordsMatch = password && confirmPassword && password === confirmPassword

  return (
    <div className="space-y-6">
      {/* Error Summary */}
      <ValidationSummary errors={errorMessages} />

      {/* Username */}
      <FormField name="username" label="Username" required />
      
      <ValidationMessage
        type="info"
        message="Username must be 3-20 characters and can only contain letters, numbers, and underscores"
      />

      {/* Email */}
      <FormField name="email" type="email" label="Email" required />

      {/* Password */}
      <div className="space-y-4">
        <FormField name="password" type="password" label="Password" required />
        
        <PasswordStrength password={password} showLabel />
        
        <ValidationList requirements={passwordRequirements} value={password} />
      </div>

      {/* Confirm Password */}
      <div className="space-y-2">
        <FormField
          name="confirmPassword"
          type="password"
          label="Confirm Password"
          required
        />
        
        {confirmPassword && (
          passwordsMatch ? (
            <ValidationMessage type="success" message="Passwords match" />
          ) : (
            <ValidationMessage type="error" message="Passwords do not match" />
          )
        )}
      </div>

      {/* Terms */}
      <FormField
        name="terms"
        type="checkbox"
        label="I accept the terms and conditions"
        required
      />

      {/* Submit */}
      <Button
        type="submit"
        disabled={!allRequirementsMet || !passwordsMatch}
        className="w-full"
      >
        Create Account
      </Button>
    </div>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ ARIA live regions for dynamic messages
- ✅ Screen reader friendly
- ✅ Clear error announcements
- ✅ Status indicators with text alternatives
- ✅ Keyboard accessible

### Best Practices
- Use `role="alert"` for error messages
- Provide text alternatives for icons
- Use appropriate `aria-live` regions
- Ensure sufficient color contrast

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create validation-display.tsx file
- [ ] Implement ValidationMessage component
- [ ] Implement ValidationList component
- [ ] Implement PasswordStrength component
- [ ] Implement FieldStateIndicator component
- [ ] Implement ValidationSummary component
- [ ] Style with Tailwind CSS
- [ ] Add animations and transitions
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Create Storybook stories
- [ ] Document usage patterns

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
