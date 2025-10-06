# SPEC-109: Student Card Component
## Student Profile Card with Quick Actions

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 1.5 hours  
> **Dependencies**: None

---

## 📋 OVERVIEW

### Purpose
A compact student profile card component displaying key student information, status indicators, and quick action buttons.

### Key Features
- ✅ Student photo/avatar
- ✅ Key information display
- ✅ Status badges (active, suspended, graduated)
- ✅ Quick action buttons
- ✅ Performance indicators
- ✅ Contact information
- ✅ Responsive design
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/academic/student-card.tsx
import * as React from 'react'
import {
  User,
  Mail,
  Phone,
  MapPin,
  Calendar,
  BookOpen,
  Award,
  MoreVertical,
  Eye,
  Edit,
  Trash2,
} from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export type StudentStatus = 'active' | 'suspended' | 'graduated' | 'transferred' | 'inactive'

export interface StudentCardData {
  id: string
  firstName: string
  lastName: string
  rollNumber: string
  avatar?: string
  status: StudentStatus
  grade: string
  section: string
  dateOfBirth: Date
  email?: string
  phone?: string
  address?: string
  admissionDate: Date
  attendance?: number
  gpa?: number
  parentName?: string
  parentPhone?: string
}

export interface StudentCardProps {
  /**
   * Student data
   */
  student: StudentCardData

  /**
   * Show contact info
   */
  showContact?: boolean

  /**
   * Show academic info
   */
  showAcademic?: boolean

  /**
   * Show actions
   */
  showActions?: boolean

  /**
   * On view details
   */
  onView?: (studentId: string) => void

  /**
   * On edit
   */
  onEdit?: (studentId: string) => void

  /**
   * On delete
   */
  onDelete?: (studentId: string) => void

  /**
   * Additional classname
   */
  className?: string
}

// ========================================
// STATUS BADGE
// ========================================

function getStatusConfig(status: StudentStatus) {
  const configs = {
    active: {
      label: 'Active',
      className: 'bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400',
    },
    suspended: {
      label: 'Suspended',
      className: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400',
    },
    graduated: {
      label: 'Graduated',
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400',
    },
    transferred: {
      label: 'Transferred',
      className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-400',
    },
    inactive: {
      label: 'Inactive',
      className: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400',
    },
  }
  return configs[status]
}

// ========================================
// STUDENT CARD COMPONENT
// ========================================

/**
 * Student Card Component
 * 
 * Compact student profile card with key information and actions.
 */
export function StudentCard({
  student,
  showContact = true,
  showAcademic = true,
  showActions = true,
  onView,
  onEdit,
  onDelete,
  className,
}: StudentCardProps) {
  const statusConfig = getStatusConfig(student.status)
  const fullName = `${student.firstName} ${student.lastName}`
  const initials = `${student.firstName[0]}${student.lastName[0]}`

  return (
    <Card className={cn('hover:shadow-lg transition-shadow', className)}>
      <CardContent className="p-6">
        <div className="space-y-4">
          {/* Header with avatar and actions */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <Avatar className="h-12 w-12">
                <AvatarImage src={student.avatar} alt={fullName} />
                <AvatarFallback>{initials}</AvatarFallback>
              </Avatar>
              <div>
                <h3 className="font-semibold text-lg">{fullName}</h3>
                <p className="text-sm text-muted-foreground">
                  Roll: {student.rollNumber}
                </p>
              </div>
            </div>

            {showActions && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon">
                    <MoreVertical className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  {onView && (
                    <DropdownMenuItem onClick={() => onView(student.id)}>
                      <Eye className="h-4 w-4 mr-2" />
                      View Details
                    </DropdownMenuItem>
                  )}
                  {onEdit && (
                    <DropdownMenuItem onClick={() => onEdit(student.id)}>
                      <Edit className="h-4 w-4 mr-2" />
                      Edit
                    </DropdownMenuItem>
                  )}
                  {onDelete && (
                    <DropdownMenuItem
                      onClick={() => onDelete(student.id)}
                      className="text-destructive"
                    >
                      <Trash2 className="h-4 w-4 mr-2" />
                      Delete
                    </DropdownMenuItem>
                  )}
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>

          {/* Status and class info */}
          <div className="flex items-center gap-2 flex-wrap">
            <Badge className={statusConfig.className}>
              {statusConfig.label}
            </Badge>
            <Badge variant="outline">
              <BookOpen className="h-3 w-3 mr-1" />
              {student.grade} - {student.section}
            </Badge>
          </div>

          {/* Academic performance */}
          {showAcademic && (student.attendance !== undefined || student.gpa !== undefined) && (
            <div className="grid grid-cols-2 gap-3">
              {student.attendance !== undefined && (
                <div className="space-y-1">
                  <p className="text-xs text-muted-foreground">Attendance</p>
                  <p className="text-lg font-semibold">{student.attendance}%</p>
                </div>
              )}
              {student.gpa !== undefined && (
                <div className="space-y-1">
                  <p className="text-xs text-muted-foreground">GPA</p>
                  <p className="text-lg font-semibold">{student.gpa.toFixed(2)}</p>
                </div>
              )}
            </div>
          )}

          {/* Contact information */}
          {showContact && (
            <div className="space-y-2 text-sm">
              {student.email && (
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Mail className="h-4 w-4" />
                  <span className="truncate">{student.email}</span>
                </div>
              )}
              {student.phone && (
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Phone className="h-4 w-4" />
                  <span>{student.phone}</span>
                </div>
              )}
              {student.parentName && (
                <div className="text-xs text-muted-foreground">
                  Parent: {student.parentName}
                  {student.parentPhone && ` (${student.parentPhone})`}
                </div>
              )}
            </div>
          )}

          {/* View details button */}
          {onView && (
            <Button
              variant="outline"
              className="w-full"
              onClick={() => onView(student.id)}
            >
              View Full Profile
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

// ========================================
// STUDENT GRID
// ========================================

export interface StudentGridProps {
  students: StudentCardData[]
  onView?: (studentId: string) => void
  onEdit?: (studentId: string) => void
  onDelete?: (studentId: string) => void
  columns?: 1 | 2 | 3 | 4
}

export function StudentGrid({
  students,
  onView,
  onEdit,
  onDelete,
  columns = 3,
}: StudentGridProps) {
  return (
    <div
      className={cn(
        'grid gap-4',
        columns === 1 && 'grid-cols-1',
        columns === 2 && 'grid-cols-1 md:grid-cols-2',
        columns === 3 && 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
        columns === 4 && 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
      )}
    >
      {students.map((student) => (
        <StudentCard
          key={student.id}
          student={student}
          onView={onView}
          onEdit={onEdit}
          onDelete={onDelete}
        />
      ))}
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

```typescript
import { StudentCard, StudentGrid } from '@/components/academic/student-card'

function StudentList() {
  const student = {
    id: '1',
    firstName: 'John',
    lastName: 'Doe',
    rollNumber: '2024-10-001',
    status: 'active' as const,
    grade: 'Grade 10',
    section: 'A',
    dateOfBirth: new Date('2009-05-15'),
    email: 'john.doe@school.com',
    phone: '+1234567890',
    admissionDate: new Date('2020-04-01'),
    attendance: 95,
    gpa: 3.8,
    parentName: 'Jane Doe',
    parentPhone: '+1234567891',
  }

  return (
    <StudentCard
      student={student}
      onView={(id) => console.log('View', id)}
      onEdit={(id) => console.log('Edit', id)}
    />
  )
}
```

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create student-card.tsx
- [ ] Implement status badges
- [ ] Add quick actions
- [ ] Write tests

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
