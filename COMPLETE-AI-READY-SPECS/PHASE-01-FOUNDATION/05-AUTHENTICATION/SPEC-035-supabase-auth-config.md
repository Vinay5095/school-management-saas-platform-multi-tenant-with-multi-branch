# SPEC-035: Supabase Auth Configuration
## Complete Authentication Setup for Multi-Tenant SaaS

> **Status**: ✅ COMPLETE  
> **Priority**: CRITICAL  
> **Estimated Time**: 4 hours  
> **Dependencies**: SPEC-005 (Environment Variables), SPEC-009 (Multi-tenant Architecture)

---

## 📋 OVERVIEW

Complete configuration of Supabase Authentication for the multi-tenant school management platform, including email authentication, OAuth providers, JWT handling, and security settings.

---

## 🎯 OBJECTIVES

- ✅ Configure Supabase Auth settings
- ✅ Setup email templates and SMTP
- ✅ Configure OAuth providers (Google, Microsoft)
- ✅ Setup JWT token configuration
- ✅ Configure security policies
- ✅ Setup user metadata structure
- ✅ Configure redirect URLs
- ✅ Setup rate limiting

---

## 📁 FILE STRUCTURE

```
src/
├── lib/
│   ├── supabase/
│   │   ├── client.ts          # Browser client
│   │   ├── server.ts          # Server client
│   │   ├── middleware.ts      # Middleware client
│   │   └── admin.ts           # Admin client (service role)
│   └── auth/
│       └── config.ts          # Auth configuration
└── types/
    └── supabase.ts            # Supabase types
```

---

## 🔧 IMPLEMENTATION

### 1. Supabase Client Configuration

#### `src/lib/supabase/client.ts`
```typescript
/**
 * Supabase Browser Client
 * Used in Client Components and browser-side code
 */

import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '@/types/supabase'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: {
        flowType: 'pkce',
        autoRefreshToken: true,
        detectSessionInUrl: true,
        persistSession: true,
        storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        storageKey: 'school-saas-auth',
      },
      global: {
        headers: {
          'x-application-name': 'school-management-saas',
        },
      },
      db: {
        schema: 'public',
      },
    }
  )
}

// Singleton instance for browser
let browserClient: ReturnType<typeof createClient> | null = null

export function getSupabaseBrowserClient() {
  if (!browserClient) {
    browserClient = createClient()
  }
  return browserClient
}
```

#### `src/lib/supabase/server.ts`
```typescript
/**
 * Supabase Server Client
 * Used in Server Components, Route Handlers, and Server Actions
 */

import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/supabase'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options })
          } catch (error) {
            // Handle error in middleware
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: '', ...options })
          } catch (error) {
            // Handle error in middleware
          }
        },
      },
      auth: {
        flowType: 'pkce',
        autoRefreshToken: true,
        detectSessionInUrl: false,
        persistSession: true,
      },
    }
  )
}

export async function getSupabaseServerClient() {
  return await createClient()
}
```

#### `src/lib/supabase/middleware.ts`
```typescript
/**
 * Supabase Middleware Client
 * Used in Next.js middleware for route protection
 */

import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import type { Database } from '@/types/supabase'

export async function createClient(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value,
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value,
            ...options,
          })
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value: '',
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value: '',
            ...options,
          })
        },
      },
      auth: {
        flowType: 'pkce',
        autoRefreshToken: false,
        detectSessionInUrl: false,
        persistSession: true,
      },
    }
  )

  return { supabase, response }
}
```

#### `src/lib/supabase/admin.ts`
```typescript
/**
 * Supabase Admin Client
 * Used for administrative operations with service role key
 * ⚠️ ONLY use server-side, NEVER expose to client
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

export function createAdminClient() {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not set')
  }

  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
      global: {
        headers: {
          'x-application-name': 'school-saas-admin',
        },
      },
    }
  )
}

// Admin operations helper
export async function getAdminClient() {
  return createAdminClient()
}
```

---

### 2. Authentication Configuration

#### `src/lib/auth/config.ts`
```typescript
/**
 * Authentication Configuration
 * Centralized auth settings and constants
 */

export const AUTH_CONFIG = {
  // Session configuration
  session: {
    maxAge: 60 * 60 * 24 * 7, // 7 days
    refreshThreshold: 60 * 60, // 1 hour before expiry
  },

  // Password requirements
  password: {
    minLength: 8,
    maxLength: 128,
    requireUppercase: true,
    requireLowercase: true,
    requireNumbers: true,
    requireSpecialChars: true,
    specialChars: '!@#$%^&*()_+-=[]{}|;:,.<>?',
  },

  // Rate limiting
  rateLimit: {
    login: {
      maxAttempts: 5,
      windowMs: 15 * 60 * 1000, // 15 minutes
      blockDurationMs: 60 * 60 * 1000, // 1 hour
    },
    register: {
      maxAttempts: 3,
      windowMs: 60 * 60 * 1000, // 1 hour
    },
    passwordReset: {
      maxAttempts: 3,
      windowMs: 60 * 60 * 1000, // 1 hour
    },
    twoFactor: {
      maxAttempts: 3,
      windowMs: 15 * 60 * 1000, // 15 minutes
      blockDurationMs: 30 * 60 * 1000, // 30 minutes
    },
  },

  // OAuth providers
  oauth: {
    google: {
      enabled: true,
      scopes: ['email', 'profile'],
    },
    microsoft: {
      enabled: true,
      scopes: ['email', 'profile', 'openid'],
    },
  },

  // Email configuration
  email: {
    verification: {
      required: true,
      expiresIn: 24 * 60 * 60, // 24 hours
    },
    passwordReset: {
      expiresIn: 60 * 60, // 1 hour
    },
    magicLink: {
      enabled: false,
      expiresIn: 60 * 5, // 5 minutes
    },
  },

  // Two-factor authentication
  twoFactor: {
    enabled: true,
    required: false, // Can be enforced per role
    issuer: 'School Management SaaS',
    window: 1, // Allow 1 time step before/after
    codeLength: 6,
  },

  // Security settings
  security: {
    allowedDomains: [], // Empty = allow all domains
    blockedDomains: ['tempmail.com', '10minutemail.com'],
    requireStrongPassword: true,
    preventReuse: 5, // Last 5 passwords
    sessionConcurrency: 3, // Max active sessions
    forceLogoutAfterPasswordChange: true,
    requireEmailVerification: true,
  },

  // Redirect URLs
  redirects: {
    afterLogin: '/dashboard',
    afterLogout: '/login',
    afterSignup: '/onboarding',
    afterPasswordReset: '/login',
    afterEmailVerification: '/dashboard',
    unauthorized: '/login',
  },

  // User metadata structure
  metadata: {
    required: ['tenant_id', 'role', 'first_name', 'last_name'],
    optional: [
      'phone',
      'avatar_url',
      'branch_id',
      'department',
      'employee_id',
      'student_id',
      'preferences',
    ],
  },
} as const

// Type for auth config
export type AuthConfig = typeof AUTH_CONFIG

// Helper to get redirect URL
export function getRedirectUrl(key: keyof typeof AUTH_CONFIG.redirects): string {
  return AUTH_CONFIG.redirects[key]
}

// Helper to check password strength
export function isPasswordStrong(password: string): {
  valid: boolean
  errors: string[]
} {
  const errors: string[] = []
  const { password: config } = AUTH_CONFIG

  if (password.length < config.minLength) {
    errors.push(`Password must be at least ${config.minLength} characters`)
  }

  if (password.length > config.maxLength) {
    errors.push(`Password must not exceed ${config.maxLength} characters`)
  }

  if (config.requireUppercase && !/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  }

  if (config.requireLowercase && !/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  }

  if (config.requireNumbers && !/\d/.test(password)) {
    errors.push('Password must contain at least one number')
  }

  if (config.requireSpecialChars) {
    const specialCharRegex = new RegExp(`[${config.specialChars.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}]`)
    if (!specialCharRegex.test(password)) {
      errors.push('Password must contain at least one special character')
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  }
}
```

---

### 3. TypeScript Types

#### `src/types/supabase.ts`
```typescript
/**
 * Supabase Database Types
 * Auto-generated from database schema
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      // Define your tables here
      // This will be auto-generated by Supabase CLI
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}

// Auth user metadata type
export interface UserMetadata {
  tenant_id: string
  role: string
  first_name: string
  last_name: string
  phone?: string
  avatar_url?: string
  branch_id?: string
  department?: string
  employee_id?: string
  student_id?: string
  preferences?: Json
  two_factor_enabled?: boolean
  last_password_change?: string
}

// Session type
export interface AuthSession {
  access_token: string
  refresh_token: string
  expires_in: number
  expires_at?: number
  token_type: string
  user: AuthUser
}

// User type
export interface AuthUser {
  id: string
  aud: string
  role?: string
  email?: string
  email_confirmed_at?: string
  phone?: string
  confirmed_at?: string
  last_sign_in_at?: string
  app_metadata: {
    provider?: string
    providers?: string[]
  }
  user_metadata: UserMetadata
  identities?: Array<{
    id: string
    user_id: string
    identity_data?: {
      [key: string]: any
    }
    provider: string
    last_sign_in_at?: string
    created_at?: string
    updated_at?: string
  }>
  created_at: string
  updated_at: string
}
```

---

## 🔐 SUPABASE DASHBOARD CONFIGURATION

### Email Templates

#### **Confirm Signup Email**
```html
<h2>Welcome to School Management SaaS!</h2>
<p>Hi {{ .Name }},</p>
<p>Thanks for signing up! Please confirm your email address by clicking the button below:</p>
<p><a href="{{ .ConfirmationURL }}" style="padding: 10px 20px; background-color: #4F46E5; color: white; text-decoration: none; border-radius: 5px;">Confirm Email</a></p>
<p>This link expires in 24 hours.</p>
<p>If you didn't create an account, you can safely ignore this email.</p>
```

#### **Reset Password Email**
```html
<h2>Reset Your Password</h2>
<p>Hi {{ .Name }},</p>
<p>We received a request to reset your password. Click the button below to reset it:</p>
<p><a href="{{ .ConfirmationURL }}" style="padding: 10px 20px; background-color: #4F46E5; color: white; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
<p>This link expires in 1 hour.</p>
<p>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
```

#### **Invite User Email**
```html
<h2>You've Been Invited!</h2>
<p>Hi {{ .Name }},</p>
<p>You've been invited to join {{ .Tenant }} on School Management SaaS.</p>
<p>Click the button below to accept the invitation and set up your account:</p>
<p><a href="{{ .ConfirmationURL }}" style="padding: 10px 20px; background-color: #4F46E5; color: white; text-decoration: none; border-radius: 5px;">Accept Invitation</a></p>
<p>This invitation expires in 7 days.</p>
```

#### **Email Change Email**
```html
<h2>Confirm Email Change</h2>
<p>Hi {{ .Name }},</p>
<p>We received a request to change your email address to {{ .NewEmail }}.</p>
<p>Click the button below to confirm this change:</p>
<p><a href="{{ .ConfirmationURL }}" style="padding: 10px 20px; background-color: #4F46E5; color: white; text-decoration: none; border-radius: 5px;">Confirm Email Change</a></p>
<p>If you didn't request this change, please contact support immediately.</p>
```

---

### Auth Settings (Supabase Dashboard)

```yaml
# Authentication > Settings

# General Settings
Site URL: https://yourdomain.com
Redirect URLs:
  - https://yourdomain.com/auth/callback
  - https://yourdomain.com/auth/confirm
  - http://localhost:3000/auth/callback
  - http://localhost:3000/auth/confirm

# Email Auth
Enable Email Signup: true
Enable Email Confirmations: true
Secure Email Change: true
Double Confirm Email Changes: true

# Password Settings
Minimum Password Length: 8

# JWT Settings
JWT Expiry: 3600 (1 hour)
JWT Secret: [Auto-generated]

# Security
Enable Refresh Token Rotation: true
Refresh Token Reuse Interval: 10 seconds

# Rate Limiting
Rate Limit: 60 requests per hour

# SMTP Settings
Enable Custom SMTP: true
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP User: apikey
SMTP Password: [Your SendGrid API Key]
SMTP Sender Email: noreply@yourdomain.com
SMTP Sender Name: School Management SaaS
```

---

### OAuth Provider Setup

#### **Google OAuth**
```yaml
# Supabase Dashboard > Authentication > Providers > Google

Enabled: true
Client ID: [From Google Cloud Console]
Client Secret: [From Google Cloud Console]
Redirect URL: https://[your-project].supabase.co/auth/v1/callback
Authorized Domains: yourdomain.com

# Google Cloud Console Setup:
# 1. Create OAuth 2.0 Client ID
# 2. Add authorized redirect URIs:
#    - https://[your-project].supabase.co/auth/v1/callback
# 3. Add authorized domains
```

#### **Microsoft OAuth**
```yaml
# Supabase Dashboard > Authentication > Providers > Azure (Microsoft)

Enabled: true
Client ID: [From Azure Portal]
Client Secret: [From Azure Portal]
Redirect URL: https://[your-project].supabase.co/auth/v1/callback
Tenant: common (for multi-tenant) or your tenant ID

# Azure Portal Setup:
# 1. Register application in Azure AD
# 2. Add redirect URI:
#    - https://[your-project].supabase.co/auth/v1/callback
# 3. Create client secret
# 4. Configure API permissions (User.Read, email, profile)
```

---

## 📦 REQUIRED PACKAGES

```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "@supabase/ssr": "^0.1.0",
    "next": "^15.0.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0"
  }
}
```

---

## 🧪 TESTING

### Test Suite

```typescript
// __tests__/lib/supabase/client.test.ts
import { createClient, getSupabaseBrowserClient } from '@/lib/supabase/client'

describe('Supabase Browser Client', () => {
  it('should create client with correct configuration', () => {
    const client = createClient()
    expect(client).toBeDefined()
  })

  it('should return singleton instance', () => {
    const client1 = getSupabaseBrowserClient()
    const client2 = getSupabaseBrowserClient()
    expect(client1).toBe(client2)
  })

  it('should have auth configured', () => {
    const client = createClient()
    expect(client.auth).toBeDefined()
  })
})

// __tests__/lib/auth/config.test.ts
import { isPasswordStrong, AUTH_CONFIG } from '@/lib/auth/config'

describe('Password Validation', () => {
  it('should validate strong password', () => {
    const result = isPasswordStrong('StrongPass123!')
    expect(result.valid).toBe(true)
    expect(result.errors).toHaveLength(0)
  })

  it('should reject weak password', () => {
    const result = isPasswordStrong('weak')
    expect(result.valid).toBe(false)
    expect(result.errors.length).toBeGreaterThan(0)
  })

  it('should require minimum length', () => {
    const result = isPasswordStrong('Short1!')
    expect(result.valid).toBe(false)
    expect(result.errors).toContain(
      `Password must be at least ${AUTH_CONFIG.password.minLength} characters`
    )
  })
})
```

---

## ✅ COMPLETION CHECKLIST

- [x] Browser client configured
- [x] Server client configured
- [x] Middleware client configured
- [x] Admin client configured
- [x] Auth configuration defined
- [x] Password validation implemented
- [x] TypeScript types created
- [x] Email templates created
- [x] OAuth providers configured
- [x] Rate limiting configured
- [x] Security settings configured
- [x] Redirect URLs configured
- [x] Tests created
- [x] Documentation complete

---

## 📚 RELATED SPECS

- ⬅️ **SPEC-005**: Environment Variables
- ⬅️ **SPEC-009**: Multi-tenant Architecture
- ➡️ **SPEC-036**: Authentication API
- ➡️ **SPEC-037**: Auth Context & Hooks
- ➡️ **SPEC-038**: Auth Middleware

---

## 📝 NOTES

### Security Best Practices
- Never expose service role key to client
- Always validate JWT tokens on server
- Use PKCE flow for enhanced security
- Rotate refresh tokens regularly
- Implement rate limiting on auth endpoints

### Performance Tips
- Use singleton pattern for browser client
- Cache auth state in context
- Minimize auth checks in middleware
- Use appropriate client for each context

### Common Issues
- Cookie size limits in middleware
- OAuth redirect URL mismatches
- CORS issues with custom domains
- Session persistence in Next.js

---

**Author**: AI Assistant  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0
