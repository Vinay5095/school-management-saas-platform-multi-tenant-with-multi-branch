# SPEC-110: Assignment Card Component
## Assignment Display and Submission Tracking

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: date-fns

---

## 📋 OVERVIEW

### Purpose
A card component for displaying assignments, homework, and projects with submission status, due dates, and grading information.

### Key Features
- ✅ Assignment details display
- ✅ Due date countdown
- ✅ Submission status tracking
- ✅ File attachments
- ✅ Grading display
- ✅ Late submission indicators
- ✅ Quick submission
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/assignment-card.tsx
import * as React from 'react'
import {
  FileText,
  Calendar,
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle,
  Download,
  Upload,
  Award,
} from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type AssignmentStatus = 'pending' | 'submitted' | 'graded' | 'late' | 'missing'

export interface AssignmentData {
  id: string
  title: string
  subject: string
  subjectCode?: string
  description: string
  assignedDate: Date
  dueDate: Date
  totalMarks: number
  teacherName: string
  attachments?: Array<{
    id: string
    name: string
    url: string
    size: number
  }>
  status: AssignmentStatus
  submittedDate?: Date
  submissionUrl?: string
  grade?: number
  feedback?: string
  isLate?: boolean
}

export interface AssignmentCardProps {
  assignment: AssignmentData
  onSubmit?: (assignmentId: string) => void
  onDownload?: (attachmentId: string) => void
  onView?: (assignmentId: string) => void
  showGrade?: boolean
  compact?: boolean
  className?: string
}

// ========================================
// STATUS BADGE
// ========================================

function getStatusConfig(status: AssignmentStatus, isLate?: boolean) {
  if (isLate && status === 'submitted') {
    return {
      label: 'Submitted Late',
      icon: AlertCircle,
      className: 'bg-orange-100 text-orange-700 dark:bg-orange-950 dark:text-orange-400',
    }
  }

  const configs = {
    pending: {
      label: 'Pending',
      icon: Clock,
      className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400',
    },
    submitted: {
      label: 'Submitted',
      icon: CheckCircle,
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400',
    },
    graded: {
      label: 'Graded',
      icon: Award,
      className: 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400',
    },
    late: {
      label: 'Late',
      icon: AlertCircle,
      className: 'bg-orange-100 text-orange-700 dark:bg-orange-950 dark:text-orange-400',
    },
    missing: {
      label: 'Missing',
      icon: XCircle,
      className: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400',
    },
  }
  return configs[status]
}

// ========================================
// DUE DATE INDICATOR
// ========================================

function DueDateIndicator({ dueDate, status }: { dueDate: Date; status: AssignmentStatus }) {
  const now = new Date()
  const isOverdue = now > dueDate && status === 'pending'
  const timeLeft = formatDistanceToNow(dueDate, { addSuffix: true })

  return (
    <div
      className={cn(
        'flex items-center gap-2 text-sm',
        isOverdue ? 'text-destructive' : 'text-muted-foreground'
      )}
    >
      <Calendar className="h-4 w-4" />
      <span>
        Due {timeLeft}
        {isOverdue && ' (Overdue)'}
      </span>
    </div>
  )
}

// ========================================
// ASSIGNMENT CARD COMPONENT
// ========================================

export function AssignmentCard({
  assignment,
  onSubmit,
  onDownload,
  onView,
  showGrade = true,
  compact = false,
  className,
}: AssignmentCardProps) {
  const statusConfig = getStatusConfig(assignment.status, assignment.isLate)
  const StatusIcon = statusConfig.icon

  const gradePercentage = assignment.grade
    ? (assignment.grade / assignment.totalMarks) * 100
    : 0

  return (
    <Card className={cn('hover:shadow-md transition-shadow', className)}>
      <CardHeader className={cn('pb-3', compact && 'p-4')}>
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 space-y-1">
            <CardTitle className={cn('text-base', compact && 'text-sm')}>
              {assignment.title}
            </CardTitle>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span>{assignment.subject}</span>
              {assignment.subjectCode && (
                <span className="text-xs">({assignment.subjectCode})</span>
              )}
            </div>
          </div>
          <Badge className={statusConfig.className}>
            <StatusIcon className="h-3 w-3 mr-1" />
            {statusConfig.label}
          </Badge>
        </div>
      </CardHeader>

      <CardContent className={cn('space-y-4', compact && 'p-4 pt-0')}>
        {/* Description */}
        {!compact && (
          <p className="text-sm text-muted-foreground line-clamp-2">
            {assignment.description}
          </p>
        )}

        {/* Meta info */}
        <div className="space-y-2">
          <DueDateIndicator dueDate={assignment.dueDate} status={assignment.status} />

          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <FileText className="h-4 w-4" />
            <span>Total Marks: {assignment.totalMarks}</span>
          </div>

          {assignment.submittedDate && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <CheckCircle className="h-4 w-4" />
              <span>
                Submitted {formatDistanceToNow(assignment.submittedDate, { addSuffix: true })}
              </span>
            </div>
          )}
        </div>

        {/* Grade display */}
        {showGrade && assignment.grade !== undefined && assignment.status === 'graded' && (
          <div className="space-y-2 p-3 bg-muted/50 rounded-lg">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Your Grade</span>
              <span className="text-lg font-bold">
                {assignment.grade} / {assignment.totalMarks}
              </span>
            </div>
            <Progress value={gradePercentage} className="h-2" />
            <p className="text-xs text-muted-foreground">
              {gradePercentage.toFixed(1)}%
            </p>
            {assignment.feedback && (
              <div className="mt-2 pt-2 border-t">
                <p className="text-xs font-medium mb-1">Teacher's Feedback:</p>
                <p className="text-xs text-muted-foreground">{assignment.feedback}</p>
              </div>
            )}
          </div>
        )}

        {/* Attachments */}
        {assignment.attachments && assignment.attachments.length > 0 && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Attachments:</p>
            <div className="space-y-1">
              {assignment.attachments.map((file) => (
                <Button
                  key={file.id}
                  variant="outline"
                  size="sm"
                  className="w-full justify-start"
                  onClick={() => onDownload?.(file.id)}
                >
                  <Download className="h-4 w-4 mr-2" />
                  <span className="truncate">{file.name}</span>
                  <span className="text-xs text-muted-foreground ml-auto">
                    {(file.size / 1024).toFixed(0)} KB
                  </span>
                </Button>
              ))}
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-2">
          {assignment.status === 'pending' && onSubmit && (
            <Button
              className="flex-1"
              onClick={() => onSubmit(assignment.id)}
            >
              <Upload className="h-4 w-4 mr-2" />
              Submit Assignment
            </Button>
          )}

          {onView && (
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => onView(assignment.id)}
            >
              View Details
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

// ========================================
// ASSIGNMENT LIST
// ========================================

export interface AssignmentListProps {
  assignments: AssignmentData[]
  onSubmit?: (assignmentId: string) => void
  onDownload?: (attachmentId: string) => void
  onView?: (assignmentId: string) => void
  groupBy?: 'status' | 'subject' | 'dueDate'
}

export function AssignmentList({
  assignments,
  onSubmit,
  onDownload,
  onView,
  groupBy,
}: AssignmentListProps) {
  if (groupBy === 'status') {
    const grouped = assignments.reduce((acc, assignment) => {
      const status = assignment.status
      if (!acc[status]) acc[status] = []
      acc[status].push(assignment)
      return acc
    }, {} as Record<string, AssignmentData[]>)

    return (
      <div className="space-y-6">
        {Object.entries(grouped).map(([status, items]) => (
          <div key={status}>
            <h3 className="text-lg font-semibold mb-3 capitalize">{status}</h3>
            <div className="grid gap-4">
              {items.map((assignment) => (
                <AssignmentCard
                  key={assignment.id}
                  assignment={assignment}
                  onSubmit={onSubmit}
                  onDownload={onDownload}
                  onView={onView}
                  compact
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {assignments.map((assignment) => (
        <AssignmentCard
          key={assignment.id}
          assignment={assignment}
          onSubmit={onSubmit}
          onDownload={onDownload}
          onView={onView}
        />
      ))}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

```typescript
import { AssignmentCard } from '@/components/academic/assignment-card'

function StudentAssignments() {
  const assignment = {
    id: '1',
    title: 'Chapter 5 - Algebra Problems',
    subject: 'Mathematics',
    subjectCode: 'MATH101',
    description: 'Solve problems 1-20 from chapter 5',
    assignedDate: new Date('2024-01-01'),
    dueDate: new Date('2024-01-15'),
    totalMarks: 100,
    teacherName: 'Mr. Smith',
    status: 'pending' as const,
  }

  return (
    <AssignmentCard
      assignment={assignment}
      onSubmit={(id) => console.log('Submit', id)}
    />
  )
}
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create assignment-card.tsx
- [ ] Add status tracking
- [ ] Implement file handling
- [ ] Write tests

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
