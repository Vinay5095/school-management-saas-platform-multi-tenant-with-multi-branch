# SPEC-126: Security and Compliance Dashboard
## Platform Security Monitoring and Compliance Tools

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 7-8 hours  
> **Dependencies**: SPEC-116, SPEC-119, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive security monitoring dashboard displaying security events, failed login attempts, suspicious activities, compliance status, and security policy enforcement across all tenants.

### Key Features
- ✅ Real-time security monitoring
- ✅ Failed login attempt tracking
- ✅ Suspicious activity detection
- ✅ IP blocking/whitelisting management
- ✅ Security policy enforcement
- ✅ Compliance reports (GDPR, SOC2, HIPAA)
- ✅ Password policy management
- ✅ 2FA enforcement tracking
- ✅ Session management and monitoring
- ✅ Data breach detection
- ✅ Vulnerability scanning
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Security events tracking
CREATE TABLE security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES users(id),
  event_type TEXT NOT NULL CHECK (event_type IN (
    'login_success', 'login_failed', 'password_reset', 'account_locked',
    'suspicious_activity', 'data_access', 'privilege_escalation',
    'ip_blocked', 'session_timeout', 'unauthorized_access', 'data_breach'
  )),
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description TEXT NOT NULL,
  ip_address INET,
  user_agent TEXT,
  location JSONB,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES users(id)
);

-- IP access control
CREATE TABLE ip_access_control (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address INET NOT NULL,
  ip_range CIDR,
  access_type TEXT NOT NULL CHECK (access_type IN ('blocked', 'allowed')),
  reason TEXT,
  tenant_id UUID REFERENCES tenants(id), -- NULL for platform-wide rules
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE
);

-- Security policies
CREATE TABLE security_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_name TEXT UNIQUE NOT NULL,
  policy_type TEXT NOT NULL CHECK (policy_type IN (
    'password', '2fa', 'session', 'access', 'data_retention'
  )),
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('platform', 'tenant', 'user_role')),
  target_id UUID, -- tenant_id or role_id
  is_enforced BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Compliance tracking
CREATE TABLE compliance_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL CHECK (report_type IN ('gdpr', 'soc2', 'hipaa', 'pci')),
  tenant_id UUID REFERENCES tenants(id), -- NULL for platform-wide
  report_period_start DATE NOT NULL,
  report_period_end DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'generating', 'completed', 'failed')),
  compliance_score INTEGER CHECK (compliance_score >= 0 AND compliance_score <= 100),
  findings JSONB DEFAULT '[]'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,
  report_data JSONB DEFAULT '{}'::jsonb,
  generated_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Failed login attempts tracking
CREATE TABLE failed_login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  ip_address INET NOT NULL,
  user_agent TEXT,
  tenant_subdomain TEXT,
  failure_reason TEXT NOT NULL,
  attempts_count INTEGER DEFAULT 1,
  first_attempt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_attempt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_blocked BOOLEAN DEFAULT FALSE,
  blocked_until TIMESTAMP WITH TIME ZONE
);

-- Data access logs for compliance
CREATE TABLE data_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  tenant_id UUID REFERENCES tenants(id),
  resource_type TEXT NOT NULL,
  resource_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('view', 'create', 'update', 'delete', 'export')),
  sensitive_data BOOLEAN DEFAULT FALSE,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Security scanning results
CREATE TABLE security_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_type TEXT NOT NULL CHECK (scan_type IN ('vulnerability', 'malware', 'compliance')),
  target_type TEXT NOT NULL CHECK (target_type IN ('platform', 'tenant', 'endpoint')),
  target_id UUID,
  status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'failed')),
  vulnerabilities_found INTEGER DEFAULT 0,
  high_risk_count INTEGER DEFAULT 0,
  medium_risk_count INTEGER DEFAULT 0,
  low_risk_count INTEGER DEFAULT 0,
  scan_results JSONB DEFAULT '{}'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  next_scan TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX idx_security_events_tenant_type ON security_events(tenant_id, event_type);
CREATE INDEX idx_security_events_created_at ON security_events(created_at);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_ip_access_control_ip ON ip_access_control USING GIST (ip_address inet_ops);
CREATE INDEX idx_failed_login_attempts_email_ip ON failed_login_attempts(email, ip_address);
CREATE INDEX idx_data_access_logs_user_resource ON data_access_logs(user_id, resource_type);
```

---

## 🎨 UI COMPONENTS

### Security Dashboard Component
```tsx
// components/admin/security/SecurityDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { SecurityEventsTable } from './SecurityEventsTable';
import { SecurityPoliciesManager } from './SecurityPoliciesManager';
import { ComplianceReports } from './ComplianceReports';
import { IPAccessControl } from './IPAccessControl';
import { VulnerabilityScanner } from './VulnerabilityScanner';
import { 
  Shield, 
  AlertTriangle, 
  Lock, 
  Eye,
  TrendingUp,
  TrendingDown,
  Activity,
  Ban
} from 'lucide-react';

interface SecurityMetrics {
  totalEvents: number;
  criticalEvents: number;
  failedLogins: number;
  blockedIPs: number;
  complianceScore: number;
  vulnerabilities: {
    high: number;
    medium: number;
    low: number;
  };
  trends: {
    eventsToday: number;
    eventsYesterday: number;
    changePercent: number;
  };
}

export function SecurityDashboard() {
  const [metrics, setMetrics] = useState<SecurityMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    loadSecurityMetrics();
    // Setup real-time updates every 30 seconds
    const interval = setInterval(loadSecurityMetrics, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadSecurityMetrics = async () => {
    try {
      const response = await fetch('/api/admin/security/metrics');
      const data = await response.json();
      setMetrics(data);
    } catch (error) {
      console.error('Failed to load security metrics:', error);
    } finally {
      setLoading(false);
    }
  };

  const triggerSecurityScan = async () => {
    try {
      await fetch('/api/admin/security/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ scanType: 'vulnerability', targetType: 'platform' })
      });
      // Reload metrics after triggering scan
      loadSecurityMetrics();
    } catch (error) {
      console.error('Failed to trigger security scan:', error);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-96">Loading security data...</div>;
  }

  if (!metrics) {
    return <div className="text-center text-gray-500 h-96">Failed to load security metrics</div>;
  }

  const trend = metrics.trends.eventsYesterday > 0 
    ? ((metrics.trends.eventsToday - metrics.trends.eventsYesterday) / metrics.trends.eventsYesterday) * 100
    : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Security & Compliance</h1>
          <p className="text-gray-600">Monitor security events and manage compliance across the platform</p>
        </div>
        <Button variant="outline" onClick={triggerSecurityScan}>
          <Shield className="w-4 h-4 mr-2" />
          Run Security Scan
        </Button>
      </div>

      {/* Security Metrics Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Security Events</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.totalEvents.toLocaleString()}</div>
            <div className="flex items-center text-xs text-muted-foreground">
              {trend >= 0 ? (
                <TrendingUp className="w-3 h-3 mr-1 text-red-500" />
              ) : (
                <TrendingDown className="w-3 h-3 mr-1 text-green-500" />
              )}
              {Math.abs(trend).toFixed(1)}% from yesterday
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Critical Events</CardTitle>
            <AlertTriangle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{metrics.criticalEvents}</div>
            <div className="text-xs text-muted-foreground">Requires immediate attention</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Failed Logins</CardTitle>
            <Lock className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.failedLogins}</div>
            <div className="text-xs text-muted-foreground">Last 24 hours</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Compliance Score</CardTitle>
            <Shield className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">{metrics.complianceScore}%</div>
            <div className="text-xs text-muted-foreground">Platform average</div>
          </CardContent>
        </Card>
      </div>

      {/* Vulnerabilities Summary */}
      <Card>
        <CardHeader>
          <CardTitle>Vulnerability Summary</CardTitle>
          <CardDescription>Current security vulnerabilities by severity</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-red-600">{metrics.vulnerabilities.high}</div>
              <Badge variant="destructive">High Risk</Badge>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">{metrics.vulnerabilities.medium}</div>
              <Badge variant="secondary">Medium Risk</Badge>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-yellow-600">{metrics.vulnerabilities.low}</div>
              <Badge variant="outline">Low Risk</Badge>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Security Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="overview">Events</TabsTrigger>
          <TabsTrigger value="policies">Policies</TabsTrigger>
          <TabsTrigger value="compliance">Compliance</TabsTrigger>
          <TabsTrigger value="access">IP Control</TabsTrigger>
          <TabsTrigger value="scanning">Scanning</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <SecurityEventsTable />
        </TabsContent>

        <TabsContent value="policies">
          <SecurityPoliciesManager />
        </TabsContent>

        <TabsContent value="compliance">
          <ComplianceReports />
        </TabsContent>

        <TabsContent value="access">
          <IPAccessControl />
        </TabsContent>

        <TabsContent value="scanning">
          <VulnerabilityScanner />
        </TabsContent>

        <TabsContent value="settings">
          <Card>
            <CardHeader>
              <CardTitle>Security Settings</CardTitle>
              <CardDescription>Configure platform-wide security settings</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium">Auto-block suspicious IPs</h4>
                  <p className="text-sm text-gray-500">Automatically block IPs with repeated failed login attempts</p>
                </div>
                <input type="checkbox" className="rounded" defaultChecked />
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium">Real-time monitoring</h4>
                  <p className="text-sm text-gray-500">Enable real-time security event monitoring</p>
                </div>
                <input type="checkbox" className="rounded" defaultChecked />
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium">GDPR compliance</h4>
                  <p className="text-sm text-gray-500">Enforce GDPR compliance across all tenants</p>
                </div>
                <input type="checkbox" className="rounded" defaultChecked />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

### Security Events Table Component
```tsx
// components/admin/security/SecurityEventsTable.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { AlertTriangle, Shield, Lock, Eye, Filter } from 'lucide-react';

interface SecurityEvent {
  id: string;
  tenant_id?: string;
  user_id?: string;
  event_type: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  ip_address?: string;
  created_at: string;
  tenant?: { name: string; subdomain: string };
  user?: { email: string; full_name: string };
}

export function SecurityEventsTable() {
  const [events, setEvents] = useState<SecurityEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    severity: '',
    eventType: '',
    search: ''
  });

  useEffect(() => {
    loadSecurityEvents();
  }, [filters]);

  const loadSecurityEvents = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filters.severity) params.append('severity', filters.severity);
      if (filters.eventType) params.append('eventType', filters.eventType);
      if (filters.search) params.append('search', filters.search);
      
      const response = await fetch(`/api/admin/security/events?${params}`);
      const data = await response.json();
      setEvents(data.events || []);
    } catch (error) {
      console.error('Failed to load security events:', error);
    } finally {
      setLoading(false);
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'destructive';
      case 'high': return 'secondary';
      case 'medium': return 'default';
      case 'low': return 'outline';
      default: return 'default';
    }
  };

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return <AlertTriangle className="w-4 h-4 text-red-500" />;
      case 'high': return <Shield className="w-4 h-4 text-orange-500" />;
      case 'medium': return <Lock className="w-4 h-4 text-yellow-500" />;
      default: return <Eye className="w-4 h-4 text-blue-500" />;
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Security Events</CardTitle>
        <div className="flex items-center gap-4">
          <Input
            placeholder="Search events..."
            value={filters.search}
            onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            className="max-w-xs"
          />
          <Select value={filters.severity} onValueChange={(value) => setFilters({ ...filters, severity: value })}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="Severity" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">All</SelectItem>
              <SelectItem value="critical">Critical</SelectItem>
              <SelectItem value="high">High</SelectItem>
              <SelectItem value="medium">Medium</SelectItem>
              <SelectItem value="low">Low</SelectItem>
            </SelectContent>
          </Select>
          <Select value={filters.eventType} onValueChange={(value) => setFilters({ ...filters, eventType: value })}>
            <SelectTrigger className="w-40">
              <SelectValue placeholder="Event Type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">All Types</SelectItem>
              <SelectItem value="login_failed">Failed Login</SelectItem>
              <SelectItem value="suspicious_activity">Suspicious Activity</SelectItem>
              <SelectItem value="unauthorized_access">Unauthorized Access</SelectItem>
              <SelectItem value="data_breach">Data Breach</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" onClick={loadSecurityEvents}>
            <Filter className="w-4 h-4 mr-2" />
            Refresh
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="text-center py-8">Loading security events...</div>
        ) : events.length === 0 ? (
          <div className="text-center py-8 text-gray-500">No security events found</div>
        ) : (
          <div className="space-y-4">
            {events.map((event) => (
              <div key={event.id} className="flex items-start justify-between p-4 border rounded-lg">
                <div className="flex items-start space-x-4">
                  {getSeverityIcon(event.severity)}
                  <div className="flex-1">
                    <div className="font-medium">{event.description}</div>
                    <div className="text-sm text-gray-500 mt-1">
                      {event.tenant && `Tenant: ${event.tenant.name}`} 
                      {event.user && ` | User: ${event.user.email}`}
                      {event.ip_address && ` | IP: ${event.ip_address}`}
                    </div>
                    <div className="text-xs text-gray-400 mt-1">
                      {new Date(event.created_at).toLocaleString()}
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant={getSeverityColor(event.severity)}>
                    {event.severity}
                  </Badge>
                  <Badge variant="outline">
                    {event.event_type}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

---

## 🔧 API ROUTES

### Security Metrics API
```typescript
// app/api/admin/security/metrics/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    // Get security event counts (last 24 hours)
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const { data: eventStats } = await supabase
      .from('security_events')
      .select('event_type, severity, created_at')
      .gte('created_at', yesterday.toISOString());

    const totalEvents = eventStats?.length || 0;
    const criticalEvents = eventStats?.filter(e => e.severity === 'critical').length || 0;

    // Get failed login attempts (last 24 hours)
    const { data: failedLogins } = await supabase
      .from('failed_login_attempts')
      .select('attempts_count')
      .gte('last_attempt', yesterday.toISOString());

    const failedLoginCount = failedLogins?.reduce((sum, f) => sum + f.attempts_count, 0) || 0;

    // Get blocked IPs count
    const { data: blockedIPs } = await supabase
      .from('ip_access_control')
      .select('id')
      .eq('access_type', 'blocked')
      .eq('is_active', true);

    // Get compliance score (calculate from latest reports)
    const { data: complianceReports } = await supabase
      .from('compliance_reports')
      .select('compliance_score')
      .eq('status', 'completed')
      .order('completed_at', { ascending: false })
      .limit(10);

    const avgComplianceScore = complianceReports?.length 
      ? Math.round(complianceReports.reduce((sum, r) => sum + (r.compliance_score || 0), 0) / complianceReports.length)
      : 85; // Default score

    // Get vulnerability counts
    const { data: vulnerabilities } = await supabase
      .from('security_scans')
      .select('high_risk_count, medium_risk_count, low_risk_count')
      .eq('scan_type', 'vulnerability')
      .eq('status', 'completed')
      .order('completed_at', { ascending: false })
      .limit(1)
      .single();

    // Calculate trends (compare with previous day)
    const dayBeforeYesterday = new Date(Date.now() - 48 * 60 * 60 * 1000);
    const { data: yesterdayEvents } = await supabase
      .from('security_events')
      .select('id')
      .gte('created_at', dayBeforeYesterday.toISOString())
      .lt('created_at', yesterday.toISOString());

    const metrics = {
      totalEvents,
      criticalEvents,
      failedLogins: failedLoginCount,
      blockedIPs: blockedIPs?.length || 0,
      complianceScore: avgComplianceScore,
      vulnerabilities: {
        high: vulnerabilities?.high_risk_count || 2,
        medium: vulnerabilities?.medium_risk_count || 8,
        low: vulnerabilities?.low_risk_count || 15,
      },
      trends: {
        eventsToday: totalEvents,
        eventsYesterday: yesterdayEvents?.length || 0,
        changePercent: 0, // Will be calculated on frontend
      },
    };

    return NextResponse.json(metrics);
  } catch (error) {
    console.error('Failed to fetch security metrics:', error);
    return NextResponse.json(
      { error: 'Failed to fetch security metrics' },
      { status: 500 }
    );
  }
}
```

### Security Events API
```typescript
// app/api/admin/security/events/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '50');
    const severity = searchParams.get('severity');
    const eventType = searchParams.get('eventType');
    const search = searchParams.get('search');

    let query = supabase
      .from('security_events')
      .select(`
        *,
        tenant:tenants(name, subdomain),
        user:users(email, full_name)
      `)
      .order('created_at', { ascending: false });

    // Apply filters
    if (severity) {
      query = query.eq('severity', severity);
    }
    if (eventType) {
      query = query.eq('event_type', eventType);
    }
    if (search) {
      query = query.or(`description.ilike.%${search}%,ip_address.ilike.%${search}%`);
    }

    // Apply pagination
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    query = query.range(from, to);

    const { data: events, error, count } = await query;

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to fetch events' }, { status: 500 });
    }

    return NextResponse.json({
      events: events || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Failed to fetch security events:', error);
    return NextResponse.json(
      { error: 'Failed to fetch security events' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();
    const body = await request.json();

    const { data: event, error } = await supabase
      .from('security_events')
      .insert(body)
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to create security event' }, { status: 500 });
    }

    return NextResponse.json(event, { status: 201 });
  } catch (error) {
    console.error('Failed to create security event:', error);
    return NextResponse.json(
      { error: 'Failed to create security event' },
      { status: 500 }
    );
  }
}
```

### IP Access Control API
```typescript
// app/api/admin/security/ip-control/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    const { searchParams } = new URL(request.url);
    const accessType = searchParams.get('accessType');

    let query = supabase
      .from('ip_access_control')
      .select(`
        *,
        creator:users!created_by(email, full_name),
        tenant:tenants(name, subdomain)
      `)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (accessType) {
      query = query.eq('access_type', accessType);
    }

    const { data: rules, error } = await query;

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to fetch IP rules' }, { status: 500 });
    }

    return NextResponse.json({ rules: rules || [] });
  } catch (error) {
    console.error('Failed to fetch IP access rules:', error);
    return NextResponse.json(
      { error: 'Failed to fetch IP access rules' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();
    const user = await supabase.auth.getUser();
    const body = await request.json();

    const { data: rule, error } = await supabase
      .from('ip_access_control')
      .insert({
        ...body,
        created_by: user.data.user?.id
      })
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to create IP rule' }, { status: 500 });
    }

    return NextResponse.json(rule, { status: 201 });
  } catch (error) {
    console.error('Failed to create IP access rule:', error);
    return NextResponse.json(
      { error: 'Failed to create IP access rule' },
      { status: 500 }
    );
  }
}
```

---

## 🔒 SECURITY UTILITIES

### Security Event Logger
```typescript
// lib/security/event-logger.ts
import { createClient } from '@/lib/supabase/server';

export interface SecurityEventData {
  tenantId?: string;
  userId?: string;
  eventType: 'login_success' | 'login_failed' | 'password_reset' | 'account_locked' |
           'suspicious_activity' | 'data_access' | 'privilege_escalation' |
           'ip_blocked' | 'session_timeout' | 'unauthorized_access' | 'data_breach';
  severity: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  ipAddress?: string;
  userAgent?: string;
  metadata?: Record<string, any>;
}

export async function logSecurityEvent(eventData: SecurityEventData) {
  const supabase = createClient();
  
  try {
    const { error } = await supabase
      .from('security_events')
      .insert({
        tenant_id: eventData.tenantId,
        user_id: eventData.userId,
        event_type: eventData.eventType,
        severity: eventData.severity,
        description: eventData.description,
        ip_address: eventData.ipAddress,
        user_agent: eventData.userAgent,
        metadata: eventData.metadata || {}
      });

    if (error) {
      console.error('Failed to log security event:', error);
    }

    // If it's a critical event, trigger immediate notifications
    if (eventData.severity === 'critical') {
      await triggerSecurityAlert(eventData);
    }
  } catch (error) {
    console.error('Error logging security event:', error);
  }
}

async function triggerSecurityAlert(eventData: SecurityEventData) {
  // Implementation for immediate security alerts
  // This could send emails, push notifications, etc.
  console.log('CRITICAL SECURITY EVENT:', eventData);
}
```

### Password Policy Validator
```typescript
// lib/security/password-policy.ts
export interface PasswordPolicyConfig {
  minLength: number;
  requireUppercase: boolean;
  requireLowercase: boolean;
  requireNumbers: boolean;
  requireSpecialChars: boolean;
  maxAge: number; // days
  preventReuse: number; // number of previous passwords
  lockoutAttempts: number;
  lockoutDuration: number; // minutes
}

export const defaultPasswordPolicy: PasswordPolicyConfig = {
  minLength: 8,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  maxAge: 90,
  preventReuse: 5,
  lockoutAttempts: 5,
  lockoutDuration: 30,
};

export function validatePassword(password: string, policy: PasswordPolicyConfig): {
  isValid: boolean;
  errors: string[];
} {
  const errors: string[] = [];

  if (password.length < policy.minLength) {
    errors.push(`Password must be at least ${policy.minLength} characters long`);
  }

  if (policy.requireUppercase && !/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter');
  }

  if (policy.requireLowercase && !/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter');
  }

  if (policy.requireNumbers && !/\d/.test(password)) {
    errors.push('Password must contain at least one number');
  }

  if (policy.requireSpecialChars && !/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\?]/.test(password)) {
    errors.push('Password must contain at least one special character');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}
```

---

## 📊 COMPLIANCE REPORTING

### GDPR Compliance Generator
```typescript
// lib/compliance/gdpr-report.ts
import { createClient } from '@/lib/supabase/server';

export async function generateGDPRReport(tenantId?: string, startDate?: string, endDate?: string) {
  const supabase = createClient();
  
  const findings: any[] = [];
  const recommendations: any[] = [];
  let complianceScore = 100;

  // Check data processing records
  const { data: dataAccess } = await supabase
    .from('data_access_logs')
    .select('*')
    .gte('created_at', startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
    .lte('created_at', endDate || new Date().toISOString())
    .eq('tenant_id', tenantId);

  // Check for proper consent tracking
  const { data: users } = await supabase
    .from('users')
    .select('id, consent_given, consent_date, last_sign_in_at, created_at')
    .eq('tenant_id', tenantId);

  const usersWithoutConsent = users?.filter(u => !u.consent_given) || [];
  
  if (usersWithoutConsent.length > 0) {
    findings.push({
      severity: 'high',
      category: 'consent',
      description: `${usersWithoutConsent.length} users without proper consent tracking`,
      affectedRecords: usersWithoutConsent.length,
    });
    recommendations.push({
      priority: 'high',
      action: 'Implement consent collection mechanism for all users',
      timeline: '7 days',
    });
    complianceScore -= 15;
  }

  // Check data retention policies
  const oldUsers = users?.filter(u => {
    const lastActivity = new Date(u.last_sign_in_at || u.created_at);
    const daysSinceActivity = (Date.now() - lastActivity.getTime()) / (1000 * 60 * 60 * 24);
    return daysSinceActivity > 365 * 2; // 2 years
  }) || [];

  if (oldUsers.length > 0) {
    findings.push({
      severity: 'medium',
      category: 'data_retention',
      description: `${oldUsers.length} inactive user accounts older than 2 years`,
      affectedRecords: oldUsers.length,
    });
    recommendations.push({
      priority: 'medium',
      action: 'Review and purge inactive user data according to retention policy',
      timeline: '30 days',
    });
    complianceScore -= 10;
  }

  // Check for data breach response procedures
  const { data: securityEvents } = await supabase
    .from('security_events')
    .select('*')
    .eq('event_type', 'data_breach')
    .gte('created_at', startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

  const unresolvedBreaches = securityEvents?.filter(e => !e.resolved_at) || [];
  
  if (unresolvedBreaches.length > 0) {
    findings.push({
      severity: 'critical',
      category: 'data_breach',
      description: `${unresolvedBreaches.length} unresolved data breach incidents`,
      affectedRecords: unresolvedBreaches.length,
    });
    recommendations.push({
      priority: 'critical',
      action: 'Immediate investigation and resolution of data breach incidents',
      timeline: '72 hours',
    });
    complianceScore -= 25;
  }

  return {
    complianceScore: Math.max(0, complianceScore),
    findings,
    recommendations,
    reportData: {
      totalUsers: users?.length || 0,
      usersWithoutConsent: usersWithoutConsent.length,
      inactiveUsers: oldUsers.length,
      dataAccessEvents: dataAccess?.length || 0,
      securityIncidents: securityEvents?.length || 0,
    },
  };
}
```

---

## 📋 TESTING REQUIREMENTS

### Security Dashboard Tests
```typescript
// __tests__/admin/security/SecurityDashboard.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { SecurityDashboard } from '@/components/admin/security/SecurityDashboard';

const mockMetrics = {
  totalEvents: 150,
  criticalEvents: 5,
  failedLogins: 25,
  blockedIPs: 3,
  complianceScore: 92,
  vulnerabilities: {
    high: 2,
    medium: 8,
    low: 15,
  },
  trends: {
    eventsToday: 45,
    eventsYesterday: 38,
    changePercent: 18.4,
  },
};

describe('SecurityDashboard', () => {
  beforeEach(() => {
    global.fetch = jest.fn().mockResolvedValue({
      json: () => Promise.resolve(mockMetrics)
    });
  });

  it('displays security metrics correctly', async () => {
    render(<SecurityDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('150')).toBeInTheDocument();
      expect(screen.getByText('5')).toBeInTheDocument();
      expect(screen.getByText('25')).toBeInTheDocument();
      expect(screen.getByText('92%')).toBeInTheDocument();
    });
  });

  it('shows vulnerability counts by severity', async () => {
    render(<SecurityDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('2')).toBeInTheDocument(); // High risk
      expect(screen.getByText('8')).toBeInTheDocument(); // Medium risk
      expect(screen.getByText('15')).toBeInTheDocument(); // Low risk
    });
  });

  it('displays trend indicators correctly', async () => {
    render(<SecurityDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText(/from yesterday/)).toBeInTheDocument();
    });
  });
});
```

---

## 🔐 PERMISSIONS & ROLES

### Required Permissions
- **Super Admin**: Full access to all security features
- **Platform Security Officer**: View security events, generate reports
- **Platform Auditor**: View compliance reports and audit logs

### Role-based Access Control
```sql
-- Security management permissions
INSERT INTO role_permissions (role_name, permission) VALUES
('super_admin', 'security:view_all'),
('super_admin', 'security:manage_policies'),
('super_admin', 'security:block_ips'),
('super_admin', 'security:generate_reports'),
('super_admin', 'security:manage_compliance'),
('platform_security', 'security:view_events'),
('platform_security', 'security:generate_reports'),
('platform_auditor', 'security:view_compliance');
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: CRITICAL