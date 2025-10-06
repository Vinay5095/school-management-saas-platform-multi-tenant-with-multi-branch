# SPEC-063: FormField Component
## Universal Form Field Wrapper with React Hook Form

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 5 hours  
> **Dependencies**: React Hook Form

---

## 📋 OVERVIEW

### Purpose
A universal form field wrapper component that integrates all form input components with React Hook Form, providing consistent field registration, error handling, and validation across all form fields.

### Key Features
- ✅ Automatic React Hook Form registration
- ✅ Supports all input component types
- ✅ Automatic error display
- ✅ Label and description support
- ✅ Required field indicators
- ✅ Consistent styling
- ✅ TypeScript support
- ✅ Controller wrapper for complex components
- ✅ Field array support
- ✅ Custom validation

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/form-field.tsx
'use client'

import * as React from 'react'
import { useFormContext, Controller, FieldValues, Path, PathValue } from 'react-hook-form'
import { cn } from '@/lib/utils'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select } from '@/components/ui/select'
import { Checkbox } from '@/components/ui/checkbox'
import { Radio, RadioGroup } from '@/components/ui/radio'
import { Switch } from '@/components/ui/switch'
import { Slider } from '@/components/ui/slider'
import { DatePicker, DateRangePicker } from '@/components/ui/date-picker'
import { TimePicker } from '@/components/ui/time-picker'
import { FileUpload } from '@/components/ui/file-upload'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type FormFieldType =
  | 'text'
  | 'email'
  | 'password'
  | 'number'
  | 'tel'
  | 'url'
  | 'textarea'
  | 'select'
  | 'checkbox'
  | 'radio'
  | 'switch'
  | 'slider'
  | 'date'
  | 'dateRange'
  | 'time'
  | 'file'

export interface SelectOption {
  value: string | number
  label: string
  disabled?: boolean
}

export interface FormFieldProps<TFieldValues extends FieldValues = FieldValues> {
  /**
   * Field name (must match schema property)
   */
  name: Path<TFieldValues>
  
  /**
   * Field type
   */
  type?: FormFieldType
  
  /**
   * Field label
   */
  label?: string
  
  /**
   * Description text shown below label
   */
  description?: string
  
  /**
   * Placeholder text
   */
  placeholder?: string
  
  /**
   * Whether the field is required
   */
  required?: boolean
  
  /**
   * Whether the field is disabled
   */
  disabled?: boolean
  
  /**
   * Options for select, radio, or checkbox groups
   */
  options?: SelectOption[]
  
  /**
   * Additional props passed to the input component
   */
  inputProps?: Record<string, any>
  
  /**
   * Custom render function for the input
   */
  render?: (field: any) => React.ReactNode
  
  /**
   * Additional CSS classes
   */
  className?: string
  
  /**
   * Transform value before setting (useful for number inputs)
   */
  transformValue?: (value: any) => any
}

// ========================================
// FORM FIELD COMPONENT
// ========================================

/**
 * FormField Component
 * 
 * A universal form field wrapper that integrates with React Hook Form.
 * Automatically handles registration, validation, and error display.
 * 
 * @example
 * // Basic text input
 * <FormField name="username" label="Username" required />
 * 
 * @example
 * // Select field
 * <FormField
 *   name="country"
 *   type="select"
 *   label="Country"
 *   options={[
 *     { value: 'us', label: 'United States' },
 *     { value: 'uk', label: 'United Kingdom' }
 *   ]}
 * />
 * 
 * @example
 * // Custom render
 * <FormField
 *   name="customField"
 *   render={({ field }) => (
 *     <CustomComponent {...field} />
 *   )}
 * />
 */
export function FormField<TFieldValues extends FieldValues = FieldValues>({
  name,
  type = 'text',
  label,
  description,
  placeholder,
  required,
  disabled,
  options,
  inputProps = {},
  render,
  className,
  transformValue,
}: FormFieldProps<TFieldValues>) {
  const {
    register,
    control,
    formState: { errors },
  } = useFormContext<TFieldValues>()

  // Get error message for this field
  const error = errors[name]?.message as string | undefined

  // Helper to get nested error messages
  const getNestedError = (name: string) => {
    const parts = name.split('.')
    let current: any = errors
    for (const part of parts) {
      if (!current) return undefined
      current = current[part]
    }
    return current?.message as string | undefined
  }

  const fieldError = error || getNestedError(name as string)

  // Render custom component
  if (render) {
    return (
      <div className={cn('space-y-2', className)}>
        <Controller
          name={name}
          control={control}
          render={({ field }) => render(field)}
        />
        {fieldError && (
          <p className="text-sm text-destructive" role="alert">
            {fieldError}
          </p>
        )}
      </div>
    )
  }

  // Simple inputs (text, email, password, etc.)
  if (['text', 'email', 'password', 'number', 'tel', 'url'].includes(type)) {
    return (
      <Input
        {...register(name, {
          ...(transformValue && {
            setValueAs: transformValue,
          }),
        })}
        type={type}
        label={label}
        description={description}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        error={fieldError}
        className={className}
        {...inputProps}
      />
    )
  }

  // Textarea
  if (type === 'textarea') {
    return (
      <Textarea
        {...register(name)}
        label={label}
        description={description}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        error={fieldError}
        className={className}
        {...inputProps}
      />
    )
  }

  // Select
  if (type === 'select') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <Select
            {...field}
            label={label}
            description={description}
            placeholder={placeholder}
            required={required}
            disabled={disabled}
            error={fieldError}
            options={options || []}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Checkbox (single)
  if (type === 'checkbox' && !options) {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <Checkbox
            checked={field.value}
            onCheckedChange={field.onChange}
            label={label}
            description={description}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Checkbox group
  if (type === 'checkbox' && options) {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <Checkbox
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            options={options}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Radio group
  if (type === 'radio') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <RadioGroup
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            required={required}
            disabled={disabled}
            error={fieldError}
            options={options || []}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Switch
  if (type === 'switch') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <Switch
            checked={field.value}
            onCheckedChange={field.onChange}
            label={label}
            description={description}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Slider
  if (type === 'slider') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <Slider
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Date picker
  if (type === 'date') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <DatePicker
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            placeholder={placeholder}
            required={required}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Date range picker
  if (type === 'dateRange') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <DateRangePicker
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            placeholder={placeholder}
            required={required}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Time picker
  if (type === 'time') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <TimePicker
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            placeholder={placeholder}
            required={required}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // File upload
  if (type === 'file') {
    return (
      <Controller
        name={name}
        control={control}
        render={({ field }) => (
          <FileUpload
            value={field.value}
            onValueChange={field.onChange}
            label={label}
            description={description}
            required={required}
            disabled={disabled}
            error={fieldError}
            className={className}
            {...inputProps}
          />
        )}
      />
    )
  }

  // Default fallback
  return (
    <Input
      {...register(name)}
      label={label}
      description={description}
      placeholder={placeholder}
      required={required}
      disabled={disabled}
      error={fieldError}
      className={className}
      {...inputProps}
    />
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Text Inputs

```typescript
import { Form } from '@/components/ui/form'
import { FormField } from '@/components/ui/form-field'

function UserForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField name="username" label="Username" required />
      <FormField name="email" type="email" label="Email" required />
      <FormField name="password" type="password" label="Password" required />
      <FormField name="age" type="number" label="Age" />
    </Form>
  )
}
```

### Select and Radio Fields

```typescript
function PreferencesForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField
        name="country"
        type="select"
        label="Country"
        placeholder="Select country"
        options={[
          { value: 'us', label: 'United States' },
          { value: 'uk', label: 'United Kingdom' },
          { value: 'ca', label: 'Canada' },
        ]}
        required
      />
      
      <FormField
        name="plan"
        type="radio"
        label="Subscription Plan"
        options={[
          { value: 'free', label: 'Free' },
          { value: 'pro', label: 'Pro - $9/month' },
          { value: 'enterprise', label: 'Enterprise - Contact Us' },
        ]}
        required
      />
    </Form>
  )
}
```

### Checkbox and Switch Fields

```typescript
function SettingsForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField
        name="terms"
        type="checkbox"
        label="I accept the terms and conditions"
        required
      />
      
      <FormField
        name="notifications"
        type="switch"
        label="Enable notifications"
        description="Receive email updates about your account"
      />
      
      <FormField
        name="interests"
        type="checkbox"
        label="Interests"
        description="Select your areas of interest"
        options={[
          { value: 'tech', label: 'Technology' },
          { value: 'design', label: 'Design' },
          { value: 'business', label: 'Business' },
        ]}
      />
    </Form>
  )
}
```

### Date and Time Fields

```typescript
function EventForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField
        name="eventDate"
        type="date"
        label="Event Date"
        required
        inputProps={{
          minDate: new Date(),
        }}
      />
      
      <FormField
        name="eventTime"
        type="time"
        label="Event Time"
        required
        inputProps={{
          use12Hour: true,
          minuteStep: 15,
        }}
      />
      
      <FormField
        name="dateRange"
        type="dateRange"
        label="Availability Period"
        inputProps={{
          showPresets: true,
        }}
      />
    </Form>
  )
}
```

### File Upload Field

```typescript
function DocumentForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField
        name="resume"
        type="file"
        label="Resume"
        description="Upload your resume (PDF only, max 5MB)"
        required
        inputProps={{
          accept: { 'application/pdf': ['.pdf'] },
          maxSize: 5 * 1024 * 1024,
        }}
      />
      
      <FormField
        name="documents"
        type="file"
        label="Additional Documents"
        description="Upload supporting documents"
        inputProps={{
          multiple: true,
          maxFiles: 5,
          showPreview: true,
        }}
      />
    </Form>
  )
}
```

### Custom Render

```typescript
import { CustomColorPicker } from '@/components/custom-color-picker'

function ThemeForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField
        name="primaryColor"
        label="Primary Color"
        render={({ field }) => (
          <CustomColorPicker
            value={field.value}
            onChange={field.onChange}
          />
        )}
      />
    </Form>
  )
}
```

### With Transform Value

```typescript
function PriceForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField
        name="price"
        type="number"
        label="Price"
        placeholder="0.00"
        transformValue={(value) => value === '' ? undefined : parseFloat(value)}
        inputProps={{
          step: 0.01,
          min: 0,
        }}
      />
    </Form>
  )
}
```

### Nested Fields

```typescript
const schema = z.object({
  user: z.object({
    name: z.string(),
    email: z.string().email(),
  }),
  address: z.object({
    street: z.string(),
    city: z.string(),
  }),
})

function NestedForm() {
  return (
    <Form schema={schema} onSubmit={handleSubmit}>
      <FormField name="user.name" label="Full Name" required />
      <FormField name="user.email" type="email" label="Email" required />
      <FormField name="address.street" label="Street Address" />
      <FormField name="address.city" label="City" />
    </Form>
  )
}
```

### Complete Profile Form Example

```typescript
const profileSchema = z.object({
  firstName: z.string().min(1, 'Required'),
  lastName: z.string().min(1, 'Required'),
  email: z.string().email(),
  phone: z.string().optional(),
  birthDate: z.date(),
  gender: z.enum(['male', 'female', 'other']),
  country: z.string().min(1, 'Required'),
  bio: z.string().max(500),
  interests: z.array(z.string()),
  newsletter: z.boolean(),
  profilePicture: z.instanceof(File).optional(),
})

function CompleteProfileForm() {
  return (
    <Form
      schema={profileSchema}
      defaultValues={{
        interests: [],
        newsletter: false,
      }}
      onSubmit={handleSubmit}
    >
      <div className="grid grid-cols-2 gap-4">
        <FormField name="firstName" label="First Name" required />
        <FormField name="lastName" label="Last Name" required />
      </div>
      
      <FormField name="email" type="email" label="Email" required />
      <FormField name="phone" type="tel" label="Phone" />
      <FormField name="birthDate" type="date" label="Date of Birth" required />
      
      <FormField
        name="gender"
        type="radio"
        label="Gender"
        options={[
          { value: 'male', label: 'Male' },
          { value: 'female', label: 'Female' },
          { value: 'other', label: 'Other' },
        ]}
        required
      />
      
      <FormField
        name="country"
        type="select"
        label="Country"
        placeholder="Select country"
        options={countryOptions}
        required
      />
      
      <FormField
        name="bio"
        type="textarea"
        label="Bio"
        description="Tell us about yourself (max 500 characters)"
        inputProps={{
          maxLength: 500,
          showCharacterCount: true,
        }}
      />
      
      <FormField
        name="interests"
        type="checkbox"
        label="Interests"
        options={interestOptions}
      />
      
      <FormField
        name="newsletter"
        type="switch"
        label="Subscribe to newsletter"
      />
      
      <FormField
        name="profilePicture"
        type="file"
        label="Profile Picture"
        inputProps={{
          accept: { 'image/*': ['.png', '.jpg', '.jpeg'] },
          maxSize: 2 * 1024 * 1024,
          showPreview: true,
        }}
      />
      
      <FormActions>
        <Button type="button" variant="outline">Cancel</Button>
        <Button type="submit">Save Profile</Button>
      </FormActions>
    </Form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Automatic label association
- ✅ Error announcements
- ✅ Required field indicators
- ✅ Proper field roles
- ✅ Keyboard navigation

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create form-field.tsx file
- [ ] Implement FormField component
- [ ] Add support for all input types
- [ ] Add Controller wrapper for complex components
- [ ] Add error handling
- [ ] Add nested field support
- [ ] Write comprehensive tests
- [ ] Test with all component types
- [ ] Test accessibility
- [ ] Create Storybook stories
- [ ] Document all field types

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
