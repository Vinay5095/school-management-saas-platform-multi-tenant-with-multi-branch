# SPEC-207: Safety & Security Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-207  
**Title**: Safety & Security Management System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Safety & Security  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-201  

---

## 📋 DESCRIPTION

Comprehensive safety and security management system enabling vice principals to track safety incidents, manage visitor logs, maintain emergency contacts, conduct safety drills, monitor security protocols, and ensure overall campus safety.

---

## 🎯 SUCCESS CRITERIA

- [ ] Incident tracking with auto-numbering operational
- [ ] Visitor management functional
- [ ] Emergency contacts maintained
- [ ] Safety drill tracking working
- [ ] Security reports generating
- [ ] Real-time alerts functional
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Safety Incidents
CREATE TABLE IF NOT EXISTS safety_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Incident number (auto-generated)
  incident_number VARCHAR(50) UNIQUE NOT NULL,
  
  incident_date DATE NOT NULL DEFAULT CURRENT_DATE,
  incident_time TIME NOT NULL DEFAULT CURRENT_TIME,
  
  incident_type VARCHAR(100), -- injury, fight, unauthorized_entry, fire, medical_emergency, natural_disaster, security_breach
  severity_level VARCHAR(50), -- minor, moderate, serious, critical, emergency
  
  location VARCHAR(200),
  location_details TEXT,
  
  incident_description TEXT NOT NULL,
  
  -- People involved
  persons_involved JSONB DEFAULT '[]', -- [{name, type (student/staff/visitor), id, role}]
  witness_count INTEGER DEFAULT 0,
  witnesses JSONB DEFAULT '[]',
  
  -- Response
  immediate_action_taken TEXT,
  first_aid_given BOOLEAN DEFAULT false,
  ambulance_called BOOLEAN DEFAULT false,
  police_informed BOOLEAN DEFAULT false,
  
  injuries_reported BOOLEAN DEFAULT false,
  injury_details TEXT,
  
  -- Follow-up
  follow_up_required BOOLEAN DEFAULT true,
  follow_up_actions TEXT,
  follow_up_completed BOOLEAN DEFAULT false,
  
  -- Reporting
  reported_by UUID REFERENCES staff(id),
  reported_to_principal BOOLEAN DEFAULT false,
  principal_notified_at TIMESTAMP WITH TIME ZONE,
  
  parents_informed BOOLEAN DEFAULT false,
  parent_notification_details TEXT,
  
  -- Investigation
  investigation_required BOOLEAN DEFAULT false,
  investigation_status VARCHAR(50), -- pending, ongoing, completed
  investigation_notes TEXT,
  
  -- Closure
  incident_closed BOOLEAN DEFAULT false,
  closure_date DATE,
  closure_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON safety_incidents(tenant_id, branch_id, incident_date DESC);
CREATE INDEX ON safety_incidents(incident_number);
CREATE INDEX ON safety_incidents(severity_level, incident_closed);

-- Function to generate incident number
CREATE OR REPLACE FUNCTION generate_incident_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.incident_number := 'INC-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(NEXTVAL('incident_number_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS incident_number_seq;

CREATE TRIGGER set_incident_number
  BEFORE INSERT ON safety_incidents
  FOR EACH ROW
  WHEN (NEW.incident_number IS NULL OR NEW.incident_number = '')
  EXECUTE FUNCTION generate_incident_number();

-- Visitor Logs
CREATE TABLE IF NOT EXISTS visitor_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Visitor details
  visitor_name VARCHAR(200) NOT NULL,
  visitor_type VARCHAR(100), -- parent, vendor, contractor, guest, government_official, inspector
  visitor_contact VARCHAR(50),
  visitor_email VARCHAR(200),
  visitor_company VARCHAR(200),
  
  -- ID verification
  id_type VARCHAR(100), -- aadhar, driving_license, passport, employee_id
  id_number VARCHAR(100),
  id_verification_status VARCHAR(50) DEFAULT 'pending', -- pending, verified, rejected
  
  -- Visit purpose
  purpose_of_visit TEXT NOT NULL,
  department_visiting VARCHAR(100),
  
  -- Host details
  host_staff_id UUID REFERENCES staff(id),
  host_staff_name VARCHAR(200),
  
  -- Check-in/out
  check_in_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  check_out_time TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    CASE 
      WHEN check_out_time IS NOT NULL 
      THEN EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 60
      ELSE NULL
    END
  ) STORED,
  
  -- Authorization
  authorization_status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
  authorized_by UUID REFERENCES staff(id),
  authorization_notes TEXT,
  
  -- Security pass
  pass_issued BOOLEAN DEFAULT false,
  pass_number VARCHAR(50),
  pass_returned BOOLEAN DEFAULT false,
  
  -- Items brought
  items_brought TEXT,
  items_verified BOOLEAN DEFAULT false,
  
  -- Belongings
  belongings_deposited BOOLEAN DEFAULT false,
  belongings_description TEXT,
  
  -- Status
  visit_status VARCHAR(50) DEFAULT 'checked_in', -- checked_in, in_progress, checked_out, overstayed
  
  remarks TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON visitor_logs(tenant_id, branch_id, visit_date DESC);
CREATE INDEX ON visitor_logs(visitor_name, visitor_contact);
CREATE INDEX ON visitor_logs(visit_status);
CREATE INDEX ON visitor_logs(check_in_time DESC);

-- Emergency Contacts
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  contact_type VARCHAR(100), -- police, fire_department, ambulance, hospital, disaster_management, parent_emergency
  
  contact_name VARCHAR(200) NOT NULL,
  organization VARCHAR(200),
  designation VARCHAR(100),
  
  -- Contact details
  primary_phone VARCHAR(50) NOT NULL,
  secondary_phone VARCHAR(50),
  emergency_hotline VARCHAR(50),
  email VARCHAR(200),
  
  -- Address
  address TEXT,
  distance_km NUMERIC(6,2),
  estimated_response_time_minutes INTEGER,
  
  -- Priority
  priority_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  
  -- Availability
  available_247 BOOLEAN DEFAULT false,
  available_hours TEXT,
  
  notes TEXT,
  
  last_contacted_date DATE,
  last_drill_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON emergency_contacts(tenant_id, branch_id, priority_order);
CREATE INDEX ON emergency_contacts(contact_type, is_active);

-- Safety Drills
CREATE TABLE IF NOT EXISTS safety_drills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  drill_type VARCHAR(100), -- fire_drill, earthquake_drill, lockdown_drill, evacuation_drill, medical_emergency_drill
  drill_date DATE NOT NULL,
  drill_time TIME NOT NULL,
  
  planned BOOLEAN DEFAULT true,
  announcement_given BOOLEAN DEFAULT true,
  
  -- Participants
  total_students_expected INTEGER,
  students_participated INTEGER,
  total_staff_expected INTEGER,
  staff_participated INTEGER,
  
  -- Timing
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  evacuation_time_seconds INTEGER,
  
  -- Assembly points
  assembly_points_used JSONB DEFAULT '[]',
  all_accounted_for BOOLEAN DEFAULT false,
  missing_persons_count INTEGER DEFAULT 0,
  
  -- Evaluation
  drill_success BOOLEAN DEFAULT true,
  success_rating INTEGER CHECK (success_rating BETWEEN 1 AND 5),
  
  issues_identified TEXT,
  improvements_needed TEXT,
  
  conducted_by UUID REFERENCES staff(id),
  observers JSONB DEFAULT '[]',
  
  report_url TEXT,
  photos_urls JSONB DEFAULT '[]',
  
  next_drill_scheduled_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON safety_drills(tenant_id, branch_id, drill_date DESC);
CREATE INDEX ON safety_drills(drill_type);

-- Safety Dashboard View
CREATE MATERIALIZED VIEW vp_safety_dashboard AS
SELECT
  si.tenant_id,
  si.branch_id,
  
  COUNT(DISTINCT CASE WHEN si.incident_date >= CURRENT_DATE - INTERVAL '30 days' THEN si.id END) as incidents_last_30_days,
  COUNT(DISTINCT CASE WHEN si.incident_date >= CURRENT_DATE - INTERVAL '7 days' THEN si.id END) as incidents_last_7_days,
  COUNT(DISTINCT CASE WHEN si.incident_date = CURRENT_DATE THEN si.id END) as incidents_today,
  
  COUNT(DISTINCT CASE WHEN si.severity_level = 'critical' AND NOT si.incident_closed THEN si.id END) as open_critical_incidents,
  COUNT(DISTINCT CASE WHEN NOT si.incident_closed THEN si.id END) as total_open_incidents,
  
  COUNT(DISTINCT CASE WHEN vl.visit_date = CURRENT_DATE AND vl.visit_status = 'checked_in' THEN vl.id END) as active_visitors_today,
  COUNT(DISTINCT CASE WHEN vl.visit_date = CURRENT_DATE THEN vl.id END) as total_visitors_today,
  
  (SELECT drill_date FROM safety_drills sd WHERE sd.tenant_id = si.tenant_id AND sd.branch_id = si.branch_id ORDER BY drill_date DESC LIMIT 1) as last_drill_date,
  
  NOW() as last_calculated_at
  
FROM safety_incidents si
CROSS JOIN visitor_logs vl
WHERE vl.tenant_id = si.tenant_id AND vl.branch_id = si.branch_id
GROUP BY si.tenant_id, si.branch_id;

CREATE INDEX ON vp_safety_dashboard(tenant_id, branch_id);

-- Enable RLS
ALTER TABLE safety_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitor_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_drills ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY safety_incidents_isolation ON safety_incidents
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY visitor_logs_isolation ON visitor_logs
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY emergency_contacts_isolation ON emergency_contacts
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY safety_drills_isolation ON safety_drills
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/safety-management.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface SafetyIncident {
  id: string;
  incidentNumber: string;
  incidentDate: string;
  incidentType: string;
  severityLevel: string;
  location: string;
  incidentDescription: string;
  incidentClosed: boolean;
}

export interface VisitorLog {
  id: string;
  visitorName: string;
  visitorType: string;
  purposeOfVisit: string;
  checkInTime: string;
  checkOutTime?: string;
  visitStatus: string;
}

export class SafetyManagementAPI {
  private supabase = createClient();

  async recordIncident(params: {
    tenantId: string;
    branchId: string;
    incidentType: string;
    severityLevel: string;
    location: string;
    incidentDescription: string;
    personsInvolved?: any[];
    immediateActionTaken?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('safety_incidents')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        incident_type: params.incidentType,
        severity_level: params.severityLevel,
        location: params.location,
        incident_description: params.incidentDescription,
        persons_involved: params.personsInvolved || [],
        immediate_action_taken: params.immediateActionTaken,
        reported_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getIncidents(params: {
    tenantId: string;
    branchId: string;
    closed?: boolean;
  }): Promise<SafetyIncident[]> {
    let query = this.supabase
      .from('safety_incidents')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId);

    if (params.closed !== undefined) {
      query = query.eq('incident_closed', params.closed);
    }

    const { data, error } = await query.order('incident_date', { ascending: false });

    if (error) throw error;

    return (data || []).map(inc => ({
      id: inc.id,
      incidentNumber: inc.incident_number,
      incidentDate: inc.incident_date,
      incidentType: inc.incident_type,
      severityLevel: inc.severity_level,
      location: inc.location,
      incidentDescription: inc.incident_description,
      incidentClosed: inc.incident_closed,
    }));
  }

  async logVisitor(params: {
    tenantId: string;
    branchId: string;
    visitorName: string;
    visitorType: string;
    visitorContact: string;
    purposeOfVisit: string;
    hostStaffId?: string;
    idType?: string;
    idNumber?: string;
  }) {
    const { data, error } = await this.supabase
      .from('visitor_logs')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        visitor_name: params.visitorName,
        visitor_type: params.visitorType,
        visitor_contact: params.visitorContact,
        purpose_of_visit: params.purposeOfVisit,
        host_staff_id: params.hostStaffId,
        id_type: params.idType,
        id_number: params.idNumber,
        visit_status: 'checked_in',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async checkOutVisitor(visitorLogId: string) {
    const { error } = await this.supabase
      .from('visitor_logs')
      .update({
        check_out_time: new Date().toISOString(),
        visit_status: 'checked_out',
      })
      .eq('id', visitorLogId);

    if (error) throw error;
  }

  async getActiveVisitors(params: {
    tenantId: string;
    branchId: string;
  }): Promise<VisitorLog[]> {
    const { data, error } = await this.supabase
      .from('visitor_logs')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('visit_date', new Date().toISOString().split('T')[0])
      .eq('visit_status', 'checked_in')
      .order('check_in_time', { ascending: false });

    if (error) throw error;

    return (data || []).map(v => ({
      id: v.id,
      visitorName: v.visitor_name,
      visitorType: v.visitor_type,
      purposeOfVisit: v.purpose_of_visit,
      checkInTime: v.check_in_time,
      checkOutTime: v.check_out_time,
      visitStatus: v.visit_status,
    }));
  }

  async getEmergencyContacts(params: {
    tenantId: string;
    branchId: string;
    contactType?: string;
  }) {
    let query = this.supabase
      .from('emergency_contacts')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .eq('is_active', true);

    if (params.contactType) {
      query = query.eq('contact_type', params.contactType);
    }

    const { data, error } = await query.order('priority_order');

    if (error) throw error;
    return data;
  }

  async getSafetyDashboard(params: {
    tenantId: string;
    branchId: string;
  }) {
    const { data, error } = await this.supabase
      .from('vp_safety_dashboard')
      .select('*')
      .eq('tenant_id', params.tenantId)
      .eq('branch_id', params.branchId)
      .single();

    if (error) throw error;
    return data;
  }
}

export const safetyManagementAPI = new SafetyManagementAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { SafetyManagementAPI } from '../safety-management';

describe('SafetyManagementAPI', () => {
  let api: SafetyManagementAPI;

  beforeEach(() => {
    api = new SafetyManagementAPI();
  });

  it('records safety incident with auto-numbering', async () => {
    const incident = await api.recordIncident({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      incidentType: 'injury',
      severityLevel: 'moderate',
      location: 'Playground',
      incidentDescription: 'Student fell during sports activity',
    });

    expect(incident).toHaveProperty('incident_number');
    expect(incident.incident_number).toMatch(/^INC-\d{6}-\d{5}$/);
  });

  it('logs visitor check-in', async () => {
    const log = await api.logVisitor({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      visitorName: 'John Doe',
      visitorType: 'parent',
      visitorContact: '9876543210',
      purposeOfVisit: 'Parent-teacher meeting',
    });

    expect(log).toHaveProperty('id');
    expect(log.visit_status).toBe('checked_in');
  });

  it('gets active visitors', async () => {
    const visitors = await api.getActiveVisitors({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
    });

    expect(Array.isArray(visitors)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Incident tracking with auto-numbering operational
- [ ] Visitor check-in/check-out working
- [ ] Emergency contacts maintained
- [ ] Safety dashboard displaying correctly
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
