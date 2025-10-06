# SPEC-044: Password Policy
## Comprehensive Password Security & Policy Enforcement

> **Status**: ✅ COMPLETE  
> **Priority**: HIGH  
> **Estimated Time**: 3 hours  
> **Dependencies**: SPEC-035 (Supabase Config)

---

## 📋 OVERVIEW

Complete password policy system enforcing strong password requirements, preventing password reuse, implementing password expiry, and providing password strength indicators.

---

## 🎯 OBJECTIVES

- ✅ Strong password requirements
- ✅ Password strength validation
- ✅ Password reuse prevention
- ✅ Password expiry policy
- ✅ Password strength indicator
- ✅ Common password blacklist
- ✅ Password history tracking

---

## 🔧 IMPLEMENTATION

### 1. Password Policy Configuration

#### `src/lib/password/policy.ts`
```typescript
/**
 * Password Policy Configuration
 * Enforces password security requirements
 */

export interface PasswordPolicy {
  minLength: number
  maxLength: number
  requireUppercase: boolean
  requireLowercase: boolean
  requireNumbers: boolean
  requireSpecialChars: boolean
  specialChars: string
  preventReuse: number // Number of previous passwords to check
  expiryDays: number // Days until password expires
  minPasswordAge: number // Minimum days before password can be changed again
  preventCommon: boolean // Prevent common passwords
  preventUserInfo: boolean // Prevent use of user info (name, email)
}

export const DEFAULT_PASSWORD_POLICY: PasswordPolicy = {
  minLength: 8,
  maxLength: 128,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  specialChars: '!@#$%^&*()_+-=[]{}|;:,.<>?',
  preventReuse: 5,
  expiryDays: 90,
  minPasswordAge: 1,
  preventCommon: true,
  preventUserInfo: true,
}

export interface PasswordValidationResult {
  valid: boolean
  score: number // 0-100
  strength: 'weak' | 'fair' | 'good' | 'strong'
  errors: string[]
  warnings: string[]
  suggestions: string[]
}

/**
 * Validate password against policy
 */
export function validatePassword(
  password: string,
  policy: PasswordPolicy = DEFAULT_PASSWORD_POLICY,
  userInfo?: { email?: string; firstName?: string; lastName?: string }
): PasswordValidationResult {
  const errors: string[] = []
  const warnings: string[] = []
  const suggestions: string[] = []
  let score = 0

  // Length check
  if (password.length < policy.minLength) {
    errors.push(`Password must be at least ${policy.minLength} characters`)
  } else {
    score += 20
  }

  if (password.length > policy.maxLength) {
    errors.push(`Password must not exceed ${policy.maxLength} characters`)
  }

  // Uppercase check
  if (policy.requireUppercase && !/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  } else if (/[A-Z]/.test(password)) {
    score += 15
  }

  // Lowercase check
  if (policy.requireLowercase && !/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  } else if (/[a-z]/.test(password)) {
    score += 15
  }

  // Number check
  if (policy.requireNumbers && !/\d/.test(password)) {
    errors.push('Password must contain at least one number')
  } else if (/\d/.test(password)) {
    score += 15
  }

  // Special character check
  if (policy.requireSpecialChars) {
    const specialCharRegex = new RegExp(
      `[${policy.specialChars.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}]`
    )
    if (!specialCharRegex.test(password)) {
      errors.push('Password must contain at least one special character')
    } else {
      score += 15
    }
  }

  // Common password check
  if (policy.preventCommon && isCommonPassword(password)) {
    errors.push('This password is too common and easily guessable')
  }

  // User info check
  if (policy.preventUserInfo && userInfo) {
    if (
      (userInfo.email && password.toLowerCase().includes(userInfo.email.split('@')[0].toLowerCase())) ||
      (userInfo.firstName && password.toLowerCase().includes(userInfo.firstName.toLowerCase())) ||
      (userInfo.lastName && password.toLowerCase().includes(userInfo.lastName.toLowerCase()))
    ) {
      errors.push('Password should not contain your personal information')
    }
  }

  // Additional strength checks
  if (password.length >= 12) {
    score += 10
    suggestions.push('Great! Long passwords are more secure')
  } else {
    suggestions.push('Consider using a longer password (12+ characters)')
  }

  if (/[A-Z].*[A-Z]/.test(password)) {
    score += 5
  }

  if (/\d.*\d/.test(password)) {
    score += 5
  }

  // Check for patterns
  if (hasSequentialCharacters(password)) {
    warnings.push('Avoid sequential characters (abc, 123)')
    score -= 10
  }

  if (hasRepeatingCharacters(password)) {
    warnings.push('Avoid repeating characters (aaa, 111)')
    score -= 10
  }

  // Normalize score
  score = Math.max(0, Math.min(100, score))

  // Determine strength
  let strength: 'weak' | 'fair' | 'good' | 'strong'
  if (score < 40) strength = 'weak'
  else if (score < 60) strength = 'fair'
  else if (score < 80) strength = 'good'
  else strength = 'strong'

  return {
    valid: errors.length === 0,
    score,
    strength,
    errors,
    warnings,
    suggestions,
  }
}

/**
 * Check if password is in common passwords list
 */
function isCommonPassword(password: string): boolean {
  const commonPasswords = [
    'password', 'Password', 'password123', 'Password123', '12345678', '123456789',
    'qwerty', 'abc123', 'monkey', '1234567', 'letmein', 'trustno1', 'dragon',
    'baseball', 'iloveyou', 'master', 'sunshine', 'ashley', 'bailey', 'passw0rd',
    'shadow', '123123', '654321', 'superman', 'qazwsx', 'michael', 'football',
  ]

  return commonPasswords.some(
    (common) => password.toLowerCase() === common.toLowerCase()
  )
}

/**
 * Check for sequential characters
 */
function hasSequentialCharacters(password: string): boolean {
  const sequences = ['abcdefghijklmnopqrstuvwxyz', '0123456789', 'qwertyuiop', 'asdfghjkl']

  for (const sequence of sequences) {
    for (let i = 0; i < sequence.length - 2; i++) {
      const seq = sequence.substring(i, i + 3)
      if (password.toLowerCase().includes(seq)) {
        return true
      }
    }
  }

  return false
}

/**
 * Check for repeating characters
 */
function hasRepeatingCharacters(password: string): boolean {
  return /(.)\1{2,}/.test(password)
}

/**
 * Generate strong password suggestion
 */
export function generateStrongPassword(length: number = 16): string {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const lowercase = 'abcdefghijklmnopqrstuvwxyz'
  const numbers = '0123456789'
  const special = '!@#$%^&*()_+-=[]{}|;:,.<>?'
  const all = uppercase + lowercase + numbers + special

  let password = ''

  // Ensure at least one of each required type
  password += uppercase[Math.floor(Math.random() * uppercase.length)]
  password += lowercase[Math.floor(Math.random() * lowercase.length)]
  password += numbers[Math.floor(Math.random() * numbers.length)]
  password += special[Math.floor(Math.random() * special.length)]

  // Fill the rest randomly
  for (let i = password.length; i < length; i++) {
    password += all[Math.floor(Math.random() * all.length)]
  }

  // Shuffle the password
  return password
    .split('')
    .sort(() => Math.random() - 0.5)
    .join('')
}
```

---

### 2. Password History Tracking

#### `src/lib/password/history.ts`
```typescript
/**
 * Password History Management
 * Prevents password reuse
 */

import { createClient } from '@/lib/supabase/server'
import bcrypt from 'bcrypt'

export interface PasswordHistory {
  user_id: string
  password_hash: string
  changed_at: string
}

/**
 * Add password to history
 */
export async function addPasswordToHistory(
  userId: string,
  passwordHash: string
): Promise<void> {
  try {
    const supabase = await createClient()

    await supabase.from('password_history').insert({
      user_id: userId,
      password_hash: passwordHash,
      changed_at: new Date().toISOString(),
    })

    // Clean up old history beyond preventReuse limit
    const { data: history } = await supabase
      .from('password_history')
      .select('id')
      .eq('user_id', userId)
      .order('changed_at', { ascending: false })

    if (history && history.length > 5) {
      const idsToDelete = history.slice(5).map((h) => h.id)
      await supabase.from('password_history').delete().in('id', idsToDelete)
    }
  } catch (error) {
    console.error('Failed to add password to history:', error)
  }
}

/**
 * Check if password was used before
 */
export async function isPasswordReused(
  userId: string,
  newPassword: string,
  limit: number = 5
): Promise<boolean> {
  try {
    const supabase = await createClient()

    const { data: history } = await supabase
      .from('password_history')
      .select('password_hash')
      .eq('user_id', userId)
      .order('changed_at', { ascending: false })
      .limit(limit)

    if (!history || history.length === 0) {
      return false
    }

    // Check against each historical password
    for (const record of history) {
      const matches = await bcrypt.compare(newPassword, record.password_hash)
      if (matches) {
        return true
      }
    }

    return false
  } catch (error) {
    console.error('Error checking password reuse:', error)
    return false
  }
}

/**
 * Check if password has expired
 */
export async function isPasswordExpired(
  userId: string,
  expiryDays: number = 90
): Promise<boolean> {
  try {
    const supabase = await createClient()

    const { data } = await supabase
      .from('password_history')
      .select('changed_at')
      .eq('user_id', userId)
      .order('changed_at', { ascending: false })
      .limit(1)
      .single()

    if (!data) {
      return false
    }

    const lastChanged = new Date(data.changed_at)
    const expiryDate = new Date(lastChanged)
    expiryDate.setDate(expiryDate.getDate() + expiryDays)

    return new Date() > expiryDate
  } catch (error) {
    console.error('Error checking password expiry:', error)
    return false
  }
}
```

---

### 3. Password Strength Component

#### `src/components/auth/password-strength.tsx`
```typescript
'use client'

/**
 * Password Strength Indicator
 * Visual feedback for password strength
 */

import { useMemo } from 'react'
import { validatePassword } from '@/lib/password/policy'
import { Progress } from '@/components/ui/progress'
import { cn } from '@/lib/utils'

interface PasswordStrengthProps {
  password: string
  userInfo?: {
    email?: string
    firstName?: string
    lastName?: string
  }
}

export function PasswordStrength({ password, userInfo }: PasswordStrengthProps) {
  const validation = useMemo(
    () => validatePassword(password, undefined, userInfo),
    [password, userInfo]
  )

  if (!password) {
    return null
  }

  const strengthColors = {
    weak: 'bg-red-500',
    fair: 'bg-orange-500',
    good: 'bg-blue-500',
    strong: 'bg-green-500',
  }

  const strengthLabels = {
    weak: 'Weak',
    fair: 'Fair',
    good: 'Good',
    strong: 'Strong',
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between text-sm">
        <span className="text-muted-foreground">Password Strength:</span>
        <span
          className={cn(
            'font-medium',
            validation.strength === 'weak' && 'text-red-500',
            validation.strength === 'fair' && 'text-orange-500',
            validation.strength === 'good' && 'text-blue-500',
            validation.strength === 'strong' && 'text-green-500'
          )}
        >
          {strengthLabels[validation.strength]}
        </span>
      </div>

      <Progress
        value={validation.score}
        className={cn('h-2', strengthColors[validation.strength])}
      />

      {validation.errors.length > 0 && (
        <ul className="text-xs text-red-500 space-y-1">
          {validation.errors.map((error, index) => (
            <li key={index}>• {error}</li>
          ))}
        </ul>
      )}

      {validation.warnings.length > 0 && (
        <ul className="text-xs text-orange-500 space-y-1">
          {validation.warnings.map((warning, index) => (
            <li key={index}>• {warning}</li>
          ))}
        </ul>
      )}

      {validation.suggestions.length > 0 && validation.errors.length === 0 && (
        <ul className="text-xs text-muted-foreground space-y-1">
          {validation.suggestions.map((suggestion, index) => (
            <li key={index}>• {suggestion}</li>
          ))}
        </ul>
      )}
    </div>
  )
}
```

---

### 4. Password Input with Strength

#### `src/components/ui/password-input.tsx`
```typescript
'use client'

/**
 * Password Input with Strength Indicator
 */

import { useState } from 'react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Eye, EyeOff } from 'lucide-react'
import { PasswordStrength } from '@/components/auth/password-strength'

interface PasswordInputProps {
  value: string
  onChange: (value: string) => void
  showStrength?: boolean
  userInfo?: {
    email?: string
    firstName?: string
    lastName?: string
  }
  placeholder?: string
  className?: string
}

export function PasswordInput({
  value,
  onChange,
  showStrength = true,
  userInfo,
  placeholder = 'Enter password',
  className,
}: PasswordInputProps) {
  const [showPassword, setShowPassword] = useState(false)

  return (
    <div className="space-y-2">
      <div className="relative">
        <Input
          type={showPassword ? 'text' : 'password'}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className={className}
        />
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
          onClick={() => setShowPassword(!showPassword)}
        >
          {showPassword ? (
            <EyeOff className="h-4 w-4 text-muted-foreground" />
          ) : (
            <Eye className="h-4 w-4 text-muted-foreground" />
          )}
        </Button>
      </div>

      {showStrength && <PasswordStrength password={value} userInfo={userInfo} />}
    </div>
  )
}
```

---

## 📦 REQUIRED PACKAGES

```json
{
  "dependencies": {
    "bcrypt": "^5.1.1"
  },
  "devDependencies": {
    "@types/bcrypt": "^5.0.2"
  }
}
```

---

## 🗄️ DATABASE SCHEMA

```sql
-- Password history table
CREATE TABLE password_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_password_history_user_id ON password_history(user_id);
CREATE INDEX idx_password_history_changed_at ON password_history(changed_at DESC);

-- RLS Policies
ALTER TABLE password_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own password history"
  ON password_history FOR SELECT
  USING (auth.uid() = user_id);
```

---

## ✅ COMPLETION CHECKLIST

- [x] Password policy configuration created
- [x] Password validation function implemented
- [x] Password strength scoring added
- [x] Common password check implemented
- [x] Password history tracking added
- [x] Password reuse prevention implemented
- [x] Password expiry check added
- [x] Strength indicator component created
- [x] Password input component created
- [x] Database schema created
- [x] Documentation complete

---

## 📚 RELATED SPECS

- ⬅️ **SPEC-035**: Supabase Auth Configuration
- ⬅️ **SPEC-043**: Two-Factor Authentication
- ➡️ **SPEC-045**: Auth Error Handling

---

**Author**: AI Assistant  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0
