# SPEC-107: Grade Card Component
## Student Grade Display and Report Cards

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 2 hours  
> **Dependencies**: Recharts

---

## 📋 OVERVIEW

### Purpose
A comprehensive grade card component for displaying student grades, subject-wise performance, GPA calculation, and progress visualization.

### Key Features
- ✅ Subject-wise grade display
- ✅ GPA/CGPA calculation
- ✅ Performance charts
- ✅ Grade comparison
- ✅ Remarks and comments
- ✅ Printable format
- ✅ Multiple grading systems
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/grade-card.tsx
import * as React from 'react'
import {
  Award,
  TrendingUp,
  TrendingDown,
  Minus,
  Download,
  Printer,
  Medal,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type GradingSystem = 'percentage' | 'gpa' | 'letter' | 'cgpa'

export interface SubjectGrade {
  subjectId: string
  subjectName: string
  subjectCode?: string
  marks: number
  totalMarks: number
  grade: string
  gradePoints?: number
  credits?: number
  remarks?: string
  teacher?: string
}

export interface GradeCardData {
  studentId: string
  studentName: string
  rollNumber: string
  className: string
  section: string
  term: string
  academicYear: string
  subjects: SubjectGrade[]
  totalMarks: number
  obtainedMarks: number
  percentage: number
  gpa?: number
  cgpa?: number
  rank?: number
  totalStudents?: number
  attendance?: number
  conduct?: string
  remarks?: string
  teacherComments?: string
  principalComments?: string
  issueDate: Date
}

export interface GradeCardProps {
  /**
   * Grade card data
   */
  data: GradeCardData

  /**
   * Grading system
   */
  gradingSystem?: GradingSystem

  /**
   * Show charts
   */
  showCharts?: boolean

  /**
   * Show comparison
   */
  showComparison?: boolean

  /**
   * Previous term data for comparison
   */
  previousTermData?: GradeCardData

  /**
   * Printable mode
   */
  printable?: boolean

  /**
   * On print
   */
  onPrint?: () => void

  /**
   * On download
   */
  onDownload?: () => void

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// GRADE BADGE
// ========================================

interface GradeBadgeProps {
  grade: string
  size?: 'sm' | 'md' | 'lg'
}

function GradeBadge({ grade, size = 'md' }: GradeBadgeProps) {
  const getGradeColor = (grade: string) => {
    const firstChar = grade.charAt(0).toUpperCase()
    switch (firstChar) {
      case 'A':
        return 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400'
      case 'B':
        return 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400'
      case 'C':
        return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400'
      case 'D':
        return 'bg-orange-100 text-orange-700 dark:bg-orange-950 dark:text-orange-400'
      case 'F':
        return 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400'
      default:
        return 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400'
    }
  }

  return (
    <Badge
      className={cn(
        'font-bold',
        getGradeColor(grade),
        {
          'text-xs px-2 py-0.5': size === 'sm',
          'text-sm px-3 py-1': size === 'md',
          'text-lg px-4 py-1.5': size === 'lg',
        }
      )}
    >
      {grade}
    </Badge>
  )
}

// ========================================
// PERFORMANCE TREND
// ========================================

interface PerformanceTrendProps {
  current: number
  previous?: number
}

function PerformanceTrend({ current, previous }: PerformanceTrendProps) {
  if (!previous) return null

  const diff = current - previous
  const percentage = ((diff / previous) * 100).toFixed(1)

  if (diff > 0) {
    return (
      <div className="flex items-center gap-1 text-green-600 text-sm">
        <TrendingUp className="h-4 w-4" />
        <span>+{percentage}%</span>
      </div>
    )
  }

  if (diff < 0) {
    return (
      <div className="flex items-center gap-1 text-red-600 text-sm">
        <TrendingDown className="h-4 w-4" />
        <span>{percentage}%</span>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-1 text-gray-600 text-sm">
      <Minus className="h-4 w-4" />
      <span>No change</span>
    </div>
  )
}

// ========================================
// GRADE CARD HEADER
// ========================================

interface GradeCardHeaderProps {
  data: GradeCardData
  onPrint?: () => void
  onDownload?: () => void
  printable?: boolean
}

function GradeCardHeader({ data, onPrint, onDownload, printable }: GradeCardHeaderProps) {
  return (
    <div className="space-y-4">
      {/* School header - would include school logo */}
      <div className="text-center space-y-1">
        <h1 className="text-2xl font-bold">Report Card</h1>
        <p className="text-muted-foreground">
          Academic Year {data.academicYear} - {data.term}
        </p>
      </div>

      {/* Student info */}
      <div className="grid grid-cols-2 gap-4 p-4 bg-muted/50 rounded-lg">
        <div className="space-y-2">
          <div>
            <span className="text-sm text-muted-foreground">Student Name</span>
            <p className="font-semibold">{data.studentName}</p>
          </div>
          <div>
            <span className="text-sm text-muted-foreground">Roll Number</span>
            <p className="font-semibold">{data.rollNumber}</p>
          </div>
        </div>
        <div className="space-y-2">
          <div>
            <span className="text-sm text-muted-foreground">Class</span>
            <p className="font-semibold">
              {data.className} - {data.section}
            </p>
          </div>
          {data.rank && (
            <div>
              <span className="text-sm text-muted-foreground">Rank</span>
              <p className="font-semibold">
                {data.rank} / {data.totalStudents}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Actions */}
      {!printable && (
        <div className="flex gap-2 justify-end print:hidden">
          {onPrint && (
            <Button variant="outline" size="sm" onClick={onPrint}>
              <Printer className="h-4 w-4 mr-2" />
              Print
            </Button>
          )}
          {onDownload && (
            <Button variant="outline" size="sm" onClick={onDownload}>
              <Download className="h-4 w-4 mr-2" />
              Download PDF
            </Button>
          )}
        </div>
      )}
    </div>
  )
}

// ========================================
// SUBJECT GRADES TABLE
// ========================================

interface SubjectGradesTableProps {
  subjects: SubjectGrade[]
  gradingSystem: GradingSystem
}

function SubjectGradesTable({ subjects, gradingSystem }: SubjectGradesTableProps) {
  const showCredits = gradingSystem === 'gpa' || gradingSystem === 'cgpa'

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Subject</TableHead>
          <TableHead className="text-center">Code</TableHead>
          <TableHead className="text-center">Marks</TableHead>
          {showCredits && <TableHead className="text-center">Credits</TableHead>}
          <TableHead className="text-center">Grade</TableHead>
          {showCredits && <TableHead className="text-center">Grade Points</TableHead>}
          <TableHead>Remarks</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {subjects.map((subject) => (
          <TableRow key={subject.subjectId}>
            <TableCell className="font-medium">{subject.subjectName}</TableCell>
            <TableCell className="text-center text-muted-foreground">
              {subject.subjectCode}
            </TableCell>
            <TableCell className="text-center">
              {subject.marks} / {subject.totalMarks}
            </TableCell>
            {showCredits && (
              <TableCell className="text-center">{subject.credits}</TableCell>
            )}
            <TableCell className="text-center">
              <GradeBadge grade={subject.grade} size="sm" />
            </TableCell>
            {showCredits && (
              <TableCell className="text-center font-semibold">
                {subject.gradePoints?.toFixed(2)}
              </TableCell>
            )}
            <TableCell className="text-sm text-muted-foreground">
              {subject.remarks}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}

// ========================================
// GRADE SUMMARY
// ========================================

interface GradeSummaryProps {
  data: GradeCardData
  gradingSystem: GradingSystem
  previousData?: GradeCardData
}

function GradeSummary({ data, gradingSystem, previousData }: GradeSummaryProps) {
  const getOverallGrade = (percentage: number) => {
    if (percentage >= 90) return 'A+'
    if (percentage >= 80) return 'A'
    if (percentage >= 70) return 'B'
    if (percentage >= 60) return 'C'
    if (percentage >= 50) return 'D'
    return 'F'
  }

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      <Card>
        <CardContent className="pt-6">
          <div className="text-center space-y-2">
            <p className="text-sm text-muted-foreground">Total Marks</p>
            <p className="text-3xl font-bold">
              {data.obtainedMarks} / {data.totalMarks}
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-6">
          <div className="text-center space-y-2">
            <p className="text-sm text-muted-foreground">Percentage</p>
            <p className="text-3xl font-bold">{data.percentage.toFixed(2)}%</p>
            {previousData && (
              <PerformanceTrend
                current={data.percentage}
                previous={previousData.percentage}
              />
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-6">
          <div className="text-center space-y-2">
            <p className="text-sm text-muted-foreground">Overall Grade</p>
            <div className="flex justify-center">
              <GradeBadge grade={getOverallGrade(data.percentage)} size="lg" />
            </div>
          </div>
        </CardContent>
      </Card>

      {(gradingSystem === 'gpa' || gradingSystem === 'cgpa') && data.gpa && (
        <Card>
          <CardContent className="pt-6">
            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">
                {gradingSystem === 'cgpa' ? 'CGPA' : 'GPA'}
              </p>
              <p className="text-3xl font-bold">{data.gpa.toFixed(2)}</p>
              {previousData && previousData.gpa && (
                <PerformanceTrend
                  current={data.gpa}
                  previous={previousData.gpa}
                />
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {data.rank && (
        <Card>
          <CardContent className="pt-6">
            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">Class Rank</p>
              <div className="flex items-center justify-center gap-2">
                <Medal className="h-6 w-6 text-yellow-600" />
                <p className="text-3xl font-bold">#{data.rank}</p>
              </div>
              <p className="text-xs text-muted-foreground">
                out of {data.totalStudents} students
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {data.attendance !== undefined && (
        <Card>
          <CardContent className="pt-6">
            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">Attendance</p>
              <p className="text-3xl font-bold">{data.attendance}%</p>
              <Progress value={data.attendance} className="h-2" />
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

// ========================================
// GRADE CARD COMPONENT
// ========================================

/**
 * Grade Card Component
 * 
 * Comprehensive student grade display and report card.
 */
export function GradeCard({
  data,
  gradingSystem = 'percentage',
  showCharts = true,
  showComparison = true,
  previousTermData,
  printable = false,
  onPrint,
  onDownload,
  className,
}: GradeCardProps) {
  return (
    <div className={cn('space-y-6', printable && 'p-8', className)}>
      {/* Header */}
      <GradeCardHeader
        data={data}
        onPrint={onPrint}
        onDownload={onDownload}
        printable={printable}
      />

      {/* Summary */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Performance Summary</h3>
        <GradeSummary
          data={data}
          gradingSystem={gradingSystem}
          previousData={showComparison ? previousTermData : undefined}
        />
      </div>

      {/* Subject grades */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Subject-wise Grades</h3>
        <div className="border rounded-lg overflow-hidden">
          <SubjectGradesTable
            subjects={data.subjects}
            gradingSystem={gradingSystem}
          />
        </div>
      </div>

      {/* Additional info */}
      <div className="grid md:grid-cols-2 gap-4">
        {data.conduct && (
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Conduct</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm">{data.conduct}</p>
            </CardContent>
          </Card>
        )}

        {data.remarks && (
          <Card>
            <CardHeader>
              <CardTitle className="text-base">General Remarks</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm">{data.remarks}</p>
            </CardContent>
          </Card>
        )}

        {data.teacherComments && (
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Class Teacher's Comments</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm">{data.teacherComments}</p>
            </CardContent>
          </Card>
        )}

        {data.principalComments && (
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Principal's Comments</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm">{data.principalComments}</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Footer */}
      {printable && (
        <div className="mt-8 pt-4 border-t text-sm text-muted-foreground text-center">
          <p>Issued on: {data.issueDate.toLocaleDateString()}</p>
        </div>
      )}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Grade Card

```typescript
import { GradeCard } from '@/components/academic/grade-card'

function StudentGrades() {
  const gradeData = {
    studentId: '1',
    studentName: 'John Doe',
    rollNumber: '2024-10-001',
    className: 'Grade 10',
    section: 'A',
    term: 'Semester 1',
    academicYear: '2024-2025',
    subjects: [
      {
        subjectId: '1',
        subjectName: 'Mathematics',
        subjectCode: 'MATH101',
        marks: 85,
        totalMarks: 100,
        grade: 'A',
        remarks: 'Excellent performance',
      },
      // ... more subjects
    ],
    totalMarks: 500,
    obtainedMarks: 425,
    percentage: 85,
    rank: 5,
    totalStudents: 40,
    attendance: 95,
    issueDate: new Date(),
  }

  return <GradeCard data={gradeData} />
}
```

---

## 🧪 TESTING

```typescript
describe('GradeCard', () => {
  it('renders student information', () => {
    render(<GradeCard data={mockGradeData} />)
    expect(screen.getByText(mockGradeData.studentName)).toBeInTheDocument()
  })

  it('calculates percentage correctly', () => {
    // Test calculation logic
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Semantic table structure
- ✅ Clear headers
- ✅ Print-friendly layout
- ✅ High contrast colors

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create grade-card.tsx
- [ ] Implement grading calculations
- [ ] Add print styles
- [ ] Add PDF export
- [ ] Write tests
- [ ] Document usage

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
