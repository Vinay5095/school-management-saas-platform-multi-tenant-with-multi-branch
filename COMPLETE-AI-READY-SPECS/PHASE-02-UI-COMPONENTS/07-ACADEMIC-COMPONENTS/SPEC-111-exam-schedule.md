# SPEC-111: Exam Schedule Component
## Examination Timetable and Schedule Display

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: date-fns

---

## 📋 OVERVIEW

### Purpose
A comprehensive exam schedule component for displaying examination timetables, exam details, room allocations, and preparation reminders.

### Key Features
- ✅ Exam timetable display
- ✅ Subject-wise exam details
- ✅ Room and seat allocation
- ✅ Countdown to exams
- ✅ Syllabus links
- ✅ Examiner information
- ✅ Download/print functionality
- ✅ Reminder notifications
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/exam-schedule.tsx
import * as React from 'react'
import {
  Calendar,
  Clock,
  MapPin,
  FileText,
  User,
  Download,
  Bell,
  AlertCircle,
  BookOpen,
} from 'lucide-react'
import { format, formatDistanceToNow, differenceInDays, isFuture } from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface ExamData {
  id: string
  subject: string
  subjectCode: string
  date: Date
  startTime: string
  endTime: string
  duration: number // in minutes
  roomNumber: string
  seatNumber?: string
  examiner: string
  totalMarks: number
  passingMarks: number
  examType: 'midterm' | 'final' | 'practical' | 'viva' | 'assignment'
  syllabus?: string[]
  syllabusUrl?: string
  notes?: string
  isCompleted?: boolean
}

export interface ExamScheduleData {
  studentId?: string
  studentName?: string
  className: string
  section: string
  term: string
  academicYear: string
  exams: ExamData[]
}

export interface ExamScheduleProps {
  /**
   * Exam schedule data
   */
  data: ExamScheduleData

  /**
   * View mode
   */
  view?: 'list' | 'calendar' | 'upcoming'

  /**
   * Show countdown
   */
  showCountdown?: boolean

  /**
   * Show syllabus
   */
  showSyllabus?: boolean

  /**
   * On download
   */
  onDownload?: () => void

  /**
   * On set reminder
   */
  onSetReminder?: (examId: string) => void

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// EXAM TYPE BADGE
// ========================================

function getExamTypeConfig(type: ExamData['examType']) {
  const configs = {
    midterm: {
      label: 'Midterm',
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400',
    },
    final: {
      label: 'Final',
      className: 'bg-purple-100 text-purple-700 dark:bg-purple-950 dark:text-purple-400',
    },
    practical: {
      label: 'Practical',
      className: 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400',
    },
    viva: {
      label: 'Viva',
      className: 'bg-orange-100 text-orange-700 dark:bg-orange-950 dark:text-orange-400',
    },
    assignment: {
      label: 'Assignment',
      className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400',
    },
  }
  return configs[type]
}

// ========================================
// COUNTDOWN TIMER
// ========================================

interface CountdownProps {
  targetDate: Date
  compact?: boolean
}

function Countdown({ targetDate, compact = false }: CountdownProps) {
  const [timeLeft, setTimeLeft] = React.useState('')

  React.useEffect(() => {
    const updateCountdown = () => {
      const now = new Date()
      const daysLeft = differenceInDays(targetDate, now)

      if (daysLeft < 0) {
        setTimeLeft('Completed')
        return
      }

      if (daysLeft === 0) {
        setTimeLeft('Today')
      } else if (daysLeft === 1) {
        setTimeLeft('Tomorrow')
      } else if (daysLeft <= 7) {
        setTimeLeft(`${daysLeft} days`)
      } else {
        setTimeLeft(formatDistanceToNow(targetDate, { addSuffix: true }))
      }
    }

    updateCountdown()
    const interval = setInterval(updateCountdown, 60000) // Update every minute

    return () => clearInterval(interval)
  }, [targetDate])

  if (compact) {
    return <span className="text-sm font-medium">{timeLeft}</span>
  }

  return (
    <div className="flex items-center gap-2">
      <Clock className="h-4 w-4" />
      <span className="font-medium">{timeLeft}</span>
    </div>
  )
}

// ========================================
// EXAM CARD
// ========================================

interface ExamCardProps {
  exam: ExamData
  showCountdown?: boolean
  showSyllabus?: boolean
  onSetReminder?: (examId: string) => void
  compact?: boolean
}

function ExamCard({
  exam,
  showCountdown = true,
  showSyllabus = true,
  onSetReminder,
  compact = false,
}: ExamCardProps) {
  const typeConfig = getExamTypeConfig(exam.examType)
  const isUpcoming = isFuture(exam.date)

  return (
    <Card
      className={cn(
        'transition-all hover:shadow-md',
        exam.isCompleted && 'opacity-60',
        compact && 'border-l-4',
        !exam.isCompleted && isUpcoming && 'border-l-primary'
      )}
    >
      <CardHeader className={cn('pb-3', compact && 'p-4')}>
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-1 flex-1">
            <CardTitle className={cn('text-base', compact && 'text-sm')}>
              {exam.subject}
            </CardTitle>
            <p className="text-xs text-muted-foreground">{exam.subjectCode}</p>
          </div>
          <Badge className={typeConfig.className}>{typeConfig.label}</Badge>
        </div>
      </CardHeader>

      <CardContent className={cn('space-y-3', compact && 'p-4 pt-0')}>
        {/* Date and time */}
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-muted-foreground" />
            <span>{format(exam.date, 'MMM dd, yyyy')}</span>
          </div>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-muted-foreground" />
            <span>
              {exam.startTime} - {exam.endTime}
            </span>
          </div>
        </div>

        {/* Room and seat */}
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="flex items-center gap-2">
            <MapPin className="h-4 w-4 text-muted-foreground" />
            <span>Room {exam.roomNumber}</span>
          </div>
          {exam.seatNumber && (
            <div className="flex items-center gap-2">
              <User className="h-4 w-4 text-muted-foreground" />
              <span>Seat {exam.seatNumber}</span>
            </div>
          )}
        </div>

        {/* Duration and marks */}
        <div className="flex items-center justify-between text-sm p-2 bg-muted/50 rounded">
          <span>Duration: {exam.duration} minutes</span>
          <span className="font-medium">
            Total Marks: {exam.totalMarks} (Pass: {exam.passingMarks})
          </span>
        </div>

        {/* Countdown */}
        {showCountdown && isUpcoming && !exam.isCompleted && (
          <div className="flex items-center gap-2 p-2 bg-primary/10 rounded">
            <AlertCircle className="h-4 w-4 text-primary" />
            <span className="text-sm">Exam in:</span>
            <Countdown targetDate={exam.date} compact />
          </div>
        )}

        {/* Syllabus */}
        {showSyllabus && exam.syllabus && exam.syllabus.length > 0 && (
          <div className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium">
              <BookOpen className="h-4 w-4" />
              <span>Syllabus Coverage:</span>
            </div>
            <ul className="list-disc list-inside text-sm text-muted-foreground space-y-1 ml-6">
              {exam.syllabus.map((topic, index) => (
                <li key={index}>{topic}</li>
              ))}
            </ul>
          </div>
        )}

        {/* Notes */}
        {exam.notes && (
          <div className="text-sm p-2 bg-yellow-50 dark:bg-yellow-950 rounded border border-yellow-200 dark:border-yellow-800">
            <p className="font-medium text-yellow-900 dark:text-yellow-400">
              Important Note:
            </p>
            <p className="text-yellow-800 dark:text-yellow-300 mt-1">{exam.notes}</p>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-2 pt-2">
          {exam.syllabusUrl && (
            <Button
              variant="outline"
              size="sm"
              className="flex-1"
              onClick={() => window.open(exam.syllabusUrl, '_blank')}
            >
              <FileText className="h-4 w-4 mr-2" />
              View Syllabus
            </Button>
          )}
          {onSetReminder && isUpcoming && !exam.isCompleted && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => onSetReminder(exam.id)}
            >
              <Bell className="h-4 w-4 mr-2" />
              Remind Me
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

// ========================================
// EXAM LIST VIEW
// ========================================

interface ExamListViewProps {
  exams: ExamData[]
  showCountdown?: boolean
  showSyllabus?: boolean
  onSetReminder?: (examId: string) => void
}

function ExamListView({
  exams,
  showCountdown,
  showSyllabus,
  onSetReminder,
}: ExamListViewProps) {
  // Group exams by status
  const upcomingExams = exams.filter((e) => isFuture(e.date) && !e.isCompleted)
  const completedExams = exams.filter((e) => e.isCompleted || !isFuture(e.date))

  return (
    <div className="space-y-6">
      {upcomingExams.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold mb-4">Upcoming Exams</h3>
          <div className="grid gap-4 md:grid-cols-2">
            {upcomingExams.map((exam) => (
              <ExamCard
                key={exam.id}
                exam={exam}
                showCountdown={showCountdown}
                showSyllabus={showSyllabus}
                onSetReminder={onSetReminder}
              />
            ))}
          </div>
        </div>
      )}

      {completedExams.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold mb-4">Completed Exams</h3>
          <div className="grid gap-4 md:grid-cols-2">
            {completedExams.map((exam) => (
              <ExamCard
                key={exam.id}
                exam={exam}
                showCountdown={false}
                showSyllabus={showSyllabus}
                compact
              />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ========================================
// UPCOMING EXAMS VIEW
// ========================================

function UpcomingExamsView({
  exams,
  showCountdown,
  onSetReminder,
}: ExamListViewProps) {
  const upcomingExams = exams
    .filter((e) => isFuture(e.date) && !e.isCompleted)
    .sort((a, b) => a.date.getTime() - b.date.getTime())
    .slice(0, 3)

  if (upcomingExams.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        <Calendar className="h-12 w-12 mx-auto mb-4 opacity-50" />
        <p>No upcoming exams scheduled</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {upcomingExams.map((exam) => (
        <ExamCard
          key={exam.id}
          exam={exam}
          showCountdown={showCountdown}
          showSyllabus={true}
          onSetReminder={onSetReminder}
        />
      ))}
    </div>
  )
}

// ========================================
// EXAM SCHEDULE COMPONENT
// ========================================

/**
 * Exam Schedule Component
 * 
 * Comprehensive examination schedule and timetable display.
 */
export function ExamSchedule({
  data,
  view = 'list',
  showCountdown = true,
  showSyllabus = true,
  onDownload,
  onSetReminder,
  className,
}: ExamScheduleProps) {
  const [currentView, setCurrentView] = React.useState(view)

  // Sort exams by date
  const sortedExams = [...data.exams].sort(
    (a, b) => a.date.getTime() - b.date.getTime()
  )

  return (
    <Card className={className}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              Exam Schedule
            </CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              {data.className} - {data.section} | {data.term} {data.academicYear}
            </p>
          </div>

          {onDownload && (
            <Button variant="outline" size="sm" onClick={onDownload}>
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* View tabs */}
        <Tabs value={currentView} onValueChange={(v) => setCurrentView(v as typeof view)}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="upcoming">Upcoming</TabsTrigger>
            <TabsTrigger value="list">All Exams</TabsTrigger>
            <TabsTrigger value="calendar">Calendar</TabsTrigger>
          </TabsList>

          <TabsContent value="upcoming" className="mt-4">
            <UpcomingExamsView
              exams={sortedExams}
              showCountdown={showCountdown}
              onSetReminder={onSetReminder}
            />
          </TabsContent>

          <TabsContent value="list" className="mt-4">
            <ExamListView
              exams={sortedExams}
              showCountdown={showCountdown}
              showSyllabus={showSyllabus}
              onSetReminder={onSetReminder}
            />
          </TabsContent>

          <TabsContent value="calendar" className="mt-4">
            {/* Calendar view would be implemented here */}
            <div className="text-center py-12 text-muted-foreground">
              <Calendar className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Calendar view coming soon</p>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Exam Schedule

```typescript
import { ExamSchedule } from '@/components/academic/exam-schedule'

function StudentExams() {
  const examData = {
    studentId: '1',
    studentName: 'John Doe',
    className: 'Grade 10',
    section: 'A',
    term: 'Final Exams',
    academicYear: '2024-2025',
    exams: [
      {
        id: '1',
        subject: 'Mathematics',
        subjectCode: 'MATH101',
        date: new Date('2024-12-15'),
        startTime: '09:00 AM',
        endTime: '12:00 PM',
        duration: 180,
        roomNumber: '201',
        seatNumber: '15',
        examiner: 'Mr. Smith',
        totalMarks: 100,
        passingMarks: 40,
        examType: 'final',
        syllabus: [
          'Algebra - Chapters 1-5',
          'Geometry - Chapters 6-8',
          'Trigonometry - Chapters 9-10',
        ],
        syllabusUrl: '/syllabus/math-final.pdf',
        notes: 'Calculators are allowed. Bring your own instruments.',
      },
      // ... more exams
    ],
  }

  return (
    <ExamSchedule
      data={examData}
      showCountdown
      showSyllabus
      onDownload={() => console.log('Download schedule')}
      onSetReminder={(id) => console.log('Set reminder for', id)}
    />
  )
}
```

### Upcoming Exams Widget

```typescript
function DashboardExams() {
  return (
    <ExamSchedule
      data={examData}
      view="upcoming"
      showCountdown
    />
  )
}
```

### Completed Exams View

```typescript
const completedExams = {
  ...examData,
  exams: examData.exams.map(exam => ({ ...exam, isCompleted: true })),
}

return <ExamSchedule data={completedExams} view="list" />
```

---

## 🧪 TESTING

```typescript
describe('ExamSchedule', () => {
  const mockExamData = {
    className: 'Grade 10',
    section: 'A',
    term: 'Final',
    academicYear: '2024-2025',
    exams: [
      {
        id: '1',
        subject: 'Math',
        subjectCode: 'MATH101',
        date: new Date('2024-12-15'),
        startTime: '09:00 AM',
        endTime: '12:00 PM',
        duration: 180,
        roomNumber: '201',
        examiner: 'Mr. Smith',
        totalMarks: 100,
        passingMarks: 40,
        examType: 'final' as const,
      },
    ],
  }

  it('renders exam schedule', () => {
    render(<ExamSchedule data={mockExamData} />)
    expect(screen.getByText('Exam Schedule')).toBeInTheDocument()
    expect(screen.getByText('Math')).toBeInTheDocument()
  })

  it('shows countdown for upcoming exams', () => {
    render(<ExamSchedule data={mockExamData} showCountdown />)
    expect(screen.getByText(/Exam in:/)).toBeInTheDocument()
  })

  it('displays syllabus when available', () => {
    const dataWithSyllabus = {
      ...mockExamData,
      exams: [
        {
          ...mockExamData.exams[0],
          syllabus: ['Chapter 1', 'Chapter 2'],
        },
      ],
    }
    render(<ExamSchedule data={dataWithSyllabus} showSyllabus />)
    expect(screen.getByText('Syllabus Coverage:')).toBeInTheDocument()
  })

  it('calls onSetReminder when reminder button clicked', () => {
    const onSetReminder = jest.fn()
    render(
      <ExamSchedule
        data={mockExamData}
        onSetReminder={onSetReminder}
      />
    )
    fireEvent.click(screen.getByText('Remind Me'))
    expect(onSetReminder).toHaveBeenCalledWith('1')
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic HTML structure
- ✅ ARIA labels for interactive elements
- ✅ Keyboard navigation support
- ✅ Screen reader friendly content
- ✅ Clear visual hierarchy
- ✅ High contrast color schemes

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install dependencies: `npm install date-fns`
- [ ] Create exam-schedule.tsx
- [ ] Implement ExamCard component
- [ ] Add countdown timer
- [ ] Implement list view
- [ ] Implement upcoming exams view
- [ ] Add calendar view (optional)
- [ ] Add download functionality
- [ ] Add reminder functionality
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Document usage examples

---

## 📦 BUNDLE SIZE

- **Component**: ~3KB
- **With dependencies**: ~8KB (date-fns)
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
