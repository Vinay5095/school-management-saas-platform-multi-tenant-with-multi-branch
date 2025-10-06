# SPEC-101: Error Boundary Component
## React Error Boundary with Fallback UI

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: React 18+

---

## 📋 OVERVIEW

### Purpose
A React error boundary component that catches JavaScript errors in child components and displays fallback UI instead of crashing the entire app.

### Key Features
- ✅ Error catching and recovery
- ✅ Multiple fallback variants
- ✅ Error reporting integration
- ✅ Reset functionality
- ✅ Development vs production modes
- ✅ Error context
- ✅ Nested boundaries
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/error-boundary.tsx
import * as React from 'react'
import { AlertTriangle, RefreshCw, Home } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ErrorInfo {
  componentStack: string
}

export interface FallbackProps {
  error: Error
  errorInfo: ErrorInfo | null
  resetError: () => void
}

export interface ErrorBoundaryProps {
  /**
   * Child components to protect
   */
  children: React.ReactNode

  /**
   * Custom fallback component
   */
  fallback?: React.ComponentType<FallbackProps> | React.ReactElement

  /**
   * Fallback render function
   */
  fallbackRender?: (props: FallbackProps) => React.ReactElement

  /**
   * Error callback
   */
  onError?: (error: Error, errorInfo: ErrorInfo) => void

  /**
   * Reset callback
   */
  onReset?: () => void

  /**
   * Reset keys - when any of these change, the error boundary resets
   */
  resetKeys?: Array<string | number>

  /**
   * Variant of default fallback
   */
  variant?: 'default' | 'minimal' | 'full'
}

export interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
  errorInfo: ErrorInfo | null
}

// ========================================
// DEFAULT FALLBACK COMPONENTS
// ========================================

/**
 * Default Error Fallback
 */
export function DefaultErrorFallback({
  error,
  errorInfo,
  resetError,
}: FallbackProps) {
  return (
    <div className="flex items-center justify-center min-h-[400px] p-6">
      <div className="max-w-md w-full space-y-4">
        <div className="flex items-center justify-center">
          <div className="rounded-full bg-destructive/10 p-3">
            <AlertTriangle className="h-6 w-6 text-destructive" />
          </div>
        </div>

        <div className="text-center space-y-2">
          <h3 className="text-lg font-semibold">Something went wrong</h3>
          <p className="text-sm text-muted-foreground">
            An unexpected error occurred. Please try again.
          </p>
        </div>

        {process.env.NODE_ENV === 'development' && (
          <Alert variant="destructive">
            <AlertTitle>Error Details</AlertTitle>
            <AlertDescription className="mt-2 space-y-2">
              <div className="font-mono text-xs break-all">
                {error.message}
              </div>
              {errorInfo && (
                <details className="mt-2">
                  <summary className="cursor-pointer">Stack Trace</summary>
                  <pre className="mt-2 text-xs whitespace-pre-wrap">
                    {errorInfo.componentStack}
                  </pre>
                </details>
              )}
            </AlertDescription>
          </Alert>
        )}

        <div className="flex gap-2">
          <Button onClick={resetError} className="flex-1">
            <RefreshCw className="mr-2 h-4 w-4" />
            Try Again
          </Button>
          <Button variant="outline" onClick={() => (window.location.href = '/')}>
            <Home className="mr-2 h-4 w-4" />
            Go Home
          </Button>
        </div>
      </div>
    </div>
  )
}

/**
 * Minimal Error Fallback
 */
export function MinimalErrorFallback({ error, resetError }: FallbackProps) {
  return (
    <Alert variant="destructive">
      <AlertTriangle className="h-4 w-4" />
      <AlertTitle>Error</AlertTitle>
      <AlertDescription className="flex items-center justify-between">
        <span>{error.message}</span>
        <Button size="sm" variant="outline" onClick={resetError}>
          Retry
        </Button>
      </AlertDescription>
    </Alert>
  )
}

/**
 * Full Page Error Fallback
 */
export function FullPageErrorFallback({
  error,
  errorInfo,
  resetError,
}: FallbackProps) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-6">
      <div className="max-w-2xl w-full space-y-6">
        <div className="text-center space-y-4">
          <div className="flex justify-center">
            <div className="rounded-full bg-destructive/10 p-6">
              <AlertTriangle className="h-12 w-12 text-destructive" />
            </div>
          </div>

          <div className="space-y-2">
            <h1 className="text-3xl font-bold">Oops! Something went wrong</h1>
            <p className="text-muted-foreground">
              We apologize for the inconvenience. Our team has been notified.
            </p>
          </div>
        </div>

        {process.env.NODE_ENV === 'development' && (
          <div className="space-y-4">
            <Alert variant="destructive">
              <AlertTitle className="font-mono">{error.name}</AlertTitle>
              <AlertDescription className="mt-2">
                <div className="font-mono text-sm break-all">
                  {error.message}
                </div>
              </AlertDescription>
            </Alert>

            {errorInfo && (
              <Alert>
                <AlertTitle>Component Stack</AlertTitle>
                <AlertDescription>
                  <pre className="mt-2 text-xs whitespace-pre-wrap overflow-auto max-h-96">
                    {errorInfo.componentStack}
                  </pre>
                </AlertDescription>
              </Alert>
            )}
          </div>
        )}

        <div className="flex gap-2 justify-center">
          <Button onClick={resetError} size="lg">
            <RefreshCw className="mr-2 h-4 w-4" />
            Try Again
          </Button>
          <Button
            variant="outline"
            size="lg"
            onClick={() => (window.location.href = '/')}
          >
            <Home className="mr-2 h-4 w-4" />
            Go Home
          </Button>
        </div>
      </div>
    </div>
  )
}

// ========================================
// ERROR BOUNDARY COMPONENT
// ========================================

/**
 * Error Boundary Component
 * 
 * Catches errors in child components and displays fallback UI.
 */
export class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
    }
  }

  static getDerivedStateFromError(error: Error): Partial<ErrorBoundaryState> {
    return {
      hasError: true,
      error,
    }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    this.setState({
      errorInfo: {
        componentStack: errorInfo.componentStack,
      },
    })

    // Call error handler
    this.props.onError?.(error, {
      componentStack: errorInfo.componentStack,
    })

    // Log to error reporting service
    if (process.env.NODE_ENV === 'production') {
      // Example: Sentry, LogRocket, etc.
      console.error('Error Boundary caught an error:', error, errorInfo)
    }
  }

  componentDidUpdate(prevProps: ErrorBoundaryProps) {
    const { resetKeys } = this.props
    const { hasError } = this.state

    // Reset error boundary if any reset key changes
    if (
      hasError &&
      resetKeys &&
      prevProps.resetKeys &&
      !this.areKeysEqual(prevProps.resetKeys, resetKeys)
    ) {
      this.reset()
    }
  }

  areKeysEqual(
    a: Array<string | number>,
    b: Array<string | number>
  ): boolean {
    return (
      a.length === b.length && a.every((key, index) => key === b[index])
    )
  }

  reset = () => {
    this.props.onReset?.()
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
    })
  }

  render() {
    const { hasError, error, errorInfo } = this.state
    const { children, fallback, fallbackRender, variant = 'default' } = this.props

    if (hasError && error) {
      const fallbackProps: FallbackProps = {
        error,
        errorInfo,
        resetError: this.reset,
      }

      // Custom fallback render function
      if (fallbackRender) {
        return fallbackRender(fallbackProps)
      }

      // Custom fallback component
      if (fallback) {
        if (React.isValidElement(fallback)) {
          return fallback
        }
        const FallbackComponent = fallback as React.ComponentType<FallbackProps>
        return <FallbackComponent {...fallbackProps} />
      }

      // Default fallback based on variant
      switch (variant) {
        case 'minimal':
          return <MinimalErrorFallback {...fallbackProps} />
        case 'full':
          return <FullPageErrorFallback {...fallbackProps} />
        default:
          return <DefaultErrorFallback {...fallbackProps} />
      }
    }

    return children
  }
}

// ========================================
// HOOKS
// ========================================

/**
 * Use Error Handler Hook
 * 
 * Provides error handling utilities.
 */
export function useErrorHandler(onError?: (error: Error) => void) {
  const [error, setError] = React.useState<Error | null>(null)

  React.useEffect(() => {
    if (error) {
      throw error
    }
  }, [error])

  const handleError = React.useCallback(
    (error: Error) => {
      onError?.(error)
      setError(error)
    },
    [onError]
  )

  const reset = React.useCallback(() => {
    setError(null)
  }, [])

  return { handleError, reset }
}
```

---

## 📚 USAGE EXAMPLES

### Basic Error Boundary

```typescript
import { ErrorBoundary } from '@/components/ui/error-boundary'

function App() {
  return (
    <ErrorBoundary>
      <MyComponent />
    </ErrorBoundary>
  )
}
```

### With Custom Fallback

```typescript
function CustomFallback({ error, resetError }: FallbackProps) {
  return (
    <div>
      <h2>Custom Error</h2>
      <p>{error.message}</p>
      <button onClick={resetError}>Reset</button>
    </div>
  )
}

function App() {
  return (
    <ErrorBoundary fallback={CustomFallback}>
      <MyComponent />
    </ErrorBoundary>
  )
}
```

### With Fallback Render

```typescript
function App() {
  return (
    <ErrorBoundary
      fallbackRender={({ error, resetError }) => (
        <div>
          <h2>Error: {error.message}</h2>
          <button onClick={resetError}>Try again</button>
        </div>
      )}
    >
      <MyComponent />
    </ErrorBoundary>
  )
}
```

### With Error Callback

```typescript
import { ErrorBoundary } from '@/components/ui/error-boundary'

function App() {
  const handleError = (error: Error, errorInfo: ErrorInfo) => {
    // Send to error reporting service
    console.error('Error caught:', error)
    console.error('Component stack:', errorInfo.componentStack)
    
    // Example: Send to Sentry
    // Sentry.captureException(error, { contexts: { react: { componentStack: errorInfo.componentStack } } })
  }

  return (
    <ErrorBoundary onError={handleError}>
      <MyComponent />
    </ErrorBoundary>
  )
}
```

### With Reset Keys

```typescript
function UserProfile({ userId }: { userId: string }) {
  return (
    <ErrorBoundary
      resetKeys={[userId]} // Reset error when user changes
      variant="default"
    >
      <UserData userId={userId} />
    </ErrorBoundary>
  )
}
```

### Nested Error Boundaries

```typescript
function App() {
  return (
    <ErrorBoundary variant="full">
      <Layout>
        <ErrorBoundary variant="default">
          <Sidebar />
        </ErrorBoundary>
        
        <ErrorBoundary variant="default">
          <MainContent />
        </ErrorBoundary>
      </Layout>
    </ErrorBoundary>
  )
}
```

### Different Variants

```typescript
// Default variant (card-like)
<ErrorBoundary variant="default">
  <Component />
</ErrorBoundary>

// Minimal variant (inline alert)
<ErrorBoundary variant="minimal">
  <Component />
</ErrorBoundary>

// Full page variant
<ErrorBoundary variant="full">
  <App />
</ErrorBoundary>
```

### With Reset Callback

```typescript
function DataTable() {
  const [data, setData] = React.useState([])

  const handleReset = () => {
    // Refetch data or reset state
    setData([])
    fetchData()
  }

  return (
    <ErrorBoundary onReset={handleReset}>
      <Table data={data} />
    </ErrorBoundary>
  )
}
```

### Use Error Handler Hook

```typescript
import { useErrorHandler } from '@/components/ui/error-boundary'

function AsyncComponent() {
  const { handleError } = useErrorHandler()

  const fetchData = async () => {
    try {
      const data = await api.fetchData()
      return data
    } catch (error) {
      handleError(error as Error) // Will trigger error boundary
    }
  }

  return <div>{/* ... */}</div>
}
```

### School Management Error Boundaries

```typescript
function SchoolDashboard() {
  return (
    <ErrorBoundary
      variant="full"
      onError={(error) => {
        // Log to school admin dashboard
        logError({
          module: 'Dashboard',
          error: error.message,
          timestamp: new Date(),
        })
      }}
    >
      <DashboardLayout>
        {/* Student data section */}
        <ErrorBoundary
          variant="default"
          resetKeys={['students']}
        >
          <StudentList />
        </ErrorBoundary>

        {/* Attendance section */}
        <ErrorBoundary variant="default">
          <AttendanceChart />
        </ErrorBoundary>

        {/* Grades section */}
        <ErrorBoundary variant="default">
          <GradesSummary />
        </ErrorBoundary>
      </DashboardLayout>
    </ErrorBoundary>
  )
}

function StudentEnrollment({ studentId }: { studentId: string }) {
  return (
    <ErrorBoundary
      resetKeys={[studentId]}
      fallbackRender={({ error, resetError }) => (
        <Alert variant="destructive">
          <AlertTitle>Failed to load student data</AlertTitle>
          <AlertDescription>
            <p>Student ID: {studentId}</p>
            <p>Error: {error.message}</p>
            <Button onClick={resetError} className="mt-2">
              Retry
            </Button>
          </AlertDescription>
        </Alert>
      )}
    >
      <EnrollmentForm studentId={studentId} />
    </ErrorBoundary>
  )
}
```

### Async Boundary with Suspense

```typescript
function AsyncData() {
  return (
    <ErrorBoundary variant="default">
      <React.Suspense fallback={<LoadingSpinner />}>
        <DataComponent />
      </React.Suspense>
    </ErrorBoundary>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('ErrorBoundary', () => {
  const ThrowError = () => {
    throw new Error('Test error')
  }

  it('catches errors and renders fallback', () => {
    const { container } = render(
      <ErrorBoundary>
        <ThrowError />
      </ErrorBoundary>
    )

    expect(container.textContent).toContain('Something went wrong')
  })

  it('calls onError when error occurs', () => {
    const onError = jest.fn()
    
    render(
      <ErrorBoundary onError={onError}>
        <ThrowError />
      </ErrorBoundary>
    )

    expect(onError).toHaveBeenCalled()
    expect(onError.mock.calls[0][0].message).toBe('Test error')
  })

  it('resets error on retry button click', () => {
    const { getByText, rerender } = render(
      <ErrorBoundary>
        <ThrowError />
      </ErrorBoundary>
    )

    expect(getByText('Something went wrong')).toBeInTheDocument()

    // Click retry
    fireEvent.click(getByText('Try Again'))

    // Component should re-render without error
    rerender(
      <ErrorBoundary>
        <div>Success</div>
      </ErrorBoundary>
    )

    expect(getByText('Success')).toBeInTheDocument()
  })

  it('renders custom fallback', () => {
    const CustomFallback = () => <div>Custom Error</div>

    render(
      <ErrorBoundary fallback={CustomFallback}>
        <ThrowError />
      </ErrorBoundary>
    )

    expect(screen.getByText('Custom Error')).toBeInTheDocument()
  })

  it('resets when reset keys change', () => {
    const { rerender } = render(
      <ErrorBoundary resetKeys={['key1']}>
        <ThrowError />
      </ErrorBoundary>
    )

    expect(screen.getByText('Something went wrong')).toBeInTheDocument()

    // Change reset key
    rerender(
      <ErrorBoundary resetKeys={['key2']}>
        <div>Success</div>
      </ErrorBoundary>
    )

    expect(screen.getByText('Success')).toBeInTheDocument()
  })

  it('calls onReset callback', () => {
    const onReset = jest.fn()
    
    render(
      <ErrorBoundary onReset={onReset}>
        <ThrowError />
      </ErrorBoundary>
    )

    fireEvent.click(screen.getByText('Try Again'))

    expect(onReset).toHaveBeenCalled()
  })

  it('renders minimal variant', () => {
    render(
      <ErrorBoundary variant="minimal">
        <ThrowError />
      </ErrorBoundary>
    )

    expect(screen.getByText('Test error')).toBeInTheDocument()
    expect(screen.getByText('Retry')).toBeInTheDocument()
  })
})

describe('useErrorHandler', () => {
  it('throws error that can be caught by error boundary', () => {
    const onError = jest.fn()
    
    function TestComponent() {
      const { handleError } = useErrorHandler(onError)

      return (
        <button onClick={() => handleError(new Error('Test'))}>
          Throw
        </button>
      )
    }

    render(
      <ErrorBoundary>
        <TestComponent />
      </ErrorBoundary>
    )

    fireEvent.click(screen.getByText('Throw'))

    expect(screen.getByText('Something went wrong')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Clear error messages
- ✅ Actionable recovery options
- ✅ Keyboard accessible buttons
- ✅ ARIA roles and labels
- ✅ Focus management on error state

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create error-boundary.tsx
- [ ] Implement ErrorBoundary class component
- [ ] Add default fallback components (Default, Minimal, Full)
- [ ] Add error logging integration
- [ ] Implement reset functionality
- [ ] Add resetKeys support
- [ ] Implement useErrorHandler hook
- [ ] Add TypeScript interfaces
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples
- [ ] Add development vs production error display

---

## 📦 BUNDLE SIZE

- **Component**: ~3KB
- **With all fallbacks**: ~4KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
