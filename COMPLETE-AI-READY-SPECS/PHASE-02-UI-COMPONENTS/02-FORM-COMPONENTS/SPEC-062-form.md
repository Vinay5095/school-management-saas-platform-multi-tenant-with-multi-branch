# SPEC-062: Form Component
## Complete Form Container with Validation

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 4 hours  
> **Dependencies**: React Hook Form, Zod

---

## 📋 OVERVIEW

### Purpose
A comprehensive form container component that integrates React Hook Form with Zod validation, providing consistent form handling, error management, and submission flow across the application.

### Key Features
- ✅ React Hook Form integration
- ✅ Zod schema validation
- ✅ Loading states during submission
- ✅ Success/error notifications
- ✅ Form reset functionality
- ✅ Dirty state tracking
- ✅ Automatic error focus
- ✅ Accessible form structure
- ✅ TypeScript support
- ✅ Customizable layout

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/form.tsx
'use client'

import * as React from 'react'
import { useForm, FormProvider, UseFormReturn, FieldValues, SubmitHandler } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface FormProps<TFieldValues extends FieldValues = FieldValues> {
  /**
   * Form submission handler
   */
  onSubmit: SubmitHandler<TFieldValues>
  
  /**
   * Zod validation schema
   */
  schema?: z.ZodType<TFieldValues>
  
  /**
   * Default form values
   */
  defaultValues?: Partial<TFieldValues>
  
  /**
   * Form ID
   */
  id?: string
  
  /**
   * Form children
   */
  children: React.ReactNode | ((methods: UseFormReturn<TFieldValues>) => React.ReactNode)
  
  /**
   * Additional CSS classes
   */
  className?: string
  
  /**
   * Callback fired on successful submission
   */
  onSuccess?: (data: TFieldValues) => void
  
  /**
   * Callback fired on submission error
   */
  onError?: (error: Error) => void
  
  /**
   * Reset form after successful submission
   */
  resetOnSuccess?: boolean
  
  /**
   * Show loading state during submission
   */
  showLoading?: boolean
  
  /**
   * Validation mode
   */
  mode?: 'onSubmit' | 'onBlur' | 'onChange' | 'onTouched' | 'all'
}

// ========================================
// FORM COMPONENT
// ========================================

/**
 * Form Component
 * 
 * A comprehensive form container with React Hook Form and Zod validation.
 * 
 * @example
 * // Basic form
 * <Form
 *   schema={loginSchema}
 *   defaultValues={{ email: '', password: '' }}
 *   onSubmit={handleLogin}
 * >
 *   <FormField name="email" label="Email" />
 *   <FormField name="password" label="Password" type="password" />
 *   <Button type="submit">Login</Button>
 * </Form>
 * 
 * @example
 * // With access to form methods
 * <Form schema={schema} onSubmit={onSubmit}>
 *   {({ watch, setValue }) => (
 *     <>
 *       <FormField name="name" label="Name" />
 *       <p>Current value: {watch('name')}</p>
 *     </>
 *   )}
 * </Form>
 */
export function Form<TFieldValues extends FieldValues = FieldValues>({
  onSubmit,
  schema,
  defaultValues,
  id,
  children,
  className,
  onSuccess,
  onError,
  resetOnSuccess = false,
  showLoading = true,
  mode = 'onSubmit',
}: FormProps<TFieldValues>) {
  const [isSubmitting, setIsSubmitting] = React.useState(false)
  
  const methods = useForm<TFieldValues>({
    resolver: schema ? zodResolver(schema) : undefined,
    defaultValues,
    mode,
  })

  const handleSubmit = async (data: TFieldValues) => {
    try {
      setIsSubmitting(true)
      await onSubmit(data)
      onSuccess?.(data)
      
      if (resetOnSuccess) {
        methods.reset()
      }
    } catch (error) {
      onError?.(error as Error)
      console.error('Form submission error:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormProvider {...methods}>
      <form
        id={id}
        onSubmit={methods.handleSubmit(handleSubmit)}
        className={cn('space-y-6', className)}
        noValidate
      >
        {typeof children === 'function' ? children(methods) : children}
        
        {showLoading && isSubmitting && (
          <div className="absolute inset-0 bg-background/50 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
          </div>
        )}
      </form>
    </FormProvider>
  )
}

// ========================================
// FORM SECTION COMPONENT
// ========================================

export interface FormSectionProps {
  /**
   * Section title
   */
  title?: string
  
  /**
   * Section description
   */
  description?: string
  
  /**
   * Section children
   */
  children: React.ReactNode
  
  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * FormSection Component
 * 
 * A section container for organizing related form fields.
 * 
 * @example
 * <FormSection
 *   title="Personal Information"
 *   description="Enter your basic details"
 * >
 *   <FormField name="firstName" label="First Name" />
 *   <FormField name="lastName" label="Last Name" />
 * </FormSection>
 */
export function FormSection({
  title,
  description,
  children,
  className,
}: FormSectionProps) {
  return (
    <div className={cn('space-y-4', className)}>
      {(title || description) && (
        <div className="space-y-1">
          {title && (
            <h3 className="text-lg font-semibold leading-none tracking-tight">
              {title}
            </h3>
          )}
          {description && (
            <p className="text-sm text-muted-foreground">{description}</p>
          )}
        </div>
      )}
      <div className="space-y-4">{children}</div>
    </div>
  )
}

// ========================================
// FORM ACTIONS COMPONENT
// ========================================

export interface FormActionsProps {
  /**
   * Actions children (typically buttons)
   */
  children: React.ReactNode
  
  /**
   * Alignment of actions
   */
  align?: 'left' | 'center' | 'right' | 'between'
  
  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * FormActions Component
 * 
 * A container for form action buttons (submit, cancel, etc.)
 * 
 * @example
 * <FormActions align="right">
 *   <Button type="button" variant="outline">Cancel</Button>
 *   <Button type="submit">Save</Button>
 * </FormActions>
 */
export function FormActions({
  children,
  align = 'right',
  className,
}: FormActionsProps) {
  const alignmentClasses = {
    left: 'justify-start',
    center: 'justify-center',
    right: 'justify-end',
    between: 'justify-between',
  }

  return (
    <div
      className={cn(
        'flex items-center gap-2 pt-4',
        alignmentClasses[align],
        className
      )}
    >
      {children}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Form with Validation

```typescript
import { Form, FormSection, FormActions } from '@/components/ui/form'
import { FormField } from '@/components/ui/form-field'
import { Button } from '@/components/ui/button'
import * as z from 'zod'

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

type LoginFormValues = z.infer<typeof loginSchema>

function LoginForm() {
  const handleSubmit = async (data: LoginFormValues) => {
    await loginUser(data)
  }

  return (
    <Form
      schema={loginSchema}
      defaultValues={{ email: '', password: '' }}
      onSubmit={handleSubmit}
    >
      <FormField name="email" label="Email" type="email" required />
      <FormField name="password" label="Password" type="password" required />
      
      <FormActions>
        <Button type="submit">Login</Button>
      </FormActions>
    </Form>
  )
}
```

### Multi-Section Form

```typescript
const profileSchema = z.object({
  firstName: z.string().min(1, 'First name required'),
  lastName: z.string().min(1, 'Last name required'),
  email: z.string().email('Invalid email'),
  phone: z.string().optional(),
  address: z.string().optional(),
  city: z.string().optional(),
  country: z.string().optional(),
})

function ProfileForm() {
  return (
    <Form
      schema={profileSchema}
      defaultValues={{}}
      onSubmit={handleSubmit}
    >
      <FormSection
        title="Personal Information"
        description="Your basic details"
      >
        <div className="grid grid-cols-2 gap-4">
          <FormField name="firstName" label="First Name" required />
          <FormField name="lastName" label="Last Name" required />
        </div>
        <FormField name="email" label="Email" type="email" required />
        <FormField name="phone" label="Phone" type="tel" />
      </FormSection>

      <FormSection
        title="Address"
        description="Your location details"
      >
        <FormField name="address" label="Street Address" />
        <div className="grid grid-cols-2 gap-4">
          <FormField name="city" label="City" />
          <FormField name="country" label="Country" />
        </div>
      </FormSection>

      <FormActions align="right">
        <Button type="button" variant="outline">Cancel</Button>
        <Button type="submit">Save Profile</Button>
      </FormActions>
    </Form>
  )
}
```

### Form with Dynamic Fields

```typescript
function DynamicForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      {({ watch, setValue }) => {
        const accountType = watch('accountType')
        
        return (
          <>
            <FormField
              name="accountType"
              label="Account Type"
              type="select"
              options={[
                { value: 'personal', label: 'Personal' },
                { value: 'business', label: 'Business' },
              ]}
            />
            
            {accountType === 'business' && (
              <>
                <FormField name="companyName" label="Company Name" required />
                <FormField name="taxId" label="Tax ID" required />
              </>
            )}
            
            <FormActions>
              <Button type="submit">Continue</Button>
            </FormActions>
          </>
        )
      }}
    </Form>
  )
}
```

### Form with Success/Error Callbacks

```typescript
function RegistrationForm() {
  const { toast } = useToast()
  
  const handleSuccess = (data: FormValues) => {
    toast({
      title: 'Success!',
      description: 'Your account has been created.',
    })
    router.push('/dashboard')
  }
  
  const handleError = (error: Error) => {
    toast({
      title: 'Error',
      description: error.message,
      variant: 'destructive',
    })
  }

  return (
    <Form
      schema={registrationSchema}
      onSubmit={handleSubmit}
      onSuccess={handleSuccess}
      onError={handleError}
      resetOnSuccess
    >
      <FormField name="username" label="Username" required />
      <FormField name="email" label="Email" type="email" required />
      <FormField name="password" label="Password" type="password" required />
      
      <FormActions>
        <Button type="submit">Create Account</Button>
      </FormActions>
    </Form>
  )
}
```

### Complex Validation Example

```typescript
const complexSchema = z.object({
  username: z.string()
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be less than 20 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Only letters, numbers, and underscores allowed'),
  
  email: z.string()
    .email('Invalid email address')
    .refine(async (email) => {
      const exists = await checkEmailExists(email)
      return !exists
    }, 'Email already registered'),
  
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain an uppercase letter')
    .regex(/[a-z]/, 'Password must contain a lowercase letter')
    .regex(/[0-9]/, 'Password must contain a number'),
  
  confirmPassword: z.string(),
  
  terms: z.boolean().refine((val) => val === true, {
    message: 'You must accept the terms and conditions',
  }),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
})

function ComplexForm() {
  return (
    <Form
      schema={complexSchema}
      defaultValues={{
        username: '',
        email: '',
        password: '',
        confirmPassword: '',
        terms: false,
      }}
      onSubmit={handleSubmit}
      mode="onBlur"
    >
      <FormField name="username" label="Username" required />
      <FormField name="email" label="Email" type="email" required />
      <FormField name="password" label="Password" type="password" required />
      <FormField name="confirmPassword" label="Confirm Password" type="password" required />
      <FormField
        name="terms"
        label="I accept the terms and conditions"
        type="checkbox"
        required
      />
      
      <FormActions>
        <Button type="submit">Register</Button>
      </FormActions>
    </Form>
  )
}
```

### Form with Grid Layout

```typescript
function ContactForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormField name="firstName" label="First Name" required />
        <FormField name="lastName" label="Last Name" required />
        <FormField name="email" label="Email" type="email" required className="md:col-span-2" />
        <FormField name="phone" label="Phone" type="tel" />
        <FormField name="company" label="Company" />
      </div>
      
      <FormField name="message" label="Message" type="textarea" rows={4} required />
      
      <FormActions>
        <Button type="submit">Send Message</Button>
      </FormActions>
    </Form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Semantic HTML structure
- ✅ Proper form labels
- ✅ Error announcements
- ✅ Focus management
- ✅ Keyboard navigation

### Best Practices
- Use `noValidate` to handle custom validation
- Automatic focus on first error field
- Clear error messages
- Proper ARIA attributes

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install react-hook-form, zod, @hookform/resolvers
- [ ] Create form.tsx file
- [ ] Implement Form component
- [ ] Implement FormSection component
- [ ] Implement FormActions component
- [ ] Add loading state overlay
- [ ] Add success/error callbacks
- [ ] Write comprehensive tests
- [ ] Test validation flows
- [ ] Test accessibility
- [ ] Create Storybook stories
- [ ] Document patterns

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
