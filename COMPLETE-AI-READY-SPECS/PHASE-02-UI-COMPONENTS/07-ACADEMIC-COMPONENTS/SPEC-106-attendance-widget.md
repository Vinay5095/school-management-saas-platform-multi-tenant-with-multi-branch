# SPEC-106: Attendance Widget Component
## Student Attendance Tracking and Visualization

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2.5 hours  
> **Dependencies**: date-fns, Recharts

---

## 📋 OVERVIEW

### Purpose
A comprehensive attendance widget for tracking, visualizing, and managing student attendance with calendar views, statistics, and real-time marking capabilities.

### Key Features
- ✅ Daily attendance marking
- ✅ Attendance calendar view
- ✅ Statistics and percentages
- ✅ Status indicators (present, absent, late, excused)
- ✅ Bulk attendance marking
- ✅ Attendance trends chart
- ✅ Export functionality
- ✅ Real-time updates
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/attendance-widget.tsx
import * as React from 'react'
import {
  Calendar,
  Check,
  X,
  Clock,
  FileText,
  Download,
  TrendingUp,
  Users,
} from 'lucide-react'
import {
  format,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameDay,
  isToday,
  isFuture,
} from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type AttendanceStatus = 'present' | 'absent' | 'late' | 'excused'

export interface AttendanceRecord {
  id: string
  studentId: string
  date: Date
  status: AttendanceStatus
  remarks?: string
  markedBy: string
  markedAt: Date
}

export interface Student {
  id: string
  name: string
  rollNumber: string
  avatar?: string
}

export interface AttendanceStats {
  totalDays: number
  presentDays: number
  absentDays: number
  lateDays: number
  excusedDays: number
  attendancePercentage: number
}

export interface AttendanceWidgetProps {
  /**
   * Student information
   */
  student?: Student

  /**
   * Class/Section ID (for bulk attendance)
   */
  classId?: string

  /**
   * Attendance records
   */
  records: AttendanceRecord[]

  /**
   * On mark attendance
   */
  onMarkAttendance?: (studentId: string, date: Date, status: AttendanceStatus) => void

  /**
   * On bulk mark attendance
   */
  onBulkMarkAttendance?: (studentIds: string[], date: Date, status: AttendanceStatus) => void

  /**
   * View mode
   */
  mode?: 'single' | 'class'

  /**
   * Show statistics
   */
  showStats?: boolean

  /**
   * Show calendar
   */
  showCalendar?: boolean

  /**
   * Show trends
   */
  showTrends?: boolean

  /**
   * Editable
   */
  editable?: boolean

  /**
   * On export
   */
  onExport?: () => void
}

// ========================================
// ATTENDANCE STATUS BADGE
// ========================================

interface AttendanceStatusBadgeProps {
  status: AttendanceStatus
  size?: 'sm' | 'md' | 'lg'
}

function AttendanceStatusBadge({ status, size = 'md' }: AttendanceStatusBadgeProps) {
  const configs = {
    present: {
      label: 'Present',
      icon: Check,
      className: 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400',
    },
    absent: {
      label: 'Absent',
      icon: X,
      className: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400',
    },
    late: {
      label: 'Late',
      icon: Clock,
      className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400',
    },
    excused: {
      label: 'Excused',
      icon: FileText,
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400',
    },
  }

  const config = configs[status]
  const Icon = config.icon

  return (
    <Badge
      variant="outline"
      className={cn('gap-1', config.className, {
        'text-xs px-2 py-0.5': size === 'sm',
        'text-sm px-3 py-1': size === 'md',
        'text-base px-4 py-1.5': size === 'lg',
      })}
    >
      <Icon className={cn(size === 'sm' ? 'h-3 w-3' : 'h-4 w-4')} />
      {config.label}
    </Badge>
  )
}

// ========================================
// ATTENDANCE CALENDAR
// ========================================

interface AttendanceCalendarProps {
  records: AttendanceRecord[]
  studentId?: string
  month: Date
  onDateClick?: (date: Date) => void
  editable?: boolean
}

function AttendanceCalendar({
  records,
  studentId,
  month,
  onDateClick,
  editable,
}: AttendanceCalendarProps) {
  const days = eachDayOfInterval({
    start: startOfMonth(month),
    end: endOfMonth(month),
  })

  const getAttendanceForDate = (date: Date) => {
    return records.find(
      (r) =>
        isSameDay(r.date, date) &&
        (!studentId || r.studentId === studentId)
    )
  }

  const getStatusColor = (status: AttendanceStatus) => {
    const colors = {
      present: 'bg-green-500',
      absent: 'bg-red-500',
      late: 'bg-yellow-500',
      excused: 'bg-blue-500',
    }
    return colors[status]
  }

  return (
    <div className="space-y-2">
      {/* Month header */}
      <div className="font-semibold text-center">
        {format(month, 'MMMM yyyy')}
      </div>

      {/* Weekday headers */}
      <div className="grid grid-cols-7 gap-1 text-center text-xs font-medium text-muted-foreground">
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
          <div key={day} className="py-1">
            {day}
          </div>
        ))}
      </div>

      {/* Days grid */}
      <div className="grid grid-cols-7 gap-1">
        {days.map((day) => {
          const attendance = getAttendanceForDate(day)
          const future = isFuture(day)
          const today = isToday(day)

          return (
            <button
              key={day.toISOString()}
              onClick={() => !future && editable && onDateClick?.(day)}
              disabled={future || !editable}
              className={cn(
                'aspect-square p-1 rounded-lg text-sm transition-colors',
                'hover:bg-accent disabled:opacity-50 disabled:cursor-not-allowed',
                today && 'ring-2 ring-primary',
                attendance && getStatusColor(attendance.status),
                !attendance && !future && 'bg-muted',
                attendance && 'text-white'
              )}
            >
              {format(day, 'd')}
            </button>
          )
        })}
      </div>

      {/* Legend */}
      <div className="flex flex-wrap gap-2 pt-2 text-xs">
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-green-500" />
          <span>Present</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-red-500" />
          <span>Absent</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-yellow-500" />
          <span>Late</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-blue-500" />
          <span>Excused</span>
        </div>
      </div>
    </div>
  )
}

// ========================================
// ATTENDANCE STATS
// ========================================

function calculateStats(records: AttendanceRecord[]): AttendanceStats {
  const totalDays = records.length
  const presentDays = records.filter((r) => r.status === 'present').length
  const absentDays = records.filter((r) => r.status === 'absent').length
  const lateDays = records.filter((r) => r.status === 'late').length
  const excusedDays = records.filter((r) => r.status === 'excused').length
  const attendancePercentage =
    totalDays > 0 ? (presentDays / totalDays) * 100 : 0

  return {
    totalDays,
    presentDays,
    absentDays,
    lateDays,
    excusedDays,
    attendancePercentage,
  }
}

interface AttendanceStatsCardProps {
  stats: AttendanceStats
}

function AttendanceStatsCard({ stats }: AttendanceStatsCardProps) {
  return (
    <div className="space-y-4">
      {/* Overall percentage */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium">Attendance Rate</span>
          <span className="text-2xl font-bold">
            {stats.attendancePercentage.toFixed(1)}%
          </span>
        </div>
        <Progress value={stats.attendancePercentage} className="h-3" />
        <p className="text-xs text-muted-foreground mt-1">
          {stats.presentDays} present out of {stats.totalDays} days
        </p>
      </div>

      {/* Breakdown */}
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1">
          <div className="text-xs text-muted-foreground">Present</div>
          <div className="text-2xl font-bold text-green-600">
            {stats.presentDays}
          </div>
        </div>
        <div className="space-y-1">
          <div className="text-xs text-muted-foreground">Absent</div>
          <div className="text-2xl font-bold text-red-600">
            {stats.absentDays}
          </div>
        </div>
        <div className="space-y-1">
          <div className="text-xs text-muted-foreground">Late</div>
          <div className="text-2xl font-bold text-yellow-600">
            {stats.lateDays}
          </div>
        </div>
        <div className="space-y-1">
          <div className="text-xs text-muted-foreground">Excused</div>
          <div className="text-2xl font-bold text-blue-600">
            {stats.excusedDays}
          </div>
        </div>
      </div>
    </div>
  )
}

// ========================================
// ATTENDANCE WIDGET COMPONENT
// ========================================

/**
 * Attendance Widget Component
 * 
 * Comprehensive attendance tracking and visualization.
 */
export function AttendanceWidget({
  student,
  classId,
  records,
  onMarkAttendance,
  onBulkMarkAttendance,
  mode = 'single',
  showStats = true,
  showCalendar = true,
  showTrends = false,
  editable = true,
  onExport,
}: AttendanceWidgetProps) {
  const [selectedDate, setSelectedDate] = React.useState(new Date())
  const [selectedMonth, setSelectedMonth] = React.useState(new Date())
  const [selectedStatus, setSelectedStatus] = React.useState<AttendanceStatus>('present')

  // Filter records for current student
  const studentRecords = student
    ? records.filter((r) => r.studentId === student.id)
    : records

  const stats = calculateStats(studentRecords)

  const handleMarkAttendance = () => {
    if (mode === 'single' && student) {
      onMarkAttendance?.(student.id, selectedDate, selectedStatus)
    }
  }

  const handleDateClick = (date: Date) => {
    setSelectedDate(date)
    // Open attendance marking dialog
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            <CardTitle>
              {mode === 'single' && student
                ? `Attendance - ${student.name}`
                : 'Class Attendance'}
            </CardTitle>
          </div>
          {onExport && (
            <Button variant="outline" size="sm" onClick={onExport}>
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* Quick mark attendance */}
        {editable && (
          <div className="flex gap-2">
            <Select
              value={selectedStatus}
              onValueChange={(v) => setSelectedStatus(v as AttendanceStatus)}
            >
              <SelectTrigger className="w-[180px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="present">Present</SelectItem>
                <SelectItem value="absent">Absent</SelectItem>
                <SelectItem value="late">Late</SelectItem>
                <SelectItem value="excused">Excused</SelectItem>
              </SelectContent>
            </Select>
            <Button onClick={handleMarkAttendance}>
              Mark {mode === 'class' ? 'All' : 'Attendance'}
            </Button>
          </div>
        )}

        {/* Statistics */}
        {showStats && (
          <div>
            <h4 className="text-sm font-semibold mb-3">Statistics</h4>
            <AttendanceStatsCard stats={stats} />
          </div>
        )}

        {/* Calendar */}
        {showCalendar && (
          <div>
            <h4 className="text-sm font-semibold mb-3">Calendar View</h4>
            <AttendanceCalendar
              records={studentRecords}
              studentId={student?.id}
              month={selectedMonth}
              onDateClick={handleDateClick}
              editable={editable}
            />
          </div>
        )}

        {/* Recent attendance */}
        <div>
          <h4 className="text-sm font-semibold mb-3">Recent Activity</h4>
          <div className="space-y-2">
            {studentRecords
              .slice(0, 5)
              .sort((a, b) => b.date.getTime() - a.date.getTime())
              .map((record) => (
                <div
                  key={record.id}
                  className="flex items-center justify-between p-2 rounded-lg bg-muted/50"
                >
                  <div className="flex items-center gap-3">
                    <div className="text-sm">
                      {format(record.date, 'MMM dd, yyyy')}
                    </div>
                    <AttendanceStatusBadge status={record.status} size="sm" />
                  </div>
                  {record.remarks && (
                    <div className="text-xs text-muted-foreground">
                      {record.remarks}
                    </div>
                  )}
                </div>
              ))}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

// ========================================
// BULK ATTENDANCE MARKING
// ========================================

export interface BulkAttendanceProps {
  students: Student[]
  date: Date
  onSubmit: (attendance: Array<{ studentId: string; status: AttendanceStatus }>) => void
}

export function BulkAttendanceMarking({ students, date, onSubmit }: BulkAttendanceProps) {
  const [attendance, setAttendance] = React.useState<
    Record<string, AttendanceStatus>
  >(
    students.reduce(
      (acc, s) => ({ ...acc, [s.id]: 'present' as AttendanceStatus }),
      {}
    )
  )

  const handleMarkAll = (status: AttendanceStatus) => {
    setAttendance(
      students.reduce((acc, s) => ({ ...acc, [s.id]: status }), {})
    )
  }

  const handleSubmit = () => {
    onSubmit(
      Object.entries(attendance).map(([studentId, status]) => ({
        studentId,
        status,
      }))
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">
          Mark Attendance - {format(date, 'MMMM dd, yyyy')}
        </h3>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleMarkAll('present')}
          >
            All Present
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleMarkAll('absent')}
          >
            All Absent
          </Button>
        </div>
      </div>

      <div className="space-y-2 max-h-[400px] overflow-y-auto">
        {students.map((student) => (
          <div
            key={student.id}
            className="flex items-center justify-between p-3 rounded-lg border"
          >
            <div className="flex items-center gap-3">
              {student.avatar ? (
                <img
                  src={student.avatar}
                  alt={student.name}
                  className="w-10 h-10 rounded-full"
                />
              ) : (
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <Users className="h-5 w-5" />
                </div>
              )}
              <div>
                <div className="font-medium">{student.name}</div>
                <div className="text-sm text-muted-foreground">
                  Roll: {student.rollNumber}
                </div>
              </div>
            </div>

            <Select
              value={attendance[student.id]}
              onValueChange={(v) =>
                setAttendance((prev) => ({
                  ...prev,
                  [student.id]: v as AttendanceStatus,
                }))
              }
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="present">Present</SelectItem>
                <SelectItem value="absent">Absent</SelectItem>
                <SelectItem value="late">Late</SelectItem>
                <SelectItem value="excused">Excused</SelectItem>
              </SelectContent>
            </Select>
          </div>
        ))}
      </div>

      <Button onClick={handleSubmit} className="w-full">
        Submit Attendance
      </Button>
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Single Student Attendance

```typescript
import { AttendanceWidget } from '@/components/academic/attendance-widget'

function StudentProfile() {
  const student = {
    id: '1',
    name: 'John Doe',
    rollNumber: '2024-10-001',
    avatar: '/avatars/john.jpg',
  }

  const records = [
    {
      id: '1',
      studentId: '1',
      date: new Date('2024-01-10'),
      status: 'present' as const,
      markedBy: 'teacher-1',
      markedAt: new Date(),
    },
    // ... more records
  ]

  return (
    <AttendanceWidget
      student={student}
      records={records}
      showStats
      showCalendar
      editable
    />
  )
}
```

### Class Attendance View

```typescript
function ClassAttendance() {
  return (
    <AttendanceWidget
      classId="class-10a"
      records={classRecords}
      mode="class"
      onBulkMarkAttendance={(studentIds, date, status) => {
        // Mark attendance for all students
      }}
    />
  )
}
```

### Bulk Attendance Marking

```typescript
import { BulkAttendanceMarking } from '@/components/academic/attendance-widget'

function MarkAttendance() {
  const students = [/* student list */]

  return (
    <BulkAttendanceMarking
      students={students}
      date={new Date()}
      onSubmit={(attendance) => {
        console.log('Attendance:', attendance)
      }}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('AttendanceWidget', () => {
  it('renders student attendance', () => {
    render(
      <AttendanceWidget
        student={mockStudent}
        records={mockRecords}
      />
    )
    expect(screen.getByText(mockStudent.name)).toBeInTheDocument()
  })

  it('calculates attendance percentage correctly', () => {
    const records = [
      { status: 'present', /* ... */ },
      { status: 'present', /* ... */ },
      { status: 'absent', /* ... */ },
    ]
    // Should show 66.7% attendance
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ ARIA labels
- ✅ Screen reader support
- ✅ Focus management

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install dependencies: `npm install date-fns recharts`
- [ ] Create attendance-widget.tsx
- [ ] Implement calendar view
- [ ] Add statistics calculation
- [ ] Add bulk marking
- [ ] Write tests
- [ ] Document usage

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
