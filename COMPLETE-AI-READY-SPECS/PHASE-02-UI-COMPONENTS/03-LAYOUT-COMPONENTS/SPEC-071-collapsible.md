# SPEC-071: Collapsible Component
## Simple Content Show/Hide with Radix UI

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: LOW  
> **Estimated Time**: 2 hours  
> **Dependencies**: Radix UI Collapsible

---

## 📋 OVERVIEW

### Purpose
A collapsible component for showing and hiding content with smooth animations. Simpler than Accordion, ideal for single expandable sections.

### Key Features
- ✅ Show/hide content
- ✅ Smooth animations
- ✅ Controlled and uncontrolled modes
- ✅ Custom trigger element
- ✅ Keyboard accessible
- ✅ Disabled state
- ✅ Animation callbacks
- ✅ Full accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/collapsible.tsx
'use client'

import * as React from 'react'
import * as CollapsiblePrimitive from '@radix-ui/react-collapsible'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface CollapsibleProps
  extends React.ComponentPropsWithoutRef<typeof CollapsiblePrimitive.Root> {
  /**
   * Whether the collapsible is open (controlled)
   */
  open?: boolean

  /**
   * Default open state (uncontrolled)
   */
  defaultOpen?: boolean

  /**
   * Callback when open state changes
   */
  onOpenChange?: (open: boolean) => void

  /**
   * Disable the collapsible
   */
  disabled?: boolean

  /**
   * Children components
   */
  children: React.ReactNode
}

export interface CollapsibleTriggerProps
  extends React.ComponentPropsWithoutRef<typeof CollapsiblePrimitive.Trigger> {
  /**
   * Trigger content
   */
  children: React.ReactNode
}

export interface CollapsibleContentProps
  extends React.ComponentPropsWithoutRef<typeof CollapsiblePrimitive.Content> {
  /**
   * Content to show/hide
   */
  children: React.ReactNode
}

// ========================================
// COLLAPSIBLE ROOT
// ========================================

/**
 * Collapsible Component
 * 
 * Root collapsible container.
 * 
 * @example
 * <Collapsible>
 *   <CollapsibleTrigger>Toggle</CollapsibleTrigger>
 *   <CollapsibleContent>Content here</CollapsibleContent>
 * </Collapsible>
 */
const Collapsible = CollapsiblePrimitive.Root

// ========================================
// COLLAPSIBLE TRIGGER
// ========================================

/**
 * CollapsibleTrigger Component
 * 
 * Button that toggles the collapsible.
 */
const CollapsibleTrigger = CollapsiblePrimitive.CollapsibleTrigger

// ========================================
// COLLAPSIBLE CONTENT
// ========================================

/**
 * CollapsibleContent Component
 * 
 * Content that expands/collapses.
 */
const CollapsibleContent = React.forwardRef<
  React.ElementRef<typeof CollapsiblePrimitive.Content>,
  CollapsibleContentProps
>(({ className, children, ...props }, ref) => (
  <CollapsiblePrimitive.Content
    ref={ref}
    className={cn(
      'overflow-hidden transition-all',
      'data-[state=closed]:animate-collapsible-up data-[state=open]:animate-collapsible-down',
      className
    )}
    {...props}
  >
    {children}
  </CollapsiblePrimitive.Content>
))
CollapsibleContent.displayName = CollapsiblePrimitive.Content.displayName

// ========================================
// EXPORTS
// ========================================

export { Collapsible, CollapsibleTrigger, CollapsibleContent }
```

### Animations (tailwind.config.ts)

```typescript
// Add to tailwind.config.ts
module.exports = {
  theme: {
    extend: {
      keyframes: {
        'collapsible-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-collapsible-content-height)' },
        },
        'collapsible-up': {
          from: { height: 'var(--radix-collapsible-content-height)' },
          to: { height: '0' },
        },
      },
      animation: {
        'collapsible-down': 'collapsible-down 0.2s ease-out',
        'collapsible-up': 'collapsible-up 0.2s ease-out',
      },
    },
  },
}
```

---

## 📚 USAGE EXAMPLES

### Basic Collapsible

```typescript
import {
  Collapsible,
  CollapsibleTrigger,
  CollapsibleContent,
} from '@/components/ui/collapsible'
import { Button } from '@/components/ui/button'

function BasicCollapsible() {
  return (
    <Collapsible>
      <CollapsibleTrigger asChild>
        <Button variant="outline">Toggle Content</Button>
      </CollapsibleTrigger>
      <CollapsibleContent>
        <div className="rounded-md border p-4 mt-2">
          This content can be toggled open and closed.
        </div>
      </CollapsibleContent>
    </Collapsible>
  )
}
```

### Controlled Collapsible

```typescript
function ControlledCollapsible() {
  const [isOpen, setIsOpen] = React.useState(false)

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <Button onClick={() => setIsOpen(true)}>Open</Button>
        <Button onClick={() => setIsOpen(false)}>Close</Button>
        <Button onClick={() => setIsOpen(!isOpen)}>Toggle</Button>
      </div>

      <Collapsible open={isOpen} onOpenChange={setIsOpen}>
        <CollapsibleTrigger asChild>
          <Button variant="outline">
            {isOpen ? 'Hide' : 'Show'} Content
          </Button>
        </CollapsibleTrigger>
        <CollapsibleContent>
          <div className="rounded-md border p-4 mt-2">
            Controlled content here
          </div>
        </CollapsibleContent>
      </Collapsible>

      <p className="text-sm text-muted-foreground">
        Status: {isOpen ? 'Open' : 'Closed'}
      </p>
    </div>
  )
}
```

### With Custom Trigger Icon

```typescript
import { ChevronDown } from 'lucide-react'

function IconCollapsible() {
  const [isOpen, setIsOpen] = React.useState(false)

  return (
    <Collapsible open={isOpen} onOpenChange={setIsOpen} className="w-full">
      <div className="flex items-center justify-between space-x-4 rounded-md border p-4">
        <div>
          <h4 className="text-sm font-semibold">Show Details</h4>
          <p className="text-sm text-muted-foreground">
            Additional information available
          </p>
        </div>
        <CollapsibleTrigger asChild>
          <Button variant="ghost" size="sm">
            <ChevronDown
              className={cn(
                'h-4 w-4 transition-transform duration-200',
                isOpen && 'rotate-180'
              )}
            />
            <span className="sr-only">Toggle</span>
          </Button>
        </CollapsibleTrigger>
      </div>
      <CollapsibleContent>
        <div className="rounded-md border border-t-0 p-4 space-y-2">
          <p className="text-sm">
            Here are the additional details that were hidden.
          </p>
          <p className="text-sm text-muted-foreground">
            This content appears when you expand the section.
          </p>
        </div>
      </CollapsibleContent>
    </Collapsible>
  )
}
```

### GitHub Style Repository List

```typescript
import { Star, GitFork } from 'lucide-react'

function RepositoryList() {
  const [openRepos, setOpenRepos] = React.useState<Set<string>>(new Set())

  const repos = [
    {
      id: 'repo-1',
      name: '@radix-ui/primitives',
      description: 'An open-source UI component library.',
      stars: 15234,
      forks: 892,
    },
    {
      id: 'repo-2',
      name: '@radix-ui/colors',
      description: 'A gorgeous, accessible color system.',
      stars: 3456,
      forks: 234,
    },
  ]

  const toggleRepo = (id: string) => {
    setOpenRepos((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  return (
    <div className="space-y-2">
      {repos.map((repo) => (
        <Collapsible
          key={repo.id}
          open={openRepos.has(repo.id)}
          onOpenChange={() => toggleRepo(repo.id)}
        >
          <div className="rounded-md border">
            <div className="flex items-center justify-between p-4">
              <div className="space-y-1">
                <h4 className="text-sm font-semibold">{repo.name}</h4>
                <div className="flex items-center gap-4 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <Star className="h-3 w-3" />
                    {repo.stars.toLocaleString()}
                  </span>
                  <span className="flex items-center gap-1">
                    <GitFork className="h-3 w-3" />
                    {repo.forks.toLocaleString()}
                  </span>
                </div>
              </div>
              <CollapsibleTrigger asChild>
                <Button variant="ghost" size="sm">
                  <ChevronDown
                    className={cn(
                      'h-4 w-4 transition-transform',
                      openRepos.has(repo.id) && 'rotate-180'
                    )}
                  />
                </Button>
              </CollapsibleTrigger>
            </div>
            <CollapsibleContent>
              <div className="border-t p-4 text-sm text-muted-foreground">
                {repo.description}
              </div>
            </CollapsibleContent>
          </div>
        </Collapsible>
      ))}
    </div>
  )
}
```

### With Card

```typescript
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'

function CardCollapsible() {
  return (
    <Collapsible className="w-full">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Advanced Settings</CardTitle>
            <CollapsibleTrigger asChild>
              <Button variant="ghost" size="sm">
                Expand
              </Button>
            </CollapsibleTrigger>
          </div>
        </CardHeader>
        <CollapsibleContent>
          <CardContent className="space-y-4">
            <div>
              <label className="text-sm font-medium">API Key</label>
              <Input type="password" placeholder="Enter API key" />
            </div>
            <div>
              <label className="text-sm font-medium">Webhook URL</label>
              <Input type="url" placeholder="https://example.com/webhook" />
            </div>
          </CardContent>
        </CollapsibleContent>
      </Card>
    </Collapsible>
  )
}
```

### Nested Collapsibles

```typescript
function NestedCollapsibles() {
  return (
    <Collapsible className="w-full">
      <div className="rounded-md border">
        <div className="flex items-center justify-between p-4">
          <h4 className="text-sm font-semibold">Parent Section</h4>
          <CollapsibleTrigger asChild>
            <Button variant="ghost" size="sm">Toggle</Button>
          </CollapsibleTrigger>
        </div>
        <CollapsibleContent>
          <div className="border-t p-4 space-y-2">
            <p className="text-sm">Parent content here.</p>
            
            {/* Nested Collapsible */}
            <Collapsible className="ml-4">
              <div className="rounded-md border">
                <div className="flex items-center justify-between p-3">
                  <span className="text-sm font-medium">Child Section</span>
                  <CollapsibleTrigger asChild>
                    <Button variant="ghost" size="sm">Toggle</Button>
                  </CollapsibleTrigger>
                </div>
                <CollapsibleContent>
                  <div className="border-t p-3 text-sm text-muted-foreground">
                    Nested content here.
                  </div>
                </CollapsibleContent>
              </div>
            </Collapsible>
          </div>
        </CollapsibleContent>
      </div>
    </Collapsible>
  )
}
```

---

## 🧪 TESTING

```typescript
// src/components/ui/__tests__/collapsible.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import {
  Collapsible,
  CollapsibleTrigger,
  CollapsibleContent,
} from '../collapsible'

describe('Collapsible', () => {
  it('renders trigger and content', () => {
    render(
      <Collapsible>
        <CollapsibleTrigger>Toggle</CollapsibleTrigger>
        <CollapsibleContent>Content</CollapsibleContent>
      </Collapsible>
    )

    expect(screen.getByText('Toggle')).toBeInTheDocument()
  })

  it('toggles content on trigger click', () => {
    render(
      <Collapsible>
        <CollapsibleTrigger>Toggle</CollapsibleTrigger>
        <CollapsibleContent>Content</CollapsibleContent>
      </Collapsible>
    )

    const trigger = screen.getByText('Toggle')
    
    // Initially closed
    expect(screen.queryByText('Content')).not.toBeVisible()
    
    // Open
    fireEvent.click(trigger)
    expect(screen.getByText('Content')).toBeVisible()
    
    // Close
    fireEvent.click(trigger)
    expect(screen.queryByText('Content')).not.toBeVisible()
  })

  it('supports controlled mode', () => {
    const TestComponent = () => {
      const [open, setOpen] = React.useState(false)
      return (
        <>
          <button onClick={() => setOpen(!open)}>External Toggle</button>
          <Collapsible open={open} onOpenChange={setOpen}>
            <CollapsibleTrigger>Internal Toggle</CollapsibleTrigger>
            <CollapsibleContent>Content</CollapsibleContent>
          </Collapsible>
        </>
      )
    }

    render(<TestComponent />)
    
    const externalToggle = screen.getByText('External Toggle')
    fireEvent.click(externalToggle)
    
    expect(screen.getByText('Content')).toBeVisible()
  })

  it('respects disabled state', () => {
    render(
      <Collapsible disabled>
        <CollapsibleTrigger>Toggle</CollapsibleTrigger>
        <CollapsibleContent>Content</CollapsibleContent>
      </Collapsible>
    )

    const trigger = screen.getByText('Toggle')
    fireEvent.click(trigger)
    
    expect(screen.queryByText('Content')).not.toBeVisible()
  })
})
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Keyboard accessible (Enter/Space)
- ✅ Focus indicators
- ✅ ARIA attributes (aria-expanded, aria-controls)
- ✅ Screen reader support

### Keyboard Shortcuts
- **Enter/Space**: Toggle collapsible

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-collapsible
- [ ] Create collapsible.tsx file
- [ ] Implement Collapsible root
- [ ] Implement CollapsibleTrigger
- [ ] Implement CollapsibleContent with animation
- [ ] Add animations to tailwind.config
- [ ] Write tests
- [ ] Test accessibility
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
