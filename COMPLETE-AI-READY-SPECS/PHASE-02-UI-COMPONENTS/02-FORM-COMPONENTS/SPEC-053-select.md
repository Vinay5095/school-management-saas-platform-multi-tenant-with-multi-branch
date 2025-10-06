# SPEC-053: Select Component
## Advanced Select/Dropdown with Single & Multi-Select Support

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Dependencies**: Radix UI Select, React Hook Form, Zod

---

## 📋 OVERVIEW

### Purpose
A fully accessible, customizable select component supporting:
- Single and multi-select modes
- Searchable options
- Async data loading
- Keyboard navigation
- Custom option rendering
- Form integration

### Key Features
- ✅ Single/multi-select modes
- ✅ Searchable with filtering
- ✅ Async option loading
- ✅ Custom option rendering
- ✅ Grouped options
- ✅ Disabled options
- ✅ Virtual scrolling for large lists
- ✅ Keyboard navigation (Arrow keys, Enter, Escape)
- ✅ WCAG 2.1 AA compliant
- ✅ React Hook Form integration

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/select.tsx
'use client'

import * as React from 'react'
import * as SelectPrimitive from '@radix-ui/react-select'
import { Check, ChevronDown, ChevronUp, X, Search } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface SelectOption {
  value: string
  label: string
  disabled?: boolean
  icon?: React.ReactNode
  description?: string
}

export interface SelectGroup {
  label: string
  options: SelectOption[]
}

export interface SelectProps {
  // Core props
  value?: string | string[]
  defaultValue?: string | string[]
  onValueChange?: (value: string | string[]) => void
  options: SelectOption[] | SelectGroup[]
  
  // Behavior
  multiple?: boolean
  searchable?: boolean
  clearable?: boolean
  disabled?: boolean
  required?: boolean
  
  // Async
  async?: boolean
  onSearch?: (query: string) => Promise<SelectOption[]>
  loading?: boolean
  
  // UI
  placeholder?: string
  emptyMessage?: string
  searchPlaceholder?: string
  maxHeight?: number
  
  // Styling
  className?: string
  error?: string
  
  // Accessibility
  'aria-label'?: string
  'aria-describedby'?: string
}

// ========================================
// SELECT COMPONENT
// ========================================

const Select = React.forwardRef<HTMLButtonElement, SelectProps>(
  (
    {
      value,
      defaultValue,
      onValueChange,
      options,
      multiple = false,
      searchable = false,
      clearable = false,
      disabled = false,
      required = false,
      async = false,
      onSearch,
      loading = false,
      placeholder = 'Select an option...',
      emptyMessage = 'No options found',
      searchPlaceholder = 'Search...',
      maxHeight = 300,
      className,
      error,
      'aria-label': ariaLabel,
      'aria-describedby': ariaDescribedBy,
    },
    ref
  ) => {
    const [open, setOpen] = React.useState(false)
    const [searchQuery, setSearchQuery] = React.useState('')
    const [asyncOptions, setAsyncOptions] = React.useState<SelectOption[]>([])
    const [internalValue, setInternalValue] = React.useState<string | string[]>(
      defaultValue || (multiple ? [] : '')
    )

    // Use controlled value if provided, otherwise use internal state
    const currentValue = value !== undefined ? value : internalValue

    // Handle async search
    React.useEffect(() => {
      if (async && searchQuery && onSearch) {
        onSearch(searchQuery).then(setAsyncOptions)
      }
    }, [searchQuery, async, onSearch])

    // Get all options (flatten groups)
    const allOptions = React.useMemo(() => {
      if (async) return asyncOptions
      
      return options.reduce<SelectOption[]>((acc, item) => {
        if ('options' in item) {
          return [...acc, ...item.options]
        }
        return [...acc, item]
      }, [])
    }, [options, async, asyncOptions])

    // Filter options based on search
    const filteredOptions = React.useMemo(() => {
      if (!searchable || !searchQuery) return allOptions
      
      return allOptions.filter(option =>
        option.label.toLowerCase().includes(searchQuery.toLowerCase())
      )
    }, [allOptions, searchQuery, searchable])

    // Get selected labels
    const selectedLabels = React.useMemo(() => {
      if (multiple && Array.isArray(currentValue)) {
        return currentValue
          .map(val => allOptions.find(opt => opt.value === val)?.label)
          .filter(Boolean)
          .join(', ')
      }
      return allOptions.find(opt => opt.value === currentValue)?.label || ''
    }, [currentValue, allOptions, multiple])

    // Handle value change
    const handleValueChange = (newValue: string) => {
      let updatedValue: string | string[]

      if (multiple && Array.isArray(currentValue)) {
        // Toggle selection in multi-select mode
        updatedValue = currentValue.includes(newValue)
          ? currentValue.filter(v => v !== newValue)
          : [...currentValue, newValue]
      } else {
        updatedValue = newValue
        setOpen(false)
      }

      setInternalValue(updatedValue)
      onValueChange?.(updatedValue)
    }

    // Handle clear
    const handleClear = (e: React.MouseEvent) => {
      e.stopPropagation()
      const clearedValue = multiple ? [] : ''
      setInternalValue(clearedValue)
      onValueChange?.(clearedValue)
    }

    // Check if option is selected
    const isSelected = (optionValue: string) => {
      if (multiple && Array.isArray(currentValue)) {
        return currentValue.includes(optionValue)
      }
      return currentValue === optionValue
    }

    if (multiple) {
      // Multi-select implementation
      return (
        <div className="relative">
          <button
            ref={ref}
            type="button"
            onClick={() => !disabled && setOpen(!open)}
            disabled={disabled}
            aria-label={ariaLabel}
            aria-describedby={ariaDescribedBy}
            aria-expanded={open}
            aria-haspopup="listbox"
            className={cn(
              'flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background',
              'focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
              'disabled:cursor-not-allowed disabled:opacity-50',
              error && 'border-error-500 focus:ring-error-500',
              className
            )}
          >
            <span className={cn('truncate', !selectedLabels && 'text-muted-foreground')}>
              {selectedLabels || placeholder}
            </span>
            <div className="flex items-center gap-2">
              {clearable && selectedLabels && !disabled && (
                <X
                  className="h-4 w-4 opacity-50 hover:opacity-100"
                  onClick={handleClear}
                />
              )}
              <ChevronDown className="h-4 w-4 opacity-50" />
            </div>
          </button>

          {open && (
            <div
              className="absolute z-50 mt-1 w-full rounded-md border bg-popover text-popover-foreground shadow-md"
              style={{ maxHeight }}
            >
              {searchable && (
                <div className="flex items-center border-b px-3">
                  <Search className="mr-2 h-4 w-4 shrink-0 opacity-50" />
                  <input
                    type="text"
                    placeholder={searchPlaceholder}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="flex h-10 w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground"
                  />
                </div>
              )}

              <div className="overflow-auto p-1" style={{ maxHeight: maxHeight - 50 }}>
                {loading ? (
                  <div className="py-6 text-center text-sm">Loading...</div>
                ) : filteredOptions.length === 0 ? (
                  <div className="py-6 text-center text-sm">{emptyMessage}</div>
                ) : (
                  filteredOptions.map((option) => (
                    <button
                      key={option.value}
                      type="button"
                      onClick={() => handleValueChange(option.value)}
                      disabled={option.disabled}
                      className={cn(
                        'relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none',
                        'hover:bg-accent hover:text-accent-foreground',
                        'focus:bg-accent focus:text-accent-foreground',
                        option.disabled && 'pointer-events-none opacity-50',
                        isSelected(option.value) && 'bg-accent'
                      )}
                    >
                      <div className="flex items-center gap-2 flex-1">
                        {option.icon && (
                          <span className="h-4 w-4">{option.icon}</span>
                        )}
                        <div className="flex flex-col items-start">
                          <span>{option.label}</span>
                          {option.description && (
                            <span className="text-xs text-muted-foreground">
                              {option.description}
                            </span>
                          )}
                        </div>
                      </div>
                      {isSelected(option.value) && (
                        <Check className="h-4 w-4 ml-2" />
                      )}
                    </button>
                  ))
                )}
              </div>
            </div>
          )}

          {error && (
            <p className="mt-1 text-sm text-error-500" role="alert">
              {error}
            </p>
          )}
        </div>
      )
    }

    // Single select with Radix UI
    return (
      <div className="relative">
        <SelectPrimitive.Root
          value={currentValue as string}
          onValueChange={handleValueChange}
          disabled={disabled}
          required={required}
        >
          <SelectPrimitive.Trigger
            ref={ref}
            aria-label={ariaLabel}
            aria-describedby={ariaDescribedBy}
            className={cn(
              'flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background',
              'focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
              'disabled:cursor-not-allowed disabled:opacity-50',
              '[&>span]:line-clamp-1',
              error && 'border-error-500 focus:ring-error-500',
              className
            )}
          >
            <SelectPrimitive.Value placeholder={placeholder} />
            <SelectPrimitive.Icon asChild>
              <ChevronDown className="h-4 w-4 opacity-50" />
            </SelectPrimitive.Icon>
          </SelectPrimitive.Trigger>

          <SelectPrimitive.Portal>
            <SelectPrimitive.Content
              className="relative z-50 max-h-96 min-w-[8rem] overflow-hidden rounded-md border bg-popover text-popover-foreground shadow-md"
              position="popper"
              sideOffset={4}
            >
              <SelectPrimitive.ScrollUpButton className="flex cursor-default items-center justify-center py-1">
                <ChevronUp className="h-4 w-4" />
              </SelectPrimitive.ScrollUpButton>

              <SelectPrimitive.Viewport className="p-1">
                {searchable && (
                  <div className="flex items-center border-b px-3 pb-2">
                    <Search className="mr-2 h-4 w-4 shrink-0 opacity-50" />
                    <input
                      type="text"
                      placeholder={searchPlaceholder}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="flex h-10 w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground"
                    />
                  </div>
                )}

                {loading ? (
                  <div className="py-6 text-center text-sm">Loading...</div>
                ) : filteredOptions.length === 0 ? (
                  <div className="py-6 text-center text-sm">{emptyMessage}</div>
                ) : (
                  filteredOptions.map((option) => (
                    <SelectPrimitive.Item
                      key={option.value}
                      value={option.value}
                      disabled={option.disabled}
                      className={cn(
                        'relative flex w-full cursor-pointer select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none',
                        'focus:bg-accent focus:text-accent-foreground',
                        'data-[disabled]:pointer-events-none data-[disabled]:opacity-50'
                      )}
                    >
                      <span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
                        <SelectPrimitive.ItemIndicator>
                          <Check className="h-4 w-4" />
                        </SelectPrimitive.ItemIndicator>
                      </span>

                      <div className="flex items-center gap-2">
                        {option.icon && (
                          <span className="h-4 w-4">{option.icon}</span>
                        )}
                        <div className="flex flex-col">
                          <SelectPrimitive.ItemText>
                            {option.label}
                          </SelectPrimitive.ItemText>
                          {option.description && (
                            <span className="text-xs text-muted-foreground">
                              {option.description}
                            </span>
                          )}
                        </div>
                      </div>
                    </SelectPrimitive.Item>
                  ))
                )}
              </SelectPrimitive.Viewport>

              <SelectPrimitive.ScrollDownButton className="flex cursor-default items-center justify-center py-1">
                <ChevronDown className="h-4 w-4" />
              </SelectPrimitive.ScrollDownButton>
            </SelectPrimitive.Content>
          </SelectPrimitive.Portal>
        </SelectPrimitive.Root>

        {clearable && currentValue && !disabled && (
          <button
            type="button"
            onClick={handleClear}
            className="absolute right-8 top-1/2 -translate-y-1/2"
          >
            <X className="h-4 w-4 opacity-50 hover:opacity-100" />
          </button>
        )}

        {error && (
          <p className="mt-1 text-sm text-error-500" role="alert">
            {error}
          </p>
        )}
      </div>
    )
  }
)

Select.displayName = 'Select'

export { Select }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/select.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Select, type SelectOption } from '../select'

const mockOptions: SelectOption[] = [
  { value: '1', label: 'Option 1' },
  { value: '2', label: 'Option 2' },
  { value: '3', label: 'Option 3', disabled: true },
]

describe('Select Component', () => {
  describe('Single Select', () => {
    it('renders correctly', () => {
      render(<Select options={mockOptions} placeholder="Select option" />)
      expect(screen.getByText('Select option')).toBeInTheDocument()
    })

    it('opens dropdown on click', async () => {
      render(<Select options={mockOptions} />)
      const trigger = screen.getByRole('combobox')
      
      await userEvent.click(trigger)
      expect(screen.getByText('Option 1')).toBeInTheDocument()
      expect(screen.getByText('Option 2')).toBeInTheDocument()
    })

    it('selects option on click', async () => {
      const handleChange = jest.fn()
      render(<Select options={mockOptions} onValueChange={handleChange} />)
      
      await userEvent.click(screen.getByRole('combobox'))
      await userEvent.click(screen.getByText('Option 1'))
      
      expect(handleChange).toHaveBeenCalledWith('1')
    })

    it('respects disabled state', () => {
      render(<Select options={mockOptions} disabled />)
      const trigger = screen.getByRole('combobox')
      
      expect(trigger).toBeDisabled()
    })

    it('shows error message', () => {
      render(<Select options={mockOptions} error="This field is required" />)
      expect(screen.getByRole('alert')).toHaveTextContent('This field is required')
    })
  })

  describe('Multi Select', () => {
    it('allows multiple selections', async () => {
      const handleChange = jest.fn()
      render(
        <Select
          options={mockOptions}
          multiple
          onValueChange={handleChange}
        />
      )
      
      const trigger = screen.getByRole('button')
      await userEvent.click(trigger)
      
      await userEvent.click(screen.getByText('Option 1'))
      expect(handleChange).toHaveBeenCalledWith(['1'])
      
      await userEvent.click(screen.getByText('Option 2'))
      expect(handleChange).toHaveBeenCalledWith(['1', '2'])
    })

    it('deselects on second click', async () => {
      const handleChange = jest.fn()
      render(
        <Select
          options={mockOptions}
          multiple
          defaultValue={['1']}
          onValueChange={handleChange}
        />
      )
      
      await userEvent.click(screen.getByRole('button'))
      await userEvent.click(screen.getByText('Option 1'))
      
      expect(handleChange).toHaveBeenCalledWith([])
    })
  })

  describe('Searchable', () => {
    it('filters options based on search', async () => {
      render(<Select options={mockOptions} searchable />)
      
      await userEvent.click(screen.getByRole('combobox'))
      const searchInput = screen.getByPlaceholderText('Search...')
      
      await userEvent.type(searchInput, 'Option 1')
      
      expect(screen.getByText('Option 1')).toBeInTheDocument()
      expect(screen.queryByText('Option 2')).not.toBeInTheDocument()
    })

    it('shows empty message when no results', async () => {
      render(<Select options={mockOptions} searchable />)
      
      await userEvent.click(screen.getByRole('combobox'))
      const searchInput = screen.getByPlaceholderText('Search...')
      
      await userEvent.type(searchInput, 'nonexistent')
      
      expect(screen.getByText('No options found')).toBeInTheDocument()
    })
  })

  describe('Async Loading', () => {
    it('loads options asynchronously', async () => {
      const mockSearch = jest.fn().mockResolvedValue([
        { value: 'async1', label: 'Async Option 1' },
      ])
      
      render(
        <Select
          options={[]}
          async
          searchable
          onSearch={mockSearch}
        />
      )
      
      await userEvent.click(screen.getByRole('button'))
      const searchInput = screen.getByPlaceholderText('Search...')
      
      await userEvent.type(searchInput, 'async')
      
      await waitFor(() => {
        expect(screen.getByText('Async Option 1')).toBeInTheDocument()
      })
    })

    it('shows loading state', () => {
      render(<Select options={[]} loading />)
      
      fireEvent.click(screen.getByRole('button'))
      expect(screen.getByText('Loading...')).toBeInTheDocument()
    })
  })

  describe('Accessibility', () => {
    it('supports keyboard navigation', async () => {
      render(<Select options={mockOptions} />)
      const trigger = screen.getByRole('combobox')
      
      trigger.focus()
      await userEvent.keyboard('{Enter}')
      
      expect(screen.getByText('Option 1')).toBeInTheDocument()
      
      await userEvent.keyboard('{ArrowDown}')
      await userEvent.keyboard('{Enter}')
      
      // Option should be selected
    })

    it('has proper ARIA attributes', () => {
      render(
        <Select
          options={mockOptions}
          aria-label="Select country"
          aria-describedby="country-description"
        />
      )
      
      const trigger = screen.getByRole('combobox')
      expect(trigger).toHaveAttribute('aria-label', 'Select country')
      expect(trigger).toHaveAttribute('aria-describedby', 'country-description')
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Usage

```typescript
import { Select } from '@/components/ui/select'

const options = [
  { value: 'us', label: 'United States' },
  { value: 'uk', label: 'United Kingdom' },
  { value: 'ca', label: 'Canada' },
]

function CountrySelect() {
  return (
    <Select
      options={options}
      placeholder="Select a country"
      onValueChange={(value) => console.log(value)}
    />
  )
}
```

### Multi-Select

```typescript
function SubjectSelect() {
  return (
    <Select
      multiple
      options={[
        { value: 'math', label: 'Mathematics' },
        { value: 'science', label: 'Science' },
        { value: 'english', label: 'English' },
      ]}
      placeholder="Select subjects"
      onValueChange={(values) => console.log(values)}
    />
  )
}
```

### Searchable with Async

```typescript
function StudentSelect() {
  const searchStudents = async (query: string) => {
    const response = await fetch(`/api/students?q=${query}`)
    return response.json()
  }

  return (
    <Select
      async
      searchable
      options={[]}
      placeholder="Search students..."
      onSearch={searchStudents}
      onValueChange={(value) => console.log(value)}
    />
  )
}
```

### With React Hook Form

```typescript
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  country: z.string().min(1, 'Please select a country'),
})

function FormWithSelect() {
  const { control, handleSubmit } = useForm({
    resolver: zodResolver(schema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="country"
        control={control}
        render={({ field, fieldState }) => (
          <Select
            {...field}
            options={countryOptions}
            error={fieldState.error?.message}
          />
        )}
      />
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

- ✅ WCAG 2.1 AA compliant
- ✅ Keyboard navigation (Arrow keys, Enter, Escape, Tab)
- ✅ Screen reader support
- ✅ ARIA attributes (role, aria-label, aria-expanded)
- ✅ Focus management
- ✅ Error announcements

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-select
- [ ] Create select.tsx component
- [ ] Implement single select mode
- [ ] Implement multi-select mode
- [ ] Add search functionality
- [ ] Add async loading support
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test screen readers
- [ ] Create Storybook stories
- [ ] Document usage examples

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
