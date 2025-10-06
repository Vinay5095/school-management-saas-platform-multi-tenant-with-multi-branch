# SPEC-089: Avatar Component
## User Profile Images with Fallbacks

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 3 hours  
> **Dependencies**: Radix UI Avatar

---

## 📋 OVERVIEW

### Purpose
A robust avatar component for displaying user profile images with automatic fallbacks, status indicators, and grouping capabilities.

### Key Features
- ✅ Image with automatic fallback to initials
- ✅ Multiple sizes
- ✅ Status indicators (online, offline, away, busy)
- ✅ Avatar groups with overlap
- ✅ Circular and rounded variants
- ✅ Loading states
- ✅ Accessibility
- ✅ Radix UI Avatar integration

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/avatar.tsx
import * as React from 'react'
import * as AvatarPrimitive from '@radix-ui/react-avatar'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

const avatarVariants = cva(
  'relative flex shrink-0 overflow-hidden',
  {
    variants: {
      size: {
        xs: 'h-6 w-6 text-[10px]',
        sm: 'h-8 w-8 text-xs',
        md: 'h-10 w-10 text-sm',
        lg: 'h-12 w-12 text-base',
        xl: 'h-16 w-16 text-lg',
        '2xl': 'h-20 w-20 text-xl',
      },
      shape: {
        circle: 'rounded-full',
        rounded: 'rounded-md',
        square: 'rounded-none',
      },
    },
    defaultVariants: {
      size: 'md',
      shape: 'circle',
    },
  }
)

export type AvatarStatus = 'online' | 'offline' | 'away' | 'busy' | 'dnd'

export interface AvatarProps
  extends React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Root>,
    VariantProps<typeof avatarVariants> {
  /**
   * Image source URL
   */
  src?: string

  /**
   * Alt text for image
   */
  alt?: string

  /**
   * Fallback text (initials)
   */
  fallback?: string

  /**
   * Status indicator
   */
  status?: AvatarStatus

  /**
   * Show status indicator
   */
  showStatus?: boolean

  /**
   * Custom status position
   */
  statusPosition?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
}

// ========================================
// AVATAR COMPONENT
// ========================================

const Avatar = React.forwardRef<
  React.ElementRef<typeof AvatarPrimitive.Root>,
  AvatarProps
>(({ 
  className, 
  size, 
  shape, 
  src, 
  alt, 
  fallback, 
  status, 
  showStatus,
  statusPosition = 'bottom-right',
  ...props 
}, ref) => {
  const statusColors: Record<AvatarStatus, string> = {
    online: 'bg-green-500',
    offline: 'bg-gray-400',
    away: 'bg-yellow-500',
    busy: 'bg-red-500',
    dnd: 'bg-red-500',
  }

  const statusPositionClasses: Record<string, string> = {
    'top-right': 'top-0 right-0',
    'top-left': 'top-0 left-0',
    'bottom-right': 'bottom-0 right-0',
    'bottom-left': 'bottom-0 left-0',
  }

  const statusSizeClasses: Record<string, string> = {
    xs: 'h-1.5 w-1.5 ring-1',
    sm: 'h-2 w-2 ring-1',
    md: 'h-2.5 w-2.5 ring-2',
    lg: 'h-3 w-3 ring-2',
    xl: 'h-3.5 w-3.5 ring-2',
    '2xl': 'h-4 w-4 ring-2',
  }

  return (
    <AvatarPrimitive.Root
      ref={ref}
      className={cn(avatarVariants({ size, shape }), className)}
      {...props}
    >
      <AvatarImage src={src} alt={alt} />
      <AvatarFallback>{fallback}</AvatarFallback>
      
      {showStatus && status && (
        <span
          className={cn(
            'absolute rounded-full ring-background',
            statusColors[status],
            statusPositionClasses[statusPosition],
            statusSizeClasses[size || 'md']
          )}
          aria-label={`Status: ${status}`}
        />
      )}
    </AvatarPrimitive.Root>
  )
})
Avatar.displayName = 'Avatar'

// ========================================
// AVATAR IMAGE
// ========================================

const AvatarImage = React.forwardRef<
  React.ElementRef<typeof AvatarPrimitive.Image>,
  React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Image>
>(({ className, ...props }, ref) => (
  <AvatarPrimitive.Image
    ref={ref}
    className={cn('aspect-square h-full w-full object-cover', className)}
    {...props}
  />
))
AvatarImage.displayName = AvatarPrimitive.Image.displayName

// ========================================
// AVATAR FALLBACK
// ========================================

const AvatarFallback = React.forwardRef<
  React.ElementRef<typeof AvatarPrimitive.Fallback>,
  React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Fallback>
>(({ className, ...props }, ref) => (
  <AvatarPrimitive.Fallback
    ref={ref}
    className={cn(
      'flex h-full w-full items-center justify-center bg-muted font-medium text-muted-foreground',
      className
    )}
    {...props}
  />
))
AvatarFallback.displayName = AvatarPrimitive.Fallback.displayName

// ========================================
// AVATAR GROUP
// ========================================

export interface AvatarGroupProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Maximum avatars to show
   */
  max?: number

  /**
   * Avatar size
   */
  size?: VariantProps<typeof avatarVariants>['size']

  /**
   * Spacing (overlap amount)
   */
  spacing?: 'tight' | 'normal' | 'loose'

  /**
   * Avatar items
   */
  avatars: Array<{
    src?: string
    alt?: string
    fallback?: string
    status?: AvatarStatus
  }>
}

const AvatarGroup = React.forwardRef<HTMLDivElement, AvatarGroupProps>(
  ({ className, max = 5, size = 'md', spacing = 'normal', avatars, ...props }, ref) => {
    const spacingClasses = {
      tight: '-space-x-4',
      normal: '-space-x-2',
      loose: '-space-x-1',
    }

    const visibleAvatars = avatars.slice(0, max)
    const remainingCount = Math.max(0, avatars.length - max)

    return (
      <div
        ref={ref}
        className={cn('flex items-center', spacingClasses[spacing], className)}
        {...props}
      >
        {visibleAvatars.map((avatar, index) => (
          <Avatar
            key={index}
            src={avatar.src}
            alt={avatar.alt}
            fallback={avatar.fallback}
            status={avatar.status}
            size={size}
            className="ring-2 ring-background hover:z-10"
          />
        ))}
        
        {remainingCount > 0 && (
          <Avatar
            fallback={`+${remainingCount}`}
            size={size}
            className="ring-2 ring-background bg-muted"
          />
        )}
      </div>
    )
  }
)
AvatarGroup.displayName = 'AvatarGroup'

// ========================================
// UTILITY FUNCTIONS
// ========================================

/**
 * Generate initials from name
 */
export function getInitials(name: string, maxLength: number = 2): string {
  if (!name) return '??'

  const parts = name.trim().split(/\s+/)
  
  if (parts.length === 1) {
    return parts[0].slice(0, maxLength).toUpperCase()
  }

  return parts
    .slice(0, maxLength)
    .map(part => part[0])
    .join('')
    .toUpperCase()
}

/**
 * Generate avatar background color from string
 */
export function getAvatarColor(str: string): string {
  const colors = [
    'bg-red-500',
    'bg-orange-500',
    'bg-amber-500',
    'bg-yellow-500',
    'bg-lime-500',
    'bg-green-500',
    'bg-emerald-500',
    'bg-teal-500',
    'bg-cyan-500',
    'bg-sky-500',
    'bg-blue-500',
    'bg-indigo-500',
    'bg-violet-500',
    'bg-purple-500',
    'bg-fuchsia-500',
    'bg-pink-500',
    'bg-rose-500',
  ]

  let hash = 0
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash)
  }

  return colors[Math.abs(hash) % colors.length]
}

export { Avatar, AvatarImage, AvatarFallback, AvatarGroup, avatarVariants }
```

---

## 📚 USAGE EXAMPLES

### Basic Avatar

```typescript
import { Avatar } from '@/components/ui/avatar'

function BasicAvatar() {
  return (
    <Avatar
      src="/avatars/user.jpg"
      alt="John Doe"
      fallback="JD"
    />
  )
}
```

### Different Sizes

```typescript
function AvatarSizes() {
  return (
    <div className="flex items-center gap-4">
      <Avatar size="xs" fallback="XS" />
      <Avatar size="sm" fallback="SM" />
      <Avatar size="md" fallback="MD" />
      <Avatar size="lg" fallback="LG" />
      <Avatar size="xl" fallback="XL" />
      <Avatar size="2xl" fallback="2XL" />
    </div>
  )
}
```

### With Status Indicators

```typescript
function AvatarWithStatus() {
  return (
    <div className="flex gap-4">
      <Avatar
        src="/avatars/user1.jpg"
        fallback="JD"
        status="online"
        showStatus
      />
      <Avatar
        src="/avatars/user2.jpg"
        fallback="JS"
        status="away"
        showStatus
      />
      <Avatar
        src="/avatars/user3.jpg"
        fallback="AB"
        status="busy"
        showStatus
      />
      <Avatar
        src="/avatars/user4.jpg"
        fallback="CD"
        status="offline"
        showStatus
      />
    </div>
  )
}
```

### Different Shapes

```typescript
function AvatarShapes() {
  return (
    <div className="flex gap-4">
      <Avatar shape="circle" fallback="CR" />
      <Avatar shape="rounded" fallback="RD" />
      <Avatar shape="square" fallback="SQ" />
    </div>
  )
}
```

### Avatar Group

```typescript
import { AvatarGroup, getInitials } from '@/components/ui/avatar'

function TeamAvatars() {
  const team = [
    { name: 'John Doe', src: '/avatars/john.jpg' },
    { name: 'Jane Smith', src: '/avatars/jane.jpg' },
    { name: 'Bob Johnson', src: '/avatars/bob.jpg' },
    { name: 'Alice Brown', src: '/avatars/alice.jpg' },
    { name: 'Charlie Wilson', src: '/avatars/charlie.jpg' },
    { name: 'David Lee', src: '/avatars/david.jpg' },
  ]

  const avatars = team.map(member => ({
    src: member.src,
    alt: member.name,
    fallback: getInitials(member.name),
  }))

  return (
    <AvatarGroup
      avatars={avatars}
      max={5}
      size="md"
      spacing="normal"
    />
  )
}
```

### With Auto-Generated Initials

```typescript
import { Avatar, getInitials } from '@/components/ui/avatar'

function UserAvatar({ user }: { user: { name: string; avatar?: string } }) {
  return (
    <Avatar
      src={user.avatar}
      alt={user.name}
      fallback={getInitials(user.name)}
    />
  )
}
```

### With Color Background

```typescript
import { Avatar, getInitials, getAvatarColor } from '@/components/ui/avatar'

function ColoredAvatar({ name }: { name: string }) {
  const initials = getInitials(name)
  const colorClass = getAvatarColor(name)

  return (
    <Avatar
      fallback={initials}
      className={cn(colorClass, 'text-white')}
    />
  )
}
```

### Loading State

```typescript
function AvatarLoading() {
  return (
    <Avatar className="animate-pulse bg-muted">
      <div className="h-full w-full bg-muted" />
    </Avatar>
  )
}
```

### Interactive Avatar

```typescript
function InteractiveAvatar() {
  return (
    <button className="group">
      <Avatar
        src="/avatars/user.jpg"
        fallback="JD"
        className="transition-transform group-hover:scale-110"
      />
    </button>
  )
}
```

### Avatar with Dropdown

```typescript
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

function AvatarDropdown() {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="rounded-full">
          <Avatar
            src="/avatars/user.jpg"
            fallback="JD"
            status="online"
            showStatus
          />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem>Profile</DropdownMenuItem>
        <DropdownMenuItem>Settings</DropdownMenuItem>
        <DropdownMenuItem>Logout</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Avatar', () => {
  it('renders with image', () => {
    render(
      <Avatar src="/test.jpg" alt="Test User" fallback="TU" />
    )
    expect(screen.getByRole('img')).toHaveAttribute('src', '/test.jpg')
  })

  it('shows fallback when image fails', async () => {
    render(<Avatar src="/invalid.jpg" fallback="TU" />)
    
    // Trigger image error
    const img = screen.getByRole('img')
    fireEvent.error(img)
    
    await waitFor(() => {
      expect(screen.getByText('TU')).toBeInTheDocument()
    })
  })

  it('renders with status indicator', () => {
    render(
      <Avatar fallback="JD" status="online" showStatus />
    )
    expect(screen.getByLabelText('Status: online')).toBeInTheDocument()
  })

  it('applies correct size classes', () => {
    const { rerender } = render(<Avatar size="sm" fallback="SM" />)
    expect(screen.getByText('SM').parentElement).toHaveClass('h-8', 'w-8')

    rerender(<Avatar size="lg" fallback="LG" />)
    expect(screen.getByText('LG').parentElement).toHaveClass('h-12', 'w-12')
  })

  it('applies correct shape', () => {
    const { rerender } = render(<Avatar shape="circle" fallback="CR" />)
    expect(screen.getByText('CR').parentElement).toHaveClass('rounded-full')

    rerender(<Avatar shape="square" fallback="SQ" />)
    expect(screen.getByText('SQ').parentElement).toHaveClass('rounded-none')
  })
})

describe('AvatarGroup', () => {
  const avatars = [
    { fallback: 'A1' },
    { fallback: 'A2' },
    { fallback: 'A3' },
    { fallback: 'A4' },
    { fallback: 'A5' },
    { fallback: 'A6' },
  ]

  it('renders all avatars when under max', () => {
    render(<AvatarGroup avatars={avatars.slice(0, 3)} max={5} />)
    expect(screen.getByText('A1')).toBeInTheDocument()
    expect(screen.getByText('A2')).toBeInTheDocument()
    expect(screen.getByText('A3')).toBeInTheDocument()
  })

  it('shows overflow count when exceeding max', () => {
    render(<AvatarGroup avatars={avatars} max={3} />)
    expect(screen.getByText('A1')).toBeInTheDocument()
    expect(screen.getByText('A2')).toBeInTheDocument()
    expect(screen.getByText('A3')).toBeInTheDocument()
    expect(screen.getByText('+3')).toBeInTheDocument()
  })
})

describe('getInitials', () => {
  it('generates initials from name', () => {
    expect(getInitials('John Doe')).toBe('JD')
    expect(getInitials('Alice Bob Charlie')).toBe('AB')
    expect(getInitials('Single')).toBe('SI')
  })

  it('handles edge cases', () => {
    expect(getInitials('')).toBe('??')
    expect(getInitials('  ')).toBe('??')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Proper alt text for images
- ✅ Fallback text for screen readers
- ✅ Status indicator labels
- ✅ Keyboard navigation support
- ✅ Focus indicators
- ✅ ARIA attributes

---

## 🎨 STYLING NOTES

### Status Colors
```css
--status-online: hsl(142 71% 45%)    /* Green */
--status-away: hsl(48 96% 53%)       /* Yellow */
--status-busy: hsl(0 84% 60%)        /* Red */
--status-offline: hsl(0 0% 60%)      /* Gray */
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Radix UI Avatar: `npm install @radix-ui/react-avatar`
- [ ] Create avatar.tsx
- [ ] Implement size variants
- [ ] Implement shape variants
- [ ] Add status indicators
- [ ] Create AvatarGroup component
- [ ] Add utility functions (getInitials, getAvatarColor)
- [ ] Write comprehensive tests
- [ ] Test image loading and fallback
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~2KB
- **With Radix UI**: ~4KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
