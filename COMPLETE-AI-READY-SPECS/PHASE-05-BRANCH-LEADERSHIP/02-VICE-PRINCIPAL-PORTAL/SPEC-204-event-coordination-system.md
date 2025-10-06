# SPEC-204: Event Coordination System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-204  
**Title**: Event Coordination System  
**Phase**: Phase 5 - Branch Leadership Portals  
**Portal**: Vice Principal Portal  
**Category**: Event Management  
**Priority**: MEDIUM  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-196  

---

## 📋 DESCRIPTION

Event coordination system enabling vice principals to manage school events, assign volunteer roles to students/staff, track event attendance, coordinate logistics, and generate post-event reports.

---

## 🎯 SUCCESS CRITERIA

- [ ] Event volunteer management working
- [ ] Role assignments functional
- [ ] Attendance tracking operational
- [ ] Logistics coordination system working
- [ ] Task management functioning
- [ ] Post-event reports generating
- [ ] Communication workflows operational
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Event Volunteers
CREATE TABLE IF NOT EXISTS event_volunteers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  event_id UUID NOT NULL REFERENCES school_events(id),
  
  volunteer_type VARCHAR(50), -- student, staff, parent, external
  volunteer_id UUID, -- student_id or staff_id if applicable
  volunteer_name VARCHAR(200),
  volunteer_contact TEXT,
  
  volunteer_role VARCHAR(100), -- coordinator, registration_desk, crowd_control, tech_support, refreshments, etc.
  assigned_tasks JSONB DEFAULT '[]', -- [{task, priority, status, notes}]
  
  availability_confirmed BOOLEAN DEFAULT false,
  confirmation_date DATE,
  
  attended BOOLEAN DEFAULT false,
  check_in_time TIMESTAMP WITH TIME ZONE,
  check_out_time TIMESTAMP WITH TIME ZONE,
  
  hours_volunteered NUMERIC(5,2),
  performance_rating INTEGER CHECK (performance_rating BETWEEN 1 AND 5),
  performance_notes TEXT,
  
  certificate_issued BOOLEAN DEFAULT false,
  certificate_number VARCHAR(100),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON event_volunteers(tenant_id, branch_id);
CREATE INDEX ON event_volunteers(event_id, volunteer_type);
CREATE INDEX ON event_volunteers(volunteer_id, volunteer_type);

-- Event Logistics
CREATE TABLE IF NOT EXISTS event_logistics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  event_id UUID NOT NULL REFERENCES school_events(id),
  
  logistics_category VARCHAR(100), -- venue, equipment, catering, transportation, security, decorations
  item_name VARCHAR(200),
  item_description TEXT,
  
  quantity_required INTEGER,
  quantity_confirmed INTEGER DEFAULT 0,
  
  vendor_name VARCHAR(200),
  vendor_contact TEXT,
  
  estimated_cost NUMERIC(10,2),
  actual_cost NUMERIC(10,2),
  
  booking_status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, delivered, cancelled
  booking_date DATE,
  delivery_date DATE,
  
  payment_status VARCHAR(50) DEFAULT 'unpaid', -- unpaid, partially_paid, paid
  payment_due_date DATE,
  
  responsible_person_id UUID REFERENCES staff(id),
  
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON event_logistics(tenant_id, branch_id);
CREATE INDEX ON event_logistics(event_id, logistics_category);
CREATE INDEX ON event_logistics(booking_status);

-- Event Task Checklist
CREATE TABLE IF NOT EXISTS event_task_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  event_id UUID NOT NULL REFERENCES school_events(id),
  
  task_category VARCHAR(100), -- pre_event, during_event, post_event
  task_name VARCHAR(200),
  task_description TEXT,
  
  priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
  
  assigned_to_id UUID REFERENCES staff(id),
  assigned_to_name VARCHAR(200),
  
  due_date DATE,
  due_time TIME,
  
  status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, cancelled
  
  completed_at TIMESTAMP WITH TIME ZONE,
  completed_by UUID REFERENCES staff(id),
  
  verification_required BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES staff(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON event_task_checklist(event_id, task_category, status);
CREATE INDEX ON event_task_checklist(assigned_to_id, due_date);

-- Event Attendance
CREATE TABLE IF NOT EXISTS event_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  event_id UUID NOT NULL REFERENCES school_events(id),
  
  attendee_type VARCHAR(50), -- student, staff, parent, guest, speaker
  attendee_id UUID, -- student_id or staff_id if applicable
  attendee_name VARCHAR(200),
  
  registration_required BOOLEAN DEFAULT false,
  registered BOOLEAN DEFAULT false,
  registration_date DATE,
  
  attended BOOLEAN DEFAULT false,
  check_in_time TIMESTAMP WITH TIME ZONE,
  
  accompanied_by VARCHAR(200), -- for students with parents/guardians
  
  feedback_provided BOOLEAN DEFAULT false,
  feedback_rating INTEGER CHECK (feedback_rating BETWEEN 1 AND 5),
  feedback_comments TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON event_attendance(event_id, attendee_type);
CREATE INDEX ON event_attendance(attendee_id, attendee_type);
CREATE INDEX ON event_attendance(attended);

-- Event Summary View
CREATE MATERIALIZED VIEW event_coordination_summary AS
SELECT
  e.id as event_id,
  e.tenant_id,
  e.branch_id,
  e.event_name,
  e.event_date,
  e.event_type,
  e.status as event_status,
  
  -- Volunteer stats
  COUNT(DISTINCT v.id) as total_volunteers,
  COUNT(DISTINCT CASE WHEN v.availability_confirmed THEN v.id END) as confirmed_volunteers,
  COUNT(DISTINCT CASE WHEN v.attended THEN v.id END) as volunteers_attended,
  
  -- Task stats
  COUNT(DISTINCT t.id) as total_tasks,
  COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.id END) as completed_tasks,
  COUNT(DISTINCT CASE WHEN t.status = 'pending' AND t.due_date < CURRENT_DATE THEN t.id END) as overdue_tasks,
  
  -- Logistics stats
  COUNT(DISTINCT l.id) as total_logistics_items,
  COUNT(DISTINCT CASE WHEN l.booking_status = 'confirmed' THEN l.id END) as confirmed_items,
  SUM(l.estimated_cost) as estimated_total_cost,
  SUM(l.actual_cost) as actual_total_cost,
  
  -- Attendance stats
  COUNT(DISTINCT a.id) FILTER (WHERE a.registered) as registered_attendees,
  COUNT(DISTINCT a.id) FILTER (WHERE a.attended) as actual_attendees,
  
  NOW() as last_calculated_at
  
FROM school_events e
LEFT JOIN event_volunteers v ON e.id = v.event_id
LEFT JOIN event_task_checklist t ON e.id = t.event_id
LEFT JOIN event_logistics l ON e.id = l.event_id
LEFT JOIN event_attendance a ON e.id = a.event_id
GROUP BY e.id, e.tenant_id, e.branch_id, e.event_name, e.event_date, e.event_type, e.status;

CREATE INDEX ON event_coordination_summary(tenant_id, branch_id, event_date);

-- Auto-update triggers
CREATE OR REPLACE FUNCTION update_event_volunteer_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_volunteer_update_trigger
  BEFORE UPDATE ON event_volunteers
  FOR EACH ROW
  EXECUTE FUNCTION update_event_volunteer_timestamp();

CREATE TRIGGER event_logistics_update_trigger
  BEFORE UPDATE ON event_logistics
  FOR EACH ROW
  EXECUTE FUNCTION update_event_volunteer_timestamp();

-- Enable RLS
ALTER TABLE event_volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_logistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_task_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_attendance ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY event_volunteers_isolation ON event_volunteers
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY event_logistics_isolation ON event_logistics
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY event_task_checklist_isolation ON event_task_checklist
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY event_attendance_isolation ON event_attendance
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/event-coordination.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface EventVolunteer {
  id: string;
  eventId: string;
  volunteerType: string;
  volunteerName: string;
  volunteerRole: string;
  assignedTasks: any[];
  availabilityConfirmed: boolean;
  attended: boolean;
}

export interface EventLogistics {
  id: string;
  eventId: string;
  logisticsCategory: string;
  itemName: string;
  quantityRequired: number;
  quantityConfirmed: number;
  bookingStatus: string;
  estimatedCost: number;
  actualCost?: number;
}

export interface EventTask {
  id: string;
  eventId: string;
  taskCategory: string;
  taskName: string;
  priority: string;
  assignedToName: string;
  dueDate: string;
  status: string;
}

export class EventCoordinationAPI {
  private supabase = createClient();

  async addVolunteer(params: {
    tenantId: string;
    branchId: string;
    eventId: string;
    volunteerType: string;
    volunteerName: string;
    volunteerContact: string;
    volunteerRole: string;
    assignedTasks?: any[];
  }) {
    const { data, error } = await this.supabase
      .from('event_volunteers')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        event_id: params.eventId,
        volunteer_type: params.volunteerType,
        volunteer_name: params.volunteerName,
        volunteer_contact: params.volunteerContact,
        volunteer_role: params.volunteerRole,
        assigned_tasks: params.assignedTasks || [],
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getEventVolunteers(eventId: string): Promise<EventVolunteer[]> {
    const { data, error } = await this.supabase
      .from('event_volunteers')
      .select('*')
      .eq('event_id', eventId)
      .order('volunteer_role');

    if (error) throw error;

    return (data || []).map(v => ({
      id: v.id,
      eventId: v.event_id,
      volunteerType: v.volunteer_type,
      volunteerName: v.volunteer_name,
      volunteerRole: v.volunteer_role,
      assignedTasks: v.assigned_tasks || [],
      availabilityConfirmed: v.availability_confirmed,
      attended: v.attended,
    }));
  }

  async confirmVolunteerAvailability(volunteerId: string) {
    const { error } = await this.supabase
      .from('event_volunteers')
      .update({
        availability_confirmed: true,
        confirmation_date: new Date().toISOString().split('T')[0],
      })
      .eq('id', volunteerId);

    if (error) throw error;
  }

  async recordVolunteerAttendance(params: {
    volunteerId: string;
    attended: boolean;
    checkInTime?: string;
    hoursVolunteered?: number;
  }) {
    const updateData: any = {
      attended: params.attended,
    };

    if (params.checkInTime) {
      updateData.check_in_time = params.checkInTime;
    }

    if (params.hoursVolunteered) {
      updateData.hours_volunteered = params.hoursVolunteered;
    }

    const { error } = await this.supabase
      .from('event_volunteers')
      .update(updateData)
      .eq('id', params.volunteerId);

    if (error) throw error;
  }

  async addLogisticsItem(params: {
    tenantId: string;
    branchId: string;
    eventId: string;
    logisticsCategory: string;
    itemName: string;
    itemDescription?: string;
    quantityRequired: number;
    estimatedCost: number;
    responsiblePersonId: string;
  }) {
    const { data, error } = await this.supabase
      .from('event_logistics')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        event_id: params.eventId,
        logistics_category: params.logisticsCategory,
        item_name: params.itemName,
        item_description: params.itemDescription,
        quantity_required: params.quantityRequired,
        estimated_cost: params.estimatedCost,
        responsible_person_id: params.responsiblePersonId,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getEventLogistics(eventId: string): Promise<EventLogistics[]> {
    const { data, error } = await this.supabase
      .from('event_logistics')
      .select('*')
      .eq('event_id', eventId)
      .order('logistics_category');

    if (error) throw error;

    return (data || []).map(l => ({
      id: l.id,
      eventId: l.event_id,
      logisticsCategory: l.logistics_category,
      itemName: l.item_name,
      quantityRequired: l.quantity_required,
      quantityConfirmed: l.quantity_confirmed,
      bookingStatus: l.booking_status,
      estimatedCost: l.estimated_cost,
      actualCost: l.actual_cost,
    }));
  }

  async updateLogisticsStatus(params: {
    logisticsId: string;
    bookingStatus: string;
    quantityConfirmed?: number;
    actualCost?: number;
  }) {
    const { error } = await this.supabase
      .from('event_logistics')
      .update({
        booking_status: params.bookingStatus,
        quantity_confirmed: params.quantityConfirmed,
        actual_cost: params.actualCost,
      })
      .eq('id', params.logisticsId);

    if (error) throw error;
  }

  async addTask(params: {
    tenantId: string;
    branchId: string;
    eventId: string;
    taskCategory: string;
    taskName: string;
    taskDescription?: string;
    priority: string;
    assignedToId: string;
    assignedToName: string;
    dueDate: string;
  }) {
    const { data, error } = await this.supabase
      .from('event_task_checklist')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        event_id: params.eventId,
        task_category: params.taskCategory,
        task_name: params.taskName,
        task_description: params.taskDescription,
        priority: params.priority,
        assigned_to_id: params.assignedToId,
        assigned_to_name: params.assignedToName,
        due_date: params.dueDate,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getEventTasks(eventId: string): Promise<EventTask[]> {
    const { data, error } = await this.supabase
      .from('event_task_checklist')
      .select('*')
      .eq('event_id', eventId)
      .order('due_date');

    if (error) throw error;

    return (data || []).map(t => ({
      id: t.id,
      eventId: t.event_id,
      taskCategory: t.task_category,
      taskName: t.task_name,
      priority: t.priority,
      assignedToName: t.assigned_to_name,
      dueDate: t.due_date,
      status: t.status,
    }));
  }

  async completeTask(taskId: string) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('event_task_checklist')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        completed_by: user?.id,
      })
      .eq('id', taskId);

    if (error) throw error;
  }

  async recordAttendance(params: {
    tenantId: string;
    branchId: string;
    eventId: string;
    attendeeType: string;
    attendeeName: string;
    attended: boolean;
  }) {
    const { data, error } = await this.supabase
      .from('event_attendance')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        event_id: params.eventId,
        attendee_type: params.attendeeType,
        attendee_name: params.attendeeName,
        attended: params.attended,
        check_in_time: params.attended ? new Date().toISOString() : null,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getEventSummary(eventId: string) {
    const { data, error } = await this.supabase
      .from('event_coordination_summary')
      .select('*')
      .eq('event_id', eventId)
      .single();

    if (error) throw error;
    return data;
  }
}

export const eventCoordinationAPI = new EventCoordinationAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { EventCoordinationAPI } from '../event-coordination';

describe('EventCoordinationAPI', () => {
  let api: EventCoordinationAPI;

  beforeEach(() => {
    api = new EventCoordinationAPI();
  });

  it('adds event volunteer', async () => {
    const volunteer = await api.addVolunteer({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      eventId: 'event-123',
      volunteerType: 'student',
      volunteerName: 'John Doe',
      volunteerContact: 'john@example.com',
      volunteerRole: 'registration_desk',
    });

    expect(volunteer).toHaveProperty('id');
  });

  it('manages event logistics', async () => {
    const logistics = await api.addLogisticsItem({
      tenantId: 'test-tenant',
      branchId: 'test-branch',
      eventId: 'event-123',
      logisticsCategory: 'equipment',
      itemName: 'Microphones',
      quantityRequired: 5,
      estimatedCost: 500,
      responsiblePersonId: 'staff-123',
    });

    expect(logistics).toHaveProperty('id');
  });

  it('completes event task', async () => {
    await expect(api.completeTask('task-123')).resolves.not.toThrow();
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Volunteer management operational
- [ ] Logistics tracking working
- [ ] Task checklist functioning
- [ ] Attendance recording operational
- [ ] Event summary generating
- [ ] Status updates working
- [ ] Tests passing (85%+ coverage)

---

**Status**: ✅ COMPLETE  
**AI-Ready**: 100%  
**Autonomous Development**: Ready
