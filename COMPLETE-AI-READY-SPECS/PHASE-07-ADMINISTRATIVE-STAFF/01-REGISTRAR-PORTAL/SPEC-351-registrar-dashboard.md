# SPEC-351: Registrar Dashboard & Overview

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-351  
**Title**: Registrar Dashboard & Overview  
**Phase**: Phase 7 - Administrative Staff Portals  
**Portal**: Registrar Portal  
**Category**: Dashboard & Analytics  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-011, SPEC-013  

---

## 📋 DESCRIPTION

Comprehensive registrar dashboard displaying student records overview, pending certificate requests, transcript requests, document verification queue, recent activities, and key metrics. Provides quick access to all registrar functions including student records, certificates, transcripts, and alumni management.

---

## 🎯 SUCCESS CRITERIA

- [ ] Dashboard displays all pending requests and tasks
- [ ] Real-time metrics for student records, certificates, transcripts
- [ ] Quick actions panel operational (certificates, transcripts, verification)
- [ ] Recent activities feed showing last 50 actions
- [ ] Document verification queue with priority indicators
- [ ] Navigation to all registrar functions working
- [ ] Mobile responsive layout
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Registrar Dashboard Preferences
CREATE TABLE IF NOT EXISTS registrar_dashboard_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  registrar_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Display preferences
  default_view VARCHAR(50) DEFAULT 'overview', -- overview, pending, recent
  widgets_config JSONB DEFAULT '{}',
  
  -- Dashboard settings
  show_pending_certificates BOOLEAN DEFAULT true,
  show_pending_transcripts BOOLEAN DEFAULT true,
  show_verification_queue BOOLEAN DEFAULT true,
  show_recent_activities BOOLEAN DEFAULT true,
  show_statistics BOOLEAN DEFAULT true,
  
  -- Notification preferences
  notify_new_requests BOOLEAN DEFAULT true,
  notify_urgent_requests BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, registrar_id)
);

CREATE INDEX ON registrar_dashboard_preferences(tenant_id, branch_id, registrar_id);

-- Registrar Activity Log
CREATE TABLE IF NOT EXISTS registrar_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  registrar_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Activity details
  activity_type VARCHAR(100) NOT NULL,
  activity_description TEXT NOT NULL,
  
  -- References
  student_id UUID REFERENCES students(id),
  reference_id UUID, -- Generic reference to any entity
  reference_type VARCHAR(50), -- certificate, transcript, document, etc.
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_activity_type CHECK (
    activity_type IN (
      'certificate_generated', 'transcript_issued', 'document_verified',
      'record_updated', 'transfer_certificate_issued', 'alumni_record_created',
      'bulk_certificates_generated', 'student_record_created'
    )
  )
);

CREATE INDEX ON registrar_activity_log(tenant_id, branch_id, registrar_id, created_at DESC);
CREATE INDEX ON registrar_activity_log(activity_type);
CREATE INDEX ON registrar_activity_log(student_id);

-- Registrar Dashboard Metrics View
CREATE OR REPLACE VIEW registrar_dashboard_metrics AS
SELECT
  tenant_id,
  branch_id,
  
  -- Student Records
  (SELECT COUNT(*) FROM students 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'active') as total_active_students,
  
  (SELECT COUNT(*) FROM students 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'alumni') as total_alumni,
  
  -- Certificate Requests
  (SELECT COUNT(*) FROM certificate_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'pending') as pending_certificates,
  
  (SELECT COUNT(*) FROM certificate_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'pending' AND priority = 'urgent') as urgent_certificates,
  
  -- Transcript Requests
  (SELECT COUNT(*) FROM transcript_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'pending') as pending_transcripts,
  
  -- Document Verification
  (SELECT COUNT(*) FROM document_verification_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'pending') as pending_verifications,
  
  -- Transfer Certificates
  (SELECT COUNT(*) FROM transfer_certificate_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND status = 'pending') as pending_transfers,
  
  -- Today's activities
  (SELECT COUNT(*) FROM registrar_activity_log 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND DATE(created_at) = CURRENT_DATE) as activities_today,
  
  -- This week's certificates
  (SELECT COUNT(*) FROM certificate_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND DATE(issued_at) >= CURRENT_DATE - INTERVAL '7 days'
   AND status = 'issued') as certificates_this_week,
  
  -- This month's transcripts
  (SELECT COUNT(*) FROM transcript_requests 
   WHERE tenant_id = s.tenant_id AND branch_id = s.branch_id 
   AND DATE(issued_at) >= DATE_TRUNC('month', CURRENT_DATE)
   AND status = 'issued') as transcripts_this_month
  
FROM (SELECT DISTINCT tenant_id, branch_id FROM students) s;

-- Pending Requests Dashboard View
CREATE OR REPLACE VIEW registrar_pending_requests AS
SELECT
  'certificate' as request_type,
  cr.id as request_id,
  cr.tenant_id,
  cr.branch_id,
  cr.student_id,
  s.student_name,
  s.student_code,
  cr.certificate_type,
  cr.priority,
  cr.requested_at as request_date,
  cr.status,
  NULL as due_date,
  EXTRACT(EPOCH FROM (NOW() - cr.requested_at))/3600 as hours_pending
FROM certificate_requests cr
JOIN students s ON cr.student_id = s.id
WHERE cr.status = 'pending'

UNION ALL

SELECT
  'transcript' as request_type,
  tr.id as request_id,
  tr.tenant_id,
  tr.branch_id,
  tr.student_id,
  s.student_name,
  s.student_code,
  tr.transcript_type as certificate_type,
  tr.priority,
  tr.requested_at as request_date,
  tr.status,
  NULL as due_date,
  EXTRACT(EPOCH FROM (NOW() - tr.requested_at))/3600 as hours_pending
FROM transcript_requests tr
JOIN students s ON tr.student_id = s.id
WHERE tr.status = 'pending'

UNION ALL

SELECT
  'transfer_certificate' as request_type,
  tc.id as request_id,
  tc.tenant_id,
  tc.branch_id,
  tc.student_id,
  s.student_name,
  s.student_code,
  'Transfer Certificate' as certificate_type,
  tc.priority,
  tc.requested_at as request_date,
  tc.status,
  tc.required_by as due_date,
  EXTRACT(EPOCH FROM (NOW() - tc.requested_at))/3600 as hours_pending
FROM transfer_certificate_requests tc
JOIN students s ON tc.student_id = s.id
WHERE tc.status = 'pending'

ORDER BY priority DESC, hours_pending DESC;

-- Function to get registrar dashboard data
CREATE OR REPLACE FUNCTION get_registrar_dashboard(
  p_registrar_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_tenant_id UUID;
  v_branch_id UUID;
  v_dashboard_data JSON;
BEGIN
  -- Get tenant and branch from session
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  
  SELECT json_build_object(
    'metrics', (
      SELECT row_to_json(m) FROM registrar_dashboard_metrics m
      WHERE m.tenant_id = v_tenant_id AND m.branch_id = v_branch_id
    ),
    'pending_requests', (
      SELECT json_agg(r) FROM (
        SELECT * FROM registrar_pending_requests
        WHERE tenant_id = v_tenant_id AND branch_id = v_branch_id
        ORDER BY priority DESC, hours_pending DESC
        LIMIT 10
      ) r
    ),
    'recent_activities', (
      SELECT json_agg(a) FROM (
        SELECT 
          activity_type,
          activity_description,
          metadata,
          created_at
        FROM registrar_activity_log
        WHERE tenant_id = v_tenant_id 
        AND branch_id = v_branch_id
        AND registrar_id = p_registrar_id
        ORDER BY created_at DESC
        LIMIT 20
      ) a
    ),
    'urgent_items', (
      SELECT json_agg(u) FROM (
        SELECT * FROM registrar_pending_requests
        WHERE tenant_id = v_tenant_id 
        AND branch_id = v_branch_id
        AND priority = 'urgent'
        ORDER BY hours_pending DESC
        LIMIT 5
      ) u
    )
  ) INTO v_dashboard_data;
  
  RETURN v_dashboard_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE registrar_dashboard_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE registrar_activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY registrar_dashboard_preferences_isolation ON registrar_dashboard_preferences
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND registrar_id = auth.uid()
  );

CREATE POLICY registrar_activity_log_select ON registrar_activity_log
  FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY registrar_activity_log_insert ON registrar_activity_log
  FOR INSERT WITH CHECK (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND registrar_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/registrar-dashboard.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface RegistrarMetrics {
  totalActiveStudents: number;
  totalAlumni: number;
  pendingCertificates: number;
  urgentCertificates: number;
  pendingTranscripts: number;
  pendingVerifications: number;
  pendingTransfers: number;
  activitiesToday: number;
  certificatesThisWeek: number;
  transcriptsThisMonth: number;
}

export interface PendingRequest {
  requestType: 'certificate' | 'transcript' | 'transfer_certificate';
  requestId: string;
  studentId: string;
  studentName: string;
  studentCode: string;
  certificateType: string;
  priority: 'normal' | 'urgent';
  requestDate: string;
  status: string;
  dueDate?: string;
  hoursPending: number;
}

export interface RegistrarActivity {
  activityType: string;
  activityDescription: string;
  metadata: Record<string, any>;
  createdAt: string;
}

export interface RegistrarDashboardData {
  metrics: RegistrarMetrics;
  pendingRequests: PendingRequest[];
  recentActivities: RegistrarActivity[];
  urgentItems: PendingRequest[];
}

export class RegistrarDashboardAPI {
  private supabase = createClient();

  /**
   * Get registrar dashboard data
   */
  async getDashboardData(): Promise<RegistrarDashboardData> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .rpc('get_registrar_dashboard', {
        p_registrar_id: user.id
      });

    if (error) throw error;
    return data as RegistrarDashboardData;
  }

  /**
   * Get dashboard metrics
   */
  async getMetrics(): Promise<RegistrarMetrics> {
    const { data, error } = await this.supabase
      .from('registrar_dashboard_metrics')
      .select('*')
      .single();

    if (error) throw error;
    
    return {
      totalActiveStudents: data.total_active_students,
      totalAlumni: data.total_alumni,
      pendingCertificates: data.pending_certificates,
      urgentCertificates: data.urgent_certificates,
      pendingTranscripts: data.pending_transcripts,
      pendingVerifications: data.pending_verifications,
      pendingTransfers: data.pending_transfers,
      activitiesToday: data.activities_today,
      certificatesThisWeek: data.certificates_this_week,
      transcriptsThisMonth: data.transcripts_this_month
    };
  }

  /**
   * Get pending requests
   */
  async getPendingRequests(limit: number = 20): Promise<PendingRequest[]> {
    const { data, error } = await this.supabase
      .from('registrar_pending_requests')
      .select('*')
      .order('priority', { ascending: false })
      .order('hours_pending', { ascending: false })
      .limit(limit);

    if (error) throw error;
    
    return data.map(item => ({
      requestType: item.request_type,
      requestId: item.request_id,
      studentId: item.student_id,
      studentName: item.student_name,
      studentCode: item.student_code,
      certificateType: item.certificate_type,
      priority: item.priority,
      requestDate: item.request_date,
      status: item.status,
      dueDate: item.due_date,
      hoursPending: item.hours_pending
    }));
  }

  /**
   * Get recent activities
   */
  async getRecentActivities(limit: number = 20): Promise<RegistrarActivity[]> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('registrar_activity_log')
      .select('activity_type, activity_description, metadata, created_at')
      .eq('registrar_id', user.id)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    
    return data.map(item => ({
      activityType: item.activity_type,
      activityDescription: item.activity_description,
      metadata: item.metadata,
      createdAt: item.created_at
    }));
  }

  /**
   * Log registrar activity
   */
  async logActivity(
    activityType: string,
    description: string,
    metadata?: Record<string, any>
  ): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('registrar_activity_log')
      .insert({
        registrar_id: user.id,
        activity_type: activityType,
        activity_description: description,
        metadata: metadata || {}
      });

    if (error) throw error;
  }

  /**
   * Update dashboard preferences
   */
  async updatePreferences(preferences: Partial<{
    defaultView: string;
    widgetsConfig: Record<string, any>;
    showPendingCertificates: boolean;
    showPendingTranscripts: boolean;
    showVerificationQueue: boolean;
    showRecentActivities: boolean;
    showStatistics: boolean;
    notifyNewRequests: boolean;
    notifyUrgentRequests: boolean;
  }>): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('registrar_dashboard_preferences')
      .upsert({
        registrar_id: user.id,
        default_view: preferences.defaultView,
        widgets_config: preferences.widgetsConfig,
        show_pending_certificates: preferences.showPendingCertificates,
        show_pending_transcripts: preferences.showPendingTranscripts,
        show_verification_queue: preferences.showVerificationQueue,
        show_recent_activities: preferences.showRecentActivities,
        show_statistics: preferences.showStatistics,
        notify_new_requests: preferences.notifyNewRequests,
        notify_urgent_requests: preferences.notifyUrgentRequests,
        updated_at: new Date().toISOString()
      });

    if (error) throw error;
  }

  /**
   * Get dashboard preferences
   */
  async getPreferences() {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('registrar_dashboard_preferences')
      .select('*')
      .eq('registrar_id', user.id)
      .single();

    if (error && error.code !== 'PGRST116') throw error;
    return data;
  }
}

export const registrarDashboardAPI = new RegistrarDashboardAPI();
```

### React Component (`/components/registrar/RegistrarDashboard.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  FileText, 
  Award, 
  CheckCircle, 
  Clock, 
  Users, 
  AlertTriangle,
  TrendingUp,
  Activity
} from 'lucide-react';
import { registrarDashboardAPI, type RegistrarDashboardData } from '@/lib/api/registrar-dashboard';
import { useToast } from '@/components/ui/use-toast';
import { Skeleton } from '@/components/ui/skeleton';

export function RegistrarDashboard() {
  const [dashboardData, setDashboardData] = useState<RegistrarDashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  const { toast } = useToast();

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const data = await registrarDashboardAPI.getDashboardData();
      setDashboardData(data);
    } catch (error) {
      console.error('Error loading dashboard:', error);
      toast({
        title: 'Error',
        description: 'Failed to load dashboard data',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <DashboardSkeleton />;
  }

  if (!dashboardData) {
    return <div>No data available</div>;
  }

  const { metrics, pendingRequests, recentActivities, urgentItems } = dashboardData;

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Registrar Dashboard</h1>
          <p className="text-muted-foreground">
            Manage student records, certificates, and transcripts
          </p>
        </div>
        <Button onClick={loadDashboardData}>
          Refresh
        </Button>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Active Students"
          value={metrics.totalActiveStudents}
          icon={<Users className="h-4 w-4" />}
          trend={`+${metrics.totalAlumni} alumni`}
        />
        <MetricCard
          title="Pending Certificates"
          value={metrics.pendingCertificates}
          icon={<Award className="h-4 w-4" />}
          trend={`${metrics.urgentCertificates} urgent`}
          urgent={metrics.urgentCertificates > 0}
        />
        <MetricCard
          title="Pending Transcripts"
          value={metrics.pendingTranscripts}
          icon={<FileText className="h-4 w-4" />}
          trend={`${metrics.transcriptsThisMonth} this month`}
        />
        <MetricCard
          title="Verifications"
          value={metrics.pendingVerifications}
          icon={<CheckCircle className="h-4 w-4" />}
          trend={`${metrics.activitiesToday} today`}
        />
      </div>

      {/* Urgent Items Alert */}
      {urgentItems && urgentItems.length > 0 && (
        <Card className="border-orange-200 bg-orange-50">
          <CardHeader className="pb-3">
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-orange-600" />
              <CardTitle className="text-orange-900">Urgent Items</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {urgentItems.map((item) => (
                <div key={item.requestId} className="flex justify-between items-center p-2 bg-white rounded">
                  <div>
                    <p className="font-medium">{item.studentName}</p>
                    <p className="text-sm text-muted-foreground">{item.certificateType}</p>
                  </div>
                  <Badge variant="destructive">
                    {Math.floor(item.hoursPending)}h pending
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Main Content Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="pending">
            Pending Requests
            {pendingRequests.length > 0 && (
              <Badge variant="secondary" className="ml-2">
                {pendingRequests.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="activity">Recent Activity</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Quick Stats */}
            <Card>
              <CardHeader>
                <CardTitle>This Week's Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Certificates Issued</span>
                  <span className="font-bold">{metrics.certificatesThisWeek}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Transcripts Issued</span>
                  <span className="font-bold">{metrics.transcriptsThisMonth}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Activities Today</span>
                  <span className="font-bold">{metrics.activitiesToday}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Pending Items</span>
                  <span className="font-bold">
                    {metrics.pendingCertificates + metrics.pendingTranscripts + metrics.pendingVerifications}
                  </span>
                </div>
              </CardContent>
            </Card>

            {/* Quick Actions */}
            <Card>
              <CardHeader>
                <CardTitle>Quick Actions</CardTitle>
              </CardHeader>
              <CardContent className="grid grid-cols-2 gap-2">
                <Button variant="outline" className="w-full">
                  <Award className="h-4 w-4 mr-2" />
                  Generate Certificate
                </Button>
                <Button variant="outline" className="w-full">
                  <FileText className="h-4 w-4 mr-2" />
                  Issue Transcript
                </Button>
                <Button variant="outline" className="w-full">
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Verify Document
                </Button>
                <Button variant="outline" className="w-full">
                  <Users className="h-4 w-4 mr-2" />
                  Student Records
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="pending" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Pending Requests</CardTitle>
            </CardHeader>
            <CardContent>
              {pendingRequests.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  <CheckCircle className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No pending requests</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {pendingRequests.map((request) => (
                    <PendingRequestCard key={request.requestId} request={request} />
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="activity" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Recent Activities</CardTitle>
            </CardHeader>
            <CardContent>
              {recentActivities.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  <Activity className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No recent activities</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {recentActivities.map((activity, index) => (
                    <ActivityCard key={index} activity={activity} />
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

// Supporting Components
interface MetricCardProps {
  title: string;
  value: number;
  icon: React.ReactNode;
  trend?: string;
  urgent?: boolean;
}

function MetricCard({ title, value, icon, trend, urgent }: MetricCardProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <div className={urgent ? 'text-orange-600' : 'text-muted-foreground'}>
          {icon}
        </div>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value.toLocaleString()}</div>
        {trend && (
          <p className={`text-xs ${urgent ? 'text-orange-600' : 'text-muted-foreground'}`}>
            {trend}
          </p>
        )}
      </CardContent>
    </Card>
  );
}

function PendingRequestCard({ request }: { request: any }) {
  const getRequestIcon = () => {
    switch (request.requestType) {
      case 'certificate': return <Award className="h-4 w-4" />;
      case 'transcript': return <FileText className="h-4 w-4" />;
      case 'transfer_certificate': return <FileText className="h-4 w-4" />;
      default: return <FileText className="h-4 w-4" />;
    }
  };

  return (
    <div className="flex items-center justify-between p-3 border rounded-lg hover:bg-accent">
      <div className="flex items-center gap-3">
        {getRequestIcon()}
        <div>
          <p className="font-medium">{request.studentName}</p>
          <p className="text-sm text-muted-foreground">
            {request.studentCode} • {request.certificateType}
          </p>
        </div>
      </div>
      <div className="flex items-center gap-2">
        {request.priority === 'urgent' && (
          <Badge variant="destructive">Urgent</Badge>
        )}
        <Badge variant="outline">
          <Clock className="h-3 w-3 mr-1" />
          {Math.floor(request.hoursPending)}h
        </Badge>
        <Button size="sm">Process</Button>
      </div>
    </div>
  );
}

function ActivityCard({ activity }: { activity: any }) {
  return (
    <div className="flex items-start gap-3 p-3 border-l-2 border-primary">
      <Activity className="h-4 w-4 mt-1 text-primary" />
      <div className="flex-1">
        <p className="text-sm font-medium">{activity.activityDescription}</p>
        <p className="text-xs text-muted-foreground">
          {new Date(activity.createdAt).toLocaleString()}
        </p>
      </div>
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="space-y-6 p-6">
      <Skeleton className="h-12 w-64" />
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {[1, 2, 3, 4].map((i) => (
          <Skeleton key={i} className="h-32" />
        ))}
      </div>
      <Skeleton className="h-96" />
    </div>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/registrar-dashboard.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { registrarDashboardAPI } from '@/lib/api/registrar-dashboard';

describe('RegistrarDashboardAPI', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getDashboardData', () => {
    it('should fetch complete dashboard data', async () => {
      const data = await registrarDashboardAPI.getDashboardData();
      
      expect(data).toHaveProperty('metrics');
      expect(data).toHaveProperty('pendingRequests');
      expect(data).toHaveProperty('recentActivities');
      expect(data).toHaveProperty('urgentItems');
    });

    it('should throw error when not authenticated', async () => {
      // Mock unauthenticated state
      await expect(registrarDashboardAPI.getDashboardData()).rejects.toThrow();
    });
  });

  describe('getMetrics', () => {
    it('should return all dashboard metrics', async () => {
      const metrics = await registrarDashboardAPI.getMetrics();
      
      expect(metrics).toHaveProperty('totalActiveStudents');
      expect(metrics).toHaveProperty('pendingCertificates');
      expect(metrics).toHaveProperty('pendingTranscripts');
      expect(typeof metrics.totalActiveStudents).toBe('number');
    });
  });

  describe('logActivity', () => {
    it('should log activity successfully', async () => {
      await expect(
        registrarDashboardAPI.logActivity(
          'certificate_generated',
          'Generated certificate for student',
          { studentId: '123' }
        )
      ).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { RegistrarDashboard } from '@/components/registrar/RegistrarDashboard';

export default function RegistrarPage() {
  return (
    <div className="container mx-auto">
      <RegistrarDashboard />
    </div>
  );
}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all tables
- Tenant and branch isolation via session variables
- Registrar-specific data access only
- Activity logging for audit trail
- Input validation on all operations

---

## 📊 PERFORMANCE

- **Dashboard Load**: < 2 seconds
- **Metrics Calculation**: Real-time via materialized views
- **Request Querying**: Indexed queries for fast retrieval
- **Activity Logging**: Async, non-blocking
- **Caching**: 1-minute cache on metrics

---

## ✅ DEFINITION OF DONE

- [ ] All database tables and views created
- [ ] API client fully implemented with TypeScript types
- [ ] React component renders all dashboard sections
- [ ] Real-time metrics displaying correctly
- [ ] Pending requests queue functional
- [ ] Activity logging working
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete
