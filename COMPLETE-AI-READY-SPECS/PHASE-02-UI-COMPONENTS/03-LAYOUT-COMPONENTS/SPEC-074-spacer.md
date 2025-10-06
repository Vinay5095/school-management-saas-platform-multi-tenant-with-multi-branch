# SPEC-074: Spacer Component
## Responsive Spacing Utility

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: LOW  
> **Estimated Time**: 1 hour  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
A simple spacing utility component for adding consistent vertical or horizontal space between elements.

### Key Features
- ✅ Multiple size options
- ✅ Horizontal and vertical spacing
- ✅ Responsive sizes
- ✅ Accessible (hidden from screen readers)

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Implementation

```typescript
// src/components/ui/spacer.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const spacerVariants = cva('shrink-0', {
  variants: {
    size: {
      xs: 'h-2',
      sm: 'h-4',
      md: 'h-6',
      lg: 'h-8',
      xl: 'h-12',
      '2xl': 'h-16',
      '3xl': 'h-24',
    },
    axis: {
      horizontal: 'w-full',
      vertical: 'h-full w-auto',
    },
  },
  defaultVariants: {
    size: 'md',
    axis: 'horizontal',
  },
})

export interface SpacerProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof spacerVariants> {}

const Spacer = React.forwardRef<HTMLDivElement, SpacerProps>(
  ({ className, size, axis, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(spacerVariants({ size, axis }), className)}
      aria-hidden="true"
      {...props}
    />
  )
)
Spacer.displayName = 'Spacer'

export { Spacer, spacerVariants }
```

---

## 📚 USAGE EXAMPLES

### Basic Usage

```typescript
import { Spacer } from '@/components/ui/spacer'

function BasicSpacer() {
  return (
    <div>
      <p>First paragraph</p>
      <Spacer size="lg" />
      <p>Second paragraph with large space above</p>
    </div>
  )
}
```

### Different Sizes

```typescript
function SizeVariants() {
  return (
    <div>
      <h3>Extra Small</h3>
      <Spacer size="xs" />
      
      <h3>Small</h3>
      <Spacer size="sm" />
      
      <h3>Medium</h3>
      <Spacer size="md" />
      
      <h3>Large</h3>
      <Spacer size="lg" />
      
      <h3>Extra Large</h3>
      <Spacer size="xl" />
      
      <h3>2XL</h3>
      <Spacer size="2xl" />
      
      <h3>3XL</h3>
      <Spacer size="3xl" />
      
      <h3>Bottom</h3>
    </div>
  )
}
```

### In Form Layout

```typescript
function FormWithSpacers() {
  return (
    <form className="max-w-md">
      <h2>Contact Form</h2>
      <Spacer size="lg" />
      
      <FormField name="name" label="Name" />
      <Spacer size="md" />
      
      <FormField name="email" label="Email" />
      <Spacer size="md" />
      
      <FormField name="message" type="textarea" label="Message" />
      <Spacer size="xl" />
      
      <Button type="submit">Submit</Button>
    </form>
  )
}
```

### Responsive Spacing

```typescript
function ResponsiveSpacer() {
  return (
    <div>
      <h2>Heading</h2>
      {/* Small on mobile, large on desktop */}
      <Spacer className="h-4 md:h-12" />
      <p>Content with responsive spacing</p>
    </div>
  )
}
```

### In Card Layout

```typescript
function CardWithSpacing() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Dashboard</CardTitle>
        <CardDescription>Welcome back!</CardDescription>
      </CardHeader>
      
      <Spacer size="sm" />
      
      <CardContent>
        <div className="grid grid-cols-3 gap-4">
          <StatsCard title="Users" value="1,234" />
          <StatsCard title="Revenue" value="$45K" />
          <StatsCard title="Orders" value="892" />
        </div>
        
        <Spacer size="lg" />
        
        <div>
          <h3 className="font-semibold mb-2">Recent Activity</h3>
          <ActivityList />
        </div>
      </CardContent>
    </Card>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Spacer', () => {
  it('renders with default size', () => {
    const { container } = render(<Spacer />)
    expect(container.firstChild).toHaveClass('h-6')
  })

  it('applies size variant', () => {
    const { container } = render(<Spacer size="xl" />)
    expect(container.firstChild).toHaveClass('h-12')
  })

  it('is hidden from screen readers', () => {
    const { container } = render(<Spacer />)
    expect(container.firstChild).toHaveAttribute('aria-hidden', 'true')
  })
})
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create spacer.tsx
- [ ] Implement size variants
- [ ] Add CVA styling
- [ ] Write tests
- [ ] Create examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
