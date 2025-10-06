# SPEC-092: Progress Component
## Progress Indicators and Loading States

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: Radix UI Progress

---

## 📋 OVERVIEW

### Purpose
A progress component for displaying task completion, loading states, and determinate/indeterminate progress with both linear and circular variants.

### Key Features
- ✅ Linear and circular variants
- ✅ Determinate and indeterminate modes
- ✅ Radix UI integration for accessibility
- ✅ Multiple sizes
- ✅ Color variants
- ✅ Label and percentage display
- ✅ Animated transitions
- ✅ Custom styling

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/progress.tsx
import * as React from 'react'
import * as ProgressPrimitive from '@radix-ui/react-progress'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

const progressVariants = cva('', {
  variants: {
    variant: {
      default: '[&>div]:bg-primary',
      secondary: '[&>div]:bg-secondary',
      success: '[&>div]:bg-green-500',
      warning: '[&>div]:bg-yellow-500',
      danger: '[&>div]:bg-red-500',
      info: '[&>div]:bg-blue-500',
    },
    size: {
      sm: 'h-1',
      md: 'h-2',
      lg: 'h-3',
    },
  },
  defaultVariants: {
    variant: 'default',
    size: 'md',
  },
})

export interface ProgressProps
  extends React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root>,
    VariantProps<typeof progressVariants> {
  /**
   * Progress value (0-100)
   */
  value?: number

  /**
   * Show percentage label
   */
  showValue?: boolean

  /**
   * Indeterminate mode (animated)
   */
  indeterminate?: boolean
}

// ========================================
// LINEAR PROGRESS
// ========================================

const Progress = React.forwardRef<
  React.ElementRef<typeof ProgressPrimitive.Root>,
  ProgressProps
>(({ className, value = 0, variant, size, showValue, indeterminate, ...props }, ref) => {
  const clampedValue = Math.min(100, Math.max(0, value))

  return (
    <div className="space-y-2">
      {showValue && (
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">Progress</span>
          <span className="font-medium">{Math.round(clampedValue)}%</span>
        </div>
      )}
      <ProgressPrimitive.Root
        ref={ref}
        className={cn(
          'relative overflow-hidden rounded-full bg-secondary',
          progressVariants({ variant, size }),
          className
        )}
        value={indeterminate ? undefined : clampedValue}
        {...props}
      >
        <ProgressPrimitive.Indicator
          className={cn(
            'h-full w-full flex-1 transition-all',
            indeterminate && 'animate-progress-indeterminate'
          )}
          style={{
            transform: indeterminate
              ? 'translateX(-100%)'
              : `translateX(-${100 - clampedValue}%)`,
          }}
        />
      </ProgressPrimitive.Root>
    </div>
  )
})
Progress.displayName = ProgressPrimitive.Root.displayName

// ========================================
// CIRCULAR PROGRESS
// ========================================

export interface CircularProgressProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof progressVariants> {
  /**
   * Progress value (0-100)
   */
  value?: number

  /**
   * Size in pixels
   */
  size?: number

  /**
   * Stroke width
   */
  strokeWidth?: number

  /**
   * Show percentage label
   */
  showValue?: boolean

  /**
   * Indeterminate mode
   */
  indeterminate?: boolean
}

const CircularProgress = React.forwardRef<HTMLDivElement, CircularProgressProps>(
  (
    {
      className,
      value = 0,
      variant = 'default',
      size = 64,
      strokeWidth = 4,
      showValue = true,
      indeterminate = false,
      ...props
    },
    ref
  ) => {
    const clampedValue = Math.min(100, Math.max(0, value))
    const radius = (size - strokeWidth) / 2
    const circumference = 2 * Math.PI * radius
    const offset = circumference - (clampedValue / 100) * circumference

    const colorMap = {
      default: 'stroke-primary',
      secondary: 'stroke-secondary',
      success: 'stroke-green-500',
      warning: 'stroke-yellow-500',
      danger: 'stroke-red-500',
      info: 'stroke-blue-500',
    }

    return (
      <div
        ref={ref}
        className={cn('relative inline-flex items-center justify-center', className)}
        style={{ width: size, height: size }}
        {...props}
      >
        <svg
          width={size}
          height={size}
          className={cn(indeterminate && 'animate-spin')}
        >
          {/* Background circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            className="text-muted"
          />
          
          {/* Progress circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="none"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            className={cn(
              'transition-all duration-300',
              colorMap[variant || 'default']
            )}
            style={{
              strokeDasharray: circumference,
              strokeDashoffset: indeterminate ? circumference * 0.75 : offset,
              transform: 'rotate(-90deg)',
              transformOrigin: '50% 50%',
            }}
          />
        </svg>
        
        {showValue && !indeterminate && (
          <span className="absolute text-sm font-semibold">
            {Math.round(clampedValue)}%
          </span>
        )}
      </div>
    )
  }
)
CircularProgress.displayName = 'CircularProgress'

// ========================================
// PROGRESS WITH LABEL
// ========================================

export interface ProgressWithLabelProps extends ProgressProps {
  /**
   * Label text
   */
  label?: string

  /**
   * Helper text
   */
  helperText?: string
}

const ProgressWithLabel = React.forwardRef<
  React.ElementRef<typeof ProgressPrimitive.Root>,
  ProgressWithLabelProps
>(({ label, helperText, showValue = true, ...props }, ref) => {
  return (
    <div className="space-y-2">
      {label && (
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium">{label}</span>
          {showValue && (
            <span className="text-sm text-muted-foreground">
              {Math.round(props.value || 0)}%
            </span>
          )}
        </div>
      )}
      <Progress ref={ref} {...props} showValue={false} />
      {helperText && (
        <p className="text-xs text-muted-foreground">{helperText}</p>
      )}
    </div>
  )
})
ProgressWithLabel.displayName = 'ProgressWithLabel'

// ========================================
// STACKED PROGRESS
// ========================================

export interface StackedProgressItem {
  value: number
  color?: string
  label?: string
}

export interface StackedProgressProps extends React.HTMLAttributes<HTMLDivElement> {
  items: StackedProgressItem[]
  size?: 'sm' | 'md' | 'lg'
  showLabels?: boolean
}

const StackedProgress = React.forwardRef<HTMLDivElement, StackedProgressProps>(
  ({ className, items, size = 'md', showLabels = true, ...props }, ref) => {
    const total = items.reduce((sum, item) => sum + item.value, 0)

    const sizeClasses = {
      sm: 'h-1',
      md: 'h-2',
      lg: 'h-3',
    }

    const defaultColors = [
      'bg-blue-500',
      'bg-green-500',
      'bg-yellow-500',
      'bg-red-500',
      'bg-purple-500',
      'bg-pink-500',
    ]

    return (
      <div ref={ref} className={cn('space-y-2', className)} {...props}>
        {showLabels && (
          <div className="flex gap-4 text-xs">
            {items.map((item, index) => (
              <div key={index} className="flex items-center gap-2">
                <div
                  className={cn(
                    'h-2 w-2 rounded-full',
                    item.color || defaultColors[index % defaultColors.length]
                  )}
                />
                <span className="text-muted-foreground">
                  {item.label}: {Math.round((item.value / total) * 100)}%
                </span>
              </div>
            ))}
          </div>
        )}
        
        <div className={cn('flex overflow-hidden rounded-full', sizeClasses[size])}>
          {items.map((item, index) => {
            const percentage = (item.value / total) * 100
            return (
              <div
                key={index}
                className={cn(
                  'transition-all',
                  item.color || defaultColors[index % defaultColors.length]
                )}
                style={{ width: `${percentage}%` }}
              />
            )
          })}
        </div>
      </div>
    )
  }
)
StackedProgress.displayName = 'StackedProgress'

export { Progress, CircularProgress, ProgressWithLabel, StackedProgress, progressVariants }
```

### Animations

```typescript
// Add to tailwind.config.ts
module.exports = {
  theme: {
    extend: {
      keyframes: {
        'progress-indeterminate': {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(200%)' },
        },
      },
      animation: {
        'progress-indeterminate': 'progress-indeterminate 1.5s ease-in-out infinite',
      },
    },
  },
}
```

---

## 📚 USAGE EXAMPLES

### Basic Progress

```typescript
import { Progress } from '@/components/ui/progress'

function BasicProgress() {
  const [progress, setProgress] = React.useState(0)

  React.useEffect(() => {
    const timer = setInterval(() => {
      setProgress((prev) => (prev >= 100 ? 0 : prev + 10))
    }, 500)
    return () => clearInterval(timer)
  }, [])

  return <Progress value={progress} showValue />
}
```

### Different Variants

```typescript
function ProgressVariants() {
  return (
    <div className="space-y-4">
      <Progress value={75} variant="default" showValue />
      <Progress value={60} variant="success" showValue />
      <Progress value={45} variant="warning" showValue />
      <Progress value={30} variant="danger" showValue />
      <Progress value={90} variant="info" showValue />
    </div>
  )
}
```

### Different Sizes

```typescript
function ProgressSizes() {
  return (
    <div className="space-y-4">
      <Progress value={75} size="sm" />
      <Progress value={75} size="md" />
      <Progress value={75} size="lg" />
    </div>
  )
}
```

### Indeterminate Progress

```typescript
function IndeterminateProgress() {
  return (
    <div className="space-y-4">
      <Progress indeterminate />
      <Progress indeterminate variant="success" />
    </div>
  )
}
```

### Progress With Label

```typescript
import { ProgressWithLabel } from '@/components/ui/progress'

function LabeledProgress() {
  return (
    <div className="space-y-4">
      <ProgressWithLabel
        value={45}
        label="Upload Progress"
        helperText="Uploading file.pdf (4.5 MB / 10 MB)"
      />
      
      <ProgressWithLabel
        value={75}
        label="Installation"
        helperText="Installing dependencies..."
        variant="success"
      />
    </div>
  )
}
```

### Circular Progress

```typescript
import { CircularProgress } from '@/components/ui/progress'

function CircularProgressExample() {
  return (
    <div className="flex gap-8">
      <CircularProgress value={75} />
      <CircularProgress value={50} variant="success" size={80} />
      <CircularProgress value={25} variant="warning" size={48} />
      <CircularProgress indeterminate variant="info" />
    </div>
  )
}
```

### File Upload Progress

```typescript
function FileUploadProgress() {
  const [progress, setProgress] = React.useState(0)
  const [uploading, setUploading] = React.useState(false)

  const handleUpload = () => {
    setUploading(true)
    setProgress(0)

    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval)
          setUploading(false)
          return 100
        }
        return prev + 10
      })
    }, 300)
  }

  return (
    <div className="space-y-4">
      <ProgressWithLabel
        value={progress}
        label="Uploading document.pdf"
        helperText={
          uploading
            ? `${Math.round(progress)}% complete`
            : progress === 100
            ? 'Upload complete!'
            : 'Ready to upload'
        }
        variant={
          progress === 100 ? 'success' : uploading ? 'default' : 'secondary'
        }
      />
      
      <Button onClick={handleUpload} disabled={uploading}>
        {uploading ? 'Uploading...' : 'Start Upload'}
      </Button>
    </div>
  )
}
```

### Stacked Progress

```typescript
import { StackedProgress } from '@/components/ui/progress'

function StackedProgressExample() {
  const diskUsage = [
    { label: 'Documents', value: 25, color: 'bg-blue-500' },
    { label: 'Photos', value: 35, color: 'bg-green-500' },
    { label: 'Videos', value: 20, color: 'bg-yellow-500' },
    { label: 'Other', value: 10, color: 'bg-red-500' },
  ]

  return (
    <div className="space-y-2">
      <h3 className="text-sm font-medium">Disk Usage (90 GB / 100 GB)</h3>
      <StackedProgress items={diskUsage} />
    </div>
  )
}
```

### Multi-Step Form Progress

```typescript
function MultiStepProgress() {
  const [step, setStep] = React.useState(1)
  const totalSteps = 4
  const progress = (step / totalSteps) * 100

  return (
    <div className="space-y-4">
      <ProgressWithLabel
        value={progress}
        label={`Step ${step} of ${totalSteps}`}
        variant={step === totalSteps ? 'success' : 'default'}
      />
      
      <div className="flex gap-2">
        <Button
          onClick={() => setStep(Math.max(1, step - 1))}
          disabled={step === 1}
        >
          Previous
        </Button>
        <Button
          onClick={() => setStep(Math.min(totalSteps, step + 1))}
          disabled={step === totalSteps}
        >
          Next
        </Button>
      </div>
    </div>
  )
}
```

### Task Progress with Status

```typescript
function TaskProgress() {
  const tasks = [
    { name: 'Database Setup', progress: 100, status: 'complete' },
    { name: 'API Configuration', progress: 75, status: 'in-progress' },
    { name: 'Frontend Build', progress: 30, status: 'in-progress' },
    { name: 'Testing', progress: 0, status: 'pending' },
  ]

  const getVariant = (status: string) => {
    switch (status) {
      case 'complete': return 'success'
      case 'in-progress': return 'default'
      case 'pending': return 'secondary'
      default: return 'default'
    }
  }

  return (
    <div className="space-y-6">
      {tasks.map((task) => (
        <ProgressWithLabel
          key={task.name}
          value={task.progress}
          label={task.name}
          variant={getVariant(task.status)}
          helperText={
            task.status === 'complete'
              ? 'Complete'
              : task.status === 'in-progress'
              ? 'In Progress'
              : 'Pending'
          }
        />
      ))}
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Progress', () => {
  it('renders with correct value', () => {
    render(<Progress value={50} />)
    const progress = screen.getByRole('progressbar')
    expect(progress).toHaveAttribute('aria-valuenow', '50')
  })

  it('clamps value between 0 and 100', () => {
    const { rerender } = render(<Progress value={150} />)
    let progress = screen.getByRole('progressbar')
    expect(progress).toHaveAttribute('aria-valuenow', '100')

    rerender(<Progress value={-50} />)
    progress = screen.getByRole('progressbar')
    expect(progress).toHaveAttribute('aria-valuenow', '0')
  })

  it('shows percentage when showValue is true', () => {
    render(<Progress value={75} showValue />)
    expect(screen.getByText('75%')).toBeInTheDocument()
  })

  it('renders indeterminate progress', () => {
    render(<Progress indeterminate />)
    const indicator = screen.getByRole('progressbar').querySelector('div')
    expect(indicator).toHaveClass('animate-progress-indeterminate')
  })
})

describe('CircularProgress', () => {
  it('renders circular progress', () => {
    render(<CircularProgress value={50} />)
    expect(screen.getByText('50%')).toBeInTheDocument()
  })

  it('applies correct variant', () => {
    render(<CircularProgress value={50} variant="success" />)
    const circle = document.querySelector('.stroke-green-500')
    expect(circle).toBeInTheDocument()
  })

  it('hides value when showValue is false', () => {
    render(<CircularProgress value={50} showValue={false} />)
    expect(screen.queryByText('50%')).not.toBeInTheDocument()
  })
})

describe('StackedProgress', () => {
  const items = [
    { label: 'A', value: 30 },
    { label: 'B', value: 50 },
    { label: 'C', value: 20 },
  ]

  it('renders all items', () => {
    render(<StackedProgress items={items} />)
    expect(screen.getByText(/A:/)).toBeInTheDocument()
    expect(screen.getByText(/B:/)).toBeInTheDocument()
    expect(screen.getByText(/C:/)).toBeInTheDocument()
  })

  it('calculates percentages correctly', () => {
    render(<StackedProgress items={items} />)
    expect(screen.getByText(/A: 30%/)).toBeInTheDocument()
    expect(screen.getByText(/B: 50%/)).toBeInTheDocument()
    expect(screen.getByText(/C: 20%/)).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ ARIA progressbar role
- ✅ aria-valuenow, aria-valuemin, aria-valuemax
- ✅ aria-label for context
- ✅ Screen reader announcements
- ✅ Color is not the only indicator

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Radix UI Progress: `npm install @radix-ui/react-progress`
- [ ] Create progress.tsx
- [ ] Implement linear progress with variants
- [ ] Implement circular progress
- [ ] Add indeterminate animation
- [ ] Create ProgressWithLabel component
- [ ] Create StackedProgress component
- [ ] Add animations to Tailwind config
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With Radix UI**: ~3.5KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
