# SPEC-093: Skeleton Component
## Loading Placeholders

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: None (Pure CSS)

---

## 📋 OVERVIEW

### Purpose
A skeleton component for displaying loading placeholders that match the shape of content being loaded, improving perceived performance.

### Key Features
- ✅ Basic skeleton shapes (text, circle, rectangle)
- ✅ Preset layouts (card, list, table, profile)
- ✅ Animated pulse effect
- ✅ Customizable dimensions
- ✅ Composition support
- ✅ Responsive design
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/skeleton.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

const skeletonVariants = cva('animate-pulse rounded-md bg-muted', {
  variants: {
    variant: {
      default: '',
      text: 'h-4',
      circle: 'rounded-full',
      rectangle: 'rounded-md',
    },
  },
  defaultVariants: {
    variant: 'default',
  },
})

export interface SkeletonProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof skeletonVariants> {
  /**
   * Width (CSS value)
   */
  width?: string | number

  /**
   * Height (CSS value)
   */
  height?: string | number

  /**
   * Disable animation
   */
  noAnimation?: boolean
}

// ========================================
// SKELETON COMPONENT
// ========================================

const Skeleton = React.forwardRef<HTMLDivElement, SkeletonProps>(
  ({ className, variant, width, height, noAnimation, style, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          skeletonVariants({ variant }),
          noAnimation && 'animate-none',
          className
        )}
        style={{
          width,
          height,
          ...style,
        }}
        {...props}
      />
    )
  }
)
Skeleton.displayName = 'Skeleton'

// ========================================
// SKELETON TEXT
// ========================================

export interface SkeletonTextProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Number of lines
   */
  lines?: number

  /**
   * Width of last line (percentage)
   */
  lastLineWidth?: number

  /**
   * Spacing between lines
   */
  spacing?: 'sm' | 'md' | 'lg'
}

const SkeletonText = React.forwardRef<HTMLDivElement, SkeletonTextProps>(
  ({ className, lines = 3, lastLineWidth = 60, spacing = 'md', ...props }, ref) => {
    const spacingClasses = {
      sm: 'space-y-2',
      md: 'space-y-3',
      lg: 'space-y-4',
    }

    return (
      <div ref={ref} className={cn(spacingClasses[spacing], className)} {...props}>
        {Array.from({ length: lines }).map((_, index) => (
          <Skeleton
            key={index}
            variant="text"
            width={index === lines - 1 ? `${lastLineWidth}%` : '100%'}
          />
        ))}
      </div>
    )
  }
)
SkeletonText.displayName = 'SkeletonText'

// ========================================
// SKELETON CARD
// ========================================

export interface SkeletonCardProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Show avatar
   */
  avatar?: boolean

  /**
   * Show image
   */
  image?: boolean

  /**
   * Number of text lines
   */
  lines?: number
}

const SkeletonCard = React.forwardRef<HTMLDivElement, SkeletonCardProps>(
  ({ className, avatar = false, image = true, lines = 3, ...props }, ref) => {
    return (
      <div ref={ref} className={cn('space-y-4', className)} {...props}>
        {image && <Skeleton height={200} />}
        <div className="space-y-3">
          {avatar && (
            <div className="flex items-center space-x-3">
              <Skeleton variant="circle" width={40} height={40} />
              <div className="flex-1 space-y-2">
                <Skeleton variant="text" width="60%" />
                <Skeleton variant="text" width="40%" />
              </div>
            </div>
          )}
          <SkeletonText lines={lines} />
        </div>
      </div>
    )
  }
)
SkeletonCard.displayName = 'SkeletonCard'

// ========================================
// SKELETON LIST
// ========================================

export interface SkeletonListProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Number of items
   */
  items?: number

  /**
   * Show avatar
   */
  avatar?: boolean

  /**
   * Number of text lines per item
   */
  lines?: number
}

const SkeletonList = React.forwardRef<HTMLDivElement, SkeletonListProps>(
  ({ className, items = 3, avatar = true, lines = 2, ...props }, ref) => {
    return (
      <div ref={ref} className={cn('space-y-4', className)} {...props}>
        {Array.from({ length: items }).map((_, index) => (
          <div key={index} className="flex items-start space-x-3">
            {avatar && <Skeleton variant="circle" width={40} height={40} />}
            <div className="flex-1 space-y-2">
              <SkeletonText lines={lines} />
            </div>
          </div>
        ))}
      </div>
    )
  }
)
SkeletonList.displayName = 'SkeletonList'

// ========================================
// SKELETON TABLE
// ========================================

export interface SkeletonTableProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Number of rows
   */
  rows?: number

  /**
   * Number of columns
   */
  columns?: number

  /**
   * Show header
   */
  header?: boolean
}

const SkeletonTable = React.forwardRef<HTMLDivElement, SkeletonTableProps>(
  ({ className, rows = 5, columns = 4, header = true, ...props }, ref) => {
    return (
      <div ref={ref} className={cn('space-y-3', className)} {...props}>
        {header && (
          <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}>
            {Array.from({ length: columns }).map((_, index) => (
              <Skeleton key={index} height={20} />
            ))}
          </div>
        )}
        <div className="space-y-3">
          {Array.from({ length: rows }).map((_, rowIndex) => (
            <div
              key={rowIndex}
              className="grid gap-4"
              style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}
            >
              {Array.from({ length: columns }).map((_, colIndex) => (
                <Skeleton key={colIndex} height={16} />
              ))}
            </div>
          ))}
        </div>
      </div>
    )
  }
)
SkeletonTable.displayName = 'SkeletonTable'

// ========================================
// SKELETON PROFILE
// ========================================

export interface SkeletonProfileProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Avatar size
   */
  avatarSize?: number

  /**
   * Show cover image
   */
  coverImage?: boolean
}

const SkeletonProfile = React.forwardRef<HTMLDivElement, SkeletonProfileProps>(
  ({ className, avatarSize = 80, coverImage = true, ...props }, ref) => {
    return (
      <div ref={ref} className={cn('space-y-4', className)} {...props}>
        {coverImage && <Skeleton height={200} />}
        <div className="flex flex-col items-center space-y-4 -mt-10">
          <Skeleton
            variant="circle"
            width={avatarSize}
            height={avatarSize}
            className="ring-4 ring-background"
          />
          <div className="space-y-2 text-center w-full max-w-sm">
            <Skeleton height={24} width="60%" className="mx-auto" />
            <Skeleton height={16} width="40%" className="mx-auto" />
          </div>
          <div className="flex gap-4 w-full max-w-sm">
            <Skeleton height={36} className="flex-1" />
            <Skeleton height={36} className="flex-1" />
          </div>
        </div>
      </div>
    )
  }
)
SkeletonProfile.displayName = 'SkeletonProfile'

// ========================================
// SKELETON FORM
// ========================================

export interface SkeletonFormProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Number of fields
   */
  fields?: number
}

const SkeletonForm = React.forwardRef<HTMLDivElement, SkeletonFormProps>(
  ({ className, fields = 4, ...props }, ref) => {
    return (
      <div ref={ref} className={cn('space-y-6', className)} {...props}>
        {Array.from({ length: fields }).map((_, index) => (
          <div key={index} className="space-y-2">
            <Skeleton height={20} width="30%" />
            <Skeleton height={40} />
          </div>
        ))}
        <div className="flex gap-3 pt-2">
          <Skeleton height={40} width={100} />
          <Skeleton height={40} width={100} />
        </div>
      </div>
    )
  }
)
SkeletonForm.displayName = 'SkeletonForm'

export {
  Skeleton,
  SkeletonText,
  SkeletonCard,
  SkeletonList,
  SkeletonTable,
  SkeletonProfile,
  SkeletonForm,
  skeletonVariants,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Skeleton

```typescript
import { Skeleton } from '@/components/ui/skeleton'

function BasicSkeleton() {
  return (
    <div className="space-y-4">
      <Skeleton width={200} height={20} />
      <Skeleton width="100%" height={40} />
      <Skeleton variant="circle" width={60} height={60} />
    </div>
  )
}
```

### Skeleton Text

```typescript
import { SkeletonText } from '@/components/ui/skeleton'

function TextSkeleton() {
  return (
    <div className="space-y-6">
      <SkeletonText lines={3} />
      <SkeletonText lines={2} lastLineWidth={40} />
    </div>
  )
}
```

### Card Skeleton

```typescript
import { SkeletonCard } from '@/components/ui/skeleton'

function CardSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      <SkeletonCard />
      <SkeletonCard avatar />
      <SkeletonCard image={false} lines={4} />
    </div>
  )
}
```

### List Skeleton

```typescript
import { SkeletonList } from '@/components/ui/skeleton'

function ListSkeleton() {
  return <SkeletonList items={5} avatar lines={2} />
}
```

### Table Skeleton

```typescript
import { SkeletonTable } from '@/components/ui/skeleton'

function TableSkeleton() {
  return <SkeletonTable rows={10} columns={5} header />
}
```

### Profile Skeleton

```typescript
import { SkeletonProfile } from '@/components/ui/skeleton'

function ProfileSkeleton() {
  return <SkeletonProfile coverImage avatarSize={100} />
}
```

### Form Skeleton

```typescript
import { SkeletonForm } from '@/components/ui/skeleton'

function FormSkeleton() {
  return <SkeletonForm fields={6} />
}
```

### Custom Composite Skeleton

```typescript
function BlogPostSkeleton() {
  return (
    <article className="space-y-6">
      {/* Header */}
      <div className="space-y-3">
        <Skeleton height={40} width="80%" />
        <div className="flex items-center gap-3">
          <Skeleton variant="circle" width={40} height={40} />
          <div className="space-y-2">
            <Skeleton height={16} width={120} />
            <Skeleton height={14} width={80} />
          </div>
        </div>
      </div>

      {/* Featured Image */}
      <Skeleton height={400} />

      {/* Content */}
      <SkeletonText lines={8} />

      {/* Tags */}
      <div className="flex gap-2">
        <Skeleton height={24} width={60} />
        <Skeleton height={24} width={80} />
        <Skeleton height={24} width={70} />
      </div>
    </article>
  )
}
```

### Loading State Hook

```typescript
function useSkeletonState(loading: boolean, skeleton: React.ReactNode) {
  return loading ? skeleton : null
}

function UserProfile({ userId }: { userId: string }) {
  const { data, isLoading } = useQuery(['user', userId], fetchUser)

  const skeleton = useSkeletonState(
    isLoading,
    <SkeletonProfile coverImage avatarSize={80} />
  )

  if (skeleton) return skeleton

  return <div>{/* Actual profile content */}</div>
}
```

### Conditional Skeleton

```typescript
function ConditionalSkeleton() {
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    setTimeout(() => setLoading(false), 2000)
  }, [])

  if (loading) {
    return (
      <div className="space-y-4">
        <SkeletonCard />
        <SkeletonList items={3} />
      </div>
    )
  }

  return <div>Loaded content</div>
}
```

### Grid Skeleton

```typescript
function GridSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {Array.from({ length: 6 }).map((_, i) => (
        <SkeletonCard key={i} />
      ))}
    </div>
  )
}
```

### Without Animation

```typescript
function StaticSkeleton() {
  return (
    <div className="space-y-4">
      <Skeleton width={200} height={20} noAnimation />
      <Skeleton width="100%" height={40} noAnimation />
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Skeleton', () => {
  it('renders with default styles', () => {
    render(<Skeleton />)
    const skeleton = screen.getByRole('generic')
    expect(skeleton).toHaveClass('animate-pulse', 'bg-muted')
  })

  it('applies custom width and height', () => {
    render(<Skeleton width={200} height={100} />)
    const skeleton = screen.getByRole('generic')
    expect(skeleton).toHaveStyle({ width: '200px', height: '100px' })
  })

  it('disables animation when noAnimation is true', () => {
    render(<Skeleton noAnimation />)
    const skeleton = screen.getByRole('generic')
    expect(skeleton).not.toHaveClass('animate-pulse')
  })

  it('applies variant classes', () => {
    const { rerender } = render(<Skeleton variant="circle" />)
    expect(screen.getByRole('generic')).toHaveClass('rounded-full')

    rerender(<Skeleton variant="text" />)
    expect(screen.getByRole('generic')).toHaveClass('h-4')
  })
})

describe('SkeletonText', () => {
  it('renders correct number of lines', () => {
    render(<SkeletonText lines={5} />)
    const lines = screen.getAllByRole('generic')
    expect(lines).toHaveLength(5)
  })

  it('applies lastLineWidth to last line', () => {
    render(<SkeletonText lines={3} lastLineWidth={50} />)
    const lines = screen.getAllByRole('generic')
    const lastLine = lines[lines.length - 1]
    expect(lastLine).toHaveStyle({ width: '50%' })
  })
})

describe('SkeletonCard', () => {
  it('renders with image by default', () => {
    render(<SkeletonCard />)
    const skeletons = screen.getAllByRole('generic')
    expect(skeletons.length).toBeGreaterThan(0)
  })

  it('shows avatar when avatar prop is true', () => {
    render(<SkeletonCard avatar />)
    const circleSkeletons = document.querySelectorAll('.rounded-full')
    expect(circleSkeletons.length).toBeGreaterThan(0)
  })

  it('hides image when image prop is false', () => {
    const { container } = render(<SkeletonCard image={false} />)
    // The first skeleton should not have a fixed height of 200
    const firstSkeleton = container.querySelector('[style*="height"]')
    expect(firstSkeleton).not.toHaveStyle({ height: '200px' })
  })
})

describe('SkeletonList', () => {
  it('renders correct number of items', () => {
    render(<SkeletonList items={5} />)
    const items = document.querySelectorAll('.flex.items-start')
    expect(items).toHaveLength(5)
  })

  it('shows avatars when avatar prop is true', () => {
    render(<SkeletonList items={3} avatar />)
    const avatars = document.querySelectorAll('.rounded-full')
    expect(avatars).toHaveLength(3)
  })
})

describe('SkeletonTable', () => {
  it('renders correct number of rows and columns', () => {
    render(<SkeletonTable rows={3} columns={4} header />)
    // Header row + 3 data rows
    const rows = document.querySelectorAll('[style*="grid-template-columns"]')
    expect(rows).toHaveLength(4) // 1 header + 3 rows
  })

  it('hides header when header prop is false', () => {
    const { container } = render(<SkeletonTable rows={3} columns={4} header={false} />)
    const rows = container.querySelectorAll('[style*="grid-template-columns"]')
    expect(rows).toHaveLength(3) // Only data rows
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Uses `aria-busy="true"` on loading containers
- ✅ Screen reader announcements for loading state
- ✅ Semantic HTML structure
- ✅ No reliance on animation for information

```typescript
// Accessible loading wrapper
function LoadingWrapper({
  loading,
  skeleton,
  children,
}: {
  loading: boolean
  skeleton: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <div aria-busy={loading} aria-live="polite">
      {loading ? skeleton : children}
    </div>
  )
}
```

---

## 🎨 STYLING NOTES

### Pulse Animation
```css
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
```

### Custom Colors
```css
/* Override skeleton background */
.skeleton-custom {
  --skeleton-color: hsl(var(--muted));
}
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create skeleton.tsx
- [ ] Implement base Skeleton component
- [ ] Create SkeletonText component
- [ ] Create SkeletonCard component
- [ ] Create SkeletonList component
- [ ] Create SkeletonTable component
- [ ] Create SkeletonProfile component
- [ ] Create SkeletonForm component
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~1KB
- **No external dependencies**: Pure CSS
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
