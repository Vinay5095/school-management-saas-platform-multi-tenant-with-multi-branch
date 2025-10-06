# SPEC-081: Navigation Tabs Component
## Router-Integrated Navigation Tabs

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4 hours  
> **Dependencies**: Tabs, Next.js Router

---

## 📋 OVERVIEW

### Purpose
A navigation tabs component integrated with Next.js routing for seamless page transitions with tab-like navigation patterns.

### Key Features
- ✅ Next.js router integration
- ✅ Active tab indicator
- ✅ Horizontal/vertical orientation
- ✅ Scrollable tabs
- ✅ Icon support
- ✅ Badge counters
- ✅ Disabled tabs
- ✅ Responsive design
- ✅ Keyboard navigation
- ✅ Smooth animations

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/navigation-tabs.tsx
'use client'

import * as React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface NavigationTab {
  /**
   * Tab label
   */
  label: string

  /**
   * Tab href
   */
  href: string

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
   * Disabled state
   */
  disabled?: boolean

  /**
   * Exact match (default: false)
   */
  exact?: boolean
}

export interface NavigationTabsProps {
  /**
   * Navigation tabs
   */
  tabs: NavigationTab[]

  /**
   * Orientation
   */
  orientation?: 'horizontal' | 'vertical'

  /**
   * Variant
   */
  variant?: 'default' | 'pills' | 'underline'

  /**
   * Size
   */
  size?: 'sm' | 'md' | 'lg'

  /**
   * Make tabs scrollable
   */
  scrollable?: boolean

  /**
   * Full width tabs
   */
  fullWidth?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// NAVIGATION TABS COMPONENT
// ========================================

/**
 * Navigation Tabs Component
 * 
 * Router-integrated navigation tabs.
 * 
 * @example
 * <NavigationTabs
 *   tabs={[
 *     { label: 'Overview', href: '/dashboard/overview' },
 *     { label: 'Analytics', href: '/dashboard/analytics' },
 *   ]}
 * />
 */
export function NavigationTabs({
  tabs,
  orientation = 'horizontal',
  variant = 'default',
  size = 'md',
  scrollable = false,
  fullWidth = false,
  className,
}: NavigationTabsProps) {
  const pathname = usePathname()

  const isActive = (tab: NavigationTab) => {
    if (tab.exact) {
      return pathname === tab.href
    }
    return pathname === tab.href || pathname?.startsWith(tab.href + '/')
  }

  const sizeClasses = {
    sm: 'text-xs px-3 py-1.5',
    md: 'text-sm px-4 py-2',
    lg: 'text-base px-6 py-3',
  }

  const variantClasses = {
    default: {
      base: 'border-b',
      tab: 'border-b-2 border-transparent',
      active: 'border-primary text-primary',
      inactive: 'text-muted-foreground hover:text-foreground',
    },
    pills: {
      base: '',
      tab: 'rounded-md',
      active: 'bg-primary text-primary-foreground',
      inactive: 'text-muted-foreground hover:bg-accent hover:text-accent-foreground',
    },
    underline: {
      base: '',
      tab: 'relative',
      active: 'text-primary after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-primary',
      inactive: 'text-muted-foreground hover:text-foreground',
    },
  }

  const styles = variantClasses[variant]

  return (
    <nav
      className={cn(
        'flex',
        orientation === 'horizontal' ? 'flex-row' : 'flex-col',
        styles.base,
        className
      )}
      role="navigation"
    >
      <div
        className={cn(
          'flex',
          orientation === 'horizontal' ? 'flex-row' : 'flex-col',
          scrollable && orientation === 'horizontal' && 'overflow-x-auto',
          scrollable && orientation === 'vertical' && 'overflow-y-auto',
          fullWidth && 'w-full',
          orientation === 'horizontal' ? 'gap-1' : 'gap-0.5'
        )}
      >
        {tabs.map((tab, index) => {
          const active = isActive(tab)

          return (
            <Link
              key={index}
              href={tab.href}
              className={cn(
                'inline-flex items-center gap-2 font-medium transition-colors whitespace-nowrap',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
                sizeClasses[size],
                styles.tab,
                active ? styles.active : styles.inactive,
                tab.disabled && 'pointer-events-none opacity-50',
                fullWidth && orientation === 'horizontal' && 'flex-1 justify-center'
              )}
              aria-current={active ? 'page' : undefined}
              aria-disabled={tab.disabled}
            >
              {tab.icon && (
                <span className="flex-shrink-0">{tab.icon}</span>
              )}
              <span>{tab.label}</span>
              {tab.badge !== undefined && (
                <span
                  className={cn(
                    'inline-flex items-center justify-center min-w-[1.25rem] h-5 px-1.5 text-xs font-bold rounded-full',
                    tab.badgeVariant === 'success' && 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
                    tab.badgeVariant === 'warning' && 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300',
                    tab.badgeVariant === 'danger' && 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
                    !tab.badgeVariant && 'bg-primary/10 text-primary'
                  )}
                >
                  {tab.badge}
                </span>
              )}
            </Link>
          )
        })}
      </div>
    </nav>
  )
}

// ========================================
// SECONDARY NAV TABS (CLIENT-SIDE ONLY)
// ========================================

export interface SecondaryTabsProps {
  /**
   * Tabs
   */
  tabs: Array<{
    label: string
    value: string
    icon?: React.ReactNode
    badge?: number | string
    disabled?: boolean
  }>

  /**
   * Active tab value
   */
  value: string

  /**
   * Tab change callback
   */
  onValueChange: (value: string) => void

  /**
   * Variant
   */
  variant?: 'default' | 'pills' | 'underline'

  /**
   * Size
   */
  size?: 'sm' | 'md' | 'lg'

  /**
   * Full width
   */
  fullWidth?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * Secondary Tabs (Non-Router)
 * 
 * Client-side only tabs without router integration.
 */
export function SecondaryTabs({
  tabs,
  value,
  onValueChange,
  variant = 'default',
  size = 'md',
  fullWidth = false,
  className,
}: SecondaryTabsProps) {
  const sizeClasses = {
    sm: 'text-xs px-3 py-1.5',
    md: 'text-sm px-4 py-2',
    lg: 'text-base px-6 py-3',
  }

  const variantClasses = {
    default: {
      base: 'border-b',
      tab: 'border-b-2 border-transparent',
      active: 'border-primary text-primary',
      inactive: 'text-muted-foreground hover:text-foreground',
    },
    pills: {
      base: '',
      tab: 'rounded-md',
      active: 'bg-primary text-primary-foreground',
      inactive: 'text-muted-foreground hover:bg-accent hover:text-accent-foreground',
    },
    underline: {
      base: '',
      tab: 'relative',
      active: 'text-primary after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-primary',
      inactive: 'text-muted-foreground hover:text-foreground',
    },
  }

  const styles = variantClasses[variant]

  return (
    <div
      className={cn('flex', styles.base, className)}
      role="tablist"
    >
      {tabs.map((tab) => {
        const active = tab.value === value

        return (
          <button
            key={tab.value}
            type="button"
            role="tab"
            aria-selected={active}
            aria-disabled={tab.disabled}
            onClick={() => !tab.disabled && onValueChange(tab.value)}
            className={cn(
              'inline-flex items-center gap-2 font-medium transition-colors whitespace-nowrap',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
              sizeClasses[size],
              styles.tab,
              active ? styles.active : styles.inactive,
              tab.disabled && 'pointer-events-none opacity-50',
              fullWidth && 'flex-1 justify-center'
            )}
          >
            {tab.icon && <span className="flex-shrink-0">{tab.icon}</span>}
            <span>{tab.label}</span>
            {tab.badge !== undefined && (
              <span className="inline-flex items-center justify-center min-w-[1.25rem] h-5 px-1.5 text-xs font-bold rounded-full bg-primary/10 text-primary">
                {tab.badge}
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Navigation Tabs

```typescript
import { NavigationTabs } from '@/components/ui/navigation-tabs'

function DashboardLayout() {
  const tabs = [
    { label: 'Overview', href: '/dashboard' },
    { label: 'Analytics', href: '/dashboard/analytics' },
    { label: 'Reports', href: '/dashboard/reports' },
    { label: 'Settings', href: '/dashboard/settings' },
  ]

  return (
    <div>
      <NavigationTabs tabs={tabs} />
      {/* Page content */}
    </div>
  )
}
```

### With Icons and Badges

```typescript
import { Home, BarChart, FileText, Settings, AlertCircle } from 'lucide-react'

const tabs = [
  {
    label: 'Overview',
    href: '/dashboard',
    icon: <Home className="h-4 w-4" />,
  },
  {
    label: 'Analytics',
    href: '/dashboard/analytics',
    icon: <BarChart className="h-4 w-4" />,
  },
  {
    label: 'Reports',
    href: '/dashboard/reports',
    icon: <FileText className="h-4 w-4" />,
    badge: 3,
    badgeVariant: 'warning',
  },
  {
    label: 'Settings',
    href: '/dashboard/settings',
    icon: <Settings className="h-4 w-4" />,
  },
]

function IconTabs() {
  return <NavigationTabs tabs={tabs} variant="pills" />
}
```

### Vertical Navigation Tabs

```typescript
function VerticalNav() {
  return (
    <div className="flex gap-4">
      <NavigationTabs
        tabs={tabs}
        orientation="vertical"
        variant="pills"
        className="w-48"
      />
      <main className="flex-1">{/* Content */}</main>
    </div>
  )
}
```

### Scrollable Tabs

```typescript
function ScrollableTabs() {
  const manyTabs = Array.from({ length: 15 }, (_, i) => ({
    label: `Tab ${i + 1}`,
    href: `/tab-${i + 1}`,
  }))

  return <NavigationTabs tabs={manyTabs} scrollable />
}
```

### Full Width Tabs

```typescript
function FullWidthTabs() {
  return (
    <NavigationTabs
      tabs={tabs}
      fullWidth
      variant="underline"
      size="lg"
    />
  )
}
```

### Secondary Tabs (Non-Router)

```typescript
import { SecondaryTabs } from '@/components/ui/navigation-tabs'

function ContentWithTabs() {
  const [activeTab, setActiveTab] = React.useState('profile')

  const tabs = [
    { label: 'Profile', value: 'profile' },
    { label: 'Account', value: 'account' },
    { label: 'Notifications', value: 'notifications', badge: 5 },
  ]

  return (
    <div>
      <SecondaryTabs
        tabs={tabs}
        value={activeTab}
        onValueChange={setActiveTab}
        variant="pills"
      />
      <div className="mt-4">
        {activeTab === 'profile' && <ProfileContent />}
        {activeTab === 'account' && <AccountContent />}
        {activeTab === 'notifications' && <NotificationsContent />}
      </div>
    </div>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('NavigationTabs', () => {
  it('renders tabs', () => {
    render(<NavigationTabs tabs={tabs} />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
  })

  it('highlights active tab', () => {
    mockPathname('/dashboard/analytics')
    render(<NavigationTabs tabs={tabs} />)
    const activeTab = screen.getByText('Analytics')
    expect(activeTab).toHaveClass('border-primary')
  })

  it('renders badges', () => {
    const tabsWithBadge = [
      { label: 'Reports', href: '/reports', badge: 5 },
    ]
    render(<NavigationTabs tabs={tabsWithBadge} />)
    expect(screen.getByText('5')).toBeInTheDocument()
  })

  it('disables tabs', () => {
    const tabsWithDisabled = [
      { label: 'Disabled', href: '/disabled', disabled: true },
    ]
    render(<NavigationTabs tabs={tabsWithDisabled} />)
    const disabledTab = screen.getByText('Disabled')
    expect(disabledTab).toHaveClass('pointer-events-none')
  })
})

describe('SecondaryTabs', () => {
  it('handles tab changes', () => {
    const onValueChange = jest.fn()
    render(
      <SecondaryTabs
        tabs={tabs}
        value="profile"
        onValueChange={onValueChange}
      />
    )
    fireEvent.click(screen.getByText('Account'))
    expect(onValueChange).toHaveBeenCalledWith('account')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic navigation
- ✅ ARIA attributes
- ✅ Current page indicator
- ✅ Keyboard navigation
- ✅ Focus indicators
- ✅ Disabled states

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create navigation-tabs.tsx
- [ ] Implement router integration
- [ ] Add variant styles
- [ ] Add icon support
- [ ] Add badge support
- [ ] Add scrollable option
- [ ] Add vertical orientation
- [ ] Create secondary tabs
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
