# SPEC-080: Menu Component
## Dropdown Menu with Nested Submenus

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5 hours  
> **Dependencies**: Radix UI Menu

---

## 📋 OVERVIEW

### Purpose
A flexible dropdown menu component with support for nested submenus, checkboxes, radio groups, separators, and keyboard navigation built on Radix UI primitives.

### Key Features
- ✅ Dropdown/context menus
- ✅ Nested submenus
- ✅ Checkbox items
- ✅ Radio groups
- ✅ Separators and labels
- ✅ Icons and shortcuts
- ✅ Custom triggers
- ✅ Portal rendering
- ✅ Keyboard navigation
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/menu.tsx
'use client'

import * as React from 'react'
import * as DropdownMenuPrimitive from '@radix-ui/react-dropdown-menu'
import { Check, ChevronRight, Circle } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface MenuItem {
  /**
   * Item type
   */
  type?: 'item' | 'checkbox' | 'radio' | 'separator' | 'label' | 'submenu'

  /**
   * Item label
   */
  label?: string

  /**
   * Icon component
   */
  icon?: React.ReactNode

  /**
   * Keyboard shortcut
   */
  shortcut?: string

  /**
   * Click handler
   */
  onClick?: () => void

  /**
   * Disabled state
   */
  disabled?: boolean

  /**
   * Checkbox checked state
   */
  checked?: boolean

  /**
   * Checkbox change handler
   */
  onCheckedChange?: (checked: boolean) => void

  /**
   * Radio value
   */
  value?: string

  /**
   * Submenu items
   */
  items?: MenuItem[]

  /**
   * Destructive action
   */
  destructive?: boolean

  /**
   * Inset (for items with icons)
   */
  inset?: boolean
}

export interface MenuProps {
  /**
   * Menu items
   */
  items: MenuItem[]

  /**
   * Trigger element
   */
  trigger?: React.ReactNode

  /**
   * Open state (controlled)
   */
  open?: boolean

  /**
   * Open state change callback
   */
  onOpenChange?: (open: boolean) => void

  /**
   * Menu side
   */
  side?: 'top' | 'right' | 'bottom' | 'left'

  /**
   * Menu align
   */
  align?: 'start' | 'center' | 'end'

  /**
   * Radio group value (for radio items)
   */
  radioValue?: string

  /**
   * Radio value change callback
   */
  onRadioValueChange?: (value: string) => void

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// BASE MENU COMPONENTS
// ========================================

const Menu = DropdownMenuPrimitive.Root
const MenuTrigger = DropdownMenuPrimitive.Trigger
const MenuGroup = DropdownMenuPrimitive.Group
const MenuPortal = DropdownMenuPrimitive.Portal
const MenuSub = DropdownMenuPrimitive.Sub
const MenuRadioGroup = DropdownMenuPrimitive.RadioGroup

const MenuSubTrigger = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.SubTrigger>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.SubTrigger> & {
    inset?: boolean
  }
>(({ className, inset, children, ...props }, ref) => (
  <DropdownMenuPrimitive.SubTrigger
    ref={ref}
    className={cn(
      'flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none focus:bg-accent data-[state=open]:bg-accent',
      inset && 'pl-8',
      className
    )}
    {...props}
  >
    {children}
    <ChevronRight className="ml-auto h-4 w-4" />
  </DropdownMenuPrimitive.SubTrigger>
))
MenuSubTrigger.displayName = DropdownMenuPrimitive.SubTrigger.displayName

const MenuSubContent = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.SubContent>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.SubContent>
>(({ className, ...props }, ref) => (
  <DropdownMenuPrimitive.SubContent
    ref={ref}
    className={cn(
      'z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-lg data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2',
      className
    )}
    {...props}
  />
))
MenuSubContent.displayName = DropdownMenuPrimitive.SubContent.displayName

const MenuContent = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Content>
>(({ className, sideOffset = 4, ...props }, ref) => (
  <DropdownMenuPrimitive.Portal>
    <DropdownMenuPrimitive.Content
      ref={ref}
      sideOffset={sideOffset}
      className={cn(
        'z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md',
        'data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2',
        className
      )}
      {...props}
    />
  </DropdownMenuPrimitive.Portal>
))
MenuContent.displayName = DropdownMenuPrimitive.Content.displayName

const MenuItem = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.Item>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Item> & {
    inset?: boolean
  }
>(({ className, inset, ...props }, ref) => (
  <DropdownMenuPrimitive.Item
    ref={ref}
    className={cn(
      'relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
      inset && 'pl-8',
      className
    )}
    {...props}
  />
))
MenuItem.displayName = DropdownMenuPrimitive.Item.displayName

const MenuCheckboxItem = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.CheckboxItem>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.CheckboxItem>
>(({ className, children, checked, ...props }, ref) => (
  <DropdownMenuPrimitive.CheckboxItem
    ref={ref}
    className={cn(
      'relative flex cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
      className
    )}
    checked={checked}
    {...props}
  >
    <span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
      <DropdownMenuPrimitive.ItemIndicator>
        <Check className="h-4 w-4" />
      </DropdownMenuPrimitive.ItemIndicator>
    </span>
    {children}
  </DropdownMenuPrimitive.CheckboxItem>
))
MenuCheckboxItem.displayName = DropdownMenuPrimitive.CheckboxItem.displayName

const MenuRadioItem = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.RadioItem>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.RadioItem>
>(({ className, children, ...props }, ref) => (
  <DropdownMenuPrimitive.RadioItem
    ref={ref}
    className={cn(
      'relative flex cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
      className
    )}
    {...props}
  >
    <span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
      <DropdownMenuPrimitive.ItemIndicator>
        <Circle className="h-2 w-2 fill-current" />
      </DropdownMenuPrimitive.ItemIndicator>
    </span>
    {children}
  </DropdownMenuPrimitive.RadioItem>
))
MenuRadioItem.displayName = DropdownMenuPrimitive.RadioItem.displayName

const MenuLabel = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.Label>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Label> & {
    inset?: boolean
  }
>(({ className, inset, ...props }, ref) => (
  <DropdownMenuPrimitive.Label
    ref={ref}
    className={cn(
      'px-2 py-1.5 text-sm font-semibold',
      inset && 'pl-8',
      className
    )}
    {...props}
  />
))
MenuLabel.displayName = DropdownMenuPrimitive.Label.displayName

const MenuSeparator = React.forwardRef<
  React.ElementRef<typeof DropdownMenuPrimitive.Separator>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Separator>
>(({ className, ...props }, ref) => (
  <DropdownMenuPrimitive.Separator
    ref={ref}
    className={cn('-mx-1 my-1 h-px bg-muted', className)}
    {...props}
  />
))
MenuSeparator.displayName = DropdownMenuPrimitive.Separator.displayName

const MenuShortcut = ({
  className,
  ...props
}: React.HTMLAttributes<HTMLSpanElement>) => {
  return (
    <span
      className={cn('ml-auto text-xs tracking-widest opacity-60', className)}
      {...props}
    />
  )
}
MenuShortcut.displayName = 'MenuShortcut'

// ========================================
// RENDER MENU ITEMS
// ========================================

function renderMenuItems(items: MenuItem[], radioValue?: string, onRadioValueChange?: (value: string) => void) {
  return items.map((item, index) => {
    const key = `menu-item-${index}`

    if (item.type === 'separator') {
      return <MenuSeparator key={key} />
    }

    if (item.type === 'label') {
      return (
        <MenuLabel key={key} inset={item.inset}>
          {item.label}
        </MenuLabel>
      )
    }

    if (item.type === 'checkbox') {
      return (
        <MenuCheckboxItem
          key={key}
          checked={item.checked}
          onCheckedChange={item.onCheckedChange}
          disabled={item.disabled}
        >
          {item.icon && <span className="mr-2">{item.icon}</span>}
          {item.label}
          {item.shortcut && <MenuShortcut>{item.shortcut}</MenuShortcut>}
        </MenuCheckboxItem>
      )
    }

    if (item.type === 'radio') {
      return (
        <MenuRadioItem
          key={key}
          value={item.value!}
          disabled={item.disabled}
        >
          {item.icon && <span className="mr-2">{item.icon}</span>}
          {item.label}
          {item.shortcut && <MenuShortcut>{item.shortcut}</MenuShortcut>}
        </MenuRadioItem>
      )
    }

    if (item.type === 'submenu' && item.items) {
      return (
        <MenuSub key={key}>
          <MenuSubTrigger inset={item.inset} disabled={item.disabled}>
            {item.icon && <span className="mr-2">{item.icon}</span>}
            {item.label}
          </MenuSubTrigger>
          <MenuPortal>
            <MenuSubContent>
              {renderMenuItems(item.items, radioValue, onRadioValueChange)}
            </MenuSubContent>
          </MenuPortal>
        </MenuSub>
      )
    }

    // Default item
    return (
      <MenuItem
        key={key}
        onClick={item.onClick}
        disabled={item.disabled}
        inset={item.inset}
        className={cn(item.destructive && 'text-destructive focus:text-destructive')}
      >
        {item.icon && <span className="mr-2">{item.icon}</span>}
        <span className="flex-1">{item.label}</span>
        {item.shortcut && <MenuShortcut>{item.shortcut}</MenuShortcut>}
      </MenuItem>
    )
  })
}

// ========================================
// MAIN MENU COMPONENT
// ========================================

/**
 * Menu Component
 * 
 * Dropdown menu with nested submenus.
 * 
 * @example
 * <Menu
 *   trigger={<Button>Open Menu</Button>}
 *   items={menuItems}
 * />
 */
export function MenuComponent({
  items,
  trigger,
  open,
  onOpenChange,
  side = 'bottom',
  align = 'start',
  radioValue,
  onRadioValueChange,
  className,
}: MenuProps) {
  const hasRadioItems = items.some((item) => item.type === 'radio')

  const content = hasRadioItems ? (
    <MenuRadioGroup value={radioValue} onValueChange={onRadioValueChange}>
      {renderMenuItems(items, radioValue, onRadioValueChange)}
    </MenuRadioGroup>
  ) : (
    renderMenuItems(items, radioValue, onRadioValueChange)
  )

  return (
    <Menu open={open} onOpenChange={onOpenChange}>
      {trigger && <MenuTrigger asChild>{trigger}</MenuTrigger>}
      <MenuContent side={side} align={align} className={className}>
        {content}
      </MenuContent>
    </Menu>
  )
}

// ========================================
// EXPORTS
// ========================================

export {
  Menu,
  MenuTrigger,
  MenuContent,
  MenuItem,
  MenuCheckboxItem,
  MenuRadioItem,
  MenuRadioGroup,
  MenuLabel,
  MenuSeparator,
  MenuShortcut,
  MenuGroup,
  MenuPortal,
  MenuSub,
  MenuSubContent,
  MenuSubTrigger,
}
```

---

## 📚 USAGE EXAMPLES

### Basic Menu

```typescript
import { MenuComponent } from '@/components/ui/menu'
import { Button } from '@/components/ui/button'

function BasicMenu() {
  const items = [
    { label: 'Profile', onClick: () => console.log('Profile') },
    { label: 'Settings', onClick: () => console.log('Settings') },
    { type: 'separator' as const },
    { label: 'Logout', onClick: () => console.log('Logout'), destructive: true },
  ]

  return (
    <MenuComponent
      trigger={<Button>Open Menu</Button>}
      items={items}
    />
  )
}
```

### Menu with Icons and Shortcuts

```typescript
import { User, Settings, LogOut } from 'lucide-react'

const items = [
  {
    label: 'Profile',
    icon: <User className="h-4 w-4" />,
    shortcut: '⌘P',
    onClick: () => {},
  },
  {
    label: 'Settings',
    icon: <Settings className="h-4 w-4" />,
    shortcut: '⌘S',
    onClick: () => {},
  },
  { type: 'separator' as const },
  {
    label: 'Logout',
    icon: <LogOut className="h-4 w-4" />,
    shortcut: '⌘Q',
    onClick: () => {},
    destructive: true,
  },
]
```

### Menu with Checkboxes

```typescript
function CheckboxMenu() {
  const [checked, setChecked] = React.useState({
    notifications: true,
    emails: false,
  })

  const items = [
    { type: 'label' as const, label: 'Preferences' },
    {
      type: 'checkbox' as const,
      label: 'Notifications',
      checked: checked.notifications,
      onCheckedChange: (value) => setChecked({ ...checked, notifications: value }),
    },
    {
      type: 'checkbox' as const,
      label: 'Email Updates',
      checked: checked.emails,
      onCheckedChange: (value) => setChecked({ ...checked, emails: value }),
    },
  ]

  return <MenuComponent trigger={<Button>Preferences</Button>} items={items} />
}
```

### Menu with Radio Group

```typescript
function RadioMenu() {
  const [theme, setTheme] = React.useState('light')

  const items = [
    { type: 'label' as const, label: 'Theme' },
    { type: 'radio' as const, label: 'Light', value: 'light' },
    { type: 'radio' as const, label: 'Dark', value: 'dark' },
    { type: 'radio' as const, label: 'System', value: 'system' },
  ]

  return (
    <MenuComponent
      trigger={<Button>Theme</Button>}
      items={items}
      radioValue={theme}
      onRadioValueChange={setTheme}
    />
  )
}
```

### Nested Submenu

```typescript
const nestedItems = [
  { label: 'New Tab', shortcut: '⌘T' },
  { label: 'New Window', shortcut: '⌘N' },
  {
    type: 'submenu' as const,
    label: 'Share',
    items: [
      { label: 'Email' },
      { label: 'Messages' },
      { label: 'AirDrop' },
    ],
  },
  { type: 'separator' as const },
  { label: 'Print', shortcut: '⌘P' },
]
```

---

## 🧪 TESTING

```typescript
describe('Menu', () => {
  it('renders menu items', () => {
    render(<MenuComponent trigger={<button>Menu</button>} items={items} />)
    fireEvent.click(screen.getByText('Menu'))
    expect(screen.getByText('Profile')).toBeInTheDocument()
  })

  it('calls onClick handler', () => {
    const onClick = jest.fn()
    const items = [{ label: 'Item', onClick }]
    render(<MenuComponent trigger={<button>Menu</button>} items={items} />)
    fireEvent.click(screen.getByText('Menu'))
    fireEvent.click(screen.getByText('Item'))
    expect(onClick).toHaveBeenCalled()
  })

  it('handles checkbox items', () => {
    const onCheckedChange = jest.fn()
    const items = [{ type: 'checkbox' as const, label: 'Check', checked: false, onCheckedChange }]
    render(<MenuComponent trigger={<button>Menu</button>} items={items} />)
    fireEvent.click(screen.getByText('Menu'))
    fireEvent.click(screen.getByText('Check'))
    expect(onCheckedChange).toHaveBeenCalledWith(true)
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Full keyboard navigation
- ✅ ARIA attributes
- ✅ Focus management
- ✅ Screen reader support
- ✅ Disabled states

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-dropdown-menu
- [ ] Create menu.tsx
- [ ] Implement base components
- [ ] Add checkbox support
- [ ] Add radio group support
- [ ] Add nested submenus
- [ ] Add shortcuts
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
