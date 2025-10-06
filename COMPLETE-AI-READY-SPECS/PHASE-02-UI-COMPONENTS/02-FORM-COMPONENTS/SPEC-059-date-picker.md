# SPEC-059: DatePicker Component
## Comprehensive Date Selection Component

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Dependencies**: react-day-picker, date-fns, Radix UI Popover

---

## 📋 OVERVIEW

### Purpose
A fully-featured date picker component with calendar interface, date range selection, and flexible formatting. Integrates with React Hook Form and provides comprehensive accessibility features.

### Key Features
- ✅ Single date and date range selection
- ✅ Calendar popover interface
- ✅ Min/max date constraints
- ✅ Disabled dates configuration
- ✅ Custom date formatting
- ✅ Preset date ranges (Today, Last 7 days, etc.)
- ✅ Month and year navigation
- ✅ Keyboard navigation
- ✅ React Hook Form integration
- ✅ WCAG 2.1 AA compliant

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/date-picker.tsx
'use client'

import * as React from 'react'
import { CalendarIcon } from 'lucide-react'
import { format, subDays, startOfWeek, endOfWeek, startOfMonth, endOfMonth } from 'date-fns'
import { DayPicker, DateRange } from 'react-day-picker'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'

import 'react-day-picker/dist/style.css'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface DatePreset {
  /**
   * Label for the preset
   */
  label: string
  
  /**
   * Date or date range value
   */
  value: Date | DateRange
}

export interface DatePickerProps {
  /**
   * Selected date value
   */
  value?: Date
  
  /**
   * Callback fired when date changes
   */
  onValueChange?: (date: Date | undefined) => void
  
  /**
   * Label for the date picker
   */
  label?: string
  
  /**
   * Description text shown below label
   */
  description?: string
  
  /**
   * Error message to display
   */
  error?: string
  
  /**
   * Placeholder text when no date selected
   */
  placeholder?: string
  
  /**
   * Date format string (date-fns format)
   */
  dateFormat?: string
  
  /**
   * Minimum selectable date
   */
  minDate?: Date
  
  /**
   * Maximum selectable date
   */
  maxDate?: Date
  
  /**
   * Function to determine if a date should be disabled
   */
  isDateDisabled?: (date: Date) => boolean
  
  /**
   * Whether the field is required
   */
  required?: boolean
  
  /**
   * Whether the picker is disabled
   */
  disabled?: boolean
  
  /**
   * Additional CSS classes
   */
  className?: string
}

export interface DateRangePickerProps {
  /**
   * Selected date range value
   */
  value?: DateRange
  
  /**
   * Callback fired when date range changes
   */
  onValueChange?: (range: DateRange | undefined) => void
  
  /**
   * Label for the date range picker
   */
  label?: string
  
  /**
   * Description text shown below label
   */
  description?: string
  
  /**
   * Error message to display
   */
  error?: string
  
  /**
   * Placeholder text when no range selected
   */
  placeholder?: string
  
  /**
   * Date format string (date-fns format)
   */
  dateFormat?: string
  
  /**
   * Preset date ranges to show
   */
  presets?: DatePreset[]
  
  /**
   * Show preset ranges
   */
  showPresets?: boolean
  
  /**
   * Minimum selectable date
   */
  minDate?: Date
  
  /**
   * Maximum selectable date
   */
  maxDate?: Date
  
  /**
   * Whether the field is required
   */
  required?: boolean
  
  /**
   * Whether the picker is disabled
   */
  disabled?: boolean
  
  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// DEFAULT PRESETS
// ========================================

const DEFAULT_PRESETS: DatePreset[] = [
  {
    label: 'Today',
    value: { from: new Date(), to: new Date() },
  },
  {
    label: 'Yesterday',
    value: { from: subDays(new Date(), 1), to: subDays(new Date(), 1) },
  },
  {
    label: 'Last 7 days',
    value: { from: subDays(new Date(), 6), to: new Date() },
  },
  {
    label: 'Last 30 days',
    value: { from: subDays(new Date(), 29), to: new Date() },
  },
  {
    label: 'This week',
    value: { from: startOfWeek(new Date()), to: endOfWeek(new Date()) },
  },
  {
    label: 'This month',
    value: { from: startOfMonth(new Date()), to: endOfMonth(new Date()) },
  },
]

// ========================================
// DATE PICKER COMPONENT (Single Date)
// ========================================

/**
 * DatePicker Component
 * 
 * A calendar-based date picker for selecting single dates.
 * 
 * @example
 * // Basic date picker
 * <DatePicker
 *   value={date}
 *   onValueChange={setDate}
 *   label="Select date"
 * />
 * 
 * @example
 * // With constraints
 * <DatePicker
 *   value={date}
 *   onValueChange={setDate}
 *   minDate={new Date()}
 *   isDateDisabled={(date) => date.getDay() === 0 || date.getDay() === 6}
 * />
 */
export const DatePicker = React.forwardRef<HTMLButtonElement, DatePickerProps>(
  (
    {
      value,
      onValueChange,
      label,
      description,
      error,
      placeholder = 'Select date',
      dateFormat = 'PPP',
      minDate,
      maxDate,
      isDateDisabled,
      required,
      disabled,
      className,
    },
    ref
  ) => {
    const [open, setOpen] = React.useState(false)
    const pickerId = React.useId()
    const errorId = `${pickerId}-error`
    const descriptionId = `${pickerId}-description`

    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    return (
      <div className="w-full space-y-2">
        {/* Label and Description */}
        {(label || description) && (
          <div className="space-y-1">
            {label && (
              <label
                htmlFor={pickerId}
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                {label}
                {required && <span className="text-destructive ml-1">*</span>}
              </label>
            )}
            {description && (
              <p id={descriptionId} className="text-sm text-muted-foreground">
                {description}
              </p>
            )}
          </div>
        )}

        {/* Popover Trigger */}
        <Popover open={open} onOpenChange={setOpen}>
          <PopoverTrigger asChild>
            <Button
              id={pickerId}
              ref={ref}
              variant="outline"
              className={cn(
                'w-full justify-start text-left font-normal',
                !value && 'text-muted-foreground',
                error && 'border-destructive',
                className
              )}
              disabled={disabled}
              aria-describedby={ariaDescribedBy}
              aria-invalid={error ? 'true' : 'false'}
              aria-required={required}
            >
              <CalendarIcon className="mr-2 h-4 w-4" />
              {value ? format(value, dateFormat) : <span>{placeholder}</span>}
            </Button>
          </PopoverTrigger>
          
          <PopoverContent className="w-auto p-0" align="start">
            <DayPicker
              mode="single"
              selected={value}
              onSelect={(date) => {
                onValueChange?.(date)
                setOpen(false)
              }}
              disabled={(date) => {
                if (minDate && date < minDate) return true
                if (maxDate && date > maxDate) return true
                if (isDateDisabled?.(date)) return true
                return false
              }}
              initialFocus
              classNames={{
                months: 'flex flex-col sm:flex-row space-y-4 sm:space-x-4 sm:space-y-0',
                month: 'space-y-4',
                caption: 'flex justify-center pt-1 relative items-center',
                caption_label: 'text-sm font-medium',
                nav: 'space-x-1 flex items-center',
                nav_button: cn(
                  'h-7 w-7 bg-transparent p-0 opacity-50 hover:opacity-100'
                ),
                nav_button_previous: 'absolute left-1',
                nav_button_next: 'absolute right-1',
                table: 'w-full border-collapse space-y-1',
                head_row: 'flex',
                head_cell: 'text-muted-foreground rounded-md w-9 font-normal text-[0.8rem]',
                row: 'flex w-full mt-2',
                cell: 'h-9 w-9 text-center text-sm p-0 relative [&:has([aria-selected].day-range-end)]:rounded-r-md [&:has([aria-selected].day-outside)]:bg-accent/50 [&:has([aria-selected])]:bg-accent first:[&:has([aria-selected])]:rounded-l-md last:[&:has([aria-selected])]:rounded-r-md focus-within:relative focus-within:z-20',
                day: cn(
                  'h-9 w-9 p-0 font-normal aria-selected:opacity-100 hover:bg-accent hover:text-accent-foreground rounded-md'
                ),
                day_range_end: 'day-range-end',
                day_selected:
                  'bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground focus:bg-primary focus:text-primary-foreground',
                day_today: 'bg-accent text-accent-foreground',
                day_outside:
                  'day-outside text-muted-foreground opacity-50 aria-selected:bg-accent/50 aria-selected:text-muted-foreground aria-selected:opacity-30',
                day_disabled: 'text-muted-foreground opacity-50',
                day_hidden: 'invisible',
              }}
            />
          </PopoverContent>
        </Popover>

        {/* Error Message */}
        {error && (
          <p id={errorId} className="text-sm text-destructive" role="alert">
            {error}
          </p>
        )}
      </div>
    )
  }
)

DatePicker.displayName = 'DatePicker'

// ========================================
// DATE RANGE PICKER COMPONENT
// ========================================

/**
 * DateRangePicker Component
 * 
 * A calendar-based date range picker with preset options.
 * 
 * @example
 * // Basic date range picker
 * <DateRangePicker
 *   value={dateRange}
 *   onValueChange={setDateRange}
 *   label="Select date range"
 * />
 * 
 * @example
 * // With presets
 * <DateRangePicker
 *   value={dateRange}
 *   onValueChange={setDateRange}
 *   showPresets
 * />
 */
export const DateRangePicker = React.forwardRef<HTMLButtonElement, DateRangePickerProps>(
  (
    {
      value,
      onValueChange,
      label,
      description,
      error,
      placeholder = 'Select date range',
      dateFormat = 'PP',
      presets = DEFAULT_PRESETS,
      showPresets = false,
      minDate,
      maxDate,
      required,
      disabled,
      className,
    },
    ref
  ) => {
    const [open, setOpen] = React.useState(false)
    const pickerId = React.useId()
    const errorId = `${pickerId}-error`
    const descriptionId = `${pickerId}-description`

    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    const handlePresetClick = (preset: DatePreset) => {
      onValueChange?.(preset.value as DateRange)
      setOpen(false)
    }

    return (
      <div className="w-full space-y-2">
        {/* Label and Description */}
        {(label || description) && (
          <div className="space-y-1">
            {label && (
              <label
                htmlFor={pickerId}
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                {label}
                {required && <span className="text-destructive ml-1">*</span>}
              </label>
            )}
            {description && (
              <p id={descriptionId} className="text-sm text-muted-foreground">
                {description}
              </p>
            )}
          </div>
        )}

        {/* Popover Trigger */}
        <Popover open={open} onOpenChange={setOpen}>
          <PopoverTrigger asChild>
            <Button
              id={pickerId}
              ref={ref}
              variant="outline"
              className={cn(
                'w-full justify-start text-left font-normal',
                !value && 'text-muted-foreground',
                error && 'border-destructive',
                className
              )}
              disabled={disabled}
              aria-describedby={ariaDescribedBy}
              aria-invalid={error ? 'true' : 'false'}
              aria-required={required}
            >
              <CalendarIcon className="mr-2 h-4 w-4" />
              {value?.from ? (
                value.to ? (
                  <>
                    {format(value.from, dateFormat)} - {format(value.to, dateFormat)}
                  </>
                ) : (
                  format(value.from, dateFormat)
                )
              ) : (
                <span>{placeholder}</span>
              )}
            </Button>
          </PopoverTrigger>
          
          <PopoverContent className="w-auto p-0" align="start">
            <div className="flex">
              {/* Presets Sidebar */}
              {showPresets && (
                <div className="border-r p-3 space-y-1">
                  {presets.map((preset) => (
                    <Button
                      key={preset.label}
                      variant="ghost"
                      size="sm"
                      className="w-full justify-start"
                      onClick={() => handlePresetClick(preset)}
                    >
                      {preset.label}
                    </Button>
                  ))}
                </div>
              )}
              
              {/* Calendar */}
              <div className="p-3">
                <DayPicker
                  mode="range"
                  selected={value}
                  onSelect={onValueChange}
                  disabled={(date) => {
                    if (minDate && date < minDate) return true
                    if (maxDate && date > maxDate) return true
                    return false
                  }}
                  numberOfMonths={2}
                  initialFocus
                  classNames={{
                    months: 'flex flex-col sm:flex-row space-y-4 sm:space-x-4 sm:space-y-0',
                    month: 'space-y-4',
                    caption: 'flex justify-center pt-1 relative items-center',
                    caption_label: 'text-sm font-medium',
                    nav: 'space-x-1 flex items-center',
                    nav_button: cn(
                      'h-7 w-7 bg-transparent p-0 opacity-50 hover:opacity-100'
                    ),
                    nav_button_previous: 'absolute left-1',
                    nav_button_next: 'absolute right-1',
                    table: 'w-full border-collapse space-y-1',
                    head_row: 'flex',
                    head_cell: 'text-muted-foreground rounded-md w-9 font-normal text-[0.8rem]',
                    row: 'flex w-full mt-2',
                    cell: 'h-9 w-9 text-center text-sm p-0 relative [&:has([aria-selected].day-range-end)]:rounded-r-md [&:has([aria-selected].day-outside)]:bg-accent/50 [&:has([aria-selected])]:bg-accent first:[&:has([aria-selected])]:rounded-l-md last:[&:has([aria-selected])]:rounded-r-md focus-within:relative focus-within:z-20',
                    day: cn(
                      'h-9 w-9 p-0 font-normal aria-selected:opacity-100 hover:bg-accent hover:text-accent-foreground rounded-md'
                    ),
                    day_range_end: 'day-range-end',
                    day_selected:
                      'bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground focus:bg-primary focus:text-primary-foreground',
                    day_today: 'bg-accent text-accent-foreground',
                    day_outside:
                      'day-outside text-muted-foreground opacity-50 aria-selected:bg-accent/50 aria-selected:text-muted-foreground aria-selected:opacity-30',
                    day_disabled: 'text-muted-foreground opacity-50',
                    day_range_middle:
                      'aria-selected:bg-accent aria-selected:text-accent-foreground',
                    day_hidden: 'invisible',
                  }}
                />
              </div>
            </div>
          </PopoverContent>
        </Popover>

        {/* Error Message */}
        {error && (
          <p id={errorId} className="text-sm text-destructive" role="alert">
            {error}
          </p>
        )}
      </div>
    )
  }
)

DateRangePicker.displayName = 'DateRangePicker'
```

---

## 📚 USAGE EXAMPLES

### Basic Date Picker

```typescript
import { DatePicker } from '@/components/ui/date-picker'

function BirthdayPicker() {
  const [birthday, setBirthday] = React.useState<Date>()

  return (
    <DatePicker
      label="Date of Birth"
      value={birthday}
      onValueChange={setBirthday}
      maxDate={new Date()}
      required
    />
  )
}
```

### Date Range Picker with Presets

```typescript
import { DateRangePicker } from '@/components/ui/date-picker'

function ReportDateRange() {
  const [dateRange, setDateRange] = React.useState<DateRange>()

  return (
    <DateRangePicker
      label="Report Period"
      description="Select the date range for your report"
      value={dateRange}
      onValueChange={setDateRange}
      showPresets
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
  startDate: z.date({ required_error: 'Start date is required' }),
  endDate: z.date().optional(),
})

function EventForm() {
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)} className="space-y-4">
      <Controller
        name="startDate"
        control={control}
        render={({ field }) => (
          <DatePicker
            label="Event Date"
            value={field.value}
            onValueChange={field.onChange}
            error={errors.startDate?.message}
            minDate={new Date()}
            required
          />
        )}
      />
      
      <Button type="submit">Create Event</Button>
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Keyboard navigation support
- ✅ Focus indicators visible
- ✅ Screen reader friendly
- ✅ ARIA labels and descriptions

### Keyboard Navigation
- **Arrow keys**: Navigate calendar dates
- **Enter/Space**: Select date
- **Escape**: Close calendar
- **Tab**: Navigate between elements

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install react-day-picker, date-fns
- [ ] Install @radix-ui/react-popover
- [ ] Create date-picker.tsx file
- [ ] Implement DatePicker component
- [ ] Implement DateRangePicker component
- [ ] Add preset ranges
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
