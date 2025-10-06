# SPEC-078: Breadcrumb Component
## Hierarchical Navigation with Custom Separators

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 3 hours  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
A breadcrumb navigation component that shows the user's location within the application hierarchy with customizable separators, icons, and dropdown menus.

### Key Features
- ✅ Auto-generated from route
- ✅ Manual breadcrumb items
- ✅ Custom separators
- ✅ Icons support
- ✅ Dropdown menus for long paths
- ✅ Truncation options
- ✅ Home icon
- ✅ Responsive collapsing
- ✅ Keyboard navigation
- ✅ Dark mode support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/breadcrumb.tsx
'use client'

import * as React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ChevronRight, Home, MoreHorizontal } from 'lucide-react'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface BreadcrumbItem {
  /**
   * Item label
   */
  label: string

  /**
   * Item href
   */
  href?: string

  /**
   * Icon component
   */
  icon?: React.ReactNode

  /**
   * Disabled state
   */
  disabled?: boolean
}

export interface BreadcrumbProps {
  /**
   * Breadcrumb items
   */
  items?: BreadcrumbItem[]

  /**
   * Auto-generate from pathname
   */
  autoGenerate?: boolean

  /**
   * Path transformation function
   */
  transformPath?: (segment: string) => string

  /**
   * Separator component
   */
  separator?: React.ReactNode

  /**
   * Show home icon
   */
  showHome?: boolean

  /**
   * Home href
   */
  homeHref?: string

  /**
   * Max items to show before collapsing
   */
  maxItems?: number

  /**
   * Truncate labels
   */
  maxLabelLength?: number

  /**
   * Size variant
   */
  size?: 'sm' | 'md' | 'lg'

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// HELPER FUNCTIONS
// ========================================

function generateBreadcrumbs(
  pathname: string,
  transformPath?: (segment: string) => string
): BreadcrumbItem[] {
  const segments = pathname.split('/').filter(Boolean)
  
  return segments.map((segment, index) => {
    const href = '/' + segments.slice(0, index + 1).join('/')
    const label = transformPath
      ? transformPath(segment)
      : segment.charAt(0).toUpperCase() + segment.slice(1).replace(/-/g, ' ')
    
    return { label, href }
  })
}

function truncateLabel(label: string, maxLength: number): string {
  if (label.length <= maxLength) return label
  return label.slice(0, maxLength - 3) + '...'
}

// ========================================
// BREADCRUMB SEPARATOR
// ========================================

interface BreadcrumbSeparatorProps {
  children?: React.ReactNode
}

function BreadcrumbSeparator({ children }: BreadcrumbSeparatorProps) {
  return (
    <span className="mx-2 text-muted-foreground" role="presentation">
      {children || <ChevronRight className="h-4 w-4" />}
    </span>
  )
}

// ========================================
// BREADCRUMB ITEM
// ========================================

interface BreadcrumbItemComponentProps {
  item: BreadcrumbItem
  isLast: boolean
  maxLabelLength?: number
  size?: 'sm' | 'md' | 'lg'
}

function BreadcrumbItemComponent({
  item,
  isLast,
  maxLabelLength,
  size = 'md',
}: BreadcrumbItemComponentProps) {
  const label = maxLabelLength ? truncateLabel(item.label, maxLabelLength) : item.label

  const sizeClasses = {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-base',
  }

  if (isLast || item.disabled) {
    return (
      <span
        className={cn(
          'font-medium',
          isLast ? 'text-foreground' : 'text-muted-foreground',
          sizeClasses[size]
        )}
        aria-current={isLast ? 'page' : undefined}
      >
        {item.icon && <span className="mr-1.5 inline-block">{item.icon}</span>}
        {label}
      </span>
    )
  }

  return (
    <Link
      href={item.href!}
      className={cn(
        'font-medium text-muted-foreground transition-colors hover:text-foreground',
        sizeClasses[size]
      )}
    >
      {item.icon && <span className="mr-1.5 inline-block">{item.icon}</span>}
      {label}
    </Link>
  )
}

// ========================================
// COLLAPSED BREADCRUMBS
// ========================================

interface CollapsedBreadcrumbsProps {
  items: BreadcrumbItem[]
}

function CollapsedBreadcrumbs({ items }: CollapsedBreadcrumbsProps) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className="h-auto p-1 text-muted-foreground hover:text-foreground"
          aria-label="Show more breadcrumbs"
        >
          <MoreHorizontal className="h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start">
        {items.map((item, index) => (
          <DropdownMenuItem key={index} asChild>
            <Link href={item.href!} className="flex items-center">
              {item.icon && <span className="mr-2">{item.icon}</span>}
              {item.label}
            </Link>
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

// ========================================
// BREADCRUMB COMPONENT
// ========================================

/**
 * Breadcrumb Component
 * 
 * Shows hierarchical navigation path.
 * 
 * @example
 * <Breadcrumb autoGenerate />
 * 
 * @example
 * <Breadcrumb items={[
 *   { label: 'Home', href: '/' },
 *   { label: 'Products', href: '/products' },
 *   { label: 'Details' }
 * ]} />
 */
export function Breadcrumb({
  items: providedItems,
  autoGenerate = false,
  transformPath,
  separator,
  showHome = false,
  homeHref = '/',
  maxItems = 5,
  maxLabelLength,
  size = 'md',
  className,
}: BreadcrumbProps) {
  const pathname = usePathname()

  // Generate or use provided items
  const generatedItems = React.useMemo(() => {
    if (providedItems) return providedItems
    if (autoGenerate && pathname) {
      return generateBreadcrumbs(pathname, transformPath)
    }
    return []
  }, [providedItems, autoGenerate, pathname, transformPath])

  // Add home item if needed
  const items = React.useMemo(() => {
    if (showHome && generatedItems[0]?.href !== homeHref) {
      return [
        { label: 'Home', href: homeHref, icon: <Home className="h-4 w-4" /> },
        ...generatedItems,
      ]
    }
    return generatedItems
  }, [showHome, homeHref, generatedItems])

  if (items.length === 0) return null

  // Handle collapsed breadcrumbs
  const shouldCollapse = items.length > maxItems
  const collapsedItems = shouldCollapse
    ? [
        items[0],
        ...items.slice(1, -Math.floor(maxItems / 2)),
      ]
    : []
  const visibleItems = shouldCollapse
    ? [
        items[0],
        ...items.slice(-Math.floor(maxItems / 2)),
      ]
    : items

  return (
    <nav aria-label="Breadcrumb" className={cn('flex items-center', className)}>
      <ol className="flex items-center flex-wrap gap-1">
        {shouldCollapse ? (
          <>
            <li className="flex items-center">
              <BreadcrumbItemComponent
                item={visibleItems[0]}
                isLast={false}
                maxLabelLength={maxLabelLength}
                size={size}
              />
            </li>
            <li className="flex items-center">
              <BreadcrumbSeparator>{separator}</BreadcrumbSeparator>
              <CollapsedBreadcrumbs items={collapsedItems.slice(1)} />
            </li>
            {visibleItems.slice(1).map((item, index) => (
              <React.Fragment key={index}>
                <li className="flex items-center">
                  <BreadcrumbSeparator>{separator}</BreadcrumbSeparator>
                  <BreadcrumbItemComponent
                    item={item}
                    isLast={index === visibleItems.slice(1).length - 1}
                    maxLabelLength={maxLabelLength}
                    size={size}
                  />
                </li>
              </React.Fragment>
            ))}
          </>
        ) : (
          items.map((item, index) => (
            <React.Fragment key={index}>
              {index > 0 && (
                <li className="flex items-center">
                  <BreadcrumbSeparator>{separator}</BreadcrumbSeparator>
                </li>
              )}
              <li className="flex items-center">
                <BreadcrumbItemComponent
                  item={item}
                  isLast={index === items.length - 1}
                  maxLabelLength={maxLabelLength}
                  size={size}
                />
              </li>
            </React.Fragment>
          ))
        )}
      </ol>
    </nav>
  )
}

// ========================================
// EXPORTS
// ========================================

export { BreadcrumbSeparator }
```

---

## 📚 USAGE EXAMPLES

### Auto-Generated Breadcrumbs

```typescript
import { Breadcrumb } from '@/components/ui/breadcrumb'

function PageHeader() {
  return (
    <div className="mb-4">
      <Breadcrumb autoGenerate showHome />
    </div>
  )
}
```

### Manual Breadcrumbs

```typescript
function ProductDetails() {
  const breadcrumbs = [
    { label: 'Home', href: '/' },
    { label: 'Products', href: '/products' },
    { label: 'Electronics', href: '/products/electronics' },
    { label: 'Laptop' }, // Current page
  ]

  return (
    <>
      <Breadcrumb items={breadcrumbs} />
      <h1>Laptop Details</h1>
    </>
  )
}
```

### Custom Separator

```typescript
import { Slash } from 'lucide-react'

function CustomBreadcrumb() {
  return (
    <Breadcrumb
      items={breadcrumbs}
      separator={<Slash className="h-4 w-4" />}
    />
  )
}
```

### With Icons

```typescript
import { Package, Tag } from 'lucide-react'

const breadcrumbs = [
  { label: 'Products', href: '/products', icon: <Package className="h-4 w-4" /> },
  { label: 'Categories', href: '/products/categories', icon: <Tag className="h-4 w-4" /> },
  { label: 'Electronics' },
]

function IconBreadcrumb() {
  return <Breadcrumb items={breadcrumbs} />
}
```

### Truncated Labels

```typescript
function TruncatedBreadcrumb() {
  return (
    <Breadcrumb
      items={breadcrumbs}
      maxLabelLength={20}
      maxItems={3}
    />
  )
}
```

### Custom Path Transform

```typescript
function TransformedBreadcrumb() {
  return (
    <Breadcrumb
      autoGenerate
      transformPath={(segment) => {
        // Custom transformation logic
        const formatted = segment.replace(/-/g, ' ')
        return formatted.charAt(0).toUpperCase() + formatted.slice(1)
      }}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Breadcrumb', () => {
  it('renders manual breadcrumb items', () => {
    render(<Breadcrumb items={breadcrumbs} />)
    expect(screen.getByText('Home')).toBeInTheDocument()
    expect(screen.getByText('Products')).toBeInTheDocument()
  })

  it('auto-generates from pathname', () => {
    mockPathname('/products/electronics/laptop')
    render(<Breadcrumb autoGenerate />)
    expect(screen.getByText('Products')).toBeInTheDocument()
    expect(screen.getByText('Electronics')).toBeInTheDocument()
  })

  it('shows home icon', () => {
    render(<Breadcrumb items={breadcrumbs} showHome />)
    expect(screen.getByLabelText('Home')).toBeInTheDocument()
  })

  it('collapses long breadcrumbs', () => {
    const manyItems = Array.from({ length: 10 }, (_, i) => ({
      label: `Level ${i}`,
      href: `/level-${i}`,
    }))
    render(<Breadcrumb items={manyItems} maxItems={5} />)
    expect(screen.getByLabelText('Show more breadcrumbs')).toBeInTheDocument()
  })

  it('truncates long labels', () => {
    const longLabel = 'Very Long Breadcrumb Label That Should Be Truncated'
    render(<Breadcrumb items={[{ label: longLabel }]} maxLabelLength={20} />)
    expect(screen.getByText(/\.\.\./)).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML (`<nav>`, `<ol>`, `<li>`)
- ✅ ARIA labels
- ✅ Current page indicator
- ✅ Keyboard navigation
- ✅ Focus indicators

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create breadcrumb.tsx
- [ ] Implement auto-generation
- [ ] Add custom separators
- [ ] Add icons support
- [ ] Implement collapsing
- [ ] Add truncation
- [ ] Add dropdown menu
- [ ] Write tests
- [ ] Test accessibility
- [ ] Test responsive behavior

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
