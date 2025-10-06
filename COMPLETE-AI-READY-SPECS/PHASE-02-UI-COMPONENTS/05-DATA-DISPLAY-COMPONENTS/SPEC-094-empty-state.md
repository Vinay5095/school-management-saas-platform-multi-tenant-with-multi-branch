# SPEC-094: Empty State Component
## No Content Placeholders

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: Lucide React (icons)

---

## 📋 OVERVIEW

### Purpose
An empty state component for displaying helpful messages when no content is available, guiding users on what to do next.

### Key Features
- ✅ Multiple preset states (no data, no results, error, no access)
- ✅ Custom icons
- ✅ Title and description
- ✅ Call-to-action buttons
- ✅ Image support
- ✅ Multiple sizes
- ✅ Customizable styling
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/empty-state.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import {
  FileX,
  Search,
  AlertTriangle,
  Lock,
  Inbox,
  Package,
  Users,
  Calendar,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'

// ========================================
// TYPE DEFINITIONS
// ========================================

const emptyStateVariants = cva('flex flex-col items-center justify-center text-center', {
  variants: {
    size: {
      sm: 'py-8 px-4',
      md: 'py-12 px-6',
      lg: 'py-16 px-8',
    },
  },
  defaultVariants: {
    size: 'md',
  },
})

export type EmptyStatePreset =
  | 'no-data'
  | 'no-results'
  | 'no-items'
  | 'no-messages'
  | 'no-users'
  | 'no-events'
  | 'error'
  | 'no-access'

export interface EmptyStateAction {
  label: string
  onClick: () => void
  variant?: 'default' | 'outline' | 'ghost'
  icon?: LucideIcon
}

export interface EmptyStateProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof emptyStateVariants> {
  /**
   * Preset empty state type
   */
  preset?: EmptyStatePreset

  /**
   * Custom icon
   */
  icon?: LucideIcon | React.ReactNode

  /**
   * Icon size
   */
  iconSize?: number

  /**
   * Title text
   */
  title?: string

  /**
   * Description text
   */
  description?: string | React.ReactNode

  /**
   * Primary action button
   */
  action?: EmptyStateAction

  /**
   * Secondary action button
   */
  secondaryAction?: EmptyStateAction

  /**
   * Image URL (alternative to icon)
   */
  image?: string

  /**
   * Image alt text
   */
  imageAlt?: string
}

// ========================================
// PRESET CONFIGURATIONS
// ========================================

const presetConfigs: Record<
  EmptyStatePreset,
  {
    icon: LucideIcon
    title: string
    description: string
  }
> = {
  'no-data': {
    icon: FileX,
    title: 'No data available',
    description: 'There is no data to display at the moment.',
  },
  'no-results': {
    icon: Search,
    title: 'No results found',
    description: 'Try adjusting your search or filters to find what you are looking for.',
  },
  'no-items': {
    icon: Package,
    title: 'No items yet',
    description: 'Get started by creating your first item.',
  },
  'no-messages': {
    icon: Inbox,
    title: 'No messages',
    description: 'Your inbox is empty. New messages will appear here.',
  },
  'no-users': {
    icon: Users,
    title: 'No users found',
    description: 'No users match your current filters.',
  },
  'no-events': {
    icon: Calendar,
    title: 'No events scheduled',
    description: 'You have no upcoming events.',
  },
  error: {
    icon: AlertTriangle,
    title: 'Something went wrong',
    description: 'An error occurred while loading the data. Please try again.',
  },
  'no-access': {
    icon: Lock,
    title: 'Access denied',
    description: "You don't have permission to view this content.",
  },
}

// ========================================
// EMPTY STATE COMPONENT
// ========================================

const EmptyState = React.forwardRef<HTMLDivElement, EmptyStateProps>(
  (
    {
      className,
      size,
      preset,
      icon: customIcon,
      iconSize = 64,
      title: customTitle,
      description: customDescription,
      action,
      secondaryAction,
      image,
      imageAlt,
      ...props
    },
    ref
  ) => {
    // Get preset config or use custom values
    const config = preset ? presetConfigs[preset] : null
    const Icon = customIcon
      ? typeof customIcon === 'function'
        ? customIcon
        : null
      : config?.icon

    const title = customTitle || config?.title || 'No data'
    const description = customDescription || config?.description

    return (
      <div ref={ref} className={cn(emptyStateVariants({ size }), className)} {...props}>
        <div className="mx-auto max-w-md space-y-4">
          {/* Image or Icon */}
          {image ? (
            <img
              src={image}
              alt={imageAlt || title}
              className="mx-auto h-48 w-48 object-contain"
            />
          ) : Icon ? (
            <div className="mx-auto flex items-center justify-center">
              {React.isValidElement(customIcon) ? (
                customIcon
              ) : (
                <Icon
                  className="text-muted-foreground"
                  size={iconSize}
                  strokeWidth={1.5}
                />
              )}
            </div>
          ) : null}

          {/* Content */}
          <div className="space-y-2">
            <h3 className="text-lg font-semibold">{title}</h3>
            {description && (
              <p className="text-sm text-muted-foreground">
                {description}
              </p>
            )}
          </div>

          {/* Actions */}
          {(action || secondaryAction) && (
            <div className="flex flex-col sm:flex-row gap-2 justify-center pt-2">
              {action && (
                <Button
                  onClick={action.onClick}
                  variant={action.variant || 'default'}
                >
                  {action.icon && <action.icon className="mr-2 h-4 w-4" />}
                  {action.label}
                </Button>
              )}
              {secondaryAction && (
                <Button
                  onClick={secondaryAction.onClick}
                  variant={secondaryAction.variant || 'outline'}
                >
                  {secondaryAction.icon && (
                    <secondaryAction.icon className="mr-2 h-4 w-4" />
                  )}
                  {secondaryAction.label}
                </Button>
              )}
            </div>
          )}
        </div>
      </div>
    )
  }
)
EmptyState.displayName = 'EmptyState'

// ========================================
// SPECIALIZED EMPTY STATES
// ========================================

export interface EmptySearchProps extends Omit<EmptyStateProps, 'preset'> {
  searchTerm?: string
  onClearSearch?: () => void
}

const EmptySearch = React.forwardRef<HTMLDivElement, EmptySearchProps>(
  ({ searchTerm, onClearSearch, ...props }, ref) => {
    return (
      <EmptyState
        ref={ref}
        preset="no-results"
        description={
          searchTerm
            ? `No results found for "${searchTerm}". Try adjusting your search.`
            : 'Try adjusting your search or filters to find what you are looking for.'
        }
        action={
          onClearSearch
            ? {
                label: 'Clear search',
                onClick: onClearSearch,
                variant: 'outline',
              }
            : undefined
        }
        {...props}
      />
    )
  }
)
EmptySearch.displayName = 'EmptySearch'

export interface EmptyListProps extends Omit<EmptyStateProps, 'preset'> {
  entityName?: string
  onCreate?: () => void
}

const EmptyList = React.forwardRef<HTMLDivElement, EmptyListProps>(
  ({ entityName = 'item', onCreate, ...props }, ref) => {
    return (
      <EmptyState
        ref={ref}
        preset="no-items"
        title={`No ${entityName}s yet`}
        description={`Get started by creating your first ${entityName}.`}
        action={
          onCreate
            ? {
                label: `Create ${entityName}`,
                onClick: onCreate,
              }
            : undefined
        }
        {...props}
      />
    )
  }
)
EmptyList.displayName = 'EmptyList'

export interface EmptyErrorProps extends Omit<EmptyStateProps, 'preset'> {
  error?: Error
  onRetry?: () => void
}

const EmptyError = React.forwardRef<HTMLDivElement, EmptyErrorProps>(
  ({ error, onRetry, ...props }, ref) => {
    return (
      <EmptyState
        ref={ref}
        preset="error"
        description={
          error?.message || 'An error occurred while loading the data. Please try again.'
        }
        action={
          onRetry
            ? {
                label: 'Try again',
                onClick: onRetry,
              }
            : undefined
        }
        {...props}
      />
    )
  }
)
EmptyError.displayName = 'EmptyError'

export {
  EmptyState,
  EmptySearch,
  EmptyList,
  EmptyError,
  emptyStateVariants,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Empty State

```typescript
import { EmptyState } from '@/components/ui/empty-state'

function BasicEmpty() {
  return (
    <EmptyState
      preset="no-data"
      action={{
        label: 'Refresh',
        onClick: () => console.log('Refresh clicked'),
      }}
    />
  )
}
```

### No Search Results

```typescript
import { EmptySearch } from '@/components/ui/empty-state'

function SearchResults() {
  const [searchTerm, setSearchTerm] = React.useState('test query')

  return (
    <EmptySearch
      searchTerm={searchTerm}
      onClearSearch={() => setSearchTerm('')}
    />
  )
}
```

### Empty List with Create Action

```typescript
import { EmptyList } from '@/components/ui/empty-state'
import { Plus } from 'lucide-react'

function ProjectsList() {
  const [projects, setProjects] = React.useState([])

  if (projects.length === 0) {
    return (
      <EmptyList
        entityName="project"
        onCreate={() => console.log('Create project')}
      />
    )
  }

  return <div>{/* Project list */}</div>
}
```

### Error State

```typescript
import { EmptyError } from '@/components/ui/empty-state'

function DataView() {
  const { data, error, refetch } = useQuery('data', fetchData)

  if (error) {
    return <EmptyError error={error} onRetry={refetch} />
  }

  return <div>{/* Data view */}</div>
}
```

### Custom Empty State

```typescript
import { EmptyState } from '@/components/ui/empty-state'
import { ShoppingCart } from 'lucide-react'

function EmptyCart() {
  return (
    <EmptyState
      icon={ShoppingCart}
      iconSize={80}
      title="Your cart is empty"
      description="Add items to your cart to get started with your order."
      action={{
        label: 'Continue shopping',
        onClick: () => router.push('/shop'),
      }}
    />
  )
}
```

### With Image

```typescript
function EmptyInbox() {
  return (
    <EmptyState
      image="/images/empty-inbox.svg"
      imageAlt="Empty inbox"
      title="All caught up!"
      description="You have no new messages. Enjoy your day!"
    />
  )
}
```

### Multiple Actions

```typescript
function EmptyTeam() {
  return (
    <EmptyState
      preset="no-users"
      title="No team members yet"
      description="Build your team by inviting members to collaborate."
      action={{
        label: 'Invite members',
        onClick: () => console.log('Invite'),
      }}
      secondaryAction={{
        label: 'Learn more',
        onClick: () => console.log('Learn more'),
        variant: 'ghost',
      }}
    />
  )
}
```

### Different Sizes

```typescript
function EmptySizes() {
  return (
    <div className="space-y-8">
      <EmptyState preset="no-data" size="sm" />
      <EmptyState preset="no-data" size="md" />
      <EmptyState preset="no-data" size="lg" />
    </div>
  )
}
```

### Conditional Rendering

```typescript
function UserList({ users }: { users: User[] }) {
  if (users.length === 0) {
    return (
      <EmptyState
        preset="no-users"
        action={{
          label: 'Add user',
          onClick: () => console.log('Add user'),
        }}
      />
    )
  }

  return (
    <div>
      {users.map((user) => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  )
}
```

### In Card Container

```typescript
function EmptyTasksCard() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Tasks</CardTitle>
      </CardHeader>
      <CardContent>
        <EmptyState
          preset="no-items"
          size="sm"
          title="No tasks"
          description="Create your first task to get started."
          action={{
            label: 'Add task',
            onClick: () => console.log('Add task'),
          }}
        />
      </CardContent>
    </Card>
  )
}
```

### All Presets

```typescript
function AllPresets() {
  return (
    <div className="space-y-8">
      <EmptyState preset="no-data" />
      <EmptyState preset="no-results" />
      <EmptyState preset="no-items" />
      <EmptyState preset="no-messages" />
      <EmptyState preset="no-users" />
      <EmptyState preset="no-events" />
      <EmptyState preset="error" />
      <EmptyState preset="no-access" />
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('EmptyState', () => {
  it('renders with preset', () => {
    render(<EmptyState preset="no-data" />)
    expect(screen.getByText('No data available')).toBeInTheDocument()
  })

  it('renders with custom title and description', () => {
    render(
      <EmptyState
        title="Custom title"
        description="Custom description"
      />
    )
    expect(screen.getByText('Custom title')).toBeInTheDocument()
    expect(screen.getByText('Custom description')).toBeInTheDocument()
  })

  it('renders action button', () => {
    const onClick = jest.fn()
    render(
      <EmptyState
        preset="no-data"
        action={{ label: 'Click me', onClick }}
      />
    )
    const button = screen.getByRole('button', { name: 'Click me' })
    fireEvent.click(button)
    expect(onClick).toHaveBeenCalled()
  })

  it('renders primary and secondary actions', () => {
    render(
      <EmptyState
        preset="no-data"
        action={{ label: 'Primary', onClick: jest.fn() }}
        secondaryAction={{ label: 'Secondary', onClick: jest.fn() }}
      />
    )
    expect(screen.getByText('Primary')).toBeInTheDocument()
    expect(screen.getByText('Secondary')).toBeInTheDocument()
  })

  it('renders image instead of icon', () => {
    render(
      <EmptyState
        image="/test.jpg"
        imageAlt="Test image"
        title="Test"
      />
    )
    const img = screen.getByRole('img', { name: 'Test image' })
    expect(img).toHaveAttribute('src', '/test.jpg')
  })

  it('applies size variants', () => {
    const { rerender } = render(<EmptyState preset="no-data" size="sm" />)
    expect(screen.getByText('No data available').closest('div')).toHaveClass('py-8')

    rerender(<EmptyState preset="no-data" size="lg" />)
    expect(screen.getByText('No data available').closest('div')).toHaveClass('py-16')
  })
})

describe('EmptySearch', () => {
  it('displays search term in description', () => {
    render(<EmptySearch searchTerm="test query" />)
    expect(screen.getByText(/No results found for "test query"/)).toBeInTheDocument()
  })

  it('calls onClearSearch when clear button is clicked', () => {
    const onClearSearch = jest.fn()
    render(<EmptySearch searchTerm="test" onClearSearch={onClearSearch} />)
    fireEvent.click(screen.getByRole('button', { name: 'Clear search' }))
    expect(onClearSearch).toHaveBeenCalled()
  })
})

describe('EmptyList', () => {
  it('displays entity name in title', () => {
    render(<EmptyList entityName="project" />)
    expect(screen.getByText('No projects yet')).toBeInTheDocument()
  })

  it('calls onCreate when create button is clicked', () => {
    const onCreate = jest.fn()
    render(<EmptyList entityName="task" onCreate={onCreate} />)
    fireEvent.click(screen.getByRole('button', { name: 'Create task' }))
    expect(onCreate).toHaveBeenCalled()
  })
})

describe('EmptyError', () => {
  it('displays error message', () => {
    const error = new Error('Test error')
    render(<EmptyError error={error} />)
    expect(screen.getByText('Test error')).toBeInTheDocument()
  })

  it('calls onRetry when retry button is clicked', () => {
    const onRetry = jest.fn()
    render(<EmptyError onRetry={onRetry} />)
    fireEvent.click(screen.getByRole('button', { name: 'Try again' }))
    expect(onRetry).toHaveBeenCalled()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML structure
- ✅ Proper heading hierarchy
- ✅ Alt text for images
- ✅ Button labels
- ✅ Color contrast compliance
- ✅ Keyboard navigation

---

## 🎨 STYLING NOTES

### Icon Colors
```typescript
// Icon uses muted-foreground for subtle appearance
className="text-muted-foreground"
```

### Responsive Layout
- Mobile: Stacked buttons
- Desktop: Horizontal buttons

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Lucide React: `npm install lucide-react`
- [ ] Create empty-state.tsx
- [ ] Implement base EmptyState component
- [ ] Create preset configurations
- [ ] Implement EmptySearch component
- [ ] Implement EmptyList component
- [ ] Implement EmptyError component
- [ ] Add support for images
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
