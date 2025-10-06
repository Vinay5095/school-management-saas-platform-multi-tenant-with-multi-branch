/**
 * OAuth Callback Handler
 * Handles OAuth authentication callbacks from providers
 */

import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { AUTH_CONFIG } from '@/lib/auth/config'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const next = requestUrl.searchParams.get('next') || AUTH_CONFIG.REDIRECT_URLS.DEFAULT_REDIRECT

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    
    if (error) {
      console.error('OAuth callback error:', error)
      return NextResponse.redirect(
        new URL(`${AUTH_CONFIG.REDIRECT_URLS.LOGIN}?error=${encodeURIComponent(error.message)}`, requestUrl.origin)
      )
    }
  }

  // URL to redirect to after sign in process completes
  return NextResponse.redirect(new URL(next, requestUrl.origin))
}
