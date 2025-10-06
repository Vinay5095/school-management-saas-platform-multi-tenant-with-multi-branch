# SPEC-072: Separator Component
## Visual Dividing Line with Radix UI

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: LOW  
> **Estimated Time**: 1 hour  
> **Dependencies**: Radix UI Separator

---

## 📋 OVERVIEW

### Purpose
A separator component that visually divides content sections with a horizontal or vertical line.

### Key Features
- ✅ Horizontal and vertical orientations
- ✅ Decorative or semantic
- ✅ Custom styling
- ✅ Accessible
- ✅ Dark mode support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Implementation

```typescript
// src/components/ui/separator.tsx
'use client'

import * as React from 'react'
import * as SeparatorPrimitive from '@radix-ui/react-separator'
import { cn } from '@/lib/utils'

export interface SeparatorProps
  extends React.ComponentPropsWithoutRef<typeof SeparatorPrimitive.Root> {
  /**
   * Orientation of the separator
   */
  orientation?: 'horizontal' | 'vertical'

  /**
   * Whether the separator is decorative (no semantic meaning)
   */
  decorative?: boolean
}

const Separator = React.forwardRef<
  React.ElementRef<typeof SeparatorPrimitive.Root>,
  SeparatorProps
>(
  (
    { className, orientation = 'horizontal', decorative = true, ...props },
    ref
  ) => (
    <SeparatorPrimitive.Root
      ref={ref}
      decorative={decorative}
      orientation={orientation}
      className={cn(
        'shrink-0 bg-border',
        orientation === 'horizontal' ? 'h-[1px] w-full' : 'h-full w-[1px]',
        className
      )}
      {...props}
    />
  )
)
Separator.displayName = SeparatorPrimitive.Root.displayName

export { Separator }
```

---

## 📚 USAGE EXAMPLES

### Basic Horizontal Separator

```typescript
import { Separator } from '@/components/ui/separator'

function HorizontalExample() {
  return (
    <div className="space-y-4">
      <div>
        <h4 className="text-sm font-medium">Radix Primitives</h4>
        <p className="text-sm text-muted-foreground">
          An open-source UI component library.
        </p>
      </div>
      <Separator />
      <div>
        <h4 className="text-sm font-medium">Next.js</h4>
        <p className="text-sm text-muted-foreground">
          The React Framework for the Web.
        </p>
      </div>
    </div>
  )
}
```

### Vertical Separator

```typescript
function VerticalExample() {
  return (
    <div className="flex h-5 items-center space-x-4 text-sm">
      <div>Blog</div>
      <Separator orientation="vertical" />
      <div>Docs</div>
      <Separator orientation="vertical" />
      <div>Source</div>
    </div>
  )
}
```

### In Navigation

```typescript
function NavigationExample() {
  return (
    <nav className="flex items-center space-x-4">
      <a href="/" className="text-sm font-medium">Home</a>
      <Separator orientation="vertical" className="h-4" />
      <a href="/about" className="text-sm font-medium">About</a>
      <Separator orientation="vertical" className="h-4" />
      <a href="/contact" className="text-sm font-medium">Contact</a>
    </nav>
  )
}
```

### With Custom Styling

```typescript
function StyledSeparator() {
  return (
    <div className="space-y-4">
      {/* Thick separator */}
      <Separator className="h-1" />
      
      {/* Colored separator */}
      <Separator className="bg-primary" />
      
      {/* Dashed separator */}
      <Separator className="border-t border-dashed bg-transparent" />
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Separator', () => {
  it('renders horizontal separator', () => {
    const { container } = render(<Separator />)
    const separator = container.firstChild
    expect(separator).toHaveClass('h-[1px]', 'w-full')
  })

  it('renders vertical separator', () => {
    const { container } = render(<Separator orientation="vertical" />)
    const separator = container.firstChild
    expect(separator).toHaveClass('h-full', 'w-[1px]')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Uses proper ARIA separator role
- ✅ Decorative by default (hidden from screen readers)
- ✅ Can be made semantic when needed

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-separator
- [ ] Create separator.tsx
- [ ] Write tests
- [ ] Create examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
