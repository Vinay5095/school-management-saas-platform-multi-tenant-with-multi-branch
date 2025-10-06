# SPEC-120: Platform User Management
## Comprehensive User Administration Across All Tenants

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-116, SPEC-117, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive user management system for super admins to view, search, manage, and monitor all users across all tenants on the platform, including user administration, role management, and access control.

### Key Features
- ✅ View all platform users
- ✅ Advanced search and filtering
- ✅ User details and activity history
- ✅ Manage user roles and permissions
- ✅ Enable/disable user accounts
- ✅ Password reset functionality
- ✅ User impersonation for support
- ✅ Export user data
- ✅ Bulk operations
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- User management view (combines auth.users with profiles)
CREATE OR REPLACE VIEW platform_users_view AS
SELECT
  u.id as user_id,
  u.email,
  u.email_confirmed_at,
  u.phone,
  u.created_at as user_created_at,
  u.updated_at as user_updated_at,
  u.last_sign_in_at,
  u.is_sso_user,
  u.banned_until,
  
  up.id as profile_id,
  up.tenant_id,
  up.first_name,
  up.last_name,
  up.role,
  up.status as profile_status,
  up.avatar_url,
  up.phone_number,
  up.department,
  up.job_title,
  
  t.name as tenant_name,
  t.status as tenant_status,
  t.subscription_tier,
  
  (SELECT COUNT(*) FROM platform_activity_log WHERE actor_id = u.id) as activity_count,
  (SELECT MAX(created_at) FROM platform_activity_log WHERE actor_id = u.id) as last_activity_at
  
FROM auth.users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN tenants t ON t.id = up.tenant_id;

-- User impersonation log
CREATE TABLE user_impersonation_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  super_admin_id UUID NOT NULL REFERENCES auth.users(id),
  impersonated_user_id UUID NOT NULL REFERENCES auth.users(id),
  tenant_id UUID REFERENCES tenants(id),
  reason TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  actions_performed JSONB DEFAULT '[]'::jsonb,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_impersonation_log_admin ON user_impersonation_log(super_admin_id);
CREATE INDEX idx_impersonation_log_user ON user_impersonation_log(impersonated_user_id);
CREATE INDEX idx_impersonation_log_started ON user_impersonation_log(started_at DESC);

-- User bulk operations tracking
CREATE TABLE user_bulk_operations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type TEXT NOT NULL CHECK (operation_type IN (
    'activate', 'deactivate', 'delete', 'role_change', 'export'
  )),
  initiated_by UUID NOT NULL REFERENCES auth.users(id),
  user_ids UUID[] NOT NULL,
  parameters JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_count INTEGER NOT NULL,
  processed_count INTEGER DEFAULT 0,
  success_count INTEGER DEFAULT 0,
  failure_count INTEGER DEFAULT 0,
  error_details JSONB DEFAULT '[]'::jsonb,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_bulk_operations_initiated_by ON user_bulk_operations(initiated_by);
CREATE INDEX idx_bulk_operations_status ON user_bulk_operations(status);
CREATE INDEX idx_bulk_operations_started ON user_bulk_operations(started_at DESC);

-- Function to get user details with stats
CREATE OR REPLACE FUNCTION get_user_details(p_user_id UUID)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  role TEXT,
  tenant_id UUID,
  tenant_name TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  total_logins BIGINT,
  recent_activity JSONB,
  assigned_permissions TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    up.first_name,
    up.last_name,
    up.role,
    up.tenant_id,
    t.name,
    up.status,
    u.created_at,
    u.last_sign_in_at,
    (SELECT COUNT(*) FROM platform_activity_log 
     WHERE actor_id = u.id AND activity_type = 'login') as total_logins,
    (SELECT jsonb_agg(jsonb_build_object(
       'action', action,
       'timestamp', created_at,
       'category', activity_category
     ) ORDER BY created_at DESC)
     FROM platform_activity_log
     WHERE actor_id = u.id
     LIMIT 10) as recent_activity,
    COALESCE(up.permissions, ARRAY[]::TEXT[]) as assigned_permissions
  FROM auth.users u
  LEFT JOIN user_profiles up ON up.user_id = u.id
  LEFT JOIN tenants t ON t.id = up.tenant_id
  WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search users
CREATE OR REPLACE FUNCTION search_platform_users(
  p_search_term TEXT DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_role TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  tenant_name TEXT,
  status TEXT,
  last_sign_in_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pv.user_id,
    pv.email,
    CONCAT(pv.first_name, ' ', pv.last_name) as full_name,
    pv.role,
    pv.tenant_name,
    pv.profile_status,
    pv.last_sign_in_at
  FROM platform_users_view pv
  WHERE
    (p_search_term IS NULL OR 
     pv.email ILIKE '%' || p_search_term || '%' OR
     pv.first_name ILIKE '%' || p_search_term || '%' OR
     pv.last_name ILIKE '%' || p_search_term || '%')
    AND (p_tenant_id IS NULL OR pv.tenant_id = p_tenant_id)
    AND (p_role IS NULL OR pv.role = p_role)
    AND (p_status IS NULL OR pv.profile_status = p_status)
  ORDER BY pv.user_created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to start user impersonation
CREATE OR REPLACE FUNCTION start_impersonation(
  p_super_admin_id UUID,
  p_user_id UUID,
  p_reason TEXT,
  p_ip_address INET DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_impersonation_id UUID;
  v_tenant_id UUID;
BEGIN
  -- Get user's tenant
  SELECT tenant_id INTO v_tenant_id
  FROM user_profiles
  WHERE user_id = p_user_id;

  -- Create impersonation record
  INSERT INTO user_impersonation_log (
    super_admin_id,
    impersonated_user_id,
    tenant_id,
    reason,
    ip_address
  ) VALUES (
    p_super_admin_id,
    p_user_id,
    v_tenant_id,
    p_reason,
    p_ip_address
  ) RETURNING id INTO v_impersonation_id;

  -- Log activity
  PERFORM log_platform_activity(
    p_super_admin_id,
    v_tenant_id,
    'impersonation_started',
    'security',
    'Started impersonating user',
    'user',
    p_user_id,
    (SELECT email FROM auth.users WHERE id = p_user_id),
    'high',
    'success',
    p_ip_address,
    NULL,
    jsonb_build_object('reason', p_reason)
  );

  RETURN v_impersonation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to end user impersonation
CREATE OR REPLACE FUNCTION end_impersonation(
  p_impersonation_id UUID,
  p_actions_performed JSONB DEFAULT '[]'::jsonb
)
RETURNS void AS $$
BEGIN
  UPDATE user_impersonation_log
  SET
    ended_at = NOW(),
    actions_performed = p_actions_performed
  WHERE id = p_impersonation_id;

  -- Log activity
  PERFORM log_platform_activity(
    (SELECT super_admin_id FROM user_impersonation_log WHERE id = p_impersonation_id),
    (SELECT tenant_id FROM user_impersonation_log WHERE id = p_impersonation_id),
    'impersonation_ended',
    'security',
    'Ended user impersonation',
    NULL,
    NULL,
    NULL,
    'high',
    'success',
    NULL,
    NULL,
    jsonb_build_object('actions_count', jsonb_array_length(p_actions_performed))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE user_impersonation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_bulk_operations ENABLE ROW LEVEL SECURITY;

CREATE POLICY super_admin_impersonation_log ON user_impersonation_log
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY super_admin_bulk_operations ON user_bulk_operations
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/platform-user.ts

export interface PlatformUser {
  userId: string
  email: string
  emailConfirmedAt?: string
  phone?: string
  userCreatedAt: string
  userUpdatedAt: string
  lastSignInAt?: string
  isSsoUser: boolean
  bannedUntil?: string
  
  profileId?: string
  tenantId?: string
  firstName?: string
  lastName?: string
  role?: string
  profileStatus?: string
  avatarUrl?: string
  phoneNumber?: string
  department?: string
  jobTitle?: string
  
  tenantName?: string
  tenantStatus?: string
  subscriptionTier?: string
  
  activityCount: number
  lastActivityAt?: string
}

export interface UserDetailsWithStats {
  userId: string
  email: string
  firstName?: string
  lastName?: string
  role?: string
  tenantId?: string
  tenantName?: string
  status: string
  createdAt: string
  lastSignInAt?: string
  totalLogins: number
  recentActivity: Array<{
    action: string
    timestamp: string
    category: string
  }>
  assignedPermissions: string[]
}

export interface ImpersonationSession {
  id: string
  superAdminId: string
  impersonatedUserId: string
  tenantId?: string
  reason: string
  startedAt: string
  endedAt?: string
  actionsPerformed: any[]
  ipAddress?: string
  userAgent?: string
  metadata?: Record<string, any>
}

export interface BulkOperation {
  id: string
  operationType: 'activate' | 'deactivate' | 'delete' | 'role_change' | 'export'
  initiatedBy: string
  userIds: string[]
  parameters?: Record<string, any>
  status: 'pending' | 'processing' | 'completed' | 'failed'
  totalCount: number
  processedCount: number
  successCount: number
  failureCount: number
  errorDetails: any[]
  startedAt: string
  completedAt?: string
  metadata?: Record<string, any>
}

export interface UserFilters {
  search?: string
  tenantId?: string
  role?: string
  status?: string
  page?: number
  pageSize?: number
}
```

### API Routes

```typescript
// src/app/api/platform/users/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Verify super admin
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('user_id', user.id)
    .single()

  if (profile?.role !== 'super_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const search = searchParams.get('search') || undefined
    const tenantId = searchParams.get('tenantId') || undefined
    const role = searchParams.get('role') || undefined
    const status = searchParams.get('status') || undefined
    const page = parseInt(searchParams.get('page') || '1')
    const pageSize = parseInt(searchParams.get('pageSize') || '50')

    const { data: users, error } = await supabase.rpc('search_platform_users', {
      p_search_term: search,
      p_tenant_id: tenantId,
      p_role: role,
      p_status: status,
      p_limit: pageSize,
      p_offset: (page - 1) * pageSize,
    })

    if (error) throw error

    // Get total count
    const { count } = await supabase
      .from('platform_users_view')
      .select('*', { count: 'exact', head: true })

    return NextResponse.json({
      users,
      pagination: {
        page,
        pageSize,
        total: count,
        totalPages: Math.ceil((count || 0) / pageSize),
      },
    })

  } catch (error) {
    console.error('Failed to fetch users:', error)
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/users/[id]/route.ts

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { data: userDetails, error } = await supabase
      .rpc('get_user_details', { p_user_id: params.id })
      .single()

    if (error) throw error

    return NextResponse.json({ user: userDetails })

  } catch (error) {
    console.error('Failed to fetch user details:', error)
    return NextResponse.json(
      { error: 'Failed to fetch user details' },
      { status: 500 }
    )
  }
}

export async function PATCH(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { status, role, permissions } = body

    // Update user profile
    const { data, error } = await supabase
      .from('user_profiles')
      .update({
        status,
        role,
        permissions,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', params.id)
      .select()
      .single()

    if (error) throw error

    // Log activity
    await supabase.rpc('log_platform_activity', {
      p_actor_id: user.id,
      p_tenant_id: data.tenant_id,
      p_activity_type: 'user_updated',
      p_activity_category: 'user_management',
      p_action: 'Updated user profile',
      p_resource_type: 'user',
      p_resource_id: params.id,
      p_severity: 'medium',
      p_status: 'success',
    })

    return NextResponse.json({ user: data })

  } catch (error) {
    console.error('Failed to update user:', error)
    return NextResponse.json(
      { error: 'Failed to update user' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/users/[id]/impersonate/route.ts

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { reason } = body

    if (!reason) {
      return NextResponse.json(
        { error: 'Reason for impersonation is required' },
        { status: 400 }
      )
    }

    const { data: sessionId, error } = await supabase.rpc('start_impersonation', {
      p_super_admin_id: user.id,
      p_user_id: params.id,
      p_reason: reason,
      p_ip_address: request.headers.get('x-forwarded-for') || null,
    })

    if (error) throw error

    return NextResponse.json({ sessionId })

  } catch (error) {
    console.error('Failed to start impersonation:', error)
    return NextResponse.json(
      { error: 'Failed to start impersonation' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Platform User Management Table

```typescript
// src/components/platform/user-management-table.tsx

'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Table, TableBody, TableCell, TableHead,
  TableHeader, TableRow
} from '@/components/ui/table'
import {
  Dialog, DialogContent, DialogDescription,
  DialogHeader, DialogTitle, DialogTrigger
} from '@/components/ui/dialog'
import { Users, Search, UserCog, Ban, CheckCircle } from 'lucide-react'
import { format } from 'date-fns'

export function UserManagementTable() {
  const [filters, setFilters] = useState({
    search: '',
    page: 1,
    pageSize: 50,
  })
  const [selectedUser, setSelectedUser] = useState<string | null>(null)
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['platform-users', filters],
    queryFn: async () => {
      const params = new URLSearchParams(filters as any)
      const res = await fetch(`/api/platform/users?${params}`)
      if (!res.ok) throw new Error('Failed to fetch users')
      return res.json()
    },
  })

  const impersonateMutation = useMutation({
    mutationFn: async ({ userId, reason }: { userId: string; reason: string }) => {
      const res = await fetch(`/api/platform/users/${userId}/impersonate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      })
      if (!res.ok) throw new Error('Failed to impersonate user')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['platform-users'] })
    },
  })

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-100 text-green-800">Active</Badge>
      case 'inactive':
        return <Badge className="bg-gray-100 text-gray-800">Inactive</Badge>
      case 'suspended':
        return <Badge className="bg-red-100 text-red-800">Suspended</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Platform Users ({data?.pagination?.total || 0})
          </CardTitle>
          <div className="flex gap-2">
            <Input
              placeholder="Search users..."
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              className="w-64"
            />
            <Button variant="outline">
              <Search className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardHeader>

      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>User</TableHead>
              <TableHead>Tenant</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Last Sign In</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data?.users?.map((user: any) => (
              <TableRow key={user.userId}>
                <TableCell>
                  <div>
                    <p className="font-medium">{user.fullName || 'N/A'}</p>
                    <p className="text-sm text-muted-foreground">{user.email}</p>
                  </div>
                </TableCell>
                <TableCell>
                  <div>
                    <p className="font-medium">{user.tenantName || 'N/A'}</p>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant="outline">{user.role || 'N/A'}</Badge>
                </TableCell>
                <TableCell>{getStatusBadge(user.status || 'unknown')}</TableCell>
                <TableCell>
                  {user.lastSignInAt
                    ? format(new Date(user.lastSignInAt), 'MMM dd, yyyy HH:mm')
                    : 'Never'}
                </TableCell>
                <TableCell>
                  <div className="flex gap-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedUser(user.userId)}
                    >
                      <UserCog className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {/* Pagination */}
        {data?.pagination && (
          <div className="flex items-center justify-between mt-4">
            <p className="text-sm text-muted-foreground">
              Page {data.pagination.page} of {data.pagination.totalPages}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={filters.page === 1}
                onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={filters.page >= data.pagination.totalPages}
                onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] View all platform users
- [x] Advanced search and filtering
- [x] User details with activity history
- [x] Enable/disable user accounts
- [x] Role and permission management
- [x] User impersonation with audit trail
- [x] Bulk operations support
- [x] Export functionality
- [x] Activity tracking
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
