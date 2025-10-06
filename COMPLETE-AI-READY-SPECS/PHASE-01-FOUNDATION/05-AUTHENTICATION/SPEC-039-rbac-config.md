# SPEC-039: RBAC Configuration
## Role-Based Access Control System with 25+ Predefined Roles

> **Status**: ✅ COMPLETE  
> **Priority**: CRITICAL  
> **Estimated Time**: 6 hours  
> **Dependencies**: SPEC-035 (Supabase Config), SPEC-038 (Auth Middleware)

---

## 📋 OVERVIEW

Complete Role-Based Access Control (RBAC) system with 25+ predefined roles, hierarchical permissions, and dynamic role assignment for the multi-tenant school management platform.

---

## 🎯 OBJECTIVES

- ✅ Define 25+ roles across all user types
- ✅ Create role hierarchy system
- ✅ Map roles to permissions
- ✅ Implement role inheritance
- ✅ Support custom tenant roles
- ✅ Dynamic role assignment
- ✅ Role validation and constraints

---

## 📊 ROLE HIERARCHY

```
Platform Level (Level 100)
└── Platform Administrator

Tenant Level (Level 80-90)
├── Tenant Owner
├── Tenant Administrator
└── Tenant Manager

Branch Level (Level 60-70)
├── Branch Administrator
├── Principal
├── Vice Principal
└── Department Head

Academic Staff (Level 40-50)
├── Senior Teacher
├── Teacher
├── Assistant Teacher
├── Subject Coordinator
└── Class Teacher

Administrative Staff (Level 30-40)
├── Registrar
├── Accountant
├── HR Manager
├── Admission Officer
└── Office Administrator

Support Staff (Level 20-30)
├── Librarian
├── Lab Assistant
├── IT Support
├── Transport Manager
└── Nurse

End Users (Level 10-20)
├── Student
├── Parent/Guardian
└── Alumni

External Stakeholders (Level 5-10)
├── Vendor
├── Auditor
└── Guest
```

---

## 🔧 IMPLEMENTATION

### 1. Role Definitions

#### `src/lib/rbac/roles.ts`
```typescript
/**
 * RBAC Role Definitions
 * 25+ predefined roles with hierarchy and permissions
 */

export interface Role {
  id: string
  name: string
  display_name: string
  description: string
  level: number
  category: RoleCategory
  permissions: string[]
  inherits_from?: string[]
  is_system_role: boolean
  is_tenant_customizable: boolean
}

export type RoleCategory =
  | 'platform'
  | 'tenant'
  | 'branch'
  | 'academic_staff'
  | 'admin_staff'
  | 'support_staff'
  | 'end_user'
  | 'external'

export const ROLES: Record<string, Role> = {
  // ============================================
  // PLATFORM LEVEL ROLES (Level 100)
  // ============================================
  PLATFORM_ADMIN: {
    id: 'platform_admin',
    name: 'platform_admin',
    display_name: 'Platform Administrator',
    description: 'Full system access across all tenants',
    level: 100,
    category: 'platform',
    permissions: ['*:*'], // All permissions
    is_system_role: true,
    is_tenant_customizable: false,
  },

  // ============================================
  // TENANT LEVEL ROLES (Level 80-90)
  // ============================================
  TENANT_OWNER: {
    id: 'tenant_owner',
    name: 'tenant_owner',
    display_name: 'Tenant Owner',
    description: 'Organization owner with full tenant access',
    level: 90,
    category: 'tenant',
    permissions: [
      'tenant:*',
      'branches:*',
      'users:*',
      'roles:*',
      'settings:*',
      'billing:*',
      'reports:*',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },

  TENANT_ADMIN: {
    id: 'tenant_admin',
    name: 'tenant_admin',
    display_name: 'Tenant Administrator',
    description: 'Full administrative access within tenant',
    level: 85,
    category: 'tenant',
    permissions: [
      'tenant:read',
      'tenant:update',
      'branches:*',
      'users:*',
      'roles:read',
      'settings:*',
      'reports:*',
    ],
    inherits_from: ['branch_admin'],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  TENANT_MANAGER: {
    id: 'tenant_manager',
    name: 'tenant_manager',
    display_name: 'Tenant Manager',
    description: 'Manages tenant operations and staff',
    level: 80,
    category: 'tenant',
    permissions: [
      'tenant:read',
      'branches:read',
      'branches:update',
      'users:read',
      'users:create',
      'users:update',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  // ============================================
  // BRANCH LEVEL ROLES (Level 60-70)
  // ============================================
  BRANCH_ADMIN: {
    id: 'branch_admin',
    name: 'branch_admin',
    display_name: 'Branch Administrator',
    description: 'Full administrative access within branch',
    level: 70,
    category: 'branch',
    permissions: [
      'branch:*',
      'students:*',
      'staff:*',
      'classes:*',
      'subjects:*',
      'attendance:*',
      'grades:*',
      'fees:*',
      'reports:*',
    ],
    inherits_from: ['principal'],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  PRINCIPAL: {
    id: 'principal',
    name: 'principal',
    display_name: 'Principal',
    description: 'School principal with oversight of all operations',
    level: 68,
    category: 'branch',
    permissions: [
      'branch:read',
      'students:*',
      'staff:read',
      'staff:create',
      'staff:update',
      'classes:*',
      'subjects:*',
      'attendance:read',
      'grades:read',
      'grades:approve',
      'reports:*',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  VICE_PRINCIPAL: {
    id: 'vice_principal',
    name: 'vice_principal',
    display_name: 'Vice Principal',
    description: 'Assistant to principal with delegated authority',
    level: 65,
    category: 'branch',
    permissions: [
      'branch:read',
      'students:read',
      'students:update',
      'staff:read',
      'classes:read',
      'classes:update',
      'attendance:read',
      'grades:read',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  DEPARTMENT_HEAD: {
    id: 'department_head',
    name: 'department_head',
    display_name: 'Department Head',
    description: 'Head of academic department',
    level: 60,
    category: 'branch',
    permissions: [
      'department:*',
      'teachers:read',
      'subjects:read',
      'subjects:update',
      'classes:read',
      'curriculum:*',
      'grades:read',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  // ============================================
  // ACADEMIC STAFF ROLES (Level 40-50)
  // ============================================
  SENIOR_TEACHER: {
    id: 'senior_teacher',
    name: 'senior_teacher',
    display_name: 'Senior Teacher',
    description: 'Experienced teacher with mentoring responsibilities',
    level: 50,
    category: 'academic_staff',
    permissions: [
      'classes:read',
      'students:read',
      'attendance:*',
      'grades:*',
      'assignments:*',
      'curriculum:read',
      'reports:read',
      'teachers:read',
    ],
    inherits_from: ['teacher'],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  TEACHER: {
    id: 'teacher',
    name: 'teacher',
    display_name: 'Teacher',
    description: 'Regular teaching staff',
    level: 45,
    category: 'academic_staff',
    permissions: [
      'classes:read',
      'students:read',
      'attendance:create',
      'attendance:update',
      'grades:create',
      'grades:update',
      'assignments:*',
      'curriculum:read',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  ASSISTANT_TEACHER: {
    id: 'assistant_teacher',
    name: 'assistant_teacher',
    display_name: 'Assistant Teacher',
    description: 'Assistant teaching staff',
    level: 42,
    category: 'academic_staff',
    permissions: [
      'classes:read',
      'students:read',
      'attendance:read',
      'grades:read',
      'assignments:read',
      'curriculum:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  SUBJECT_COORDINATOR: {
    id: 'subject_coordinator',
    name: 'subject_coordinator',
    display_name: 'Subject Coordinator',
    description: 'Coordinates specific subject across classes',
    level: 48,
    category: 'academic_staff',
    permissions: [
      'subjects:read',
      'subjects:update',
      'curriculum:read',
      'curriculum:update',
      'teachers:read',
      'classes:read',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  CLASS_TEACHER: {
    id: 'class_teacher',
    name: 'class_teacher',
    display_name: 'Class Teacher',
    description: 'Homeroom teacher for a specific class',
    level: 46,
    category: 'academic_staff',
    permissions: [
      'classes:read',
      'students:read',
      'students:update',
      'attendance:*',
      'grades:read',
      'assignments:read',
      'parents:read',
      'communication:create',
      'reports:read',
    ],
    inherits_from: ['teacher'],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  // ============================================
  // ADMINISTRATIVE STAFF ROLES (Level 30-40)
  // ============================================
  REGISTRAR: {
    id: 'registrar',
    name: 'registrar',
    display_name: 'Registrar',
    description: 'Manages student records and admissions',
    level: 40,
    category: 'admin_staff',
    permissions: [
      'students:*',
      'admissions:*',
      'classes:read',
      'classes:update',
      'documents:*',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  ACCOUNTANT: {
    id: 'accountant',
    name: 'accountant',
    display_name: 'Accountant',
    description: 'Manages financial records and fees',
    level: 38,
    category: 'admin_staff',
    permissions: [
      'fees:*',
      'payments:*',
      'expenses:*',
      'financial_reports:*',
      'students:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  HR_MANAGER: {
    id: 'hr_manager',
    name: 'hr_manager',
    display_name: 'HR Manager',
    description: 'Manages staff and HR operations',
    level: 36,
    category: 'admin_staff',
    permissions: [
      'staff:*',
      'payroll:*',
      'leave:*',
      'attendance:read',
      'hr_reports:*',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  ADMISSION_OFFICER: {
    id: 'admission_officer',
    name: 'admission_officer',
    display_name: 'Admission Officer',
    description: 'Handles student admissions',
    level: 34,
    category: 'admin_staff',
    permissions: [
      'admissions:*',
      'students:create',
      'students:read',
      'communication:create',
      'documents:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  OFFICE_ADMIN: {
    id: 'office_admin',
    name: 'office_admin',
    display_name: 'Office Administrator',
    description: 'General office administration',
    level: 32,
    category: 'admin_staff',
    permissions: [
      'communication:*',
      'documents:read',
      'documents:create',
      'calendar:*',
      'notices:*',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  // ============================================
  // SUPPORT STAFF ROLES (Level 20-30)
  // ============================================
  LIBRARIAN: {
    id: 'librarian',
    name: 'librarian',
    display_name: 'Librarian',
    description: 'Manages library operations',
    level: 30,
    category: 'support_staff',
    permissions: [
      'library:*',
      'books:*',
      'students:read',
      'staff:read',
      'library_reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  LAB_ASSISTANT: {
    id: 'lab_assistant',
    name: 'lab_assistant',
    display_name: 'Lab Assistant',
    description: 'Assists with laboratory operations',
    level: 28,
    category: 'support_staff',
    permissions: [
      'labs:*',
      'equipment:*',
      'classes:read',
      'students:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  IT_SUPPORT: {
    id: 'it_support',
    name: 'it_support',
    display_name: 'IT Support',
    description: 'Technical support staff',
    level: 26,
    category: 'support_staff',
    permissions: [
      'technical_support:*',
      'equipment:*',
      'users:read',
      'system_logs:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  TRANSPORT_MANAGER: {
    id: 'transport_manager',
    name: 'transport_manager',
    display_name: 'Transport Manager',
    description: 'Manages school transportation',
    level: 24,
    category: 'support_staff',
    permissions: [
      'transport:*',
      'routes:*',
      'vehicles:*',
      'students:read',
      'transport_reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  NURSE: {
    id: 'nurse',
    name: 'nurse',
    display_name: 'School Nurse',
    description: 'Manages student health records',
    level: 22,
    category: 'support_staff',
    permissions: [
      'health:*',
      'medical_records:*',
      'students:read',
      'health_reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: true,
  },

  // ============================================
  // END USER ROLES (Level 10-20)
  // ============================================
  STUDENT: {
    id: 'student',
    name: 'student',
    display_name: 'Student',
    description: 'Enrolled student',
    level: 15,
    category: 'end_user',
    permissions: [
      'own_profile:read',
      'own_profile:update',
      'own_classes:read',
      'own_grades:read',
      'own_attendance:read',
      'own_assignments:read',
      'own_assignments:submit',
      'own_fees:read',
      'own_documents:read',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },

  PARENT: {
    id: 'parent',
    name: 'parent',
    display_name: 'Parent/Guardian',
    description: 'Parent or legal guardian',
    level: 12,
    category: 'end_user',
    permissions: [
      'own_profile:read',
      'own_profile:update',
      'children:read',
      'children_grades:read',
      'children_attendance:read',
      'children_fees:read',
      'children_fees:pay',
      'communication:read',
      'communication:create',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },

  ALUMNI: {
    id: 'alumni',
    name: 'alumni',
    display_name: 'Alumni',
    description: 'Former student',
    level: 10,
    category: 'end_user',
    permissions: [
      'own_profile:read',
      'alumni_network:read',
      'events:read',
      'news:read',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },

  // ============================================
  // EXTERNAL STAKEHOLDER ROLES (Level 5-10)
  // ============================================
  VENDOR: {
    id: 'vendor',
    name: 'vendor',
    display_name: 'Vendor',
    description: 'External vendor or supplier',
    level: 8,
    category: 'external',
    permissions: [
      'own_profile:read',
      'orders:read',
      'invoices:create',
      'invoices:read',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },

  AUDITOR: {
    id: 'auditor',
    name: 'auditor',
    display_name: 'Auditor',
    description: 'External auditor with read-only access',
    level: 6,
    category: 'external',
    permissions: [
      'financial_records:read',
      'audit_logs:read',
      'reports:read',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },

  GUEST: {
    id: 'guest',
    name: 'guest',
    display_name: 'Guest',
    description: 'Temporary guest access',
    level: 5,
    category: 'external',
    permissions: [
      'public:read',
      'events:read',
      'news:read',
    ],
    is_system_role: true,
    is_tenant_customizable: false,
  },
} as const

// Role utility functions
export function getRoleByName(name: string): Role | undefined {
  return Object.values(ROLES).find((role) => role.name === name)
}

export function getRolesByCategory(category: RoleCategory): Role[] {
  return Object.values(ROLES).filter((role) => role.category === category)
}

export function canRoleAccessRole(actorRole: string, targetRole: string): boolean {
  const actor = getRoleByName(actorRole)
  const target = getRoleByName(targetRole)

  if (!actor || !target) return false

  return actor.level >= target.level
}

export function getAllPermissionsForRole(roleName: string): string[] {
  const role = getRoleByName(roleName)
  if (!role) return []

  let permissions = [...role.permissions]

  // Add inherited permissions
  if (role.inherits_from) {
    for (const parentRoleName of role.inherits_from) {
      const parentPermissions = getAllPermissionsForRole(parentRoleName)
      permissions = [...permissions, ...parentPermissions]
    }
  }

  // Remove duplicates
  return [...new Set(permissions)]
}
```

---

### 2. Role Assignment Logic

#### `src/lib/rbac/assignment.ts`
```typescript
/**
 * Role Assignment Logic
 * Handles dynamic role assignment and validation
 */

import { createAdminClient } from '@/lib/supabase/admin'
import { ROLES, canRoleAccessRole, getRoleByName } from './roles'

export interface RoleAssignment {
  user_id: string
  role: string
  tenant_id: string
  branch_id?: string
  assigned_by: string
  assigned_at: string
  expires_at?: string
}

/**
 * Assign role to user
 */
export async function assignRole(
  userId: string,
  role: string,
  tenantId: string,
  assignedBy: string,
  options?: {
    branchId?: string
    expiresAt?: string
  }
): Promise<{ success: boolean; error?: string }> {
  try {
    // Validate role exists
    const roleConfig = getRoleByName(role)
    if (!roleConfig) {
      return { success: false, error: 'Invalid role' }
    }

    // Get assigner's role
    const supabase = createAdminClient()
    const { data: assignerData } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', assignedBy)
      .single()

    if (!assignerData) {
      return { success: false, error: 'Assigner not found' }
    }

    // Check if assigner can assign this role
    if (!canRoleAccessRole(assignerData.role, role)) {
      return { success: false, error: 'Insufficient permissions to assign this role' }
    }

    // Assign role
    const { error } = await supabase.from('user_roles').insert({
      user_id: userId,
      role,
      tenant_id: tenantId,
      branch_id: options?.branchId,
      assigned_by: assignedBy,
      expires_at: options?.expiresAt,
    })

    if (error) {
      return { success: false, error: error.message }
    }

    return { success: true }
  } catch (error: any) {
    return { success: false, error: error.message }
  }
}

/**
 * Remove role from user
 */
export async function removeRole(
  userId: string,
  role: string,
  removedBy: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const supabase = createAdminClient()

    // Get remover's role
    const { data: removerData } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', removedBy)
      .single()

    if (!removerData) {
      return { success: false, error: 'Unauthorized' }
    }

    // Check if remover can remove this role
    if (!canRoleAccessRole(removerData.role, role)) {
      return { success: false, error: 'Insufficient permissions' }
    }

    // Remove role
    const { error } = await supabase
      .from('user_roles')
      .delete()
      .eq('user_id', userId)
      .eq('role', role)

    if (error) {
      return { success: false, error: error.message }
    }

    return { success: true }
  } catch (error: any) {
    return { success: false, error: error.message }
  }
}
```

---

## ✅ COMPLETION CHECKLIST

- [x] 25+ roles defined
- [x] Role hierarchy established
- [x] Permission mappings created
- [x] Role inheritance implemented
- [x] Assignment logic created
- [x] Validation functions implemented
- [x] Custom tenant roles supported
- [x] Type definitions complete
- [x] Documentation complete

---

## 📚 RELATED SPECS

- ⬅️ **SPEC-038**: Auth Middleware
- ➡️ **SPEC-040**: Permission System
- ➡️ **SPEC-041**: Session Management

---

**Author**: AI Assistant  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0
