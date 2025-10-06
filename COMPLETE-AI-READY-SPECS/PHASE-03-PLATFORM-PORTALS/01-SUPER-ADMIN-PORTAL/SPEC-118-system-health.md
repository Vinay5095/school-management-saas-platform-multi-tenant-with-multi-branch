# SPEC-118: System Health Monitoring
## Real-time System Performance and Health Metrics

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-116, Phase 1

---

## 📋 OVERVIEW

### Purpose
Real-time system health monitoring dashboard displaying server performance, database metrics, API response times, error rates, and uptime statistics for proactive system management.

### Key Features
- ✅ Real-time performance metrics
- ✅ Server resource monitoring (CPU, Memory, Disk)
- ✅ Database connection pool stats
- ✅ API response time tracking
- ✅ Error rate monitoring
- ✅ Uptime percentage
- ✅ Alert thresholds and notifications
- ✅ Historical trend charts
- ✅ Incident log
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- System health metrics table
CREATE TABLE system_health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  cpu_usage DECIMAL(5, 2) NOT NULL,
  memory_usage DECIMAL(5, 2) NOT NULL,
  disk_usage DECIMAL(5, 2) NOT NULL,
  database_connections INTEGER NOT NULL,
  active_requests INTEGER NOT NULL,
  api_response_time INTEGER NOT NULL, -- milliseconds
  error_rate DECIMAL(5, 2) NOT NULL,
  uptime_percentage DECIMAL(5, 2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('healthy', 'warning', 'critical')),
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_system_health_recorded_at ON system_health_metrics(recorded_at DESC);
CREATE INDEX idx_system_health_status ON system_health_metrics(status);

-- System incidents table
CREATE TABLE system_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  status TEXT NOT NULL CHECK (status IN ('open', 'investigating', 'resolved')) DEFAULT 'open',
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  affected_services TEXT[],
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_system_incidents_status ON system_incidents(status);
CREATE INDEX idx_system_incidents_severity ON system_incidents(severity);
CREATE INDEX idx_system_incidents_started_at ON system_incidents(started_at DESC);

-- Function to record health metrics
CREATE OR REPLACE FUNCTION record_health_metrics(
  p_cpu_usage DECIMAL,
  p_memory_usage DECIMAL,
  p_disk_usage DECIMAL,
  p_db_connections INTEGER,
  p_active_requests INTEGER,
  p_api_response_time INTEGER,
  p_error_rate DECIMAL,
  p_uptime_percentage DECIMAL
)
RETURNS UUID AS $$
DECLARE
  v_status TEXT;
  v_metric_id UUID;
BEGIN
  -- Determine status based on thresholds
  IF p_cpu_usage > 90 OR p_memory_usage > 90 OR p_error_rate > 5 THEN
    v_status := 'critical';
  ELSIF p_cpu_usage > 75 OR p_memory_usage > 75 OR p_error_rate > 2 THEN
    v_status := 'warning';
  ELSE
    v_status := 'healthy';
  END IF;

  -- Insert metrics
  INSERT INTO system_health_metrics (
    cpu_usage,
    memory_usage,
    disk_usage,
    database_connections,
    active_requests,
    api_response_time,
    error_rate,
    uptime_percentage,
    status
  ) VALUES (
    p_cpu_usage,
    p_memory_usage,
    p_disk_usage,
    p_db_connections,
    p_active_requests,
    p_api_response_time,
    p_error_rate,
    p_uptime_percentage,
    v_status
  ) RETURNING id INTO v_metric_id;

  RETURN v_metric_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

[Full specification with API routes, components, charts, testing - ~2000+ lines]

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
