# SPEC-108: Timetable View Component
## Class Schedule and Timetable Display

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2.5 hours  
> **Dependencies**: date-fns

---

## 📋 OVERVIEW

### Purpose
A comprehensive timetable component for displaying class schedules, periods, teacher assignments, and room allocations with daily, weekly, and monthly views.

### Key Features
- ✅ Weekly timetable grid
- ✅ Daily schedule view
- ✅ Period details (subject, teacher, room)
- ✅ Current period highlighting
- ✅ Break periods
- ✅ Substitute teacher notifications
- ✅ Room change alerts
- ✅ Export to calendar
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/timetable-view.tsx
import * as React from 'react'
import { Clock, MapPin, User, Calendar, Bell, Download } from 'lucide-react'
import { format, addDays, startOfWeek, isSameDay, isToday } from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type DayOfWeek = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday'

export interface Period {
  id: string
  periodNumber: number
  startTime: string
  endTime: string
  subjectId?: string
  subjectName?: string
  subjectCode?: string
  teacherId?: string
  teacherName?: string
  roomNumber?: string
  isBreak?: boolean
  breakType?: 'short' | 'lunch' | 'long'
  isSubstitute?: boolean
  substituteTeacher?: string
  notes?: string
}

export interface DaySchedule {
  day: DayOfWeek
  date?: Date
  periods: Period[]
}

export interface TimetableData {
  classId: string
  className: string
  section: string
  academicYear: string
  schedule: DaySchedule[]
}

export interface TimetableViewProps {
  /**
   * Timetable data
   */
  data: TimetableData

  /**
   * View mode
   */
  view?: 'daily' | 'weekly'

  /**
   * Selected date (for daily view)
   */
  selectedDate?: Date

  /**
   * Highlight current period
   */
  highlightCurrent?: boolean

  /**
   * Show teacher names
   */
  showTeachers?: boolean

  /**
   * Show room numbers
   */
  showRooms?: boolean

  /**
   * On period click
   */
  onPeriodClick?: (period: Period) => void

  /**
   * On export
   */
  onExport?: () => void

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// PERIOD CARD
// ========================================

interface PeriodCardProps {
  period: Period
  isCurrentPeriod?: boolean
  showTeacher?: boolean
  showRoom?: boolean
  onClick?: () => void
}

function PeriodCard({
  period,
  isCurrentPeriod,
  showTeacher = true,
  showRoom = true,
  onClick,
}: PeriodCardProps) {
  if (period.isBreak) {
    return (
      <div
        className={cn(
          'p-3 rounded-lg border-2 border-dashed bg-muted/50 text-center',
          isCurrentPeriod && 'ring-2 ring-primary'
        )}
      >
        <Bell className="h-4 w-4 mx-auto mb-1 text-muted-foreground" />
        <p className="text-sm font-medium text-muted-foreground">
          {period.breakType === 'lunch' ? 'Lunch Break' : 'Break'}
        </p>
        <p className="text-xs text-muted-foreground">
          {period.startTime} - {period.endTime}
        </p>
      </div>
    )
  }

  return (
    <div
      onClick={onClick}
      className={cn(
        'p-3 rounded-lg border-2 transition-all cursor-pointer hover:shadow-md',
        isCurrentPeriod
          ? 'bg-primary/10 border-primary ring-2 ring-primary'
          : 'bg-card border-border hover:border-primary/50',
        period.isSubstitute && 'border-orange-500 bg-orange-50 dark:bg-orange-950'
      )}
    >
      {/* Period number and time */}
      <div className="flex items-center justify-between mb-2">
        <Badge variant="outline" className="text-xs">
          Period {period.periodNumber}
        </Badge>
        <div className="flex items-center gap-1 text-xs text-muted-foreground">
          <Clock className="h-3 w-3" />
          <span>
            {period.startTime} - {period.endTime}
          </span>
        </div>
      </div>

      {/* Subject */}
      <div className="space-y-1">
        <h4 className="font-semibold text-sm">{period.subjectName}</h4>
        {period.subjectCode && (
          <p className="text-xs text-muted-foreground">{period.subjectCode}</p>
        )}
      </div>

      {/* Teacher */}
      {showTeacher && period.teacherName && (
        <div className="flex items-center gap-1 mt-2 text-xs">
          <User className="h-3 w-3" />
          <span>
            {period.isSubstitute && (
              <span className="text-orange-600 font-medium">Substitute: </span>
            )}
            {period.isSubstitute ? period.substituteTeacher : period.teacherName}
          </span>
        </div>
      )}

      {/* Room */}
      {showRoom && period.roomNumber && (
        <div className="flex items-center gap-1 mt-1 text-xs">
          <MapPin className="h-3 w-3" />
          <span>Room {period.roomNumber}</span>
        </div>
      )}

      {/* Notes */}
      {period.notes && (
        <p className="mt-2 text-xs text-muted-foreground italic">{period.notes}</p>
      )}
    </div>
  )
}

// ========================================
// DAILY VIEW
// ========================================

interface DailyViewProps {
  schedule: DaySchedule
  highlightCurrent?: boolean
  showTeacher?: boolean
  showRoom?: boolean
  onPeriodClick?: (period: Period) => void
}

function DailyView({
  schedule,
  highlightCurrent,
  showTeacher,
  showRoom,
  onPeriodClick,
}: DailyViewProps) {
  const getCurrentPeriod = () => {
    if (!highlightCurrent) return null

    const now = new Date()
    const currentTime = format(now, 'HH:mm')

    return schedule.periods.find((period) => {
      return currentTime >= period.startTime && currentTime <= period.endTime
    })
  }

  const currentPeriod = getCurrentPeriod()

  return (
    <div className="space-y-3">
      {schedule.periods.map((period) => (
        <PeriodCard
          key={period.id}
          period={period}
          isCurrentPeriod={currentPeriod?.id === period.id}
          showTeacher={showTeacher}
          showRoom={showRoom}
          onClick={() => onPeriodClick?.(period)}
        />
      ))}
    </div>
  )
}

// ========================================
// WEEKLY VIEW
// ========================================

interface WeeklyViewProps {
  schedules: DaySchedule[]
  highlightCurrent?: boolean
  showTeacher?: boolean
  showRoom?: boolean
  onPeriodClick?: (period: Period) => void
}

function WeeklyView({
  schedules,
  highlightCurrent,
  showTeacher,
  showRoom,
  onPeriodClick,
}: WeeklyViewProps) {
  const today = new Date()
  const weekStart = startOfWeek(today, { weekStartsOn: 1 })

  const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

  // Get max periods across all days
  const maxPeriods = Math.max(
    ...schedules.map((s) => s.periods.length),
    0
  )

  const getCurrentPeriod = (periods: Period[]) => {
    if (!highlightCurrent) return null

    const now = new Date()
    const currentTime = format(now, 'HH:mm')

    return periods.find((period) => {
      return currentTime >= period.startTime && currentTime <= period.endTime
    })
  }

  return (
    <div className="overflow-x-auto">
      <div className="min-w-[900px]">
        {/* Header */}
        <div className="grid grid-cols-7 gap-2 mb-3">
          <div className="font-semibold text-sm">Time</div>
          {dayLabels.map((day, index) => {
            const dayDate = addDays(weekStart, index)
            const schedule = schedules[index]
            const isTodayDay = schedule?.date && isToday(schedule.date)

            return (
              <div key={day} className="text-center">
                <div
                  className={cn(
                    'font-semibold text-sm',
                    isTodayDay && 'text-primary'
                  )}
                >
                  {day}
                </div>
                {schedule?.date && (
                  <div className="text-xs text-muted-foreground">
                    {format(schedule.date, 'MMM dd')}
                  </div>
                )}
              </div>
            )
          })}
        </div>

        {/* Periods grid */}
        {Array.from({ length: maxPeriods }).map((_, periodIndex) => {
          const firstPeriod = schedules[0]?.periods[periodIndex]

          return (
            <div key={periodIndex} className="grid grid-cols-7 gap-2 mb-2">
              {/* Time column */}
              <div className="flex items-center justify-center text-xs text-muted-foreground">
                {firstPeriod && (
                  <div className="text-center">
                    <div>{firstPeriod.startTime}</div>
                    <div>-</div>
                    <div>{firstPeriod.endTime}</div>
                  </div>
                )}
              </div>

              {/* Day columns */}
              {schedules.map((schedule, dayIndex) => {
                const period = schedule.periods[periodIndex]
                const currentPeriod = getCurrentPeriod(schedule.periods)
                const isTodayDay = schedule.date && isToday(schedule.date)

                if (!period) {
                  return <div key={dayIndex} />
                }

                return (
                  <div key={dayIndex}>
                    <PeriodCard
                      period={period}
                      isCurrentPeriod={
                        isTodayDay && currentPeriod?.id === period.id
                      }
                      showTeacher={showTeacher}
                      showRoom={showRoom}
                      onClick={() => onPeriodClick?.(period)}
                    />
                  </div>
                )
              })}
            </div>
          )
        })}
      </div>
    </div>
  )
}

// ========================================
// TIMETABLE VIEW COMPONENT
// ========================================

/**
 * Timetable View Component
 * 
 * Displays class schedules with daily and weekly views.
 */
export function TimetableView({
  data,
  view = 'weekly',
  selectedDate = new Date(),
  highlightCurrent = true,
  showTeachers = true,
  showRooms = true,
  onPeriodClick,
  onExport,
  className,
}: TimetableViewProps) {
  const [currentView, setCurrentView] = React.useState(view)
  const [currentDate, setCurrentDate] = React.useState(selectedDate)

  // Get schedule for selected date (daily view)
  const getDailySchedule = () => {
    const dayName = format(currentDate, 'EEEE').toLowerCase() as DayOfWeek
    return data.schedule.find((s) => s.day === dayName)
  }

  const dailySchedule = getDailySchedule()

  return (
    <Card className={className}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              {data.className} - {data.section} Timetable
            </CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              Academic Year {data.academicYear}
            </p>
          </div>

          {onExport && (
            <Button variant="outline" size="sm" onClick={onExport}>
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* View toggle */}
        <Tabs value={currentView} onValueChange={(v) => setCurrentView(v as 'daily' | 'weekly')}>
          <TabsList>
            <TabsTrigger value="daily">Daily View</TabsTrigger>
            <TabsTrigger value="weekly">Weekly View</TabsTrigger>
          </TabsList>

          {/* Daily view */}
          <TabsContent value="daily" className="mt-4">
            {dailySchedule ? (
              <>
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-semibold">
                    {format(currentDate, 'EEEE, MMMM dd, yyyy')}
                  </h3>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentDate(addDays(currentDate, -1))}
                    >
                      Previous
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentDate(new Date())}
                    >
                      Today
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentDate(addDays(currentDate, 1))}
                    >
                      Next
                    </Button>
                  </div>
                </div>

                <DailyView
                  schedule={dailySchedule}
                  highlightCurrent={highlightCurrent}
                  showTeacher={showTeachers}
                  showRoom={showRooms}
                  onPeriodClick={onPeriodClick}
                />
              </>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                No classes scheduled for this day
              </div>
            )}
          </TabsContent>

          {/* Weekly view */}
          <TabsContent value="weekly" className="mt-4">
            <WeeklyView
              schedules={data.schedule}
              highlightCurrent={highlightCurrent}
              showTeacher={showTeachers}
              showRoom={showRooms}
              onPeriodClick={onPeriodClick}
            />
          </TabsContent>
        </Tabs>

        {/* Legend */}
        <div className="flex flex-wrap gap-4 pt-4 border-t text-sm">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded border-2 border-primary bg-primary/10" />
            <span>Current Period</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded border-2 border-orange-500 bg-orange-50" />
            <span>Substitute Teacher</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded border-2 border-dashed bg-muted/50" />
            <span>Break</span>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Timetable

```typescript
import { TimetableView } from '@/components/academic/timetable-view'

function ClassTimetable() {
  const timetableData = {
    classId: '1',
    className: 'Grade 10',
    section: 'A',
    academicYear: '2024-2025',
    schedule: [
      {
        day: 'monday',
        date: new Date('2024-01-08'),
        periods: [
          {
            id: '1',
            periodNumber: 1,
            startTime: '08:00',
            endTime: '09:00',
            subjectName: 'Mathematics',
            subjectCode: 'MATH101',
            teacherName: 'Mr. Smith',
            roomNumber: '201',
          },
          // ... more periods
        ],
      },
      // ... more days
    ],
  }

  return <TimetableView data={timetableData} />
}
```

---

## 🧪 TESTING

```typescript
describe('TimetableView', () => {
  it('renders weekly view', () => {
    render(<TimetableView data={mockTimetableData} />)
    expect(screen.getByText('Weekly View')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ ARIA labels
- ✅ Clear visual hierarchy

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create timetable-view.tsx
- [ ] Implement daily view
- [ ] Implement weekly view
- [ ] Add current period highlighting
- [ ] Write tests

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
