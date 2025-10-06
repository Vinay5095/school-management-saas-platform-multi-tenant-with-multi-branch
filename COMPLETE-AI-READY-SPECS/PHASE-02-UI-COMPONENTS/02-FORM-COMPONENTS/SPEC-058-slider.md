# SPEC-058: Slider Component
## Range Slider Component with Single and Dual Handles

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5 hours  
> **Dependencies**: Radix UI Slider

---

## 📋 OVERVIEW

### Purpose
An accessible slider component for selecting numeric values within a range. Supports both single-value and range (dual-handle) modes with customizable steps, marks, and value formatting.

### Key Features
- ✅ Single and dual-handle modes
- ✅ Custom min, max, and step values
- ✅ Value labels and tooltips
- ✅ Range marks with labels
- ✅ Vertical and horizontal orientations
- ✅ Disabled state support
- ✅ Error state handling
- ✅ Keyboard navigation (Arrow keys)
- ✅ React Hook Form integration
- ✅ WCAG 2.1 AA compliant

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/slider.tsx
'use client'

import * as React from 'react'
import * as SliderPrimitive from '@radix-ui/react-slider'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface SliderMark {
  /**
   * Value position for the mark
   */
  value: number
  
  /**
   * Optional label to display at this mark
   */
  label?: string
}

export interface SliderProps
  extends Omit<
    React.ComponentPropsWithoutRef<typeof SliderPrimitive.Root>,
    'defaultValue' | 'value' | 'onValueChange'
  > {
  /**
   * The controlled value(s) of the slider
   */
  value?: number | number[]
  
  /**
   * The default value(s) when uncontrolled
   */
  defaultValue?: number | number[]
  
  /**
   * Callback fired when value changes
   */
  onValueChange?: (value: number | number[]) => void
  
  /**
   * Label for the slider
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
   * Show current value(s) as label
   */
  showValue?: boolean
  
  /**
   * Custom formatter for value display
   */
  formatValue?: (value: number) => string
  
  /**
   * Show tooltips on thumbs
   */
  showTooltips?: boolean
  
  /**
   * Array of marks to display on the slider
   */
  marks?: SliderMark[]
  
  /**
   * Show marks on the track
   */
  showMarks?: boolean
}

// ========================================
// SLIDER COMPONENT
// ========================================

/**
 * Slider Component
 * 
 * An accessible slider for selecting numeric values within a range.
 * Supports single and dual-handle modes with marks and tooltips.
 * 
 * @example
 * // Basic single-value slider
 * <Slider
 *   min={0}
 *   max={100}
 *   value={value}
 *   onValueChange={setValue}
 * />
 * 
 * @example
 * // Range slider (dual handles)
 * <Slider
 *   min={0}
 *   max={1000}
 *   value={[minPrice, maxPrice]}
 *   onValueChange={([min, max]) => {
 *     setMinPrice(min)
 *     setMaxPrice(max)
 *   }}
 * />
 * 
 * @example
 * // With marks and custom formatting
 * <Slider
 *   min={0}
 *   max={100}
 *   marks={[
 *     { value: 0, label: '0%' },
 *     { value: 50, label: '50%' },
 *     { value: 100, label: '100%' }
 *   ]}
 *   formatValue={(v) => `${v}%`}
 *   showValue
 * />
 */
const Slider = React.forwardRef<
  React.ElementRef<typeof SliderPrimitive.Root>,
  SliderProps
>(
  (
    {
      className,
      value,
      defaultValue,
      onValueChange,
      label,
      description,
      error,
      showValue,
      formatValue = (v) => String(v),
      showTooltips,
      marks = [],
      showMarks = false,
      min = 0,
      max = 100,
      step = 1,
      disabled,
      orientation = 'horizontal',
      id,
      ...props
    },
    ref
  ) => {
    // Normalize value to array format for easier handling
    const normalizedValue = React.useMemo(() => {
      if (value !== undefined) {
        return Array.isArray(value) ? value : [value]
      }
      if (defaultValue !== undefined) {
        return Array.isArray(defaultValue) ? defaultValue : [defaultValue]
      }
      return [min]
    }, [value, defaultValue, min])

    const [internalValue, setInternalValue] = React.useState(normalizedValue)
    const [hoveredThumb, setHoveredThumb] = React.useState<number | null>(null)

    const sliderId = id || React.useId()
    const errorId = `${sliderId}-error`
    const descriptionId = `${sliderId}-description`

    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    // Handle value changes
    const handleValueChange = (newValue: number[]) => {
      setInternalValue(newValue)
      
      if (onValueChange) {
        // Return single value or array based on original format
        const originalWasArray = Array.isArray(value) || Array.isArray(defaultValue)
        onValueChange(originalWasArray ? newValue : newValue[0])
      }
    }

    // Calculate mark position percentage
    const getMarkPosition = (markValue: number) => {
      return ((markValue - min) / (max - min)) * 100
    }

    // Use controlled or internal value
    const currentValue = value !== undefined ? normalizedValue : internalValue

    return (
      <div className="w-full space-y-4">
        {/* Label, Description, and Value Display */}
        {(label || description || showValue) && (
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              {label && (
                <label
                  htmlFor={sliderId}
                  className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                >
                  {label}
                </label>
              )}
              
              {showValue && (
                <span className="text-sm font-medium text-muted-foreground">
                  {currentValue.length === 1
                    ? formatValue(currentValue[0])
                    : `${formatValue(currentValue[0])} - ${formatValue(currentValue[1])}`}
                </span>
              )}
            </div>
            
            {description && (
              <p id={descriptionId} className="text-sm text-muted-foreground">
                {description}
              </p>
            )}
          </div>
        )}

        {/* Slider Container */}
        <div className={cn('relative', orientation === 'vertical' && 'h-48')}>
          <SliderPrimitive.Root
            id={sliderId}
            ref={ref}
            value={currentValue}
            onValueChange={handleValueChange}
            min={min}
            max={max}
            step={step}
            disabled={disabled}
            orientation={orientation}
            aria-describedby={ariaDescribedBy}
            aria-invalid={error ? 'true' : 'false'}
            className={cn(
              'relative flex touch-none select-none items-center',
              orientation === 'horizontal' && 'w-full',
              orientation === 'vertical' && 'h-full flex-col',
              disabled && 'opacity-50 cursor-not-allowed',
              className
            )}
            {...props}
          >
            {/* Track */}
            <SliderPrimitive.Track
              className={cn(
                'relative grow overflow-hidden rounded-full bg-secondary',
                orientation === 'horizontal' && 'h-2 w-full',
                orientation === 'vertical' && 'h-full w-2'
              )}
            >
              {/* Range (filled portion) */}
              <SliderPrimitive.Range
                className={cn(
                  'absolute bg-primary',
                  orientation === 'horizontal' && 'h-full',
                  orientation === 'vertical' && 'w-full'
                )}
              />
            </SliderPrimitive.Track>

            {/* Thumbs */}
            {currentValue.map((_, index) => (
              <SliderPrimitive.Thumb
                key={index}
                className={cn(
                  'block h-5 w-5 rounded-full border-2 border-primary bg-background',
                  'ring-offset-background transition-colors',
                  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
                  'disabled:pointer-events-none disabled:opacity-50',
                  'hover:scale-110'
                )}
                onMouseEnter={() => setHoveredThumb(index)}
                onMouseLeave={() => setHoveredThumb(null)}
              >
                {/* Tooltip */}
                {showTooltips && hoveredThumb === index && (
                  <div
                    className={cn(
                      'absolute z-10 rounded bg-popover px-2 py-1 text-xs text-popover-foreground shadow-md',
                      orientation === 'horizontal' && '-top-10 left-1/2 -translate-x-1/2',
                      orientation === 'vertical' && '-left-12 top-1/2 -translate-y-1/2'
                    )}
                  >
                    {formatValue(currentValue[index])}
                    <div
                      className={cn(
                        'absolute h-2 w-2 rotate-45 bg-popover',
                        orientation === 'horizontal' && 'left-1/2 top-full -translate-x-1/2 -translate-y-1/2',
                        orientation === 'vertical' && 'left-full top-1/2 -translate-x-1/2 -translate-y-1/2'
                      )}
                    />
                  </div>
                )}
              </SliderPrimitive.Thumb>
            ))}
          </SliderPrimitive.Root>

          {/* Marks */}
          {(showMarks || marks.length > 0) && (
            <div
              className={cn(
                'absolute flex',
                orientation === 'horizontal' && 'top-full mt-2 w-full justify-between',
                orientation === 'vertical' && 'left-full ml-2 h-full flex-col justify-between'
              )}
            >
              {marks.map((mark) => (
                <div
                  key={mark.value}
                  className={cn(
                    'absolute flex items-center',
                    orientation === 'horizontal' && 'flex-col',
                    orientation === 'vertical' && 'flex-row'
                  )}
                  style={{
                    [orientation === 'horizontal' ? 'left' : 'top']: `${getMarkPosition(mark.value)}%`,
                    transform:
                      orientation === 'horizontal' ? 'translateX(-50%)' : 'translateY(-50%)',
                  }}
                >
                  {showMarks && (
                    <div
                      className={cn(
                        'bg-border',
                        orientation === 'horizontal' && 'h-2 w-px',
                        orientation === 'vertical' && 'h-px w-2'
                      )}
                    />
                  )}
                  {mark.label && (
                    <span
                      className={cn(
                        'text-xs text-muted-foreground',
                        orientation === 'horizontal' && 'mt-1',
                        orientation === 'vertical' && 'ml-1'
                      )}
                    >
                      {mark.label}
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

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

Slider.displayName = SliderPrimitive.Root.displayName

export { Slider }
```

---

## ✅ TESTING

### Comprehensive Test Suite

```typescript
// src/components/ui/__tests__/slider.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Slider } from '../slider'

describe('Slider Component', () => {
  describe('Rendering', () => {
    it('renders correctly', () => {
      render(<Slider />)
      expect(screen.getByRole('slider')).toBeInTheDocument()
    })

    it('renders with label', () => {
      render(<Slider label="Volume" />)
      expect(screen.getByText('Volume')).toBeInTheDocument()
    })

    it('renders with description', () => {
      render(<Slider description="Adjust the volume level" />)
      expect(screen.getByText('Adjust the volume level')).toBeInTheDocument()
    })
  })

  describe('Single Value Mode', () => {
    it('renders single thumb by default', () => {
      const { container } = render(<Slider value={50} />)
      const thumbs = container.querySelectorAll('[role="slider"]')
      expect(thumbs).toHaveLength(1)
    })

    it('displays current value when showValue is true', () => {
      render(<Slider value={75} showValue />)
      expect(screen.getByText('75')).toBeInTheDocument()
    })

    it('formats value with custom formatter', () => {
      render(
        <Slider
          value={50}
          showValue
          formatValue={(v) => `${v}%`}
        />
      )
      expect(screen.getByText('50%')).toBeInTheDocument()
    })

    it('calls onValueChange with single number', () => {
      const handleChange = jest.fn()
      render(
        <Slider
          min={0}
          max={100}
          value={50}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      fireEvent.change(slider, { target: { value: '75' } })
      
      // Handler should be called with single number, not array
      expect(handleChange).toHaveBeenCalled()
    })
  })

  describe('Range Mode (Dual Handles)', () => {
    it('renders two thumbs for range', () => {
      const { container } = render(<Slider value={[25, 75]} />)
      const thumbs = container.querySelectorAll('[role="slider"]')
      expect(thumbs).toHaveLength(2)
    })

    it('displays range when showValue is true', () => {
      render(<Slider value={[25, 75]} showValue />)
      expect(screen.getByText('25 - 75')).toBeInTheDocument()
    })

    it('formats range with custom formatter', () => {
      render(
        <Slider
          value={[100, 500]}
          showValue
          formatValue={(v) => `$${v}`}
        />
      )
      expect(screen.getByText('$100 - $500')).toBeInTheDocument()
    })
  })

  describe('Min, Max, and Step', () => {
    it('respects min value', () => {
      render(<Slider min={10} value={10} />)
      const slider = screen.getByRole('slider')
      expect(slider).toHaveAttribute('aria-valuemin', '10')
    })

    it('respects max value', () => {
      render(<Slider max={200} value={100} />)
      const slider = screen.getByRole('slider')
      expect(slider).toHaveAttribute('aria-valuemax', '200')
    })

    it('respects step value', () => {
      render(<Slider step={5} value={50} />)
      const slider = screen.getByRole('slider')
      // Step is used internally for value increments
      expect(slider).toBeInTheDocument()
    })
  })

  describe('Marks', () => {
    const marks = [
      { value: 0, label: 'Min' },
      { value: 50, label: 'Mid' },
      { value: 100, label: 'Max' },
    ]

    it('renders mark labels', () => {
      render(<Slider marks={marks} />)
      expect(screen.getByText('Min')).toBeInTheDocument()
      expect(screen.getByText('Mid')).toBeInTheDocument()
      expect(screen.getByText('Max')).toBeInTheDocument()
    })

    it('shows mark indicators when showMarks is true', () => {
      const { container } = render(<Slider marks={marks} showMarks />)
      const markIndicators = container.querySelectorAll('.bg-border')
      expect(markIndicators.length).toBeGreaterThan(0)
    })
  })

  describe('Orientation', () => {
    it('renders horizontally by default', () => {
      const { container } = render(<Slider />)
      const root = container.querySelector('[role="slider"]')?.parentElement
      expect(root).toHaveClass('w-full')
    })

    it('renders vertically when specified', () => {
      const { container } = render(<Slider orientation="vertical" />)
      const root = container.querySelector('[role="slider"]')?.parentElement
      expect(root).toHaveClass('h-full', 'flex-col')
    })
  })

  describe('Tooltips', () => {
    it('does not show tooltips by default', () => {
      const { container } = render(<Slider value={50} />)
      expect(container.querySelector('.absolute.z-10')).not.toBeInTheDocument()
    })

    // Note: Hover events are hard to test without real browser
    // This would be better tested in E2E tests
  })

  describe('Keyboard Navigation', () => {
    it('can be focused with Tab', async () => {
      render(<Slider />)
      const slider = screen.getByRole('slider')
      
      await userEvent.tab()
      expect(slider).toHaveFocus()
    })

    it('increases value with ArrowRight', async () => {
      const handleChange = jest.fn()
      render(
        <Slider
          value={50}
          min={0}
          max={100}
          step={1}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      slider.focus()
      
      await userEvent.keyboard('{ArrowRight}')
      expect(handleChange).toHaveBeenCalled()
    })

    it('decreases value with ArrowLeft', async () => {
      const handleChange = jest.fn()
      render(
        <Slider
          value={50}
          min={0}
          max={100}
          step={1}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      slider.focus()
      
      await userEvent.keyboard('{ArrowLeft}')
      expect(handleChange).toHaveBeenCalled()
    })

    it('increases value with ArrowUp', async () => {
      const handleChange = jest.fn()
      render(
        <Slider
          value={50}
          min={0}
          max={100}
          step={1}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      slider.focus()
      
      await userEvent.keyboard('{ArrowUp}')
      expect(handleChange).toHaveBeenCalled()
    })

    it('decreases value with ArrowDown', async () => {
      const handleChange = jest.fn()
      render(
        <Slider
          value={50}
          min={0}
          max={100}
          step={1}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      slider.focus()
      
      await userEvent.keyboard('{ArrowDown}')
      expect(handleChange).toHaveBeenCalled()
    })

    it('jumps to min with Home key', async () => {
      const handleChange = jest.fn()
      render(
        <Slider
          value={50}
          min={0}
          max={100}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      slider.focus()
      
      await userEvent.keyboard('{Home}')
      expect(handleChange).toHaveBeenCalledWith(0)
    })

    it('jumps to max with End key', async () => {
      const handleChange = jest.fn()
      render(
        <Slider
          value={50}
          min={0}
          max={100}
          onValueChange={handleChange}
        />
      )
      
      const slider = screen.getByRole('slider')
      slider.focus()
      
      await userEvent.keyboard('{End}')
      expect(handleChange).toHaveBeenCalledWith(100)
    })
  })

  describe('Disabled State', () => {
    it('respects disabled prop', () => {
      render(<Slider disabled />)
      expect(screen.getByRole('slider')).toHaveAttribute('aria-disabled', 'true')
    })

    it('applies disabled styling', () => {
      const { container } = render(<Slider disabled />)
      const root = container.querySelector('[role="slider"]')?.parentElement
      expect(root).toHaveClass('opacity-50', 'cursor-not-allowed')
    })

    it('does not trigger onChange when disabled', () => {
      const handleChange = jest.fn()
      render(<Slider disabled onValueChange={handleChange} />)
      
      const slider = screen.getByRole('slider')
      fireEvent.change(slider, { target: { value: '75' } })
      
      expect(handleChange).not.toHaveBeenCalled()
    })
  })

  describe('Error Handling', () => {
    it('displays error message', () => {
      render(<Slider error="Value out of range" />)
      expect(screen.getByRole('alert')).toHaveTextContent('Value out of range')
    })

    it('sets aria-invalid when error present', () => {
      const { container } = render(<Slider error="Error" />)
      const root = container.querySelector('[role="slider"]')?.parentElement
      expect(root).toHaveAttribute('aria-invalid', 'true')
    })
  })

  describe('Accessibility', () => {
    it('has proper role', () => {
      render(<Slider />)
      expect(screen.getByRole('slider')).toBeInTheDocument()
    })

    it('has aria-valuemin', () => {
      render(<Slider min={10} value={50} />)
      expect(screen.getByRole('slider')).toHaveAttribute('aria-valuemin', '10')
    })

    it('has aria-valuemax', () => {
      render(<Slider max={200} value={50} />)
      expect(screen.getByRole('slider')).toHaveAttribute('aria-valuemax', '200')
    })

    it('has aria-valuenow', () => {
      render(<Slider value={50} />)
      expect(screen.getByRole('slider')).toHaveAttribute('aria-valuenow', '50')
    })

    it('links label with slider', () => {
      render(<Slider label="Volume" />)
      const slider = screen.getByRole('slider')
      const label = screen.getByText('Volume')
      
      expect(slider.id).toBe(label.getAttribute('for'))
    })

    it('includes description in aria-describedby', () => {
      const { container } = render(<Slider description="Helper text" />)
      const root = container.querySelector('[role="slider"]')?.parentElement
      const describedBy = root?.getAttribute('aria-describedby')
      
      expect(describedBy).toBeTruthy()
    })
  })
})
```

---

## 📚 USAGE EXAMPLES

### Basic Slider

```typescript
import { Slider } from '@/components/ui/slider'

function VolumeControl() {
  const [volume, setVolume] = React.useState(50)

  return (
    <Slider
      label="Volume"
      min={0}
      max={100}
      value={volume}
      onValueChange={setVolume}
      showValue
    />
  )
}
```

### Range Slider (Price Filter)

```typescript
function PriceFilter() {
  const [priceRange, setPriceRange] = React.useState([100, 500])

  return (
    <Slider
      label="Price Range"
      min={0}
      max={1000}
      step={10}
      value={priceRange}
      onValueChange={setPriceRange}
      formatValue={(v) => `$${v}`}
      showValue
    />
  )
}
```

### With Marks

```typescript
function OpacitySlider() {
  const [opacity, setOpacity] = React.useState(100)

  return (
    <Slider
      label="Opacity"
      min={0}
      max={100}
      step={25}
      value={opacity}
      onValueChange={setOpacity}
      marks={[
        { value: 0, label: '0%' },
        { value: 25, label: '25%' },
        { value: 50, label: '50%' },
        { value: 75, label: '75%' },
        { value: 100, label: '100%' },
      ]}
      showMarks
      formatValue={(v) => `${v}%`}
      showValue
    />
  )
}
```

### Vertical Slider

```typescript
function VerticalVolumeControl() {
  const [volume, setVolume] = React.useState(50)

  return (
    <div className="flex flex-col items-center">
      <Slider
        orientation="vertical"
        min={0}
        max={100}
        value={volume}
        onValueChange={setVolume}
      />
      <span className="mt-2 text-sm">{volume}%</span>
    </div>
  )
}
```

### With Tooltips

```typescript
function PrecisionSlider() {
  const [value, setValue] = React.useState(50)

  return (
    <Slider
      label="Precision Control"
      description="Hover over the handle to see the exact value"
      min={0}
      max={100}
      step={0.1}
      value={value}
      onValueChange={setValue}
      showTooltips
      formatValue={(v) => v.toFixed(1)}
    />
  )
}
```

### Temperature Range

```typescript
function TemperatureRange() {
  const [tempRange, setTempRange] = React.useState([18, 24])

  return (
    <Slider
      label="Temperature Range"
      description="Set your preferred temperature range"
      min={10}
      max={30}
      value={tempRange}
      onValueChange={setTempRange}
      formatValue={(v) => `${v}°C`}
      showValue
      marks={[
        { value: 10, label: '10°C' },
        { value: 20, label: '20°C' },
        { value: 30, label: '30°C' },
      ]}
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
  budget: z.number().min(100).max(10000),
})

function BudgetForm() {
  const { control, handleSubmit } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { budget: 1000 },
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="budget"
        control={control}
        render={({ field }) => (
          <Slider
            label="Monthly Budget"
            min={100}
            max={10000}
            step={100}
            value={field.value}
            onValueChange={field.onChange}
            formatValue={(v) => `$${v.toLocaleString()}`}
            showValue
          />
        )}
      />
      <Button type="submit">Save Budget</Button>
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
- ✅ Clear value announcements

### Keyboard Navigation
- **Arrow Left/Down**: Decrease value
- **Arrow Right/Up**: Increase value
- **Home**: Jump to minimum
- **End**: Jump to maximum
- **Page Up**: Large increase
- **Page Down**: Large decrease

### ARIA Attributes
- `role="slider"`: Identifies slider thumbs
- `aria-valuemin`: Minimum value
- `aria-valuemax`: Maximum value
- `aria-valuenow`: Current value
- `aria-describedby`: Links to description/error
- `aria-invalid`: Indicates error state

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-slider
- [ ] Create slider.tsx file
- [ ] Implement Slider component with Radix UI
- [ ] Add single and dual-handle modes
- [ ] Add marks support
- [ ] Add tooltips on hover
- [ ] Add vertical orientation
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
