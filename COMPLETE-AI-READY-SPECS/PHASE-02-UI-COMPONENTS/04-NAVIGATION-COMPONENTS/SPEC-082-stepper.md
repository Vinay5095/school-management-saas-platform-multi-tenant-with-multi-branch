# SPEC-082: Stepper Component
## Step Progress Indicator for Multi-Step Processes

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4 hours  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
A stepper component to guide users through multi-step processes with visual progress indication, step validation, and navigation controls.

### Key Features
- ✅ Horizontal/vertical orientation
- ✅ Step status (pending, active, completed, error)
- ✅ Clickable/non-clickable steps
- ✅ Step validation
- ✅ Custom icons
- ✅ Optional descriptions
- ✅ Progress bar
- ✅ Responsive design
- ✅ Keyboard navigation
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/stepper.tsx
'use client'

import * as React from 'react'
import { Check, Circle, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type StepStatus = 'pending' | 'active' | 'completed' | 'error'

export interface Step {
  /**
   * Step label
   */
  label: string

  /**
   * Step description (optional)
   */
  description?: string

  /**
   * Custom icon (optional)
   */
  icon?: React.ReactNode

  /**
   * Step status (optional, auto-calculated by default)
   */
  status?: StepStatus

  /**
   * Disabled state
   */
  disabled?: boolean

  /**
   * Optional validation function
   */
  validate?: () => boolean | Promise<boolean>
}

export interface StepperProps {
  /**
   * Steps array
   */
  steps: Step[]

  /**
   * Current active step (0-indexed)
   */
  activeStep: number

  /**
   * Step change callback
   */
  onStepChange?: (step: number) => void

  /**
   * Orientation
   */
  orientation?: 'horizontal' | 'vertical'

  /**
   * Allow clicking on steps
   */
  clickable?: boolean

  /**
   * Show step numbers
   */
  showNumbers?: boolean

  /**
   * Show descriptions
   */
  showDescriptions?: boolean

  /**
   * Show progress bar (horizontal only)
   */
  showProgressBar?: boolean

  /**
   * Size variant
   */
  size?: 'sm' | 'md' | 'lg'

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// STEP ICON COMPONENT
// ========================================

interface StepIconProps {
  step: Step
  index: number
  status: StepStatus
  showNumbers: boolean
  size: 'sm' | 'md' | 'lg'
}

function StepIcon({ step, index, status, showNumbers, size }: StepIconProps) {
  const sizeClasses = {
    sm: 'h-6 w-6 text-xs',
    md: 'h-8 w-8 text-sm',
    lg: 'h-10 w-10 text-base',
  }

  const iconSizes = {
    sm: 'h-3 w-3',
    md: 'h-4 w-4',
    lg: 'h-5 w-5',
  }

  // Custom icon
  if (step.icon) {
    return (
      <div
        className={cn(
          'flex items-center justify-center rounded-full font-medium',
          sizeClasses[size],
          status === 'completed' && 'bg-primary text-primary-foreground',
          status === 'active' && 'bg-primary text-primary-foreground ring-4 ring-primary/20',
          status === 'error' && 'bg-destructive text-destructive-foreground',
          status === 'pending' && 'bg-muted text-muted-foreground'
        )}
      >
        {step.icon}
      </div>
    )
  }

  // Status icons
  if (status === 'completed') {
    return (
      <div
        className={cn(
          'flex items-center justify-center rounded-full bg-primary text-primary-foreground',
          sizeClasses[size]
        )}
      >
        <Check className={iconSizes[size]} />
      </div>
    )
  }

  if (status === 'error') {
    return (
      <div
        className={cn(
          'flex items-center justify-center rounded-full bg-destructive text-destructive-foreground',
          sizeClasses[size]
        )}
      >
        <AlertCircle className={iconSizes[size]} />
      </div>
    )
  }

  // Number or pending circle
  return (
    <div
      className={cn(
        'flex items-center justify-center rounded-full font-medium',
        sizeClasses[size],
        status === 'active' && 'bg-primary text-primary-foreground ring-4 ring-primary/20',
        status === 'pending' && 'bg-muted text-muted-foreground'
      )}
    >
      {showNumbers ? (
        index + 1
      ) : (
        <Circle className={cn(iconSizes[size], status === 'active' && 'fill-current')} />
      )}
    </div>
  )
}

// ========================================
// STEPPER COMPONENT
// ========================================

/**
 * Stepper Component
 * 
 * Guide users through multi-step processes.
 * 
 * @example
 * <Stepper
 *   steps={steps}
 *   activeStep={activeStep}
 *   onStepChange={setActiveStep}
 * />
 */
export function Stepper({
  steps,
  activeStep,
  onStepChange,
  orientation = 'horizontal',
  clickable = false,
  showNumbers = true,
  showDescriptions = true,
  showProgressBar = true,
  size = 'md',
  className,
}: StepperProps) {
  // Calculate step statuses
  const getStepStatus = (index: number, step: Step): StepStatus => {
    if (step.status) return step.status
    if (index < activeStep) return 'completed'
    if (index === activeStep) return 'active'
    return 'pending'
  }

  const handleStepClick = (index: number, step: Step) => {
    if (!clickable || step.disabled || index > activeStep) return
    onStepChange?.(index)
  }

  const progressPercentage = ((activeStep + 1) / steps.length) * 100

  if (orientation === 'vertical') {
    return (
      <div className={cn('flex flex-col', className)}>
        {steps.map((step, index) => {
          const status = getStepStatus(index, step)
          const isLast = index === steps.length - 1
          const isClickable = clickable && !step.disabled && index <= activeStep

          return (
            <div key={index} className="flex gap-4">
              {/* Icon Column */}
              <div className="flex flex-col items-center">
                <button
                  onClick={() => handleStepClick(index, step)}
                  disabled={!isClickable}
                  className={cn(
                    'transition-all',
                    isClickable && 'cursor-pointer hover:scale-110',
                    !isClickable && 'cursor-default'
                  )}
                  aria-current={status === 'active' ? 'step' : undefined}
                >
                  <StepIcon
                    step={step}
                    index={index}
                    status={status}
                    showNumbers={showNumbers}
                    size={size}
                  />
                </button>
                {!isLast && (
                  <div
                    className={cn(
                      'w-0.5 flex-1 my-2',
                      status === 'completed' ? 'bg-primary' : 'bg-muted'
                    )}
                  />
                )}
              </div>

              {/* Content Column */}
              <div className={cn('flex-1', !isLast && 'pb-8')}>
                <button
                  onClick={() => handleStepClick(index, step)}
                  disabled={!isClickable}
                  className={cn(
                    'text-left transition-colors',
                    isClickable && 'cursor-pointer hover:text-primary',
                    !isClickable && 'cursor-default'
                  )}
                >
                  <div
                    className={cn(
                      'font-medium',
                      status === 'active' && 'text-foreground',
                      status === 'completed' && 'text-foreground',
                      status === 'pending' && 'text-muted-foreground',
                      status === 'error' && 'text-destructive'
                    )}
                  >
                    {step.label}
                  </div>
                  {showDescriptions && step.description && (
                    <div className="text-sm text-muted-foreground mt-1">
                      {step.description}
                    </div>
                  )}
                </button>
              </div>
            </div>
          )
        })}
      </div>
    )
  }

  // Horizontal orientation
  return (
    <div className={cn('w-full', className)}>
      {/* Progress Bar */}
      {showProgressBar && (
        <div className="w-full h-1 bg-muted rounded-full mb-8">
          <div
            className="h-full bg-primary rounded-full transition-all duration-300"
            style={{ width: `${progressPercentage}%` }}
          />
        </div>
      )}

      {/* Steps */}
      <div className="flex items-start justify-between">
        {steps.map((step, index) => {
          const status = getStepStatus(index, step)
          const isLast = index === steps.length - 1
          const isClickable = clickable && !step.disabled && index <= activeStep

          return (
            <React.Fragment key={index}>
              <div className="flex flex-col items-center gap-2 flex-1">
                <button
                  onClick={() => handleStepClick(index, step)}
                  disabled={!isClickable}
                  className={cn(
                    'transition-all',
                    isClickable && 'cursor-pointer hover:scale-110',
                    !isClickable && 'cursor-default'
                  )}
                  aria-current={status === 'active' ? 'step' : undefined}
                >
                  <StepIcon
                    step={step}
                    index={index}
                    status={status}
                    showNumbers={showNumbers}
                    size={size}
                  />
                </button>
                <button
                  onClick={() => handleStepClick(index, step)}
                  disabled={!isClickable}
                  className={cn(
                    'text-center transition-colors',
                    isClickable && 'cursor-pointer hover:text-primary',
                    !isClickable && 'cursor-default'
                  )}
                >
                  <div
                    className={cn(
                      'text-sm font-medium',
                      status === 'active' && 'text-foreground',
                      status === 'completed' && 'text-foreground',
                      status === 'pending' && 'text-muted-foreground',
                      status === 'error' && 'text-destructive'
                    )}
                  >
                    {step.label}
                  </div>
                  {showDescriptions && step.description && (
                    <div className="text-xs text-muted-foreground mt-1">
                      {step.description}
                    </div>
                  )}
                </button>
              </div>
              {!isLast && (
                <div className="flex items-center pt-4 flex-shrink-0 w-12">
                  <div
                    className={cn(
                      'h-0.5 w-full',
                      status === 'completed' ? 'bg-primary' : 'bg-muted'
                    )}
                  />
                </div>
              )}
            </React.Fragment>
          )
        })}
      </div>
    </div>
  )
}

// ========================================
// STEPPER CONTROLS
// ========================================

export interface StepperControlsProps {
  /**
   * Current step
   */
  activeStep: number

  /**
   * Total steps
   */
  totalSteps: number

  /**
   * Next button callback
   */
  onNext?: () => void

  /**
   * Previous button callback
   */
  onPrevious?: () => void

  /**
   * Finish button callback
   */
  onFinish?: () => void

  /**
   * Next button disabled
   */
  nextDisabled?: boolean

  /**
   * Previous button disabled
   */
  previousDisabled?: boolean

  /**
   * Show finish button on last step
   */
  showFinish?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

/**
 * Stepper Controls
 * 
 * Navigation controls for stepper.
 */
export function StepperControls({
  activeStep,
  totalSteps,
  onNext,
  onPrevious,
  onFinish,
  nextDisabled = false,
  previousDisabled = false,
  showFinish = true,
  className,
}: StepperControlsProps) {
  const isFirstStep = activeStep === 0
  const isLastStep = activeStep === totalSteps - 1

  return (
    <div className={cn('flex justify-between', className)}>
      <Button
        variant="outline"
        onClick={onPrevious}
        disabled={isFirstStep || previousDisabled}
      >
        Previous
      </Button>
      {isLastStep && showFinish ? (
        <Button onClick={onFinish} disabled={nextDisabled}>
          Finish
        </Button>
      ) : (
        <Button onClick={onNext} disabled={nextDisabled}>
          Next
        </Button>
      )}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Stepper

```typescript
import { Stepper, StepperControls } from '@/components/ui/stepper'

function MultiStepForm() {
  const [activeStep, setActiveStep] = React.useState(0)

  const steps = [
    { label: 'Personal Info', description: 'Enter your details' },
    { label: 'Address', description: 'Provide your address' },
    { label: 'Review', description: 'Review and submit' },
  ]

  return (
    <div>
      <Stepper steps={steps} activeStep={activeStep} />
      
      <div className="my-8">
        {/* Step content */}
      </div>

      <StepperControls
        activeStep={activeStep}
        totalSteps={steps.length}
        onNext={() => setActiveStep(activeStep + 1)}
        onPrevious={() => setActiveStep(activeStep - 1)}
        onFinish={() => console.log('Finished!')}
      />
    </div>
  )
}
```

### Vertical Stepper

```typescript
function VerticalStepper() {
  return (
    <div className="flex gap-8">
      <Stepper
        steps={steps}
        activeStep={activeStep}
        orientation="vertical"
        onStepChange={setActiveStep}
        clickable
      />
      <div className="flex-1">
        {/* Step content */}
      </div>
    </div>
  )
}
```

### With Custom Icons

```typescript
import { User, MapPin, Check } from 'lucide-react'

const steps = [
  {
    label: 'Account',
    icon: <User className="h-4 w-4" />,
  },
  {
    label: 'Location',
    icon: <MapPin className="h-4 w-4" />,
  },
  {
    label: 'Complete',
    icon: <Check className="h-4 w-4" />,
  },
]
```

### With Validation

```typescript
function ValidatedStepper() {
  const [activeStep, setActiveStep] = React.useState(0)
  const [errors, setErrors] = React.useState<Record<number, boolean>>({})

  const steps = [
    {
      label: 'Step 1',
      validate: () => {
        const isValid = form.step1.isValid()
        setErrors({ ...errors, 0: !isValid })
        return isValid
      },
    },
    // ... more steps
  ]

  const handleNext = async () => {
    const currentStep = steps[activeStep]
    if (currentStep.validate) {
      const isValid = await currentStep.validate()
      if (!isValid) return
    }
    setActiveStep(activeStep + 1)
  }

  return (
    <>
      <Stepper
        steps={steps.map((step, index) => ({
          ...step,
          status: errors[index] ? 'error' : undefined,
        }))}
        activeStep={activeStep}
      />
      <StepperControls
        activeStep={activeStep}
        totalSteps={steps.length}
        onNext={handleNext}
        onPrevious={() => setActiveStep(activeStep - 1)}
      />
    </>
  )
}
```

---

## 🧪 TESTING

```typescript
describe('Stepper', () => {
  it('renders all steps', () => {
    render(<Stepper steps={steps} activeStep={0} />)
    expect(screen.getByText('Step 1')).toBeInTheDocument()
  })

  it('highlights active step', () => {
    render(<Stepper steps={steps} activeStep={1} />)
    const activeStep = screen.getByText('Step 2').closest('button')
    expect(activeStep).toHaveAttribute('aria-current', 'step')
  })

  it('handles step clicks when clickable', () => {
    const onStepChange = jest.fn()
    render(
      <Stepper
        steps={steps}
        activeStep={2}
        onStepChange={onStepChange}
        clickable
      />
    )
    fireEvent.click(screen.getByText('Step 1'))
    expect(onStepChange).toHaveBeenCalledWith(0)
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ ARIA attributes
- ✅ Current step indicator
- ✅ Keyboard navigation
- ✅ Focus indicators
- ✅ Status announcements
- ✅ Disabled states

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create stepper.tsx
- [ ] Implement horizontal layout
- [ ] Implement vertical layout
- [ ] Add step icons
- [ ] Add progress bar
- [ ] Add clickable steps
- [ ] Create stepper controls
- [ ] Add validation support
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
