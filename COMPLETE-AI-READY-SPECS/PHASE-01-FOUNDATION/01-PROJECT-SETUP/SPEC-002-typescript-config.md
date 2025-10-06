# SPEC-002: TypeScript Configuration

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-002  
**Title**: TypeScript Configuration (Strict Mode)  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 20 minutes  

---

## 📋 DESCRIPTION

Configure TypeScript with strict mode settings optimized for a large-scale multi-tenant SaaS application. This includes proper type checking, path mapping, and integration with Next.js 15.

## 🎯 SUCCESS CRITERIA

- [ ] TypeScript configured in strict mode
- [ ] Path mapping set up for clean imports
- [ ] Next.js integration optimized
- [ ] Type checking passes without errors
- [ ] IDE support fully functional
- [ ] Build process includes type checking
- [ ] All modern TypeScript features enabled

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. TypeScript Configuration

**File**: `tsconfig.json`
```json
{
  "compilerOptions": {
    // Target and Module
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "es6", "ES2022"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,

    // Strict Type Checking
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,

    // Additional Checks
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noPropertyAccessFromIndexSignature": false,
    "noImplicitThis": true,
    "alwaysStrict": true,

    // Path Mapping
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/hooks/*": ["./src/hooks/*"],
      "@/types/*": ["./src/types/*"],
      "@/context/*": ["./src/context/*"],
      "@/constants/*": ["./src/constants/*"],
      "@/utils/*": ["./src/lib/*"],
      "@/api/*": ["./src/app/api/*"],
      "@/styles/*": ["./src/styles/*"]
    },

    // Next.js specific
    "plugins": [
      {
        "name": "next"
      }
    ],
    "forceConsistentCasingInFileNames": true
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": [
    "node_modules",
    ".next",
    "out",
    "dist",
    "build"
  ]
}
```

### 2. Next.js TypeScript Declaration

**File**: `next-env.d.ts`
```typescript
/// <reference types="next" />
/// <reference types="next/image-types/global" />

// NOTE: This file should not be edited
// see https://nextjs.org/docs/basic-features/typescript for more information.
```

### 3. Global Type Definitions

**File**: `src/types/index.ts`
```typescript
// Global type definitions for the application

// User and Authentication Types
export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  tenantId: string;
  branchId?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export enum UserRole {
  SUPER_ADMIN = 'super_admin',
  TENANT_ADMIN = 'tenant_admin',
  BRANCH_ADMIN = 'branch_admin',
  TEACHER = 'teacher',
  STUDENT = 'student',
  PARENT = 'parent',
  STAFF = 'staff',
}

// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Database Types
export interface BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

// Multi-tenant Types
export interface Tenant extends BaseEntity {
  name: string;
  subdomain: string;
  isActive: boolean;
  plan: TenantPlan;
}

export enum TenantPlan {
  FREE = 'free',
  BASIC = 'basic',
  PREMIUM = 'premium',
  ENTERPRISE = 'enterprise',
}

// Component Props Types
export interface ComponentWithChildren {
  children: React.ReactNode;
}

export interface ComponentWithClassName {
  className?: string;
}

// Form Types
export interface FormState {
  isLoading: boolean;
  errors: Record<string, string>;
  success: boolean;
}

// Utility Types
export type Without<T, U> = { [P in Exclude<keyof T, keyof U>]?: never };
export type XOR<T, U> = T | U extends object 
  ? (Without<T, U> & U) | (Without<U, T> & T) 
  : T | U;

// Environment Variables
export interface EnvVars {
  NEXT_PUBLIC_APP_URL: string;
  NEXT_PUBLIC_SUPABASE_URL: string;
  NEXT_PUBLIC_SUPABASE_ANON_KEY: string;
  DATABASE_URL: string;
  JWT_SECRET: string;
}

declare global {
  namespace NodeJS {
    interface ProcessEnv extends EnvVars {}
  }
}
```

### 4. API Types

**File**: `src/types/api.ts`
```typescript
import { NextRequest, NextResponse } from 'next/server';

// API Handler Types
export type ApiHandler = (
  request: NextRequest,
  context?: { params: Record<string, string> }
) => Promise<NextResponse>;

export interface ApiError {
  message: string;
  statusCode: number;
  code?: string;
}

export interface ApiSuccess<T = any> {
  data: T;
  message?: string;
  statusCode?: number;
}

// Request/Response Types
export interface CreateUserRequest {
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  tenantId: string;
  branchId?: string;
}

export interface UpdateUserRequest {
  firstName?: string;
  lastName?: string;
  isActive?: boolean;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  token: string;
  refreshToken: string;
}

// Pagination Types
export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  search?: string;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}
```

### 5. Component Types

**File**: `src/types/components.ts`
```typescript
import { LucideIcon } from 'lucide-react';
import { ButtonHTMLAttributes, InputHTMLAttributes } from 'react';

// Button Component Types
export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: LucideIcon;
  rightIcon?: LucideIcon;
}

// Input Component Types
export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: LucideIcon;
  rightIcon?: LucideIcon;
}

// Modal Component Types
export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showCloseButton?: boolean;
}

// Table Component Types
export interface TableColumn<T = any> {
  key: keyof T | string;
  label: string;
  sortable?: boolean;
  render?: (value: any, record: T) => React.ReactNode;
  width?: string | number;
}

export interface TableProps<T = any> {
  columns: TableColumn<T>[];
  data: T[];
  loading?: boolean;
  pagination?: PaginationMeta;
  onPageChange?: (page: number) => void;
  onSort?: (column: string, direction: 'asc' | 'desc') => void;
}

// Form Component Types
export interface FormFieldProps {
  name: string;
  label?: string;
  required?: boolean;
  error?: string;
  helperText?: string;
}

export interface SelectOption {
  value: string | number;
  label: string;
  disabled?: boolean;
}

export interface SelectProps extends FormFieldProps {
  options: SelectOption[];
  placeholder?: string;
  isMulti?: boolean;
  isSearchable?: boolean;
}
```

### 6. Package.json Scripts Update

**File**: `package.json` (add these scripts)
```json
{
  "scripts": {
    "type-check": "tsc --noEmit",
    "type-check:watch": "tsc --noEmit --watch",
    "lint:types": "tsc --noEmit && next lint",
    "build:types": "tsc --project tsconfig.build.json"
  }
}
```

### 7. TypeScript Build Configuration

**File**: `tsconfig.build.json`
```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noEmit": false,
    "declaration": true,
    "outDir": "./dist"
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "src/**/*.test.ts",
    "src/**/*.test.tsx",
    "src/**/*.spec.ts",
    "src/**/*.spec.tsx",
    "**/*.stories.ts",
    "**/*.stories.tsx"
  ]
}
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Type Checking Test
```bash
# Run TypeScript compiler check
npm run type-check

# Verify no type errors
# Verify all imports resolve correctly
# Verify path mapping works
```

### 2. Build Test
```bash
# Test production build with type checking
npm run build

# Verify build includes type checking
# Verify no type errors in build
```

### 3. IDE Integration Test
```bash
# Open VSCode
# Verify IntelliSense works
# Verify auto-imports work
# Verify path mapping in IDE
# Verify error highlighting
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] TypeScript strict mode enabled
- [x] All strict type checking options enabled
- [x] Path mapping configured for clean imports
- [x] Type definitions created for common types
- [x] Type checking passes without errors
- [x] Build process includes type checking
- [x] IDE integration fully functional

### Should Have
- [x] Global type definitions created
- [x] API types defined
- [x] Component types defined
- [x] Utility types created
- [x] Environment variables typed
- [x] Build configuration optimized

### Could Have
- [x] Additional type checking scripts
- [x] Separate build configuration
- [x] Advanced utility types
- [x] Comprehensive type coverage

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-001 (Next.js Initialization)  
**Depends On**: Next.js 15 project setup  
**Blocks**: SPEC-003 (Tailwind CSS Setup)  

---

## 📝 IMPLEMENTATION NOTES

### Key Configuration Decisions
1. **Strict Mode**: All strict type checking options enabled
2. **Path Mapping**: Comprehensive path aliases for clean imports
3. **Target**: ES2022 for modern JavaScript features
4. **Module Resolution**: Bundler resolution for Next.js compatibility
5. **Type Definitions**: Comprehensive type system from the start

### TypeScript Features Enabled
- Strict null checks
- No implicit any
- Exact optional property types
- No unchecked indexed access
- Unused locals/parameters detection
- Consistent casing enforcement

### Common Issues & Solutions
1. **Import errors**: Check path mapping in tsconfig.json
2. **Strict null checks**: Use proper null checking patterns
3. **Type errors**: Use explicit type assertions when needed
4. **Build errors**: Verify all dependencies have types

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-003 (Tailwind CSS + shadcn/ui Setup)
2. ✅ Verify all type checking passes
3. ✅ Test IDE integration
4. ✅ Update project documentation

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-003-tailwind-shadcn-setup.md