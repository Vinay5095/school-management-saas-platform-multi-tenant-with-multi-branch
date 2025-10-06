# SPEC-086: List Component
## Flexible List with Multiple Variants

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4 hours  
> **Dependencies**: Avatar, Button

---

## 📋 OVERVIEW

### Purpose
A versatile list component supporting various layouts including simple lists, card lists, and detailed item lists with avatars, descriptions, and actions.

### Key Features
- ✅ Multiple variants (simple, detailed, card)
- ✅ Avatar support
- ✅ Secondary text/descriptions
- ✅ Item actions
- ✅ Dividers
- ✅ Loading states
- ✅ Empty states
- ✅ Infinite scroll support
- ✅ Selectable items
- ✅ Keyboard navigation

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/list.tsx
'use client'

import * as React from 'react'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ListItem {
  /**
   * Unique identifier
   */
  id: string

  /**
   * Primary text
   */
  primary: React.ReactNode

  /**
   * Secondary text
   */
  secondary?: React.ReactNode

  /**
   * Avatar image URL
   */
  avatar?: string

  /**
   * Avatar fallback text
   */
  avatarFallback?: string

  /**
   * Leading icon/element
   */
  leading?: React.ReactNode

  /**
   * Trailing icon/element
   */
  trailing?: React.ReactNode

  /**
   * Actions
   */
  actions?: React.ReactNode

  /**
   * Click handler
   */
  onClick?: () => void

  /**
   * Disabled state
   */
  disabled?: boolean

  /**
   * Selected state
   */
  selected?: boolean
}

export interface ListProps {
  /**
   * List items
   */
  items: ListItem[]

  /**
   * Variant
   */
  variant?: 'simple' | 'detailed' | 'card'

  /**
   * Size
   */
  size?: 'sm' | 'md' | 'lg'

  /**
   * Show dividers
   */
  divided?: boolean

  /**
   * Enable selection
   */
  selectable?: boolean

  /**
   * Selected items (controlled)
   */
  selectedItems?: string[]

  /**
   * Selection change callback
   */
  onSelectionChange?: (selectedIds: string[]) => void

  /**
   * Loading state
   */
  isLoading?: boolean

  /**
   * Loading items count
   */
  loadingCount?: number

  /**
   * Empty state message
   */
  emptyMessage?: string

  /**
   * Empty state icon
   */
  emptyIcon?: React.ReactNode

  /**
   * Empty state action
   */
  emptyAction?: React.ReactNode

  /**
   * Enable infinite scroll
   */
  infiniteScroll?: boolean

  /**
   * Load more callback
   */
  onLoadMore?: () => void

  /**
   * Has more items
   */
  hasMore?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// LIST ITEM SKELETON
// ========================================

function ListItemSkeleton({ variant, size }: { variant: string; size: string }) {
  const heights = { sm: 'h-12', md: 'h-16', lg: 'h-20' }

  return (
    <div className={cn('flex items-center gap-4 p-4', heights[size])}>
      {variant !== 'simple' && <Skeleton className="h-10 w-10 rounded-full" />}
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-1/3" />
        {variant === 'detailed' && <Skeleton className="h-3 w-1/2" />}
      </div>
      <Skeleton className="h-8 w-8 rounded" />
    </div>
  )
}

// ========================================
// EMPTY STATE
// ========================================

interface EmptyStateProps {
  message?: string
  icon?: React.ReactNode
  action?: React.ReactNode
}

function EmptyState({ message = 'No items found', icon, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      {icon && <div className="mb-4 text-muted-foreground">{icon}</div>}
      <p className="text-sm text-muted-foreground mb-4">{message}</p>
      {action}
    </div>
  )
}

// ========================================
// LIST ITEM COMPONENT
// ========================================

interface ListItemComponentProps {
  item: ListItem
  variant: 'simple' | 'detailed' | 'card'
  size: 'sm' | 'md' | 'lg'
  selectable?: boolean
  isSelected?: boolean
  onSelect?: (id: string) => void
}

function ListItemComponent({
  item,
  variant,
  size,
  selectable,
  isSelected,
  onSelect,
}: ListItemComponentProps) {
  const heights = {
    sm: 'min-h-12',
    md: 'min-h-16',
    lg: 'min-h-20',
  }

  const paddingClasses = {
    sm: 'p-2',
    md: 'p-4',
    lg: 'p-6',
  }

  const handleClick = () => {
    if (item.disabled) return
    if (selectable) {
      onSelect?.(item.id)
    }
    item.onClick?.()
  }

  const content = (
    <>
      {/* Leading */}
      {(item.leading || item.avatar) && (
        <div className="flex-shrink-0">
          {item.avatar ? (
            <Avatar className={cn(size === 'sm' && 'h-8 w-8', size === 'md' && 'h-10 w-10', size === 'lg' && 'h-12 w-12')}>
              <AvatarImage src={item.avatar} />
              <AvatarFallback>{item.avatarFallback}</AvatarFallback>
            </Avatar>
          ) : (
            item.leading
          )}
        </div>
      )}

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className={cn('font-medium truncate', size === 'sm' && 'text-sm')}>
          {item.primary}
        </div>
        {item.secondary && (
          <div className={cn('text-muted-foreground truncate', size === 'sm' ? 'text-xs' : 'text-sm')}>
            {item.secondary}
          </div>
        )}
      </div>

      {/* Trailing */}
      {item.trailing && (
        <div className="flex-shrink-0">
          {item.trailing}
        </div>
      )}

      {/* Actions */}
      {item.actions && (
        <div className="flex-shrink-0 flex items-center gap-2">
          {item.actions}
        </div>
      )}
    </>
  )

  if (variant === 'card') {
    return (
      <div
        onClick={handleClick}
        className={cn(
          'flex items-center gap-4 rounded-lg border bg-card text-card-foreground shadow-sm transition-colors',
          paddingClasses[size],
          heights[size],
          (item.onClick || selectable) && !item.disabled && 'cursor-pointer hover:bg-accent',
          isSelected && 'bg-accent border-primary',
          item.disabled && 'opacity-50 cursor-not-allowed'
        )}
      >
        {content}
      </div>
    )
  }

  return (
    <div
      onClick={handleClick}
      className={cn(
        'flex items-center gap-4',
        paddingClasses[size],
        heights[size],
        (item.onClick || selectable) && !item.disabled && 'cursor-pointer hover:bg-accent',
        isSelected && 'bg-accent',
        item.disabled && 'opacity-50 cursor-not-allowed'
      )}
    >
      {content}
    </div>
  )
}

// ========================================
// LIST COMPONENT
// ========================================

/**
 * List Component
 * 
 * Flexible list with multiple variants.
 * 
 * @example
 * <List
 *   items={items}
 *   variant="detailed"
 *   divided
 * />
 */
export function List({
  items,
  variant = 'detailed',
  size = 'md',
  divided = false,
  selectable = false,
  selectedItems: controlledSelection,
  onSelectionChange,
  isLoading = false,
  loadingCount = 5,
  emptyMessage,
  emptyIcon,
  emptyAction,
  infiniteScroll = false,
  onLoadMore,
  hasMore = false,
  className,
}: ListProps) {
  const [localSelection, setLocalSelection] = React.useState<string[]>([])
  const observerTarget = React.useRef<HTMLDivElement>(null)

  const selectedItems = controlledSelection ?? localSelection

  const handleSelect = (id: string) => {
    const newSelection = selectedItems.includes(id)
      ? selectedItems.filter((item) => item !== id)
      : [...selectedItems, id]

    if (!controlledSelection) {
      setLocalSelection(newSelection)
    }
    onSelectionChange?.(newSelection)
  }

  // Infinite scroll
  React.useEffect(() => {
    if (!infiniteScroll || !onLoadMore) return

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasMore && !isLoading) {
          onLoadMore()
        }
      },
      { threshold: 0.1 }
    )

    if (observerTarget.current) {
      observer.observe(observerTarget.current)
    }

    return () => observer.disconnect()
  }, [infiniteScroll, onLoadMore, hasMore, isLoading])

  // Loading state
  if (isLoading && items.length === 0) {
    return (
      <div className={cn(variant === 'card' ? 'space-y-4' : divided && 'divide-y', className)}>
        {Array.from({ length: loadingCount }).map((_, i) => (
          <ListItemSkeleton key={i} variant={variant} size={size} />
        ))}
      </div>
    )
  }

  // Empty state
  if (!isLoading && items.length === 0) {
    return (
      <div className={className}>
        <EmptyState message={emptyMessage} icon={emptyIcon} action={emptyAction} />
      </div>
    )
  }

  return (
    <div className={cn(variant === 'card' ? 'space-y-4' : divided && 'divide-y', className)}>
      {items.map((item) => (
        <ListItemComponent
          key={item.id}
          item={item}
          variant={variant}
          size={size}
          selectable={selectable}
          isSelected={selectedItems.includes(item.id)}
          onSelect={handleSelect}
        />
      ))}

      {/* Infinite scroll trigger */}
      {infiniteScroll && hasMore && (
        <div ref={observerTarget} className="py-4">
          {isLoading && <ListItemSkeleton variant={variant} size={size} />}
        </div>
      )}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Simple List

```typescript
import { List } from '@/components/ui/list'

function SimpleList() {
  const items = [
    { id: '1', primary: 'Item 1' },
    { id: '2', primary: 'Item 2' },
    { id: '3', primary: 'Item 3' },
  ]

  return <List items={items} variant="simple" divided />
}
```

### Detailed List with Avatars

```typescript
function UsersList() {
  const items = [
    {
      id: '1',
      primary: 'John Doe',
      secondary: 'john@example.com',
      avatar: '/avatars/john.jpg',
      avatarFallback: 'JD',
    },
    {
      id: '2',
      primary: 'Jane Smith',
      secondary: 'jane@example.com',
      avatar: '/avatars/jane.jpg',
      avatarFallback: 'JS',
    },
  ]

  return <List items={items} variant="detailed" divided />
}
```

### Card List with Actions

```typescript
import { MoreHorizontal, Edit, Trash } from 'lucide-react'

function CardList() {
  const items = [
    {
      id: '1',
      primary: 'Project Alpha',
      secondary: 'Due: Tomorrow',
      avatar: '/project-alpha.jpg',
      trailing: <span className="text-sm text-muted-foreground">$10,000</span>,
      actions: (
        <>
          <Button size="icon" variant="ghost">
            <Edit className="h-4 w-4" />
          </Button>
          <Button size="icon" variant="ghost">
            <Trash className="h-4 w-4" />
          </Button>
        </>
      ),
    },
  ]

  return <List items={items} variant="card" />
}
```

### Selectable List

```typescript
function SelectableList() {
  const [selected, setSelected] = React.useState<string[]>([])

  return (
    <List
      items={items}
      selectable
      selectedItems={selected}
      onSelectionChange={setSelected}
    />
  )
}
```

### With Infinite Scroll

```typescript
function InfiniteList() {
  const [items, setItems] = React.useState([])
  const [hasMore, setHasMore] = React.useState(true)
  const [isLoading, setIsLoading] = React.useState(false)

  const loadMore = async () => {
    setIsLoading(true)
    const newItems = await fetchMoreItems()
    setItems([...items, ...newItems])
    setHasMore(newItems.length > 0)
    setIsLoading(false)
  }

  return (
    <List
      items={items}
      infiniteScroll
      onLoadMore={loadMore}
      hasMore={hasMore}
      isLoading={isLoading}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('List', () => {
  it('renders items', () => {
    render(<List items={items} />)
    expect(screen.getByText(items[0].primary)).toBeInTheDocument()
  })

  it('handles selection', () => {
    const onSelectionChange = jest.fn()
    render(
      <List
        items={items}
        selectable
        onSelectionChange={onSelectionChange}
      />
    )
    fireEvent.click(screen.getByText(items[0].primary))
    expect(onSelectionChange).toHaveBeenCalled()
  })

  it('shows empty state', () => {
    render(<List items={[]} emptyMessage="No data" />)
    expect(screen.getByText('No data')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ ARIA roles
- ✅ Focus indicators
- ✅ Screen reader support
- ✅ Disabled states

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create list.tsx
- [ ] Implement variants
- [ ] Add avatar support
- [ ] Add selection
- [ ] Add infinite scroll
- [ ] Add loading/empty states
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
