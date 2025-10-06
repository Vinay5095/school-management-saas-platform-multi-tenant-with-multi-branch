import * as React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { CheckCircle2, XCircle, Clock, AlertCircle } from 'lucide-react'

export interface AttendanceWidgetProps {
  studentName?: string
  className?: string
  date?: string
  status: 'present' | 'absent' | 'late' | 'excused'
  onStatusChange?: (status: AttendanceWidgetProps['status']) => void
  readonly?: boolean
}

export function AttendanceWidget({
  studentName,
  className,
  date = new Date().toLocaleDateString(),
  status,
  onStatusChange,
  readonly = false,
}: AttendanceWidgetProps) {
  const statusConfig = {
    present: {
      icon: CheckCircle2,
      label: 'Present',
      color: 'text-green-500',
      bg: 'bg-green-50 dark:bg-green-950',
    },
    absent: {
      icon: XCircle,
      label: 'Absent',
      color: 'text-red-500',
      bg: 'bg-red-50 dark:bg-red-950',
    },
    late: {
      icon: Clock,
      label: 'Late',
      color: 'text-orange-500',
      bg: 'bg-orange-50 dark:bg-orange-950',
    },
    excused: {
      icon: AlertCircle,
      label: 'Excused',
      color: 'text-blue-500',
      bg: 'bg-blue-50 dark:bg-blue-950',
    },
  }

  const config = statusConfig[status]
  const Icon = config.icon

  return (
    <Card className={cn('w-full', className)}>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm font-medium">
          {studentName || 'Attendance'}
        </CardTitle>
        <p className="text-xs text-muted-foreground">{date}</p>
      </CardHeader>
      <CardContent>
        <div className={cn('flex items-center gap-3 p-3 rounded-lg', config.bg)}>
          <Icon className={cn('h-5 w-5', config.color)} />
          <div className="flex-1">
            <p className={cn('font-medium', config.color)}>{config.label}</p>
          </div>
          {!readonly && (
            <div className="flex gap-1">
              {(Object.keys(statusConfig) as Array<keyof typeof statusConfig>).map(
                (s) => (
                  <button
                    key={s}
                    onClick={() => onStatusChange?.(s)}
                    className={cn(
                      'p-1 rounded hover:bg-background/50',
                      status === s && 'ring-2 ring-primary'
                    )}
                    aria-label={`Mark as ${statusConfig[s].label}`}
                  >
                    {React.createElement(statusConfig[s].icon, {
                      className: cn('h-4 w-4', statusConfig[s].color),
                    })}
                  </button>
                )
              )}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  )
}
