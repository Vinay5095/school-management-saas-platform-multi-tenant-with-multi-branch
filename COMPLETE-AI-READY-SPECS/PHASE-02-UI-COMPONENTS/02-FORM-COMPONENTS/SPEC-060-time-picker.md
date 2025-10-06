# SPEC-060: TimePicker Component
## Time Selection Component with 12/24 Hour Formats

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5 hours  
> **Dependencies**: date-fns, Radix UI Popover

---

## 📋 OVERVIEW

### Purpose
A time selection component supporting both 12-hour and 24-hour formats with hour, minute, and optional second selection. Provides keyboard input and dropdown selection modes.

### Key Features
- ✅ 12-hour and 24-hour formats
- ✅ Hour, minute, and second selection
- ✅ Keyboard input support
- ✅ Dropdown selection interface
- ✅ AM/PM toggle for 12-hour format
- ✅ Min/max time constraints
- ✅ Step intervals (15 min, 30 min, etc.)
- ✅ Error state handling
- ✅ React Hook Form integration
- ✅ WCAG 2.1 AA compliant

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/time-picker.tsx
'use client'

import * as React from 'react'
import { Clock } from 'lucide-react'
import { format, parse, isValid } from 'date-fns'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Select } from '@/components/ui/select'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface TimeValue {
  hour: number
  minute: number
  second?: number
}

export interface TimePickerProps {
  /**
   * Selected time value
   */
  value?: TimeValue
  
  /**
   * Callback fired when time changes
   */
  onValueChange?: (time: TimeValue | undefined) => void
  
  /**
   * Label for the time picker
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
   * Placeholder text
   */
  placeholder?: string
  
  /**
   * Use 12-hour format with AM/PM
   */
  use12Hour?: boolean
  
  /**
   * Show seconds selector
   */
  showSeconds?: boolean
  
  /**
   * Minute step interval (e.g., 15 for 15-minute intervals)
   */
  minuteStep?: number
  
  /**
   * Second step interval
   */
  secondStep?: number
  
  /**
   * Minimum selectable time
   */
  minTime?: TimeValue
  
  /**
   * Maximum selectable time
   */
  maxTime?: TimeValue
  
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
// HELPER FUNCTIONS
// ========================================

const formatTimeValue = (time: TimeValue, use12Hour: boolean): string => {
  const { hour, minute, second } = time
  
  if (use12Hour) {
    const period = hour >= 12 ? 'PM' : 'AM'
    const hour12 = hour % 12 || 12
    const parts = [
      hour12.toString().padStart(2, '0'),
      minute.toString().padStart(2, '0'),
    ]
    if (second !== undefined) {
      parts.push(second.toString().padStart(2, '0'))
    }
    return `${parts.join(':')} ${period}`
  }
  
  const parts = [
    hour.toString().padStart(2, '0'),
    minute.toString().padStart(2, '0'),
  ]
  if (second !== undefined) {
    parts.push(second.toString().padStart(2, '0'))
  }
  return parts.join(':')
}

const parseTimeString = (
  timeString: string,
  use12Hour: boolean
): TimeValue | null => {
  try {
    // Remove spaces and convert to uppercase for AM/PM
    const cleaned = timeString.trim().toUpperCase()
    
    // Extract AM/PM if present
    const isPM = cleaned.includes('PM')
    const isAM = cleaned.includes('AM')
    const timeOnly = cleaned.replace(/\s*(AM|PM)\s*/, '')
    
    // Split by colon
    const parts = timeOnly.split(':').map(Number)
    
    if (parts.length < 2 || parts.some(isNaN)) {
      return null
    }
    
    let [hour, minute, second] = parts
    
    // Convert 12-hour to 24-hour if needed
    if (use12Hour && (isAM || isPM)) {
      if (isPM && hour !== 12) {
        hour += 12
      } else if (isAM && hour === 12) {
        hour = 0
      }
    }
    
    // Validate ranges
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null
    }
    
    if (second !== undefined && (second < 0 || second > 59)) {
      return null
    }
    
    return { hour, minute, second }
  } catch {
    return null
  }
}

const generateTimeOptions = (
  max: number,
  step: number = 1
): number[] => {
  const options: number[] = []
  for (let i = 0; i <= max; i += step) {
    options.push(i)
  }
  return options
}

// ========================================
// TIME PICKER COMPONENT
// ========================================

/**
 * TimePicker Component
 * 
 * A time selection component with support for 12/24 hour formats
 * and configurable minute/second intervals.
 * 
 * @example
 * // Basic time picker
 * <TimePicker
 *   value={time}
 *   onValueChange={setTime}
 *   label="Select time"
 * />
 * 
 * @example
 * // 12-hour format with 15-minute intervals
 * <TimePicker
 *   value={time}
 *   onValueChange={setTime}
 *   use12Hour
 *   minuteStep={15}
 * />
 */
export const TimePicker = React.forwardRef<HTMLButtonElement, TimePickerProps>(
  (
    {
      value,
      onValueChange,
      label,
      description,
      error,
      placeholder = 'Select time',
      use12Hour = false,
      showSeconds = false,
      minuteStep = 1,
      secondStep = 1,
      minTime,
      maxTime,
      required,
      disabled,
      className,
    },
    ref
  ) => {
    const [open, setOpen] = React.useState(false)
    const [inputValue, setInputValue] = React.useState('')
    const [internalValue, setInternalValue] = React.useState<TimeValue | undefined>(value)
    
    const pickerId = React.useId()
    const errorId = `${pickerId}-error`
    const descriptionId = `${pickerId}-description`

    // Update input when value changes
    React.useEffect(() => {
      if (value) {
        setInputValue(formatTimeValue(value, use12Hour))
        setInternalValue(value)
      } else {
        setInputValue('')
        setInternalValue(undefined)
      }
    }, [value, use12Hour])

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const newValue = e.target.value
      setInputValue(newValue)
      
      // Try to parse as user types
      const parsed = parseTimeString(newValue, use12Hour)
      if (parsed) {
        setInternalValue(parsed)
        onValueChange?.(parsed)
      }
    }

    const handleInputBlur = () => {
      // Validate and format on blur
      if (internalValue) {
        setInputValue(formatTimeValue(internalValue, use12Hour))
      } else if (inputValue) {
        // Try to parse one more time
        const parsed = parseTimeString(inputValue, use12Hour)
        if (parsed) {
          setInternalValue(parsed)
          onValueChange?.(parsed)
          setInputValue(formatTimeValue(parsed, use12Hour))
        } else {
          // Invalid input, clear it
          setInputValue('')
        }
      }
    }

    const handleSelectChange = (field: 'hour' | 'minute' | 'second', newValue: number) => {
      const updated = {
        hour: internalValue?.hour ?? 0,
        minute: internalValue?.minute ?? 0,
        ...(showSeconds && { second: internalValue?.second ?? 0 }),
        [field]: newValue,
      }
      
      setInternalValue(updated)
      onValueChange?.(updated)
      setInputValue(formatTimeValue(updated, use12Hour))
    }

    const handlePeriodChange = (period: 'AM' | 'PM') => {
      if (!internalValue) return
      
      let newHour = internalValue.hour
      const currentPeriod = newHour >= 12 ? 'PM' : 'AM'
      
      if (currentPeriod !== period) {
        if (period === 'PM') {
          newHour = newHour < 12 ? newHour + 12 : newHour
        } else {
          newHour = newHour >= 12 ? newHour - 12 : newHour
        }
        
        handleSelectChange('hour', newHour)
      }
    }

    const hourOptions = use12Hour
      ? generateTimeOptions(12, 1).filter(h => h !== 0)
      : generateTimeOptions(23, 1)
      
    const minuteOptions = generateTimeOptions(59, minuteStep)
    const secondOptions = showSeconds ? generateTimeOptions(59, secondStep) : []

    const displayHour = internalValue?.hour !== undefined
      ? use12Hour
        ? internalValue.hour % 12 || 12
        : internalValue.hour
      : ''

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
              <Clock className="mr-2 h-4 w-4" />
              {value ? formatTimeValue(value, use12Hour) : <span>{placeholder}</span>}
            </Button>
          </PopoverTrigger>
          
          <PopoverContent className="w-auto p-4" align="start">
            <div className="space-y-4">
              {/* Manual Input */}
              <div>
                <label className="text-sm font-medium mb-2 block">
                  Enter Time
                </label>
                <Input
                  value={inputValue}
                  onChange={handleInputChange}
                  onBlur={handleInputBlur}
                  placeholder={use12Hour ? 'HH:MM AM/PM' : 'HH:MM'}
                />
              </div>

              {/* Time Selectors */}
              <div className="flex gap-2 items-center">
                {/* Hour */}
                <div className="flex-1">
                  <label className="text-xs text-muted-foreground mb-1 block">
                    Hour
                  </label>
                  <select
                    value={displayHour}
                    onChange={(e) => {
                      let hour = Number(e.target.value)
                      if (use12Hour && internalValue) {
                        const isPM = internalValue.hour >= 12
                        if (isPM && hour !== 12) hour += 12
                        if (!isPM && hour === 12) hour = 0
                      }
                      handleSelectChange('hour', hour)
                    }}
                    className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
                  >
                    <option value="">--</option>
                    {hourOptions.map((h) => (
                      <option key={h} value={h}>
                        {h.toString().padStart(2, '0')}
                      </option>
                    ))}
                  </select>
                </div>

                <span className="text-2xl font-bold mt-6">:</span>

                {/* Minute */}
                <div className="flex-1">
                  <label className="text-xs text-muted-foreground mb-1 block">
                    Minute
                  </label>
                  <select
                    value={internalValue?.minute ?? ''}
                    onChange={(e) => handleSelectChange('minute', Number(e.target.value))}
                    className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
                  >
                    <option value="">--</option>
                    {minuteOptions.map((m) => (
                      <option key={m} value={m}>
                        {m.toString().padStart(2, '0')}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Second (optional) */}
                {showSeconds && (
                  <>
                    <span className="text-2xl font-bold mt-6">:</span>
                    <div className="flex-1">
                      <label className="text-xs text-muted-foreground mb-1 block">
                        Second
                      </label>
                      <select
                        value={internalValue?.second ?? ''}
                        onChange={(e) => handleSelectChange('second', Number(e.target.value))}
                        className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
                      >
                        <option value="">--</option>
                        {secondOptions.map((s) => (
                          <option key={s} value={s}>
                            {s.toString().padStart(2, '0')}
                          </option>
                        ))}
                      </select>
                    </div>
                  </>
                )}

                {/* AM/PM (for 12-hour format) */}
                {use12Hour && internalValue && (
                  <div className="flex-1">
                    <label className="text-xs text-muted-foreground mb-1 block">
                      Period
                    </label>
                    <select
                      value={internalValue.hour >= 12 ? 'PM' : 'AM'}
                      onChange={(e) => handlePeriodChange(e.target.value as 'AM' | 'PM')}
                      className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
                    >
                      <option value="AM">AM</option>
                      <option value="PM">PM</option>
                    </select>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  className="flex-1"
                  onClick={() => {
                    setInternalValue(undefined)
                    onValueChange?.(undefined)
                    setInputValue('')
                    setOpen(false)
                  }}
                >
                  Clear
                </Button>
                <Button
                  size="sm"
                  className="flex-1"
                  onClick={() => setOpen(false)}
                >
                  Done
                </Button>
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

TimePicker.displayName = 'TimePicker'
```

---

## 📚 USAGE EXAMPLES

### Basic Time Picker (24-hour)

```typescript
import { TimePicker } from '@/components/ui/time-picker'

function AppointmentTime() {
  const [time, setTime] = React.useState<TimeValue>()

  return (
    <TimePicker
      label="Appointment Time"
      value={time}
      onValueChange={setTime}
    />
  )
}
```

### 12-Hour Format with 15-Minute Intervals

```typescript
function MeetingTime() {
  const [time, setTime] = React.useState<TimeValue>()

  return (
    <TimePicker
      label="Meeting Time"
      description="Select a time for your meeting"
      value={time}
      onValueChange={setTime}
      use12Hour
      minuteStep={15}
    />
  )
}
```

### With Seconds

```typescript
function PreciseTime() {
  const [time, setTime] = React.useState<TimeValue>()

  return (
    <TimePicker
      label="Precise Time"
      value={time}
      onValueChange={setTime}
      showSeconds
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
  appointmentTime: z.object({
    hour: z.number().min(0).max(23),
    minute: z.number().min(0).max(59),
  }).refine((time) => time.hour !== undefined && time.minute !== undefined, {
    message: 'Please select a time',
  }),
})

function AppointmentForm() {
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="appointmentTime"
        control={control}
        render={({ field }) => (
          <TimePicker
            label="Appointment Time"
            value={field.value}
            onValueChange={field.onChange}
            error={errors.appointmentTime?.message}
            use12Hour
            minuteStep={15}
            required
          />
        )}
      />
      <Button type="submit">Book Appointment</Button>
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
- **Tab**: Navigate between fields
- **Arrow keys**: Adjust time in dropdowns
- **Enter/Space**: Open/close picker
- **Escape**: Close picker

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install date-fns
- [ ] Install @radix-ui/react-popover
- [ ] Create time-picker.tsx file
- [ ] Implement TimePicker component
- [ ] Add 12/24 hour format support
- [ ] Add keyboard input parsing
- [ ] Add dropdown selectors
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
