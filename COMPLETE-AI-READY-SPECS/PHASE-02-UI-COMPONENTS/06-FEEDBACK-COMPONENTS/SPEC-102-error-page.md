# SPEC-102: Error Page Component
## Custom Error Pages (404, 500, 503)

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
Pre-built error page components for common HTTP errors (404 Not Found, 500 Internal Server Error, 503 Service Unavailable) with consistent branding and helpful actions.

### Key Features
- ✅ Multiple error page variants
- ✅ Customizable content
- ✅ Illustration/icon support
- ✅ Action buttons
- ✅ Search functionality (404)
- ✅ Status indicator (503)
- ✅ Responsive design
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/error-page.tsx
import * as React from 'react'
import { Home, Search, RefreshCw, ArrowLeft, Mail } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ErrorPageProps {
  /**
   * Error code
   */
  code?: string | number

  /**
   * Error title
   */
  title: string

  /**
   * Error description
   */
  description?: string

  /**
   * Show search bar (for 404)
   */
  showSearch?: boolean

  /**
   * Search placeholder
   */
  searchPlaceholder?: string

  /**
   * On search callback
   */
  onSearch?: (query: string) => void

  /**
   * Show home button
   */
  showHomeButton?: boolean

  /**
   * Show back button
   */
  showBackButton?: boolean

  /**
   * Show refresh button
   */
  showRefreshButton?: boolean

  /**
   * Custom actions
   */
  actions?: React.ReactNode

  /**
   * Illustration or icon
   */
  illustration?: React.ReactNode

  /**
   * Additional content
   */
  children?: React.ReactNode

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// ERROR PAGE COMPONENT
// ========================================

/**
 * Error Page Component
 * 
 * Generic error page with customizable content and actions.
 */
export function ErrorPage({
  code,
  title,
  description,
  showSearch = false,
  searchPlaceholder = 'Search...',
  onSearch,
  showHomeButton = true,
  showBackButton = false,
  showRefreshButton = false,
  actions,
  illustration,
  children,
  className,
}: ErrorPageProps) {
  const [searchQuery, setSearchQuery] = React.useState('')

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    onSearch?.(searchQuery)
  }

  return (
    <div
      className={cn(
        'min-h-screen flex items-center justify-center bg-background p-6',
        className
      )}
    >
      <div className="max-w-2xl w-full space-y-8 text-center">
        {/* Illustration/Icon */}
        {illustration && (
          <div className="flex justify-center">{illustration}</div>
        )}

        {/* Error Code */}
        {code && (
          <div className="text-6xl md:text-8xl font-bold text-muted-foreground/20">
            {code}
          </div>
        )}

        {/* Title & Description */}
        <div className="space-y-3">
          <h1 className="text-3xl md:text-4xl font-bold">{title}</h1>
          {description && (
            <p className="text-lg text-muted-foreground max-w-md mx-auto">
              {description}
            </p>
          )}
        </div>

        {/* Search (for 404) */}
        {showSearch && (
          <form onSubmit={handleSearch} className="max-w-md mx-auto">
            <div className="flex gap-2">
              <Input
                type="text"
                placeholder={searchPlaceholder}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="flex-1"
              />
              <Button type="submit">
                <Search className="h-4 w-4" />
              </Button>
            </div>
          </form>
        )}

        {/* Custom Content */}
        {children && <div className="max-w-md mx-auto">{children}</div>}

        {/* Actions */}
        <div className="flex flex-wrap gap-3 justify-center">
          {showBackButton && (
            <Button
              variant="outline"
              onClick={() => window.history.back()}
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              Go Back
            </Button>
          )}

          {showHomeButton && (
            <Button onClick={() => (window.location.href = '/')}>
              <Home className="mr-2 h-4 w-4" />
              Go Home
            </Button>
          )}

          {showRefreshButton && (
            <Button onClick={() => window.location.reload()}>
              <RefreshCw className="mr-2 h-4 w-4" />
              Refresh
            </Button>
          )}

          {actions}
        </div>
      </div>
    </div>
  )
}

// ========================================
// 404 NOT FOUND
// ========================================

export interface NotFoundPageProps {
  /**
   * Custom title
   */
  title?: string

  /**
   * Custom description
   */
  description?: string

  /**
   * Show search bar
   */
  showSearch?: boolean

  /**
   * On search callback
   */
  onSearch?: (query: string) => void

  /**
   * Suggested links
   */
  suggestions?: Array<{
    label: string
    href: string
  }>
}

/**
 * 404 Not Found Page
 */
export function NotFoundPage({
  title = 'Page Not Found',
  description = "The page you're looking for doesn't exist or has been moved.",
  showSearch = true,
  onSearch,
  suggestions,
}: NotFoundPageProps) {
  return (
    <ErrorPage
      code={404}
      title={title}
      description={description}
      showSearch={showSearch}
      onSearch={onSearch}
      showHomeButton
      showBackButton
      illustration={
        <div className="relative">
          <div className="text-9xl">🔍</div>
        </div>
      }
    >
      {suggestions && suggestions.length > 0 && (
        <div className="space-y-3">
          <p className="text-sm font-medium">Here are some helpful links:</p>
          <div className="space-y-2">
            {suggestions.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="block text-sm text-primary hover:underline"
              >
                {link.label}
              </a>
            ))}
          </div>
        </div>
      )}
    </ErrorPage>
  )
}

// ========================================
// 500 INTERNAL SERVER ERROR
// ========================================

export interface ServerErrorPageProps {
  /**
   * Custom title
   */
  title?: string

  /**
   * Custom description
   */
  description?: string

  /**
   * Error ID (for support)
   */
  errorId?: string

  /**
   * Support email
   */
  supportEmail?: string
}

/**
 * 500 Internal Server Error Page
 */
export function ServerErrorPage({
  title = 'Internal Server Error',
  description = "Something went wrong on our end. We're working to fix it.",
  errorId,
  supportEmail = 'support@example.com',
}: ServerErrorPageProps) {
  return (
    <ErrorPage
      code={500}
      title={title}
      description={description}
      showHomeButton
      showRefreshButton
      illustration={
        <div className="relative">
          <div className="text-9xl">⚠️</div>
        </div>
      }
      actions={
        supportEmail && (
          <Button
            variant="outline"
            onClick={() =>
              (window.location.href = `mailto:${supportEmail}${
                errorId ? `?subject=Error Report (${errorId})` : ''
              }`)
            }
          >
            <Mail className="mr-2 h-4 w-4" />
            Contact Support
          </Button>
        )
      }
    >
      {errorId && (
        <div className="text-sm text-muted-foreground">
          <p>Error ID: {errorId}</p>
          <p className="mt-1">
            Please include this ID when contacting support.
          </p>
        </div>
      )}
    </ErrorPage>
  )
}

// ========================================
// 503 SERVICE UNAVAILABLE
// ========================================

export interface MaintenancePageProps {
  /**
   * Custom title
   */
  title?: string

  /**
   * Custom description
   */
  description?: string

  /**
   * Estimated time
   */
  estimatedTime?: string

  /**
   * Show countdown
   */
  countdown?: Date

  /**
   * Status page URL
   */
  statusPageUrl?: string
}

/**
 * 503 Service Unavailable / Maintenance Page
 */
export function MaintenancePage({
  title = 'Under Maintenance',
  description = "We're currently performing scheduled maintenance. We'll be back soon!",
  estimatedTime,
  countdown,
  statusPageUrl,
}: MaintenancePageProps) {
  const [timeLeft, setTimeLeft] = React.useState('')

  React.useEffect(() => {
    if (!countdown) return

    const interval = setInterval(() => {
      const now = new Date().getTime()
      const distance = countdown.getTime() - now

      if (distance < 0) {
        setTimeLeft('Any moment now...')
        clearInterval(interval)
        return
      }

      const hours = Math.floor(distance / (1000 * 60 * 60))
      const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60))
      const seconds = Math.floor((distance % (1000 * 60)) / 1000)

      setTimeLeft(`${hours}h ${minutes}m ${seconds}s`)
    }, 1000)

    return () => clearInterval(interval)
  }, [countdown])

  return (
    <ErrorPage
      code={503}
      title={title}
      description={description}
      showRefreshButton
      illustration={
        <div className="relative">
          <div className="text-9xl">🔧</div>
        </div>
      }
      actions={
        statusPageUrl && (
          <Button
            variant="outline"
            onClick={() => window.open(statusPageUrl, '_blank')}
          >
            Check Status
          </Button>
        )
      }
    >
      {(estimatedTime || timeLeft) && (
        <div className="space-y-2">
          <p className="text-sm font-medium">Estimated Return Time:</p>
          <p className="text-2xl font-bold">
            {timeLeft || estimatedTime}
          </p>
        </div>
      )}
    </ErrorPage>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic 404 Page

```typescript
import { NotFoundPage } from '@/components/ui/error-page'

export default function NotFound() {
  return <NotFoundPage />
}
```

### 404 with Search and Suggestions

```typescript
import { NotFoundPage } from '@/components/ui/error-page'
import { useRouter } from 'next/navigation'

export default function NotFound() {
  const router = useRouter()

  return (
    <NotFoundPage
      showSearch
      onSearch={(query) => router.push(`/search?q=${query}`)}
      suggestions={[
        { label: 'Dashboard', href: '/dashboard' },
        { label: 'Students', href: '/students' },
        { label: 'Classes', href: '/classes' },
        { label: 'Help Center', href: '/help' },
      ]}
    />
  )
}
```

### Custom 404 Page

```typescript
import { ErrorPage } from '@/components/ui/error-page'

export default function CustomNotFound() {
  return (
    <ErrorPage
      code="404"
      title="Oops! Class Not Found"
      description="This class doesn't exist in our system."
      showHomeButton
      showBackButton
      illustration={
        <img src="/illustrations/not-found.svg" alt="Not Found" />
      }
    />
  )
}
```

### 500 Server Error Page

```typescript
import { ServerErrorPage } from '@/components/ui/error-page'

export default function ServerError() {
  return (
    <ServerErrorPage
      errorId="ERR-2024-001-XYZ"
      supportEmail="support@school.com"
    />
  )
}
```

### Maintenance Page

```typescript
import { MaintenancePage } from '@/components/ui/error-page'

export default function Maintenance() {
  const endTime = new Date('2024-01-10T10:00:00')

  return (
    <MaintenancePage
      title="Scheduled Maintenance"
      description="We're upgrading our servers to serve you better. Thank you for your patience!"
      countdown={endTime}
      statusPageUrl="https://status.school.com"
    />
  )
}
```

### Custom Error Page

```typescript
import { ErrorPage } from '@/components/ui/error-page'
import { Button } from '@/components/ui/button'
import { HelpCircle } from 'lucide-react'

export default function CustomError() {
  return (
    <ErrorPage
      code="403"
      title="Access Denied"
      description="You don't have permission to access this resource."
      showHomeButton
      illustration={<div className="text-9xl">🚫</div>}
      actions={
        <>
          <Button variant="outline">
            <HelpCircle className="mr-2 h-4 w-4" />
            Learn More
          </Button>
          <Button onClick={() => window.open('/contact')}>
            Request Access
          </Button>
        </>
      }
    >
      <div className="text-sm text-muted-foreground">
        <p>If you believe this is a mistake, please contact your administrator.</p>
      </div>
    </ErrorPage>
  )
}
```

### School Management Error Pages

```typescript
// Student Not Found
function StudentNotFound() {
  return (
    <NotFoundPage
      title="Student Not Found"
      description="The student you're looking for doesn't exist or has been removed from the system."
      suggestions={[
        { label: 'All Students', href: '/students' },
        { label: 'Add New Student', href: '/students/new' },
        { label: 'Archived Students', href: '/students/archived' },
      ]}
    />
  )
}

// Enrollment Error
function EnrollmentError() {
  return (
    <ServerErrorPage
      title="Enrollment Failed"
      description="We couldn't complete the enrollment process. Please try again or contact support."
      errorId="ENROLL-ERR-001"
      supportEmail="registrar@school.com"
    />
  )
}

// System Maintenance During Exam Period
function ExamMaintenancePage() {
  return (
    <MaintenancePage
      title="System Maintenance"
      description="Our student portal is temporarily unavailable for scheduled maintenance. Exam schedules remain unchanged."
      estimatedTime="2 hours"
      statusPageUrl="https://status.school.com"
    >
      <div className="mt-4 p-4 bg-primary/10 rounded-lg">
        <p className="text-sm font-medium">Important Notice:</p>
        <p className="text-sm text-muted-foreground mt-1">
          All scheduled exams will proceed as planned. Students should report
          to their assigned exam halls at the designated times.
        </p>
      </div>
    </MaintenancePage>
  )
}

// Permission Denied for Grade Access
function GradeAccessDenied() {
  return (
    <ErrorPage
      code="403"
      title="Grade Access Restricted"
      description="You don't have permission to view these grades. Only course instructors and administrators can access this information."
      showHomeButton
      showBackButton
      illustration={<div className="text-9xl">🔒</div>}
      actions={
        <Button onClick={() => window.open('/help/permissions')}>
          Learn About Permissions
        </Button>
      }
    />
  )
}
```

### With Next.js App Router

```typescript
// app/not-found.tsx
import { NotFoundPage } from '@/components/ui/error-page'

export default function NotFound() {
  return <NotFoundPage />
}

// app/error.tsx
'use client'

import { ServerErrorPage } from '@/components/ui/error-page'
import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
  }, [error])

  return (
    <ServerErrorPage
      errorId={error.digest}
      actions={
        <Button onClick={reset}>
          Try Again
        </Button>
      }
    />
  )
}
```

### With Loading State

```typescript
function LoadingErrorPage() {
  const [isLoading, setIsLoading] = React.useState(false)

  const handleRetry = async () => {
    setIsLoading(true)
    try {
      await retryOperation()
      window.location.reload()
    } catch (error) {
      setIsLoading(false)
    }
  }

  return (
    <ServerErrorPage
      actions={
        <Button onClick={handleRetry} disabled={isLoading}>
          {isLoading ? 'Retrying...' : 'Try Again'}
        </Button>
      }
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('ErrorPage', () => {
  it('renders error code, title, and description', () => {
    render(
      <ErrorPage
        code={404}
        title="Not Found"
        description="Page not found"
      />
    )

    expect(screen.getByText('404')).toBeInTheDocument()
    expect(screen.getByText('Not Found')).toBeInTheDocument()
    expect(screen.getByText('Page not found')).toBeInTheDocument()
  })

  it('renders home button by default', () => {
    render(<ErrorPage title="Error" />)
    expect(screen.getByText('Go Home')).toBeInTheDocument()
  })

  it('renders search bar when showSearch is true', () => {
    render(
      <ErrorPage
        title="Error"
        showSearch
        searchPlaceholder="Search here..."
      />
    )

    expect(screen.getByPlaceholderText('Search here...')).toBeInTheDocument()
  })

  it('calls onSearch when form is submitted', () => {
    const onSearch = jest.fn()
    render(<ErrorPage title="Error" showSearch onSearch={onSearch} />)

    const input = screen.getByPlaceholderText('Search...')
    fireEvent.change(input, { target: { value: 'test query' } })

    const form = input.closest('form')
    fireEvent.submit(form!)

    expect(onSearch).toHaveBeenCalledWith('test query')
  })

  it('renders custom actions', () => {
    render(
      <ErrorPage
        title="Error"
        actions={<button>Custom Action</button>}
      />
    )

    expect(screen.getByText('Custom Action')).toBeInTheDocument()
  })
})

describe('NotFoundPage', () => {
  it('renders 404 with default content', () => {
    render(<NotFoundPage />)

    expect(screen.getByText('404')).toBeInTheDocument()
    expect(screen.getByText('Page Not Found')).toBeInTheDocument()
  })

  it('renders suggestions', () => {
    const suggestions = [
      { label: 'Home', href: '/' },
      { label: 'About', href: '/about' },
    ]

    render(<NotFoundPage suggestions={suggestions} />)

    expect(screen.getByText('Home')).toBeInTheDocument()
    expect(screen.getByText('About')).toBeInTheDocument()
  })
})

describe('ServerErrorPage', () => {
  it('renders 500 with error ID', () => {
    render(<ServerErrorPage errorId="ERR-123" />)

    expect(screen.getByText('500')).toBeInTheDocument()
    expect(screen.getByText(/ERR-123/)).toBeInTheDocument()
  })

  it('renders contact support button', () => {
    render(<ServerErrorPage supportEmail="help@example.com" />)
    expect(screen.getByText('Contact Support')).toBeInTheDocument()
  })
})

describe('MaintenancePage', () => {
  it('renders 503 maintenance page', () => {
    render(<MaintenancePage />)

    expect(screen.getByText('503')).toBeInTheDocument()
    expect(screen.getByText('Under Maintenance')).toBeInTheDocument()
  })

  it('renders estimated time', () => {
    render(<MaintenancePage estimatedTime="2 hours" />)
    expect(screen.getByText('2 hours')).toBeInTheDocument()
  })

  it('renders countdown timer', () => {
    jest.useFakeTimers()
    const futureDate = new Date(Date.now() + 3600000) // 1 hour from now

    render(<MaintenancePage countdown={futureDate} />)

    expect(screen.getByText(/\d+h \d+m \d+s/)).toBeInTheDocument()

    jest.useRealTimers()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML structure
- ✅ Clear headings hierarchy
- ✅ Keyboard accessible buttons
- ✅ Focus management
- ✅ Screen reader friendly content
- ✅ Sufficient color contrast

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create error-page.tsx
- [ ] Implement ErrorPage base component
- [ ] Create NotFoundPage (404)
- [ ] Create ServerErrorPage (500)
- [ ] Create MaintenancePage (503)
- [ ] Add search functionality
- [ ] Add countdown timer for maintenance
- [ ] Add responsive design
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples
- [ ] Add custom illustrations/icons

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **All variants**: ~3KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
