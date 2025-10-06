/**
 * Authentication Configuration
 * Centralized auth settings and constants
 */

export const AUTH_CONFIG = {
  // Session settings
  SESSION_DURATION: 60 * 60 * 24 * 7, // 7 days in seconds
  REFRESH_TOKEN_DURATION: 60 * 60 * 24 * 30, // 30 days in seconds
  
  // Password requirements
  PASSWORD_MIN_LENGTH: 8,
  PASSWORD_REQUIRE_UPPERCASE: true,
  PASSWORD_REQUIRE_LOWERCASE: true,
  PASSWORD_REQUIRE_NUMBER: true,
  PASSWORD_REQUIRE_SPECIAL: true,
  
  // Rate limiting
  MAX_LOGIN_ATTEMPTS: 5,
  LOGIN_ATTEMPT_WINDOW: 15 * 60, // 15 minutes in seconds
  LOCKOUT_DURATION: 30 * 60, // 30 minutes in seconds
  
  // OAuth providers
  OAUTH_PROVIDERS: {
    GOOGLE: 'google',
    MICROSOFT: 'azure',
    APPLE: 'apple',
  },
  
  // Redirect URLs
  REDIRECT_URLS: {
    LOGIN: '/auth/login',
    REGISTER: '/auth/register',
    FORGOT_PASSWORD: '/auth/forgot-password',
    RESET_PASSWORD: '/auth/reset-password',
    VERIFY_EMAIL: '/auth/verify-email',
    OAUTH_CALLBACK: '/auth/callback',
    DEFAULT_REDIRECT: '/dashboard',
    UNAUTHORIZED: '/unauthorized',
  },
  
  // Protected routes (require authentication)
  PROTECTED_ROUTES: [
    '/dashboard',
    '/profile',
    '/settings',
    '/students',
    '/teachers',
    '/staff',
    '/classes',
    '/attendance',
    '/exams',
    '/fees',
    '/library',
    '/transport',
  ],
  
  // Public routes (no authentication required)
  PUBLIC_ROUTES: [
    '/',
    '/auth/login',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/verify-email',
    '/auth/callback',
  ],
  
  // Role-based permissions
  ROLES: {
    SUPER_ADMIN: 'super_admin',
    TENANT_ADMIN: 'tenant_admin',
    BRANCH_ADMIN: 'branch_admin',
    TEACHER: 'teacher',
    STUDENT: 'student',
    PARENT: 'parent',
    STAFF: 'staff',
  },
  
  // User statuses
  USER_STATUS: {
    ACTIVE: 'active',
    INACTIVE: 'inactive',
    SUSPENDED: 'suspended',
  },
} as const

export type Role = typeof AUTH_CONFIG.ROLES[keyof typeof AUTH_CONFIG.ROLES]
export type UserStatus = typeof AUTH_CONFIG.USER_STATUS[keyof typeof AUTH_CONFIG.USER_STATUS]

/**
 * Password validation regex
 */
export const PASSWORD_REGEX = {
  UPPERCASE: /[A-Z]/,
  LOWERCASE: /[a-z]/,
  NUMBER: /[0-9]/,
  SPECIAL: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/,
}

/**
 * Validate password against requirements
 */
export function validatePassword(password: string): { valid: boolean; errors: string[] } {
  const errors: string[] = []
  
  if (password.length < AUTH_CONFIG.PASSWORD_MIN_LENGTH) {
    errors.push(`Password must be at least ${AUTH_CONFIG.PASSWORD_MIN_LENGTH} characters long`)
  }
  
  if (AUTH_CONFIG.PASSWORD_REQUIRE_UPPERCASE && !PASSWORD_REGEX.UPPERCASE.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  }
  
  if (AUTH_CONFIG.PASSWORD_REQUIRE_LOWERCASE && !PASSWORD_REGEX.LOWERCASE.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  }
  
  if (AUTH_CONFIG.PASSWORD_REQUIRE_NUMBER && !PASSWORD_REGEX.NUMBER.test(password)) {
    errors.push('Password must contain at least one number')
  }
  
  if (AUTH_CONFIG.PASSWORD_REQUIRE_SPECIAL && !PASSWORD_REGEX.SPECIAL.test(password)) {
    errors.push('Password must contain at least one special character')
  }
  
  return {
    valid: errors.length === 0,
    errors,
  }
}

/**
 * Check if route is protected
 */
export function isProtectedRoute(pathname: string): boolean {
  return AUTH_CONFIG.PROTECTED_ROUTES.some(route => pathname.startsWith(route))
}

/**
 * Check if route is public
 */
export function isPublicRoute(pathname: string): boolean {
  return AUTH_CONFIG.PUBLIC_ROUTES.some(route => pathname === route || pathname.startsWith(route))
}

/**
 * Get redirect URL after login based on user role
 */
export function getRedirectUrl(role: Role): string {
  switch (role) {
    case AUTH_CONFIG.ROLES.SUPER_ADMIN:
    case AUTH_CONFIG.ROLES.TENANT_ADMIN:
    case AUTH_CONFIG.ROLES.BRANCH_ADMIN:
      return '/dashboard/admin'
    case AUTH_CONFIG.ROLES.TEACHER:
      return '/dashboard/teacher'
    case AUTH_CONFIG.ROLES.STUDENT:
      return '/dashboard/student'
    case AUTH_CONFIG.ROLES.PARENT:
      return '/dashboard/parent'
    case AUTH_CONFIG.ROLES.STAFF:
      return '/dashboard/staff'
    default:
      return AUTH_CONFIG.REDIRECT_URLS.DEFAULT_REDIRECT
  }
}
