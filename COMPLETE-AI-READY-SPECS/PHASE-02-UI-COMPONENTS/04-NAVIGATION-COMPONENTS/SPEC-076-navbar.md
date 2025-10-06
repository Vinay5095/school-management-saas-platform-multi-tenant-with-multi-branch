# SPEC-076: Navbar Component
## Responsive Navigation Bar with Mobile Menu

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Dependencies**: Button, Menu, Avatar

---

## 📋 OVERVIEW

### Purpose
A responsive navigation bar component that adapts to all screen sizes, featuring logo placement, navigation links, search, user menu, and mobile hamburger menu.

### Key Features
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Sticky/fixed positioning
- ✅ Logo and branding
- ✅ Navigation links with active states
- ✅ Search integration
- ✅ User dropdown menu
- ✅ Notification bell
- ✅ Mobile hamburger menu
- ✅ Transparent/solid variants
- ✅ Dark mode support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/navbar.tsx
'use client'

import * as React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Menu, X, Search, Bell, User } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from '@/components/ui/dropdown-menu'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface NavItem {
  /**
   * Link label
   */
  label: string

  /**
   * Link href
   */
  href: string

  /**
   * Icon component
   */
  icon?: React.ReactNode

  /**
   * Badge count
   */
  badge?: number

  /**
   * External link
   */
  external?: boolean

  /**
   * Dropdown items
   */
  items?: NavItem[]
}

export interface NavbarProps {
  /**
   * Logo component or image
   */
  logo?: React.ReactNode

  /**
   * Navigation items
   */
  items?: NavItem[]

  /**
   * Action buttons/elements
   */
  actions?: React.ReactNode

  /**
   * Show search bar
   */
  showSearch?: boolean

  /**
   * Search placeholder
   */
  searchPlaceholder?: string

  /**
   * Search callback
   */
  onSearch?: (query: string) => void

  /**
   * Show user menu
   */
  showUserMenu?: boolean

  /**
   * User data
   */
  user?: {
    name: string
    email?: string
    avatar?: string
    initials?: string
  }

  /**
   * User menu items
   */
  userMenuItems?: Array<{
    label: string
    onClick: () => void
    icon?: React.ReactNode
  }>

  /**
   * Show notifications
   */
  showNotifications?: boolean

  /**
   * Notification count
   */
  notificationCount?: number

  /**
   * Sticky navbar
   */
  sticky?: boolean

  /**
   * Transparent background (becomes solid on scroll)
   */
  transparent?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// NAVBAR COMPONENT
// ========================================

/**
 * Navbar Component
 * 
 * Responsive navigation bar with mobile menu support.
 * 
 * @example
 * <Navbar
 *   logo={<Logo />}
 *   items={navItems}
 *   showSearch
 *   showUserMenu
 *   user={{ name: 'John Doe', avatar: '/avatar.jpg' }}
 * />
 */
export function Navbar({
  logo,
  items = [],
  actions,
  showSearch = false,
  searchPlaceholder = 'Search...',
  onSearch,
  showUserMenu = false,
  user,
  userMenuItems = [],
  showNotifications = false,
  notificationCount = 0,
  sticky = false,
  transparent = false,
  className,
}: NavbarProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false)
  const [searchQuery, setSearchQuery] = React.useState('')
  const [isScrolled, setIsScrolled] = React.useState(false)
  const pathname = usePathname()

  // Handle scroll for transparent navbar
  React.useEffect(() => {
    if (!transparent) return

    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10)
    }

    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [transparent])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    onSearch?.(searchQuery)
  }

  const isActive = (href: string) => {
    return pathname === href || pathname?.startsWith(href + '/')
  }

  return (
    <nav
      className={cn(
        'w-full border-b transition-all duration-200',
        sticky && 'sticky top-0 z-50',
        transparent && !isScrolled
          ? 'bg-transparent border-transparent'
          : 'bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60',
        className
      )}
    >
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <div className="flex items-center gap-8">
            {logo && (
              <Link href="/" className="flex items-center">
                {logo}
              </Link>
            )}

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-1">
              {items.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    'px-3 py-2 text-sm font-medium rounded-md transition-colors',
                    'hover:bg-accent hover:text-accent-foreground',
                    isActive(item.href)
                      ? 'bg-accent text-accent-foreground'
                      : 'text-muted-foreground'
                  )}
                >
                  {item.icon && <span className="mr-2">{item.icon}</span>}
                  {item.label}
                  {item.badge !== undefined && item.badge > 0 && (
                    <span className="ml-2 inline-flex items-center justify-center w-5 h-5 text-xs font-bold rounded-full bg-primary text-primary-foreground">
                      {item.badge}
                    </span>
                  )}
                </Link>
              ))}
            </div>
          </div>

          {/* Right Side */}
          <div className="flex items-center gap-2">
            {/* Search */}
            {showSearch && (
              <form onSubmit={handleSearch} className="hidden sm:block">
                <div className="relative">
                  <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                    type="search"
                    placeholder={searchPlaceholder}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-9 w-48 lg:w-64"
                  />
                </div>
              </form>
            )}

            {/* Notifications */}
            {showNotifications && (
              <Button variant="ghost" size="icon" className="relative">
                <Bell className="h-5 w-5" />
                {notificationCount > 0 && (
                  <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-destructive text-[10px] font-bold text-destructive-foreground">
                    {notificationCount > 9 ? '9+' : notificationCount}
                  </span>
                )}
              </Button>
            )}

            {/* Custom Actions */}
            {actions}

            {/* User Menu */}
            {showUserMenu && user && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="rounded-full">
                    <Avatar className="h-8 w-8">
                      {user.avatar && <AvatarImage src={user.avatar} alt={user.name} />}
                      <AvatarFallback>
                        {user.initials || user.name.slice(0, 2).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <div className="flex items-center gap-2 p-2">
                    <Avatar className="h-10 w-10">
                      {user.avatar && <AvatarImage src={user.avatar} alt={user.name} />}
                      <AvatarFallback>
                        {user.initials || user.name.slice(0, 2).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col space-y-1">
                      <p className="text-sm font-medium">{user.name}</p>
                      {user.email && (
                        <p className="text-xs text-muted-foreground">{user.email}</p>
                      )}
                    </div>
                  </div>
                  <DropdownMenuSeparator />
                  {userMenuItems.map((item, index) => (
                    <DropdownMenuItem key={index} onClick={item.onClick}>
                      {item.icon && <span className="mr-2">{item.icon}</span>}
                      {item.label}
                    </DropdownMenuItem>
                  ))}
                </DropdownMenuContent>
              </DropdownMenu>
            )}

            {/* Mobile Menu Toggle */}
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? (
                <X className="h-5 w-5" />
              ) : (
                <Menu className="h-5 w-5" />
              )}
            </Button>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden py-4 space-y-2 border-t">
            {/* Mobile Search */}
            {showSearch && (
              <form onSubmit={handleSearch} className="px-2 pb-4">
                <div className="relative">
                  <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                    type="search"
                    placeholder={searchPlaceholder}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-9"
                  />
                </div>
              </form>
            )}

            {/* Mobile Navigation Links */}
            {items.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMobileMenuOpen(false)}
                className={cn(
                  'flex items-center justify-between px-2 py-2 text-sm font-medium rounded-md transition-colors',
                  'hover:bg-accent hover:text-accent-foreground',
                  isActive(item.href)
                    ? 'bg-accent text-accent-foreground'
                    : 'text-muted-foreground'
                )}
              >
                <span className="flex items-center">
                  {item.icon && <span className="mr-2">{item.icon}</span>}
                  {item.label}
                </span>
                {item.badge !== undefined && item.badge > 0 && (
                  <span className="inline-flex items-center justify-center w-5 h-5 text-xs font-bold rounded-full bg-primary text-primary-foreground">
                    {item.badge}
                  </span>
                )}
              </Link>
            ))}
          </div>
        )}
      </div>
    </nav>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Navbar

```typescript
import { Navbar } from '@/components/ui/navbar'
import { Home, Users, Settings } from 'lucide-react'

function BasicNavbar() {
  const navItems = [
    { label: 'Home', href: '/', icon: <Home className="h-4 w-4" /> },
    { label: 'Users', href: '/users', icon: <Users className="h-4 w-4" /> },
    { label: 'Settings', href: '/settings', icon: <Settings className="h-4 w-4" /> },
  ]

  return (
    <Navbar
      logo={<span className="text-xl font-bold">MyApp</span>}
      items={navItems}
    />
  )
}
```

### Full-Featured Navbar

```typescript
function FullNavbar() {
  const navItems = [
    { label: 'Dashboard', href: '/dashboard' },
    { label: 'Projects', href: '/projects', badge: 3 },
    { label: 'Team', href: '/team' },
    { label: 'Reports', href: '/reports' },
  ]

  const userMenuItems = [
    { label: 'Profile', onClick: () => router.push('/profile') },
    { label: 'Settings', onClick: () => router.push('/settings') },
    { label: 'Billing', onClick: () => router.push('/billing') },
    { label: 'Sign Out', onClick: () => signOut() },
  ]

  return (
    <Navbar
      logo={<Logo />}
      items={navItems}
      showSearch
      onSearch={(query) => console.log('Search:', query)}
      showUserMenu
      user={{
        name: 'John Doe',
        email: 'john@example.com',
        avatar: '/avatars/john.jpg',
      }}
      userMenuItems={userMenuItems}
      showNotifications
      notificationCount={5}
      sticky
    />
  )
}
```

### Transparent Navbar

```typescript
function HeroWithNavbar() {
  return (
    <>
      <Navbar
        logo={<Logo white />}
        items={navItems}
        transparent
        sticky
        className="text-white"
      />
      <div className="h-screen bg-gradient-to-r from-blue-600 to-purple-600">
        {/* Hero content */}
      </div>
    </>
  )
}
```

### With Custom Actions

```typescript
function NavbarWithActions() {
  return (
    <Navbar
      logo={<Logo />}
      items={navItems}
      actions={
        <>
          <Button variant="ghost">Login</Button>
          <Button>Sign Up</Button>
        </>
      }
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Navbar', () => {
  it('renders logo and nav items', () => {
    render(<Navbar logo={<span>Logo</span>} items={navItems} />)
    expect(screen.getByText('Logo')).toBeInTheDocument()
    expect(screen.getByText('Home')).toBeInTheDocument()
  })

  it('highlights active link', () => {
    render(<Navbar items={navItems} />)
    const activeLink = screen.getByText('Home')
    expect(activeLink).toHaveClass('bg-accent')
  })

  it('toggles mobile menu', () => {
    render(<Navbar items={navItems} />)
    const menuButton = screen.getByLabelText('Toggle menu')
    fireEvent.click(menuButton)
    expect(screen.getAllByText('Home').length).toBeGreaterThan(1)
  })

  it('handles search', () => {
    const onSearch = jest.fn()
    render(<Navbar showSearch onSearch={onSearch} />)
    const searchInput = screen.getByPlaceholderText('Search...')
    fireEvent.change(searchInput, { target: { value: 'test' } })
    fireEvent.submit(searchInput.closest('form')!)
    expect(onSearch).toHaveBeenCalledWith('test')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ ARIA labels
- ✅ Focus indicators
- ✅ Screen reader support
- ✅ Mobile touch targets

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create navbar.tsx
- [ ] Implement responsive design
- [ ] Add mobile menu
- [ ] Integrate search
- [ ] Add user menu
- [ ] Add notifications
- [ ] Implement sticky behavior
- [ ] Add transparent variant
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
