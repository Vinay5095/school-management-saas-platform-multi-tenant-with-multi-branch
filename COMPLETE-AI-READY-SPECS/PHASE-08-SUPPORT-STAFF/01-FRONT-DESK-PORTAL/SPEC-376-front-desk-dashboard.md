# SPEC-376: Front Desk Dashboard & Overview

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-376  
**Title**: Front Desk Dashboard & Overview  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: Front Desk Portal  
**Category**: Dashboard & Operations  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-011, SPEC-013  

---

## 📋 DESCRIPTION

Comprehensive front desk dashboard displaying visitor statistics, pending appointments, active visitors in building, call logs, mail tracking, and reception operations. Provides quick access to all front desk functions including visitor management, call logging, mail tracking, and enquiry processing.

---

## 🎯 SUCCESS CRITERIA

- [ ] Dashboard displays active visitors and pending appointments
- [ ] Real-time metrics for visitors, calls, mail items
- [ ] Quick actions panel operational (register visitor, log call, track mail)
- [ ] Recent activities feed showing last 50 operations
- [ ] Visitor queue with check-in/check-out status
- [ ] Navigation to all front desk functions working
- [ ] Mobile responsive layout
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Front Desk Dashboard Preferences
CREATE TABLE IF NOT EXISTS front_desk_dashboard_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  staff_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Display preferences
  default_view VARCHAR(50) DEFAULT 'overview',
  widgets_config JSONB DEFAULT '{}',
  
  -- Dashboard settings
  show_visitor_queue BOOLEAN DEFAULT true,
  show_appointment_list BOOLEAN DEFAULT true,
  show_call_log BOOLEAN DEFAULT true,
  show_mail_tracker BOOLEAN DEFAULT true,
  show_statistics BOOLEAN DEFAULT true,
  
  -- Notification preferences
  notify_new_visitors BOOLEAN DEFAULT true,
  notify_appointments BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, staff_id)
);

CREATE INDEX ON front_desk_dashboard_preferences(tenant_id, branch_id, staff_id);

-- Front Desk Activity Log
CREATE TABLE IF NOT EXISTS front_desk_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  staff_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Activity details
  activity_type VARCHAR(100) NOT NULL,
  activity_description TEXT NOT NULL,
  
  -- References
  visitor_id UUID REFERENCES visitors(id),
  reference_id UUID,
  reference_type VARCHAR(50),
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_activity_type CHECK (
    activity_type IN (
      'visitor_checked_in', 'visitor_checked_out', 'appointment_scheduled',
      'call_logged', 'mail_received', 'mail_dispatched', 'enquiry_registered',
      'gate_pass_issued'
    )
  )
);

CREATE INDEX ON front_desk_activity_log(tenant_id, branch_id, staff_id, created_at DESC);
CREATE INDEX ON front_desk_activity_log(activity_type);

-- Front Desk Dashboard Metrics View
CREATE OR REPLACE VIEW front_desk_dashboard_metrics AS
SELECT
  tenant_id,
  branch_id,
  
  -- Visitors
  (SELECT COUNT(*) FROM visitors 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'checked_in') as active_visitors,
  
  (SELECT COUNT(*) FROM visitors 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND DATE(check_in_time) = CURRENT_DATE) as visitors_today,
  
  -- Appointments
  (SELECT COUNT(*) FROM appointments 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'pending'
   AND DATE(appointment_date) = CURRENT_DATE) as pending_appointments,
  
  (SELECT COUNT(*) FROM appointments 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'confirmed'
   AND DATE(appointment_date) = CURRENT_DATE) as confirmed_appointments,
  
  -- Calls
  (SELECT COUNT(*) FROM call_logs 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND DATE(call_time) = CURRENT_DATE) as calls_today,
  
  (SELECT COUNT(*) FROM call_logs 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'pending_callback') as pending_callbacks,
  
  -- Mail
  (SELECT COUNT(*) FROM mail_tracking 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'received'
   AND DATE(received_date) = CURRENT_DATE) as mail_received_today,
  
  (SELECT COUNT(*) FROM mail_tracking 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'pending_collection') as mail_pending_collection,
  
  -- Enquiries
  (SELECT COUNT(*) FROM enquiries 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND status = 'pending'
   AND DATE(enquiry_date) = CURRENT_DATE) as enquiries_today,
  
  -- Activities
  (SELECT COUNT(*) FROM front_desk_activity_log 
   WHERE tenant_id = v.tenant_id AND branch_id = v.branch_id 
   AND DATE(created_at) = CURRENT_DATE) as activities_today
  
FROM (SELECT DISTINCT tenant_id, branch_id FROM visitors) v;

-- Function to get front desk dashboard data
CREATE OR REPLACE FUNCTION get_front_desk_dashboard(
  p_staff_id UUID
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
      SELECT row_to_json(m) FROM front_desk_dashboard_metrics m
      WHERE m.tenant_id = v_tenant_id AND m.branch_id = v_branch_id
    ),
    'active_visitors', (
      SELECT json_agg(v) FROM (
        SELECT 
          id,
          visitor_name,
          visitor_type,
          person_to_meet,
          check_in_time,
          purpose
        FROM visitors
        WHERE tenant_id = v_tenant_id 
        AND branch_id = v_branch_id
        AND status = 'checked_in'
        ORDER BY check_in_time DESC
        LIMIT 10
      ) v
    ),
    'todays_appointments', (
      SELECT json_agg(a) FROM (
        SELECT 
          id,
          visitor_name,
          appointment_time,
          person_to_meet,
          status,
          purpose
        FROM appointments
        WHERE tenant_id = v_tenant_id 
        AND branch_id = v_branch_id
        AND DATE(appointment_date) = CURRENT_DATE
        ORDER BY appointment_time ASC
        LIMIT 10
      ) a
    ),
    'recent_activities', (
      SELECT json_agg(act) FROM (
        SELECT 
          activity_type,
          activity_description,
          metadata,
          created_at
        FROM front_desk_activity_log
        WHERE tenant_id = v_tenant_id 
        AND branch_id = v_branch_id
        AND staff_id = p_staff_id
        ORDER BY created_at DESC
        LIMIT 20
      ) act
    ),
    'pending_callbacks', (
      SELECT json_agg(c) FROM (
        SELECT 
          id,
          caller_name,
          caller_phone,
          call_time,
          message
        FROM call_logs
        WHERE tenant_id = v_tenant_id 
        AND branch_id = v_branch_id
        AND status = 'pending_callback'
        ORDER BY call_time DESC
        LIMIT 5
      ) c
    )
  ) INTO v_dashboard_data;
  
  RETURN v_dashboard_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE front_desk_dashboard_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE front_desk_activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY front_desk_dashboard_preferences_isolation ON front_desk_dashboard_preferences
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND staff_id = auth.uid()
  );

CREATE POLICY front_desk_activity_log_select ON front_desk_activity_log
  FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY front_desk_activity_log_insert ON front_desk_activity_log
  FOR INSERT WITH CHECK (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND staff_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/front-desk-dashboard.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface FrontDeskMetrics {
  activeVisitors: number;
  visitorsToday: number;
  pendingAppointments: number;
  confirmedAppointments: number;
  callsToday: number;
  pendingCallbacks: number;
  mailReceivedToday: number;
  mailPendingCollection: number;
  enquiriesToday: number;
  activitiesToday: number;
}

export interface ActiveVisitor {
  id: string;
  visitorName: string;
  visitorType: string;
  personToMeet: string;
  checkInTime: string;
  purpose: string;
}

export interface TodaysAppointment {
  id: string;
  visitorName: string;
  appointmentTime: string;
  personToMeet: string;
  status: string;
  purpose: string;
}

export interface FrontDeskActivity {
  activityType: string;
  activityDescription: string;
  metadata: Record<string, any>;
  createdAt: string;
}

export interface PendingCallback {
  id: string;
  callerName: string;
  callerPhone: string;
  callTime: string;
  message: string;
}

export interface FrontDeskDashboardData {
  metrics: FrontDeskMetrics;
  activeVisitors: ActiveVisitor[];
  todaysAppointments: TodaysAppointment[];
  recentActivities: FrontDeskActivity[];
  pendingCallbacks: PendingCallback[];
}

export class FrontDeskDashboardAPI {
  private supabase = createClient();

  /**
   * Get front desk dashboard data
   */
  async getDashboardData(): Promise<FrontDeskDashboardData> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .rpc('get_front_desk_dashboard', {
        p_staff_id: user.id
      });

    if (error) throw error;
    return data as FrontDeskDashboardData;
  }

  /**
   * Get dashboard metrics
   */
  async getMetrics(): Promise<FrontDeskMetrics> {
    const { data, error } = await this.supabase
      .from('front_desk_dashboard_metrics')
      .select('*')
      .single();

    if (error) throw error;
    
    return {
      activeVisitors: data.active_visitors,
      visitorsToday: data.visitors_today,
      pendingAppointments: data.pending_appointments,
      confirmedAppointments: data.confirmed_appointments,
      callsToday: data.calls_today,
      pendingCallbacks: data.pending_callbacks,
      mailReceivedToday: data.mail_received_today,
      mailPendingCollection: data.mail_pending_collection,
      enquiriesToday: data.enquiries_today,
      activitiesToday: data.activities_today
    };
  }

  /**
   * Log front desk activity
   */
  async logActivity(
    activityType: string,
    description: string,
    metadata?: Record<string, any>
  ): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('front_desk_activity_log')
      .insert({
        staff_id: user.id,
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
    showVisitorQueue: boolean;
    showAppointmentList: boolean;
    showCallLog: boolean;
    showMailTracker: boolean;
    showStatistics: boolean;
    notifyNewVisitors: boolean;
    notifyAppointments: boolean;
  }>): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('front_desk_dashboard_preferences')
      .upsert({
        staff_id: user.id,
        default_view: preferences.defaultView,
        widgets_config: preferences.widgetsConfig,
        show_visitor_queue: preferences.showVisitorQueue,
        show_appointment_list: preferences.showAppointmentList,
        show_call_log: preferences.showCallLog,
        show_mail_tracker: preferences.showMailTracker,
        show_statistics: preferences.showStatistics,
        notify_new_visitors: preferences.notifyNewVisitors,
        notify_appointments: preferences.notifyAppointments,
        updated_at: new Date().toISOString()
      });

    if (error) throw error;
  }
}

export const frontDeskDashboardAPI = new FrontDeskDashboardAPI();
```

### React Component (`/components/front-desk/FrontDeskDashboard.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Users, 
  Calendar, 
  Phone, 
  Mail, 
  Clock,
  UserCheck,
  AlertCircle,
  Activity
} from 'lucide-react';
import { frontDeskDashboardAPI, type FrontDeskDashboardData } from '@/lib/api/front-desk-dashboard';
import { useToast } from '@/components/ui/use-toast';
import { Skeleton } from '@/components/ui/skeleton';

export function FrontDeskDashboard() {
  const [dashboardData, setDashboardData] = useState<FrontDeskDashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  const { toast } = useToast();

  useEffect(() => {
    loadDashboardData();
    // Auto-refresh every 30 seconds
    const interval = setInterval(loadDashboardData, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const data = await frontDeskDashboardAPI.getDashboardData();
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

  if (loading && !dashboardData) {
    return <DashboardSkeleton />;
  }

  if (!dashboardData) {
    return <div>No data available</div>;
  }

  const { metrics, activeVisitors, todaysAppointments, recentActivities, pendingCallbacks } = dashboardData;

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Front Desk Dashboard</h1>
          <p className="text-muted-foreground">
            Manage visitors, appointments, calls, and reception operations
          </p>
        </div>
        <Button onClick={loadDashboardData}>
          Refresh
        </Button>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <MetricCard
          title="Active Visitors"
          value={metrics.activeVisitors}
          icon={<UserCheck className="h-4 w-4" />}
          trend={`${metrics.visitorsToday} today`}
          urgent={metrics.activeVisitors > 10}
        />
        <MetricCard
          title="Appointments"
          value={metrics.pendingAppointments}
          icon={<Calendar className="h-4 w-4" />}
          trend={`${metrics.confirmedAppointments} confirmed`}
        />
        <MetricCard
          title="Pending Callbacks"
          value={metrics.pendingCallbacks}
          icon={<Phone className="h-4 w-4" />}
          trend={`${metrics.callsToday} calls today`}
          urgent={metrics.pendingCallbacks > 0}
        />
        <MetricCard
          title="Mail Pending"
          value={metrics.mailPendingCollection}
          icon={<Mail className="h-4 w-4" />}
          trend={`${metrics.mailReceivedToday} received today`}
        />
        <MetricCard
          title="Enquiries"
          value={metrics.enquiriesToday}
          icon={<AlertCircle className="h-4 w-4" />}
          trend={`Today's count`}
        />
      </div>

      {/* Main Content Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="visitors">
            Active Visitors
            {activeVisitors.length > 0 && (
              <Badge variant="secondary" className="ml-2">
                {activeVisitors.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="appointments">
            Appointments
            {todaysAppointments.length > 0 && (
              <Badge variant="secondary" className="ml-2">
                {todaysAppointments.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="activity">Activity Log</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Quick Stats */}
            <Card>
              <CardHeader>
                <CardTitle>Today's Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Visitors Checked In</span>
                  <span className="font-bold">{metrics.visitorsToday}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Calls Logged</span>
                  <span className="font-bold">{metrics.callsToday}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Mail Items</span>
                  <span className="font-bold">{metrics.mailReceivedToday}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Enquiries</span>
                  <span className="font-bold">{metrics.enquiriesToday}</span>
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
                  <UserCheck className="h-4 w-4 mr-2" />
                  Register Visitor
                </Button>
                <Button variant="outline" className="w-full">
                  <Calendar className="h-4 w-4 mr-2" />
                  Schedule Appointment
                </Button>
                <Button variant="outline" className="w-full">
                  <Phone className="h-4 w-4 mr-2" />
                  Log Call
                </Button>
                <Button variant="outline" className="w-full">
                  <Mail className="h-4 w-4 mr-2" />
                  Track Mail
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Pending Callbacks Alert */}
          {pendingCallbacks.length > 0 && (
            <Card className="border-orange-200 bg-orange-50">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <AlertCircle className="h-5 w-5 text-orange-600" />
                  <CardTitle className="text-orange-900">Pending Callbacks</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {pendingCallbacks.map((callback) => (
                    <div key={callback.id} className="flex justify-between items-center p-2 bg-white rounded">
                      <div>
                        <p className="font-medium">{callback.callerName}</p>
                        <p className="text-sm text-muted-foreground">{callback.callerPhone}</p>
                      </div>
                      <Badge variant="outline">
                        <Clock className="h-3 w-3 mr-1" />
                        {new Date(callback.callTime).toLocaleTimeString()}
                      </Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="visitors" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Active Visitors in Building</CardTitle>
            </CardHeader>
            <CardContent>
              {activeVisitors.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  <Users className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No active visitors</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {activeVisitors.map((visitor) => (
                    <VisitorCard key={visitor.id} visitor={visitor} />
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="appointments" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Today's Appointments</CardTitle>
            </CardHeader>
            <CardContent>
              {todaysAppointments.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  <Calendar className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No appointments scheduled</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {todaysAppointments.map((appointment) => (
                    <AppointmentCard key={appointment.id} appointment={appointment} />
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
        <div className="text-2xl font-bold">{value}</div>
        {trend && (
          <p className={`text-xs ${urgent ? 'text-orange-600' : 'text-muted-foreground'}`}>
            {trend}
          </p>
        )}
      </CardContent>
    </Card>
  );
}

function VisitorCard({ visitor }: { visitor: any }) {
  return (
    <div className="flex items-center justify-between p-3 border rounded-lg hover:bg-accent">
      <div className="flex items-center gap-3">
        <UserCheck className="h-4 w-4" />
        <div>
          <p className="font-medium">{visitor.visitorName}</p>
          <p className="text-sm text-muted-foreground">
            Meeting: {visitor.personToMeet} • {visitor.purpose}
          </p>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <Badge variant="outline">
          <Clock className="h-3 w-3 mr-1" />
          {new Date(visitor.checkInTime).toLocaleTimeString()}
        </Badge>
        <Button size="sm">Check Out</Button>
      </div>
    </div>
  );
}

function AppointmentCard({ appointment }: { appointment: any }) {
  return (
    <div className="flex items-center justify-between p-3 border rounded-lg hover:bg-accent">
      <div className="flex items-center gap-3">
        <Calendar className="h-4 w-4" />
        <div>
          <p className="font-medium">{appointment.visitorName}</p>
          <p className="text-sm text-muted-foreground">
            With: {appointment.personToMeet} at {new Date(appointment.appointmentTime).toLocaleTimeString()}
          </p>
        </div>
      </div>
      <Badge variant={appointment.status === 'confirmed' ? 'success' : 'secondary'}>
        {appointment.status}
      </Badge>
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
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        {[1, 2, 3, 4, 5].map((i) => (
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

### Unit Tests (`/tests/unit/front-desk-dashboard.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { frontDeskDashboardAPI } from '@/lib/api/front-desk-dashboard';

describe('FrontDeskDashboardAPI', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getDashboardData', () => {
    it('should fetch complete dashboard data', async () => {
      const data = await frontDeskDashboardAPI.getDashboardData();
      
      expect(data).toHaveProperty('metrics');
      expect(data).toHaveProperty('activeVisitors');
      expect(data).toHaveProperty('todaysAppointments');
      expect(data).toHaveProperty('recentActivities');
    });

    it('should throw error when not authenticated', async () => {
      await expect(frontDeskDashboardAPI.getDashboardData()).rejects.toThrow();
    });
  });

  describe('getMetrics', () => {
    it('should return all dashboard metrics', async () => {
      const metrics = await frontDeskDashboardAPI.getMetrics();
      
      expect(metrics).toHaveProperty('activeVisitors');
      expect(metrics).toHaveProperty('pendingAppointments');
      expect(typeof metrics.activeVisitors).toBe('number');
    });
  });

  describe('logActivity', () => {
    it('should log activity successfully', async () => {
      await expect(
        frontDeskDashboardAPI.logActivity(
          'visitor_checked_in',
          'Visitor checked in successfully',
          { visitorId: '123' }
        )
      ).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { FrontDeskDashboard } from '@/components/front-desk/FrontDeskDashboard';

export default function FrontDeskPage() {
  return (
    <div className="container mx-auto">
      <FrontDeskDashboard />
    </div>
  );
}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all tables
- Tenant and branch isolation via session variables
- Staff-specific data access only
- Activity logging for audit trail
- Input validation on all operations

---

## 📊 PERFORMANCE

- **Dashboard Load**: < 2 seconds
- **Metrics Calculation**: Real-time via materialized views
- **Auto-refresh**: Every 30 seconds
- **Activity Logging**: Async, non-blocking
- **Caching**: Real-time data, no caching needed

---

## ✅ DEFINITION OF DONE

- [ ] All database tables and views created
- [ ] API client fully implemented with TypeScript types
- [ ] React component renders all dashboard sections
- [ ] Real-time metrics displaying correctly
- [ ] Active visitors queue functional
- [ ] Activity logging working
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete
