# SPEC-070: Accordion Component
## Collapsible Content Sections with Radix UI

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4 hours  
> **Dependencies**: Radix UI Accordion

---

## 📋 OVERVIEW

### Purpose
An accordion component that displays collapsible content panels. Built on Radix UI Accordion primitives for full accessibility, allowing users to expand and collapse sections of content to reduce page clutter and improve scannability.

### Key Features
- ✅ Single or multiple open items
- ✅ Collapsible when active
- ✅ Smooth animations
- ✅ Keyboard navigation
- ✅ Icon indicators
- ✅ Controlled and uncontrolled modes
- ✅ Custom styling per item
- ✅ Disabled items support
- ✅ Full accessibility
- ✅ Dark mode support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/accordion.tsx
'use client'

import * as React from 'react'
import * as AccordionPrimitive from '@radix-ui/react-accordion'
import { ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface AccordionProps
  extends React.ComponentPropsWithoutRef<typeof AccordionPrimitive.Root> {
  /**
   * Accordion type - single allows one open item, multiple allows many
   */
  type: 'single' | 'multiple'

  /**
   * Whether an open item can be collapsed (only for type="single")
   */
  collapsible?: boolean

  /**
   * Default open items (uncontrolled)
   */
  defaultValue?: string | string[]

  /**
   * Controlled open items
   */
  value?: string | string[]

  /**
   * Callback when open items change
   */
  onValueChange?: (value: string | string[]) => void

  /**
   * Accordion items
   */
  children: React.ReactNode
}

export interface AccordionItemProps
  extends React.ComponentPropsWithoutRef<typeof AccordionPrimitive.Item> {
  /**
   * Unique value for this item
   */
  value: string

  /**
   * Disable this item
   */
  disabled?: boolean
}

export interface AccordionTriggerProps
  extends React.ComponentPropsWithoutRef<typeof AccordionPrimitive.Trigger> {
  /**
   * Custom icon (defaults to ChevronDown)
   */
  icon?: React.ReactNode

  /**
   * Show icon
   */
  showIcon?: boolean
}

export interface AccordionContentProps
  extends React.ComponentPropsWithoutRef<typeof AccordionPrimitive.Content> {
  /**
   * Content to display
   */
  children: React.ReactNode
}

// ========================================
// ACCORDION ROOT
// ========================================

/**
 * Accordion Component
 * 
 * Root accordion container.
 * 
 * @example
 * <Accordion type="single" collapsible>
 *   <AccordionItem value="item-1">
 *     <AccordionTrigger>Title</AccordionTrigger>
 *     <AccordionContent>Content</AccordionContent>
 *   </AccordionItem>
 * </Accordion>
 */
const Accordion = AccordionPrimitive.Root

Accordion.displayName = 'Accordion'

// ========================================
// ACCORDION ITEM
// ========================================

/**
 * AccordionItem Component
 * 
 * Individual accordion item container.
 */
const AccordionItem = React.forwardRef<
  React.ElementRef<typeof AccordionPrimitive.Item>,
  AccordionItemProps
>(({ className, ...props }, ref) => (
  <AccordionPrimitive.Item
    ref={ref}
    className={cn('border-b', className)}
    {...props}
  />
))
AccordionItem.displayName = 'AccordionItem'

// ========================================
// ACCORDION TRIGGER
// ========================================

/**
 * AccordionTrigger Component
 * 
 * Button that toggles accordion item.
 */
const AccordionTrigger = React.forwardRef<
  React.ElementRef<typeof AccordionPrimitive.Trigger>,
  AccordionTriggerProps
>(({ className, children, icon, showIcon = true, ...props }, ref) => (
  <AccordionPrimitive.Header className="flex">
    <AccordionPrimitive.Trigger
      ref={ref}
      className={cn(
        'flex flex-1 items-center justify-between py-4 text-sm font-medium transition-all hover:underline text-left',
        '[&[data-state=open]>svg]:rotate-180',
        className
      )}
      {...props}
    >
      {children}
      {showIcon && (
        icon || <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground transition-transform duration-200" />
      )}
    </AccordionPrimitive.Trigger>
  </AccordionPrimitive.Header>
))
AccordionTrigger.displayName = AccordionPrimitive.Trigger.displayName

// ========================================
// ACCORDION CONTENT
// ========================================

/**
 * AccordionContent Component
 * 
 * Content panel that expands/collapses.
 */
const AccordionContent = React.forwardRef<
  React.ElementRef<typeof AccordionPrimitive.Content>,
  AccordionContentProps
>(({ className, children, ...props }, ref) => (
  <AccordionPrimitive.Content
    ref={ref}
    className="overflow-hidden text-sm data-[state=closed]:animate-accordion-up data-[state=open]:animate-accordion-down"
    {...props}
  >
    <div className={cn('pb-4 pt-0', className)}>{children}</div>
  </AccordionPrimitive.Content>
))
AccordionContent.displayName = AccordionPrimitive.Content.displayName

// ========================================
// EXPORTS
// ========================================

export { Accordion, AccordionItem, AccordionTrigger, AccordionContent }
```

### Animations (tailwind.config.ts)

```typescript
// Add to tailwind.config.ts
module.exports = {
  theme: {
    extend: {
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },
    },
  },
}
```

---

## 📚 USAGE EXAMPLES

### Basic Accordion

```typescript
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from '@/components/ui/accordion'

function BasicAccordion() {
  return (
    <Accordion type="single" collapsible className="w-full">
      <AccordionItem value="item-1">
        <AccordionTrigger>Is it accessible?</AccordionTrigger>
        <AccordionContent>
          Yes. It adheres to the WAI-ARIA design pattern.
        </AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-2">
        <AccordionTrigger>Is it styled?</AccordionTrigger>
        <AccordionContent>
          Yes. It comes with default styles that matches the other components' aesthetic.
        </AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-3">
        <AccordionTrigger>Is it animated?</AccordionTrigger>
        <AccordionContent>
          Yes. It's animated by default, but you can disable it if you prefer.
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  )
}
```

### Multiple Items Open

```typescript
function MultipleAccordion() {
  return (
    <Accordion type="multiple" className="w-full">
      <AccordionItem value="item-1">
        <AccordionTrigger>Section 1</AccordionTrigger>
        <AccordionContent>
          Multiple sections can be open at the same time.
        </AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-2">
        <AccordionTrigger>Section 2</AccordionTrigger>
        <AccordionContent>
          This is also open while Section 1 is open.
        </AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-3">
        <AccordionTrigger>Section 3</AccordionTrigger>
        <AccordionContent>
          And this one too!
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  )
}
```

### FAQ Section

```typescript
function FAQAccordion() {
  const faqs = [
    {
      question: 'What is your refund policy?',
      answer: 'We offer a 30-day money-back guarantee on all purchases. If you\'re not satisfied with your purchase, contact our support team for a full refund.',
    },
    {
      question: 'How do I track my order?',
      answer: 'Once your order ships, you\'ll receive an email with a tracking number. You can use this number on our tracking page or the carrier\'s website to monitor your package.',
    },
    {
      question: 'Do you ship internationally?',
      answer: 'Yes! We ship to over 50 countries worldwide. International shipping times vary by location but typically take 7-14 business days.',
    },
    {
      question: 'What payment methods do you accept?',
      answer: 'We accept all major credit cards (Visa, MasterCard, American Express), PayPal, Apple Pay, and Google Pay.',
    },
    {
      question: 'Can I change or cancel my order?',
      answer: 'You can modify or cancel your order within 24 hours of placing it. After that, it may have already been processed for shipping.',
    },
  ]

  return (
    <div className="max-w-3xl mx-auto">
      <h2 className="text-3xl font-bold mb-6">Frequently Asked Questions</h2>
      <Accordion type="single" collapsible className="w-full">
        {faqs.map((faq, index) => (
          <AccordionItem key={index} value={`faq-${index}`}>
            <AccordionTrigger className="text-left">
              {faq.question}
            </AccordionTrigger>
            <AccordionContent className="text-muted-foreground">
              {faq.answer}
            </AccordionContent>
          </AccordionItem>
        ))}
      </Accordion>
    </div>
  )
}
```

### Controlled Accordion

```typescript
function ControlledAccordion() {
  const [value, setValue] = React.useState<string>('item-1')

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <Button onClick={() => setValue('item-1')}>Open Section 1</Button>
        <Button onClick={() => setValue('item-2')}>Open Section 2</Button>
        <Button onClick={() => setValue('item-3')}>Open Section 3</Button>
      </div>

      <Accordion type="single" value={value} onValueChange={setValue}>
        <AccordionItem value="item-1">
          <AccordionTrigger>Section 1</AccordionTrigger>
          <AccordionContent>Content for section 1</AccordionContent>
        </AccordionItem>

        <AccordionItem value="item-2">
          <AccordionTrigger>Section 2</AccordionTrigger>
          <AccordionContent>Content for section 2</AccordionContent>
        </AccordionItem>

        <AccordionItem value="item-3">
          <AccordionTrigger>Section 3</AccordionTrigger>
          <AccordionContent>Content for section 3</AccordionContent>
        </AccordionItem>
      </Accordion>

      <p className="text-sm text-muted-foreground">
        Currently open: {value || 'none'}
      </p>
    </div>
  )
}
```

### Custom Icon

```typescript
import { Plus, Minus } from 'lucide-react'

function CustomIconAccordion() {
  return (
    <Accordion type="single" collapsible>
      <AccordionItem value="item-1">
        <AccordionTrigger 
          icon={<Plus className="h-4 w-4 transition-transform [&[data-state=open]]:hidden" />}
        >
          Custom Plus/Minus Icons
        </AccordionTrigger>
        <AccordionContent>
          This uses custom icons instead of the default chevron.
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  )
}
```

### With Card Styling

```typescript
import { Card } from '@/components/ui/card'

function StyledAccordion() {
  return (
    <Card>
      <Accordion type="single" collapsible>
        <AccordionItem value="item-1" className="border-b-0">
          <AccordionTrigger className="px-6">
            Premium Features
          </AccordionTrigger>
          <AccordionContent className="px-6">
            <ul className="list-disc list-inside space-y-2">
              <li>Advanced analytics dashboard</li>
              <li>Priority customer support</li>
              <li>Custom integrations</li>
              <li>Unlimited team members</li>
            </ul>
          </AccordionContent>
        </AccordionItem>

        <AccordionItem value="item-2" className="border-b-0">
          <AccordionTrigger className="px-6">
            Standard Features
          </AccordionTrigger>
          <AccordionContent className="px-6">
            <ul className="list-disc list-inside space-y-2">
              <li>Basic analytics</li>
              <li>Email support</li>
              <li>Up to 10 team members</li>
            </ul>
          </AccordionContent>
        </AccordionItem>
      </Accordion>
    </Card>
  )
}
```

### Disabled Items

```typescript
function DisabledAccordion() {
  return (
    <Accordion type="single" collapsible>
      <AccordionItem value="item-1">
        <AccordionTrigger>Available Section</AccordionTrigger>
        <AccordionContent>This section is accessible.</AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-2" disabled>
        <AccordionTrigger className="opacity-50 cursor-not-allowed">
          Disabled Section
        </AccordionTrigger>
        <AccordionContent>This content won't show.</AccordionContent>
      </AccordionItem>

      <AccordionItem value="item-3">
        <AccordionTrigger>Another Available Section</AccordionTrigger>
        <AccordionContent>This section is also accessible.</AccordionContent>
      </AccordionItem>
    </Accordion>
  )
}
```

---

## 🧪 TESTING

```typescript
// src/components/ui/__tests__/accordion.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from '../accordion'

describe('Accordion', () => {
  it('renders accordion items', () => {
    render(
      <Accordion type="single">
        <AccordionItem value="item-1">
          <AccordionTrigger>Trigger</AccordionTrigger>
          <AccordionContent>Content</AccordionContent>
        </AccordionItem>
      </Accordion>
    )

    expect(screen.getByText('Trigger')).toBeInTheDocument()
  })

  it('expands item when trigger is clicked', () => {
    render(
      <Accordion type="single" collapsible>
        <AccordionItem value="item-1">
          <AccordionTrigger>Trigger</AccordionTrigger>
          <AccordionContent>Content</AccordionContent>
        </AccordionItem>
      </Accordion>
    )

    const trigger = screen.getByText('Trigger')
    fireEvent.click(trigger)
    
    expect(screen.getByText('Content')).toBeVisible()
  })

  it('collapses item when clicked again (collapsible mode)', () => {
    render(
      <Accordion type="single" collapsible>
        <AccordionItem value="item-1">
          <AccordionTrigger>Trigger</AccordionTrigger>
          <AccordionContent>Content</AccordionContent>
        </AccordionItem>
      </Accordion>
    )

    const trigger = screen.getByText('Trigger')
    
    // Open
    fireEvent.click(trigger)
    expect(screen.getByText('Content')).toBeVisible()
    
    // Close
    fireEvent.click(trigger)
    expect(screen.queryByText('Content')).not.toBeVisible()
  })

  it('allows multiple items open with type="multiple"', () => {
    render(
      <Accordion type="multiple">
        <AccordionItem value="item-1">
          <AccordionTrigger>Trigger 1</AccordionTrigger>
          <AccordionContent>Content 1</AccordionContent>
        </AccordionItem>
        <AccordionItem value="item-2">
          <AccordionTrigger>Trigger 2</AccordionTrigger>
          <AccordionContent>Content 2</AccordionContent>
        </AccordionItem>
      </Accordion>
    )

    fireEvent.click(screen.getByText('Trigger 1'))
    fireEvent.click(screen.getByText('Trigger 2'))
    
    expect(screen.getByText('Content 1')).toBeVisible()
    expect(screen.getByText('Content 2')).toBeVisible()
  })

  it('supports keyboard navigation', () => {
    render(
      <Accordion type="single">
        <AccordionItem value="item-1">
          <AccordionTrigger>Trigger 1</AccordionTrigger>
          <AccordionContent>Content 1</AccordionContent>
        </AccordionItem>
        <AccordionItem value="item-2">
          <AccordionTrigger>Trigger 2</AccordionTrigger>
          <AccordionContent>Content 2</AccordionContent>
        </AccordionItem>
      </Accordion>
    )

    const trigger1 = screen.getByText('Trigger 1')
    trigger1.focus()
    
    fireEvent.keyDown(trigger1, { key: 'Enter' })
    expect(screen.getByText('Content 1')).toBeVisible()
  })

  it('respects disabled prop', () => {
    render(
      <Accordion type="single">
        <AccordionItem value="item-1" disabled>
          <AccordionTrigger>Disabled Trigger</AccordionTrigger>
          <AccordionContent>Disabled Content</AccordionContent>
        </AccordionItem>
      </Accordion>
    )

    const trigger = screen.getByText('Disabled Trigger')
    fireEvent.click(trigger)
    
    expect(screen.queryByText('Disabled Content')).not.toBeVisible()
  })
})
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Keyboard navigation (Enter/Space to toggle)
- ✅ Arrow keys to move between items
- ✅ Home/End keys to jump to first/last
- ✅ Focus indicators
- ✅ ARIA attributes (aria-expanded, aria-controls)
- ✅ Semantic HTML structure
- ✅ Screen reader support

### Keyboard Shortcuts
- **Enter/Space**: Toggle accordion item
- **Arrow Down**: Focus next trigger
- **Arrow Up**: Focus previous trigger
- **Home**: Focus first trigger
- **End**: Focus last trigger

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @radix-ui/react-accordion
- [ ] Create accordion.tsx file
- [ ] Implement Accordion root component
- [ ] Implement AccordionItem component
- [ ] Implement AccordionTrigger with icon
- [ ] Implement AccordionContent with animation
- [ ] Add accordion animations to tailwind.config
- [ ] Write comprehensive tests
- [ ] Test keyboard navigation
- [ ] Test screen reader compatibility
- [ ] Create Storybook stories
- [ ] Document usage patterns

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
