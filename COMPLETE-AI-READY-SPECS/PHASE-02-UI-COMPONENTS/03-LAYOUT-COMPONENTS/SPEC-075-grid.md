# SPEC-075: Grid Component
## Responsive Grid Layout System

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
A flexible grid layout component with responsive column configurations, gap spacing, and item spanning capabilities.

### Key Features
- ✅ Responsive column layouts (1-6 columns)
- ✅ Auto-fill/auto-fit support
- ✅ Flexible gap spacing
- ✅ Grid item spanning
- ✅ Mobile-first responsive
- ✅ Custom grid templates

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Implementation

```typescript
// src/components/ui/grid.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// GRID VARIANTS
// ========================================

const gridVariants = cva('grid w-full', {
  variants: {
    cols: {
      1: 'grid-cols-1',
      2: 'grid-cols-1 sm:grid-cols-2',
      3: 'grid-cols-1 sm:grid-cols-2 md:grid-cols-3',
      4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4',
      5: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-5',
      6: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6',
      auto: 'grid-cols-[repeat(auto-fill,minmax(250px,1fr))]',
      autoFit: 'grid-cols-[repeat(auto-fit,minmax(250px,1fr))]',
    },
    gap: {
      none: 'gap-0',
      xs: 'gap-1',
      sm: 'gap-2',
      md: 'gap-4',
      lg: 'gap-6',
      xl: 'gap-8',
      '2xl': 'gap-12',
    },
  },
  defaultVariants: {
    cols: 3,
    gap: 'md',
  },
})

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface GridProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof gridVariants> {
  /**
   * Grid items
   */
  children: React.ReactNode
}

export interface GridItemProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Column span (number or 'full')
   */
  colSpan?: 1 | 2 | 3 | 4 | 5 | 6 | 'full'

  /**
   * Row span
   */
  rowSpan?: 1 | 2 | 3 | 4 | 5 | 6

  /**
   * Column start position
   */
  colStart?: 1 | 2 | 3 | 4 | 5 | 6

  /**
   * Row start position
   */
  rowStart?: 1 | 2 | 3 | 4 | 5 | 6
}

// ========================================
// GRID COMPONENT
// ========================================

/**
 * Grid Component
 * 
 * Responsive grid container.
 * 
 * @example
 * <Grid cols={3} gap="md">
 *   <Card>Item 1</Card>
 *   <Card>Item 2</Card>
 *   <Card>Item 3</Card>
 * </Grid>
 */
const Grid = React.forwardRef<HTMLDivElement, GridProps>(
  ({ className, cols, gap, children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(gridVariants({ cols, gap }), className)}
      {...props}
    >
      {children}
    </div>
  )
)
Grid.displayName = 'Grid'

// ========================================
// GRID ITEM COMPONENT
// ========================================

const colSpanMap = {
  1: 'col-span-1',
  2: 'col-span-2',
  3: 'col-span-3',
  4: 'col-span-4',
  5: 'col-span-5',
  6: 'col-span-6',
  full: 'col-span-full',
} as const

const rowSpanMap = {
  1: 'row-span-1',
  2: 'row-span-2',
  3: 'row-span-3',
  4: 'row-span-4',
  5: 'row-span-5',
  6: 'row-span-6',
} as const

const colStartMap = {
  1: 'col-start-1',
  2: 'col-start-2',
  3: 'col-start-3',
  4: 'col-start-4',
  5: 'col-start-5',
  6: 'col-start-6',
} as const

const rowStartMap = {
  1: 'row-start-1',
  2: 'row-start-2',
  3: 'row-start-3',
  4: 'row-start-4',
  5: 'row-start-5',
  6: 'row-start-6',
} as const

/**
 * GridItem Component
 * 
 * Individual grid item with spanning capabilities.
 */
const GridItem = React.forwardRef<HTMLDivElement, GridItemProps>(
  ({ className, colSpan, rowSpan, colStart, rowStart, children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        colSpan && colSpanMap[colSpan],
        rowSpan && rowSpanMap[rowSpan],
        colStart && colStartMap[colStart],
        rowStart && rowStartMap[rowStart],
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
)
GridItem.displayName = 'GridItem'

// ========================================
// EXPORTS
// ========================================

export { Grid, GridItem, gridVariants }
```

---

## 📚 USAGE EXAMPLES

### Basic Grid

```typescript
import { Grid } from '@/components/ui/grid'
import { Card, CardContent } from '@/components/ui/card'

function BasicGrid() {
  return (
    <Grid cols={3} gap="md">
      <Card><CardContent>Item 1</CardContent></Card>
      <Card><CardContent>Item 2</CardContent></Card>
      <Card><CardContent>Item 3</CardContent></Card>
      <Card><CardContent>Item 4</CardContent></Card>
      <Card><CardContent>Item 5</CardContent></Card>
      <Card><CardContent>Item 6</CardContent></Card>
    </Grid>
  )
}
```

### Different Column Counts

```typescript
function ColumnVariants() {
  return (
    <div className="space-y-8">
      <Grid cols={2} gap="md">
        {[1, 2].map((i) => (
          <Card key={i}><CardContent>2 Cols - Item {i}</CardContent></Card>
        ))}
      </Grid>

      <Grid cols={4} gap="md">
        {[1, 2, 3, 4].map((i) => (
          <Card key={i}><CardContent>4 Cols - Item {i}</CardContent></Card>
        ))}
      </Grid>

      <Grid cols={6} gap="md">
        {[1, 2, 3, 4, 5, 6].map((i) => (
          <Card key={i}><CardContent>6 Cols - Item {i}</CardContent></Card>
        ))}
      </Grid>
    </div>
  )
}
```

### Grid with Item Spans

```typescript
import { GridItem } from '@/components/ui/grid'

function SpannedGrid() {
  return (
    <Grid cols={4} gap="lg">
      <GridItem colSpan={2}>
        <Card className="h-full">
          <CardContent>Wide item (2 columns)</CardContent>
        </Card>
      </GridItem>
      
      <Card><CardContent>Item</CardContent></Card>
      <Card><CardContent>Item</CardContent></Card>
      
      <Card><CardContent>Item</CardContent></Card>
      
      <GridItem colSpan={3}>
        <Card className="h-full">
          <CardContent>Extra wide item (3 columns)</CardContent>
        </Card>
      </GridItem>
      
      <GridItem colSpan="full">
        <Card>
          <CardContent>Full width item</CardContent>
        </Card>
      </GridItem>
    </Grid>
  )
}
```

### Dashboard Layout

```typescript
function DashboardGrid() {
  return (
    <Grid cols={4} gap="lg">
      {/* Stats Cards - Each takes 1 column */}
      <Card>
        <CardHeader>
          <CardTitle>Total Users</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">1,234</div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Revenue</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">$45,678</div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Orders</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">892</div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Conversion</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">3.2%</div>
        </CardContent>
      </Card>

      {/* Chart - Spans 3 columns */}
      <GridItem colSpan={3}>
        <Card className="h-full">
          <CardHeader>
            <CardTitle>Revenue Chart</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">Chart goes here</div>
          </CardContent>
        </Card>
      </GridItem>

      {/* Recent Activity - Spans 1 column */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2">
            <li>User registered</li>
            <li>Order placed</li>
            <li>Payment received</li>
          </ul>
        </CardContent>
      </Card>

      {/* Full width footer */}
      <GridItem colSpan="full">
        <Card>
          <CardContent>
            Full width footer content
          </CardContent>
        </Card>
      </GridItem>
    </Grid>
  )
}
```

### Auto-Fill Grid

```typescript
function AutoFillGrid() {
  return (
    <Grid cols="auto" gap="md">
      {Array.from({ length: 12 }).map((_, i) => (
        <Card key={i}>
          <CardContent>Auto item {i + 1}</CardContent>
        </Card>
      ))}
    </Grid>
  )
}
```

### Product Grid

```typescript
function ProductGrid() {
  const products = [
    { id: 1, name: 'Product 1', price: '$29.99', image: '/product1.jpg' },
    { id: 2, name: 'Product 2', price: '$39.99', image: '/product2.jpg' },
    // ... more products
  ]

  return (
    <Grid cols={4} gap="lg">
      {products.map((product) => (
        <Card key={product.id} className="overflow-hidden">
          <img
            src={product.image}
            alt={product.name}
            className="w-full h-48 object-cover"
          />
          <CardContent className="p-4">
            <h3 className="font-semibold">{product.name}</h3>
            <p className="text-lg font-bold mt-2">{product.price}</p>
            <Button className="w-full mt-4">Add to Cart</Button>
          </CardContent>
        </Card>
      ))}
    </Grid>
  )
}
```

### Row Spanning

```typescript
function RowSpanGrid() {
  return (
    <Grid cols={3} gap="md">
      <GridItem rowSpan={2}>
        <Card className="h-full">
          <CardContent>Tall item (2 rows)</CardContent>
        </Card>
      </GridItem>
      
      <Card><CardContent>Item</CardContent></Card>
      <Card><CardContent>Item</CardContent></Card>
      <Card><CardContent>Item</CardContent></Card>
      <Card><CardContent>Item</CardContent></Card>
    </Grid>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Grid', () => {
  it('renders grid with correct columns', () => {
    const { container } = render(
      <Grid cols={3}>
        <div>Item</div>
      </Grid>
    )
    expect(container.firstChild).toHaveClass('grid-cols-1', 'sm:grid-cols-2', 'md:grid-cols-3')
  })

  it('applies gap spacing', () => {
    const { container } = render(
      <Grid gap="lg">
        <div>Item</div>
      </Grid>
    )
    expect(container.firstChild).toHaveClass('gap-6')
  })

  it('GridItem spans columns', () => {
    const { container } = render(
      <Grid cols={4}>
        <GridItem colSpan={2}>Item</GridItem>
      </Grid>
    )
    expect(container.querySelector('div > div')).toHaveClass('col-span-2')
  })
})
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create grid.tsx
- [ ] Implement Grid with CVA variants
- [ ] Implement GridItem with span support
- [ ] Add responsive breakpoints
- [ ] Write tests
- [ ] Create examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
