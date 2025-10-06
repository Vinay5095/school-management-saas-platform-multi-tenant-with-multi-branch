# SPEC-095: Stats Card Component
## KPI and Metrics Display

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: Lucide React (icons)

---

## 📋 OVERVIEW

### Purpose
A stats card component for displaying key performance indicators (KPIs), metrics, and statistics with trend indicators and visual enhancements.

### Key Features
- ✅ Metric display with label and value
- ✅ Trend indicators (up, down, neutral)
- ✅ Percentage change display
- ✅ Icon support
- ✅ Multiple variants (default, bordered, filled)
- ✅ Chart integration support
- ✅ Loading states
- ✅ Responsive design

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/stats-card.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import {
  TrendingUp,
  TrendingDown,
  Minus,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'

// ========================================
// TYPE DEFINITIONS
// ========================================

const statsCardVariants = cva('', {
  variants: {
    variant: {
      default: '',
      bordered: 'border-2',
      filled: 'bg-muted/50',
    },
  },
  defaultVariants: {
    variant: 'default',
  },
})

export type TrendType = 'up' | 'down' | 'neutral'

export interface StatsCardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof statsCardVariants> {
  /**
   * Stat label/title
   */
  label: string

  /**
   * Stat value
   */
  value: string | number

  /**
   * Previous value for comparison
   */
  previousValue?: number

  /**
   * Percentage change
   */
  change?: number

  /**
   * Trend direction
   */
  trend?: TrendType

  /**
   * Icon
   */
  icon?: LucideIcon

  /**
   * Icon color class
   */
  iconColor?: string

  /**
   * Description text
   */
  description?: string

  /**
   * Loading state
   */
  loading?: boolean

  /**
   * Chart component (optional)
   */
  chart?: React.ReactNode

  /**
   * Compact mode
   */
  compact?: boolean
}

// ========================================
// STATS CARD COMPONENT
// ========================================

const StatsCard = React.forwardRef<HTMLDivElement, StatsCardProps>(
  (
    {
      className,
      variant,
      label,
      value,
      previousValue,
      change,
      trend: manualTrend,
      icon: Icon,
      iconColor = 'text-muted-foreground',
      description,
      loading = false,
      chart,
      compact = false,
      ...props
    },
    ref
  ) => {
    // Calculate trend automatically if not provided
    const calculatedTrend: TrendType = React.useMemo(() => {
      if (manualTrend) return manualTrend

      if (change !== undefined) {
        if (change > 0) return 'up'
        if (change < 0) return 'down'
        return 'neutral'
      }

      if (previousValue !== undefined && typeof value === 'number') {
        if (value > previousValue) return 'up'
        if (value < previousValue) return 'down'
        return 'neutral'
      }

      return 'neutral'
    }, [manualTrend, change, previousValue, value])

    // Calculate percentage change if not provided
    const calculatedChange = React.useMemo(() => {
      if (change !== undefined) return change

      if (previousValue !== undefined && typeof value === 'number' && previousValue !== 0) {
        return ((value - previousValue) / previousValue) * 100
      }

      return undefined
    }, [change, value, previousValue])

    const TrendIcon = {
      up: TrendingUp,
      down: TrendingDown,
      neutral: Minus,
    }[calculatedTrend]

    const trendColor = {
      up: 'text-green-600 dark:text-green-500',
      down: 'text-red-600 dark:text-red-500',
      neutral: 'text-muted-foreground',
    }[calculatedTrend]

    if (loading) {
      return (
        <Card ref={ref} className={cn(statsCardVariants({ variant }), className)} {...props}>
          <CardHeader className={cn('pb-2', compact && 'p-4')}>
            <div className="flex items-center justify-between">
              <Skeleton height={16} width={120} />
              {Icon && <Skeleton variant="circle" width={36} height={36} />}
            </div>
          </CardHeader>
          <CardContent className={cn(compact && 'p-4 pt-0')}>
            <Skeleton height={32} width={100} className="mb-2" />
            <Skeleton height={14} width={80} />
          </CardContent>
        </Card>
      )
    }

    return (
      <Card ref={ref} className={cn(statsCardVariants({ variant }), className)} {...props}>
        <CardHeader className={cn('pb-2', compact && 'p-4')}>
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-muted-foreground">{label}</span>
            {Icon && (
              <div className={cn('rounded-full bg-muted p-2', iconColor)}>
                <Icon className="h-4 w-4" />
              </div>
            )}
          </div>
        </CardHeader>
        <CardContent className={cn(compact && 'p-4 pt-0')}>
          <div className="space-y-1">
            <div className="text-2xl font-bold">{value}</div>
            
            {(calculatedChange !== undefined || description) && (
              <div className="flex items-center gap-2 text-xs">
                {calculatedChange !== undefined && (
                  <span className={cn('flex items-center gap-1 font-medium', trendColor)}>
                    <TrendIcon className="h-3 w-3" />
                    {Math.abs(calculatedChange).toFixed(1)}%
                  </span>
                )}
                {description && (
                  <span className="text-muted-foreground">{description}</span>
                )}
              </div>
            )}
          </div>

          {chart && <div className="mt-4">{chart}</div>}
        </CardContent>
      </Card>
    )
  }
)
StatsCard.displayName = 'StatsCard'

// ========================================
// STATS GRID
// ========================================

export interface StatsGridProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Number of columns
   */
  columns?: 1 | 2 | 3 | 4

  /**
   * Stats data
   */
  stats: Array<Omit<StatsCardProps, 'variant'>>

  /**
   * Loading state
   */
  loading?: boolean

  /**
   * Card variant
   */
  variant?: StatsCardProps['variant']
}

const StatsGrid = React.forwardRef<HTMLDivElement, StatsGridProps>(
  ({ className, columns = 4, stats, loading = false, variant, ...props }, ref) => {
    const gridCols = {
      1: 'grid-cols-1',
      2: 'grid-cols-1 md:grid-cols-2',
      3: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
      4: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-4',
    }

    return (
      <div ref={ref} className={cn('grid gap-4', gridCols[columns], className)} {...props}>
        {stats.map((stat, index) => (
          <StatsCard key={index} {...stat} variant={variant} loading={loading} />
        ))}
      </div>
    )
  }
)
StatsGrid.displayName = 'StatsGrid'

// ========================================
// STATS COMPARISON
// ========================================

export interface StatsComparisonProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Primary stat
   */
  primary: Omit<StatsCardProps, 'variant'>

  /**
   * Secondary stat
   */
  secondary: Omit<StatsCardProps, 'variant'>

  /**
   * Loading state
   */
  loading?: boolean
}

const StatsComparison = React.forwardRef<HTMLDivElement, StatsComparisonProps>(
  ({ className, primary, secondary, loading = false, ...props }, ref) => {
    return (
      <Card ref={ref} className={className} {...props}>
        <CardContent className="p-6">
          <div className="grid grid-cols-2 divide-x">
            <div className="pr-6">
              <div className="space-y-2">
                <span className="text-sm font-medium text-muted-foreground">
                  {loading ? <Skeleton width={80} height={14} /> : primary.label}
                </span>
                <div className="text-3xl font-bold">
                  {loading ? <Skeleton width={100} height={36} /> : primary.value}
                </div>
                {!loading && primary.description && (
                  <p className="text-xs text-muted-foreground">{primary.description}</p>
                )}
              </div>
            </div>
            <div className="pl-6">
              <div className="space-y-2">
                <span className="text-sm font-medium text-muted-foreground">
                  {loading ? <Skeleton width={80} height={14} /> : secondary.label}
                </span>
                <div className="text-3xl font-bold">
                  {loading ? <Skeleton width={100} height={36} /> : secondary.value}
                </div>
                {!loading && secondary.description && (
                  <p className="text-xs text-muted-foreground">{secondary.description}</p>
                )}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }
)
StatsComparison.displayName = 'StatsComparison'

export { StatsCard, StatsGrid, StatsComparison, statsCardVariants }
```

---

## 📚 USAGE EXAMPLES

### Basic Stats Card

```typescript
import { StatsCard } from '@/components/ui/stats-card'
import { Users } from 'lucide-react'

function BasicStats() {
  return (
    <StatsCard
      label="Total Users"
      value="2,543"
      change={12.5}
      icon={Users}
      iconColor="text-blue-600"
      description="from last month"
    />
  )
}
```

### Stats Grid

```typescript
import { StatsGrid } from '@/components/ui/stats-card'
import { Users, DollarSign, ShoppingCart, TrendingUp } from 'lucide-react'

function DashboardStats() {
  const stats = [
    {
      label: 'Total Revenue',
      value: '$45,231',
      change: 20.1,
      icon: DollarSign,
      iconColor: 'text-green-600',
      description: 'from last month',
    },
    {
      label: 'Active Users',
      value: '2,543',
      change: 12.5,
      icon: Users,
      iconColor: 'text-blue-600',
      description: 'from last month',
    },
    {
      label: 'Orders',
      value: '1,234',
      change: -4.3,
      icon: ShoppingCart,
      iconColor: 'text-purple-600',
      description: 'from last month',
    },
    {
      label: 'Conversion Rate',
      value: '3.24%',
      change: 1.8,
      icon: TrendingUp,
      iconColor: 'text-orange-600',
      description: 'from last month',
    },
  ]

  return <StatsGrid stats={stats} columns={4} />
}
```

### With Previous Value

```typescript
function RevenueStats() {
  return (
    <StatsCard
      label="Monthly Revenue"
      value={45231}
      previousValue={37654}
      description="vs last month"
    />
  )
}
```

### Loading State

```typescript
function LoadingStats() {
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    setTimeout(() => setLoading(false), 2000)
  }, [])

  return (
    <StatsCard
      label="Total Sales"
      value="$25,000"
      change={15}
      loading={loading}
    />
  )
}
```

### Different Variants

```typescript
function StatsVariants() {
  return (
    <div className="grid grid-cols-3 gap-4">
      <StatsCard
        label="Default"
        value="100"
        variant="default"
      />
      <StatsCard
        label="Bordered"
        value="200"
        variant="bordered"
      />
      <StatsCard
        label="Filled"
        value="300"
        variant="filled"
      />
    </div>
  )
}
```

### Compact Mode

```typescript
function CompactStats() {
  return (
    <StatsCard
      label="Active Sessions"
      value="124"
      change={8.2}
      compact
    />
  )
}
```

### With Chart

```typescript
import { LineChart, Line, ResponsiveContainer } from 'recharts'

function StatsWithChart() {
  const chartData = [
    { value: 10 },
    { value: 20 },
    { value: 15 },
    { value: 30 },
    { value: 25 },
    { value: 40 },
  ]

  return (
    <StatsCard
      label="Page Views"
      value="12,345"
      change={18.2}
      chart={
        <ResponsiveContainer width="100%" height={60}>
          <LineChart data={chartData}>
            <Line
              type="monotone"
              dataKey="value"
              stroke="#3b82f6"
              strokeWidth={2}
              dot={false}
            />
          </LineChart>
        </ResponsiveContainer>
      }
    />
  )
}
```

### Stats Comparison

```typescript
import { StatsComparison } from '@/components/ui/stats-card'

function ComparisonStats() {
  return (
    <StatsComparison
      primary={{
        label: 'This Month',
        value: '$45,231',
        description: 'Total revenue',
      }}
      secondary={{
        label: 'Last Month',
        value: '$37,654',
        description: 'Total revenue',
      }}
    />
  )
}
```

### Real-time Stats

```typescript
function RealtimeStats() {
  const [value, setValue] = React.useState(0)

  React.useEffect(() => {
    const interval = setInterval(() => {
      setValue((prev) => prev + Math.floor(Math.random() * 10))
    }, 2000)

    return () => clearInterval(interval)
  }, [])

  return (
    <StatsCard
      label="Active Connections"
      value={value}
      description="live"
    />
  )
}
```

### School Management Stats

```typescript
function SchoolStats() {
  const stats = [
    {
      label: 'Total Students',
      value: '1,234',
      change: 5.2,
      icon: Users,
      iconColor: 'text-blue-600',
      description: 'enrolled this year',
    },
    {
      label: 'Teaching Staff',
      value: '86',
      change: 2.3,
      icon: Users,
      iconColor: 'text-green-600',
      description: 'active teachers',
    },
    {
      label: 'Attendance Rate',
      value: '94.5%',
      change: 1.2,
      icon: TrendingUp,
      iconColor: 'text-purple-600',
      description: 'this month',
    },
    {
      label: 'Average Grade',
      value: '85.2',
      change: 3.8,
      icon: TrendingUp,
      iconColor: 'text-orange-600',
      description: 'class average',
    },
  ]

  return <StatsGrid stats={stats} columns={4} />
}
```

### Custom Formatted Value

```typescript
function FormattedStats() {
  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
    }).format(value)
  }

  return (
    <StatsCard
      label="Total Revenue"
      value={formatCurrency(125000)}
      change={15.3}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('StatsCard', () => {
  it('renders with label and value', () => {
    render(<StatsCard label="Test Stat" value="100" />)
    expect(screen.getByText('Test Stat')).toBeInTheDocument()
    expect(screen.getByText('100')).toBeInTheDocument()
  })

  it('displays percentage change', () => {
    render(<StatsCard label="Test" value="100" change={15.5} />)
    expect(screen.getByText('15.5%')).toBeInTheDocument()
  })

  it('calculates trend from change', () => {
    const { rerender } = render(<StatsCard label="Test" value="100" change={10} />)
    expect(screen.getByRole('img', { hidden: true })).toHaveClass('lucide-trending-up')

    rerender(<StatsCard label="Test" value="100" change={-10} />)
    expect(screen.getByRole('img', { hidden: true })).toHaveClass('lucide-trending-down')
  })

  it('renders icon', () => {
    render(<StatsCard label="Test" value="100" icon={Users} />)
    expect(screen.getByRole('img', { hidden: true })).toHaveClass('lucide-users')
  })

  it('shows loading state', () => {
    render(<StatsCard label="Test" value="100" loading />)
    expect(document.querySelector('.animate-pulse')).toBeInTheDocument()
  })

  it('renders description', () => {
    render(
      <StatsCard
        label="Test"
        value="100"
        description="from last month"
      />
    )
    expect(screen.getByText('from last month')).toBeInTheDocument()
  })

  it('calculates change from previous value', () => {
    render(<StatsCard label="Test" value={110} previousValue={100} />)
    expect(screen.getByText('10.0%')).toBeInTheDocument()
  })
})

describe('StatsGrid', () => {
  const stats = [
    { label: 'Stat 1', value: '100' },
    { label: 'Stat 2', value: '200' },
  ]

  it('renders all stats', () => {
    render(<StatsGrid stats={stats} />)
    expect(screen.getByText('Stat 1')).toBeInTheDocument()
    expect(screen.getByText('Stat 2')).toBeInTheDocument()
  })

  it('applies correct grid columns', () => {
    const { container } = render(<StatsGrid stats={stats} columns={2} />)
    expect(container.firstChild).toHaveClass('md:grid-cols-2')
  })

  it('passes loading state to all cards', () => {
    render(<StatsGrid stats={stats} loading />)
    const skeletons = document.querySelectorAll('.animate-pulse')
    expect(skeletons.length).toBeGreaterThan(0)
  })
})

describe('StatsComparison', () => {
  const primary = { label: 'This Month', value: '$100' }
  const secondary = { label: 'Last Month', value: '$80' }

  it('renders both stats', () => {
    render(<StatsComparison primary={primary} secondary={secondary} />)
    expect(screen.getByText('This Month')).toBeInTheDocument()
    expect(screen.getByText('Last Month')).toBeInTheDocument()
    expect(screen.getByText('$100')).toBeInTheDocument()
    expect(screen.getByText('$80')).toBeInTheDocument()
  })

  it('shows loading state', () => {
    render(<StatsComparison primary={primary} secondary={secondary} loading />)
    expect(document.querySelector('.animate-pulse')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML
- ✅ Proper heading hierarchy
- ✅ Color is not the only indicator (icons for trends)
- ✅ Readable text sizes
- ✅ Sufficient color contrast

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Lucide React: `npm install lucide-react`
- [ ] Create stats-card.tsx
- [ ] Implement StatsCard component
- [ ] Add trend calculation logic
- [ ] Implement StatsGrid component
- [ ] Implement StatsComparison component
- [ ] Add loading states
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With Lucide React**: ~3KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
