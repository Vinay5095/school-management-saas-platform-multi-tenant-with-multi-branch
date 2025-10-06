/**
 * Next.js Middleware
 * Handles authentication and authorization for protected routes
 */

import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createClient } from '@/lib/supabase/middleware'
import { AUTH_CONFIG, isProtectedRoute, isPublicRoute } from '@/lib/auth/config'

export async function middleware(request: NextRequest) {
  const { supabase, response } = await createClient(request)
  const pathname = request.nextUrl.pathname

  // Refresh session if expired
  const { data: { session } } = await supabase.auth.getSession()

  // Public routes - allow access
  if (isPublicRoute(pathname)) {
    return response
  }

  // Protected routes - require authentication
  if (isProtectedRoute(pathname)) {
    if (!session) {
      // Redirect to login if not authenticated
      const redirectUrl = new URL(AUTH_CONFIG.REDIRECT_URLS.LOGIN, request.url)
      redirectUrl.searchParams.set('redirect', pathname)
      return NextResponse.redirect(redirectUrl)
    }

    // Get user profile to check role and permissions
    const { data: userProfile } = await supabase
      .from('users')
      .select('id, role, status, tenant_id, branch_id')
      .eq('id', session.user.id)
      .single()

    if (!userProfile) {
      return NextResponse.redirect(new URL(AUTH_CONFIG.REDIRECT_URLS.LOGIN, request.url))
    }

    // Check if user is active (cast to any to avoid type issues with Supabase inference)
    const profile = userProfile as any
    if (profile.status !== 'active') {
      return NextResponse.redirect(new URL(AUTH_CONFIG.REDIRECT_URLS.UNAUTHORIZED, request.url))
    }

    // Add user info to headers for downstream use
    response.headers.set('x-user-id', session.user.id)
    response.headers.set('x-user-role', profile.role)
    response.headers.set('x-tenant-id', profile.tenant_id)
    if (profile.branch_id) {
      response.headers.set('x-branch-id', profile.branch_id)
    }

    return response
  }

  // Default - allow access
  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
