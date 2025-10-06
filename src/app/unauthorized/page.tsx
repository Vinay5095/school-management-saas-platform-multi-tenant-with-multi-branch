import Link from 'next/link'
import { AUTH_CONFIG } from '@/lib/auth/config'

export default function UnauthorizedPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-md space-y-8 text-center">
        <div>
          <div className="mx-auto flex h-24 w-24 items-center justify-center rounded-full bg-destructive/10">
            <svg className="h-12 w-12 text-destructive" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h1 className="mt-6 text-4xl font-bold tracking-tight">Access Denied</h1>
          <p className="mt-4 text-muted-foreground">
            You don't have permission to access this resource, or your account has been suspended.
          </p>
          <p className="mt-2 text-sm text-muted-foreground">
            Please contact your administrator if you believe this is an error.
          </p>
        </div>
        <div className="mt-8 space-y-4">
          <Link
            href={AUTH_CONFIG.REDIRECT_URLS.DEFAULT_REDIRECT}
            className="inline-block rounded-md bg-primary px-6 py-3 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90"
          >
            Go to Dashboard
          </Link>
          <br />
          <Link
            href={AUTH_CONFIG.REDIRECT_URLS.LOGIN}
            className="inline-block text-sm font-medium text-primary hover:underline"
          >
            Sign in with a different account
          </Link>
        </div>
      </div>
    </div>
  )
}
