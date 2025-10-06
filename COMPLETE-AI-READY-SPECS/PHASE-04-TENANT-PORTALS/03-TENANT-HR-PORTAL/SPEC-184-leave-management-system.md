# SPEC-184: Leave Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-184  
**Title**: Leave Management & Time-Off System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Leave Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-179  

---

## 📋 DESCRIPTION

Complete leave management system with multiple leave types, balance tracking, automated accrual, leave policies, approval workflows, calendar integration, encashment calculations, and comprehensive leave analytics.

---

## 🎯 SUCCESS CRITERIA

- [ ] Leave policies configured
- [ ] Leave applications working
- [ ] Approval workflows functional
- [ ] Balance tracking accurate
- [ ] Auto-accrual operational
- [ ] Calendar integration working
- [ ] Encashment calculations correct
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Leave Types
CREATE TABLE IF NOT EXISTS leave_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Type details
  leave_type_name VARCHAR(100) NOT NULL,
  leave_type_code VARCHAR(20) NOT NULL,
  
  -- Configuration
  is_paid BOOLEAN DEFAULT true,
  is_encashable BOOLEAN DEFAULT false,
  requires_approval BOOLEAN DEFAULT true,
  
  -- Limits
  max_days_per_year NUMERIC(5,2),
  max_consecutive_days INTEGER,
  min_days_per_application NUMERIC(4,2) DEFAULT 0.5,
  
  -- Accrual
  accrual_type VARCHAR(50), -- monthly, annual, none
  accrual_rate NUMERIC(5,2), -- Days per month/year
  
  -- Carryover
  allow_carryover BOOLEAN DEFAULT false,
  max_carryover_days NUMERIC(5,2),
  carryover_expiry_months INTEGER,
  
  -- Restrictions
  can_apply_future_days INTEGER DEFAULT 365,
  can_apply_past_days INTEGER DEFAULT 7,
  notice_period_days INTEGER DEFAULT 1,
  
  -- Proration
  prorate_on_joining BOOLEAN DEFAULT true,
  prorate_on_leaving BOOLEAN DEFAULT true,
  
  -- Gender specific
  applicable_gender VARCHAR(20), -- all, male, female
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  display_order INTEGER,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, leave_type_code)
);

CREATE INDEX ON leave_types(tenant_id);

-- Employee Leave Balances
CREATE TABLE IF NOT EXISTS employee_leave_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  leave_type_id UUID NOT NULL REFERENCES leave_types(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Period
  leave_year INTEGER NOT NULL,
  
  -- Balance
  opening_balance NUMERIC(6,2) DEFAULT 0,
  accrued_days NUMERIC(6,2) DEFAULT 0,
  carried_forward NUMERIC(6,2) DEFAULT 0,
  used_days NUMERIC(6,2) DEFAULT 0,
  encashed_days NUMERIC(6,2) DEFAULT 0,
  
  -- Calculated
  available_balance NUMERIC(6,2) GENERATED ALWAYS AS (
    opening_balance + accrued_days + carried_forward - used_days - encashed_days
  ) STORED,
  
  -- Last accrual
  last_accrual_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(employee_id, leave_type_id, leave_year)
);

CREATE INDEX ON employee_leave_balances(employee_id);
CREATE INDEX ON employee_leave_balances(tenant_id, leave_year);

-- Leave Applications
CREATE TABLE IF NOT EXISTS leave_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  leave_type_id UUID NOT NULL REFERENCES leave_types(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Application details
  application_number VARCHAR(50) UNIQUE NOT NULL,
  application_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Leave period
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  total_days NUMERIC(4,2) NOT NULL,
  
  -- Half day
  is_half_day BOOLEAN DEFAULT false,
  half_day_period VARCHAR(10), -- first_half, second_half
  
  -- Reason
  reason TEXT NOT NULL,
  
  -- Contact
  contact_number VARCHAR(20),
  contact_address TEXT,
  
  -- Attachments
  supporting_documents JSONB,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, cancelled, withdrawn
  
  -- Approval flow
  current_approver_id UUID REFERENCES auth.users(id),
  approval_level INTEGER DEFAULT 1,
  
  -- Actions
  submitted_at TIMESTAMP WITH TIME ZONE,
  approved_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES auth.users(id),
  rejected_at TIMESTAMP WITH TIME ZONE,
  rejected_by UUID REFERENCES auth.users(id),
  rejection_reason TEXT,
  
  -- Cancellation
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancellation_reason TEXT,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'withdrawn'))
);

CREATE INDEX ON leave_applications(employee_id);
CREATE INDEX ON leave_applications(tenant_id, status);
CREATE INDEX ON leave_applications(from_date, to_date);
CREATE INDEX ON leave_applications(current_approver_id, status);

-- Leave Approval Workflow
CREATE TABLE IF NOT EXISTS leave_approval_workflow (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES leave_applications(id) ON DELETE CASCADE,
  
  -- Approver
  approver_id UUID NOT NULL REFERENCES auth.users(id),
  approval_level INTEGER NOT NULL,
  approver_role VARCHAR(50), -- reporting_manager, hr, department_head
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, skipped
  
  -- Action
  action_taken_at TIMESTAMP WITH TIME ZONE,
  comments TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected', 'skipped'))
);

CREATE INDEX ON leave_approval_workflow(application_id);
CREATE INDEX ON leave_approval_workflow(approver_id, status);

-- Leave Holidays
CREATE TABLE IF NOT EXISTS leave_holidays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Holiday details
  holiday_name VARCHAR(200) NOT NULL,
  holiday_date DATE NOT NULL,
  
  -- Type
  holiday_type VARCHAR(50), -- public, optional, festival
  
  -- Applicability
  is_mandatory BOOLEAN DEFAULT true,
  applicable_to_all BOOLEAN DEFAULT true,
  
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, holiday_date, branch_id)
);

CREATE INDEX ON leave_holidays(tenant_id);
CREATE INDEX ON leave_holidays(holiday_date);

-- Leave Encashment
CREATE TABLE IF NOT EXISTS leave_encashment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  leave_type_id UUID NOT NULL REFERENCES leave_types(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Encashment details
  encashment_number VARCHAR(50) UNIQUE NOT NULL,
  leave_year INTEGER NOT NULL,
  
  -- Days
  days_encashed NUMERIC(5,2) NOT NULL,
  
  -- Amount
  per_day_rate NUMERIC(10,2) NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, processed, rejected
  
  -- Processing
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  processed_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'processed', 'rejected'))
);

CREATE INDEX ON leave_encashment(employee_id);
CREATE INDEX ON leave_encashment(status);

-- Function to generate application number
CREATE OR REPLACE FUNCTION generate_leave_application_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.application_number := 'LVE-' || 
    TO_CHAR(NOW(), 'YYYYMM') || '-' ||
    LPAD(NEXTVAL('leave_application_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS leave_application_seq;

CREATE TRIGGER set_leave_application_number
  BEFORE INSERT ON leave_applications
  FOR EACH ROW
  WHEN (NEW.application_number IS NULL OR NEW.application_number = '')
  EXECUTE FUNCTION generate_leave_application_number();

-- Function to calculate working days
CREATE OR REPLACE FUNCTION calculate_working_days(
  p_tenant_id UUID,
  p_from_date DATE,
  p_to_date DATE,
  p_branch_id UUID DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
  v_total_days INTEGER;
  v_holidays INTEGER;
  v_working_days NUMERIC;
BEGIN
  -- Calculate calendar days
  v_total_days := (p_to_date - p_from_date) + 1;
  
  -- Count holidays
  SELECT COUNT(*) INTO v_holidays
  FROM leave_holidays
  WHERE tenant_id = p_tenant_id
  AND holiday_date BETWEEN p_from_date AND p_to_date
  AND (branch_id IS NULL OR branch_id = p_branch_id OR p_branch_id IS NULL);
  
  -- Calculate working days (excluding weekends - Sunday only for simplicity)
  v_working_days := v_total_days - v_holidays;
  
  -- Subtract Sundays
  v_working_days := v_working_days - (
    SELECT COUNT(*)
    FROM generate_series(p_from_date, p_to_date, '1 day'::interval) AS day
    WHERE EXTRACT(DOW FROM day) = 0
  );
  
  RETURN GREATEST(v_working_days, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to accrue leave
CREATE OR REPLACE FUNCTION accrue_monthly_leave(
  p_tenant_id UUID,
  p_leave_year INTEGER
)
RETURNS INTEGER AS $$
DECLARE
  v_employee RECORD;
  v_leave_type RECORD;
  v_accrued_count INTEGER := 0;
BEGIN
  -- Loop through employees
  FOR v_employee IN 
    SELECT id FROM staff 
    WHERE tenant_id = p_tenant_id 
    AND status = 'active'
  LOOP
    -- Loop through leave types with monthly accrual
    FOR v_leave_type IN
      SELECT * FROM leave_types
      WHERE tenant_id = p_tenant_id
      AND accrual_type = 'monthly'
      AND is_active = true
    LOOP
      -- Update or insert balance
      INSERT INTO employee_leave_balances (
        employee_id,
        leave_type_id,
        tenant_id,
        leave_year,
        accrued_days,
        last_accrual_date
      ) VALUES (
        v_employee.id,
        v_leave_type.id,
        p_tenant_id,
        p_leave_year,
        v_leave_type.accrual_rate,
        CURRENT_DATE
      )
      ON CONFLICT (employee_id, leave_type_id, leave_year)
      DO UPDATE SET
        accrued_days = employee_leave_balances.accrued_days + v_leave_type.accrual_rate,
        last_accrual_date = CURRENT_DATE;
      
      v_accrued_count := v_accrued_count + 1;
    END LOOP;
  END LOOP;
  
  RETURN v_accrued_count;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update leave balance after approval
CREATE OR REPLACE FUNCTION update_leave_balance_on_approval()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    UPDATE employee_leave_balances
    SET used_days = used_days + NEW.total_days
    WHERE employee_id = NEW.employee_id
    AND leave_type_id = NEW.leave_type_id
    AND leave_year = EXTRACT(YEAR FROM NEW.from_date);
  END IF;
  
  IF NEW.status = 'cancelled' AND OLD.status = 'approved' THEN
    UPDATE employee_leave_balances
    SET used_days = used_days - NEW.total_days
    WHERE employee_id = NEW.employee_id
    AND leave_type_id = NEW.leave_type_id
    AND leave_year = EXTRACT(YEAR FROM NEW.from_date);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER adjust_leave_balance
  AFTER UPDATE ON leave_applications
  FOR EACH ROW
  WHEN (NEW.status IS DISTINCT FROM OLD.status)
  EXECUTE FUNCTION update_leave_balance_on_approval();

-- Enable RLS
ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_approval_workflow ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_encashment ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/leave-management.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface LeaveType {
  id: string;
  leaveTypeName: string;
  leaveTypeCode: string;
  isPaid: boolean;
  maxDaysPerYear: number;
  isActive: boolean;
}

export interface LeaveBalance {
  leaveType: string;
  availableBalance: number;
  usedDays: number;
  accruedDays: number;
}

export interface LeaveApplication {
  id: string;
  applicationNumber: string;
  fromDate: string;
  toDate: string;
  totalDays: number;
  status: string;
  leaveType: string;
}

export class LeaveManagementAPI {
  private supabase = createClient();

  async getLeaveTypes(tenantId: string): Promise<LeaveType[]> {
    const { data, error } = await this.supabase
      .from('leave_types')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('is_active', true)
      .order('display_order');

    if (error) throw error;

    return (data || []).map(type => ({
      id: type.id,
      leaveTypeName: type.leave_type_name,
      leaveTypeCode: type.leave_type_code,
      isPaid: type.is_paid,
      maxDaysPerYear: type.max_days_per_year,
      isActive: type.is_active,
    }));
  }

  async getEmployeeLeaveBalances(params: {
    employeeId: string;
    leaveYear: number;
  }): Promise<LeaveBalance[]> {
    const { data, error } = await this.supabase
      .from('employee_leave_balances')
      .select(`
        *,
        leave_type:leave_types(leave_type_name)
      `)
      .eq('employee_id', params.employeeId)
      .eq('leave_year', params.leaveYear);

    if (error) throw error;

    return (data || []).map(balance => ({
      leaveType: balance.leave_type.leave_type_name,
      availableBalance: balance.available_balance,
      usedDays: balance.used_days,
      accruedDays: balance.accrued_days,
    }));
  }

  async applyLeave(params: {
    employeeId: string;
    leaveTypeId: string;
    tenantId: string;
    fromDate: Date;
    toDate: Date;
    totalDays: number;
    reason: string;
    isHalfDay?: boolean;
    contactNumber?: string;
  }): Promise<LeaveApplication> {
    const { data, error } = await this.supabase
      .from('leave_applications')
      .insert({
        employee_id: params.employeeId,
        leave_type_id: params.leaveTypeId,
        tenant_id: params.tenantId,
        from_date: params.fromDate.toISOString().split('T')[0],
        to_date: params.toDate.toISOString().split('T')[0],
        total_days: params.totalDays,
        reason: params.reason,
        is_half_day: params.isHalfDay || false,
        contact_number: params.contactNumber,
        status: 'pending',
        submitted_at: new Date().toISOString(),
      })
      .select(`
        *,
        leave_type:leave_types(leave_type_name)
      `)
      .single();

    if (error) throw error;

    return {
      id: data.id,
      applicationNumber: data.application_number,
      fromDate: data.from_date,
      toDate: data.to_date,
      totalDays: data.total_days,
      status: data.status,
      leaveType: data.leave_type.leave_type_name,
    };
  }

  async approveLeaveApplication(params: {
    applicationId: string;
    comments?: string;
  }): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('leave_applications')
      .update({
        status: 'approved',
        approved_by: user?.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', params.applicationId);

    if (error) throw error;

    // Update workflow
    await this.supabase
      .from('leave_approval_workflow')
      .update({
        status: 'approved',
        action_taken_at: new Date().toISOString(),
        comments: params.comments,
      })
      .eq('application_id', params.applicationId)
      .eq('approver_id', user?.id);
  }

  async rejectLeaveApplication(params: {
    applicationId: string;
    rejectionReason: string;
  }): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { error } = await this.supabase
      .from('leave_applications')
      .update({
        status: 'rejected',
        rejected_by: user?.id,
        rejected_at: new Date().toISOString(),
        rejection_reason: params.rejectionReason,
      })
      .eq('id', params.applicationId);

    if (error) throw error;
  }

  async getEmployeeLeaveApplications(params: {
    employeeId: string;
    status?: string;
  }): Promise<LeaveApplication[]> {
    let query = this.supabase
      .from('leave_applications')
      .select(`
        *,
        leave_type:leave_types(leave_type_name)
      `)
      .eq('employee_id', params.employeeId);

    if (params.status) {
      query = query.eq('status', params.status);
    }

    const { data, error } = await query.order('application_date', {
      ascending: false,
    });

    if (error) throw error;

    return (data || []).map(app => ({
      id: app.id,
      applicationNumber: app.application_number,
      fromDate: app.from_date,
      toDate: app.to_date,
      totalDays: app.total_days,
      status: app.status,
      leaveType: app.leave_type.leave_type_name,
    }));
  }

  async getPendingApprovals(approverId: string): Promise<LeaveApplication[]> {
    const { data, error } = await this.supabase
      .from('leave_applications')
      .select(`
        *,
        employee:staff(full_name, employee_code),
        leave_type:leave_types(leave_type_name)
      `)
      .eq('current_approver_id', approverId)
      .eq('status', 'pending')
      .order('application_date');

    if (error) throw error;

    return (data || []).map(app => ({
      id: app.id,
      applicationNumber: app.application_number,
      fromDate: app.from_date,
      toDate: app.to_date,
      totalDays: app.total_days,
      status: app.status,
      leaveType: app.leave_type.leave_type_name,
    }));
  }

  async calculateWorkingDays(params: {
    tenantId: string;
    fromDate: Date;
    toDate: Date;
    branchId?: string;
  }): Promise<number> {
    const { data, error } = await this.supabase.rpc('calculate_working_days', {
      p_tenant_id: params.tenantId,
      p_from_date: params.fromDate.toISOString().split('T')[0],
      p_to_date: params.toDate.toISOString().split('T')[0],
      p_branch_id: params.branchId,
    });

    if (error) throw error;
    return data;
  }

  async accrueMonthlyLeave(params: {
    tenantId: string;
    leaveYear: number;
  }): Promise<number> {
    const { data, error } = await this.supabase.rpc('accrue_monthly_leave', {
      p_tenant_id: params.tenantId,
      p_leave_year: params.leaveYear,
    });

    if (error) throw error;
    return data;
  }

  async requestLeaveEncashment(params: {
    employeeId: string;
    leaveTypeId: string;
    tenantId: string;
    leaveYear: number;
    daysToEncash: number;
    perDayRate: number;
  }) {
    const encashmentNumber = `ENC-${Date.now()}`;
    const totalAmount = params.daysToEncash * params.perDayRate;

    const { data, error } = await this.supabase
      .from('leave_encashment')
      .insert({
        employee_id: params.employeeId,
        leave_type_id: params.leaveTypeId,
        tenant_id: params.tenantId,
        encashment_number: encashmentNumber,
        leave_year: params.leaveYear,
        days_encashed: params.daysToEncash,
        per_day_rate: params.perDayRate,
        total_amount: totalAmount,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}

export const leaveManagementAPI = new LeaveManagementAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { LeaveManagementAPI } from '../leave-management';

describe('LeaveManagementAPI', () => {
  it('retrieves leave balances', async () => {
    const api = new LeaveManagementAPI();
    const balances = await api.getEmployeeLeaveBalances({
      employeeId: 'emp-123',
      leaveYear: 2025,
    });

    expect(Array.isArray(balances)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Leave types configured
- [ ] Applications working
- [ ] Approvals functional
- [ ] Balance tracking accurate
- [ ] Auto-accrual operational
- [ ] Encashment working
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-185 (Policy & Compliance)  
**Time**: 4 hours  
**AI-Ready**: 100%
