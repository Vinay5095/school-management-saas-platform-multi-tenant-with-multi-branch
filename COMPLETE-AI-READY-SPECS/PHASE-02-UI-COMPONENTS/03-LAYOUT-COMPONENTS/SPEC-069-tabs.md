# SPEC-069: Tabs Component
## Accessible Tab Navigation with Radix UI

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5 hours  
> **Dependencies**: Radix UI Tabs

---

## 📋 OVERVIEW

### Purpose
A tab component for organizing content into multiple panels, with only one panel visible at a time. Built on Radix UI Tabs for full accessibility support.

### Key Features
- ✅ Horizontal and vertical orientations
- ✅ Multiple visual variants
- ✅ Keyboard navigation (Arrow keys)
- ✅ Active tab indicators
- ✅ Lazy loading content
- ✅ Disabled tabs
- ✅ Icon support
- ✅ Badge/count indicators
- ✅ Controlled and uncontrolled modes
- ✅ Smooth animations

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/tabs.tsx
'use client'

import * as React from 'react'
import * as TabsPrimitive from '@radix-ui/react-tabs'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// ========================================
// VARIANT DEFINITIONS
// ========================================

const tabsListVariants = cva('inline-flex items-center justify-center', {
  variants: {
    variant: {
      line: 'border-b',
      enclosed: 'bg-muted p-1 rounded-lg',
      pills: 'gap-2',
    },
    orientation: {
      horizontal: 'w-full',
      vertical: 'flex-col w-auto h-full',
    },
  },
  defaultVariants: {
    variant: 'line',
    orientation: 'horizontal',
  },
})

const tabsTriggerVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap px-4 py-2 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        line: 'border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:text-foreground hover:text-foreground',
        enclosed:
          'data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm rounded-md',
        pills:
          'rounded-full data-[state=active]:bg-primary data-[state=active]:text-primary-foreground hover:bg-muted',
      },
    },
    defaultVariants: {
      variant: 'line',
    },
  }
)

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface TabsProps
  extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.Root>,
    VariantProps<typeof tabsListVariants> {
  /**
   * Default active tab value
   */
  defaultValue?: string

  /**
   * Controlled tab value
   */
  value?: string

  /**
   * Callback when tab changes
   */
  onValueChange?: (value: string) => void

  /**
   * Tab content
   */
  children: React.ReactNode
}

export interface TabsListProps
  extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>,
    VariantProps<typeof tabsListVariants> {}

export interface TabsTriggerProps
  extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>,
    VariantProps<typeof tabsTriggerVariants> {
  /**
   * Tab value
   */
  value: string

  /**
   * Icon to display
   */
  icon?: React.ReactNode

  /**
   * Badge count
   */
  count?: number

  /**
   * Disable tab
   */
  disabled?: boolean
}

export interface TabsContentProps
  extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content> {
  /**
   * Tab value
   */
  value: string

  /**
   * Lazy load content (only render when active)
   */
  lazy?: boolean
}

// ========================================
// TABS ROOT
// ========================================

/**
 * Tabs Component
 * 
 * Root tabs component.
 * 
 * @example
 * <Tabs defaultValue="tab1">
 *   <TabsList>
 *     <TabsTrigger value="tab1">Tab 1</TabsTrigger>
 *     <TabsTrigger value="tab2">Tab 2</TabsTrigger>
 *   </TabsList>
 *   <TabsContent value="tab1">Content 1</TabsContent>
 *   <TabsContent value="tab2">Content 2</TabsContent>
 * </Tabs>
 */
const Tabs = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Root>,
  TabsProps
>(({ className, orientation, ...props }, ref) => (
  <TabsPrimitive.Root
    ref={ref}
    className={cn(
      orientation === 'vertical' && 'flex gap-4',
      className
    )}
    orientation={orientation}
    {...props}
  />
))
Tabs.displayName = TabsPrimitive.Root.displayName

// ========================================
// TABS LIST
// ========================================

/**
 * TabsList Component
 * 
 * Container for tab triggers.
 */
const TabsList = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  TabsListProps
>(({ className, variant, orientation, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn(tabsListVariants({ variant, orientation }), className)}
    {...props}
  />
))
TabsList.displayName = TabsPrimitive.List.displayName

// ========================================
// TABS TRIGGER
// ========================================

/**
 * TabsTrigger Component
 * 
 * Individual tab button.
 */
const TabsTrigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  TabsTriggerProps
>(({ className, variant, icon, count, children, ...props }, ref) => (
  <TabsPrimitive.Trigger
    ref={ref}
    className={cn(tabsTriggerVariants({ variant }), className)}
    {...props}
  >
    {icon && <span className="mr-2">{icon}</span>}
    {children}
    {count !== undefined && (
      <span className="ml-2 inline-flex items-center justify-center w-5 h-5 text-xs rounded-full bg-muted">
        {count}
      </span>
    )}
  </TabsPrimitive.Trigger>
))
TabsTrigger.displayName = TabsPrimitive.Trigger.displayName

// ========================================
// TABS CONTENT
// ========================================

/**
 * TabsContent Component
 * 
 * Content panel for each tab.
 */
const TabsContent = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Content>,
  TabsContentProps
>(({ className, lazy = false, value, children, ...props }, ref) => {
  const [hasBeenActive, setHasBeenActive] = React.useState(!lazy)

  return (
    <TabsPrimitive.Content
      ref={ref}
      className={cn(
        'mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
        className
      )}
      value={value}
      onFocus={() => setHasBeenActive(true)}
      {...props}
    >
      {hasBeenActive ? children : null}
    </TabsPrimitive.Content>
  )
})
TabsContent.displayName = TabsPrimitive.Content.displayName

// ========================================
// EXPORTS
// ========================================

export { Tabs, TabsList, TabsTrigger, TabsContent }
```

---

## 📚 USAGE EXAMPLES

### Basic Tabs

```typescript
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'

function BasicTabs() {
  return (
    <Tabs defaultValue="overview">
      <TabsList>
        <TabsTrigger value="overview">Overview</TabsTrigger>
        <TabsTrigger value="analytics">Analytics</TabsTrigger>
        <TabsTrigger value="reports">Reports</TabsTrigger>
        <TabsTrigger value="settings">Settings</TabsTrigger>
      </TabsList>
      <TabsContent value="overview">
        <p>Overview content here</p>
      </TabsContent>
      <TabsContent value="analytics">
        <p>Analytics content here</p>
      </TabsContent>
      <TabsContent value="reports">
        <p>Reports content here</p>
      </TabsContent>
      <TabsContent value="settings">
        <p>Settings content here</p>
      </TabsContent>
    </Tabs>
  )
}
```

### Tab Variants

```typescript
function TabVariants() {
  return (
    <div className="space-y-8">
      {/* Line Variant (Default) */}
      <Tabs defaultValue="tab1" variant="line">
        <TabsList>
          <TabsTrigger value="tab1">Line Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Line Tab 2</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Line content 1</TabsContent>
        <TabsContent value="tab2">Line content 2</TabsContent>
      </Tabs>

      {/* Enclosed Variant */}
      <Tabs defaultValue="tab1" variant="enclosed">
        <TabsList>
          <TabsTrigger value="tab1">Enclosed Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Enclosed Tab 2</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Enclosed content 1</TabsContent>
        <TabsContent value="tab2">Enclosed content 2</TabsContent>
      </Tabs>

      {/* Pills Variant */}
      <Tabs defaultValue="tab1" variant="pills">
        <TabsList>
          <TabsTrigger value="tab1">Pills Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Pills Tab 2</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Pills content 1</TabsContent>
        <TabsContent value="tab2">Pills content 2</TabsContent>
      </Tabs>
    </div>
  )
}
```

### Tabs with Icons

```typescript
import { Home, Users, Settings, FileText } from 'lucide-react'

function TabsWithIcons() {
  return (
    <Tabs defaultValue="home">
      <TabsList>
        <TabsTrigger value="home" icon={<Home className="h-4 w-4" />}>
          Home
        </TabsTrigger>
        <TabsTrigger value="users" icon={<Users className="h-4 w-4" />}>
          Users
        </TabsTrigger>
        <TabsTrigger value="documents" icon={<FileText className="h-4 w-4" />}>
          Documents
        </TabsTrigger>
        <TabsTrigger value="settings" icon={<Settings className="h-4 w-4" />}>
          Settings
        </TabsTrigger>
      </TabsList>
      <TabsContent value="home">Home content</TabsContent>
      <TabsContent value="users">Users content</TabsContent>
      <TabsContent value="documents">Documents content</TabsContent>
      <TabsContent value="settings">Settings content</TabsContent>
    </Tabs>
  )
}
```

### Tabs with Counts/Badges

```typescript
function TabsWithCounts() {
  return (
    <Tabs defaultValue="all">
      <TabsList>
        <TabsTrigger value="all" count={42}>
          All
        </TabsTrigger>
        <TabsTrigger value="active" count={15}>
          Active
        </TabsTrigger>
        <TabsTrigger value="pending" count={8}>
          Pending
        </TabsTrigger>
        <TabsTrigger value="completed" count={19}>
          Completed
        </TabsTrigger>
      </TabsList>
      <TabsContent value="all">All items (42)</TabsContent>
      <TabsContent value="active">Active items (15)</TabsContent>
      <TabsContent value="pending">Pending items (8)</TabsContent>
      <TabsContent value="completed">Completed items (19)</TabsContent>
    </Tabs>
  )
}
```

### Vertical Tabs

```typescript
function VerticalTabs() {
  return (
    <Tabs defaultValue="profile" orientation="vertical" className="min-h-[400px]">
      <TabsList variant="pills" orientation="vertical">
        <TabsTrigger value="profile">Profile</TabsTrigger>
        <TabsTrigger value="account">Account</TabsTrigger>
        <TabsTrigger value="security">Security</TabsTrigger>
        <TabsTrigger value="notifications">Notifications</TabsTrigger>
      </TabsList>
      <div className="flex-1">
        <TabsContent value="profile">
          <Card>
            <CardHeader>
              <CardTitle>Profile Settings</CardTitle>
            </CardHeader>
            <CardContent>Profile content here</CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="account">
          <Card>
            <CardHeader>
              <CardTitle>Account Settings</CardTitle>
            </CardHeader>
            <CardContent>Account content here</CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="security">
          <Card>
            <CardHeader>
              <CardTitle>Security Settings</CardTitle>
            </CardHeader>
            <CardContent>Security content here</CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="notifications">
          <Card>
            <CardHeader>
              <CardTitle>Notification Settings</CardTitle>
            </CardHeader>
            <CardContent>Notifications content here</CardContent>
          </Card>
        </TabsContent>
      </div>
    </Tabs>
  )
}
```

### Controlled Tabs

```typescript
function ControlledTabs() {
  const [activeTab, setActiveTab] = React.useState('tab1')

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <Button onClick={() => setActiveTab('tab1')}>Go to Tab 1</Button>
        <Button onClick={() => setActiveTab('tab2')}>Go to Tab 2</Button>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="tab1">Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Tab 2</TabsTrigger>
          <TabsTrigger value="tab3">Tab 3</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Content 1</TabsContent>
        <TabsContent value="tab2">Content 2</TabsContent>
        <TabsContent value="tab3">Content 3</TabsContent>
      </Tabs>

      <p className="text-sm text-muted-foreground">
        Current tab: {activeTab}
      </p>
    </div>
  )
}
```

### Lazy Loading Tabs

```typescript
function LazyTabs() {
  return (
    <Tabs defaultValue="tab1">
      <TabsList>
        <TabsTrigger value="tab1">Immediate</TabsTrigger>
        <TabsTrigger value="tab2">Lazy Loaded</TabsTrigger>
        <TabsTrigger value="tab3">Also Lazy</TabsTrigger>
      </TabsList>
      <TabsContent value="tab1">
        This content renders immediately
      </TabsContent>
      <TabsContent value="tab2" lazy>
        This content only renders when you click the tab
      </TabsContent>
      <TabsContent value="tab3" lazy>
        This content also lazy loads
      </TabsContent>
    </Tabs>
  )
}
```

---

## 🧪 TESTING

```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../tabs'

describe('Tabs', () => {
  it('renders tabs and content', () => {
    render(
      <Tabs defaultValue="tab1">
        <TabsList>
          <TabsTrigger value="tab1">Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Tab 2</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Content 1</TabsContent>
        <TabsContent value="tab2">Content 2</TabsContent>
      </Tabs>
    )

    expect(screen.getByText('Tab 1')).toBeInTheDocument()
    expect(screen.getByText('Content 1')).toBeInTheDocument()
  })

  it('switches tabs on click', () => {
    render(
      <Tabs defaultValue="tab1">
        <TabsList>
          <TabsTrigger value="tab1">Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Tab 2</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Content 1</TabsContent>
        <TabsContent value="tab2">Content 2</TabsContent>
      </Tabs>
    )

    fireEvent.click(screen.getByText('Tab 2'))
    expect(screen.getByText('Content 2')).toBeVisible()
  })

  it('supports keyboard navigation', () => {
    render(
      <Tabs defaultValue="tab1">
        <TabsList>
          <TabsTrigger value="tab1">Tab 1</TabsTrigger>
          <TabsTrigger value="tab2">Tab 2</TabsTrigger>
        </TabsList>
        <TabsContent value="tab1">Content 1</TabsContent>
        <TabsContent value="tab2">Content 2</TabsContent>
      </Tabs>
    )

    const tab1 = screen.getByText('Tab 1')
    tab1.focus()
    fireEvent.keyDown(tab1, { key: 'ArrowRight' })
    expect(screen.getByText('Tab 2')).toHaveFocus()
  })
})
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Keyboard navigation (Arrow keys, Home, End)
- ✅ ARIA roles and attributes
- ✅ Focus management
- ✅ Screen reader support

### Keyboard Navigation
- **Arrow Left/Right**: Navigate between horizontal tabs
- **Arrow Up/Down**: Navigate between vertical tabs
- **Home**: Go to first tab
- **End**: Go to last tab
- **Tab**: Focus on tab list, then tab content

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-tabs
- [ ] Create tabs.tsx file
- [ ] Implement Tabs root component
- [ ] Implement TabsList with variants
- [ ] Implement TabsTrigger with icon/count support
- [ ] Implement TabsContent with lazy loading
- [ ] Add orientation support
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
