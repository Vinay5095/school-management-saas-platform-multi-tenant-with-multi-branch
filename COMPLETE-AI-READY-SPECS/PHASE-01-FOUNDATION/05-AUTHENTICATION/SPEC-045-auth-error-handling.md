# SPEC-045: Authentication Error Handling
## Comprehensive Error Handling & User Feedback System

> **Status**: ✅ COMPLETE  
> **Priority**: HIGH  
> **Estimated Time**: 4 hours  
> **Dependencies**: SPEC-035 (Supabase Config), SPEC-036 (Auth API)

---

## 📋 OVERVIEW

Complete error handling system for authentication flows, providing user-friendly error messages, detailed logging, error recovery options, and comprehensive error codes.

---

## 🎯 OBJECTIVES

- ✅ Centralized error handling
- ✅ User-friendly error messages
- ✅ Detailed error logging
- ✅ Error recovery flows
- ✅ Error code standardization
- ✅ Toast notifications
- ✅ Error boundaries

---

## 🔧 IMPLEMENTATION

### 1. Error Codes & Messages

#### `src/lib/errors/auth-errors.ts`
```typescript
/**
 * Authentication Error Codes and Messages
 * Centralized error handling for auth operations
 */

export enum AuthErrorCode {
  // General errors
  UNKNOWN_ERROR = 'UNKNOWN_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  SERVER_ERROR = 'SERVER_ERROR',

  // Authentication errors
  INVALID_CREDENTIALS = 'INVALID_CREDENTIALS',
  EMAIL_NOT_CONFIRMED = 'EMAIL_NOT_CONFIRMED',
  ACCOUNT_LOCKED = 'ACCOUNT_LOCKED',
  ACCOUNT_DISABLED = 'ACCOUNT_DISABLED',
  SESSION_EXPIRED = 'SESSION_EXPIRED',
  INVALID_TOKEN = 'INVALID_TOKEN',

  // Registration errors
  EMAIL_ALREADY_EXISTS = 'EMAIL_ALREADY_EXISTS',
  WEAK_PASSWORD = 'WEAK_PASSWORD',
  INVALID_EMAIL = 'INVALID_EMAIL',
  REGISTRATION_DISABLED = 'REGISTRATION_DISABLED',

  // Password errors
  PASSWORD_MISMATCH = 'PASSWORD_MISMATCH',
  PASSWORD_REUSED = 'PASSWORD_REUSED',
  PASSWORD_EXPIRED = 'PASSWORD_EXPIRED',
  INVALID_RESET_TOKEN = 'INVALID_RESET_TOKEN',
  RESET_TOKEN_EXPIRED = 'RESET_TOKEN_EXPIRED',

  // Rate limiting
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  TOO_MANY_REQUESTS = 'TOO_MANY_REQUESTS',

  // OAuth errors
  OAUTH_ERROR = 'OAUTH_ERROR',
  OAUTH_CANCELLED = 'OAUTH_CANCELLED',
  OAUTH_CALLBACK_ERROR = 'OAUTH_CALLBACK_ERROR',

  // 2FA errors
  TWO_FACTOR_REQUIRED = 'TWO_FACTOR_REQUIRED',
  INVALID_2FA_CODE = 'INVALID_2FA_CODE',
  TWO_FACTOR_SETUP_FAILED = 'TWO_FACTOR_SETUP_FAILED',

  // Permission errors
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  INSUFFICIENT_PERMISSIONS = 'INSUFFICIENT_PERMISSIONS',

  // Validation errors
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  MISSING_REQUIRED_FIELD = 'MISSING_REQUIRED_FIELD',
  INVALID_INPUT = 'INVALID_INPUT',
}

export interface AuthError {
  code: AuthErrorCode
  message: string
  details?: Record<string, any>
  timestamp: string
  recoverable: boolean
  recoveryAction?: {
    label: string
    action: () => void | Promise<void>
  }
}

export const AUTH_ERROR_MESSAGES: Record<AuthErrorCode, string> = {
  // General
  [AuthErrorCode.UNKNOWN_ERROR]:
    'An unexpected error occurred. Please try again.',
  [AuthErrorCode.NETWORK_ERROR]:
    'Network connection lost. Please check your internet connection.',
  [AuthErrorCode.SERVER_ERROR]:
    'Server error occurred. Please try again later.',

  // Authentication
  [AuthErrorCode.INVALID_CREDENTIALS]:
    'Invalid email or password. Please try again.',
  [AuthErrorCode.EMAIL_NOT_CONFIRMED]:
    'Please verify your email address before signing in.',
  [AuthErrorCode.ACCOUNT_LOCKED]:
    'Your account has been locked due to too many failed login attempts.',
  [AuthErrorCode.ACCOUNT_DISABLED]:
    'Your account has been disabled. Please contact support.',
  [AuthErrorCode.SESSION_EXPIRED]:
    'Your session has expired. Please sign in again.',
  [AuthErrorCode.INVALID_TOKEN]:
    'Invalid authentication token. Please sign in again.',

  // Registration
  [AuthErrorCode.EMAIL_ALREADY_EXISTS]:
    'An account with this email already exists.',
  [AuthErrorCode.WEAK_PASSWORD]:
    'Password does not meet security requirements.',
  [AuthErrorCode.INVALID_EMAIL]:
    'Please enter a valid email address.',
  [AuthErrorCode.REGISTRATION_DISABLED]:
    'Registration is currently disabled. Please contact support.',

  // Password
  [AuthErrorCode.PASSWORD_MISMATCH]:
    'Passwords do not match. Please try again.',
  [AuthErrorCode.PASSWORD_REUSED]:
    'This password was used recently. Please choose a different password.',
  [AuthErrorCode.PASSWORD_EXPIRED]:
    'Your password has expired. Please reset your password.',
  [AuthErrorCode.INVALID_RESET_TOKEN]:
    'Invalid password reset link. Please request a new one.',
  [AuthErrorCode.RESET_TOKEN_EXPIRED]:
    'Password reset link has expired. Please request a new one.',

  // Rate limiting
  [AuthErrorCode.RATE_LIMIT_EXCEEDED]:
    'Too many attempts. Please try again later.',
  [AuthErrorCode.TOO_MANY_REQUESTS]:
    'Too many requests. Please slow down and try again.',

  // OAuth
  [AuthErrorCode.OAUTH_ERROR]:
    'OAuth authentication failed. Please try again.',
  [AuthErrorCode.OAUTH_CANCELLED]:
    'OAuth authentication was cancelled.',
  [AuthErrorCode.OAUTH_CALLBACK_ERROR]:
    'OAuth callback failed. Please try again.',

  // 2FA
  [AuthErrorCode.TWO_FACTOR_REQUIRED]:
    'Two-factor authentication code required.',
  [AuthErrorCode.INVALID_2FA_CODE]:
    'Invalid two-factor authentication code.',
  [AuthErrorCode.TWO_FACTOR_SETUP_FAILED]:
    'Failed to setup two-factor authentication.',

  // Permission
  [AuthErrorCode.UNAUTHORIZED]:
    'You must be signed in to access this resource.',
  [AuthErrorCode.FORBIDDEN]:
    'You do not have permission to access this resource.',
  [AuthErrorCode.INSUFFICIENT_PERMISSIONS]:
    'You do not have sufficient permissions for this action.',

  // Validation
  [AuthErrorCode.VALIDATION_ERROR]:
    'Please check your input and try again.',
  [AuthErrorCode.MISSING_REQUIRED_FIELD]:
    'Please fill in all required fields.',
  [AuthErrorCode.INVALID_INPUT]:
    'Invalid input. Please check and try again.',
}

/**
 * Create an AuthError
 */
export function createAuthError(
  code: AuthErrorCode,
  details?: Record<string, any>,
  customMessage?: string
): AuthError {
  return {
    code,
    message: customMessage || AUTH_ERROR_MESSAGES[code],
    details,
    timestamp: new Date().toISOString(),
    recoverable: isRecoverableError(code),
  }
}

/**
 * Check if error is recoverable
 */
function isRecoverableError(code: AuthErrorCode): boolean {
  const nonRecoverableErrors = [
    AuthErrorCode.ACCOUNT_DISABLED,
    AuthErrorCode.REGISTRATION_DISABLED,
    AuthErrorCode.FORBIDDEN,
  ]
  return !nonRecoverableErrors.includes(code)
}

/**
 * Map Supabase error to AuthError
 */
export function mapSupabaseError(error: any): AuthError {
  const message = error?.message?.toLowerCase() || ''

  if (message.includes('invalid login credentials')) {
    return createAuthError(AuthErrorCode.INVALID_CREDENTIALS)
  }

  if (message.includes('email not confirmed')) {
    return createAuthError(AuthErrorCode.EMAIL_NOT_CONFIRMED)
  }

  if (message.includes('user already registered')) {
    return createAuthError(AuthErrorCode.EMAIL_ALREADY_EXISTS)
  }

  if (message.includes('password')) {
    return createAuthError(AuthErrorCode.WEAK_PASSWORD)
  }

  if (message.includes('rate limit')) {
    return createAuthError(AuthErrorCode.RATE_LIMIT_EXCEEDED)
  }

  if (message.includes('network') || message.includes('fetch')) {
    return createAuthError(AuthErrorCode.NETWORK_ERROR)
  }

  return createAuthError(AuthErrorCode.UNKNOWN_ERROR, { originalError: error })
}
```

---

### 2. Error Handler Service

#### `src/lib/errors/error-handler.ts`
```typescript
/**
 * Error Handler Service
 * Centralized error handling and logging
 */

import { AuthError, AuthErrorCode, createAuthError } from './auth-errors'
import { toast } from '@/components/ui/use-toast'

export interface ErrorHandlerOptions {
  silent?: boolean // Don't show toast
  logToConsole?: boolean
  logToServer?: boolean
  onError?: (error: AuthError) => void
}

class ErrorHandler {
  private static instance: ErrorHandler

  private constructor() {}

  static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler()
    }
    return ErrorHandler.instance
  }

  /**
   * Handle authentication error
   */
  handle(
    error: Error | AuthError | any,
    options: ErrorHandlerOptions = {}
  ): AuthError {
    const authError = this.normalizeError(error)

    // Log to console
    if (options.logToConsole !== false) {
      console.error('[Auth Error]', authError)
    }

    // Log to server
    if (options.logToServer) {
      this.logToServer(authError)
    }

    // Show toast notification
    if (!options.silent) {
      this.showToast(authError)
    }

    // Custom error callback
    if (options.onError) {
      options.onError(authError)
    }

    return authError
  }

  /**
   * Normalize error to AuthError
   */
  private normalizeError(error: any): AuthError {
    if (error && typeof error === 'object' && 'code' in error) {
      return error as AuthError
    }

    if (error instanceof Error) {
      return createAuthError(AuthErrorCode.UNKNOWN_ERROR, {
        message: error.message,
        stack: error.stack,
      })
    }

    return createAuthError(AuthErrorCode.UNKNOWN_ERROR, { error })
  }

  /**
   * Show toast notification
   */
  private showToast(error: AuthError): void {
    toast({
      title: this.getErrorTitle(error.code),
      description: error.message,
      variant: 'destructive',
      duration: 5000,
    })
  }

  /**
   * Get error title based on code
   */
  private getErrorTitle(code: AuthErrorCode): string {
    const titles: Partial<Record<AuthErrorCode, string>> = {
      [AuthErrorCode.INVALID_CREDENTIALS]: 'Authentication Failed',
      [AuthErrorCode.EMAIL_NOT_CONFIRMED]: 'Email Not Verified',
      [AuthErrorCode.ACCOUNT_LOCKED]: 'Account Locked',
      [AuthErrorCode.RATE_LIMIT_EXCEEDED]: 'Too Many Attempts',
      [AuthErrorCode.NETWORK_ERROR]: 'Connection Error',
      [AuthErrorCode.SERVER_ERROR]: 'Server Error',
    }

    return titles[code] || 'Error'
  }

  /**
   * Log error to server
   */
  private async logToServer(error: AuthError): Promise<void> {
    try {
      await fetch('/api/logs/errors', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          error,
          userAgent: navigator.userAgent,
          url: window.location.href,
        }),
      })
    } catch (err) {
      console.error('Failed to log error to server:', err)
    }
  }
}

// Export singleton instance
export const errorHandler = ErrorHandler.getInstance()

// Convenience function
export function handleAuthError(
  error: any,
  options?: ErrorHandlerOptions
): AuthError {
  return errorHandler.handle(error, options)
}
```

---

### 3. Error Boundary Component

#### `src/components/errors/auth-error-boundary.tsx`
```typescript
'use client'

/**
 * Authentication Error Boundary
 * Catches and displays authentication errors
 */

import React from 'react'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { AlertCircle } from 'lucide-react'

interface Props {
  children: React.ReactNode
  fallback?: React.ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class AuthErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Auth Error Boundary caught error:', error, errorInfo)
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null })
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback
      }

      return (
        <Card className="p-8 max-w-md mx-auto mt-8">
          <div className="flex flex-col items-center text-center space-y-4">
            <AlertCircle className="h-12 w-12 text-destructive" />
            <div>
              <h2 className="text-xl font-semibold">Something went wrong</h2>
              <p className="text-sm text-muted-foreground mt-2">
                {this.state.error?.message || 'An unexpected error occurred'}
              </p>
            </div>
            <div className="flex gap-2">
              <Button onClick={this.handleReset}>Try Again</Button>
              <Button variant="outline" onClick={() => window.location.href = '/'}>
                Go Home
              </Button>
            </div>
          </div>
        </Card>
      )
    }

    return this.props.children
  }
}
```

---

### 4. Error Recovery Component

#### `src/components/errors/error-recovery.tsx`
```typescript
'use client'

/**
 * Error Recovery Component
 * Provides recovery options for auth errors
 */

import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { AuthError, AuthErrorCode } from '@/lib/errors/auth-errors'
import { useRouter } from 'next/navigation'

interface ErrorRecoveryProps {
  error: AuthError
  onRetry?: () => void
}

export function ErrorRecovery({ error, onRetry }: ErrorRecoveryProps) {
  const router = useRouter()

  const getRecoveryOptions = () => {
    switch (error.code) {
      case AuthErrorCode.EMAIL_NOT_CONFIRMED:
        return {
          title: 'Email Verification Required',
          description: 'Please check your email and click the verification link.',
          actions: [
            {
              label: 'Resend Verification Email',
              onClick: () => router.push('/resend-verification'),
            },
          ],
        }

      case AuthErrorCode.ACCOUNT_LOCKED:
        return {
          title: 'Account Locked',
          description: 'Your account has been locked due to security reasons.',
          actions: [
            {
              label: 'Contact Support',
              onClick: () => router.push('/support'),
            },
            {
              label: 'Reset Password',
              onClick: () => router.push('/forgot-password'),
            },
          ],
        }

      case AuthErrorCode.SESSION_EXPIRED:
        return {
          title: 'Session Expired',
          description: 'Your session has expired. Please sign in again.',
          actions: [
            {
              label: 'Sign In',
              onClick: () => router.push('/login'),
            },
          ],
        }

      case AuthErrorCode.INVALID_RESET_TOKEN:
      case AuthErrorCode.RESET_TOKEN_EXPIRED:
        return {
          title: 'Invalid Reset Link',
          description: 'This password reset link is invalid or has expired.',
          actions: [
            {
              label: 'Request New Link',
              onClick: () => router.push('/forgot-password'),
            },
          ],
        }

      default:
        return {
          title: 'Error Occurred',
          description: error.message,
          actions: onRetry
            ? [
                {
                  label: 'Try Again',
                  onClick: onRetry,
                },
              ]
            : [],
        }
    }
  }

  const recovery = getRecoveryOptions()

  return (
    <Card className="p-6">
      <div className="space-y-4">
        <div>
          <h3 className="font-semibold text-lg">{recovery.title}</h3>
          <p className="text-sm text-muted-foreground mt-1">
            {recovery.description}
          </p>
        </div>

        {recovery.actions.length > 0 && (
          <div className="flex gap-2">
            {recovery.actions.map((action, index) => (
              <Button
                key={index}
                onClick={action.onClick}
                variant={index === 0 ? 'default' : 'outline'}
              >
                {action.label}
              </Button>
            ))}
          </div>
        )}
      </div>
    </Card>
  )
}
```

---

### 5. Usage Example

#### `src/app/login/page.tsx`
```typescript
'use client'

import { useState } from 'react'
import { useAuth } from '@/hooks/use-auth'
import { handleAuthError } from '@/lib/errors/error-handler'
import { AuthErrorBoundary } from '@/components/errors/auth-error-boundary'
import { ErrorRecovery } from '@/components/errors/error-recovery'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

export default function LoginPage() {
  const { signIn } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<any>(null)
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      const result = await signIn(email, password)

      if (!result.success) {
        const authError = handleAuthError(result.error)
        setError(authError)
      }
    } catch (err) {
      const authError = handleAuthError(err)
      setError(authError)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <AuthErrorBoundary>
      <div className="max-w-md mx-auto mt-8 space-y-6">
        {error && (
          <ErrorRecovery error={error} onRetry={() => setError(null)} />
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
          />
          <Input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
          />
          <Button type="submit" disabled={isLoading} className="w-full">
            {isLoading ? 'Signing in...' : 'Sign In'}
          </Button>
        </form>
      </div>
    </AuthErrorBoundary>
  )
}
```

---

## ✅ COMPLETION CHECKLIST

- [x] Error codes defined
- [x] Error messages created
- [x] Error handler service implemented
- [x] Error boundary component created
- [x] Error recovery component created
- [x] Toast notifications integrated
- [x] Server-side logging added
- [x] Recovery flows implemented
- [x] Usage examples provided
- [x] Documentation complete

---

## 📚 RELATED SPECS

- ⬅️ **SPEC-035**: Supabase Auth Configuration
- ⬅️ **SPEC-036**: Authentication API
- ⬅️ **SPEC-037**: Auth Context & Hooks
- ⬅️ **SPEC-044**: Password Policy

---

## 🎉 AUTHENTICATION MODULE COMPLETE

All 11 authentication specifications (SPEC-035 to SPEC-045) are now complete and production-ready!

---

**Author**: AI Assistant  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0
