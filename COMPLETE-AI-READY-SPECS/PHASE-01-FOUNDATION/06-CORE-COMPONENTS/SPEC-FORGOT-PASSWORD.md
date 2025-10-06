# SPEC-FORGOT-PASSWORD: Password Recovery Component
## Complete Password Reset Request Form

> **Status**: 📝 PLANNED  
> **Priority**: HIGH  
> **Estimated Time**: 3 hours  
> **Dependencies**: SPEC-037 (Auth Context), SPEC-036 (Auth API)

---

## 📋 OVERVIEW

Complete password recovery form component that handles password reset requests securely. This component allows users to request password reset emails and provides clear feedback about the process while preventing email enumeration attacks.

### Key Features
- Secure email validation
- Rate limiting protection
- Email enumeration prevention
- Clear user feedback
- Resend functionality
- Accessibility compliance
- Mobile-responsive design
- Loading states and error handling

---

## 🎯 TECHNICAL REQUIREMENTS

### Form Data Structure
```typescript
interface ForgotPasswordFormData {
  email: string
}

interface ForgotPasswordState {
  isLoading: boolean
  isSuccess: boolean
  error: string | null
  canResend: boolean
  nextResendTime: Date | null
  emailSent: boolean
}
```

### Security Features
- Rate limiting (3 requests per hour per email)
- Email enumeration prevention (always show success)
- CSRF protection
- Input sanitization
- Secure error handling

---

## 🔧 IMPLEMENTATION

### 1. Main Component

#### `src/components/auth/forgot-password-form.tsx`
```typescript
'use client'

/**
 * Forgot Password Form Component
 * Handles password reset requests securely
 */

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { Mail, ArrowLeft, Loader2, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { useAuth } from '@/hooks/use-auth'
import { cn } from '@/lib/utils'

// Validation Schema
const forgotPasswordSchema = z.object({
  email: z
    .string()
    .min(1, { message: 'Email is required' })
    .email({ message: 'Please enter a valid email address' })
    .max(255, { message: 'Email must be less than 255 characters' }),
})

type ForgotPasswordFormData = z.infer<typeof forgotPasswordSchema>

interface ForgotPasswordFormProps {
  onBack?: () => void
  onSuccess?: (email: string) => void
  onError?: (error: string) => void
  className?: string
  redirectTo?: string
}

export function ForgotPasswordForm({
  onBack,
  onSuccess,
  onError,
  className,
  redirectTo = '/reset-password',
}: ForgotPasswordFormProps) {
  const { resetPassword, isLoading } = useAuth()
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [submittedEmail, setSubmittedEmail] = useState('')
  const [canResend, setCanResend] = useState(false)
  const [nextResendTime, setNextResendTime] = useState<Date | null>(null)
  const [resendCountdown, setResendCountdown] = useState(0)

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isValid },
    setError,
  } = useForm<ForgotPasswordFormData>({
    resolver: zodResolver(forgotPasswordSchema),
    mode: 'onChange',
  })

  const email = watch('email')

  // Countdown timer for resend
  useEffect(() => {
    let interval: NodeJS.Timeout

    if (nextResendTime && resendCountdown > 0) {
      interval = setInterval(() => {
        const remaining = Math.ceil((nextResendTime.getTime() - Date.now()) / 1000)
        
        if (remaining <= 0) {
          setCanResend(true)
          setResendCountdown(0)
          setNextResendTime(null)
        } else {
          setResendCountdown(remaining)
        }
      }, 1000)
    }

    return () => {
      if (interval) clearInterval(interval)
    }
  }, [nextResendTime, resendCountdown])

  const onSubmit = async (data: ForgotPasswordFormData) => {
    try {
      const response = await resetPassword(data.email, redirectTo)
      
      // Always show success to prevent email enumeration
      setIsSubmitted(true)
      setSubmittedEmail(data.email)
      setCanResend(false)
      
      // Set resend timer (5 minutes)
      const nextResend = new Date(Date.now() + 5 * 60 * 1000)
      setNextResendTime(nextResend)
      setResendCountdown(300) // 5 minutes in seconds
      
      onSuccess?.(data.email)
      
    } catch (error: any) {
      // Handle specific error cases
      if (error.code === 'RATE_LIMIT_EXCEEDED') {
        setError('email', {
          message: 'Too many requests. Please try again later.',
        })
      } else {
        onError?.(error.message || 'Failed to send reset email')
      }
    }
  }

  const handleResend = async () => {
    if (!canResend || !submittedEmail) return

    try {
      await resetPassword(submittedEmail, redirectTo)
      
      // Reset timer
      const nextResend = new Date(Date.now() + 5 * 60 * 1000)
      setNextResendTime(nextResend)
      setResendCountdown(300)
      setCanResend(false)
      
    } catch (error: any) {
      onError?.(error.message || 'Failed to resend email')
    }
  }

  const formatCountdown = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  }

  if (isSubmitted) {
    return (
      <Card className={cn('max-w-md mx-auto', className)}>
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
            <Mail className="h-6 w-6 text-green-600" />
          </div>
          <CardTitle>Check your email</CardTitle>
          <CardDescription>
            If an account with <strong>{submittedEmail}</strong> exists, we've sent you a password reset link.
          </CardDescription>
        </CardHeader>

        <CardContent className="space-y-4">
          <Alert>
            <Check className="h-4 w-4" />
            <AlertDescription>
              The reset link will expire in 1 hour for security reasons.
            </AlertDescription>
          </Alert>

          <div className="space-y-4">
            <div className="text-center text-sm text-muted-foreground">
              Didn't receive the email? Check your spam folder or 
            </div>

            <Button
              variant="outline"
              className="w-full"
              onClick={handleResend}
              disabled={!canResend || isLoading}
            >
              {isLoading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Sending...
                </>
              ) : canResend ? (
                'Resend email'
              ) : (
                `Resend in ${formatCountdown(resendCountdown)}`
              )}
            </Button>

            <Button
              variant="ghost"
              className="w-full"
              onClick={() => {
                setIsSubmitted(false)
                setSubmittedEmail('')
                setCanResend(false)
                setNextResendTime(null)
                setResendCountdown(0)
              }}
            >
              Try different email
            </Button>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className={cn('max-w-md mx-auto', className)}>
      <CardHeader>
        <div className="flex items-center gap-2">
          {onBack && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onBack}
              className="p-0 h-auto"
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
          )}
          <div className="flex-1">
            <CardTitle>Forgot your password?</CardTitle>
            <CardDescription>
              Enter your email address and we'll send you a link to reset your password.
            </CardDescription>
          </div>
        </div>
      </CardHeader>

      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Email Field */}
          <div className="space-y-2">
            <Label htmlFor="email">Email address</Label>
            <Input
              id="email"
              type="email"
              placeholder="you@example.com"
              autoComplete="email"
              autoFocus
              {...register('email')}
              aria-invalid={errors.email ? 'true' : 'false'}
              aria-describedby={errors.email ? 'email-error' : undefined}
              className={cn({
                'border-destructive focus-visible:ring-destructive': errors.email,
              })}
            />
            {errors.email && (
              <p id="email-error" className="text-sm text-destructive">
                {errors.email.message}
              </p>
            )}
          </div>

          {/* Submit Button */}
          <Button
            type="submit"
            className="w-full"
            disabled={isLoading || !isValid}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Sending reset link...
              </>
            ) : (
              'Send reset link'
            )}
          </Button>
        </form>

        {/* Back to Login */}
        <div className="mt-6 text-center">
          <Button
            variant="link"
            size="sm"
            className="px-0 font-normal"
            onClick={() => window.location.href = '/login'}
          >
            Back to sign in
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
```

### 2. Rate Limiting Hook

#### `src/hooks/use-rate-limit.ts`
```typescript
'use client'

/**
 * Rate Limiting Hook
 * Manages request rate limiting for sensitive operations
 */

import { useState, useEffect } from 'react'

interface RateLimitState {
  attempts: number
  lastAttempt: Date | null
  isBlocked: boolean
  timeUntilReset: number
}

interface RateLimitConfig {
  maxAttempts: number
  windowMs: number
  blockDurationMs: number
}

const DEFAULT_CONFIG: RateLimitConfig = {
  maxAttempts: 3,
  windowMs: 60 * 60 * 1000, // 1 hour
  blockDurationMs: 15 * 60 * 1000, // 15 minutes
}

export function useRateLimit(
  key: string,
  config: Partial<RateLimitConfig> = {}
) {
  const fullConfig = { ...DEFAULT_CONFIG, ...config }
  const [state, setState] = useState<RateLimitState>({
    attempts: 0,
    lastAttempt: null,
    isBlocked: false,
    timeUntilReset: 0,
  })

  // Load state from localStorage
  useEffect(() => {
    const stored = localStorage.getItem(`rateLimit_${key}`)
    if (stored) {
      try {
        const parsed = JSON.parse(stored)
        const lastAttempt = parsed.lastAttempt ? new Date(parsed.lastAttempt) : null
        
        // Check if window has expired
        const now = new Date()
        const windowExpired = lastAttempt && 
          (now.getTime() - lastAttempt.getTime()) > fullConfig.windowMs
        
        if (windowExpired) {
          // Reset attempts
          setState({
            attempts: 0,
            lastAttempt: null,
            isBlocked: false,
            timeUntilReset: 0,
          })
        } else {
          // Check if still blocked
          const blockExpired = lastAttempt &&
            (now.getTime() - lastAttempt.getTime()) > fullConfig.blockDurationMs
          
          setState({
            attempts: parsed.attempts || 0,
            lastAttempt,
            isBlocked: parsed.attempts >= fullConfig.maxAttempts && !blockExpired,
            timeUntilReset: blockExpired ? 0 : Math.max(0, 
              fullConfig.blockDurationMs - (now.getTime() - (lastAttempt?.getTime() || 0))
            ),
          })
        }
      } catch (error) {
        console.error('Failed to parse rate limit state:', error)
      }
    }
  }, [key, fullConfig.windowMs, fullConfig.blockDurationMs, fullConfig.maxAttempts])

  // Save state to localStorage
  const saveState = (newState: RateLimitState) => {
    localStorage.setItem(`rateLimit_${key}`, JSON.stringify({
      attempts: newState.attempts,
      lastAttempt: newState.lastAttempt?.toISOString(),
    }))
  }

  // Record an attempt
  const recordAttempt = () => {
    const now = new Date()
    const newAttempts = state.attempts + 1
    const newState = {
      attempts: newAttempts,
      lastAttempt: now,
      isBlocked: newAttempts >= fullConfig.maxAttempts,
      timeUntilReset: newAttempts >= fullConfig.maxAttempts ? fullConfig.blockDurationMs : 0,
    }
    
    setState(newState)
    saveState(newState)
    
    return !newState.isBlocked
  }

  // Reset attempts
  const reset = () => {
    const newState = {
      attempts: 0,
      lastAttempt: null,
      isBlocked: false,
      timeUntilReset: 0,
    }
    
    setState(newState)
    localStorage.removeItem(`rateLimit_${key}`)
  }

  return {
    ...state,
    recordAttempt,
    reset,
    remainingAttempts: Math.max(0, fullConfig.maxAttempts - state.attempts),
  }
}
```

---

## 🧪 TESTING

### Unit Tests

#### `src/components/auth/__tests__/forgot-password-form.test.tsx`
```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ForgotPasswordForm } from '../forgot-password-form'
import { AuthProvider } from '@/contexts/auth-context'

// Mock the auth hook
const mockResetPassword = jest.fn()

jest.mock('@/hooks/use-auth', () => ({
  useAuth: () => ({
    resetPassword: mockResetPassword,
    isLoading: false,
  }),
}))

const renderForgotPasswordForm = (props = {}) => {
  return render(
    <AuthProvider>
      <ForgotPasswordForm {...props} />
    </AuthProvider>
  )
}

describe('ForgotPasswordForm', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    localStorage.clear()
  })

  it('renders the form correctly', () => {
    renderForgotPasswordForm()
    
    expect(screen.getByText('Forgot your password?')).toBeInTheDocument()
    expect(screen.getByLabelText('Email address')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Send reset link' })).toBeInTheDocument()
    expect(screen.getByText('Back to sign in')).toBeInTheDocument()
  })

  it('validates email field', async () => {
    const user = userEvent.setup()
    renderForgotPasswordForm()
    
    const submitButton = screen.getByRole('button', { name: 'Send reset link' })
    
    // Try to submit without email
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText('Email is required')).toBeInTheDocument()
    })
    
    // Try with invalid email
    const emailInput = screen.getByLabelText('Email address')
    await user.type(emailInput, 'invalid-email')
    await user.tab()
    
    await waitFor(() => {
      expect(screen.getByText('Please enter a valid email address')).toBeInTheDocument()
    })
  })

  it('submits form with valid email', async () => {
    const user = userEvent.setup()
    const mockOnSuccess = jest.fn()
    
    mockResetPassword.mockResolvedValue({ success: true })
    
    renderForgotPasswordForm({ onSuccess: mockOnSuccess })
    
    const emailInput = screen.getByLabelText('Email address')
    await user.type(emailInput, 'test@example.com')
    
    const submitButton = screen.getByRole('button', { name: 'Send reset link' })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(mockResetPassword).toHaveBeenCalledWith(
        'test@example.com',
        '/reset-password'
      )
      expect(mockOnSuccess).toHaveBeenCalledWith('test@example.com')
    })
  })

  it('shows success message after submission', async () => {
    const user = userEvent.setup()
    
    mockResetPassword.mockResolvedValue({ success: true })
    
    renderForgotPasswordForm()
    
    const emailInput = screen.getByLabelText('Email address')
    await user.type(emailInput, 'test@example.com')
    
    const submitButton = screen.getByRole('button', { name: 'Send reset link' })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText('Check your email')).toBeInTheDocument()
      expect(screen.getByText(/test@example.com/)).toBeInTheDocument()
      expect(screen.getByText('The reset link will expire in 1 hour')).toBeInTheDocument()
    })
  })

  it('handles resend functionality', async () => {
    const user = userEvent.setup()
    
    mockResetPassword.mockResolvedValue({ success: true })
    
    renderForgotPasswordForm()
    
    // Submit initial request
    const emailInput = screen.getByLabelText('Email address')
    await user.type(emailInput, 'test@example.com')
    
    const submitButton = screen.getByRole('button', { name: 'Send reset link' })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText('Check your email')).toBeInTheDocument()
    })
    
    // Resend button should be disabled initially
    const resendButton = screen.getByText(/Resend in/)
    expect(resendButton).toBeDisabled()
  })

  it('handles error states', async () => {
    const user = userEvent.setup()
    const mockOnError = jest.fn()
    
    mockResetPassword.mockRejectedValue(new Error('Network error'))
    
    renderForgotPasswordForm({ onError: mockOnError })
    
    const emailInput = screen.getByLabelText('Email address')
    await user.type(emailInput, 'test@example.com')
    
    const submitButton = screen.getByRole('button', { name: 'Send reset link' })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(mockOnError).toHaveBeenCalledWith('Network error')
    })
  })

  it('handles rate limiting', async () => {
    const user = userEvent.setup()
    
    mockResetPassword.mockRejectedValue({ 
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests'
    })
    
    renderForgotPasswordForm()
    
    const emailInput = screen.getByLabelText('Email address')
    await user.type(emailInput, 'test@example.com')
    
    const submitButton = screen.getByRole('button', { name: 'Send reset link' })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText('Too many requests. Please try again later.')).toBeInTheDocument()
    })
  })

  it('shows back button when onBack is provided', () => {
    const mockOnBack = jest.fn()
    renderForgotPasswordForm({ onBack: mockOnBack })
    
    const backButton = screen.getByRole('button', { name: '' }) // ArrowLeft icon
    expect(backButton).toBeInTheDocument()
  })
})
```

---

## 📱 RESPONSIVE DESIGN

### Mobile-First Approach
```css
/* Mobile styles (default) */
.forgot-password-form {
  padding: 1rem;
  max-width: 100%;
}

/* Tablet and up */
@media (min-width: 768px) {
  .forgot-password-form {
    padding: 2rem;
    max-width: 28rem;
  }
}

/* Desktop and up */
@media (min-width: 1024px) {
  .forgot-password-form {
    padding: 2.5rem;
  }
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- **Keyboard Navigation**: Full keyboard support
- **Screen Readers**: Proper ARIA labels and descriptions
- **Color Contrast**: Minimum 4.5:1 ratio
- **Focus Management**: Clear focus indicators
- **Error Announcements**: Screen reader accessible errors

### Implementation Details
```typescript
// Proper form labeling
<Label htmlFor="email">Email address</Label>
<Input
  id="email"
  aria-invalid={errors.email ? 'true' : 'false'}
  aria-describedby={errors.email ? 'email-error' : undefined}
/>

// Error announcements
{errors.email && (
  <p id="email-error" className="text-sm text-destructive" role="alert">
    {errors.email.message}
  </p>
)}
```

---

## 🔒 SECURITY

### Rate Limiting
- **Email Requests**: 3 per hour per email
- **IP-based Limiting**: 10 per hour per IP
- **Progressive Delays**: Exponential backoff

### Email Enumeration Prevention
```typescript
// Always return success, regardless of email existence
const response = await resetPassword(email)
// Don't reveal if email exists or not
setIsSubmitted(true)
```

### Input Sanitization
```typescript
const sanitizeEmail = (email: string): string => {
  return email.trim().toLowerCase()
}
```

---

## 🚀 USAGE EXAMPLES

### Basic Usage
```typescript
import { ForgotPasswordForm } from '@/components/auth/forgot-password-form'

export default function ForgotPasswordPage() {
  return (
    <div className="container mx-auto py-16">
      <ForgotPasswordForm 
        onSuccess={(email) => {
          console.log(`Reset email sent to ${email}`)
        }}
        onError={(error) => {
          toast.error(error)
        }}
      />
    </div>
  )
}
```

### With Custom Redirect
```typescript
<ForgotPasswordForm 
  redirectTo="/custom-reset-page"
  onBack={() => router.back()}
/>
```

### In Modal
```typescript
<Dialog open={showForgotPassword} onOpenChange={setShowForgotPassword}>
  <DialogContent>
    <ForgotPasswordForm 
      onBack={() => setShowForgotPassword(false)}
      onSuccess={() => setShowForgotPassword(false)}
    />
  </DialogContent>
</Dialog>
```

---

## ✅ COMPLETION CHECKLIST

- [ ] Component interface implemented
- [ ] Form validation with Zod schema
- [ ] Email submission handling
- [ ] Success state with instructions
- [ ] Rate limiting protection
- [ ] Resend functionality with countdown
- [ ] Error handling and display
- [ ] Loading states management
- [ ] Email enumeration prevention
- [ ] Accessibility features (WCAG 2.1 AA)
- [ ] Responsive design
- [ ] Security measures implemented
- [ ] Unit tests written
- [ ] Integration tests added
- [ ] Documentation completed
- [ ] TypeScript types defined

---

## 🔗 RELATED SPECIFICATIONS

- **SPEC-LOGIN-FORM**: Login component (back navigation)
- **SPEC-RESET-PASSWORD**: Password reset form (completion flow)
- **SPEC-037**: Auth Context (provides reset methods)
- **SPEC-036**: Authentication API (reset endpoint)
- **SPEC-045**: Auth Error Handling (error management)

---

**File**: `SPEC-FORGOT-PASSWORD.md`  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Status**: 📝 PLANNED