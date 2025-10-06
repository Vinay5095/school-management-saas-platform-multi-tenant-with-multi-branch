# SPEC-119: Activity Log and Audit Trail
## Platform-wide Activity Monitoring and Audit System

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-116, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive activity log and audit trail system that tracks all super admin actions, tenant activities, system events, and security-related operations for compliance and monitoring.

### Key Features
- ✅ Real-time activity feed
- ✅ Filterable audit log
- ✅ User action tracking
- ✅ System event logging
- ✅ Security event monitoring
- ✅ Export audit reports
- ✅ Advanced search and filtering
- ✅ Severity levels
- ✅ Retention policies
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Platform activity log (extends existing table)
CREATE TABLE platform_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES auth.users(id),
  actor_email TEXT,
  actor_role TEXT,
  tenant_id UUID REFERENCES tenants(id),
  
  -- Activity details
  activity_type TEXT NOT NULL,
  activity_category TEXT NOT NULL CHECK (activity_category IN (
    'authentication', 'tenant_management', 'user_management',
    'system_config', 'security', 'billing', 'data_access', 'other'
  )),
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id UUID,
  resource_name TEXT,
  
  -- Event details
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  status TEXT NOT NULL CHECK (status IN ('success', 'failure', 'pending')),
  
  -- Context
  ip_address INET,
  user_agent TEXT,
  request_path TEXT,
  request_method TEXT,
  
  -- Data
  changes_made JSONB,
  metadata JSONB DEFAULT '{}'::jsonb,
  error_message TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  retention_until TIMESTAMPTZ
);

CREATE INDEX idx_activity_log_actor ON platform_activity_log(actor_id);
CREATE INDEX idx_activity_log_tenant ON platform_activity_log(tenant_id);
CREATE INDEX idx_activity_log_type ON platform_activity_log(activity_type);
CREATE INDEX idx_activity_log_category ON platform_activity_log(activity_category);
CREATE INDEX idx_activity_log_created ON platform_activity_log(created_at DESC);
CREATE INDEX idx_activity_log_severity ON platform_activity_log(severity);
CREATE INDEX idx_activity_log_status ON platform_activity_log(status);
CREATE INDEX idx_activity_log_resource ON platform_activity_log(resource_type, resource_id);

-- Security events table
CREATE TABLE security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  description TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  tenant_id UUID REFERENCES tenants(id),
  ip_address INET,
  user_agent TEXT,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id),
  resolution_notes TEXT,
  event_data JSONB DEFAULT '{}'::jsonb,
  is_false_positive BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_user ON security_events(user_id);
CREATE INDEX idx_security_events_tenant ON security_events(tenant_id);
CREATE INDEX idx_security_events_detected ON security_events(detected_at DESC);
CREATE INDEX idx_security_events_resolved ON security_events(resolved_at) WHERE resolved_at IS NOT NULL;

-- Audit report configurations
CREATE TABLE audit_report_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  filters JSONB NOT NULL,
  columns TEXT[] NOT NULL,
  schedule TEXT, -- cron expression
  recipients TEXT[],
  format TEXT CHECK (format IN ('csv', 'json', 'pdf')),
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Generated audit reports
CREATE TABLE audit_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id UUID REFERENCES audit_report_configs(id),
  report_name TEXT NOT NULL,
  file_url TEXT,
  record_count INTEGER,
  date_from TIMESTAMPTZ,
  date_to TIMESTAMPTZ,
  filters_applied JSONB,
  generated_by UUID REFERENCES auth.users(id),
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_audit_reports_config ON audit_reports(config_id);
CREATE INDEX idx_audit_reports_generated ON audit_reports(generated_at DESC);

-- Function to log activity
CREATE OR REPLACE FUNCTION log_platform_activity(
  p_actor_id UUID,
  p_tenant_id UUID,
  p_activity_type TEXT,
  p_activity_category TEXT,
  p_action TEXT,
  p_resource_type TEXT DEFAULT NULL,
  p_resource_id UUID DEFAULT NULL,
  p_resource_name TEXT DEFAULT NULL,
  p_severity TEXT DEFAULT 'low',
  p_status TEXT DEFAULT 'success',
  p_ip_address INET DEFAULT NULL,
  p_changes_made JSONB DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_activity_id UUID;
  v_actor_email TEXT;
  v_actor_role TEXT;
BEGIN
  -- Get actor details
  SELECT email INTO v_actor_email
  FROM auth.users
  WHERE id = p_actor_id;
  
  SELECT role INTO v_actor_role
  FROM user_profiles
  WHERE user_id = p_actor_id;

  -- Insert activity log
  INSERT INTO platform_activity_log (
    actor_id,
    actor_email,
    actor_role,
    tenant_id,
    activity_type,
    activity_category,
    action,
    resource_type,
    resource_id,
    resource_name,
    severity,
    status,
    ip_address,
    changes_made,
    metadata,
    retention_until
  ) VALUES (
    p_actor_id,
    v_actor_email,
    v_actor_role,
    p_tenant_id,
    p_activity_type,
    p_activity_category,
    p_action,
    p_resource_type,
    p_resource_id,
    p_resource_name,
    p_severity,
    p_status,
    p_ip_address,
    p_changes_made,
    p_metadata,
    NOW() + INTERVAL '7 years' -- Compliance requirement
  ) RETURNING id INTO v_activity_id;

  RETURN v_activity_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get activity statistics
CREATE OR REPLACE FUNCTION get_activity_statistics(
  p_from_date TIMESTAMPTZ,
  p_to_date TIMESTAMPTZ
)
RETURNS TABLE (
  category TEXT,
  total_count BIGINT,
  success_count BIGINT,
  failure_count BIGINT,
  critical_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    activity_category,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE status = 'success') as success_count,
    COUNT(*) FILTER (WHERE status = 'failure') as failure_count,
    COUNT(*) FILTER (WHERE severity = 'critical') as critical_count
  FROM platform_activity_log
  WHERE created_at BETWEEN p_from_date AND p_to_date
  GROUP BY activity_category
  ORDER BY total_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to detect suspicious activity
CREATE OR REPLACE FUNCTION detect_suspicious_activity()
RETURNS void AS $$
DECLARE
  v_user RECORD;
BEGIN
  -- Detect multiple failed login attempts
  FOR v_user IN
    SELECT actor_id, COUNT(*) as failure_count
    FROM platform_activity_log
    WHERE activity_type = 'failed_login'
      AND created_at > NOW() - INTERVAL '15 minutes'
    GROUP BY actor_id
    HAVING COUNT(*) >= 5
  LOOP
    INSERT INTO security_events (
      event_type,
      severity,
      description,
      user_id,
      event_data
    )
    SELECT 'multiple_failed_logins', 'warning',
           format('Multiple failed login attempts detected for user %s', v_user.actor_id),
           v_user.actor_id,
           jsonb_build_object('failure_count', v_user.failure_count)
    WHERE NOT EXISTS (
      SELECT 1 FROM security_events
      WHERE event_type = 'multiple_failed_logins'
        AND user_id = v_user.actor_id
        AND detected_at > NOW() - INTERVAL '1 hour'
    );
  END LOOP;

  -- Detect unusual data access patterns
  FOR v_user IN
    SELECT actor_id, COUNT(*) as access_count
    FROM platform_activity_log
    WHERE activity_category = 'data_access'
      AND created_at > NOW() - INTERVAL '1 hour'
    GROUP BY actor_id
    HAVING COUNT(*) >= 100
  LOOP
    INSERT INTO security_events (
      event_type,
      severity,
      description,
      user_id,
      event_data
    )
    SELECT 'unusual_data_access', 'warning',
           format('Unusual data access pattern detected for user %s', v_user.actor_id),
           v_user.actor_id,
           jsonb_build_object('access_count', v_user.access_count)
    WHERE NOT EXISTS (
      SELECT 1 FROM security_events
      WHERE event_type = 'unusual_data_access'
        AND user_id = v_user.actor_id
        AND detected_at > NOW() - INTERVAL '1 hour'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE platform_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_report_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY super_admin_activity_log ON platform_activity_log
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY super_admin_security_events ON security_events
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY super_admin_audit_reports ON audit_report_configs
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
// src/types/activity-log.ts

export interface ActivityLog {
  id: string
  actorId?: string
  actorEmail?: string
  actorRole?: string
  tenantId?: string
  activityType: string
  activityCategory: string
  action: string
  resourceType?: string
  resourceId?: string
  resourceName?: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  status: 'success' | 'failure' | 'pending'
  ipAddress?: string
  userAgent?: string
  requestPath?: string
  requestMethod?: string
  changesMade?: Record<string, any>
  metadata?: Record<string, any>
  errorMessage?: string
  createdAt: string
  retentionUntil?: string
}

export interface SecurityEvent {
  id: string
  eventType: string
  severity: 'info' | 'warning' | 'critical'
  description: string
  userId?: string
  tenantId?: string
  ipAddress?: string
  userAgent?: string
  detectedAt: string
  resolvedAt?: string
  resolvedBy?: string
  resolutionNotes?: string
  eventData?: Record<string, any>
  isFalsePositive: boolean
  createdAt: string
}

export interface AuditReportConfig {
  id: string
  name: string
  description?: string
  filters: Record<string, any>
  columns: string[]
  schedule?: string
  recipients?: string[]
  format: 'csv' | 'json' | 'pdf'
  isActive: boolean
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface ActivityStatistics {
  category: string
  totalCount: number
  successCount: number
  failureCount: number
  criticalCount: number
}

export interface ActivityFilters {
  activityCategory?: string
  activityType?: string
  severity?: string
  status?: string
  tenantId?: string
  actorId?: string
  dateFrom?: string
  dateTo?: string
  search?: string
}
```

### API Routes

```typescript
// src/app/api/platform/activity-log/route.ts

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
    const page = parseInt(searchParams.get('page') || '1')
    const pageSize = parseInt(searchParams.get('pageSize') || '50')
    const category = searchParams.get('category')
    const severity = searchParams.get('severity')
    const status = searchParams.get('status')
    const dateFrom = searchParams.get('dateFrom')
    const dateTo = searchParams.get('dateTo')
    const search = searchParams.get('search')

    let query = supabase
      .from('platform_activity_log')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })

    if (category) query = query.eq('activity_category', category)
    if (severity) query = query.eq('severity', severity)
    if (status) query = query.eq('status', status)
    if (dateFrom) query = query.gte('created_at', dateFrom)
    if (dateTo) query = query.lte('created_at', dateTo)
    if (search) {
      query = query.or(`action.ilike.%${search}%,actor_email.ilike.%${search}%,resource_name.ilike.%${search}%`)
    }

    const { data: activities, error, count } = await query
      .range((page - 1) * pageSize, page * pageSize - 1)

    if (error) throw error

    return NextResponse.json({
      activities,
      pagination: {
        page,
        pageSize,
        total: count,
        totalPages: Math.ceil((count || 0) / pageSize),
      },
    })

  } catch (error) {
    console.error('Failed to fetch activity log:', error)
    return NextResponse.json(
      { error: 'Failed to fetch activity log' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()

    const { data, error } = await supabase.rpc('log_platform_activity', {
      p_actor_id: user.id,
      p_tenant_id: body.tenantId,
      p_activity_type: body.activityType,
      p_activity_category: body.activityCategory,
      p_action: body.action,
      p_resource_type: body.resourceType,
      p_resource_id: body.resourceId,
      p_resource_name: body.resourceName,
      p_severity: body.severity || 'low',
      p_status: body.status || 'success',
      p_ip_address: body.ipAddress,
      p_changes_made: body.changesMade,
      p_metadata: body.metadata,
    })

    if (error) throw error

    return NextResponse.json({ activityId: data }, { status: 201 })

  } catch (error) {
    console.error('Failed to log activity:', error)
    return NextResponse.json(
      { error: 'Failed to log activity' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/activity-log/statistics/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const dateFrom = searchParams.get('dateFrom') || 
                     new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
    const dateTo = searchParams.get('dateTo') || new Date().toISOString()

    const { data: stats, error } = await supabase.rpc('get_activity_statistics', {
      p_from_date: dateFrom,
      p_to_date: dateTo,
    })

    if (error) throw error

    return NextResponse.json({ statistics: stats })

  } catch (error) {
    console.error('Failed to fetch statistics:', error)
    return NextResponse.json(
      { error: 'Failed to fetch statistics' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/security-events/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const resolved = searchParams.get('resolved')
    const severity = searchParams.get('severity')

    let query = supabase
      .from('security_events')
      .select('*')
      .order('detected_at', { ascending: false })

    if (resolved === 'false') {
      query = query.is('resolved_at', null)
    } else if (resolved === 'true') {
      query = query.not('resolved_at', 'is', null)
    }

    if (severity) {
      query = query.eq('severity', severity)
    }

    const { data: events, error } = await query.limit(100)

    if (error) throw error

    return NextResponse.json({ events })

  } catch (error) {
    console.error('Failed to fetch security events:', error)
    return NextResponse.json(
      { error: 'Failed to fetch security events' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Activity Log Viewer

```typescript
// src/components/platform/activity-log-viewer.tsx

'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  Table, TableBody, TableCell, TableHead, 
  TableHeader, TableRow 
} from '@/components/ui/table'
import { Activity, Download, Filter, Search } from 'lucide-react'
import { format } from 'date-fns'

export function ActivityLogViewer() {
  const [filters, setFilters] = useState({
    category: '',
    severity: '',
    status: '',
    search: '',
    page: 1,
  })

  const { data, isLoading } = useQuery({
    queryKey: ['activity-log', filters],
    queryFn: async () => {
      const params = new URLSearchParams()
      Object.entries(filters).forEach(([key, value]) => {
        if (value) params.append(key, value.toString())
      })
      
      const res = await fetch(`/api/platform/activity-log?${params}`)
      if (!res.ok) throw new Error('Failed to fetch activity log')
      return res.json()
    },
  })

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'destructive'
      case 'high': return 'default'
      case 'medium': return 'secondary'
      default: return 'outline'
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success': return 'bg-green-100 text-green-800'
      case 'failure': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Activity Log
          </CardTitle>
          <Button variant="outline" size="sm">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>

        {/* Filters */}
        <div className="flex gap-3 mt-4">
          <div className="flex-1">
            <Input
              placeholder="Search activities..."
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              className="w-full"
            />
          </div>
          <Select
            value={filters.category}
            onValueChange={(value) => setFilters({ ...filters, category: value })}
          >
            <option value="">All Categories</option>
            <option value="authentication">Authentication</option>
            <option value="tenant_management">Tenant Management</option>
            <option value="user_management">User Management</option>
            <option value="system_config">System Config</option>
            <option value="security">Security</option>
            <option value="billing">Billing</option>
          </Select>
          <Select
            value={filters.severity}
            onValueChange={(value) => setFilters({ ...filters, severity: value })}
          >
            <option value="">All Severities</option>
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
            <option value="critical">Critical</option>
          </Select>
        </div>
      </CardHeader>

      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Timestamp</TableHead>
              <TableHead>Actor</TableHead>
              <TableHead>Action</TableHead>
              <TableHead>Resource</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Severity</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data?.activities?.map((activity: any) => (
              <TableRow key={activity.id}>
                <TableCell className="font-mono text-sm">
                  {format(new Date(activity.createdAt), 'MMM dd, HH:mm:ss')}
                </TableCell>
                <TableCell>
                  <div>
                    <p className="font-medium">{activity.actorEmail || 'System'}</p>
                    <p className="text-xs text-muted-foreground">{activity.actorRole}</p>
                  </div>
                </TableCell>
                <TableCell>{activity.action}</TableCell>
                <TableCell>
                  {activity.resourceName ? (
                    <div>
                      <p className="font-medium">{activity.resourceName}</p>
                      <p className="text-xs text-muted-foreground">{activity.resourceType}</p>
                    </div>
                  ) : (
                    '-'
                  )}
                </TableCell>
                <TableCell>
                  <Badge variant="outline">{activity.activityCategory}</Badge>
                </TableCell>
                <TableCell>
                  <Badge variant={getSeverityColor(activity.severity)}>
                    {activity.severity}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Badge className={getStatusColor(activity.status)}>
                    {activity.status}
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {/* Pagination */}
        {data?.pagination && (
          <div className="flex items-center justify-between mt-4">
            <p className="text-sm text-muted-foreground">
              Showing {data.pagination.page} of {data.pagination.totalPages} pages
              ({data.pagination.total} total activities)
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
                disabled={filters.page === data.pagination.totalPages}
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

- [x] Real-time activity feed
- [x] Comprehensive activity logging
- [x] Advanced filtering and search
- [x] Security event detection
- [x] Audit trail export
- [x] Activity statistics
- [x] Retention policy enforcement
- [x] IP address tracking
- [x] Change tracking
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
