# SPEC-065: FormWizard Component
## Multi-Step Form with Navigation and Validation

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 8 hours  
> **Dependencies**: React Hook Form, Form, FormField, Button

---

## 📋 OVERVIEW

### Purpose
A multi-step form wizard component that guides users through complex forms with step-by-step validation, progress indication, and navigation controls. Ideal for registration flows, onboarding, and lengthy data entry processes.

### Key Features
- ✅ Multiple step management
- ✅ Step validation before proceeding
- ✅ Progress indicator
- ✅ Navigation controls (Next/Previous/Skip)
- ✅ Step state management
- ✅ Data persistence across steps
- ✅ Review/summary step
- ✅ Custom step components
- ✅ Conditional steps
- ✅ Mobile responsive
- ✅ Accessibility compliant
- ✅ Unsaved changes warning

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/form-wizard.tsx
'use client'

import * as React from 'react'
import { useForm, FormProvider, UseFormReturn } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ChevronLeft, ChevronRight, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface WizardStep {
  /**
   * Step identifier
   */
  id: string

  /**
   * Step title
   */
  title: string

  /**
   * Step description (optional)
   */
  description?: string

  /**
   * Validation schema for this step
   */
  schema?: z.ZodSchema

  /**
   * Step component
   */
  component: React.ComponentType<WizardStepComponentProps>

  /**
   * Whether step can be skipped
   */
  optional?: boolean

  /**
   * Function to determine if step should be shown
   */
  shouldShow?: (data: any) => boolean
}

export interface WizardStepComponentProps {
  /**
   * React Hook Form methods
   */
  form: UseFormReturn<any>

  /**
   * Navigate to next step
   */
  next: () => void

  /**
   * Navigate to previous step
   */
  previous: () => void

  /**
   * Skip current step
   */
  skip: () => void

  /**
   * All form data
   */
  data: any

  /**
   * Is first step
   */
  isFirst: boolean

  /**
   * Is last step
   */
  isLast: boolean
}

export interface FormWizardProps {
  /**
   * Wizard steps
   */
  steps: WizardStep[]

  /**
   * Form submission handler
   */
  onSubmit: (data: any) => void | Promise<void>

  /**
   * Initial form values
   */
  defaultValues?: Record<string, any>

  /**
   * Show progress bar
   */
  showProgress?: boolean

  /**
   * Show step numbers
   */
  showStepNumbers?: boolean

  /**
   * Allow navigation to previous steps
   */
  allowBackNavigation?: boolean

  /**
   * Save data on each step
   */
  persistStepData?: boolean

  /**
   * Callback when step changes
   */
  onStepChange?: (step: number, direction: 'next' | 'previous') => void

  /**
   * Custom submit button text
   */
  submitButtonText?: string

  /**
   * Loading state
   */
  isLoading?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// FORM WIZARD COMPONENT
// ========================================

/**
 * FormWizard Component
 * 
 * Multi-step form wizard with validation and navigation.
 * 
 * @example
 * <FormWizard
 *   steps={[
 *     { id: 'personal', title: 'Personal Info', component: PersonalStep, schema: personalSchema },
 *     { id: 'account', title: 'Account Details', component: AccountStep, schema: accountSchema },
 *     { id: 'review', title: 'Review', component: ReviewStep }
 *   ]}
 *   onSubmit={handleSubmit}
 * />
 */
export function FormWizard({
  steps,
  onSubmit,
  defaultValues = {},
  showProgress = true,
  showStepNumbers = true,
  allowBackNavigation = true,
  persistStepData = true,
  onStepChange,
  submitButtonText = 'Submit',
  isLoading = false,
  className,
}: FormWizardProps) {
  const [currentStepIndex, setCurrentStepIndex] = React.useState(0)
  const [completedSteps, setCompletedSteps] = React.useState<Set<number>>(new Set())
  const [formData, setFormData] = React.useState(defaultValues)

  // Filter steps based on shouldShow conditions
  const visibleSteps = steps.filter((step, index) => {
    if (!step.shouldShow) return true
    return step.shouldShow(formData)
  })

  const currentStep = visibleSteps[currentStepIndex]
  const isFirstStep = currentStepIndex === 0
  const isLastStep = currentStepIndex === visibleSteps.length - 1

  // Initialize form with current step schema
  const form = useForm({
    resolver: currentStep?.schema ? zodResolver(currentStep.schema) : undefined,
    defaultValues: formData,
    mode: 'onChange',
  })

  // Update form values when formData changes
  React.useEffect(() => {
    form.reset(formData)
  }, [formData, form])

  // Persist form data
  const persistData = React.useCallback(() => {
    if (persistStepData) {
      const currentValues = form.getValues()
      setFormData((prev) => ({ ...prev, ...currentValues }))
    }
  }, [form, persistStepData])

  // Navigate to next step
  const handleNext = async () => {
    const isValid = await form.trigger()

    if (isValid) {
      persistData()
      setCompletedSteps((prev) => new Set(prev).add(currentStepIndex))

      if (isLastStep) {
        // Submit form
        const finalData = { ...formData, ...form.getValues() }
        await onSubmit(finalData)
      } else {
        // Move to next step
        setCurrentStepIndex((prev) => prev + 1)
        onStepChange?.(currentStepIndex + 1, 'next')
      }
    }
  }

  // Navigate to previous step
  const handlePrevious = () => {
    if (!isFirstStep && allowBackNavigation) {
      persistData()
      setCurrentStepIndex((prev) => prev - 1)
      onStepChange?.(currentStepIndex - 1, 'previous')
    }
  }

  // Skip current step
  const handleSkip = () => {
    if (currentStep?.optional) {
      setCurrentStepIndex((prev) => prev + 1)
      onStepChange?.(currentStepIndex + 1, 'next')
    }
  }

  // Navigate to specific step
  const goToStep = (index: number) => {
    if (index < currentStepIndex || completedSteps.has(index)) {
      persistData()
      setCurrentStepIndex(index)
    }
  }

  const progress = ((currentStepIndex + 1) / visibleSteps.length) * 100

  return (
    <div className={cn('w-full space-y-8', className)}>
      {/* Progress Indicator */}
      {showProgress && (
        <div className="space-y-4">
          {/* Progress Bar */}
          <div className="h-2 bg-muted rounded-full overflow-hidden">
            <div
              className="h-full bg-primary transition-all duration-300"
              style={{ width: `${progress}%` }}
              role="progressbar"
              aria-valuenow={currentStepIndex + 1}
              aria-valuemin={1}
              aria-valuemax={visibleSteps.length}
              aria-label="Form progress"
            />
          </div>

          {/* Step Indicators */}
          <div className="flex justify-between">
            {visibleSteps.map((step, index) => {
              const isCompleted = completedSteps.has(index)
              const isCurrent = index === currentStepIndex
              const isAccessible = index < currentStepIndex || isCompleted

              return (
                <button
                  key={step.id}
                  onClick={() => isAccessible && goToStep(index)}
                  disabled={!isAccessible}
                  className={cn(
                    'flex flex-col items-center gap-2 transition-all',
                    'disabled:cursor-not-allowed disabled:opacity-50',
                    isAccessible && 'cursor-pointer hover:opacity-80'
                  )}
                  aria-current={isCurrent ? 'step' : undefined}
                >
                  {/* Step Number/Check */}
                  <div
                    className={cn(
                      'flex items-center justify-center w-10 h-10 rounded-full border-2 text-sm font-medium transition-colors',
                      isCurrent && 'border-primary bg-primary text-primary-foreground',
                      isCompleted && 'border-primary bg-primary text-primary-foreground',
                      !isCurrent && !isCompleted && 'border-muted-foreground text-muted-foreground'
                    )}
                  >
                    {isCompleted ? (
                      <Check className="h-5 w-5" />
                    ) : showStepNumbers ? (
                      index + 1
                    ) : null}
                  </div>

                  {/* Step Title */}
                  <div className="hidden sm:block text-center">
                    <p
                      className={cn(
                        'text-sm font-medium',
                        isCurrent && 'text-foreground',
                        isCompleted && 'text-foreground',
                        !isCurrent && !isCompleted && 'text-muted-foreground'
                      )}
                    >
                      {step.title}
                    </p>
                    {step.description && (
                      <p className="text-xs text-muted-foreground">{step.description}</p>
                    )}
                  </div>
                </button>
              )
            })}
          </div>
        </div>
      )}

      {/* Current Step Content */}
      <FormProvider {...form}>
        <form onSubmit={form.handleSubmit(handleNext)} className="space-y-6">
          {/* Step Header */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <h2 className="text-2xl font-bold">{currentStep.title}</h2>
              {currentStep.optional && (
                <span className="text-sm text-muted-foreground">(Optional)</span>
              )}
            </div>
            {currentStep.description && (
              <p className="text-muted-foreground">{currentStep.description}</p>
            )}
          </div>

          {/* Step Component */}
          <div className="py-4">
            <currentStep.component
              form={form}
              next={handleNext}
              previous={handlePrevious}
              skip={handleSkip}
              data={formData}
              isFirst={isFirstStep}
              isLast={isLastStep}
            />
          </div>

          {/* Navigation Buttons */}
          <div className="flex items-center justify-between gap-4 pt-6 border-t">
            {/* Previous Button */}
            <Button
              type="button"
              variant="outline"
              onClick={handlePrevious}
              disabled={isFirstStep || !allowBackNavigation}
              className={cn(!isFirstStep && allowBackNavigation && 'visible', 'invisible')}
            >
              <ChevronLeft className="h-4 w-4 mr-2" />
              Previous
            </Button>

            <div className="flex items-center gap-2">
              {/* Skip Button */}
              {currentStep.optional && !isLastStep && (
                <Button type="button" variant="ghost" onClick={handleSkip}>
                  Skip
                </Button>
              )}

              {/* Next/Submit Button */}
              <Button type="submit" disabled={isLoading}>
                {isLoading ? (
                  <>
                    <span className="animate-spin mr-2">⏳</span>
                    Processing...
                  </>
                ) : isLastStep ? (
                  submitButtonText
                ) : (
                  <>
                    Next
                    <ChevronRight className="h-4 w-4 ml-2" />
                  </>
                )}
              </Button>
            </div>
          </div>
        </form>
      </FormProvider>
    </div>
  )
}

// ========================================
// WIZARD STEP CONTAINER
// ========================================

export interface WizardStepContainerProps {
  /**
   * Step content
   */
  children: React.ReactNode

  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * WizardStepContainer Component
 * 
 * Container for wizard step content with consistent spacing.
 */
export function WizardStepContainer({
  children,
  className,
}: WizardStepContainerProps) {
  return <div className={cn('space-y-6', className)}>{children}</div>
}
```

---

## 📚 USAGE EXAMPLES

### Basic Multi-Step Form

```typescript
import { FormWizard, WizardStep, WizardStepContainer } from '@/components/ui/form-wizard'
import { FormField } from '@/components/ui/form-field'
import { z } from 'zod'

// Step 1: Personal Information
const personalSchema = z.object({
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(10, 'Phone number must be at least 10 digits'),
})

function PersonalStep({ form }: WizardStepComponentProps) {
  return (
    <WizardStepContainer>
      <div className="grid grid-cols-2 gap-4">
        <FormField name="firstName" label="First Name" required />
        <FormField name="lastName" label="Last Name" required />
      </div>
      <FormField name="email" type="email" label="Email" required />
      <FormField name="phone" type="tel" label="Phone Number" required />
    </WizardStepContainer>
  )
}

// Step 2: Account Details
const accountSchema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
})

function AccountStep({ form }: WizardStepComponentProps) {
  return (
    <WizardStepContainer>
      <FormField name="username" label="Username" required />
      <FormField name="password" type="password" label="Password" required />
      <FormField name="confirmPassword" type="password" label="Confirm Password" required />
    </WizardStepContainer>
  )
}

// Step 3: Review
function ReviewStep({ data }: WizardStepComponentProps) {
  return (
    <WizardStepContainer>
      <div className="space-y-4 rounded-lg border p-6">
        <h3 className="font-semibold">Personal Information</h3>
        <dl className="grid grid-cols-2 gap-4">
          <div>
            <dt className="text-sm text-muted-foreground">Name</dt>
            <dd className="font-medium">{data.firstName} {data.lastName}</dd>
          </div>
          <div>
            <dt className="text-sm text-muted-foreground">Email</dt>
            <dd className="font-medium">{data.email}</dd>
          </div>
          <div>
            <dt className="text-sm text-muted-foreground">Phone</dt>
            <dd className="font-medium">{data.phone}</dd>
          </div>
        </dl>

        <h3 className="font-semibold mt-6">Account Details</h3>
        <dl className="grid grid-cols-2 gap-4">
          <div>
            <dt className="text-sm text-muted-foreground">Username</dt>
            <dd className="font-medium">{data.username}</dd>
          </div>
        </dl>
      </div>
    </WizardStepContainer>
  )
}

// Wizard Configuration
const steps: WizardStep[] = [
  {
    id: 'personal',
    title: 'Personal Information',
    description: 'Tell us about yourself',
    schema: personalSchema,
    component: PersonalStep,
  },
  {
    id: 'account',
    title: 'Account Details',
    description: 'Create your account',
    schema: accountSchema,
    component: AccountStep,
  },
  {
    id: 'review',
    title: 'Review & Submit',
    description: 'Review your information',
    component: ReviewStep,
  },
]

function RegistrationWizard() {
  const handleSubmit = async (data: any) => {
    console.log('Form submitted:', data)
    // API call here
  }

  return (
    <FormWizard
      steps={steps}
      onSubmit={handleSubmit}
      submitButtonText="Create Account"
    />
  )
}
```

### Conditional Steps

```typescript
// Step only shows if user selects "Company" account type
const companyStep: WizardStep = {
  id: 'company',
  title: 'Company Information',
  component: CompanyStep,
  schema: companySchema,
  shouldShow: (data) => data.accountType === 'company',
}

const steps: WizardStep[] = [
  {
    id: 'account-type',
    title: 'Account Type',
    component: AccountTypeStep,
    schema: accountTypeSchema,
  },
  companyStep, // Conditionally shown
  {
    id: 'contact',
    title: 'Contact Information',
    component: ContactStep,
    schema: contactSchema,
  },
]
```

### Optional Steps

```typescript
const steps: WizardStep[] = [
  {
    id: 'required',
    title: 'Required Information',
    component: RequiredStep,
    schema: requiredSchema,
  },
  {
    id: 'optional',
    title: 'Additional Details',
    description: 'You can skip this step',
    component: OptionalStep,
    schema: optionalSchema,
    optional: true, // Step can be skipped
  },
  {
    id: 'final',
    title: 'Finalize',
    component: FinalStep,
  },
]
```

### With Data Persistence

```typescript
function OnboardingWizard() {
  const [savedData, setSavedData] = React.useState(() => {
    // Load from localStorage
    const saved = localStorage.getItem('onboarding-data')
    return saved ? JSON.parse(saved) : {}
  })

  const handleStepChange = (step: number, direction: 'next' | 'previous') => {
    console.log(`Moved to step ${step} (${direction})`)
  }

  const handleSubmit = async (data: any) => {
    try {
      await api.submitOnboarding(data)
      localStorage.removeItem('onboarding-data')
      router.push('/dashboard')
    } catch (error) {
      console.error('Submission failed:', error)
    }
  }

  return (
    <FormWizard
      steps={steps}
      onSubmit={handleSubmit}
      defaultValues={savedData}
      persistStepData
      onStepChange={handleStepChange}
    />
  )
}
```

### Complex Multi-Step Application

```typescript
const applicationSteps: WizardStep[] = [
  {
    id: 'applicant',
    title: 'Applicant Information',
    component: ApplicantStep,
    schema: applicantSchema,
  },
  {
    id: 'education',
    title: 'Education History',
    component: EducationStep,
    schema: educationSchema,
  },
  {
    id: 'employment',
    title: 'Employment History',
    component: EmploymentStep,
    schema: employmentSchema,
  },
  {
    id: 'references',
    title: 'References',
    component: ReferencesStep,
    schema: referencesSchema,
    optional: true,
  },
  {
    id: 'documents',
    title: 'Upload Documents',
    component: DocumentsStep,
    schema: documentsSchema,
  },
  {
    id: 'review',
    title: 'Review Application',
    component: ReviewStep,
  },
]

function JobApplicationWizard() {
  const [isSubmitting, setIsSubmitting] = React.useState(false)

  const handleSubmit = async (data: any) => {
    setIsSubmitting(true)
    try {
      await api.submitApplication(data)
      toast.success('Application submitted successfully!')
      router.push('/applications')
    } catch (error) {
      toast.error('Failed to submit application')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="max-w-4xl mx-auto py-12 px-4">
      <div className="mb-8 text-center">
        <h1 className="text-3xl font-bold">Job Application</h1>
        <p className="text-muted-foreground mt-2">
          Complete all steps to submit your application
        </p>
      </div>

      <FormWizard
        steps={applicationSteps}
        onSubmit={handleSubmit}
        isLoading={isSubmitting}
        submitButtonText="Submit Application"
        showProgress
        showStepNumbers
        allowBackNavigation
      />
    </div>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Keyboard navigation between steps
- ✅ Screen reader announcements for step changes
- ✅ Progress indicator with ARIA attributes
- ✅ Clear focus indicators
- ✅ Semantic HTML structure

### Keyboard Navigation
- **Tab**: Navigate between form fields
- **Enter**: Submit current step / Move to next
- **Escape**: Cancel (if applicable)

### Screen Reader Support
- Progress bar announces current step
- Step indicators labeled with status
- Navigation buttons clearly labeled
- Form errors announced

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create form-wizard.tsx file
- [ ] Implement FormWizard component
- [ ] Implement step navigation logic
- [ ] Implement progress indicator
- [ ] Add step validation
- [ ] Add data persistence
- [ ] Implement conditional steps
- [ ] Add optional step support
- [ ] Style with Tailwind CSS
- [ ] Add animations
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Test mobile responsiveness
- [ ] Create usage documentation
- [ ] Add Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
