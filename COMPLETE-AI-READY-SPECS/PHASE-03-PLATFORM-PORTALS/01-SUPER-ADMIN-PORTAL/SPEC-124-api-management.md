# SPEC-124: API Management & Rate Limiting
## Platform API Key Management and Usage Monitoring

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-116, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive API management system for super admins to generate API keys, monitor usage, enforce rate limits, track API metrics, and manage API access across all tenants.

### Key Features
- ✅ API key generation and management
- ✅ Rate limiting per key/tenant
- ✅ Usage tracking and analytics
- ✅ API endpoint monitoring
- ✅ Quota management
- ✅ IP whitelisting
- ✅ Webhook management
- ✅ API versioning control
- ✅ Error rate monitoring
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- API keys table
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  key_name TEXT NOT NULL,
  key_hash TEXT UNIQUE NOT NULL,
  key_prefix TEXT NOT NULL,
  
  -- Permissions
  scopes TEXT[] NOT NULL DEFAULT ARRAY['read']::TEXT[],
  allowed_ips INET[],
  allowed_origins TEXT[],
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  
  -- Rate limiting
  rate_limit_per_minute INTEGER DEFAULT 60,
  rate_limit_per_hour INTEGER DEFAULT 1000,
  rate_limit_per_day INTEGER DEFAULT 10000,
  
  -- Usage tracking
  total_requests BIGINT DEFAULT 0,
  total_errors BIGINT DEFAULT 0,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES auth.users(id),
  revoked_reason TEXT,
  
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_active ON api_keys(is_active);

-- API usage logs
CREATE TABLE api_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID REFERENCES api_keys(id) ON DELETE SET NULL,
  tenant_id UUID REFERENCES tenants(id),
  
  -- Request details
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER NOT NULL,
  
  -- Client details
  ip_address INET,
  user_agent TEXT,
  origin TEXT,
  
  -- Error details
  error_type TEXT,
  error_message TEXT,
  
  -- Timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_usage_key ON api_usage_logs(api_key_id);
CREATE INDEX idx_api_usage_tenant ON api_usage_logs(tenant_id);
CREATE INDEX idx_api_usage_created ON api_usage_logs(created_at DESC);
CREATE INDEX idx_api_usage_endpoint ON api_usage_logs(endpoint);
CREATE INDEX idx_api_usage_status ON api_usage_logs(status_code);

-- API rate limit tracking
CREATE TABLE api_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID NOT NULL REFERENCES api_keys(id) ON DELETE CASCADE,
  window_type TEXT NOT NULL CHECK (window_type IN ('minute', 'hour', 'day')),
  window_start TIMESTAMPTZ NOT NULL,
  request_count INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(api_key_id, window_type, window_start)
);

CREATE INDEX idx_rate_limits_key ON api_rate_limits(api_key_id);
CREATE INDEX idx_rate_limits_window ON api_rate_limits(window_start);

-- API endpoints registry
CREATE TABLE api_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  path TEXT UNIQUE NOT NULL,
  method TEXT NOT NULL,
  description TEXT,
  required_scopes TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_public BOOLEAN DEFAULT false,
  is_deprecated BOOLEAN DEFAULT false,
  rate_limit_override INTEGER,
  version TEXT DEFAULT 'v1',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_endpoints_path ON api_endpoints(path);
CREATE INDEX idx_api_endpoints_deprecated ON api_endpoints(is_deprecated);

-- Webhooks
CREATE TABLE webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  webhook_url TEXT NOT NULL,
  secret_key TEXT NOT NULL,
  
  -- Events
  events TEXT[] NOT NULL,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMPTZ,
  last_success_at TIMESTAMPTZ,
  last_failure_at TIMESTAMPTZ,
  failure_count INTEGER DEFAULT 0,
  
  -- Headers
  custom_headers JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhooks_tenant ON webhooks(tenant_id);
CREATE INDEX idx_webhooks_active ON webhooks(is_active);

-- Webhook delivery log
CREATE TABLE webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'delivered', 'failed')),
  status_code INTEGER,
  response_body TEXT,
  error_message TEXT,
  attempt_count INTEGER DEFAULT 0,
  next_retry_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhook_deliveries_webhook ON webhook_deliveries(webhook_id);
CREATE INDEX idx_webhook_deliveries_status ON webhook_deliveries(status);
CREATE INDEX idx_webhook_deliveries_created ON webhook_deliveries(created_at DESC);

-- Function to generate API key
CREATE OR REPLACE FUNCTION generate_api_key()
RETURNS TEXT AS $$
DECLARE
  v_key TEXT;
BEGIN
  v_key := 'sk_' || encode(gen_random_bytes(32), 'hex');
  RETURN v_key;
END;
$$ LANGUAGE plpgsql;

-- Function to check rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_api_key_id UUID,
  p_window_type TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_limit INTEGER;
  v_current_count INTEGER;
BEGIN
  -- Calculate window start
  v_window_start := CASE p_window_type
    WHEN 'minute' THEN date_trunc('minute', NOW())
    WHEN 'hour' THEN date_trunc('hour', NOW())
    WHEN 'day' THEN date_trunc('day', NOW())
  END;

  -- Get limit
  SELECT 
    CASE p_window_type
      WHEN 'minute' THEN rate_limit_per_minute
      WHEN 'hour' THEN rate_limit_per_hour
      WHEN 'day' THEN rate_limit_per_day
    END INTO v_limit
  FROM api_keys
  WHERE id = p_api_key_id;

  -- Get current count
  SELECT COALESCE(request_count, 0) INTO v_current_count
  FROM api_rate_limits
  WHERE api_key_id = p_api_key_id
    AND window_type = p_window_type
    AND window_start = v_window_start;

  -- Check if under limit
  IF v_current_count < v_limit THEN
    -- Increment counter
    INSERT INTO api_rate_limits (api_key_id, window_type, window_start, request_count)
    VALUES (p_api_key_id, p_window_type, v_window_start, 1)
    ON CONFLICT (api_key_id, window_type, window_start)
    DO UPDATE SET request_count = api_rate_limits.request_count + 1;
    
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log API usage
CREATE OR REPLACE FUNCTION log_api_usage(
  p_api_key_id UUID,
  p_tenant_id UUID,
  p_endpoint TEXT,
  p_method TEXT,
  p_status_code INTEGER,
  p_response_time_ms INTEGER,
  p_ip_address INET DEFAULT NULL,
  p_error_type TEXT DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO api_usage_logs (
    api_key_id,
    tenant_id,
    endpoint,
    method,
    status_code,
    response_time_ms,
    ip_address,
    error_type,
    error_message
  ) VALUES (
    p_api_key_id,
    p_tenant_id,
    p_endpoint,
    p_method,
    p_status_code,
    p_response_time_ms,
    p_ip_address,
    p_error_type,
    p_error_message
  ) RETURNING id INTO v_log_id;

  -- Update API key stats
  UPDATE api_keys
  SET
    total_requests = total_requests + 1,
    total_errors = total_errors + CASE WHEN p_status_code >= 400 THEN 1 ELSE 0 END,
    last_used_at = NOW()
  WHERE id = p_api_key_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get API usage statistics
CREATE OR REPLACE FUNCTION get_api_usage_stats(
  p_tenant_id UUID DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  p_to_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  total_requests BIGINT,
  successful_requests BIGINT,
  failed_requests BIGINT,
  avg_response_time DECIMAL,
  error_rate DECIMAL,
  top_endpoints JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE status_code < 400) as successful_requests,
    COUNT(*) FILTER (WHERE status_code >= 400) as failed_requests,
    AVG(response_time_ms)::DECIMAL as avg_response_time,
    (COUNT(*) FILTER (WHERE status_code >= 400)::DECIMAL / NULLIF(COUNT(*), 0) * 100) as error_rate,
    (
      SELECT jsonb_agg(jsonb_build_object(
        'endpoint', endpoint,
        'count', count
      ))
      FROM (
        SELECT endpoint, COUNT(*) as count
        FROM api_usage_logs
        WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
          AND created_at BETWEEN p_from_date AND p_to_date
        GROUP BY endpoint
        ORDER BY count DESC
        LIMIT 10
      ) top
    ) as top_endpoints
  FROM api_usage_logs
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
    AND created_at BETWEEN p_from_date AND p_to_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY super_admin_api_keys ON api_keys
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY tenant_own_api_keys ON api_keys
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY super_admin_usage_logs ON api_usage_logs
  FOR SELECT USING (
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
// src/types/api-management.ts

export interface ApiKey {
  id: string
  tenantId: string
  keyName: string
  keyHash: string
  keyPrefix: string
  scopes: string[]
  allowedIps?: string[]
  allowedOrigins?: string[]
  isActive: boolean
  expiresAt?: string
  lastUsedAt?: string
  rateLimitPerMinute: number
  rateLimitPerHour: number
  rateLimitPerDay: number
  totalRequests: number
  totalErrors: number
  createdBy?: string
  createdAt: string
  updatedAt: string
  revokedAt?: string
  revokedBy?: string
  revokedReason?: string
  metadata?: Record<string, any>
}

export interface ApiUsageLog {
  id: string
  apiKeyId?: string
  tenantId?: string
  endpoint: string
  method: string
  statusCode: number
  responseTimeMs: number
  ipAddress?: string
  userAgent?: string
  origin?: string
  errorType?: string
  errorMessage?: string
  createdAt: string
}

export interface ApiUsageStats {
  totalRequests: number
  successfulRequests: number
  failedRequests: number
  avgResponseTime: number
  errorRate: number
  topEndpoints: Array<{
    endpoint: string
    count: number
  }>
}

export interface Webhook {
  id: string
  tenantId: string
  webhookUrl: string
  secretKey: string
  events: string[]
  isActive: boolean
  lastTriggeredAt?: string
  lastSuccessAt?: string
  lastFailureAt?: string
  failureCount: number
  customHeaders?: Record<string, string>
  createdAt: string
  updatedAt: string
}

export interface ApiKeyCreateData {
  tenantId: string
  keyName: string
  scopes: string[]
  rateLimitPerMinute?: number
  rateLimitPerHour?: number
  rateLimitPerDay?: number
  expiresAt?: string
  allowedIps?: string[]
  allowedOrigins?: string[]
}
```

### API Routes

```typescript
// src/app/api/platform/api-keys/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { createHash } from 'crypto'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const tenantId = searchParams.get('tenantId')

    let query = supabase
      .from('api_keys')
      .select('*, tenant:tenants(name)')
      .order('created_at', { ascending: false })

    if (tenantId) {
      query = query.eq('tenant_id', tenantId)
    }

    const { data: apiKeys, error } = await query

    if (error) throw error

    // Remove sensitive data
    const sanitized = apiKeys?.map(key => ({
      ...key,
      keyHash: undefined,
    }))

    return NextResponse.json({ apiKeys: sanitized })

  } catch (error) {
    console.error('Failed to fetch API keys:', error)
    return NextResponse.json(
      { error: 'Failed to fetch API keys' },
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

    // Generate API key
    const { data: rawKey } = await supabase.rpc('generate_api_key')
    const keyHash = createHash('sha256').update(rawKey).digest('hex')
    const keyPrefix = rawKey.substring(0, 10)

    const { data: apiKey, error } = await supabase
      .from('api_keys')
      .insert({
        ...body,
        key_hash: keyHash,
        key_prefix: keyPrefix,
        created_by: user.id,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({
      apiKey: {
        ...apiKey,
        plainKey: rawKey, // Only returned once
      },
    }, { status: 201 })

  } catch (error) {
    console.error('Failed to create API key:', error)
    return NextResponse.json(
      { error: 'Failed to create API key' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/api-keys/[id]/revoke/route.ts

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

    const { data, error } = await supabase
      .from('api_keys')
      .update({
        is_active: false,
        revoked_at: new Date().toISOString(),
        revoked_by: user.id,
        revoked_reason: reason,
      })
      .eq('id', params.id)
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ apiKey: data })

  } catch (error) {
    console.error('Failed to revoke API key:', error)
    return NextResponse.json(
      { error: 'Failed to revoke API key' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/api-usage/stats/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const tenantId = searchParams.get('tenantId')
    const fromDate = searchParams.get('fromDate')
    const toDate = searchParams.get('toDate')

    const { data: stats, error } = await supabase
      .rpc('get_api_usage_stats', {
        p_tenant_id: tenantId,
        p_from_date: fromDate,
        p_to_date: toDate,
      })
      .single()

    if (error) throw error

    return NextResponse.json({ stats })

  } catch (error) {
    console.error('Failed to fetch usage stats:', error)
    return NextResponse.json(
      { error: 'Failed to fetch usage stats' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### API Management Dashboard

```typescript
// src/components/platform/api-management-dashboard.tsx

'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogDescription,
  DialogHeader, DialogTitle, DialogTrigger
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Table, TableBody, TableCell, TableHead,
  TableHeader, TableRow
} from '@/components/ui/table'
import { Key, TrendingUp, Activity, Copy, Trash } from 'lucide-react'
import { format } from 'date-fns'
import { useToast } from '@/hooks/use-toast'

export function ApiManagementDashboard() {
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const queryClient = useQueryClient()
  const { toast } = useToast()

  const { data: apiKeysData } = useQuery({
    queryKey: ['api-keys'],
    queryFn: async () => {
      const res = await fetch('/api/platform/api-keys')
      if (!res.ok) throw new Error('Failed to fetch API keys')
      return res.json()
    },
  })

  const { data: statsData } = useQuery({
    queryKey: ['api-usage-stats'],
    queryFn: async () => {
      const res = await fetch('/api/platform/api-usage/stats')
      if (!res.ok) throw new Error('Failed to fetch stats')
      return res.json()
    },
  })

  const revokeMutation = useMutation({
    mutationFn: async ({ keyId, reason }: { keyId: string; reason: string }) => {
      const res = await fetch(`/api/platform/api-keys/${keyId}/revoke`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      })
      if (!res.ok) throw new Error('Failed to revoke key')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['api-keys'] })
      toast({
        title: 'Success',
        description: 'API key revoked successfully',
      })
    },
  })

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
    toast({
      title: 'Copied',
      description: 'API key copied to clipboard',
    })
  }

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Total Requests</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {statsData?.stats?.totalRequests?.toLocaleString() || 0}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Success Rate</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {(100 - (statsData?.stats?.errorRate || 0)).toFixed(1)}%
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Avg Response Time</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {statsData?.stats?.avgResponseTime?.toFixed(0) || 0}ms
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Active Keys</CardTitle>
            <Key className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {apiKeysData?.apiKeys?.filter((k: any) => k.isActive).length || 0}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* API Keys Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Key className="h-5 w-5" />
              API Keys
            </CardTitle>
            <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
              <DialogTrigger asChild>
                <Button>Create API Key</Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Create New API Key</DialogTitle>
                  <DialogDescription>
                    Generate a new API key for a tenant
                  </DialogDescription>
                </DialogHeader>
                {/* Create form would go here */}
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Tenant</TableHead>
                <TableHead>Prefix</TableHead>
                <TableHead>Scopes</TableHead>
                <TableHead>Requests</TableHead>
                <TableHead>Last Used</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {apiKeysData?.apiKeys?.map((key: any) => (
                <TableRow key={key.id}>
                  <TableCell className="font-medium">{key.keyName}</TableCell>
                  <TableCell>{key.tenant?.name}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <code className="text-xs bg-muted px-2 py-1 rounded">
                        {key.keyPrefix}...
                      </code>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => copyToClipboard(key.keyPrefix)}
                      >
                        <Copy className="h-3 w-3" />
                      </Button>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      {key.scopes.map((scope: string) => (
                        <Badge key={scope} variant="outline" className="text-xs">
                          {scope}
                        </Badge>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell>{key.totalRequests?.toLocaleString()}</TableCell>
                  <TableCell>
                    {key.lastUsedAt
                      ? format(new Date(key.lastUsedAt), 'MMM dd, HH:mm')
                      : 'Never'}
                  </TableCell>
                  <TableCell>
                    <Badge variant={key.isActive ? 'default' : 'secondary'}>
                      {key.isActive ? 'Active' : 'Revoked'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {key.isActive && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() =>
                          revokeMutation.mutate({
                            keyId: key.id,
                            reason: 'Manually revoked',
                          })
                        }
                      >
                        <Trash className="h-4 w-4 text-red-500" />
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] API key generation and management
- [x] Rate limiting enforcement
- [x] Usage tracking and analytics
- [x] API endpoint monitoring
- [x] Quota management
- [x] IP whitelisting
- [x] Webhook management
- [x] Key revocation workflow
- [x] Usage statistics dashboard
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
