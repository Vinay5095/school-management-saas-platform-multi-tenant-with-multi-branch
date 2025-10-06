# SPEC-377: Visitor Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-377  
**Title**: Visitor Management System  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: Front Desk Portal  
**Category**: Visitor Operations  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 8 hours  
**Dependencies**: SPEC-011, SPEC-013, SPEC-376  

---

## 📋 DESCRIPTION

Complete visitor management system with registration, check-in/check-out tracking, badge printing, photo capture, purpose documentation, and host notification. Maintains comprehensive visitor history and security compliance with vehicle registration and blacklist management.

---

## 🎯 SUCCESS CRITERIA

- [ ] Visitor registration (walk-in and pre-registered) functional
- [ ] Check-in/check-out tracking with timestamps operational
- [ ] Visitor badge printing with photo working
- [ ] Photo capture integration functional
- [ ] Purpose and host documentation complete
- [ ] Automatic host notification (SMS/Email) working
- [ ] Visitor history and analytics accessible
- [ ] Security clearance tracking operational
- [ ] Vehicle registration functional
- [ ] Blacklist management working
- [ ] Mobile responsive layout
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Visitor Types
CREATE TABLE IF NOT EXISTS visitor_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  type_name VARCHAR(100) NOT NULL,
  description TEXT,
  requires_approval BOOLEAN DEFAULT false,
  max_duration_hours INTEGER DEFAULT 24,
  color_code VARCHAR(7) DEFAULT '#3B82F6',
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, type_name)
);

CREATE INDEX ON visitor_types(tenant_id, branch_id, is_active);

-- Visitors
CREATE TABLE IF NOT EXISTS visitors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Visitor Information
  visitor_name VARCHAR(255) NOT NULL,
  visitor_phone VARCHAR(20),
  visitor_email VARCHAR(255),
  visitor_company VARCHAR(255),
  visitor_type_id UUID REFERENCES visitor_types(id),
  
  -- Visit Details
  person_to_meet VARCHAR(255) NOT NULL,
  person_to_meet_id UUID REFERENCES auth.users(id),
  department VARCHAR(100),
  purpose TEXT NOT NULL,
  
  -- Check-in/out
  check_in_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expected_checkout_time TIMESTAMP WITH TIME ZONE,
  check_out_time TIMESTAMP WITH TIME ZONE,
  status VARCHAR(50) DEFAULT 'checked_in',
  
  -- Documents
  id_proof_type VARCHAR(50),
  id_proof_number VARCHAR(100),
  photo_url TEXT,
  badge_number VARCHAR(50),
  
  -- Vehicle
  vehicle_number VARCHAR(50),
  vehicle_type VARCHAR(50),
  
  -- Security
  is_pre_registered BOOLEAN DEFAULT false,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  security_clearance_level VARCHAR(50) DEFAULT 'standard',
  
  -- Metadata
  remarks TEXT,
  items_carried TEXT,
  metadata JSONB DEFAULT '{}',
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (
    status IN ('pre_registered', 'checked_in', 'checked_out', 'rejected', 'expired')
  )
);

CREATE INDEX ON visitors(tenant_id, branch_id, status);
CREATE INDEX ON visitors(visitor_phone);
CREATE INDEX ON visitors(check_in_time DESC);
CREATE INDEX ON visitors(person_to_meet_id);
CREATE INDEX ON visitors(badge_number);

-- Visitor Badges
CREATE TABLE IF NOT EXISTS visitor_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  badge_number VARCHAR(50) UNIQUE NOT NULL,
  visitor_id UUID REFERENCES visitors(id),
  
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  returned_at TIMESTAMP WITH TIME ZONE,
  status VARCHAR(50) DEFAULT 'issued',
  
  CONSTRAINT valid_badge_status CHECK (
    status IN ('available', 'issued', 'lost', 'damaged')
  )
);

CREATE INDEX ON visitor_badges(tenant_id, branch_id, status);
CREATE INDEX ON visitor_badges(badge_number);

-- Visitor History
CREATE TABLE IF NOT EXISTS visitor_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  visitor_id UUID NOT NULL REFERENCES visitors(id),
  visitor_name VARCHAR(255) NOT NULL,
  visitor_phone VARCHAR(20),
  
  action_type VARCHAR(50) NOT NULL,
  action_description TEXT,
  performed_by UUID REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_action_type CHECK (
    action_type IN ('registered', 'checked_in', 'checked_out', 'extended', 'rejected', 'blacklisted')
  )
);

CREATE INDEX ON visitor_history(tenant_id, branch_id, visitor_id);
CREATE INDEX ON visitor_history(created_at DESC);

-- Visitor Blacklist
CREATE TABLE IF NOT EXISTS visitor_blacklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  visitor_name VARCHAR(255),
  visitor_phone VARCHAR(20),
  id_proof_number VARCHAR(100),
  
  reason TEXT NOT NULL,
  blacklisted_by UUID REFERENCES auth.users(id),
  blacklisted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, branch_id, visitor_phone)
);

CREATE INDEX ON visitor_blacklist(tenant_id, branch_id, is_active);
CREATE INDEX ON visitor_blacklist(visitor_phone);

-- Visitor Notifications
CREATE TABLE IF NOT EXISTS visitor_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  visitor_id UUID NOT NULL REFERENCES visitors(id),
  notification_type VARCHAR(50) NOT NULL,
  recipient_id UUID REFERENCES auth.users(id),
  
  sent_via VARCHAR(20) NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'sent',
  
  CONSTRAINT valid_notification_type CHECK (
    notification_type IN ('arrival', 'checkout', 'overdue', 'approval_request')
  ),
  CONSTRAINT valid_sent_via CHECK (
    sent_via IN ('sms', 'email', 'push', 'whatsapp')
  )
);

CREATE INDEX ON visitor_notifications(tenant_id, branch_id, visitor_id);
CREATE INDEX ON visitor_notifications(recipient_id);

-- Dashboard View
CREATE OR REPLACE VIEW visitor_dashboard_stats AS
SELECT
  tenant_id,
  branch_id,
  COUNT(*) FILTER (WHERE status = 'checked_in') as active_visitors,
  COUNT(*) FILTER (WHERE DATE(check_in_time) = CURRENT_DATE) as visitors_today,
  COUNT(*) FILTER (WHERE status = 'pre_registered' AND DATE(check_in_time) >= CURRENT_DATE) as pre_registered_today,
  COUNT(*) FILTER (WHERE status = 'checked_in' AND expected_checkout_time < NOW()) as overdue_visitors
FROM visitors
GROUP BY tenant_id, branch_id;

-- Functions
CREATE OR REPLACE FUNCTION check_in_visitor(
  p_visitor_id UUID,
  p_badge_number VARCHAR
)
RETURNS JSON AS $$
DECLARE
  v_tenant_id UUID;
  v_branch_id UUID;
  v_result JSON;
BEGIN
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  
  -- Update visitor status
  UPDATE visitors
  SET status = 'checked_in',
      check_in_time = NOW(),
      badge_number = p_badge_number,
      updated_at = NOW()
  WHERE id = p_visitor_id
    AND tenant_id = v_tenant_id
    AND branch_id = v_branch_id;
  
  -- Update badge status
  UPDATE visitor_badges
  SET visitor_id = p_visitor_id,
      status = 'issued',
      issued_at = NOW()
  WHERE badge_number = p_badge_number
    AND tenant_id = v_tenant_id
    AND branch_id = v_branch_id;
  
  -- Log history
  INSERT INTO visitor_history (
    tenant_id, branch_id, visitor_id, visitor_name, action_type, action_description
  )
  SELECT tenant_id, branch_id, id, visitor_name, 'checked_in', 
         'Visitor checked in with badge ' || p_badge_number
  FROM visitors WHERE id = p_visitor_id;
  
  SELECT json_build_object(
    'success', true,
    'visitor_id', p_visitor_id,
    'badge_number', p_badge_number,
    'check_in_time', NOW()
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION check_out_visitor(
  p_visitor_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_tenant_id UUID;
  v_branch_id UUID;
  v_badge_number VARCHAR;
  v_result JSON;
BEGIN
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  
  -- Get badge number
  SELECT badge_number INTO v_badge_number
  FROM visitors
  WHERE id = p_visitor_id;
  
  -- Update visitor status
  UPDATE visitors
  SET status = 'checked_out',
      check_out_time = NOW(),
      updated_at = NOW()
  WHERE id = p_visitor_id
    AND tenant_id = v_tenant_id
    AND branch_id = v_branch_id;
  
  -- Return badge
  UPDATE visitor_badges
  SET visitor_id = NULL,
      status = 'available',
      returned_at = NOW()
  WHERE badge_number = v_badge_number
    AND tenant_id = v_tenant_id
    AND branch_id = v_branch_id;
  
  -- Log history
  INSERT INTO visitor_history (
    tenant_id, branch_id, visitor_id, visitor_name, action_type, action_description
  )
  SELECT tenant_id, branch_id, id, visitor_name, 'checked_out', 
         'Visitor checked out, badge returned'
  FROM visitors WHERE id = p_visitor_id;
  
  SELECT json_build_object(
    'success', true,
    'visitor_id', p_visitor_id,
    'check_out_time', NOW()
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE visitor_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitor_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitor_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitor_blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitor_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY visitor_types_isolation ON visitor_types
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY visitors_isolation ON visitors
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY visitor_badges_isolation ON visitor_badges
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY visitor_history_isolation ON visitor_history
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY visitor_blacklist_isolation ON visitor_blacklist
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY visitor_notifications_isolation ON visitor_notifications
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/visitor-management.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface Visitor {
  id: string;
  tenantId: string;
  branchId: string;
  visitorName: string;
  visitorPhone: string;
  visitorEmail: string;
  visitorCompany: string;
  visitorTypeId: string;
  personToMeet: string;
  personToMeetId: string;
  department: string;
  purpose: string;
  checkInTime: string;
  expectedCheckoutTime: string;
  checkOutTime: string;
  status: string;
  idProofType: string;
  idProofNumber: string;
  photoUrl: string;
  badgeNumber: string;
  vehicleNumber: string;
  vehicleType: string;
  isPreRegistered: boolean;
  securityClearanceLevel: string;
  remarks: string;
  itemsCarried: string;
  createdAt: string;
  updatedAt: string;
}

export interface VisitorType {
  id: string;
  typeName: string;
  description: string;
  requiresApproval: boolean;
  maxDurationHours: number;
  colorCode: string;
}

export class VisitorManagementAPI {
  private supabase = createClient();

  /**
   * Register new visitor
   */
  async registerVisitor(data: Partial<Visitor>): Promise<Visitor> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Check blacklist first
    if (data.visitorPhone) {
      const { data: blacklisted } = await this.supabase
        .from('visitor_blacklist')
        .select('*')
        .eq('visitor_phone', data.visitorPhone)
        .eq('is_active', true)
        .single();

      if (blacklisted) {
        throw new Error('Visitor is blacklisted: ' + blacklisted.reason);
      }
    }

    const { data: visitor, error } = await this.supabase
      .from('visitors')
      .insert({
        ...data,
        created_by: user.id,
        updated_by: user.id
      })
      .select()
      .single();

    if (error) throw error;

    // Send notification to host
    await this.notifyHost(visitor.id, 'arrival');

    return visitor as Visitor;
  }

  /**
   * Check-in visitor
   */
  async checkInVisitor(visitorId: string, badgeNumber: string): Promise<any> {
    const { data, error } = await this.supabase
      .rpc('check_in_visitor', {
        p_visitor_id: visitorId,
        p_badge_number: badgeNumber
      });

    if (error) throw error;
    return data;
  }

  /**
   * Check-out visitor
   */
  async checkOutVisitor(visitorId: string): Promise<any> {
    const { data, error } = await this.supabase
      .rpc('check_out_visitor', {
        p_visitor_id: visitorId
      });

    if (error) throw error;
    return data;
  }

  /**
   * Get active visitors
   */
  async getActiveVisitors(): Promise<Visitor[]> {
    const { data, error } = await this.supabase
      .from('visitors')
      .select('*')
      .eq('status', 'checked_in')
      .order('check_in_time', { ascending: false });

    if (error) throw error;
    return data as Visitor[];
  }

  /**
   * Search visitors
   */
  async searchVisitors(query: string): Promise<Visitor[]> {
    const { data, error } = await this.supabase
      .from('visitors')
      .select('*')
      .or(`visitor_name.ilike.%${query}%,visitor_phone.ilike.%${query}%,visitor_company.ilike.%${query}%`)
      .order('check_in_time', { ascending: false })
      .limit(50);

    if (error) throw error;
    return data as Visitor[];
  }

  /**
   * Get visitor history
   */
  async getVisitorHistory(visitorId: string): Promise<any[]> {
    const { data, error } = await this.supabase
      .from('visitor_history')
      .select('*')
      .eq('visitor_id', visitorId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  /**
   * Upload visitor photo
   */
  async uploadPhoto(visitorId: string, file: File): Promise<string> {
    const fileExt = file.name.split('.').pop();
    const fileName = `${visitorId}-${Date.now()}.${fileExt}`;
    const filePath = `visitor-photos/${fileName}`;

    const { error: uploadError } = await this.supabase.storage
      .from('visitors')
      .upload(filePath, file);

    if (uploadError) throw uploadError;

    const { data: { publicUrl } } = this.supabase.storage
      .from('visitors')
      .getPublicUrl(filePath);

    // Update visitor record
    await this.supabase
      .from('visitors')
      .update({ photo_url: publicUrl })
      .eq('id', visitorId);

    return publicUrl;
  }

  /**
   * Get available badges
   */
  async getAvailableBadges(): Promise<string[]> {
    const { data, error } = await this.supabase
      .from('visitor_badges')
      .select('badge_number')
      .eq('status', 'available')
      .order('badge_number');

    if (error) throw error;
    return data.map(b => b.badge_number);
  }

  /**
   * Add to blacklist
   */
  async addToBlacklist(visitorPhone: string, reason: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('visitor_blacklist')
      .insert({
        visitor_phone: visitorPhone,
        reason: reason,
        blacklisted_by: user.id
      });

    if (error) throw error;
  }

  /**
   * Send notification to host
   */
  private async notifyHost(visitorId: string, type: string): Promise<void> {
    const { data: visitor } = await this.supabase
      .from('visitors')
      .select('person_to_meet_id, visitor_name')
      .eq('id', visitorId)
      .single();

    if (visitor && visitor.person_to_meet_id) {
      await this.supabase
        .from('visitor_notifications')
        .insert({
          visitor_id: visitorId,
          notification_type: type,
          recipient_id: visitor.person_to_meet_id,
          sent_via: 'email'
        });
    }
  }

  /**
   * Get dashboard stats
   */
  async getDashboardStats(): Promise<any> {
    const { data, error } = await this.supabase
      .from('visitor_dashboard_stats')
      .select('*')
      .single();

    if (error) throw error;
    return data;
  }
}

export const visitorManagementAPI = new VisitorManagementAPI();
```

### React Component (`/components/front-desk/VisitorManagement.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { 
  UserPlus, 
  LogIn, 
  LogOut, 
  Search, 
  Camera,
  IdCard,
  Car,
  AlertTriangle,
  History
} from 'lucide-react';
import { visitorManagementAPI, type Visitor } from '@/lib/api/visitor-management';
import { useToast } from '@/components/ui/use-toast';

export function VisitorManagement() {
  const [activeVisitors, setActiveVisitors] = useState<Visitor[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [showRegisterDialog, setShowRegisterDialog] = useState(false);
  const [showCheckInDialog, setShowCheckInDialog] = useState(false);
  const [selectedVisitor, setSelectedVisitor] = useState<Visitor | null>(null);
  const { toast } = useToast();

  useEffect(() => {
    loadActiveVisitors();
  }, []);

  const loadActiveVisitors = async () => {
    try {
      setLoading(true);
      const visitors = await visitorManagementAPI.getActiveVisitors();
      setActiveVisitors(visitors);
    } catch (error) {
      console.error('Error loading visitors:', error);
      toast({
        title: 'Error',
        description: 'Failed to load visitors',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const handleCheckOut = async (visitorId: string) => {
    try {
      await visitorManagementAPI.checkOutVisitor(visitorId);
      toast({
        title: 'Success',
        description: 'Visitor checked out successfully'
      });
      loadActiveVisitors();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive'
      });
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Visitor Management</h1>
          <p className="text-muted-foreground">
            Register, track, and manage visitor access
          </p>
        </div>
        <div className="flex gap-2">
          <Button onClick={() => setShowRegisterDialog(true)}>
            <UserPlus className="h-4 w-4 mr-2" />
            Register Visitor
          </Button>
          <Button variant="outline" onClick={() => setShowCheckInDialog(true)}>
            <LogIn className="h-4 w-4 mr-2" />
            Check-In
          </Button>
        </div>
      </div>

      <Tabs defaultValue="active">
        <TabsList>
          <TabsTrigger value="active">
            Active Visitors
            {activeVisitors.length > 0 && (
              <Badge variant="secondary" className="ml-2">
                {activeVisitors.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
          <TabsTrigger value="blacklist">Blacklist</TabsTrigger>
        </TabsList>

        <TabsContent value="active" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center gap-4">
                <div className="flex-1">
                  <div className="relative">
                    <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder="Search visitors..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="text-center py-8">Loading...</div>
              ) : activeVisitors.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  No active visitors
                </div>
              ) : (
                <div className="space-y-3">
                  {activeVisitors.map((visitor) => (
                    <div key={visitor.id} className="flex items-center justify-between p-4 border rounded-lg">
                      <div className="flex items-center gap-4">
                        <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center">
                          {visitor.photoUrl ? (
                            <img src={visitor.photoUrl} alt={visitor.visitorName} className="h-12 w-12 rounded-full" />
                          ) : (
                            <UserPlus className="h-6 w-6 text-primary" />
                          )}
                        </div>
                        <div>
                          <p className="font-medium">{visitor.visitorName}</p>
                          <p className="text-sm text-muted-foreground">
                            Meeting: {visitor.personToMeet} • {visitor.purpose}
                          </p>
                          <div className="flex gap-2 mt-1">
                            {visitor.badgeNumber && (
                              <Badge variant="outline">
                                <IdCard className="h-3 w-3 mr-1" />
                                {visitor.badgeNumber}
                              </Badge>
                            )}
                            {visitor.vehicleNumber && (
                              <Badge variant="outline">
                                <Car className="h-3 w-3 mr-1" />
                                {visitor.vehicleNumber}
                              </Badge>
                            )}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant="success">Checked In</Badge>
                        <span className="text-sm text-muted-foreground">
                          {new Date(visitor.checkInTime).toLocaleTimeString()}
                        </span>
                        <Button size="sm" onClick={() => handleCheckOut(visitor.id)}>
                          <LogOut className="h-4 w-4 mr-2" />
                          Check Out
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="history">
          <Card>
            <CardHeader>
              <CardTitle>Visitor History</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">View past visitors and their visit records</p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="blacklist">
          <Card>
            <CardHeader>
              <CardTitle>Blacklisted Visitors</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Manage blacklisted visitors</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Register Dialog */}
      <Dialog open={showRegisterDialog} onOpenChange={setShowRegisterDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Register New Visitor</DialogTitle>
          </DialogHeader>
          <VisitorRegistrationForm onSuccess={() => {
            setShowRegisterDialog(false);
            loadActiveVisitors();
          }} />
        </DialogContent>
      </Dialog>

      {/* Check-In Dialog */}
      <Dialog open={showCheckInDialog} onOpenChange={setShowCheckInDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Check-In Visitor</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Search for pre-registered visitor or scan badge
            </p>
            {/* Check-in form here */}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function VisitorRegistrationForm({ onSuccess }: { onSuccess: () => void }) {
  const [formData, setFormData] = useState({
    visitorName: '',
    visitorPhone: '',
    visitorEmail: '',
    visitorCompany: '',
    personToMeet: '',
    purpose: '',
    vehicleNumber: ''
  });
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await visitorManagementAPI.registerVisitor(formData);
      toast({
        title: 'Success',
        description: 'Visitor registered successfully'
      });
      onSuccess();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive'
      });
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>Visitor Name *</Label>
          <Input
            required
            value={formData.visitorName}
            onChange={(e) => setFormData({...formData, visitorName: e.target.value})}
          />
        </div>
        <div className="space-y-2">
          <Label>Phone Number *</Label>
          <Input
            required
            value={formData.visitorPhone}
            onChange={(e) => setFormData({...formData, visitorPhone: e.target.value})}
          />
        </div>
        <div className="space-y-2">
          <Label>Email</Label>
          <Input
            type="email"
            value={formData.visitorEmail}
            onChange={(e) => setFormData({...formData, visitorEmail: e.target.value})}
          />
        </div>
        <div className="space-y-2">
          <Label>Company</Label>
          <Input
            value={formData.visitorCompany}
            onChange={(e) => setFormData({...formData, visitorCompany: e.target.value})}
          />
        </div>
        <div className="space-y-2">
          <Label>Person to Meet *</Label>
          <Input
            required
            value={formData.personToMeet}
            onChange={(e) => setFormData({...formData, personToMeet: e.target.value})}
          />
        </div>
        <div className="space-y-2">
          <Label>Vehicle Number</Label>
          <Input
            value={formData.vehicleNumber}
            onChange={(e) => setFormData({...formData, vehicleNumber: e.target.value})}
          />
        </div>
      </div>
      <div className="space-y-2">
        <Label>Purpose of Visit *</Label>
        <Textarea
          required
          value={formData.purpose}
          onChange={(e) => setFormData({...formData, purpose: e.target.value})}
        />
      </div>
      <div className="flex justify-end gap-2">
        <Button type="submit">Register Visitor</Button>
      </div>
    </form>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/visitor-management.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { visitorManagementAPI } from '@/lib/api/visitor-management';

describe('VisitorManagementAPI', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('registerVisitor', () => {
    it('should register new visitor', async () => {
      const visitorData = {
        visitorName: 'John Doe',
        visitorPhone: '+1234567890',
        personToMeet: 'Jane Smith',
        purpose: 'Business meeting'
      };

      const visitor = await visitorManagementAPI.registerVisitor(visitorData);
      expect(visitor).toHaveProperty('id');
      expect(visitor.visitorName).toBe('John Doe');
    });

    it('should reject blacklisted visitor', async () => {
      const visitorData = {
        visitorName: 'Blacklisted Person',
        visitorPhone: '+9999999999',
        personToMeet: 'Someone',
        purpose: 'Visit'
      };

      await expect(visitorManagementAPI.registerVisitor(visitorData)).rejects.toThrow();
    });
  });

  describe('checkInVisitor', () => {
    it('should check-in visitor with badge', async () => {
      const result = await visitorManagementAPI.checkInVisitor('visitor-id', 'BADGE-001');
      expect(result.success).toBe(true);
      expect(result.badge_number).toBe('BADGE-001');
    });
  });

  describe('checkOutVisitor', () => {
    it('should check-out visitor and return badge', async () => {
      const result = await visitorManagementAPI.checkOutVisitor('visitor-id');
      expect(result.success).toBe(true);
      expect(result).toHaveProperty('check_out_time');
    });
  });

  describe('getActiveVisitors', () => {
    it('should return list of active visitors', async () => {
      const visitors = await visitorManagementAPI.getActiveVisitors();
      expect(Array.isArray(visitors)).toBe(true);
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { VisitorManagement } from '@/components/front-desk/VisitorManagement';

export default function VisitorPage() {
  return (
    <div className="container mx-auto">
      <VisitorManagement />
    </div>
  );
}
```

---

## 🔒 SECURITY

- **Blacklist Check**: Automatic check before registration
- **RLS Policies**: Tenant and branch isolation
- **Photo Storage**: Secure storage with access control
- **Badge Tracking**: Prevent badge misuse
- **Audit Trail**: Complete visitor history
- **Host Notifications**: Automatic SMS/email alerts

---

## 📊 PERFORMANCE

- **Registration**: < 1 second
- **Check-In/Out**: < 500ms
- **Search**: < 300ms with indexing
- **Photo Upload**: < 3 seconds
- **Dashboard Load**: < 1 second

---

## ✅ DEFINITION OF DONE

- [ ] All database tables created with RLS
- [ ] API client fully implemented
- [ ] React component with registration form
- [ ] Check-in/check-out functionality working
- [ ] Badge management operational
- [ ] Photo upload functional
- [ ] Blacklist management working
- [ ] Notification system integrated
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive verified
- [ ] Security audit completed
- [ ] Documentation complete
