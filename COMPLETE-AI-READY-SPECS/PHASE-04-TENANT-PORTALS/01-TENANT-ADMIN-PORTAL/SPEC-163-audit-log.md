# SPEC-163: Activity and Audit Log
## Comprehensive Activity Tracking and Audit Trail

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-151, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Complete activity monitoring and audit logging system to track all user actions, system events, and data changes across the organization for security, compliance, and troubleshooting purposes.

### Key Features
- ✅ Comprehensive activity logging
- ✅ User action tracking
- ✅ Data change history
- ✅ Login/logout tracking
- ✅ Security event monitoring
- ✅ Advanced filtering and search
- ✅ Export audit logs
- ✅ Real-time activity feed
- ✅ Suspicious activity alerts
- ✅ Compliance reporting
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Activity log table (already exists, extending it)
ALTER TABLE platform_activity_log ADD COLUMN IF NOT EXISTS
  severity TEXT CHECK (severity IN ('info', 'warning', 'error', 'critical')) DEFAULT 'info',
  ip_address INET,
  user_agent TEXT,
  session_id TEXT,
  request_id TEXT,
  duration_ms INTEGER,
  status TEXT CHECK (status IN ('success', 'failed', 'pending')) DEFAULT 'success',
  error_message TEXT,
  before_data JSONB,
  after_data JSONB,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[];

CREATE INDEX IF NOT EXISTS idx_activity_log_severity ON platform_activity_log(severity);
CREATE INDEX IF NOT EXISTS idx_activity_log_status ON platform_activity_log(status);
CREATE INDEX IF NOT EXISTS idx_activity_log_ip ON platform_activity_log(ip_address);
CREATE INDEX IF NOT EXISTS idx_activity_log_session ON platform_activity_log(session_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_tags ON platform_activity_log USING gin(tags);

-- Authentication events table
CREATE TABLE auth_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('login', 'logout', 'login_failed', 'password_change', 'password_reset', 'mfa_enabled', 'mfa_disabled', 'session_expired')),
  ip_address INET NOT NULL,
  user_agent TEXT,
  location JSONB,
  mfa_method TEXT,
  success BOOLEAN DEFAULT true,
  failure_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_auth_events_user ON auth_events(user_id);
CREATE INDEX idx_auth_events_tenant ON auth_events(tenant_id);
CREATE INDEX idx_auth_events_type ON auth_events(event_type);
CREATE INDEX idx_auth_events_date ON auth_events(created_at DESC);
CREATE INDEX idx_auth_events_ip ON auth_events(ip_address);
CREATE INDEX idx_auth_events_success ON auth_events(success);

-- Data change history table
CREATE TABLE data_change_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_by UUID REFERENCES auth.users(id),
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[],
  reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_data_changes_tenant ON data_change_history(tenant_id);
CREATE INDEX idx_data_changes_table ON data_change_history(table_name);
CREATE INDEX idx_data_changes_record ON data_change_history(record_id);
CREATE INDEX idx_data_changes_user ON data_change_history(changed_by);
CREATE INDEX idx_data_changes_date ON data_change_history(changed_at DESC);
CREATE INDEX idx_data_changes_operation ON data_change_history(operation);

-- Security events table
CREATE TABLE security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('unauthorized_access', 'permission_denied', 'suspicious_activity', 'data_breach_attempt', 'brute_force', 'sql_injection', 'xss_attempt', 'rate_limit_exceeded', 'api_abuse')),
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  description TEXT NOT NULL,
  ip_address INET,
  user_agent TEXT,
  endpoint TEXT,
  request_method TEXT,
  request_payload JSONB,
  response_status INTEGER,
  is_resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_security_events_tenant ON security_events(tenant_id);
CREATE INDEX idx_security_events_user ON security_events(user_id);
CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_date ON security_events(created_at DESC);
CREATE INDEX idx_security_events_resolved ON security_events(is_resolved);
CREATE INDEX idx_security_events_ip ON security_events(ip_address);

-- Session tracking table
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  session_token TEXT NOT NULL UNIQUE,
  ip_address INET NOT NULL,
  user_agent TEXT,
  device_info JSONB,
  location JSONB,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  logout_reason TEXT CHECK (logout_reason IN ('manual', 'timeout', 'forced', 'expired'))
);

CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_tenant ON user_sessions(tenant_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_date ON user_sessions(started_at DESC);

-- Export requests table
CREATE TABLE audit_log_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  requested_by UUID NOT NULL REFERENCES auth.users(id),
  export_type TEXT NOT NULL CHECK (export_type IN ('activity', 'auth', 'security', 'data_changes', 'all')),
  filters JSONB DEFAULT '{}'::jsonb,
  date_range_start DATE NOT NULL,
  date_range_end DATE NOT NULL,
  file_format TEXT NOT NULL CHECK (file_format IN ('csv', 'json', 'pdf')) DEFAULT 'csv',
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')) DEFAULT 'pending',
  file_path TEXT,
  file_size INTEGER,
  record_count INTEGER,
  error_message TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
);

CREATE INDEX idx_audit_exports_tenant ON audit_log_exports(tenant_id);
CREATE INDEX idx_audit_exports_user ON audit_log_exports(requested_by);
CREATE INDEX idx_audit_exports_status ON audit_log_exports(status);
CREATE INDEX idx_audit_exports_date ON audit_log_exports(requested_at DESC);

-- Function to log activity
CREATE OR REPLACE FUNCTION log_activity(
  p_tenant_id UUID,
  p_user_id UUID,
  p_action_type TEXT,
  p_action TEXT,
  p_details TEXT DEFAULT NULL,
  p_severity TEXT DEFAULT 'info',
  p_ip_address INET DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO platform_activity_log (
    tenant_id,
    user_id,
    action_type,
    action,
    details,
    severity,
    ip_address,
    metadata,
    status
  ) VALUES (
    p_tenant_id,
    p_user_id,
    p_action_type,
    p_action,
    p_details,
    p_severity,
    p_ip_address,
    p_metadata,
    'success'
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log auth event
CREATE OR REPLACE FUNCTION log_auth_event(
  p_user_id UUID,
  p_tenant_id UUID,
  p_event_type TEXT,
  p_ip_address INET,
  p_user_agent TEXT DEFAULT NULL,
  p_success BOOLEAN DEFAULT true,
  p_failure_reason TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  INSERT INTO auth_events (
    user_id,
    tenant_id,
    event_type,
    ip_address,
    user_agent,
    success,
    failure_reason
  ) VALUES (
    p_user_id,
    p_tenant_id,
    p_event_type,
    p_ip_address,
    p_user_agent,
    p_success,
    p_failure_reason
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log data change
CREATE OR REPLACE FUNCTION log_data_change(
  p_tenant_id UUID,
  p_table_name TEXT,
  p_record_id UUID,
  p_operation TEXT,
  p_changed_by UUID,
  p_old_values JSONB DEFAULT NULL,
  p_new_values JSONB DEFAULT NULL,
  p_reason TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_changed_fields TEXT[];
BEGIN
  -- Calculate changed fields if both old and new values exist
  IF p_old_values IS NOT NULL AND p_new_values IS NOT NULL THEN
    SELECT ARRAY_AGG(key)
    INTO v_changed_fields
    FROM jsonb_each(p_new_values)
    WHERE value IS DISTINCT FROM (p_old_values->key);
  END IF;

  INSERT INTO data_change_history (
    tenant_id,
    table_name,
    record_id,
    operation,
    changed_by,
    old_values,
    new_values,
    changed_fields,
    reason
  ) VALUES (
    p_tenant_id,
    p_table_name,
    p_record_id,
    p_operation,
    p_changed_by,
    p_old_values,
    p_new_values,
    v_changed_fields,
    p_reason
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to detect suspicious activity
CREATE OR REPLACE FUNCTION detect_suspicious_activity(
  p_user_id UUID,
  p_time_window INTERVAL DEFAULT '1 hour'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_failed_login_count INTEGER;
  v_different_ip_count INTEGER;
  v_suspicious BOOLEAN := false;
BEGIN
  -- Check for multiple failed login attempts
  SELECT COUNT(*)
  INTO v_failed_login_count
  FROM auth_events
  WHERE user_id = p_user_id
    AND event_type = 'login_failed'
    AND created_at >= NOW() - p_time_window;

  IF v_failed_login_count >= 5 THEN
    v_suspicious := true;
  END IF;

  -- Check for logins from different IPs
  SELECT COUNT(DISTINCT ip_address)
  INTO v_different_ip_count
  FROM auth_events
  WHERE user_id = p_user_id
    AND event_type = 'login'
    AND success = true
    AND created_at >= NOW() - p_time_window;

  IF v_different_ip_count >= 3 THEN
    v_suspicious := true;
  END IF;

  RETURN v_suspicious;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get activity summary
CREATE OR REPLACE FUNCTION get_activity_summary(
  p_tenant_id UUID,
  p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
  total_activities BIGINT,
  unique_users INTEGER,
  failed_actions INTEGER,
  critical_events INTEGER,
  top_actions JSONB
) AS $$
BEGIN
  RETURN QUERY
  WITH activity_stats AS (
    SELECT
      COUNT(*) as total,
      COUNT(DISTINCT user_id) as users,
      COUNT(*) FILTER (WHERE status = 'failed') as failures,
      COUNT(*) FILTER (WHERE severity = 'critical') as critical
    FROM platform_activity_log
    WHERE tenant_id = p_tenant_id
      AND created_at >= CURRENT_DATE - p_days_back
  ),
  top_activity AS (
    SELECT jsonb_agg(
      jsonb_build_object(
        'action', action_type,
        'count', count
      ) ORDER BY count DESC
    ) as actions
    FROM (
      SELECT action_type, COUNT(*) as count
      FROM platform_activity_log
      WHERE tenant_id = p_tenant_id
        AND created_at >= CURRENT_DATE - p_days_back
      GROUP BY action_type
      ORDER BY count DESC
      LIMIT 10
    ) t
  )
  SELECT
    s.total,
    s.users,
    s.failures,
    s.critical,
    t.actions
  FROM activity_stats s, top_activity t;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically log data changes
CREATE OR REPLACE FUNCTION trigger_log_data_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM log_data_change(
      NEW.tenant_id,
      TG_TABLE_NAME::TEXT,
      NEW.id,
      'INSERT',
      auth.uid(),
      NULL,
      to_jsonb(NEW),
      'Record created'
    );
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM log_data_change(
      NEW.tenant_id,
      TG_TABLE_NAME::TEXT,
      NEW.id,
      'UPDATE',
      auth.uid(),
      to_jsonb(OLD),
      to_jsonb(NEW),
      'Record updated'
    );
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM log_data_change(
      OLD.tenant_id,
      TG_TABLE_NAME::TEXT,
      OLD.id,
      'DELETE',
      auth.uid(),
      to_jsonb(OLD),
      NULL,
      'Record deleted'
    );
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE auth_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_change_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log_exports ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_admin_auth_events ON auth_events
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_data_changes ON data_change_history
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_security_events ON security_events
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY user_own_sessions ON user_sessions
  FOR SELECT USING (
    user_id = auth.uid() OR
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_exports ON audit_log_exports
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/audit-log.ts

export interface ActivityLog {
  id: string
  tenantId: string
  userId?: string
  actionType: string
  action: string
  details?: string
  severity: 'info' | 'warning' | 'error' | 'critical'
  ipAddress?: string
  userAgent?: string
  sessionId?: string
  requestId?: string
  durationMs?: number
  status: 'success' | 'failed' | 'pending'
  errorMessage?: string
  beforeData?: Record<string, any>
  afterData?: Record<string, any>
  tags?: string[]
  metadata?: Record<string, any>
  createdAt: string
}

export interface AuthEvent {
  id: string
  userId?: string
  tenantId?: string
  eventType: 'login' | 'logout' | 'login_failed' | 'password_change' | 'password_reset' | 'mfa_enabled' | 'mfa_disabled' | 'session_expired'
  ipAddress: string
  userAgent?: string
  location?: Record<string, any>
  mfaMethod?: string
  success: boolean
  failureReason?: string
  metadata?: Record<string, any>
  createdAt: string
}

export interface DataChangeHistory {
  id: string
  tenantId: string
  tableName: string
  recordId: string
  operation: 'INSERT' | 'UPDATE' | 'DELETE'
  changedBy?: string
  changedAt: string
  oldValues?: Record<string, any>
  newValues?: Record<string, any>
  changedFields?: string[]
  reason?: string
  metadata?: Record<string, any>
}

export interface SecurityEvent {
  id: string
  tenantId?: string
  userId?: string
  eventType: 'unauthorized_access' | 'permission_denied' | 'suspicious_activity' | 'data_breach_attempt' | 'brute_force' | 'sql_injection' | 'xss_attempt' | 'rate_limit_exceeded' | 'api_abuse'
  severity: 'low' | 'medium' | 'high' | 'critical'
  description: string
  ipAddress?: string
  userAgent?: string
  endpoint?: string
  requestMethod?: string
  requestPayload?: Record<string, any>
  responseStatus?: number
  isResolved: boolean
  resolvedBy?: string
  resolvedAt?: string
  resolutionNotes?: string
  metadata?: Record<string, any>
  createdAt: string
}

export interface UserSession {
  id: string
  userId: string
  tenantId?: string
  sessionToken: string
  ipAddress: string
  userAgent?: string
  deviceInfo?: Record<string, any>
  location?: Record<string, any>
  startedAt: string
  lastActivityAt: string
  endedAt?: string
  isActive: boolean
  logoutReason?: 'manual' | 'timeout' | 'forced' | 'expired'
}

export interface ActivitySummary {
  totalActivities: number
  uniqueUsers: number
  failedActions: number
  criticalEvents: number
  topActions: Array<{
    action: string
    count: number
  }>
}
```

### API Routes

```typescript
// src/app/api/tenant/audit-logs/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const logType = searchParams.get('type') || 'activity'
  const severity = searchParams.get('severity')
  const userId = searchParams.get('user_id')
  const startDate = searchParams.get('start_date')
  const endDate = searchParams.get('end_date')
  const page = parseInt(searchParams.get('page') || '1')
  const limit = parseInt(searchParams.get('limit') || '50')
  const offset = (page - 1) * limit

  try {
    let query

    if (logType === 'activity') {
      query = supabase
        .from('platform_activity_log')
        .select(`
          *,
          user:auth.users (
            id,
            email,
            user_metadata
          )
        `, { count: 'exact' })
        .eq('tenant_id', profile.tenant_id)

      if (severity) query = query.eq('severity', severity)
      if (userId) query = query.eq('user_id', userId)
    } else if (logType === 'auth') {
      query = supabase
        .from('auth_events')
        .select(`
          *,
          user:auth.users (
            id,
            email,
            user_metadata
          )
        `, { count: 'exact' })
        .eq('tenant_id', profile.tenant_id)

      if (userId) query = query.eq('user_id', userId)
    } else if (logType === 'security') {
      query = supabase
        .from('security_events')
        .select('*', { count: 'exact' })
        .eq('tenant_id', profile.tenant_id)

      if (severity) query = query.eq('severity', severity)
      if (userId) query = query.eq('user_id', userId)
    } else if (logType === 'data_changes') {
      query = supabase
        .from('data_change_history')
        .select(`
          *,
          changedByUser:auth.users!changed_by (
            id,
            email,
            user_metadata
          )
        `, { count: 'exact' })
        .eq('tenant_id', profile.tenant_id)

      if (userId) query = query.eq('changed_by', userId)
    }

    if (startDate) {
      query = query.gte('created_at', startDate)
    }
    if (endDate) {
      query = query.lte('created_at', endDate)
    }

    const { data: logs, error, count } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    if (error) throw error

    return NextResponse.json({
      logs,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    })

  } catch (error) {
    console.error('Failed to fetch audit logs:', error)
    return NextResponse.json(
      { error: 'Failed to fetch audit logs' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/audit-logs/summary/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const daysBack = parseInt(searchParams.get('days_back') || '30')

  try {
    const { data: summary } = await supabase.rpc(
      'get_activity_summary',
      {
        p_tenant_id: profile.tenant_id,
        p_days_back: daysBack,
      }
    )

    return NextResponse.json({ summary: summary?.[0] || {} })

  } catch (error) {
    console.error('Failed to fetch summary:', error)
    return NextResponse.json(
      { error: 'Failed to fetch summary' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/audit-logs/export/route.ts

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

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

    const { data: exportRequest, error } = await supabase
      .from('audit_log_exports')
      .insert({
        tenant_id: profile.tenant_id,
        requested_by: user.id,
        export_type: body.exportType,
        filters: body.filters,
        date_range_start: body.dateRangeStart,
        date_range_end: body.dateRangeEnd,
        file_format: body.fileFormat,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      })
      .select()
      .single()

    if (error) throw error

    // Queue export job (background process)
    
    return NextResponse.json({ exportRequest }, { status: 202 })

  } catch (error) {
    console.error('Failed to create export:', error)
    return NextResponse.json(
      { error: 'Failed to create export' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Audit Log Page

```typescript
// src/app/tenant/audit-logs/page.tsx

'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { 
  FileText, Shield, Key, Database, 
  Download, Filter, Search 
} from 'lucide-react'
import { ActivityLogTable } from '@/components/audit/activity-log-table'
import { AuthEventsTable } from '@/components/audit/auth-events-table'
import { SecurityEventsTable } from '@/components/audit/security-events-table'
import { DataChangesTable } from '@/components/audit/data-changes-table'
import { ExportAuditDialog } from '@/components/audit/export-dialog'
import { ActivitySummaryCard } from '@/components/audit/summary-card'

export default function AuditLogPage() {
  const [activeTab, setActiveTab] = useState('activity')
  const [filters, setFilters] = useState<any>({})
  const [isExportOpen, setIsExportOpen] = useState(false)

  const { data: summary } = useQuery({
    queryKey: ['audit-summary'],
    queryFn: async () => {
      const res = await fetch('/api/tenant/audit-logs/summary?days_back=30')
      if (!res.ok) throw new Error('Failed to fetch summary')
      return res.json()
    },
  })

  const { data, isLoading } = useQuery({
    queryKey: ['audit-logs', activeTab, filters],
    queryFn: async () => {
      const params = new URLSearchParams({
        type: activeTab,
        ...filters,
      })
      const res = await fetch(`/api/tenant/audit-logs?${params}`)
      if (!res.ok) throw new Error('Failed to fetch logs')
      return res.json()
    },
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Audit Logs</h1>
          <p className="text-muted-foreground">
            Activity tracking and audit trail
          </p>
        </div>
        <Button onClick={() => setIsExportOpen(true)}>
          <Download className="h-4 w-4 mr-2" />
          Export Logs
        </Button>
      </div>

      {/* Summary */}
      {summary && (
        <div className="grid gap-4 md:grid-cols-4">
          <ActivitySummaryCard
            title="Total Activities"
            value={summary.summary.totalActivities}
            icon={FileText}
          />
          <ActivitySummaryCard
            title="Unique Users"
            value={summary.summary.uniqueUsers}
            icon={Key}
          />
          <ActivitySummaryCard
            title="Failed Actions"
            value={summary.summary.failedActions}
            icon={Shield}
          />
          <ActivitySummaryCard
            title="Critical Events"
            value={summary.summary.criticalEvents}
            icon={Database}
          />
        </div>
      )}

      {/* Logs Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="activity">Activity Logs</TabsTrigger>
          <TabsTrigger value="auth">Auth Events</TabsTrigger>
          <TabsTrigger value="security">Security Events</TabsTrigger>
          <TabsTrigger value="data_changes">Data Changes</TabsTrigger>
        </TabsList>

        <TabsContent value="activity" className="mt-6">
          <ActivityLogTable
            logs={data?.logs || []}
            pagination={data?.pagination}
            isLoading={isLoading}
          />
        </TabsContent>

        <TabsContent value="auth" className="mt-6">
          <AuthEventsTable
            events={data?.logs || []}
            pagination={data?.pagination}
            isLoading={isLoading}
          />
        </TabsContent>

        <TabsContent value="security" className="mt-6">
          <SecurityEventsTable
            events={data?.logs || []}
            pagination={data?.pagination}
            isLoading={isLoading}
          />
        </TabsContent>

        <TabsContent value="data_changes" className="mt-6">
          <DataChangesTable
            changes={data?.logs || []}
            pagination={data?.pagination}
            isLoading={isLoading}
          />
        </TabsContent>
      </Tabs>

      <ExportAuditDialog
        open={isExportOpen}
        onOpenChange={setIsExportOpen}
      />
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Comprehensive activity logging
- [x] Authentication event tracking
- [x] Security event monitoring
- [x] Data change history
- [x] Advanced filtering and search
- [x] Export functionality
- [x] Suspicious activity detection
- [x] Real-time activity feed
- [x] Compliance reporting
- [x] Session tracking
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
