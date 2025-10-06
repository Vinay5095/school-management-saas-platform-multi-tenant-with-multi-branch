import * as React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { cn } from '@/lib/utils'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

export interface GradeCardProps {
  subject: string
  grade: string | number
  maxGrade?: number
  percentage?: number
  trend?: 'up' | 'down' | 'stable'
  className?: string
  comments?: string
}

export function GradeCard({
  subject,
  grade,
  maxGrade = 100,
  percentage,
  trend = 'stable',
  className,
  comments,
}: GradeCardProps) {
  const calculatedPercentage =
    percentage ?? (typeof grade === 'number' ? (grade / maxGrade) * 100 : 0)

  const getGradeColor = (pct: number) => {
    if (pct >= 90) return 'text-green-600 dark:text-green-400'
    if (pct >= 80) return 'text-blue-600 dark:text-blue-400'
    if (pct >= 70) return 'text-yellow-600 dark:text-yellow-400'
    if (pct >= 60) return 'text-orange-600 dark:text-orange-400'
    return 'text-red-600 dark:text-red-400'
  }

  const getGradeBadge = (pct: number) => {
    if (pct >= 90) return 'Excellent'
    if (pct >= 80) return 'Good'
    if (pct >= 70) return 'Average'
    if (pct >= 60) return 'Below Average'
    return 'Needs Improvement'
  }

  const TrendIcon =
    trend === 'up' ? TrendingUp : trend === 'down' ? TrendingDown : Minus

  return (
    <Card className={cn('w-full', className)}>
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="text-base font-semibold">{subject}</CardTitle>
            <div className="flex items-center gap-2 mt-1">
              <span className={cn('text-2xl font-bold', getGradeColor(calculatedPercentage))}>
                {grade}
              </span>
              {typeof grade === 'number' && (
                <span className="text-sm text-muted-foreground">/ {maxGrade}</span>
              )}
            </div>
          </div>
          <TrendIcon
            className={cn(
              'h-4 w-4',
              trend === 'up' && 'text-green-500',
              trend === 'down' && 'text-red-500',
              trend === 'stable' && 'text-gray-500'
            )}
          />
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        <div>
          <div className="flex items-center justify-between text-sm mb-1">
            <span className="text-muted-foreground">Performance</span>
            <span className="font-medium">{calculatedPercentage.toFixed(1)}%</span>
          </div>
          <Progress value={calculatedPercentage} className="h-2" />
        </div>
        <div className="flex items-center justify-between">
          <Badge variant={calculatedPercentage >= 80 ? 'default' : 'secondary'}>
            {getGradeBadge(calculatedPercentage)}
          </Badge>
        </div>
        {comments && (
          <p className="text-xs text-muted-foreground mt-2">{comments}</p>
        )}
      </CardContent>
    </Card>
  )
}
