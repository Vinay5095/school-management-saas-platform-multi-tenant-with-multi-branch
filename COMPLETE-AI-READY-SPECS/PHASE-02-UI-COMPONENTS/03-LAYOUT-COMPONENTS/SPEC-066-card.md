# SPEC-066: Card Component
## Flexible Content Container with Variants

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 3 hours  
> **Dependencies**: None (Core Component)

---

## 📋 OVERVIEW

### Purpose
A versatile card component that serves as a container for grouping related content. Used extensively throughout the application for displaying information in an organized, visually appealing manner.

### Key Features
- ✅ Multiple visual variants
- ✅ Composable sub-components (Header, Content, Footer)
- ✅ Loading skeleton states
- ✅ Hover and interactive states
- ✅ Flexible padding options
- ✅ Image support
- ✅ Action buttons
- ✅ Badge/label overlays
- ✅ Clickable cards
- ✅ Dark mode support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/card.tsx
'use client'

import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// VARIANT DEFINITIONS
// ========================================

const cardVariants = cva(
  'rounded-lg transition-all duration-200',
  {
    variants: {
      variant: {
        default: 'bg-card text-card-foreground',
        bordered: 'border bg-card text-card-foreground',
        elevated: 'bg-card text-card-foreground shadow-lg hover:shadow-xl',
        ghost: 'bg-transparent',
        outline: 'border-2 border-primary bg-transparent',
      },
      padding: {
        none: '',
        sm: 'p-3',
        md: 'p-6',
        lg: 'p-8',
      },
    },
    defaultVariants: {
      variant: 'default',
      padding: 'md',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface CardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {
  /**
   * Whether the card is clickable
   */
  clickable?: boolean

  /**
   * Click handler for clickable cards
   */
  onClick?: () => void

  /**
   * Show loading skeleton
   */
  loading?: boolean

  /**
   * Disable card interactions
   */
  disabled?: boolean

  /**
   * Card content
   */
  children: React.ReactNode
}

export interface CardHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Header content
   */
  children: React.ReactNode
}

export interface CardTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {
  /**
   * Title text
   */
  children: React.ReactNode

  /**
   * Title size
   */
  size?: 'sm' | 'md' | 'lg'
}

export interface CardDescriptionProps extends React.HTMLAttributes<HTMLParagraphElement> {
  /**
   * Description text
   */
  children: React.ReactNode
}

export interface CardContentProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Content
   */
  children: React.ReactNode

  /**
   * Custom padding override
   */
  padding?: 'none' | 'sm' | 'md' | 'lg'
}

export interface CardFooterProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Footer content
   */
  children: React.ReactNode

  /**
   * Footer layout
   */
  justify?: 'start' | 'center' | 'end' | 'between'
}

export interface CardImageProps extends React.ImgHTMLAttributes<HTMLImageElement> {
  /**
   * Image source
   */
  src: string

  /**
   * Alt text
   */
  alt: string

  /**
   * Image position
   */
  position?: 'top' | 'bottom'

  /**
   * Image aspect ratio
   */
  aspectRatio?: 'auto' | 'square' | 'video' | 'wide'
}

// ========================================
// CARD COMPONENT
// ========================================

/**
 * Card Component
 * 
 * Main container component for grouping related content.
 * 
 * @example
 * <Card variant="bordered" padding="md">
 *   <CardHeader>
 *     <CardTitle>Card Title</CardTitle>
 *   </CardHeader>
 *   <CardContent>
 *     Content goes here
 *   </CardContent>
 * </Card>
 */
const Card = React.forwardRef<HTMLDivElement, CardProps>(
  (
    {
      className,
      variant,
      padding,
      clickable,
      onClick,
      loading,
      disabled,
      children,
      ...props
    },
    ref
  ) => {
    if (loading) {
      return (
        <div
          ref={ref}
          className={cn(
            cardVariants({ variant, padding }),
            'animate-pulse',
            className
          )}
          {...props}
        >
          <div className="space-y-3">
            <div className="h-4 bg-muted rounded w-3/4" />
            <div className="h-4 bg-muted rounded w-1/2" />
            <div className="h-20 bg-muted rounded" />
          </div>
        </div>
      )
    }

    return (
      <div
        ref={ref}
        className={cn(
          cardVariants({ variant, padding }),
          clickable && 'cursor-pointer hover:shadow-md active:scale-[0.98]',
          disabled && 'opacity-50 cursor-not-allowed pointer-events-none',
          className
        )}
        onClick={!disabled ? onClick : undefined}
        role={clickable ? 'button' : undefined}
        tabIndex={clickable && !disabled ? 0 : undefined}
        onKeyDown={
          clickable && !disabled
            ? (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault()
                  onClick?.()
                }
              }
            : undefined
        }
        {...props}
      >
        {children}
      </div>
    )
  }
)
Card.displayName = 'Card'

// ========================================
// CARD HEADER
// ========================================

/**
 * CardHeader Component
 * 
 * Container for card title and description.
 */
const CardHeader = React.forwardRef<HTMLDivElement, CardHeaderProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('flex flex-col space-y-1.5', className)}
        {...props}
      >
        {children}
      </div>
    )
  }
)
CardHeader.displayName = 'CardHeader'

// ========================================
// CARD TITLE
// ========================================

const cardTitleVariants = cva('font-semibold leading-none tracking-tight', {
  variants: {
    size: {
      sm: 'text-base',
      md: 'text-lg',
      lg: 'text-2xl',
    },
  },
  defaultVariants: {
    size: 'md',
  },
})

/**
 * CardTitle Component
 * 
 * Title text for the card.
 */
const CardTitle = React.forwardRef<HTMLHeadingElement, CardTitleProps>(
  ({ className, size, children, ...props }, ref) => {
    return (
      <h3
        ref={ref}
        className={cn(cardTitleVariants({ size }), className)}
        {...props}
      >
        {children}
      </h3>
    )
  }
)
CardTitle.displayName = 'CardTitle'

// ========================================
// CARD DESCRIPTION
// ========================================

/**
 * CardDescription Component
 * 
 * Description text for the card.
 */
const CardDescription = React.forwardRef<HTMLParagraphElement, CardDescriptionProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <p
        ref={ref}
        className={cn('text-sm text-muted-foreground', className)}
        {...props}
      >
        {children}
      </p>
    )
  }
)
CardDescription.displayName = 'CardDescription'

// ========================================
// CARD CONTENT
// ========================================

const contentPaddingMap = {
  none: '',
  sm: 'p-3',
  md: 'p-6',
  lg: 'p-8',
}

/**
 * CardContent Component
 * 
 * Main content area of the card.
 */
const CardContent = React.forwardRef<HTMLDivElement, CardContentProps>(
  ({ className, padding, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(padding && contentPaddingMap[padding], className)}
        {...props}
      >
        {children}
      </div>
    )
  }
)
CardContent.displayName = 'CardContent'

// ========================================
// CARD FOOTER
// ========================================

const footerJustifyMap = {
  start: 'justify-start',
  center: 'justify-center',
  end: 'justify-end',
  between: 'justify-between',
}

/**
 * CardFooter Component
 * 
 * Footer area for actions and additional information.
 */
const CardFooter = React.forwardRef<HTMLDivElement, CardFooterProps>(
  ({ className, justify = 'start', children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          'flex items-center gap-2',
          footerJustifyMap[justify],
          className
        )}
        {...props}
      >
        {children}
      </div>
    )
  }
)
CardFooter.displayName = 'CardFooter'

// ========================================
// CARD IMAGE
// ========================================

const aspectRatioMap = {
  auto: '',
  square: 'aspect-square',
  video: 'aspect-video',
  wide: 'aspect-[21/9]',
}

/**
 * CardImage Component
 * 
 * Image component for cards.
 */
const CardImage = React.forwardRef<HTMLImageElement, CardImageProps>(
  (
    { className, position = 'top', aspectRatio = 'auto', src, alt, ...props },
    ref
  ) => {
    return (
      <div
        className={cn(
          'overflow-hidden',
          position === 'top' && 'rounded-t-lg',
          position === 'bottom' && 'rounded-b-lg'
        )}
      >
        <img
          ref={ref}
          src={src}
          alt={alt}
          className={cn(
            'w-full object-cover',
            aspectRatioMap[aspectRatio],
            className
          )}
          {...props}
        />
      </div>
    )
  }
)
CardImage.displayName = 'CardImage'

// ========================================
// EXPORTS
// ========================================

export {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
  CardImage,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Card

```typescript
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'

function BasicCard() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Card Title</CardTitle>
        <CardDescription>Card description goes here</CardDescription>
      </CardHeader>
      <CardContent>
        <p>This is the main content of the card.</p>
      </CardContent>
      <CardFooter>
        <Button>Action</Button>
      </CardFooter>
    </Card>
  )
}
```

### Card Variants

```typescript
function CardVariants() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      <Card variant="default">
        <CardContent>Default Card</CardContent>
      </Card>

      <Card variant="bordered">
        <CardContent>Bordered Card</CardContent>
      </Card>

      <Card variant="elevated">
        <CardContent>Elevated Card with Shadow</CardContent>
      </Card>

      <Card variant="ghost">
        <CardContent>Ghost Card (Transparent)</CardContent>
      </Card>

      <Card variant="outline">
        <CardContent>Outline Card</CardContent>
      </Card>
    </div>
  )
}
```

### Clickable Card

```typescript
function ClickableCard() {
  const handleClick = () => {
    console.log('Card clicked!')
  }

  return (
    <Card variant="bordered" clickable onClick={handleClick}>
      <CardHeader>
        <CardTitle>Clickable Card</CardTitle>
        <CardDescription>Click anywhere on this card</CardDescription>
      </CardHeader>
      <CardContent>
        <p>This entire card is clickable.</p>
      </CardContent>
    </Card>
  )
}
```

### Card with Image

```typescript
import { CardImage } from '@/components/ui/card'

function ImageCard() {
  return (
    <Card variant="bordered" padding="none">
      <CardImage
        src="/images/product.jpg"
        alt="Product"
        aspectRatio="video"
      />
      <CardContent padding="md">
        <CardTitle>Product Name</CardTitle>
        <CardDescription>Product description goes here</CardDescription>
      </CardContent>
      <CardFooter justify="between" className="p-6 pt-0">
        <span className="text-2xl font-bold">$99.99</span>
        <Button>Add to Cart</Button>
      </CardFooter>
    </Card>
  )
}
```

### Dashboard Stats Card

```typescript
import { TrendingUp, Users } from 'lucide-react'

function StatsCard() {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle size="sm">Total Users</CardTitle>
        <Users className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">45,231</div>
        <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
          <TrendingUp className="h-3 w-3 text-green-500" />
          <span className="text-green-500">+20.1%</span> from last month
        </p>
      </CardContent>
    </Card>
  )
}
```

### Loading State

```typescript
function LoadingCard() {
  const [isLoading, setIsLoading] = React.useState(true)

  React.useEffect(() => {
    setTimeout(() => setIsLoading(false), 2000)
  }, [])

  return (
    <Card loading={isLoading}>
      <CardHeader>
        <CardTitle>Data Card</CardTitle>
      </CardHeader>
      <CardContent>
        <p>This content will appear after loading.</p>
      </CardContent>
    </Card>
  )
}
```

### Complex Card with Multiple Sections

```typescript
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'

function UserProfileCard() {
  return (
    <Card variant="bordered">
      <CardImage
        src="/images/cover.jpg"
        alt="Cover"
        aspectRatio="wide"
      />
      <CardContent className="relative">
        {/* Avatar overlay */}
        <Avatar className="absolute -top-12 left-6 h-24 w-24 border-4 border-background">
          <AvatarImage src="/images/avatar.jpg" />
          <AvatarFallback>JD</AvatarFallback>
        </Avatar>

        {/* Profile info */}
        <div className="pt-14">
          <div className="flex items-start justify-between">
            <div>
              <CardTitle>John Doe</CardTitle>
              <CardDescription>@johndoe</CardDescription>
            </div>
            <Badge>Premium</Badge>
          </div>

          <p className="mt-4 text-sm">
            Full-stack developer passionate about building great user experiences.
          </p>

          {/* Stats */}
          <div className="flex gap-6 mt-4">
            <div>
              <div className="font-semibold">1,234</div>
              <div className="text-xs text-muted-foreground">Following</div>
            </div>
            <div>
              <div className="font-semibold">5,678</div>
              <div className="text-xs text-muted-foreground">Followers</div>
            </div>
          </div>
        </div>
      </CardContent>
      <CardFooter justify="between">
        <Button variant="outline">Message</Button>
        <Button>Follow</Button>
      </CardFooter>
    </Card>
  )
}
```

---

## 🧪 TESTING

### Test Suite

```typescript
// src/components/ui/__tests__/card.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from '../card'

describe('Card', () => {
  it('renders card with content', () => {
    render(
      <Card>
        <CardContent>Test content</CardContent>
      </Card>
    )
    expect(screen.getByText('Test content')).toBeInTheDocument()
  })

  it('applies variant styles', () => {
    const { container } = render(<Card variant="bordered">Content</Card>)
    expect(container.firstChild).toHaveClass('border')
  })

  it('handles click events when clickable', () => {
    const handleClick = jest.fn()
    render(
      <Card clickable onClick={handleClick}>
        <CardContent>Clickable</CardContent>
      </Card>
    )

    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('handles keyboard events when clickable', () => {
    const handleClick = jest.fn()
    render(
      <Card clickable onClick={handleClick}>
        <CardContent>Clickable</CardContent>
      </Card>
    )

    const card = screen.getByRole('button')
    fireEvent.keyDown(card, { key: 'Enter' })
    expect(handleClick).toHaveBeenCalledTimes(1)

    fireEvent.keyDown(card, { key: ' ' })
    expect(handleClick).toHaveBeenCalledTimes(2)
  })

  it('displays loading skeleton', () => {
    const { container } = render(<Card loading />)
    expect(container.querySelector('.animate-pulse')).toBeInTheDocument()
  })

  it('disables interactions when disabled', () => {
    const handleClick = jest.fn()
    render(
      <Card clickable onClick={handleClick} disabled>
        <CardContent>Disabled</CardContent>
      </Card>
    )

    const card = screen.getByText('Disabled').parentElement
    expect(card).toHaveClass('opacity-50', 'cursor-not-allowed')
  })

  it('renders all sub-components', () => {
    render(
      <Card>
        <CardHeader>
          <CardTitle>Title</CardTitle>
          <CardDescription>Description</CardDescription>
        </CardHeader>
        <CardContent>Content</CardContent>
        <CardFooter>Footer</CardFooter>
      </Card>
    )

    expect(screen.getByText('Title')).toBeInTheDocument()
    expect(screen.getByText('Description')).toBeInTheDocument()
    expect(screen.getByText('Content')).toBeInTheDocument()
    expect(screen.getByText('Footer')).toBeInTheDocument()
  })

  it('applies custom padding', () => {
    const { container } = render(<Card padding="lg">Content</Card>)
    expect(container.firstChild).toHaveClass('p-8')
  })
})
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Proper semantic HTML structure
- ✅ Keyboard navigation for clickable cards
- ✅ Focus indicators
- ✅ ARIA roles when interactive
- ✅ Sufficient color contrast

### Best Practices
- Use semantic heading levels in CardTitle
- Provide alt text for CardImage
- Ensure clickable cards are keyboard accessible
- Use proper button elements in CardFooter

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create card.tsx file
- [ ] Implement Card component with variants
- [ ] Implement CardHeader component
- [ ] Implement CardTitle component
- [ ] Implement CardDescription component
- [ ] Implement CardContent component
- [ ] Implement CardFooter component
- [ ] Implement CardImage component
- [ ] Add CVA variants for styling
- [ ] Implement loading skeleton state
- [ ] Add clickable card functionality
- [ ] Implement keyboard navigation
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Create Storybook stories
- [ ] Document usage patterns

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
