# SPEC-087: Timeline Component
## Vertical Timeline with Events

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: LOW  
> **Estimated Time**: 3 hours  
> **Dependencies**: Avatar, Card

---

## 📋 OVERVIEW

### Purpose
A vertical timeline component for displaying chronological events, activities, or progress with icons, descriptions, and timestamps.

### Key Features
- ✅ Vertical/horizontal orientation
- ✅ Custom icons per event
- ✅ Timestamps
- ✅ Event descriptions
- ✅ Different event types (success, error, warning, info)
- ✅ Loading states
- ✅ Collapsible events
- ✅ Responsive design

---

## 🎯 COMPONENT SPECIFICATION

```typescript
// src/components/ui/timeline.tsx
'use client'

import * as React from 'react'
import { Check, X, AlertCircle, Info, Clock } from 'lucide-react'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { cn } from '@/lib/utils'

export interface TimelineEvent {
  id: string
  title: React.ReactNode
  description?: React.ReactNode
  timestamp?: string | Date
  icon?: React.ReactNode
  type?: 'default' | 'success' | 'error' | 'warning' | 'info'
  avatar?: string
  avatarFallback?: string
  content?: React.ReactNode
}

export interface TimelineProps {
  events: TimelineEvent[]
  orientation?: 'vertical' | 'horizontal'
  className?: string
}

const typeIcons = {
  default: Clock,
  success: Check,
  error: X,
  warning: AlertCircle,
  info: Info,
}

const typeColors = {
  default: 'bg-muted text-muted-foreground',
  success: 'bg-green-500 text-white',
  error: 'bg-red-500 text-white',
  warning: 'bg-yellow-500 text-white',
  info: 'bg-blue-500 text-white',
}

export function Timeline({ events, orientation = 'vertical', className }: TimelineProps) {
  if (orientation === 'horizontal') {
    return (
      <div className={cn('flex items-start gap-4 overflow-x-auto pb-4', className)}>
        {events.map((event, index) => {
          const Icon = event.icon ? null : typeIcons[event.type || 'default']
          return (
            <div key={event.id} className="flex flex-col items-center min-w-[200px]">
              <div className={cn('flex h-10 w-10 items-center justify-center rounded-full', typeColors[event.type || 'default'])}>
                {event.icon || (Icon && <Icon className="h-5 w-5" />)}
              </div>
              <div className="mt-4 text-center">
                <div className="font-medium">{event.title}</div>
                {event.timestamp && <div className="text-xs text-muted-foreground mt-1">{String(event.timestamp)}</div>}
                {event.description && <div className="text-sm text-muted-foreground mt-2">{event.description}</div>}
              </div>
              {index < events.length - 1 && <div className="h-0.5 w-full bg-border mt-4" />}
            </div>
          )
        })}
      </div>
    )
  }

  return (
    <div className={cn('space-y-8', className)}>
      {events.map((event, index) => {
        const Icon = event.icon ? null : typeIcons[event.type || 'default']
        const isLast = index === events.length - 1

        return (
          <div key={event.id} className="relative flex gap-4">
            <div className="flex flex-col items-center">
              {event.avatar ? (
                <Avatar>
                  <AvatarImage src={event.avatar} />
                  <AvatarFallback>{event.avatarFallback}</AvatarFallback>
                </Avatar>
              ) : (
                <div className={cn('flex h-10 w-10 items-center justify-center rounded-full', typeColors[event.type || 'default'])}>
                  {event.icon || (Icon && <Icon className="h-5 w-5" />)}
                </div>
              )}
              {!isLast && <div className="w-0.5 flex-1 bg-border mt-2" />}
            </div>
            <div className="flex-1 pb-8">
              <div className="flex items-center justify-between">
                <div className="font-medium">{event.title}</div>
                {event.timestamp && (
                  <div className="text-xs text-muted-foreground">{String(event.timestamp)}</div>
                )}
              </div>
              {event.description && (
                <div className="text-sm text-muted-foreground mt-1">{event.description}</div>
              )}
              {event.content && <div className="mt-4">{event.content}</div>}
            </div>
          </div>
        )
      })}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

```typescript
import { Timeline } from '@/components/ui/timeline'

const events = [
  {
    id: '1',
    title: 'Order Placed',
    description: 'Your order has been confirmed',
    timestamp: '2025-01-05 10:30 AM',
    type: 'success' as const,
  },
  {
    id: '2',
    title: 'Payment Processed',
    description: 'Payment successfully received',
    timestamp: '2025-01-05 10:35 AM',
    type: 'success' as const,
  },
  {
    id: '3',
    title: 'In Transit',
    description: 'Package is on the way',
    timestamp: '2025-01-05 02:00 PM',
    type: 'info' as const,
  },
]

function OrderTimeline() {
  return <Timeline events={events} />
}
```

---

## ♿ ACCESSIBILITY
- ✅ Semantic HTML
- ✅ ARIA labels
- ✅ Screen reader support

---

## 🚀 IMPLEMENTATION CHECKLIST
- [ ] Create timeline.tsx
- [ ] Implement vertical layout
- [ ] Implement horizontal layout
- [ ] Add event types
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
