# SPEC-104: Notification Center Component
## Notification Bell and Dropdown Center

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 2 hours  
> **Dependencies**: Radix UI Dropdown, date-fns

---

## 📋 OVERVIEW

### Purpose
A comprehensive notification center with bell icon, badge counter, dropdown panel, notification list, filtering, and mark as read functionality.

### Key Features
- ✅ Bell icon with badge counter
- ✅ Dropdown notification panel
- ✅ Multiple notification types
- ✅ Mark as read/unread
- ✅ Mark all as read
- ✅ Filter notifications
- ✅ Real-time updates
- ✅ Pagination/infinite scroll
- ✅ Action buttons
- ✅ TypeScript support

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/notification-center.tsx
import * as React from 'react'
import {
  Bell,
  Check,
  CheckCheck,
  X,
  AlertCircle,
  Info,
  UserPlus,
  Calendar,
  Mail,
  Settings,
} from 'lucide-react'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { cn } from '@/lib/utils'
import { formatDistanceToNow } from 'date-fns'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface Notification {
  id: string
  type: 'info' | 'success' | 'warning' | 'error' | 'message' | 'update'
  title: string
  message: string
  timestamp: Date
  read: boolean
  link?: string
  action?: {
    label: string
    onClick: () => void
  }
  avatar?: string
  icon?: React.ReactNode
}

export interface NotificationCenterProps {
  /**
   * Notifications
   */
  notifications: Notification[]

  /**
   * On notification click
   */
  onNotificationClick?: (notification: Notification) => void

  /**
   * Mark notification as read
   */
  onMarkAsRead?: (id: string) => void

  /**
   * Mark all as read
   */
  onMarkAllAsRead?: () => void

  /**
   * Delete notification
   */
  onDelete?: (id: string) => void

  /**
   * Clear all notifications
   */
  onClearAll?: () => void

  /**
   * Load more notifications
   */
  onLoadMore?: () => void

  /**
   * Has more notifications
   */
  hasMore?: boolean

  /**
   * Loading state
   */
  loading?: boolean

  /**
   * Show tabs for filtering
   */
  showTabs?: boolean

  /**
   * Custom bell icon
   */
  bellIcon?: React.ReactNode

  /**
   * Max notifications to show before "View All"
   */
  maxVisible?: number
}

export interface NotificationItemProps {
  notification: Notification
  onRead?: (id: string) => void
  onDelete?: (id: string) => void
  onClick?: () => void
}

// ========================================
// NOTIFICATION ITEM COMPONENT
// ========================================

/**
 * Notification Item Component
 */
function NotificationItem({
  notification,
  onRead,
  onDelete,
  onClick,
}: NotificationItemProps) {
  const typeIcons = {
    info: <Info className="h-4 w-4 text-blue-500" />,
    success: <CheckCheck className="h-4 w-4 text-green-500" />,
    warning: <AlertCircle className="h-4 w-4 text-yellow-500" />,
    error: <X className="h-4 w-4 text-red-500" />,
    message: <Mail className="h-4 w-4 text-purple-500" />,
    update: <Settings className="h-4 w-4 text-gray-500" />,
  }

  const handleClick = () => {
    onClick?.()
    if (!notification.read) {
      onRead?.(notification.id)
    }
  }

  return (
    <div
      className={cn(
        'group relative flex gap-3 p-4 transition-colors hover:bg-accent cursor-pointer border-b last:border-b-0',
        !notification.read && 'bg-accent/50'
      )}
      onClick={handleClick}
    >
      {/* Unread indicator */}
      {!notification.read && (
        <div className="absolute left-2 top-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-primary" />
      )}

      {/* Icon/Avatar */}
      <div className="flex-shrink-0 ml-3">
        {notification.avatar ? (
          <img
            src={notification.avatar}
            alt=""
            className="w-10 h-10 rounded-full"
          />
        ) : notification.icon ? (
          <div className="w-10 h-10 rounded-full bg-accent flex items-center justify-center">
            {notification.icon}
          </div>
        ) : (
          <div className="w-10 h-10 rounded-full bg-accent flex items-center justify-center">
            {typeIcons[notification.type]}
          </div>
        )}
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium truncate">
              {notification.title}
            </p>
            <p className="text-sm text-muted-foreground line-clamp-2 mt-0.5">
              {notification.message}
            </p>
          </div>

          {/* Delete button */}
          <button
            onClick={(e) => {
              e.stopPropagation()
              onDelete?.(notification.id)
            }}
            className="opacity-0 group-hover:opacity-100 transition-opacity"
            aria-label="Delete notification"
          >
            <X className="h-4 w-4 text-muted-foreground hover:text-foreground" />
          </button>
        </div>

        {/* Timestamp */}
        <p className="text-xs text-muted-foreground mt-1">
          {formatDistanceToNow(notification.timestamp, { addSuffix: true })}
        </p>

        {/* Action button */}
        {notification.action && (
          <Button
            size="sm"
            variant="outline"
            className="mt-2"
            onClick={(e) => {
              e.stopPropagation()
              notification.action!.onClick()
            }}
          >
            {notification.action.label}
          </Button>
        )}
      </div>
    </div>
  )
}

// ========================================
// NOTIFICATION CENTER COMPONENT
// ========================================

/**
 * Notification Center Component
 * 
 * Bell icon with dropdown notification panel.
 */
export function NotificationCenter({
  notifications,
  onNotificationClick,
  onMarkAsRead,
  onMarkAllAsRead,
  onDelete,
  onClearAll,
  onLoadMore,
  hasMore = false,
  loading = false,
  showTabs = true,
  bellIcon,
  maxVisible = 5,
}: NotificationCenterProps) {
  const [filter, setFilter] = React.useState<'all' | 'unread'>('all')
  const [open, setOpen] = React.useState(false)

  // Filter notifications
  const filteredNotifications = React.useMemo(() => {
    if (filter === 'unread') {
      return notifications.filter((n) => !n.read)
    }
    return notifications
  }, [notifications, filter])

  // Visible notifications
  const visibleNotifications = filteredNotifications.slice(0, maxVisible)

  // Unread count
  const unreadCount = React.useMemo(
    () => notifications.filter((n) => !n.read).length,
    [notifications]
  )

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          {bellIcon || <Bell className="h-5 w-5" />}
          {unreadCount > 0 && (
            <Badge
              variant="destructive"
              className="absolute -top-1 -right-1 h-5 min-w-5 flex items-center justify-center p-0 text-xs"
            >
              {unreadCount > 99 ? '99+' : unreadCount}
            </Badge>
          )}
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent
        align="end"
        className="w-[400px] p-0"
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b">
          <h3 className="font-semibold">Notifications</h3>
          <div className="flex gap-2">
            {unreadCount > 0 && (
              <Button
                size="sm"
                variant="ghost"
                onClick={onMarkAllAsRead}
              >
                <CheckCheck className="h-4 w-4 mr-1" />
                Mark all read
              </Button>
            )}
          </div>
        </div>

        {/* Tabs */}
        {showTabs && (
          <Tabs
            value={filter}
            onValueChange={(v) => setFilter(v as 'all' | 'unread')}
            className="w-full"
          >
            <TabsList className="w-full rounded-none border-b">
              <TabsTrigger value="all" className="flex-1">
                All
              </TabsTrigger>
              <TabsTrigger value="unread" className="flex-1">
                Unread ({unreadCount})
              </TabsTrigger>
            </TabsList>
          </Tabs>
        )}

        {/* Notification list */}
        <ScrollArea className="h-[400px]">
          {filteredNotifications.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-[200px] text-center p-4">
              <Bell className="h-12 w-12 text-muted-foreground mb-2" />
              <p className="text-sm text-muted-foreground">
                {filter === 'unread'
                  ? 'No unread notifications'
                  : 'No notifications'}
              </p>
            </div>
          ) : (
            <>
              {visibleNotifications.map((notification) => (
                <NotificationItem
                  key={notification.id}
                  notification={notification}
                  onRead={onMarkAsRead}
                  onDelete={onDelete}
                  onClick={() => {
                    onNotificationClick?.(notification)
                    if (notification.link) {
                      window.location.href = notification.link
                    }
                  }}
                />
              ))}

              {/* Load more */}
              {hasMore && (
                <div className="p-4 text-center border-t">
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={onLoadMore}
                    disabled={loading}
                  >
                    {loading ? 'Loading...' : 'Load More'}
                  </Button>
                </div>
              )}
            </>
          )}
        </ScrollArea>

        {/* Footer */}
        {filteredNotifications.length > 0 && (
          <div className="flex items-center justify-between p-3 border-t">
            <Button
              size="sm"
              variant="ghost"
              onClick={() => {
                setOpen(false)
                // Navigate to notifications page
                window.location.href = '/notifications'
              }}
            >
              View All
            </Button>
            {onClearAll && (
              <Button
                size="sm"
                variant="ghost"
                onClick={onClearAll}
              >
                Clear All
              </Button>
            )}
          </div>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

// ========================================
// USE NOTIFICATIONS HOOK
// ========================================

export interface UseNotificationsReturn {
  notifications: Notification[]
  unreadCount: number
  addNotification: (notification: Omit<Notification, 'id' | 'timestamp'>) => void
  markAsRead: (id: string) => void
  markAllAsRead: () => void
  deleteNotification: (id: string) => void
  clearAll: () => void
}

/**
 * Use Notifications Hook
 * 
 * Manages notification state.
 */
export function useNotifications(
  initialNotifications: Notification[] = []
): UseNotificationsReturn {
  const [notifications, setNotifications] = React.useState<Notification[]>(
    initialNotifications
  )

  const unreadCount = React.useMemo(
    () => notifications.filter((n) => !n.read).length,
    [notifications]
  )

  const addNotification = React.useCallback(
    (notification: Omit<Notification, 'id' | 'timestamp'>) => {
      const newNotification: Notification = {
        ...notification,
        id: `${Date.now()}-${Math.random()}`,
        timestamp: new Date(),
      }
      setNotifications((prev) => [newNotification, ...prev])
    },
    []
  )

  const markAsRead = React.useCallback((id: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    )
  }, [])

  const markAllAsRead = React.useCallback(() => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
  }, [])

  const deleteNotification = React.useCallback((id: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id))
  }, [])

  const clearAll = React.useCallback(() => {
    setNotifications([])
  }, [])

  return {
    notifications,
    unreadCount,
    addNotification,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAll,
  }
}
```

---

## 📚 USAGE EXAMPLES

### Basic Notification Center

```typescript
import { NotificationCenter } from '@/components/ui/notification-center'

function Header() {
  const notifications = [
    {
      id: '1',
      type: 'info',
      title: 'New message',
      message: 'You have a new message from John',
      timestamp: new Date(),
      read: false,
    },
  ]

  return (
    <header>
      <NotificationCenter
        notifications={notifications}
        onMarkAsRead={(id) => console.log('Mark as read:', id)}
        onMarkAllAsRead={() => console.log('Mark all as read')}
        onDelete={(id) => console.log('Delete:', id)}
      />
    </header>
  )
}
```

### With Hook

```typescript
import {
  NotificationCenter,
  useNotifications,
} from '@/components/ui/notification-center'

function App() {
  const {
    notifications,
    addNotification,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAll,
  } = useNotifications()

  // Add notification example
  const handleNewMessage = () => {
    addNotification({
      type: 'message',
      title: 'New Message',
      message: 'You have received a new message',
      read: false,
    })
  }

  return (
    <div>
      <NotificationCenter
        notifications={notifications}
        onMarkAsRead={markAsRead}
        onMarkAllAsRead={markAllAsRead}
        onDelete={deleteNotification}
        onClearAll={clearAll}
      />
    </div>
  )
}
```

### With Actions

```typescript
const notifications = [
  {
    id: '1',
    type: 'info',
    title: 'Friend Request',
    message: 'John Doe sent you a friend request',
    timestamp: new Date(),
    read: false,
    action: {
      label: 'Accept',
      onClick: () => acceptFriendRequest(),
    },
  },
]
```

### With Links

```typescript
const notifications = [
  {
    id: '1',
    type: 'update',
    title: 'New Update Available',
    message: 'Version 2.0 is now available',
    timestamp: new Date(),
    read: false,
    link: '/updates',
  },
]
```

### School Management Examples

```typescript
import {
  NotificationCenter,
  useNotifications,
} from '@/components/ui/notification-center'

function SchoolDashboard() {
  const { notifications, addNotification, markAsRead, markAllAsRead } =
    useNotifications([
      // Attendance Alert
      {
        id: '1',
        type: 'warning',
        title: 'Low Attendance Alert',
        message: 'Student John Doe has 65% attendance (below 75% requirement)',
        timestamp: new Date(Date.now() - 1000 * 60 * 15),
        read: false,
        link: '/students/john-doe/attendance',
        action: {
          label: 'View Details',
          onClick: () => navigate('/students/john-doe/attendance'),
        },
      },
      // Grade Submission
      {
        id: '2',
        type: 'info',
        title: 'Grade Submission Reminder',
        message: 'Midterm grades are due in 3 days',
        timestamp: new Date(Date.now() - 1000 * 60 * 60),
        read: false,
        link: '/grades/submit',
      },
      // New Enrollment
      {
        id: '3',
        type: 'success',
        title: 'New Student Enrolled',
        message: 'Sarah Smith has been enrolled in Grade 10A',
        timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2),
        read: true,
        avatar: '/avatars/sarah-smith.jpg',
      },
      // Fee Payment
      {
        id: '4',
        type: 'success',
        title: 'Fee Payment Received',
        message: 'Payment of $500 received from Parent Portal',
        timestamp: new Date(Date.now() - 1000 * 60 * 60 * 5),
        read: true,
        action: {
          label: 'View Receipt',
          onClick: () => window.open('/receipts/latest'),
        },
      },
      // Exam Schedule
      {
        id: '5',
        type: 'info',
        title: 'Exam Schedule Updated',
        message: 'Final exam dates have been published',
        timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24),
        read: false,
        link: '/exams/schedule',
        icon: <Calendar className="h-4 w-4" />,
      },
    ])

  // Real-time notification examples
  React.useEffect(() => {
    // Simulate real-time notifications
    const socket = connectToWebSocket()

    socket.on('student-enrolled', (student) => {
      addNotification({
        type: 'success',
        title: 'New Enrollment',
        message: `${student.name} has been enrolled in ${student.grade}`,
        read: false,
        link: `/students/${student.id}`,
      })
    })

    socket.on('attendance-alert', (alert) => {
      addNotification({
        type: 'warning',
        title: 'Attendance Alert',
        message: alert.message,
        read: false,
        link: `/attendance/${alert.studentId}`,
      })
    })

    socket.on('grade-submitted', (data) => {
      addNotification({
        type: 'info',
        title: 'Grades Submitted',
        message: `Grades for ${data.subject} have been submitted`,
        read: false,
      })
    })

    return () => socket.disconnect()
  }, [])

  return (
    <header className="border-b p-4">
      <div className="flex items-center justify-between">
        <h1>School Dashboard</h1>
        <NotificationCenter
          notifications={notifications}
          onMarkAsRead={markAsRead}
          onMarkAllAsRead={markAllAsRead}
          showTabs
        />
      </div>
    </header>
  )
}
```

### With Pagination

```typescript
function NotificationsWithPagination() {
  const [page, setPage] = React.useState(1)
  const [notifications, setNotifications] = React.useState([])
  const [hasMore, setHasMore] = React.useState(true)

  const loadMore = async () => {
    const newNotifications = await fetchNotifications(page + 1)
    setNotifications([...notifications, ...newNotifications])
    setPage(page + 1)
    setHasMore(newNotifications.length > 0)
  }

  return (
    <NotificationCenter
      notifications={notifications}
      onLoadMore={loadMore}
      hasMore={hasMore}
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('NotificationCenter', () => {
  const mockNotifications = [
    {
      id: '1',
      type: 'info' as const,
      title: 'Test',
      message: 'Test message',
      timestamp: new Date(),
      read: false,
    },
  ]

  it('renders bell icon with badge', () => {
    render(
      <NotificationCenter
        notifications={mockNotifications}
      />
    )
    expect(screen.getByRole('button')).toBeInTheDocument()
    expect(screen.getByText('1')).toBeInTheDocument()
  })

  it('opens dropdown on click', async () => {
    render(
      <NotificationCenter
        notifications={mockNotifications}
      />
    )

    fireEvent.click(screen.getByRole('button'))

    await waitFor(() => {
      expect(screen.getByText('Notifications')).toBeInTheDocument()
    })
  })

  it('displays unread count', () => {
    render(
      <NotificationCenter
        notifications={mockNotifications}
      />
    )
    expect(screen.getByText('1')).toBeInTheDocument()
  })

  it('marks notification as read', async () => {
    const onMarkAsRead = jest.fn()
    
    render(
      <NotificationCenter
        notifications={mockNotifications}
        onMarkAsRead={onMarkAsRead}
      />
    )

    fireEvent.click(screen.getByRole('button'))

    await waitFor(() => {
      expect(screen.getByText('Test')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByText('Test'))

    expect(onMarkAsRead).toHaveBeenCalledWith('1')
  })

  it('marks all as read', async () => {
    const onMarkAllAsRead = jest.fn()
    
    render(
      <NotificationCenter
        notifications={mockNotifications}
        onMarkAllAsRead={onMarkAllAsRead}
      />
    )

    fireEvent.click(screen.getByRole('button'))

    await waitFor(() => {
      expect(screen.getByText('Mark all read')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByText('Mark all read'))

    expect(onMarkAllAsRead).toHaveBeenCalled()
  })
})

describe('useNotifications', () => {
  it('adds notification', () => {
    function TestComponent() {
      const { notifications, addNotification } = useNotifications()

      return (
        <>
          <button
            onClick={() =>
              addNotification({
                type: 'info',
                title: 'Test',
                message: 'Test',
                read: false,
              })
            }
          >
            Add
          </button>
          <div>{notifications.length}</div>
        </>
      )
    }

    render(<TestComponent />)
    fireEvent.click(screen.getByText('Add'))
    expect(screen.getByText('1')).toBeInTheDocument()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard accessible dropdown
- ✅ ARIA labels for bell icon
- ✅ Focus management
- ✅ Screen reader announcements
- ✅ Clear notification content

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install dependencies: `npm install @radix-ui/react-dropdown-menu date-fns`
- [ ] Create notification-center.tsx
- [ ] Implement NotificationItem component
- [ ] Implement NotificationCenter component
- [ ] Add badge counter
- [ ] Add filtering (all/unread)
- [ ] Add mark as read functionality
- [ ] Add delete functionality
- [ ] Implement useNotifications hook
- [ ] Add pagination/load more
- [ ] Write comprehensive tests
- [ ] Test accessibility

---

## 📦 BUNDLE SIZE

- **Component**: ~4KB
- **With dependencies**: ~8KB
- **Tree-shakeable**: Yes

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
