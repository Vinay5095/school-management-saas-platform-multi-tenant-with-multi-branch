# SPEC-152: Branch Management System
## Complete Branch CRUD and Configuration

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 6-7 hours  
> **Dependencies**: SPEC-151, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Comprehensive branch management system for creating, viewing, editing, and managing all school branches within the organization with complete configuration options.

### Key Features
- ✅ Branch CRUD operations
- ✅ Branch details and configuration
- ✅ Branch status management (active, inactive, suspended)
- ✅ Contact information management
- ✅ Location and address management
- ✅ Capacity and limits configuration
- ✅ Branch hierarchy
- ✅ Document attachments
- ✅ Branch activation/deactivation
- ✅ Branch performance metrics
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Extended branches table (already exists from Phase 1, adding fields)
ALTER TABLE branches ADD COLUMN IF NOT EXISTS
  code TEXT UNIQUE,
  type TEXT CHECK (type IN ('main', 'branch', 'satellite')) DEFAULT 'branch',
  parent_branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  established_date DATE,
  accreditation TEXT,
  capacity INTEGER DEFAULT 500,
  current_enrollment INTEGER DEFAULT 0,
  settings JSONB DEFAULT '{
    "weekStartDay": 1,
    "sessionDuration": 40,
    "breakDuration": 10,
    "lunchDuration": 45
  }'::jsonb,
  facilities TEXT[],
  metadata JSONB DEFAULT '{}'::jsonb;

-- Branch contacts table
CREATE TABLE branch_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  contact_type TEXT NOT NULL CHECK (contact_type IN ('phone', 'email', 'fax', 'emergency')),
  contact_value TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT false,
  label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_branch_contacts_branch ON branch_contacts(branch_id);

-- Branch documents table
CREATE TABLE branch_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('license', 'certificate', 'accreditation', 'insurance', 'other')),
  title TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  expiry_date DATE,
  uploaded_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_branch_documents_branch ON branch_documents(branch_id);
CREATE INDEX idx_branch_documents_tenant ON branch_documents(tenant_id);
CREATE INDEX idx_branch_documents_expiry ON branch_documents(expiry_date) WHERE expiry_date IS NOT NULL;

-- Branch operating hours table
CREATE TABLE branch_operating_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 6=Saturday
  is_open BOOLEAN DEFAULT true,
  open_time TIME,
  close_time TIME,
  notes TEXT,
  UNIQUE(branch_id, day_of_week)
);

CREATE INDEX idx_branch_hours_branch ON branch_operating_hours(branch_id);

-- Function to validate branch capacity
CREATE OR REPLACE FUNCTION validate_branch_capacity()
RETURNS TRIGGER AS $$
BEGIN
  -- Update current enrollment count
  UPDATE branches
  SET current_enrollment = (
    SELECT COUNT(*)
    FROM students
    WHERE branch_id = NEW.branch_id
      AND status = 'active'
      AND deleted_at IS NULL
  )
  WHERE id = NEW.branch_id;

  -- Check if over capacity
  IF (SELECT current_enrollment FROM branches WHERE id = NEW.branch_id) > 
     (SELECT capacity FROM branches WHERE id = NEW.branch_id) THEN
    RAISE WARNING 'Branch % is over capacity', NEW.branch_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_branch_capacity
AFTER INSERT OR UPDATE ON students
FOR EACH ROW
EXECUTE FUNCTION validate_branch_capacity();

-- Function to get branch hierarchy
CREATE OR REPLACE FUNCTION get_branch_hierarchy(p_branch_id UUID)
RETURNS TABLE (
  branch_id UUID,
  branch_name TEXT,
  level INTEGER,
  path TEXT[]
) AS $$
WITH RECURSIVE branch_tree AS (
  -- Base case: start with the given branch
  SELECT 
    id,
    name,
    parent_branch_id,
    0 as level,
    ARRAY[name] as path
  FROM branches
  WHERE id = p_branch_id
  
  UNION ALL
  
  -- Recursive case: find children
  SELECT 
    b.id,
    b.name,
    b.parent_branch_id,
    bt.level + 1,
    bt.path || b.name
  FROM branches b
  INNER JOIN branch_tree bt ON b.parent_branch_id = bt.id
  WHERE b.deleted_at IS NULL
)
SELECT 
  id as branch_id,
  name as branch_name,
  level,
  path
FROM branch_tree
ORDER BY level, name;
$$ LANGUAGE sql STABLE;
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/branch.ts

export interface Branch {
  id: string
  tenantId: string
  name: string
  code: string
  type: 'main' | 'branch' | 'satellite'
  parentBranchId?: string
  status: 'active' | 'inactive' | 'suspended'
  address: {
    street: string
    city: string
    state: string
    postalCode: string
    country: string
  }
  establishedDate?: string
  accreditation?: string
  capacity: number
  currentEnrollment: number
  settings: {
    weekStartDay: number
    sessionDuration: number
    breakDuration: number
    lunchDuration: number
  }
  facilities: string[]
  metadata: Record<string, any>
  createdAt: string
  updatedAt: string
  deletedAt?: string
}

export interface BranchContact {
  id: string
  branchId: string
  contactType: 'phone' | 'email' | 'fax' | 'emergency'
  contactValue: string
  isPrimary: boolean
  label?: string
}

export interface BranchDocument {
  id: string
  branchId: string
  documentType: 'license' | 'certificate' | 'accreditation' | 'insurance' | 'other'
  title: string
  filePath: string
  fileSize: number
  mimeType: string
  expiryDate?: string
  uploadedBy: string
  createdAt: string
}

export interface BranchOperatingHours {
  id: string
  branchId: string
  dayOfWeek: number
  isOpen: boolean
  openTime?: string
  closeTime?: string
  notes?: string
}

export interface BranchFormData {
  name: string
  code: string
  type: 'main' | 'branch' | 'satellite'
  parentBranchId?: string
  address: {
    street: string
    city: string
    state: string
    postalCode: string
    country: string
  }
  establishedDate?: string
  accreditation?: string
  capacity: number
  settings?: {
    weekStartDay?: number
    sessionDuration?: number
    breakDuration?: number
    lunchDuration?: number
  }
  facilities?: string[]
  contacts: BranchContact[]
  operatingHours: BranchOperatingHours[]
}
```

### API Routes

```typescript
// src/app/api/tenant/branches/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { z } from 'zod'

const branchSchema = z.object({
  name: z.string().min(2).max(100),
  code: z.string().min(2).max(20),
  type: z.enum(['main', 'branch', 'satellite']),
  parentBranchId: z.string().uuid().optional(),
  address: z.object({
    street: z.string().min(5),
    city: z.string().min(2),
    state: z.string().min(2),
    postalCode: z.string().min(3),
    country: z.string().min(2),
  }),
  establishedDate: z.string().optional(),
  accreditation: z.string().optional(),
  capacity: z.number().min(10).max(10000),
  settings: z.object({
    weekStartDay: z.number().min(0).max(6).optional(),
    sessionDuration: z.number().min(15).max(120).optional(),
    breakDuration: z.number().min(5).max(30).optional(),
    lunchDuration: z.number().min(15).max(90).optional(),
  }).optional(),
  facilities: z.array(z.string()).optional(),
  contacts: z.array(z.object({
    contactType: z.enum(['phone', 'email', 'fax', 'emergency']),
    contactValue: z.string(),
    isPrimary: z.boolean().optional(),
    label: z.string().optional(),
  })),
  operatingHours: z.array(z.object({
    dayOfWeek: z.number().min(0).max(6),
    isOpen: z.boolean(),
    openTime: z.string().optional(),
    closeTime: z.string().optional(),
    notes: z.string().optional(),
  })),
})

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

  // Auth check
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Get user's tenant
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Parse query parameters
  const status = searchParams.get('status') || 'all'
  const search = searchParams.get('search') || ''
  const type = searchParams.get('type') || 'all'

  try {
    let query = supabase
      .from('branches')
      .select(`
        *,
        parent:parent_branch_id (name),
        contacts:branch_contacts (*),
        documents:branch_documents (count),
        operating_hours:branch_operating_hours (*)
      `)
      .eq('tenant_id', profile.tenant_id)
      .is('deleted_at', null)
      .order('name')

    // Filters
    if (status !== 'all') {
      query = query.eq('status', status)
    }

    if (type !== 'all') {
      query = query.eq('type', type)
    }

    if (search) {
      query = query.or(`name.ilike.%${search}%,code.ilike.%${search}%,address->>city.ilike.%${search}%`)
    }

    const { data: branches, error } = await query

    if (error) throw error

    return NextResponse.json({ branches })

  } catch (error) {
    console.error('Branches fetch error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch branches' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  // Auth check
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Get user's tenant
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const body = await request.json()
    const validatedData = branchSchema.parse(body)

    // Check code uniqueness
    const { data: existing } = await supabase
      .from('branches')
      .select('id')
      .eq('tenant_id', profile.tenant_id)
      .eq('code', validatedData.code)
      .single()

    if (existing) {
      return NextResponse.json(
        { error: 'Branch code already exists' },
        { status: 400 }
      )
    }

    // Create branch
    const { data: branch, error: branchError } = await supabase
      .from('branches')
      .insert({
        tenant_id: profile.tenant_id,
        name: validatedData.name,
        code: validatedData.code,
        type: validatedData.type,
        parent_branch_id: validatedData.parentBranchId,
        address: validatedData.address,
        established_date: validatedData.establishedDate,
        accreditation: validatedData.accreditation,
        capacity: validatedData.capacity,
        settings: validatedData.settings || {},
        facilities: validatedData.facilities || [],
        status: 'active',
      })
      .select()
      .single()

    if (branchError) throw branchError

    // Create contacts
    if (validatedData.contacts.length > 0) {
      const { error: contactsError } = await supabase
        .from('branch_contacts')
        .insert(
          validatedData.contacts.map(contact => ({
            branch_id: branch.id,
            ...contact,
          }))
        )

      if (contactsError) throw contactsError
    }

    // Create operating hours
    if (validatedData.operatingHours.length > 0) {
      const { error: hoursError } = await supabase
        .from('branch_operating_hours')
        .insert(
          validatedData.operatingHours.map(hours => ({
            branch_id: branch.id,
            ...hours,
          }))
        )

      if (hoursError) throw hoursError
    }

    // Log activity
    await supabase.from('platform_activity_log').insert({
      tenant_id: profile.tenant_id,
      branch_id: branch.id,
      user_id: user.id,
      action: 'branch_created',
      action_type: 'create',
      details: `Created branch: ${branch.name}`,
      metadata: { branchId: branch.id },
    })

    return NextResponse.json({ branch }, { status: 201 })

  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation error', details: error.errors },
        { status: 400 }
      )
    }
    console.error('Branch creation error:', error)
    return NextResponse.json(
      { error: 'Failed to create branch' },
      { status: 500 }
    )
  }
}

// src/app/api/tenant/branches/[branchId]/route.ts

export async function GET(
  request: Request,
  { params }: { params: { branchId: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { data: branch, error } = await supabase
      .from('branches')
      .select(`
        *,
        parent:parent_branch_id (id, name, code),
        contacts:branch_contacts (*),
        documents:branch_documents (*),
        operating_hours:branch_operating_hours (*),
        children:branches!parent_branch_id (id, name, code, status)
      `)
      .eq('id', params.branchId)
      .is('deleted_at', null)
      .single()

    if (error) throw error

    if (!branch) {
      return NextResponse.json(
        { error: 'Branch not found' },
        { status: 404 }
      )
    }

    // Get performance metrics
    const { data: performance } = await supabase
      .from('branch_performance_metrics')
      .select('*')
      .eq('branch_id', params.branchId)
      .order('metric_date', { ascending: false })
      .limit(30)

    return NextResponse.json({
      branch: {
        ...branch,
        performance,
      },
    })

  } catch (error) {
    console.error('Branch fetch error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch branch' },
      { status: 500 }
    )
  }
}

export async function PATCH(
  request: Request,
  { params }: { params: { branchId: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()

    const { data: branch, error } = await supabase
      .from('branches')
      .update({
        ...body,
        updated_at: new Date().toISOString(),
      })
      .eq('id', params.branchId)
      .select()
      .single()

    if (error) throw error

    // Log activity
    await supabase.from('platform_activity_log').insert({
      tenant_id: branch.tenant_id,
      branch_id: branch.id,
      user_id: user.id,
      action: 'branch_updated',
      action_type: 'update',
      details: `Updated branch: ${branch.name}`,
      metadata: { changes: body },
    })

    return NextResponse.json({ branch })

  } catch (error) {
    console.error('Branch update error:', error)
    return NextResponse.json(
      { error: 'Failed to update branch' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: { branchId: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    // Soft delete
    const { data: branch, error } = await supabase
      .from('branches')
      .update({
        status: 'inactive',
        deleted_at: new Date().toISOString(),
      })
      .eq('id', params.branchId)
      .select()
      .single()

    if (error) throw error

    // Log activity
    await supabase.from('platform_activity_log').insert({
      tenant_id: branch.tenant_id,
      user_id: user.id,
      action: 'branch_deleted',
      action_type: 'delete',
      details: `Deleted branch: ${branch.name}`,
      metadata: { branchId: branch.id },
    })

    return NextResponse.json({ message: 'Branch deleted successfully' })

  } catch (error) {
    console.error('Branch deletion error:', error)
    return NextResponse.json(
      { error: 'Failed to delete branch' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Branch List Page

```typescript
// src/app/tenant/branches/page.tsx

'use client'

import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { 
  Select, SelectContent, SelectItem, 
  SelectTrigger, SelectValue 
} from '@/components/ui/select'
import {
  Table, TableBody, TableCell, TableHead,
  TableHeader, TableRow
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { 
  Plus, Search, Filter, Building2, 
  MapPin, Users, MoreVertical, Eye, Edit, Trash 
} from 'lucide-react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'

export default function BranchesPage() {
  const router = useRouter()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['branches', statusFilter, typeFilter, search],
    queryFn: async () => {
      const params = new URLSearchParams({
        status: statusFilter,
        type: typeFilter,
        search,
      })
      const res = await fetch(`/api/tenant/branches?${params}`)
      if (!res.ok) throw new Error('Failed to fetch branches')
      return res.json()
    },
  })

  const handleDelete = async (branchId: string) => {
    if (!confirm('Are you sure you want to delete this branch?')) return

    try {
      const res = await fetch(`/api/tenant/branches/${branchId}`, {
        method: 'DELETE',
      })
      if (res.ok) {
        refetch()
      }
    } catch (error) {
      console.error('Delete error:', error)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800'
      case 'inactive': return 'bg-gray-100 text-gray-800'
      case 'suspended': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'main': return '🏛️'
      case 'branch': return '🏢'
      case 'satellite': return '📍'
      default: return '🏢'
    }
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Branches</h1>
        </div>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-16 bg-gray-100 animate-pulse rounded"></div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Branches</h1>
          <p className="text-muted-foreground">
            Manage all organization branches
          </p>
        </div>
        <Button onClick={() => router.push('/tenant/branches/new')}>
          <Plus className="h-4 w-4 mr-2" />
          Add Branch
        </Button>
      </div>

      {/* Summary Cards */}
      <div className="grid gap-6 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Branches
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data?.branches?.length || 0}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Active
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {data?.branches?.filter((b: any) => b.status === 'active').length || 0}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Capacity
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data?.branches?.reduce((sum: number, b: any) => sum + b.capacity, 0) || 0}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Current Enrollment
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {data?.branches?.reduce((sum: number, b: any) => sum + (b.current_enrollment || 0), 0) || 0}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search branches..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
                <SelectItem value="suspended">Suspended</SelectItem>
              </SelectContent>
            </Select>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Types</SelectItem>
                <SelectItem value="main">Main</SelectItem>
                <SelectItem value="branch">Branch</SelectItem>
                <SelectItem value="satellite">Satellite</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Branches Table */}
      <Card>
        <CardContent className="pt-6">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Branch</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Location</TableHead>
                <TableHead>Enrollment</TableHead>
                <TableHead>Capacity</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data?.branches?.map((branch: any) => (
                <TableRow key={branch.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                        <Building2 className="h-5 w-5 text-primary" />
                      </div>
                      <div>
                        <div className="font-medium">{branch.name}</div>
                        <div className="text-sm text-muted-foreground">
                          {branch.code}
                        </div>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <span>{getTypeIcon(branch.type)}</span>
                      <span className="capitalize">{branch.type}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge className={getStatusColor(branch.status)}>
                      {branch.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <MapPin className="h-4 w-4 text-muted-foreground" />
                      <span>{branch.address?.city}, {branch.address?.state}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Users className="h-4 w-4 text-muted-foreground" />
                      <span>{branch.current_enrollment || 0}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <span>{branch.capacity}</span>
                      <span className="text-xs text-muted-foreground">
                        ({Math.round((branch.current_enrollment || 0) / branch.capacity * 100)}%)
                      </span>
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem asChild>
                          <Link href={`/tenant/branches/${branch.id}`}>
                            <Eye className="h-4 w-4 mr-2" />
                            View Details
                          </Link>
                        </DropdownMenuItem>
                        <DropdownMenuItem asChild>
                          <Link href={`/tenant/branches/${branch.id}/edit`}>
                            <Edit className="h-4 w-4 mr-2" />
                            Edit
                          </Link>
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onClick={() => handleDelete(branch.id)}
                          className="text-red-600"
                        >
                          <Trash className="h-4 w-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {data?.branches?.length === 0 && (
            <div className="text-center py-12">
              <Building2 className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-medium mb-2">No branches found</h3>
              <p className="text-muted-foreground mb-4">
                Get started by creating your first branch
              </p>
              <Button onClick={() => router.push('/tenant/branches/new')}>
                <Plus className="h-4 w-4 mr-2" />
                Add Branch
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
```

---

[Continues with Branch Creation Form, Branch Details View, Tests, etc.]

---

## 🧪 TESTING

### Unit Tests

```typescript
// src/app/api/tenant/branches/__tests__/route.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { GET, POST } from '../route'

describe('Branch API', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should fetch all branches for tenant', async () => {
    const request = new Request('http://localhost/api/tenant/branches')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data).toHaveProperty('branches')
    expect(Array.isArray(data.branches)).toBe(true)
  })

  it('should create a new branch', async () => {
    const branchData = {
      name: 'Main Campus',
      code: 'MC001',
      type: 'main',
      address: {
        street: '123 Main St',
        city: 'Boston',
        state: 'MA',
        postalCode: '02101',
        country: 'USA',
      },
      capacity: 1000,
      contacts: [
        {
          contactType: 'phone',
          contactValue: '+1-555-0100',
          isPrimary: true,
        },
      ],
      operatingHours: [],
    }

    const request = new Request('http://localhost/api/tenant/branches', {
      method: 'POST',
      body: JSON.stringify(branchData),
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(201)
    expect(data).toHaveProperty('branch')
    expect(data.branch.name).toBe('Main Campus')
  })
})
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Create new branches with full details
- [x] View list of all branches with filters
- [x] Edit branch information
- [x] Delete branches (soft delete)
- [x] Manage branch contacts
- [x] Configure operating hours
- [x] Upload branch documents
- [x] Track branch capacity
- [x] View branch hierarchy
- [x] Branch performance metrics
- [x] Responsive design
- [x] Accessible UI (WCAG 2.1 AA)

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: CRITICAL
