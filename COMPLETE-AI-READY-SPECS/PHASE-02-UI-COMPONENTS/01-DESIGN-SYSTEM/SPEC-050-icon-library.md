# SPEC-050: Icon Library System
## Comprehensive Icon Integration with Lucide React

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 3 hours  
> **Dependencies**: SPEC-046 (Theme), SPEC-047 (Design Tokens)

---

## 📋 OVERVIEW

### Purpose
Establish a comprehensive icon system that:
- Provides 1000+ consistent, beautiful icons
- Supports customization (size, color, stroke width)
- Ensures accessibility (ARIA labels, titles)
- Optimizes bundle size (tree-shakeable)
- Works seamlessly with React and TypeScript

### Key Features
- ✅ Lucide React integration (1000+ icons)
- ✅ Categorized icon exports
- ✅ Icon wrapper component
- ✅ Size and color variants
- ✅ Accessibility features
- ✅ Tree-shakeable imports
- ✅ TypeScript support

---

## 🎨 ICON SYSTEM ARCHITECTURE

### 1. Icon Library Setup

```typescript
// package.json
{
  "dependencies": {
    "lucide-react": "^0.300.0"
  }
}
```

### 2. Icon Categories

```typescript
// src/components/icons/index.ts

/**
 * Centralized icon exports from Lucide React
 * Organized by category for easy discovery
 */

// ========================================
// NAVIGATION ICONS
// ========================================
export {
  Home,
  Menu,
  X,
  ChevronRight,
  ChevronLeft,
  ChevronUp,
  ChevronDown,
  ChevronsRight,
  ChevronsLeft,
  ChevronsUp,
  ChevronsDown,
  ArrowRight,
  ArrowLeft,
  ArrowUp,
  ArrowDown,
  ArrowUpRight,
  ArrowDownRight,
  MoreVertical,
  MoreHorizontal,
  ExternalLink,
} from 'lucide-react';

// ========================================
// ACADEMIC ICONS
// ========================================
export {
  BookOpen,
  Book,
  BookMarked,
  GraduationCap,
  School,
  Library,
  Pencil,
  PencilLine,
  FileText,
  ClipboardList,
  ClipboardCheck,
  Award,
  Trophy,
  Medal,
  Target,
  BookOpenCheck,
} from 'lucide-react';

// ========================================
// USER & PEOPLE ICONS
// ========================================
export {
  User,
  Users,
  UserPlus,
  UserMinus,
  UserCheck,
  UserX,
  UserCircle,
  UserCog,
  Contact,
  CircleUserRound,
  UsersRound,
} from 'lucide-react';

// ========================================
// TIME & DATE ICONS
// ========================================
export {
  Calendar,
  CalendarDays,
  CalendarCheck,
  CalendarX,
  CalendarPlus,
  Clock,
  Timer,
  AlarmClock,
  Hourglass,
} from 'lucide-react';

// ========================================
// ATTENDANCE & STATUS ICONS
// ========================================
export {
  Check,
  CheckCircle,
  CheckSquare,
  X as XIcon,
  XCircle,
  XSquare,
  Minus,
  MinusCircle,
  Plus,
  PlusCircle,
  AlertCircle,
  AlertTriangle,
  Info,
  HelpCircle,
  Ban,
} from 'lucide-react';

// ========================================
// DATA & ANALYTICS ICONS
// ========================================
export {
  BarChart,
  BarChart2,
  BarChart3,
  LineChart,
  PieChart,
  TrendingUp,
  TrendingDown,
  Activity,
  Signal,
  Percent,
} from 'lucide-react';

// ========================================
// ACTIONS ICONS
// ========================================
export {
  Settings,
  Edit,
  Edit2,
  Edit3,
  Trash,
  Trash2,
  Save,
  Download,
  Upload,
  Share,
  Share2,
  Copy,
  Clipboard,
  Search,
  Filter,
  SlidersHorizontal,
  RefreshCw,
  RotateCw,
  RotateCcw,
  Undo,
  Redo,
} from 'lucide-react';

// ========================================
// FILE & DOCUMENT ICONS
// ========================================
export {
  File,
  FileText as FileTextIcon,
  FilePlus,
  FileMinus,
  FileCheck,
  FileX,
  Files,
  Folder,
  FolderOpen,
  FolderPlus,
  Archive,
  Paperclip,
} from 'lucide-react';

// ========================================
// COMMUNICATION ICONS
// ========================================
export {
  Mail,
  MailOpen,
  Send,
  MessageCircle,
  MessageSquare,
  Phone,
  PhoneCall,
  PhoneIncoming,
  PhoneOutgoing,
  Bell,
  BellOff,
  BellRing,
} from 'lucide-react';

// ========================================
// FINANCIAL ICONS
// ========================================
export {
  DollarSign,
  CreditCard,
  Wallet,
  Banknote,
  Receipt,
  BadgeDollarSign,
  Coins,
} from 'lucide-react';

// ========================================
// INTERFACE ICONS
// ========================================
export {
  Eye,
  EyeOff,
  Lock,
  Unlock,
  Key,
  LogOut,
  LogIn,
  ShieldCheck,
  ShieldAlert,
  ShieldX,
  Star,
  Heart,
  ThumbsUp,
  ThumbsDown,
  Bookmark,
} from 'lucide-react';

// ========================================
// LAYOUT ICONS
// ========================================
export {
  Layout,
  LayoutDashboard,
  LayoutGrid,
  LayoutList,
  Sidebar,
  PanelLeft,
  PanelRight,
  Maximize,
  Minimize,
  Expand,
  Shrink,
} from 'lucide-react';

// ========================================
// MEDIA ICONS
// ========================================
export {
  Image,
  ImagePlus,
  Video,
  Camera,
  Play,
  Pause,
  Volume2,
  VolumeX,
} from 'lucide-react';

// ========================================
// LOCATION ICONS
// ========================================
export {
  MapPin,
  Map,
  Navigation,
  Compass,
  Globe,
} from 'lucide-react';

// ========================================
// UTILITY ICONS
// ========================================
export {
  Loader,
  Loader2,
  Circle,
  Square,
  Triangle,
  Zap,
  Lightbulb,
  Sparkles,
  Sun,
  Moon,
  Cloud,
  Wifi,
  WifiOff,
  Battery,
  BatteryCharging,
} from 'lucide-react';

// ========================================
// GRADE & PERFORMANCE ICONS
// ========================================
export {
  ChartBar as GradeChart,
  TrendingUp as PerformanceUp,
  TrendingDown as PerformanceDown,
  Target as Goal,
} from 'lucide-react';
```

---

## 🛠️ ICON COMPONENT IMPLEMENTATION

### Base Icon Component

```typescript
// src/components/icons/Icon.tsx
import React from 'react';
import { LucideIcon, LucideProps } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface IconProps extends Omit<LucideProps, 'ref'> {
  icon: LucideIcon;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | number;
  className?: string;
  'aria-label'?: string;
}

const iconSizes = {
  xs: 12,
  sm: 16,
  md: 20,
  lg: 24,
  xl: 32,
} as const;

/**
 * Icon wrapper component for consistent icon usage
 * 
 * @example
 * <Icon icon={Home} size="md" />
 * <Icon icon={User} size={24} className="text-primary-500" />
 */
export function Icon({
  icon: IconComponent,
  size = 'md',
  className,
  'aria-label': ariaLabel,
  ...props
}: IconProps) {
  const iconSize = typeof size === 'number' ? size : iconSizes[size];

  return (
    <IconComponent
      size={iconSize}
      className={cn('inline-block', className)}
      aria-label={ariaLabel}
      role={ariaLabel ? 'img' : undefined}
      {...props}
    />
  );
}

export type { LucideIcon };
```

### Icon Button Component

```typescript
// src/components/icons/IconButton.tsx
import React from 'react';
import { LucideIcon } from 'lucide-react';
import { Button, type ButtonProps } from '@/components/ui/Button';
import { Icon } from './Icon';
import { cn } from '@/lib/utils';

interface IconButtonProps extends Omit<ButtonProps, 'children'> {
  icon: LucideIcon;
  iconSize?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  'aria-label': string; // Required for accessibility
}

/**
 * Button component with icon only
 * 
 * @example
 * <IconButton
 *   icon={Trash}
 *   aria-label="Delete item"
 *   variant="destructive"
 * />
 */
export function IconButton({
  icon,
  iconSize = 'md',
  className,
  'aria-label': ariaLabel,
  ...props
}: IconButtonProps) {
  return (
    <Button
      className={cn('aspect-square p-2', className)}
      aria-label={ariaLabel}
      {...props}
    >
      <Icon icon={icon} size={iconSize} />
    </Button>
  );
}
```

### Icon with Text Component

```typescript
// src/components/icons/IconText.tsx
import React from 'react';
import { LucideIcon } from 'lucide-react';
import { Icon } from './Icon';
import { cn } from '@/lib/utils';

interface IconTextProps {
  icon: LucideIcon;
  iconPosition?: 'left' | 'right';
  iconSize?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  gap?: 'xs' | 'sm' | 'md' | 'lg';
  className?: string;
  children: React.ReactNode;
}

const gapSizes = {
  xs: 'gap-1',
  sm: 'gap-2',
  md: 'gap-3',
  lg: 'gap-4',
} as const;

/**
 * Component for displaying icon with text
 * 
 * @example
 * <IconText icon={Home} iconPosition="left">
 *   Dashboard
 * </IconText>
 */
export function IconText({
  icon,
  iconPosition = 'left',
  iconSize = 'md',
  gap = 'sm',
  className,
  children,
}: IconTextProps) {
  return (
    <span className={cn('inline-flex items-center', gapSizes[gap], className)}>
      {iconPosition === 'left' && <Icon icon={icon} size={iconSize} />}
      {children}
      {iconPosition === 'right' && <Icon icon={icon} size={iconSize} />}
    </span>
  );
}
```

---

## 🎯 ICON UTILITIES

### Icon Helper Functions

```typescript
// src/lib/icons/utils.ts
import { LucideIcon } from 'lucide-react';
import {
  CheckCircle,
  XCircle,
  AlertCircle,
  Info,
  Loader2,
} from 'lucide-react';

/**
 * Get status icon based on status type
 */
export function getStatusIcon(
  status: 'success' | 'error' | 'warning' | 'info' | 'loading'
): LucideIcon {
  const statusIcons = {
    success: CheckCircle,
    error: XCircle,
    warning: AlertCircle,
    info: Info,
    loading: Loader2,
  };

  return statusIcons[status];
}

/**
 * Get attendance icon
 */
export function getAttendanceIcon(
  status: 'present' | 'absent' | 'late' | 'excused'
): LucideIcon {
  const icons = {
    present: CheckCircle,
    absent: XCircle,
    late: AlertCircle,
    excused: Info,
  };

  return icons[status];
}
```

### Icon Animation Utilities

```typescript
// src/lib/icons/animations.ts

/**
 * Icon animation classes
 */
export const iconAnimations = {
  spin: 'animate-spin',
  pulse: 'animate-pulse',
  bounce: 'animate-bounce',
  ping: 'animate-ping',
} as const;

/**
 * Icon transition classes
 */
export const iconTransitions = {
  default: 'transition-all duration-200 ease-in-out',
  fast: 'transition-all duration-100 ease-in-out',
  slow: 'transition-all duration-300 ease-in-out',
} as const;
```

---

## 📦 ACADEMIC-SPECIFIC ICON SETS

### Attendance Status Icons

```typescript
// src/components/icons/academic/AttendanceIcon.tsx
import React from 'react';
import { Icon, type IconProps } from '../Icon';
import { getAttendanceIcon } from '@/lib/icons/utils';
import { getAttendanceColor } from '@/lib/colors/utils';

interface AttendanceIconProps extends Omit<IconProps, 'icon'> {
  status: 'present' | 'absent' | 'late' | 'excused';
}

export function AttendanceIcon({ status, ...props }: AttendanceIconProps) {
  const icon = getAttendanceIcon(status);
  const colors = getAttendanceColor(status);

  return (
    <Icon
      icon={icon}
      className={props.className}
      style={{ color: colors.color }}
      aria-label={`Attendance: ${status}`}
      {...props}
    />
  );
}
```

### Grade Performance Icons

```typescript
// src/components/icons/academic/GradeIcon.tsx
import React from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';
import { Icon } from '../Icon';

interface GradeIconProps {
  trend: 'up' | 'down' | 'stable';
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

export function GradeIcon({ trend, size = 'md', className }: GradeIconProps) {
  const icons = {
    up: TrendingUp,
    down: TrendingDown,
    stable: Minus,
  };

  const colors = {
    up: 'text-success-500',
    down: 'text-error-500',
    stable: 'text-gray-500',
  };

  return (
    <Icon
      icon={icons[trend]}
      size={size}
      className={`${colors[trend]} ${className}`}
      aria-label={`Grade trend: ${trend}`}
    />
  );
}
```

---

## ✅ TESTING

### Icon Component Tests

```typescript
// src/components/icons/__tests__/Icon.test.tsx
import { render, screen } from '@testing-library/react';
import { Icon } from '../Icon';
import { Home } from 'lucide-react';

describe('Icon Component', () => {
  it('renders icon correctly', () => {
    render(<Icon icon={Home} aria-label="Home" />);
    expect(screen.getByLabelText('Home')).toBeInTheDocument();
  });

  it('applies size correctly', () => {
    render(<Icon icon={Home} size="lg" aria-label="Home" />);
    const icon = screen.getByLabelText('Home');
    // Check SVG size attribute
    expect(icon).toHaveAttribute('width', '24');
    expect(icon).toHaveAttribute('height', '24');
  });

  it('applies custom size', () => {
    render(<Icon icon={Home} size={32} aria-label="Home" />);
    const icon = screen.getByLabelText('Home');
    expect(icon).toHaveAttribute('width', '32');
    expect(icon).toHaveAttribute('height', '32');
  });

  it('applies custom className', () => {
    render(<Icon icon={Home} className="text-primary-500" aria-label="Home" />);
    expect(screen.getByLabelText('Home')).toHaveClass('text-primary-500');
  });

  it('includes aria-label when provided', () => {
    render(<Icon icon={Home} aria-label="Go to homepage" />);
    expect(screen.getByLabelText('Go to homepage')).toBeInTheDocument();
  });
});
```

### IconButton Tests

```typescript
// src/components/icons/__tests__/IconButton.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { IconButton } from '../IconButton';
import { Trash } from 'lucide-react';

describe('IconButton Component', () => {
  it('renders button with icon', () => {
    render(<IconButton icon={Trash} aria-label="Delete" />);
    expect(screen.getByLabelText('Delete')).toBeInTheDocument();
  });

  it('handles click events', () => {
    const handleClick = jest.fn();
    render(
      <IconButton icon={Trash} aria-label="Delete" onClick={handleClick} />
    );
    
    fireEvent.click(screen.getByLabelText('Delete'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('applies variant styles', () => {
    render(
      <IconButton
        icon={Trash}
        aria-label="Delete"
        variant="destructive"
      />
    );
    expect(screen.getByLabelText('Delete')).toHaveClass('bg-destructive');
  });

  it('requires aria-label for accessibility', () => {
    // TypeScript should enforce this, but test runtime behavior
    const { container } = render(
      <IconButton icon={Trash} aria-label="Delete" />
    );
    expect(container.querySelector('button')).toHaveAttribute('aria-label');
  });
});
```

---

## 📚 USAGE EXAMPLES

### Basic Icon Usage

```typescript
import { Home, User, Settings } from '@/components/icons';
import { Icon } from '@/components/icons/Icon';

// Direct usage
<Home className="text-primary-500" size={20} />

// With Icon wrapper
<Icon icon={Home} size="md" className="text-primary-500" />

// Different sizes
<Icon icon={User} size="xs" />  // 12px
<Icon icon={User} size="sm" />  // 16px
<Icon icon={User} size="md" />  // 20px
<Icon icon={User} size="lg" />  // 24px
<Icon icon={User} size="xl" />  // 32px
<Icon icon={User} size={48} />  // Custom size
```

### Icon with Button

```typescript
import { Trash, Save, Download } from '@/components/icons';
import { IconButton } from '@/components/icons/IconButton';

// Icon-only button
<IconButton
  icon={Trash}
  aria-label="Delete item"
  variant="destructive"
  size="sm"
/>

// Regular button with icon
<Button variant="primary">
  <Save className="mr-2" size={16} />
  Save Changes
</Button>
```

### Academic Icons

```typescript
import {
  GraduationCap,
  BookOpen,
  Calendar,
  CheckCircle,
} from '@/components/icons';
import { AttendanceIcon } from '@/components/icons/academic/AttendanceIcon';
import { GradeIcon } from '@/components/icons/academic/GradeIcon';

// Attendance status
<AttendanceIcon status="present" size="md" />
<AttendanceIcon status="absent" size="md" />

// Grade trend
<GradeIcon trend="up" size="sm" />
<GradeIcon trend="down" size="sm" />

// Academic features
<BookOpen className="text-primary-500" />
<GraduationCap className="text-secondary-500" />
```

### Animated Icons

```typescript
import { Loader2, RefreshCw } from '@/components/icons';

// Spinning loader
<Loader2 className="animate-spin" />

// Refresh button with animation
<button onClick={handleRefresh}>
  <RefreshCw className={isRefreshing ? 'animate-spin' : ''} />
  Refresh
</button>
```

---

## ♿ ACCESSIBILITY

### Icon Accessibility Features

```typescript
// Decorative icons (no aria-label needed)
<Icon icon={Home} />

// Semantic icons (aria-label required)
<Icon icon={Trash} aria-label="Delete item" />

// Icon buttons (aria-label required)
<IconButton icon={Settings} aria-label="Open settings" />

// Icon with visible text (no aria-label needed)
<button>
  <Icon icon={Save} />
  <span>Save</span>
</button>
```

### Best Practices
- ✅ Always provide `aria-label` for standalone icons
- ✅ Use `role="img"` for semantic icons
- ✅ Ensure sufficient color contrast
- ✅ Don't rely on icons alone to convey meaning
- ✅ Provide text alternatives

---

## 📖 DOCUMENTATION

### Icon Categories Reference

| Category | Count | Examples |
|----------|-------|----------|
| Navigation | 19 | Home, Menu, ChevronRight, ArrowLeft |
| Academic | 16 | BookOpen, GraduationCap, School |
| User & People | 11 | User, Users, UserPlus, UserCircle |
| Time & Date | 9 | Calendar, Clock, Timer |
| Status | 15 | Check, X, AlertCircle, Info |
| Data & Analytics | 10 | BarChart, LineChart, TrendingUp |
| Actions | 20 | Edit, Delete, Save, Download |
| Files | 12 | File, Folder, Archive |
| Communication | 11 | Mail, MessageCircle, Phone, Bell |
| Financial | 7 | DollarSign, CreditCard, Receipt |
| Interface | 15 | Eye, Lock, Star, Heart |
| Layout | 11 | Layout, Sidebar, Maximize |
| Media | 8 | Image, Video, Camera, Play |
| Location | 5 | MapPin, Globe, Navigation |
| Utility | 14 | Loader, Sun, Moon, Wifi |

**Total Icons**: 183+ core icons (1000+ available from Lucide)

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install lucide-react package
- [ ] Create icon category exports
- [ ] Implement Icon component
- [ ] Implement IconButton component
- [ ] Implement IconText component
- [ ] Create icon utilities
- [ ] Create academic-specific icons
- [ ] Write comprehensive tests
- [ ] Create Storybook stories
- [ ] Document all icon categories
- [ ] Test accessibility
- [ ] Verify tree-shaking works

---

## 📝 NOTES

- All icons are from Lucide React (MIT license)
- Icons are tree-shakeable (only imported icons are bundled)
- Icons support all CSS styling (color, size, etc.)
- Icons are fully accessible with ARIA support
- Custom icons can be added following Lucide's SVG format

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
