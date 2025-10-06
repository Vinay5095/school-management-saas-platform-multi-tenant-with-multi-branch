import * as React from 'react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { Mail, Phone, MapPin, Calendar } from 'lucide-react'

export interface StudentCardProps {
  name: string
  studentId: string
  grade?: string
  className?: string
  photoUrl?: string
  email?: string
  phone?: string
  address?: string
  dateOfBirth?: string
  status?: 'active' | 'inactive' | 'suspended'
  onViewDetails?: () => void
  onContact?: () => void
}

export function StudentCard({
  name,
  studentId,
  grade,
  className,
  photoUrl,
  email,
  phone,
  address,
  dateOfBirth,
  status = 'active',
  onViewDetails,
  onContact,
}: StudentCardProps) {
  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2)
  }

  const statusColors = {
    active: 'bg-green-500',
    inactive: 'bg-gray-500',
    suspended: 'bg-red-500',
  }

  return (
    <Card className={cn('w-full', className)}>
      <CardHeader className="pb-3">
        <div className="flex items-start gap-4">
          <div className="relative">
            <Avatar className="h-16 w-16">
              <AvatarImage src={photoUrl} alt={name} />
              <AvatarFallback>{getInitials(name)}</AvatarFallback>
            </Avatar>
            <span
              className={cn(
                'absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-background',
                statusColors[status]
              )}
            />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <div>
                <h3 className="font-semibold text-lg truncate">{name}</h3>
                <p className="text-sm text-muted-foreground">ID: {studentId}</p>
              </div>
              {grade && (
                <Badge variant="secondary" className="shrink-0">
                  {grade}
                </Badge>
              )}
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        {email && (
          <div className="flex items-center gap-2 text-sm">
            <Mail className="h-4 w-4 text-muted-foreground shrink-0" />
            <span className="truncate">{email}</span>
          </div>
        )}
        {phone && (
          <div className="flex items-center gap-2 text-sm">
            <Phone className="h-4 w-4 text-muted-foreground shrink-0" />
            <span>{phone}</span>
          </div>
        )}
        {address && (
          <div className="flex items-center gap-2 text-sm">
            <MapPin className="h-4 w-4 text-muted-foreground shrink-0" />
            <span className="truncate">{address}</span>
          </div>
        )}
        {dateOfBirth && (
          <div className="flex items-center gap-2 text-sm">
            <Calendar className="h-4 w-4 text-muted-foreground shrink-0" />
            <span>{dateOfBirth}</span>
          </div>
        )}
        <div className="flex gap-2 pt-2">
          {onViewDetails && (
            <Button variant="outline" size="sm" onClick={onViewDetails} className="flex-1">
              View Details
            </Button>
          )}
          {onContact && (
            <Button variant="default" size="sm" onClick={onContact} className="flex-1">
              Contact
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  )
}
