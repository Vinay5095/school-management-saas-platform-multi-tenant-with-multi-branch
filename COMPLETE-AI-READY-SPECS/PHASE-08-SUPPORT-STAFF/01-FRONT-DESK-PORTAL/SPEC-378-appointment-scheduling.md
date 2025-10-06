# SPEC-378: Appointment Scheduling System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-378  
**Title**: Appointment Scheduling System  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: Front Desk Portal  
**Category**: Appointment Management  
**Priority**: HIGH  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-011, SPEC-013, SPEC-376  

---

## 📋 DESCRIPTION

Comprehensive appointment scheduling system with calendar view, confirmation workflow, reminder notifications, and guest pre-registration capabilities. Supports reschedule and cancellation with notification, recurring appointments, and meeting room booking integration.

---

## 🎯 SUCCESS CRITERIA

- [ ] Schedule appointments with time slots functional
- [ ] Calendar view (day/week/month) operational
- [ ] Appointment confirmation workflow working
- [ ] Email/SMS reminder notifications sending
- [ ] Reschedule functionality operational
- [ ] Cancel with reasons working
- [ ] Guest pre-registration functional
- [ ] Recurring appointments supported
- [ ] Meeting room booking integrated
- [ ] Appointment history accessible
- [ ] Mobile responsive layout
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Appointments
CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Appointment Details
  visitor_name VARCHAR(255) NOT NULL,
  visitor_phone VARCHAR(20) NOT NULL,
  visitor_email VARCHAR(255),
  visitor_company VARCHAR(255),
  
  -- Meeting Details
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  person_to_meet VARCHAR(255) NOT NULL,
  person_to_meet_id UUID REFERENCES auth.users(id),
  department VARCHAR(100),
  purpose TEXT NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending',
  confirmed_at TIMESTAMP WITH TIME ZONE,
  confirmed_by UUID REFERENCES auth.users(id),
  
  -- Meeting Room
  meeting_room_id UUID REFERENCES meeting_rooms(id),
  
  -- Recurring
  is_recurring BOOLEAN DEFAULT false,
  recurrence_pattern VARCHAR(50),
  recurrence_end_date DATE,
  parent_appointment_id UUID REFERENCES appointments(id),
  
  -- Cancellation
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancelled_by UUID REFERENCES auth.users(id),
  cancellation_reason TEXT,
  
  -- Metadata
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (
    status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')
  ),
  CONSTRAINT valid_recurrence_pattern CHECK (
    recurrence_pattern IS NULL OR recurrence_pattern IN ('daily', 'weekly', 'monthly')
  )
);

CREATE INDEX ON appointments(tenant_id, branch_id, appointment_date);
CREATE INDEX ON appointments(person_to_meet_id);
CREATE INDEX ON appointments(status);
CREATE INDEX ON appointments(visitor_phone);
CREATE INDEX ON appointments(meeting_room_id);

-- Appointment Reminders
CREATE TABLE IF NOT EXISTS appointment_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  appointment_id UUID NOT NULL REFERENCES appointments(id),
  reminder_type VARCHAR(50) NOT NULL,
  
  scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE,
  sent_via VARCHAR(20) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  
  CONSTRAINT valid_reminder_type CHECK (
    reminder_type IN ('1_day_before', '1_hour_before', '30_min_before', 'on_appointment')
  ),
  CONSTRAINT valid_sent_via CHECK (
    sent_via IN ('sms', 'email', 'push', 'whatsapp')
  )
);

CREATE INDEX ON appointment_reminders(tenant_id, branch_id, appointment_id);
CREATE INDEX ON appointment_reminders(scheduled_for, status);

-- Meeting Rooms
CREATE TABLE IF NOT EXISTS meeting_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  room_name VARCHAR(100) NOT NULL,
  room_code VARCHAR(50),
  capacity INTEGER NOT NULL,
  floor_number INTEGER,
  building VARCHAR(100),
  
  facilities JSONB DEFAULT '[]',
  is_available BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, room_code)
);

CREATE INDEX ON meeting_rooms(tenant_id, branch_id, is_available);

-- Appointment History
CREATE TABLE IF NOT EXISTS appointment_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  appointment_id UUID NOT NULL REFERENCES appointments(id),
  action_type VARCHAR(50) NOT NULL,
  action_description TEXT,
  performed_by UUID REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_action_type CHECK (
    action_type IN ('created', 'confirmed', 'rescheduled', 'cancelled', 'completed', 'no_show')
  )
);

CREATE INDEX ON appointment_history(tenant_id, branch_id, appointment_id);
CREATE INDEX ON appointment_history(created_at DESC);

-- Functions
CREATE OR REPLACE FUNCTION schedule_appointment(
  p_appointment_data JSONB
)
RETURNS JSON AS $$
DECLARE
  v_tenant_id UUID;
  v_branch_id UUID;
  v_appointment_id UUID;
  v_result JSON;
BEGIN
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  
  -- Insert appointment
  INSERT INTO appointments (
    tenant_id, branch_id,
    visitor_name, visitor_phone, visitor_email, visitor_company,
    appointment_date, appointment_time, duration_minutes,
    person_to_meet, person_to_meet_id, department, purpose,
    meeting_room_id, notes
  )
  VALUES (
    v_tenant_id, v_branch_id,
    (p_appointment_data->>'visitor_name')::VARCHAR,
    (p_appointment_data->>'visitor_phone')::VARCHAR,
    (p_appointment_data->>'visitor_email')::VARCHAR,
    (p_appointment_data->>'visitor_company')::VARCHAR,
    (p_appointment_data->>'appointment_date')::DATE,
    (p_appointment_data->>'appointment_time')::TIME,
    (p_appointment_data->>'duration_minutes')::INTEGER,
    (p_appointment_data->>'person_to_meet')::VARCHAR,
    (p_appointment_data->>'person_to_meet_id')::UUID,
    (p_appointment_data->>'department')::VARCHAR,
    (p_appointment_data->>'purpose')::TEXT,
    (p_appointment_data->>'meeting_room_id')::UUID,
    (p_appointment_data->>'notes')::TEXT
  )
  RETURNING id INTO v_appointment_id;
  
  -- Schedule reminders
  INSERT INTO appointment_reminders (
    tenant_id, branch_id, appointment_id, reminder_type, scheduled_for, sent_via
  )
  SELECT 
    v_tenant_id, v_branch_id, v_appointment_id,
    '1_day_before',
    ((p_appointment_data->>'appointment_date')::DATE + (p_appointment_data->>'appointment_time')::TIME - INTERVAL '1 day'),
    'email'
  UNION ALL
  SELECT 
    v_tenant_id, v_branch_id, v_appointment_id,
    '1_hour_before',
    ((p_appointment_data->>'appointment_date')::DATE + (p_appointment_data->>'appointment_time')::TIME - INTERVAL '1 hour'),
    'sms';
  
  -- Log history
  INSERT INTO appointment_history (
    tenant_id, branch_id, appointment_id, action_type, action_description
  )
  VALUES (
    v_tenant_id, v_branch_id, v_appointment_id, 'created',
    'Appointment scheduled for ' || (p_appointment_data->>'appointment_date') || ' at ' || (p_appointment_data->>'appointment_time')
  );
  
  SELECT json_build_object(
    'success', true,
    'appointment_id', v_appointment_id,
    'scheduled_for', (p_appointment_data->>'appointment_date') || ' ' || (p_appointment_data->>'appointment_time')
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION confirm_appointment(
  p_appointment_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_tenant_id UUID;
  v_branch_id UUID;
  v_result JSON;
BEGIN
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  
  UPDATE appointments
  SET status = 'confirmed',
      confirmed_at = NOW(),
      confirmed_by = auth.uid(),
      updated_at = NOW()
  WHERE id = p_appointment_id
    AND tenant_id = v_tenant_id
    AND branch_id = v_branch_id;
  
  INSERT INTO appointment_history (
    tenant_id, branch_id, appointment_id, action_type, action_description, performed_by
  )
  VALUES (
    v_tenant_id, v_branch_id, p_appointment_id, 'confirmed',
    'Appointment confirmed', auth.uid()
  );
  
  SELECT json_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'confirmed'
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointment_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointment_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY appointments_isolation ON appointments
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY appointment_reminders_isolation ON appointment_reminders
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY meeting_rooms_isolation ON meeting_rooms
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY appointment_history_isolation ON appointment_history
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/appointment-scheduling.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface Appointment {
  id: string;
  visitorName: string;
  visitorPhone: string;
  visitorEmail: string;
  appointmentDate: string;
  appointmentTime: string;
  durationMinutes: number;
  personToMeet: string;
  personToMeetId: string;
  purpose: string;
  status: string;
  meetingRoomId?: string;
  notes?: string;
}

export class AppointmentSchedulingAPI {
  private supabase = createClient();

  async scheduleAppointment(data: Partial<Appointment>): Promise<any> {
    const { data: result, error } = await this.supabase
      .rpc('schedule_appointment', {
        p_appointment_data: data
      });

    if (error) throw error;
    return result;
  }

  async confirmAppointment(appointmentId: string): Promise<any> {
    const { data, error } = await this.supabase
      .rpc('confirm_appointment', {
        p_appointment_id: appointmentId
      });

    if (error) throw error;
    return data;
  }

  async getTodaysAppointments(): Promise<Appointment[]> {
    const today = new Date().toISOString().split('T')[0];
    
    const { data, error } = await this.supabase
      .from('appointments')
      .select('*')
      .eq('appointment_date', today)
      .order('appointment_time');

    if (error) throw error;
    return data as Appointment[];
  }

  async cancelAppointment(appointmentId: string, reason: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('appointments')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        cancelled_by: user.id,
        cancellation_reason: reason
      })
      .eq('id', appointmentId);

    if (error) throw error;
  }

  async rescheduleAppointment(
    appointmentId: string, 
    newDate: string, 
    newTime: string
  ): Promise<void> {
    const { error } = await this.supabase
      .from('appointments')
      .update({
        appointment_date: newDate,
        appointment_time: newTime,
        updated_at: new Date().toISOString()
      })
      .eq('id', appointmentId);

    if (error) throw error;
  }

  async getAvailableMeetingRooms(date: string, time: string, duration: number): Promise<any[]> {
    const { data, error } = await this.supabase
      .from('meeting_rooms')
      .select('*')
      .eq('is_available', true);

    if (error) throw error;
    return data;
  }
}

export const appointmentSchedulingAPI = new AppointmentSchedulingAPI();
```

### React Component (`/components/front-desk/AppointmentScheduling.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import { appointmentSchedulingAPI, type Appointment } from '@/lib/api/appointment-scheduling';
import { useToast } from '@/components/ui/use-toast';

export function AppointmentScheduling() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const { toast } = useToast();

  useEffect(() => {
    loadAppointments();
  }, [selectedDate]);

  const loadAppointments = async () => {
    try {
      const data = await appointmentSchedulingAPI.getTodaysAppointments();
      setAppointments(data);
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
      <h1 className="text-3xl font-bold">Appointment Scheduling</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Calendar</CardTitle>
          </CardHeader>
          <CardContent>
            <Calendar
              mode="single"
              selected={selectedDate}
              onSelect={(date) => date && setSelectedDate(date)}
            />
          </CardContent>
        </Card>
        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>Appointments</CardTitle>
          </CardHeader>
          <CardContent>
            {appointments.length === 0 ? (
              <p className="text-muted-foreground">No appointments scheduled</p>
            ) : (
              <div className="space-y-2">
                {appointments.map((apt) => (
                  <div key={apt.id} className="p-3 border rounded">
                    <p className="font-medium">{apt.visitorName}</p>
                    <p className="text-sm">{apt.appointmentTime} - {apt.personToMeet}</p>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { appointmentSchedulingAPI } from '@/lib/api/appointment-scheduling';

describe('AppointmentSchedulingAPI', () => {
  it('should schedule appointment', async () => {
    const result = await appointmentSchedulingAPI.scheduleAppointment({
      visitorName: 'John Doe',
      visitorPhone: '+1234567890',
      appointmentDate: '2025-10-10',
      appointmentTime: '14:00',
      personToMeet: 'Jane Smith',
      purpose: 'Meeting'
    });
    expect(result.success).toBe(true);
  });

  it('should confirm appointment', async () => {
    const result = await appointmentSchedulingAPI.confirmAppointment('apt-id');
    expect(result.success).toBe(true);
  });
});
```

---

## ✅ DEFINITION OF DONE

- [ ] All database tables created with RLS
- [ ] API client fully implemented
- [ ] Calendar view component working
- [ ] Appointment scheduling functional
- [ ] Reminder system operational
- [ ] Meeting room booking integrated
- [ ] Tests passing (85%+ coverage)
- [ ] Mobile responsive verified
- [ ] Documentation complete
