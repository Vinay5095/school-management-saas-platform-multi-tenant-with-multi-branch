# SPEC-REGISTER-FORM: User Registration Component
## Complete Registration Form with Multi-Step Flow

> **Status**: 📝 PLANNED  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Dependencies**: SPEC-LOGIN-FORM, SPEC-037 (Auth Context), SPEC-036 (Auth API)

---

## 📋 OVERVIEW

Complete user registration form component with multi-step flow, comprehensive validation, email verification, and role assignment. This component handles new user onboarding for all user types in the school management system.

### Key Features
- Multi-step registration flow
- Role-based registration paths
- Email verification integration
- Password strength validation
- Terms of service acceptance
- Real-time availability checking
- Invite code support (for staff)
- Profile picture upload
- School/tenant selection
- Comprehensive validation

---

## 🎯 TECHNICAL REQUIREMENTS

### Registration Flow
```typescript
interface RegistrationFlow {
  step1: BasicInformation    // Email, password, name
  step2: RoleSelection      // Student, parent, staff
  step3: ProfileDetails     // Role-specific information
  step4: Verification       // Email verification
  step5: Completion         // Account activation
}
```

### Form Data Structure
```typescript
interface RegisterFormData {
  // Step 1: Basic Information
  email: string
  password: string
  confirmPassword: string
  firstName: string
  lastName: string
  phone?: string
  
  // Step 2: Role Selection
  role: 'student' | 'parent' | 'teacher' | 'admin' | 'staff'
  inviteCode?: string  // Required for staff roles
  
  // Step 3: Profile Details (varies by role)
  dateOfBirth?: Date
  gender?: 'male' | 'female' | 'other'
  address?: Address
  emergencyContact?: EmergencyContact
  profilePicture?: File
  
  // Step 4: Agreements
  acceptTerms: boolean
  acceptPrivacy: boolean
  marketingConsent: boolean
  
  // Meta
  tenantId?: string
  referralSource?: string
}
```

---

## 🔧 IMPLEMENTATION

### 1. Main Registration Component

#### `src/components/auth/register-form.tsx`
```typescript
'use client'

/**
 * Multi-Step Registration Form
 * Handles complete user registration flow
 */

import { useState, useEffect } from 'react'
import { useForm, FormProvider } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { useAuth } from '@/hooks/use-auth'
import { registerFormSchema, type RegisterFormData } from '@/lib/validations/auth'
import { cn } from '@/lib/utils'

// Step Components
import { BasicInformationStep } from './steps/basic-information'
import { RoleSelectionStep } from './steps/role-selection'
import { ProfileDetailsStep } from './steps/profile-details'
import { VerificationStep } from './steps/verification'
import { CompletionStep } from './steps/completion'

interface RegisterFormProps {
  onSuccess?: () => void
  onError?: (error: string) => void
  className?: string
  inviteCode?: string
  tenantId?: string
}

const STEPS = [
  { id: 'basic', title: 'Basic Information', description: 'Your personal details' },
  { id: 'role', title: 'Role Selection', description: 'Choose your role in the system' },
  { id: 'profile', title: 'Profile Details', description: 'Additional information' },
  { id: 'verification', title: 'Email Verification', description: 'Verify your email address' },
  { id: 'completion', title: 'Complete', description: 'Account setup complete' },
]

export function RegisterForm({
  onSuccess,
  onError,
  className,
  inviteCode,
  tenantId,
}: RegisterFormProps) {
  const [currentStep, setCurrentStep] = useState(0)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { signUp, verifyEmail, isLoading } = useAuth()

  const methods = useForm<RegisterFormData>({
    resolver: zodResolver(registerFormSchema),
    mode: 'onChange',
    defaultValues: {
      inviteCode,
      tenantId,
      acceptTerms: false,
      acceptPrivacy: false,
      marketingConsent: false,
    },
  })

  const { 
    handleSubmit, 
    watch, 
    trigger, 
    formState: { errors, isValid },
    setValue,
  } = methods

  // Watch current step data for validation
  const watchedData = watch()
  const currentStepData = getCurrentStepData(currentStep, watchedData)

  const nextStep = async () => {
    const isStepValid = await validateCurrentStep()
    if (isStepValid && currentStep < STEPS.length - 1) {
      setCurrentStep(currentStep + 1)
    }
  }

  const prevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1)
    }
  }

  const validateCurrentStep = async (): Promise<boolean> => {
    const stepFields = getStepFields(currentStep)
    return await trigger(stepFields)
  }

  const onSubmit = async (data: RegisterFormData) => {
    try {
      setIsSubmitting(true)

      // Submit registration data
      const response = await signUp(data)

      if (response.success) {
        // Move to verification step
        setCurrentStep(3)
      } else {
        onError?.(response.error?.message || 'Registration failed')
      }
    } catch (error: any) {
      onError?.(error.message || 'An unexpected error occurred')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleEmailVerification = async (token: string) => {
    try {
      const response = await verifyEmail(token)
      
      if (response.success) {
        setCurrentStep(4) // Move to completion
        onSuccess?.()
      } else {
        onError?.('Email verification failed')
      }
    } catch (error: any) {
      onError?.(error.message)
    }
  }

  const progressPercentage = ((currentStep + 1) / STEPS.length) * 100

  return (
    <div className={cn('max-w-2xl mx-auto', className)}>
      <Card>
        <CardHeader>
          <CardTitle>Create your account</CardTitle>
          <CardDescription>
            {STEPS[currentStep].description}
          </CardDescription>
          
          {/* Progress Indicator */}
          <div className="space-y-2">
            <Progress value={progressPercentage} className="h-2" />
            <div className="flex justify-between text-xs text-muted-foreground">
              {STEPS.map((step, index) => (
                <span
                  key={step.id}
                  className={cn('truncate', {
                    'text-primary font-medium': index === currentStep,
                    'text-green-600': index < currentStep,
                  })}
                >
                  {step.title}
                </span>
              ))}
            </div>
          </div>
        </CardHeader>

        <CardContent>
          <FormProvider {...methods}>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              {/* Step Content */}
              {currentStep === 0 && (
                <BasicInformationStep />
              )}
              
              {currentStep === 1 && (
                <RoleSelectionStep />
              )}
              
              {currentStep === 2 && (
                <ProfileDetailsStep role={watchedData.role} />
              )}
              
              {currentStep === 3 && (
                <VerificationStep 
                  email={watchedData.email}
                  onVerificationSuccess={handleEmailVerification}
                />
              )}
              
              {currentStep === 4 && (
                <CompletionStep 
                  userData={watchedData}
                  onComplete={onSuccess}
                />
              )}

              {/* Navigation Buttons */}
              <div className="flex justify-between pt-6">
                <Button
                  type="button"
                  variant="outline"
                  onClick={prevStep}
                  disabled={currentStep === 0 || isSubmitting}
                >
                  Previous
                </Button>

                {currentStep < 2 && (
                  <Button
                    type="button"
                    onClick={nextStep}
                    disabled={!isStepValid(currentStep, watchedData)}
                  >
                    Next
                  </Button>
                )}

                {currentStep === 2 && (
                  <Button
                    type="submit"
                    disabled={isSubmitting || !isValid}
                  >
                    {isSubmitting ? 'Creating Account...' : 'Create Account'}
                  </Button>
                )}
              </div>
            </form>
          </FormProvider>
        </CardContent>
      </Card>

      {/* Login Link */}
      <div className="mt-6 text-center text-sm">
        <span className="text-muted-foreground">Already have an account? </span>
        <Button
          variant="link"
          size="sm"
          className="px-0 font-normal"
          onClick={() => window.location.href = '/login'}
        >
          Sign in
        </Button>
      </div>
    </div>
  )
}

// Helper functions
function getCurrentStepData(step: number, data: RegisterFormData) {
  switch (step) {
    case 0:
      return {
        email: data.email,
        password: data.password,
        confirmPassword: data.confirmPassword,
        firstName: data.firstName,
        lastName: data.lastName,
      }
    case 1:
      return {
        role: data.role,
        inviteCode: data.inviteCode,
      }
    case 2:
      return {
        dateOfBirth: data.dateOfBirth,
        gender: data.gender,
        phone: data.phone,
        address: data.address,
        emergencyContact: data.emergencyContact,
        acceptTerms: data.acceptTerms,
        acceptPrivacy: data.acceptPrivacy,
      }
    default:
      return data
  }
}

function getStepFields(step: number): (keyof RegisterFormData)[] {
  switch (step) {
    case 0:
      return ['email', 'password', 'confirmPassword', 'firstName', 'lastName']
    case 1:
      return ['role', 'inviteCode']
    case 2:
      return ['acceptTerms', 'acceptPrivacy']
    default:
      return []
  }
}

function isStepValid(step: number, data: RegisterFormData): boolean {
  switch (step) {
    case 0:
      return !!(data.email && data.password && data.confirmPassword && 
               data.firstName && data.lastName)
    case 1:
      return !!(data.role && (data.role === 'student' || data.role === 'parent' || data.inviteCode))
    case 2:
      return !!(data.acceptTerms && data.acceptPrivacy)
    default:
      return true
  }
}
```

### 2. Step Components

#### `src/components/auth/steps/basic-information.tsx`
```typescript
'use client'

import { useState } from 'react'
import { useFormContext } from 'react-hook-form'
import { Eye, EyeOff, Check, X } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { validatePasswordStrength } from '@/lib/validations/password'
import { checkEmailAvailability } from '@/lib/api/auth'
import { cn } from '@/lib/utils'

export function BasicInformationStep() {
  const { register, watch, formState: { errors } } = useFormContext()
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [emailAvailable, setEmailAvailable] = useState<boolean | null>(null)
  const [checkingEmail, setCheckingEmail] = useState(false)

  const password = watch('password')
  const email = watch('email')
  const passwordStrength = password ? validatePasswordStrength(password) : null

  // Check email availability
  const handleEmailBlur = async () => {
    if (email && !errors.email) {
      setCheckingEmail(true)
      try {
        const available = await checkEmailAvailability(email)
        setEmailAvailable(available)
      } catch (error) {
        setEmailAvailable(null)
      } finally {
        setCheckingEmail(false)
      }
    }
  }

  return (
    <div className="space-y-6">
      <div className="space-y-4">
        <h3 className="text-lg font-medium">Basic Information</h3>
        <p className="text-sm text-muted-foreground">
          Let's start with your basic details
        </p>
      </div>

      <div className="grid grid-cols-2 gap-4">
        {/* First Name */}
        <div className="space-y-2">
          <Label htmlFor="firstName">First Name</Label>
          <Input
            id="firstName"
            {...register('firstName')}
            placeholder="John"
            className={cn({
              'border-destructive': errors.firstName,
            })}
          />
          {errors.firstName && (
            <p className="text-sm text-destructive">
              {errors.firstName.message}
            </p>
          )}
        </div>

        {/* Last Name */}
        <div className="space-y-2">
          <Label htmlFor="lastName">Last Name</Label>
          <Input
            id="lastName"
            {...register('lastName')}
            placeholder="Doe"
            className={cn({
              'border-destructive': errors.lastName,
            })}
          />
          {errors.lastName && (
            <p className="text-sm text-destructive">
              {errors.lastName.message}
            </p>
          )}
        </div>
      </div>

      {/* Email */}
      <div className="space-y-2">
        <Label htmlFor="email">Email Address</Label>
        <div className="relative">
          <Input
            id="email"
            type="email"
            {...register('email')}
            placeholder="you@example.com"
            onBlur={handleEmailBlur}
            className={cn('pr-10', {
              'border-destructive': errors.email || emailAvailable === false,
              'border-green-500': emailAvailable === true,
            })}
          />
          {checkingEmail && (
            <div className="absolute right-3 top-3">
              <div className="animate-spin h-4 w-4 border-2 border-primary border-t-transparent rounded-full" />
            </div>
          )}
          {!checkingEmail && emailAvailable === true && (
            <Check className="absolute right-3 top-3 h-4 w-4 text-green-500" />
          )}
          {!checkingEmail && emailAvailable === false && (
            <X className="absolute right-3 top-3 h-4 w-4 text-destructive" />
          )}
        </div>
        {errors.email && (
          <p className="text-sm text-destructive">
            {errors.email.message}
          </p>
        )}
        {emailAvailable === false && (
          <p className="text-sm text-destructive">
            This email is already registered. Try <a href="/login" className="underline">signing in</a> instead.
          </p>
        )}
      </div>

      {/* Password */}
      <div className="space-y-2">
        <Label htmlFor="password">Password</Label>
        <div className="relative">
          <Input
            id="password"
            type={showPassword ? 'text' : 'password'}
            {...register('password')}
            placeholder="Create a strong password"
            className={cn('pr-10', {
              'border-destructive': errors.password,
            })}
          />
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="absolute right-0 top-0 h-full px-3"
            onClick={() => setShowPassword(!showPassword)}
          >
            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </Button>
        </div>
        
        {/* Password Strength Indicator */}
        {password && passwordStrength && (
          <div className="space-y-2">
            <Progress 
              value={passwordStrength.score * 25} 
              className={cn('h-2', {
                '[&>div]:bg-red-500': passwordStrength.score <= 1,
                '[&>div]:bg-orange-500': passwordStrength.score === 2,
                '[&>div]:bg-yellow-500': passwordStrength.score === 3,
                '[&>div]:bg-green-500': passwordStrength.score === 4,
              })}
            />
            <div className="flex justify-between text-xs">
              <span className={cn({
                'text-red-500': passwordStrength.score <= 1,
                'text-orange-500': passwordStrength.score === 2,
                'text-yellow-500': passwordStrength.score === 3,
                'text-green-500': passwordStrength.score === 4,
              })}>
                {passwordStrength.feedback}
              </span>
              <span className="text-muted-foreground">
                {passwordStrength.score}/4
              </span>
            </div>
          </div>
        )}
        
        {errors.password && (
          <p className="text-sm text-destructive">
            {errors.password.message}
          </p>
        )}
      </div>

      {/* Confirm Password */}
      <div className="space-y-2">
        <Label htmlFor="confirmPassword">Confirm Password</Label>
        <div className="relative">
          <Input
            id="confirmPassword"
            type={showConfirmPassword ? 'text' : 'password'}
            {...register('confirmPassword')}
            placeholder="Confirm your password"
            className={cn('pr-10', {
              'border-destructive': errors.confirmPassword,
            })}
          />
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="absolute right-0 top-0 h-full px-3"
            onClick={() => setShowConfirmPassword(!showConfirmPassword)}
          >
            {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </Button>
        </div>
        {errors.confirmPassword && (
          <p className="text-sm text-destructive">
            {errors.confirmPassword.message}
          </p>
        )}
      </div>
    </div>
  )
}
```

---

## 🧪 TESTING

### Unit Tests

#### `src/components/auth/__tests__/register-form.test.tsx`
```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { RegisterForm } from '../register-form'
import { AuthProvider } from '@/contexts/auth-context'

const renderRegisterForm = (props = {}) => {
  return render(
    <AuthProvider>
      <RegisterForm {...props} />
    </AuthProvider>
  )
}

describe('RegisterForm', () => {
  it('renders the first step correctly', () => {
    renderRegisterForm()
    
    expect(screen.getByText('Basic Information')).toBeInTheDocument()
    expect(screen.getByLabelText('First Name')).toBeInTheDocument()
    expect(screen.getByLabelText('Last Name')).toBeInTheDocument()
    expect(screen.getByLabelText('Email Address')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
    expect(screen.getByLabelText('Confirm Password')).toBeInTheDocument()
  })

  it('validates required fields in step 1', async () => {
    const user = userEvent.setup()
    renderRegisterForm()
    
    const nextButton = screen.getByText('Next')
    await user.click(nextButton)
    
    // Should not progress without valid data
    expect(screen.getByText('Basic Information')).toBeInTheDocument()
  })

  it('progresses through steps with valid data', async () => {
    const user = userEvent.setup()
    renderRegisterForm()
    
    // Fill step 1
    await user.type(screen.getByLabelText('First Name'), 'John')
    await user.type(screen.getByLabelText('Last Name'), 'Doe')
    await user.type(screen.getByLabelText('Email Address'), 'john@example.com')
    await user.type(screen.getByLabelText('Password'), 'StrongPassword123!')
    await user.type(screen.getByLabelText('Confirm Password'), 'StrongPassword123!')
    
    const nextButton = screen.getByText('Next')
    await user.click(nextButton)
    
    // Should progress to step 2
    await waitFor(() => {
      expect(screen.getByText('Role Selection')).toBeInTheDocument()
    })
  })

  it('shows password strength indicator', async () => {
    const user = userEvent.setup()
    renderRegisterForm()
    
    const passwordInput = screen.getByLabelText('Password')
    await user.type(passwordInput, 'weak')
    
    expect(screen.getByRole('progressbar')).toBeInTheDocument()
  })

  it('validates email availability', async () => {
    const user = userEvent.setup()
    renderRegisterForm()
    
    const emailInput = screen.getByLabelText('Email Address')
    await user.type(emailInput, 'existing@example.com')
    await user.tab() // Trigger blur
    
    // Mock API would return false for existing email
    await waitFor(() => {
      expect(screen.getByText(/This email is already registered/)).toBeInTheDocument()
    })
  })
})
```

---

## ✅ COMPLETION CHECKLIST

- [ ] Multi-step form structure implemented
- [ ] Step navigation with validation
- [ ] Basic information step component
- [ ] Role selection step component  
- [ ] Profile details step component
- [ ] Email verification step component
- [ ] Completion step component
- [ ] Password strength validation
- [ ] Email availability checking
- [ ] Form state management
- [ ] Error handling and display
- [ ] Progress indicator
- [ ] Responsive design
- [ ] Accessibility features
- [ ] Unit tests written
- [ ] Integration tests added
- [ ] Documentation completed

---

## 🔗 RELATED SPECIFICATIONS

- **SPEC-LOGIN-FORM**: Login component (navigation after registration)
- **SPEC-037**: Auth Context (provides registration methods)
- **SPEC-036**: Authentication API (registration endpoints)
- **SPEC-044**: Password Policy (password validation rules)
- **SPEC-045**: Auth Error Handling (error management)

---

**File**: `SPEC-REGISTER-FORM.md`  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Status**: 📝 PLANNED