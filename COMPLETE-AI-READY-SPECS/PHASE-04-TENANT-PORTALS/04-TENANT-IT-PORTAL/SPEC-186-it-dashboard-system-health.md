# SPEC-186: IT Dashboard & System Health

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-186  
**Title**: IT Dashboard & System Health Monitoring  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant IT Portal  
**Category**: Monitoring & Analytics  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-010  

---

## 📋 DESCRIPTION

Comprehensive IT dashboard with real-time system health monitoring, active user sessions, API usage analytics, storage utilization, database metrics, incident tracking, and system alerts.

---

## 🎯 SUCCESS CRITERIA

- [ ] System health dashboard operational
- [ ] Real-time metrics displayed
- [ ] User session tracking working
- [ ] API usage monitored
- [ ] Storage utilization tracked
- [ ] Alert system functional
- [ ] Performance metrics available
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- System Health Metrics
CREATE TABLE IF NOT EXISTS system_health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Timestamp
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Database metrics
  database_size_mb NUMERIC(12,2),
  table_count INTEGER,
  active_connections INTEGER,
  max_connections INTEGER,
  
  -- Storage metrics
  storage_used_mb NUMERIC(12,2),
  storage_limit_mb NUMERIC(12,2),
  storage_percentage NUMERIC(5,2),
  
  -- User metrics
  active_user_sessions INTEGER,
  total_registered_users INTEGER,
  
  -- API metrics
  api_requests_last_hour INTEGER,
  api_errors_last_hour INTEGER,
  avg_response_time_ms NUMERIC(8,2),
  
  -- Performance
  cpu_usage_percentage NUMERIC(5,2),
  memory_usage_percentage NUMERIC(5,2),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON system_health_metrics(tenant_id, recorded_at DESC);

-- API Usage Logs
CREATE TABLE IF NOT EXISTS api_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Request details
  endpoint VARCHAR(500) NOT NULL,
  method VARCHAR(10) NOT NULL,
  
  -- User
  user_id UUID REFERENCES auth.users(id),
  
  -- Response
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER NOT NULL,
  
  -- Request/Response size
  request_size_bytes INTEGER,
  response_size_bytes INTEGER,
  
  -- IP and user agent
  ip_address VARCHAR(50),
  user_agent TEXT,
  
  -- Error details
  error_message TEXT,
  
  -- Timestamp
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON api_usage_logs(tenant_id, requested_at DESC);
CREATE INDEX ON api_usage_logs(endpoint, requested_at DESC);
CREATE INDEX ON api_usage_logs(status_code);

-- Active User Sessions
CREATE TABLE IF NOT EXISTS active_user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Session details
  session_token VARCHAR(500) UNIQUE NOT NULL,
  device_type VARCHAR(50),
  browser VARCHAR(100),
  os VARCHAR(100),
  
  -- Location
  ip_address VARCHAR(50),
  location_city VARCHAR(100),
  location_country VARCHAR(100),
  
  -- Activity
  login_at TIMESTAMP WITH TIME ZONE NOT NULL,
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  logout_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON active_user_sessions(tenant_id, is_active);
CREATE INDEX ON active_user_sessions(user_id);

-- System Alerts
CREATE TABLE IF NOT EXISTS system_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Alert details
  alert_type VARCHAR(50) NOT NULL, -- error, warning, info, critical
  alert_category VARCHAR(100), -- database, storage, api, security, performance
  alert_title VARCHAR(200) NOT NULL,
  alert_message TEXT NOT NULL,
  
  -- Severity
  severity VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
  
  -- Source
  source_component VARCHAR(100),
  
  -- Status
  status VARCHAR(50) DEFAULT 'open', -- open, acknowledged, resolved, ignored
  
  -- Assignment
  assigned_to UUID REFERENCES auth.users(id),
  
  -- Resolution
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  resolution_notes TEXT,
  
  -- Notification
  notification_sent BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_severity CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  CONSTRAINT valid_status CHECK (status IN ('open', 'acknowledged', 'resolved', 'ignored'))
);

CREATE INDEX ON system_alerts(tenant_id, status);
CREATE INDEX ON system_alerts(alert_category, severity);

-- Scheduled Jobs
CREATE TABLE IF NOT EXISTS scheduled_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Job details
  job_name VARCHAR(200) NOT NULL,
  job_type VARCHAR(100), -- backup, cleanup, report_generation, data_sync
  job_description TEXT,
  
  -- Schedule
  schedule_cron VARCHAR(100) NOT NULL,
  next_run_at TIMESTAMP WITH TIME ZONE,
  last_run_at TIMESTAMP WITH TIME ZONE,
  
  -- Status
  is_enabled BOOLEAN DEFAULT true,
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, running, completed, failed
  
  -- Execution
  last_execution_duration_ms INTEGER,
  last_execution_status VARCHAR(50),
  last_execution_error TEXT,
  
  -- Stats
  total_executions INTEGER DEFAULT 0,
  successful_executions INTEGER DEFAULT 0,
  failed_executions INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON scheduled_jobs(tenant_id, is_enabled);

-- Function to record system health
CREATE OR REPLACE FUNCTION record_system_health(
  p_tenant_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_metric_id UUID;
  v_db_size NUMERIC;
  v_storage_used NUMERIC;
  v_active_sessions INTEGER;
BEGIN
  -- Get database size (simplified)
  SELECT pg_database_size(current_database()) / (1024 * 1024) INTO v_db_size;
  
  -- Count active sessions
  SELECT COUNT(*) INTO v_active_sessions
  FROM active_user_sessions
  WHERE tenant_id = p_tenant_id
  AND is_active = true;
  
  -- Insert metrics
  INSERT INTO system_health_metrics (
    tenant_id,
    database_size_mb,
    active_user_sessions,
    recorded_at
  ) VALUES (
    p_tenant_id,
    v_db_size,
    v_active_sessions,
    NOW()
  ) RETURNING id INTO v_metric_id;
  
  RETURN v_metric_id;
END;
$$ LANGUAGE plpgsql;

-- Materialized view for API analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS api_usage_analytics AS
SELECT
  tenant_id,
  DATE_TRUNC('hour', requested_at) as hour,
  endpoint,
  COUNT(*) as request_count,
  AVG(response_time_ms) as avg_response_time,
  COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_count,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_response_time
FROM api_usage_logs
WHERE requested_at >= NOW() - INTERVAL '7 days'
GROUP BY tenant_id, DATE_TRUNC('hour', requested_at), endpoint;

CREATE INDEX ON api_usage_analytics(tenant_id, hour DESC);

-- Enable RLS
ALTER TABLE system_health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_jobs ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/system-health.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface SystemHealthMetrics {
  databaseSizeMb: number;
  activeUserSessions: number;
  apiRequestsLastHour: number;
  storagePercentage: number;
}

export interface SystemAlert {
  id: string;
  alertType: string;
  alertTitle: string;
  alertMessage: string;
  severity: string;
  status: string;
  createdAt: string;
}

export class SystemHealthAPI {
  private supabase = createClient();

  async getCurrentHealthMetrics(tenantId: string): Promise<SystemHealthMetrics> {
    const { data, error } = await this.supabase
      .from('system_health_metrics')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('recorded_at', { ascending: false })
      .limit(1)
      .single();

    if (error) throw error;

    return {
      databaseSizeMb: data.database_size_mb,
      activeUserSessions: data.active_user_sessions,
      apiRequestsLastHour: data.api_requests_last_hour || 0,
      storagePercentage: data.storage_percentage || 0,
    };
  }

  async getActiveUserSessions(tenantId: string) {
    const { data, error } = await this.supabase
      .from('active_user_sessions')
      .select(`
        *,
        user:auth.users(email)
      `)
      .eq('tenant_id', tenantId)
      .eq('is_active', true)
      .order('last_activity_at', { ascending: false });

    if (error) throw error;

    return (data || []).map(session => ({
      id: session.id,
      userEmail: session.user.email,
      deviceType: session.device_type,
      browser: session.browser,
      ipAddress: session.ip_address,
      loginAt: session.login_at,
      lastActivityAt: session.last_activity_at,
    }));
  }

  async getAPIUsageStats(params: {
    tenantId: string;
    hours?: number;
  }) {
    const hoursAgo = params.hours || 24;
    const startTime = new Date(Date.now() - hoursAgo * 60 * 60 * 1000);

    const { data, error } = await this.supabase
      .from('api_usage_logs')
      .select('endpoint, status_code, response_time_ms')
      .eq('tenant_id', params.tenantId)
      .gte('requested_at', startTime.toISOString());

    if (error) throw error;

    // Calculate statistics
    const totalRequests = data.length;
    const errorCount = data.filter(log => log.status_code >= 400).length;
    const avgResponseTime =
      data.reduce((sum, log) => sum + log.response_time_ms, 0) / totalRequests;

    // Group by endpoint
    const endpointStats = data.reduce((acc: any, log) => {
      if (!acc[log.endpoint]) {
        acc[log.endpoint] = { count: 0, errors: 0 };
      }
      acc[log.endpoint].count++;
      if (log.status_code >= 400) {
        acc[log.endpoint].errors++;
      }
      return acc;
    }, {});

    return {
      totalRequests,
      errorCount,
      errorRate: (errorCount / totalRequests) * 100,
      avgResponseTime,
      endpointStats,
    };
  }

  async getSystemAlerts(params: {
    tenantId: string;
    status?: string;
    severity?: string;
  }): Promise<SystemAlert[]> {
    let query = this.supabase
      .from('system_alerts')
      .select('*')
      .eq('tenant_id', params.tenantId);

    if (params.status) {
      query = query.eq('status', params.status);
    }

    if (params.severity) {
      query = query.eq('severity', params.severity);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map(alert => ({
      id: alert.id,
      alertType: alert.alert_type,
      alertTitle: alert.alert_title,
      alertMessage: alert.alert_message,
      severity: alert.severity,
      status: alert.status,
      createdAt: alert.created_at,
    }));
  }

  async createSystemAlert(params: {
    tenantId: string;
    alertType: string;
    alertCategory: string;
    alertTitle: string;
    alertMessage: string;
    severity: string;
  }): Promise<SystemAlert> {
    const { data, error } = await this.supabase
      .from('system_alerts')
      .insert({
        tenant_id: params.tenantId,
        alert_type: params.alertType,
        alert_category: params.alertCategory,
        alert_title: params.alertTitle,
        alert_message: params.alertMessage,
        severity: params.severity,
        status: 'open',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      alertType: data.alert_type,
      alertTitle: data.alert_title,
      alertMessage: data.alert_message,
      severity: data.severity,
      status: data.status,
      createdAt: data.created_at,
    };
  }

  async resolveAlert(params: {
    alertId: string;
    resolutionNotes: string;
  }): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('system_alerts')
      .update({
        status: 'resolved',
        resolved_at: new Date().toISOString(),
        resolved_by: user?.id,
        resolution_notes: params.resolutionNotes,
      })
      .eq('id', params.alertId);

    if (error) throw error;
  }

  async getScheduledJobs(tenantId: string) {
    const { data, error } = await this.supabase
      .from('scheduled_jobs')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('next_run_at');

    if (error) throw error;

    return (data || []).map(job => ({
      id: job.id,
      jobName: job.job_name,
      jobType: job.job_type,
      scheduleCron: job.schedule_cron,
      nextRunAt: job.next_run_at,
      lastRunAt: job.last_run_at,
      isEnabled: job.is_enabled,
      status: job.status,
      successfulExecutions: job.successful_executions,
      failedExecutions: job.failed_executions,
    }));
  }

  async recordSystemHealth(tenantId: string) {
    const { data, error } = await this.supabase.rpc('record_system_health', {
      p_tenant_id: tenantId,
    });

    if (error) throw error;
    return data;
  }
}

export const systemHealthAPI = new SystemHealthAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { SystemHealthAPI } from '../system-health';

describe('SystemHealthAPI', () => {
  it('retrieves current health metrics', async () => {
    const api = new SystemHealthAPI();
    const metrics = await api.getCurrentHealthMetrics('test-tenant');

    expect(metrics).toHaveProperty('databaseSizeMb');
    expect(metrics).toHaveProperty('activeUserSessions');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Health dashboard working
- [ ] Metrics displayed
- [ ] Sessions tracked
- [ ] API usage monitored
- [ ] Alerts functional
- [ ] Jobs scheduled
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-187 (System Integration)  
**Time**: 4 hours  
**AI-Ready**: 100%
