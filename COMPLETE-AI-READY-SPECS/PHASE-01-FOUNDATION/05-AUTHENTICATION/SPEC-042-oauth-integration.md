# SPEC-042: OAuth Integration
## Google & Microsoft OAuth 2.0 Integration

> **Status**: ✅ COMPLETE  
> **Priority**: HIGH  
> **Estimated Time**: 4 hours  
> **Dependencies**: SPEC-035 (Supabase Config)

---

## 📋 OVERVIEW

Complete OAuth 2.0 integration with Google and Microsoft providers, supporting single sign-on (SSO), profile synchronization, and seamless authentication flow.

---

## 🎯 OBJECTIVES

- ✅ Google OAuth integration
- ✅ Microsoft OAuth integration
- ✅ Profile data synchronization
- ✅ OAuth error handling
- ✅ Account linking
- ✅ Provider management
- ✅ OAuth callbacks

---

## 🔧 IMPLEMENTATION

### 1. OAuth Configuration

#### Google Cloud Console Setup
```yaml
# Google OAuth 2.0 Setup

Project: School Management SaaS

OAuth 2.0 Client ID:
  Application Type: Web Application
  Name: School SaaS Production
  
Authorized JavaScript Origins:
  - https://yourdomain.com
  - http://localhost:3000 (for development)
  
Authorized Redirect URIs:
  - https://[your-project].supabase.co/auth/v1/callback
  - http://localhost:3000/auth/callback
  
Scopes:
  - email
  - profile
  - openid
```

#### Azure Portal Setup (Microsoft)
```yaml
# Microsoft OAuth Setup

Azure AD App Registration:
  Name: School Management SaaS
  Supported Account Types: Multitenant
  
Redirect URIs:
  Platform: Web
  URIs:
    - https://[your-project].supabase.co/auth/v1/callback
    - http://localhost:3000/auth/callback
    
API Permissions:
  - Microsoft Graph:
      - User.Read (Delegated)
      - email (Delegated)
      - profile (Delegated)
      - openid (Delegated)
      
Client Secret:
  Create and copy immediately (shown only once)
```

---

### 2. OAuth Component

#### `src/components/auth/oauth-buttons.tsx`
```typescript
'use client'

/**
 * OAuth Sign-In Buttons
 * Google and Microsoft authentication buttons
 */

import { useState } from 'react'
import { useAuth } from '@/hooks/use-auth'
import { Button } from '@/components/ui/button'
import { Icons } from '@/components/ui/icons'
import { toast } from '@/components/ui/use-toast'

interface OAuthButtonsProps {
  onSuccess?: () => void
  onError?: (error: Error) => void
}

export function OAuthButtons({ onSuccess, onError }: OAuthButtonsProps) {
  const { signInWithOAuth } = useAuth()
  const [isLoading, setIsLoading] = useState<{
    google: boolean
    microsoft: boolean
  }>({
    google: false,
    microsoft: false,
  })

  const handleOAuthSignIn = async (provider: 'google' | 'microsoft') => {
    setIsLoading((prev) => ({ ...prev, [provider]: true }))

    try {
      await signInWithOAuth(provider)
      onSuccess?.()
    } catch (error) {
      console.error(`${provider} OAuth error:`, error)
      toast({
        title: 'Authentication Failed',
        description: `Failed to sign in with ${provider}. Please try again.`,
        variant: 'destructive',
      })
      onError?.(error as Error)
    } finally {
      setIsLoading((prev) => ({ ...prev, [provider]: false }))
    }
  }

  return (
    <div className="space-y-3">
      {/* Google Sign-In */}
      <Button
        type="button"
        variant="outline"
        className="w-full"
        onClick={() => handleOAuthSignIn('google')}
        disabled={isLoading.google}
      >
        {isLoading.google ? (
          <Icons.spinner className="mr-2 h-4 w-4 animate-spin" />
        ) : (
          <Icons.google className="mr-2 h-4 w-4" />
        )}
        Continue with Google
      </Button>

      {/* Microsoft Sign-In */}
      <Button
        type="button"
        variant="outline"
        className="w-full"
        onClick={() => handleOAuthSignIn('microsoft')}
        disabled={isLoading.microsoft}
      >
        {isLoading.microsoft ? (
          <Icons.spinner className="mr-2 h-4 w-4 animate-spin" />
        ) : (
          <Icons.microsoft className="mr-2 h-4 w-4" />
        )}
        Continue with Microsoft
      </Button>

      <div className="relative">
        <div className="absolute inset-0 flex items-center">
          <span className="w-full border-t" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-background px-2 text-muted-foreground">
            Or continue with email
          </span>
        </div>
      </div>
    </div>
  )
}
```

---

### 3. OAuth Callback Handler

#### `src/app/auth/callback/route.ts`
```typescript
/**
 * OAuth Callback Handler
 * Processes OAuth authentication callbacks
 */

import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const error = requestUrl.searchParams.get('error')
  const errorDescription = requestUrl.searchParams.get('error_description')

  // Handle OAuth errors
  if (error) {
    console.error('OAuth error:', error, errorDescription)
    return NextResponse.redirect(
      new URL(
        `/login?error=${encodeURIComponent(error)}&description=${encodeURIComponent(
          errorDescription || 'OAuth authentication failed'
        )}`,
        requestUrl.origin
      )
    )
  }

  if (code) {
    try {
      const supabase = await createClient()

      // Exchange code for session
      const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code)

      if (exchangeError) {
        throw exchangeError
      }

      if (data.session) {
        // Sync OAuth profile data
        await syncOAuthProfile(data.session.user)

        // Check if user needs onboarding
        const needsOnboarding = !data.session.user.user_metadata?.tenant_id

        if (needsOnboarding) {
          return NextResponse.redirect(new URL('/onboarding', requestUrl.origin))
        }

        // Redirect to dashboard
        return NextResponse.redirect(new URL('/dashboard', requestUrl.origin))
      }
    } catch (error) {
      console.error('OAuth callback error:', error)
      return NextResponse.redirect(
        new URL('/login?error=oauth_callback_failed', requestUrl.origin)
      )
    }
  }

  // Fallback redirect
  return NextResponse.redirect(new URL('/login', requestUrl.origin))
}

/**
 * Sync OAuth profile data with our database
 */
async function syncOAuthProfile(user: any): Promise<void> {
  try {
    const supabase = await createClient()

    // Extract profile data from OAuth provider
    const { email, user_metadata } = user
    const provider = user.app_metadata?.provider

    let profileData: any = {
      email,
      email_verified: true,
      avatar_url: user_metadata.avatar_url || user_metadata.picture,
    }

    // Provider-specific data mapping
    if (provider === 'google') {
      profileData = {
        ...profileData,
        first_name: user_metadata.given_name,
        last_name: user_metadata.family_name,
        full_name: user_metadata.full_name || user_metadata.name,
      }
    } else if (provider === 'microsoft' || provider === 'azure') {
      profileData = {
        ...profileData,
        first_name: user_metadata.given_name || user_metadata.givenName,
        last_name: user_metadata.family_name || user_metadata.surname,
        full_name: user_metadata.name || user_metadata.displayName,
      }
    }

    // Update user metadata
    await supabase.auth.updateUser({
      data: profileData,
    })

    console.log('OAuth profile synced successfully')
  } catch (error) {
    console.error('Failed to sync OAuth profile:', error)
  }
}
```

---

### 4. Account Linking

#### `src/lib/auth/account-linking.ts`
```typescript
/**
 * OAuth Account Linking
 * Link OAuth providers to existing accounts
 */

import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'

export interface LinkedAccount {
  provider: string
  provider_id: string
  email: string
  linked_at: string
}

/**
 * Get linked OAuth accounts for user
 */
export async function getLinkedAccounts(userId: string): Promise<LinkedAccount[]> {
  try {
    const adminClient = createAdminClient()

    const { data: user, error } = await adminClient.auth.admin.getUserById(userId)

    if (error || !user) {
      return []
    }

    return (user.user.identities || []).map((identity) => ({
      provider: identity.provider,
      provider_id: identity.id,
      email: identity.identity_data?.email || '',
      linked_at: identity.created_at || '',
    }))
  } catch (error) {
    console.error('Failed to get linked accounts:', error)
    return []
  }
}

/**
 * Link OAuth provider to existing account
 */
export async function linkOAuthAccount(
  userId: string,
  provider: 'google' | 'microsoft'
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    const supabase = await createClient()

    const { data, error } = await supabase.auth.linkIdentity({
      provider,
      options: {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
      },
    })

    if (error) {
      return { success: false, error: error.message }
    }

    return { success: true, url: data.url }
  } catch (error: any) {
    return { success: false, error: error.message }
  }
}

/**
 * Unlink OAuth provider from account
 */
export async function unlinkOAuthAccount(
  userId: string,
  provider: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const supabase = await createClient()

    const { error } = await supabase.auth.unlinkIdentity({
      provider,
    })

    if (error) {
      return { success: false, error: error.message }
    }

    return { success: true }
  } catch (error: any) {
    return { success: false, error: error.message }
  }
}
```

---

### 5. OAuth Provider Management Component

#### `src/components/settings/oauth-providers.tsx`
```typescript
'use client'

/**
 * OAuth Providers Management
 * UI for managing linked OAuth accounts
 */

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Icons } from '@/components/ui/icons'
import { toast } from '@/components/ui/use-toast'
import {
  getLinkedAccounts,
  linkOAuthAccount,
  unlinkOAuthAccount,
  type LinkedAccount,
} from '@/lib/auth/account-linking'
import { useUser } from '@/hooks/use-user'

export function OAuthProviders() {
  const { userId } = useUser()
  const [linkedAccounts, setLinkedAccounts] = useState<LinkedAccount[]>([])
  const [isLoading, setIsLoading] = useState(false)

  useEffect(() => {
    if (userId) {
      loadLinkedAccounts()
    }
  }, [userId])

  const loadLinkedAccounts = async () => {
    if (!userId) return
    const accounts = await getLinkedAccounts(userId)
    setLinkedAccounts(accounts)
  }

  const handleLink = async (provider: 'google' | 'microsoft') => {
    if (!userId) return

    setIsLoading(true)
    try {
      const result = await linkOAuthAccount(userId, provider)

      if (result.success && result.url) {
        window.location.href = result.url
      } else {
        toast({
          title: 'Failed to link account',
          description: result.error,
          variant: 'destructive',
        })
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: 'An unexpected error occurred',
        variant: 'destructive',
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleUnlink = async (provider: string) => {
    if (!userId) return

    if (linkedAccounts.length <= 1) {
      toast({
        title: 'Cannot unlink',
        description: 'You must have at least one authentication method',
        variant: 'destructive',
      })
      return
    }

    setIsLoading(true)
    try {
      const result = await unlinkOAuthAccount(userId, provider)

      if (result.success) {
        toast({
          title: 'Account unlinked',
          description: `${provider} account has been unlinked successfully`,
        })
        await loadLinkedAccounts()
      } else {
        toast({
          title: 'Failed to unlink',
          description: result.error,
          variant: 'destructive',
        })
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: 'An unexpected error occurred',
        variant: 'destructive',
      })
    } finally {
      setIsLoading(false)
    }
  }

  const isLinked = (provider: string) => {
    return linkedAccounts.some((account) => account.provider === provider)
  }

  const providers = [
    { id: 'google', name: 'Google', icon: Icons.google },
    { id: 'microsoft', name: 'Microsoft', icon: Icons.microsoft },
  ]

  return (
    <div className="space-y-4">
      <div>
        <h3 className="text-lg font-medium">Linked Accounts</h3>
        <p className="text-sm text-muted-foreground">
          Connect your account with OAuth providers for quick sign-in
        </p>
      </div>

      <div className="space-y-3">
        {providers.map((provider) => {
          const linked = isLinked(provider.id)
          const Icon = provider.icon

          return (
            <Card key={provider.id} className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <Icon className="h-6 w-6" />
                  <div>
                    <p className="font-medium">{provider.name}</p>
                    {linked && (
                      <p className="text-sm text-muted-foreground">Connected</p>
                    )}
                  </div>
                </div>

                {linked ? (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleUnlink(provider.id)}
                    disabled={isLoading}
                  >
                    Disconnect
                  </Button>
                ) : (
                  <Button
                    variant="default"
                    size="sm"
                    onClick={() => handleLink(provider.id as any)}
                    disabled={isLoading}
                  >
                    Connect
                  </Button>
                )}
              </div>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
// __tests__/lib/auth/oauth.test.ts
import { linkOAuthAccount, unlinkOAuthAccount } from '@/lib/auth/account-linking'

describe('OAuth Account Linking', () => {
  it('should link Google account', async () => {
    const result = await linkOAuthAccount('user-id', 'google')
    expect(result.success).toBe(true)
    expect(result.url).toBeDefined()
  })

  it('should unlink provider', async () => {
    const result = await unlinkOAuthAccount('user-id', 'google')
    expect(result.success).toBe(true)
  })
})
```

---

## ✅ COMPLETION CHECKLIST

- [x] Google OAuth configured
- [x] Microsoft OAuth configured
- [x] OAuth buttons component created
- [x] Callback handler implemented
- [x] Profile synchronization implemented
- [x] Account linking functionality added
- [x] Provider management UI created
- [x] Error handling implemented
- [x] Tests created
- [x] Documentation complete

---

## 📚 RELATED SPECS

- ⬅️ **SPEC-035**: Supabase Auth Configuration
- ⬅️ **SPEC-037**: Auth Context & Hooks
- ➡️ **SPEC-043**: Two-Factor Authentication

---

**Author**: AI Assistant  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0
