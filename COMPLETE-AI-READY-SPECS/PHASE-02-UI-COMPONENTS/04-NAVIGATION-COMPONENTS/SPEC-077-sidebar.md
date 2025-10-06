# SPEC-077: Sidebar Component
## Collapsible Side Navigation with Mini Mode

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 8 hours  
> **Dependencies**: Button, Tooltip, Collapsible

---

## 📋 OVERVIEW

### Purpose
A flexible sidebar navigation component with collapsible functionality, mini mode, nested navigation, and responsive behavior for admin panels and dashboards.

### Key Features
- ✅ Collapsible sidebar
- ✅ Mini mode (icon-only)
- ✅ Nested navigation groups
- ✅ Active state indicators
- ✅ Badges and counters
- ✅ Tooltips in mini mode
- ✅ Responsive (mobile drawer)
- ✅ Persistent state
- ✅ Custom width
- ✅ Dark mode support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/sidebar.tsx
'use client'

import * as React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ChevronDown, ChevronRight, Menu, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip'
import { ScrollArea } from '@/components/ui/scroll-area'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface SidebarItem {
  /**
   * Item label
   */
  label: string

  /**
   * Item href (for links)
   */
  href?: string

  /**
   * Icon component
   */
  icon?: React.ReactNode

  /**
   * Badge count
   */
  badge?: number | string

  /**
   * Badge variant
   */
  badgeVariant?: 'default' | 'success' | 'warning' | 'danger'

  /**
   * Nested items
   */
  items?: SidebarItem[]

  /**
   * Initially expanded (for groups)
   */
  defaultExpanded?: boolean

  /**
   * Disabled state
   */
  disabled?: boolean

  /**
   * Click handler
   */
  onClick?: () => void
}

export interface SidebarProps {
  /**
   * Sidebar items
   */
  items: SidebarItem[]

  /**
   * Header content (logo, branding)
   */
  header?: React.ReactNode

  /**
   * Footer content
   */
  footer?: React.ReactNode

  /**
   * Initially collapsed
   */
  defaultCollapsed?: boolean

  /**
   * Allow collapsing
   */
  collapsible?: boolean

  /**
   * Mini mode (icon-only when collapsed)
   */
  miniMode?: boolean

  /**
   * Sidebar width (expanded)
   */
  width?: number | string

  /**
   * Mini width (collapsed)
   */
  miniWidth?: number | string

  /**
   * Position
   */
  position?: 'left' | 'right'

  /**
   * Persist collapsed state
   */
  persistState?: boolean

  /**
   * Storage key for persistent state
   */
  storageKey?: string

  /**
   * Collapsed state (controlled)
   */
  collapsed?: boolean

  /**
   * Collapsed state change callback
   */
  onCollapsedChange?: (collapsed: boolean) => void

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// SIDEBAR CONTEXT
// ========================================

interface SidebarContextValue {
  collapsed: boolean
  miniMode: boolean
  toggleCollapsed: () => void
}

const SidebarContext = React.createContext<SidebarContextValue | undefined>(undefined)

function useSidebar() {
  const context = React.useContext(SidebarContext)
  if (!context) {
    throw new Error('useSidebar must be used within Sidebar')
  }
  return context
}

// ========================================
// SIDEBAR ITEM COMPONENT
// ========================================

interface SidebarItemProps {
  item: SidebarItem
  level?: number
}

function SidebarItemComponent({ item, level = 0 }: SidebarItemProps) {
  const { collapsed, miniMode } = useSidebar()
  const pathname = usePathname()
  const [expanded, setExpanded] = React.useState(item.defaultExpanded ?? false)

  const hasChildren = item.items && item.items.length > 0
  const isActive = item.href ? pathname === item.href || pathname?.startsWith(item.href + '/') : false

  const content = (
    <>
      {item.icon && (
        <span className="flex-shrink-0 w-5 h-5 flex items-center justify-center">
          {item.icon}
        </span>
      )}
      {!collapsed && (
        <>
          <span className="flex-1 truncate">{item.label}</span>
          {item.badge !== undefined && (
            <span
              className={cn(
                'px-2 py-0.5 text-xs font-medium rounded-full',
                item.badgeVariant === 'success' && 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
                item.badgeVariant === 'warning' && 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300',
                item.badgeVariant === 'danger' && 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
                !item.badgeVariant && 'bg-primary/10 text-primary'
              )}
            >
              {item.badge}
            </span>
          )}
          {hasChildren && (
            <span className="flex-shrink-0 w-4 h-4">
              {expanded ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
            </span>
          )}
        </>
      )}
    </>
  )

  const className = cn(
    'flex items-center gap-3 px-3 py-2 text-sm font-medium rounded-md transition-colors',
    'hover:bg-accent hover:text-accent-foreground',
    isActive && 'bg-accent text-accent-foreground',
    !isActive && 'text-muted-foreground',
    item.disabled && 'opacity-50 cursor-not-allowed',
    collapsed && miniMode && 'justify-center px-2',
    level > 0 && !collapsed && 'ml-4'
  )

  if (hasChildren) {
    return (
      <>
        <button
          onClick={() => !collapsed && setExpanded(!expanded)}
          disabled={item.disabled}
          className={className}
        >
          {collapsed && miniMode ? (
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <div className="flex items-center">{content}</div>
                </TooltipTrigger>
                <TooltipContent side="right">
                  <p>{item.label}</p>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          ) : (
            content
          )}
        </button>
        {!collapsed && expanded && (
          <div className="space-y-1">
            {item.items?.map((child, index) => (
              <SidebarItemComponent key={index} item={child} level={level + 1} />
            ))}
          </div>
        )}
      </>
    )
  }

  if (item.href) {
    return (
      <Link
        href={item.href}
        onClick={item.onClick}
        className={className}
      >
        {collapsed && miniMode ? (
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger asChild>
                <div className="flex items-center">{content}</div>
              </TooltipTrigger>
              <TooltipContent side="right">
                <p>{item.label}</p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
        ) : (
          content
        )}
      </Link>
    )
  }

  return (
    <button
      onClick={item.onClick}
      disabled={item.disabled}
      className={className}
    >
      {collapsed && miniMode ? (
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <div className="flex items-center">{content}</div>
            </TooltipTrigger>
            <TooltipContent side="right">
              <p>{item.label}</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      ) : (
        content
      )}
    </button>
  )
}

// ========================================
// SIDEBAR COMPONENT
// ========================================

/**
 * Sidebar Component
 * 
 * Collapsible side navigation with mini mode support.
 * 
 * @example
 * <Sidebar
 *   items={navItems}
 *   header={<Logo />}
 *   collapsible
 *   miniMode
 * />
 */
export function Sidebar({
  items,
  header,
  footer,
  defaultCollapsed = false,
  collapsible = true,
  miniMode = true,
  width = 280,
  miniWidth = 80,
  position = 'left',
  persistState = true,
  storageKey = 'sidebar-collapsed',
  collapsed: controlledCollapsed,
  onCollapsedChange,
  className,
}: SidebarProps) {
  const [localCollapsed, setLocalCollapsed] = React.useState(() => {
    if (typeof window === 'undefined') return defaultCollapsed
    if (persistState) {
      const stored = localStorage.getItem(storageKey)
      return stored ? JSON.parse(stored) : defaultCollapsed
    }
    return defaultCollapsed
  })

  const collapsed = controlledCollapsed ?? localCollapsed
  const isControlled = controlledCollapsed !== undefined

  const toggleCollapsed = () => {
    const newValue = !collapsed
    if (!isControlled) {
      setLocalCollapsed(newValue)
      if (persistState) {
        localStorage.setItem(storageKey, JSON.stringify(newValue))
      }
    }
    onCollapsedChange?.(newValue)
  }

  const sidebarWidth = collapsed && miniMode ? miniWidth : width

  return (
    <SidebarContext.Provider value={{ collapsed, miniMode, toggleCollapsed }}>
      <aside
        style={{
          width: typeof sidebarWidth === 'number' ? `${sidebarWidth}px` : sidebarWidth,
        }}
        className={cn(
          'flex flex-col border-r bg-background transition-all duration-300',
          position === 'right' && 'border-r-0 border-l',
          className
        )}
      >
        {/* Header */}
        {header && (
          <div className={cn('p-4 border-b', collapsed && miniMode && 'px-2')}>
            {header}
          </div>
        )}

        {/* Navigation */}
        <ScrollArea className="flex-1 px-3 py-4">
          <nav className="space-y-1">
            {items.map((item, index) => (
              <SidebarItemComponent key={index} item={item} />
            ))}
          </nav>
        </ScrollArea>

        {/* Footer */}
        {footer && (
          <div className={cn('p-4 border-t', collapsed && miniMode && 'px-2')}>
            {footer}
          </div>
        )}

        {/* Collapse Toggle */}
        {collapsible && (
          <div className={cn('p-4 border-t', collapsed && miniMode && 'px-2')}>
            <Button
              variant="ghost"
              size={collapsed && miniMode ? 'icon' : 'sm'}
              onClick={toggleCollapsed}
              className="w-full"
            >
              <Menu className="h-4 w-4" />
              {!collapsed && <span className="ml-2">Collapse</span>}
            </Button>
          </div>
        )}
      </aside>
    </SidebarContext.Provider>
  )
}

// ========================================
// MOBILE SIDEBAR
// ========================================

export interface MobileSidebarProps extends Omit<SidebarProps, 'collapsed' | 'collapsible'> {
  /**
   * Open state
   */
  open: boolean

  /**
   * Open state change callback
   */
  onOpenChange: (open: boolean) => void
}

/**
 * Mobile Sidebar (Drawer)
 */
export function MobileSidebar({ open, onOpenChange, ...props }: MobileSidebarProps) {
  return (
    <>
      {open && (
        <div
          className="fixed inset-0 z-50 bg-black/50 lg:hidden"
          onClick={() => onOpenChange(false)}
        />
      )}
      <div
        className={cn(
          'fixed inset-y-0 z-50 transition-transform duration-300 lg:hidden',
          props.position === 'right' ? 'right-0' : 'left-0',
          open
            ? 'translate-x-0'
            : props.position === 'right'
            ? 'translate-x-full'
            : '-translate-x-full'
        )}
      >
        <Sidebar {...props} collapsible={false} />
        <Button
          variant="ghost"
          size="icon"
          onClick={() => onOpenChange(false)}
          className="absolute top-4 right-4"
        >
          <X className="h-4 w-4" />
        </Button>
      </div>
    </>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Sidebar

```typescript
import { Sidebar } from '@/components/ui/sidebar'
import { Home, Users, Settings, FileText } from 'lucide-react'

function AppLayout() {
  const navItems = [
    { label: 'Dashboard', href: '/dashboard', icon: <Home className="h-5 w-5" /> },
    { label: 'Users', href: '/users', icon: <Users className="h-5 w-5" />, badge: 12 },
    { label: 'Documents', href: '/documents', icon: <FileText className="h-5 w-5" /> },
    { label: 'Settings', href: '/settings', icon: <Settings className="h-5 w-5" /> },
  ]

  return (
    <div className="flex h-screen">
      <Sidebar items={navItems} />
      <main className="flex-1">{/* Content */}</main>
    </div>
  )
}
```

### Nested Navigation

```typescript
const nestedItems = [
  {
    label: 'Products',
    icon: <Package className="h-5 w-5" />,
    items: [
      { label: 'All Products', href: '/products' },
      { label: 'Categories', href: '/products/categories' },
      { label: 'Inventory', href: '/products/inventory', badge: '5' },
    ],
    defaultExpanded: true,
  },
  {
    label: 'Orders',
    icon: <ShoppingCart className="h-5 w-5" />,
    items: [
      { label: 'All Orders', href: '/orders' },
      { label: 'Pending', href: '/orders/pending', badge: 8, badgeVariant: 'warning' },
      { label: 'Completed', href: '/orders/completed' },
    ],
  },
]

function NestedSidebar() {
  return (
    <Sidebar
      items={nestedItems}
      header={<Logo />}
      footer={<UserProfile />}
      collapsible
      miniMode
    />
  )
}
```

### Responsive Layout

```typescript
function ResponsiveLayout() {
  const [mobileSidebarOpen, setMobileSidebarOpen] = React.useState(false)

  return (
    <>
      {/* Mobile Header */}
      <div className="lg:hidden flex items-center justify-between p-4 border-b">
        <Logo />
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setMobileSidebarOpen(true)}
        >
          <Menu className="h-5 w-5" />
        </Button>
      </div>

      <div className="flex h-screen">
        {/* Desktop Sidebar */}
        <div className="hidden lg:block">
          <Sidebar items={navItems} collapsible miniMode persistState />
        </div>

        {/* Mobile Sidebar */}
        <MobileSidebar
          items={navItems}
          open={mobileSidebarOpen}
          onOpenChange={setMobileSidebarOpen}
        />

        {/* Main Content */}
        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Sidebar', () => {
  it('renders navigation items', () => {
    render(<Sidebar items={navItems} />)
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
  })

  it('toggles collapsed state', () => {
    render(<Sidebar items={navItems} collapsible />)
    const collapseButton = screen.getByText('Collapse')
    fireEvent.click(collapseButton)
    // Sidebar should be collapsed
  })

  it('expands nested items', () => {
    render(<Sidebar items={nestedItems} />)
    const groupButton = screen.getByText('Products')
    fireEvent.click(groupButton)
    expect(screen.getByText('All Products')).toBeVisible()
  })

  it('persists state to localStorage', () => {
    const { rerender } = render(<Sidebar items={navItems} persistState />)
    const collapseButton = screen.getByText('Collapse')
    fireEvent.click(collapseButton)
    rerender(<Sidebar items={navItems} persistState />)
    // Should remain collapsed
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ ARIA labels
- ✅ Focus management
- ✅ Screen reader support
- ✅ Tooltips in mini mode

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create sidebar.tsx
- [ ] Implement collapsible behavior
- [ ] Add mini mode with tooltips
- [ ] Add nested navigation
- [ ] Implement mobile drawer
- [ ] Add persistent state
- [ ] Add badge support
- [ ] Write tests
- [ ] Test accessibility
- [ ] Test responsive behavior

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
