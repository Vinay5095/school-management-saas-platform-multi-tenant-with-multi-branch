# SPEC-088: Badge Component
## Status and Label Indicators

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: CVA (Class Variance Authority)

---

## 📋 OVERVIEW

### Purpose
A badge component for displaying status indicators, labels, counts, and tags with multiple variants and sizes.

### Key Features
- ✅ Multiple variants (default, success, warning, danger, info)
- ✅ Different sizes (sm, md, lg)
- ✅ Dot indicator option
- ✅ Removable badges
- ✅ Icon support
- ✅ Pill and rounded variants
- ✅ Interactive states
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/badge.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

const badgeVariants = cva(
  'inline-flex items-center rounded-full border font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
  {
    variants: {
      variant: {
        default: 'border-transparent bg-primary text-primary-foreground hover:bg-primary/80',
        secondary: 'border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80',
        destructive: 'border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80',
        outline: 'text-foreground border-border',
        success: 'border-transparent bg-green-500 text-white hover:bg-green-600',
        warning: 'border-transparent bg-yellow-500 text-white hover:bg-yellow-600',
        info: 'border-transparent bg-blue-500 text-white hover:bg-blue-600',
      },
      size: {
        sm: 'px-2 py-0 text-[10px]',
        md: 'px-2.5 py-0.5 text-xs',
        lg: 'px-3 py-1 text-sm',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  /**
   * Show dot indicator
   */
  dot?: boolean

  /**
   * Icon component (leading)
   */
  icon?: React.ReactNode

  /**
   * Removable badge
   */
  removable?: boolean

  /**
   * Remove callback
   */
  onRemove?: () => void

  /**
   * Pill shape (fully rounded)
   */
  pill?: boolean
}

// ========================================
// BADGE COMPONENT
// ========================================

/**
 * Badge Component
 * 
 * Display status indicators and labels.
 * 
 * @example
 * <Badge>Default</Badge>
 * <Badge variant="success">Success</Badge>
 * <Badge variant="warning" dot>Warning</Badge>
 */
const Badge = React.forwardRef<HTMLDivElement, BadgeProps>(
  ({ 
    className, 
    variant, 
    size, 
    dot, 
    icon, 
    removable, 
    onRemove, 
    pill,
    children, 
    ...props 
  }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          badgeVariants({ variant, size }),
          pill && 'rounded-full',
          removable && 'pr-1',
          className
        )}
        {...props}
      >
        {dot && (
          <span className="mr-1.5 h-1.5 w-1.5 rounded-full bg-current" />
        )}
        {icon && (
          <span className="mr-1.5">{icon}</span>
        )}
        {children}
        {removable && (
          <button
            onClick={(e) => {
              e.stopPropagation()
              onRemove?.()
            }}
            className="ml-1.5 rounded-full hover:bg-black/10 p-0.5 transition-colors"
            aria-label="Remove"
          >
            <X className="h-3 w-3" />
          </button>
        )}
      </div>
    )
  }
)
Badge.displayName = 'Badge'

// ========================================
// BADGE GROUP
// ========================================

export interface BadgeGroupProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Maximum badges to show
   */
  max?: number

  /**
   * Spacing between badges
   */
  spacing?: 'sm' | 'md' | 'lg'
}

/**
 * Badge Group Component
 * 
 * Group multiple badges with overflow handling.
 */
const BadgeGroup = React.forwardRef<HTMLDivElement, BadgeGroupProps>(
  ({ className, max, spacing = 'md', children, ...props }, ref) => {
    const spacingClasses = {
      sm: 'gap-1',
      md: 'gap-2',
      lg: 'gap-3',
    }

    const badges = React.Children.toArray(children)
    const visibleBadges = max ? badges.slice(0, max) : badges
    const hiddenCount = max ? badges.length - max : 0

    return (
      <div
        ref={ref}
        className={cn('flex flex-wrap items-center', spacingClasses[spacing], className)}
        {...props}
      >
        {visibleBadges}
        {hiddenCount > 0 && (
          <Badge variant="secondary" size="sm">
            +{hiddenCount}
          </Badge>
        )}
      </div>
    )
  }
)
BadgeGroup.displayName = 'BadgeGroup'

export { Badge, badgeVariants, BadgeGroup }
```

---

## 📚 USAGE EXAMPLES

### Basic Badges

```typescript
import { Badge } from '@/components/ui/badge'

function BasicBadges() {
  return (
    <div className="flex gap-2">
      <Badge>Default</Badge>
      <Badge variant="secondary">Secondary</Badge>
      <Badge variant="destructive">Destructive</Badge>
      <Badge variant="outline">Outline</Badge>
    </div>
  )
}
```

### Status Badges

```typescript
function StatusBadges() {
  return (
    <div className="flex gap-2">
      <Badge variant="success">Active</Badge>
      <Badge variant="warning">Pending</Badge>
      <Badge variant="destructive">Inactive</Badge>
      <Badge variant="info">Draft</Badge>
    </div>
  )
}
```

### Badges with Dot Indicator

```typescript
function DotBadges() {
  return (
    <div className="flex gap-2">
      <Badge variant="success" dot>Online</Badge>
      <Badge variant="destructive" dot>Offline</Badge>
      <Badge variant="warning" dot>Away</Badge>
    </div>
  )
}
```

### Different Sizes

```typescript
function SizedBadges() {
  return (
    <div className="flex items-center gap-2">
      <Badge size="sm">Small</Badge>
      <Badge size="md">Medium</Badge>
      <Badge size="lg">Large</Badge>
    </div>
  )
}
```

### Badges with Icons

```typescript
import { Check, X, AlertTriangle } from 'lucide-react'

function IconBadges() {
  return (
    <div className="flex gap-2">
      <Badge variant="success" icon={<Check className="h-3 w-3" />}>
        Completed
      </Badge>
      <Badge variant="destructive" icon={<X className="h-3 w-3" />}>
        Failed
      </Badge>
      <Badge variant="warning" icon={<AlertTriangle className="h-3 w-3" />}>
        Warning
      </Badge>
    </div>
  )
}
```

### Removable Badges

```typescript
function RemovableBadges() {
  const [tags, setTags] = React.useState(['React', 'TypeScript', 'Tailwind'])

  const removeTag = (index: number) => {
    setTags(tags.filter((_, i) => i !== index))
  }

  return (
    <div className="flex gap-2">
      {tags.map((tag, index) => (
        <Badge
          key={tag}
          variant="secondary"
          removable
          onRemove={() => removeTag(index)}
        >
          {tag}
        </Badge>
      ))}
    </div>
  )
}
```

### Badge Group

```typescript
import { BadgeGroup } from '@/components/ui/badge'

function BadgeGroupExample() {
  const skills = ['React', 'TypeScript', 'Node.js', 'Python', 'AWS', 'Docker']

  return (
    <BadgeGroup max={4}>
      {skills.map((skill) => (
        <Badge key={skill} variant="outline">
          {skill}
        </Badge>
      ))}
    </BadgeGroup>
  )
}
```

### Pill Badges

```typescript
function PillBadges() {
  return (
    <div className="flex gap-2">
      <Badge pill>Pill Badge</Badge>
      <Badge pill variant="success">Active</Badge>
      <Badge pill variant="info">Pro</Badge>
    </div>
  )
}
```

### Count Badges

```typescript
function CountBadges() {
  return (
    <div className="flex items-center gap-4">
      <div className="relative">
        <Button variant="outline" size="icon">
          <Mail className="h-4 w-4" />
        </Button>
        <Badge
          variant="destructive"
          size="sm"
          className="absolute -top-2 -right-2 h-5 w-5 justify-center p-0 rounded-full"
        >
          5
        </Badge>
      </div>

      <div className="relative">
        <Button variant="outline" size="icon">
          <Bell className="h-4 w-4" />
        </Button>
        <Badge
          variant="destructive"
          size="sm"
          className="absolute -top-2 -right-2 h-5 w-5 justify-center p-0 rounded-full"
        >
          12
        </Badge>
      </div>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Badge', () => {
  it('renders with default variant', () => {
    render(<Badge>Default</Badge>)
    expect(screen.getByText('Default')).toBeInTheDocument()
  })

  it('renders with different variants', () => {
    const { rerender } = render(<Badge variant="success">Success</Badge>)
    expect(screen.getByText('Success')).toHaveClass('bg-green-500')

    rerender(<Badge variant="warning">Warning</Badge>)
    expect(screen.getByText('Warning')).toHaveClass('bg-yellow-500')
  })

  it('renders with dot indicator', () => {
    render(<Badge dot>With Dot</Badge>)
    const badge = screen.getByText('With Dot')
    expect(badge.querySelector('.rounded-full')).toBeInTheDocument()
  })

  it('handles remove action', () => {
    const onRemove = jest.fn()
    render(
      <Badge removable onRemove={onRemove}>
        Removable
      </Badge>
    )
    const removeButton = screen.getByLabelText('Remove')
    fireEvent.click(removeButton)
    expect(onRemove).toHaveBeenCalled()
  })

  it('renders with icon', () => {
    render(
      <Badge icon={<Check data-testid="check-icon" />}>
        With Icon
      </Badge>
    )
    expect(screen.getByTestId('check-icon')).toBeInTheDocument()
  })

  it('renders different sizes', () => {
    const { rerender } = render(<Badge size="sm">Small</Badge>)
    expect(screen.getByText('Small')).toHaveClass('text-[10px]')

    rerender(<Badge size="lg">Large</Badge>)
    expect(screen.getByText('Large')).toHaveClass('text-sm')
  })
})

describe('BadgeGroup', () => {
  it('renders all badges when no max is set', () => {
    render(
      <BadgeGroup>
        <Badge>One</Badge>
        <Badge>Two</Badge>
        <Badge>Three</Badge>
      </BadgeGroup>
    )
    expect(screen.getByText('One')).toBeInTheDocument()
    expect(screen.getByText('Two')).toBeInTheDocument()
    expect(screen.getByText('Three')).toBeInTheDocument()
  })

  it('shows overflow count when max is exceeded', () => {
    render(
      <BadgeGroup max={2}>
        <Badge>One</Badge>
        <Badge>Two</Badge>
        <Badge>Three</Badge>
        <Badge>Four</Badge>
      </BadgeGroup>
    )
    expect(screen.getByText('One')).toBeInTheDocument()
    expect(screen.getByText('Two')).toBeInTheDocument()
    expect(screen.getByText('+2')).toBeInTheDocument()
    expect(screen.queryByText('Three')).not.toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML
- ✅ ARIA labels for removable badges
- ✅ Keyboard navigation for interactive badges
- ✅ Focus indicators
- ✅ Screen reader support
- ✅ Color contrast compliance

---

## 🎨 STYLING NOTES

### Color Tokens
```css
/* Badge variants use theme colors */
--badge-default: var(--primary)
--badge-success: hsl(142 71% 45%)
--badge-warning: hsl(48 96% 53%)
--badge-destructive: var(--destructive)
--badge-info: hsl(217 91% 60%)
```

### Size Guidelines
- **Small**: Use for compact spaces, inline text
- **Medium**: Default size for most use cases
- **Large**: Use for prominent status indicators

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create badge.tsx
- [ ] Implement badge variants (CVA)
- [ ] Add size variants
- [ ] Add dot indicator
- [ ] Add icon support
- [ ] Implement removable badges
- [ ] Create badge group component
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~1.5KB
- **With CVA**: ~2KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
