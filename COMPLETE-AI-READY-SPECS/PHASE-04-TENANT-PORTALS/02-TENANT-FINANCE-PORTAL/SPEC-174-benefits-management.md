# SPEC-174: Benefits Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-174  
**Title**: Employee Benefits Management  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant Finance Portal  
**Category**: Benefits Administration  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-012, SPEC-173  

---

## 📋 DESCRIPTION

Comprehensive employee benefits management including health insurance, life insurance, retirement plans, leave encashment, gratuity, wellness programs, and benefit enrollment. Supports benefit cost tracking, eligibility rules, and automated enrollment.

---

## 🎯 SUCCESS CRITERIA

- [ ] Benefit plans configuration working
- [ ] Enrollment system operational
- [ ] Eligibility rules enforced
- [ ] Cost tracking accurate
- [ ] Leave encashment calculated
- [ ] Gratuity computation correct
- [ ] Reporting functional
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Benefit Plans
CREATE TABLE IF NOT EXISTS benefit_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Plan details
  plan_code VARCHAR(50) NOT NULL,
  plan_name VARCHAR(200) NOT NULL,
  plan_type VARCHAR(50) NOT NULL, -- health_insurance, life_insurance, retirement, wellness, leave_encashment
  description TEXT,
  
  -- Provider
  provider_name VARCHAR(200),
  policy_number VARCHAR(100),
  
  -- Cost
  employer_contribution_type VARCHAR(20), -- fixed, percentage
  employer_contribution_amount NUMERIC(15,2),
  employee_contribution_type VARCHAR(20),
  employee_contribution_amount NUMERIC(15,2),
  
  -- Coverage
  coverage_amount NUMERIC(15,2),
  coverage_details JSONB, -- Specific benefits included
  
  -- Eligibility
  eligibility_criteria JSONB, -- {"min_tenure_months": 3, "employee_types": ["permanent"]}
  auto_enroll BOOLEAN DEFAULT false,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Metadata
  documents JSONB, -- Policy documents, brochures
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, plan_code),
  CONSTRAINT valid_plan_type CHECK (plan_type IN ('health_insurance', 'life_insurance', 'retirement', 'wellness', 'leave_encashment', 'gratuity', 'other'))
);

-- Employee Benefit Enrollments
CREATE TABLE IF NOT EXISTS employee_benefit_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  benefit_plan_id UUID NOT NULL REFERENCES benefit_plans(id),
  
  -- Enrollment details
  enrollment_date DATE NOT NULL,
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, suspended, cancelled, expired
  
  -- Dependents
  dependents JSONB, -- [{"name": "John Doe", "relationship": "spouse", "dob": "1990-01-01"}]
  dependent_count INTEGER DEFAULT 0,
  
  -- Cost
  employee_contribution NUMERIC(15,2) DEFAULT 0,
  employer_contribution NUMERIC(15,2) DEFAULT 0,
  total_premium NUMERIC(15,2) DEFAULT 0,
  
  -- Deduction
  deduct_from_salary BOOLEAN DEFAULT true,
  deduction_frequency VARCHAR(20) DEFAULT 'monthly',
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(employee_id, benefit_plan_id, effective_from),
  CONSTRAINT valid_status CHECK (status IN ('active', 'pending', 'suspended', 'cancelled', 'expired'))
);

CREATE INDEX ON employee_benefit_enrollments(employee_id);
CREATE INDEX ON employee_benefit_enrollments(benefit_plan_id);
CREATE INDEX ON employee_benefit_enrollments(status);

-- Benefit Claims
CREATE TABLE IF NOT EXISTS benefit_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id UUID NOT NULL REFERENCES employee_benefit_enrollments(id),
  employee_id UUID NOT NULL REFERENCES staff(id),
  benefit_plan_id UUID NOT NULL REFERENCES benefit_plans(id),
  
  -- Claim details
  claim_number VARCHAR(50) UNIQUE NOT NULL,
  claim_type VARCHAR(50) NOT NULL, -- medical, reimbursement, encashment
  claim_date DATE NOT NULL,
  
  -- Amount
  claimed_amount NUMERIC(15,2) NOT NULL,
  approved_amount NUMERIC(15,2),
  
  -- Supporting documents
  attachments JSONB, -- [{"name": "bill.pdf", "url": "..."}]
  
  -- Status
  status VARCHAR(50) DEFAULT 'submitted',
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  
  -- Payment
  payment_status VARCHAR(50) DEFAULT 'pending',
  paid_at TIMESTAMP WITH TIME ZONE,
  payment_reference VARCHAR(100),
  
  -- Notes
  claim_description TEXT,
  review_notes TEXT,
  rejection_reason TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_claim_status CHECK (status IN ('submitted', 'under_review', 'approved', 'rejected', 'paid')),
  CONSTRAINT valid_payment_status CHECK (payment_status IN ('pending', 'processing', 'paid', 'failed'))
);

CREATE INDEX ON benefit_claims(employee_id);
CREATE INDEX ON benefit_claims(status);

-- Leave Encashment Records
CREATE TABLE IF NOT EXISTS leave_encashment_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Period
  financial_year INTEGER NOT NULL,
  leave_type VARCHAR(50) NOT NULL,
  
  -- Calculation
  eligible_days NUMERIC(5,2) NOT NULL,
  encashed_days NUMERIC(5,2) NOT NULL,
  per_day_rate NUMERIC(15,2) NOT NULL,
  total_amount NUMERIC(15,2) NOT NULL,
  
  -- Tax treatment
  is_taxable BOOLEAN DEFAULT true,
  tax_exemption_amount NUMERIC(15,2) DEFAULT 0,
  
  -- Processing
  processed_in_payroll_cycle_id UUID REFERENCES payroll_cycles(id),
  payment_date DATE,
  status VARCHAR(50) DEFAULT 'pending',
  
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON leave_encashment_records(employee_id);

-- Gratuity Calculations
CREATE TABLE IF NOT EXISTS gratuity_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Service details
  date_of_joining DATE NOT NULL,
  date_of_exit DATE NOT NULL,
  years_of_service NUMERIC(5,2) NOT NULL,
  
  -- Calculation
  last_drawn_salary NUMERIC(15,2) NOT NULL,
  gratuity_formula VARCHAR(100), -- e.g., "(Last Salary * Years) / 2"
  calculated_amount NUMERIC(15,2) NOT NULL,
  
  -- Tax
  tax_exempt_amount NUMERIC(15,2),
  taxable_amount NUMERIC(15,2),
  
  -- Payment
  payment_status VARCHAR(50) DEFAULT 'pending',
  paid_at TIMESTAMP WITH TIME ZONE,
  payment_reference VARCHAR(100),
  
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_payment_status CHECK (payment_status IN ('pending', 'approved', 'paid', 'rejected'))
);

CREATE INDEX ON gratuity_calculations(employee_id);

-- Function to auto-generate claim number
CREATE OR REPLACE FUNCTION generate_claim_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.claim_number := 'CLM-' || 
    TO_CHAR(NOW(), 'YYYYMM') || '-' ||
    LPAD(NEXTVAL('claim_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS claim_seq;

CREATE TRIGGER set_claim_number
  BEFORE INSERT ON benefit_claims
  FOR EACH ROW
  WHEN (NEW.claim_number IS NULL)
  EXECUTE FUNCTION generate_claim_number();

-- Function to calculate leave encashment
CREATE OR REPLACE FUNCTION calculate_leave_encashment(
  p_employee_id UUID,
  p_leave_days NUMERIC,
  p_financial_year INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
  v_basic_salary NUMERIC;
  v_per_day_rate NUMERIC;
  v_total_amount NUMERIC;
BEGIN
  -- Get employee's basic salary
  SELECT basic_salary INTO v_basic_salary
  FROM employee_payroll_details
  WHERE employee_id = p_employee_id
  AND is_active = true
  LIMIT 1;
  
  -- Calculate per day rate (monthly salary / 30)
  v_per_day_rate := v_basic_salary / 30;
  
  -- Calculate total encashment
  v_total_amount := v_per_day_rate * p_leave_days;
  
  RETURN v_total_amount;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate gratuity
CREATE OR REPLACE FUNCTION calculate_gratuity(
  p_employee_id UUID,
  p_date_of_exit DATE
)
RETURNS NUMERIC AS $$
DECLARE
  v_joining_date DATE;
  v_years_of_service NUMERIC;
  v_last_salary NUMERIC;
  v_gratuity NUMERIC;
BEGIN
  -- Get joining date
  SELECT date_of_joining INTO v_joining_date
  FROM staff
  WHERE id = p_employee_id;
  
  -- Calculate years of service
  v_years_of_service := EXTRACT(YEAR FROM AGE(p_date_of_exit, v_joining_date));
  
  -- Get last drawn salary
  SELECT basic_salary INTO v_last_salary
  FROM employee_payroll_details
  WHERE employee_id = p_employee_id
  AND is_active = true
  LIMIT 1;
  
  -- Calculate gratuity (Indian formula: Last Salary * Years / 2)
  -- Minimum 5 years of service required
  IF v_years_of_service >= 5 THEN
    v_gratuity := (v_last_salary * v_years_of_service) / 2;
    -- Cap at statutory limit (e.g., 20 lakhs in India)
    v_gratuity := LEAST(v_gratuity, 2000000);
  ELSE
    v_gratuity := 0;
  END IF;
  
  RETURN v_gratuity;
END;
$$ LANGUAGE plpgsql;

-- Benefit cost summary view
CREATE OR REPLACE VIEW benefit_cost_summary AS
SELECT
  bp.tenant_id,
  bp.plan_name,
  bp.plan_type,
  COUNT(ebe.id) as enrolled_employees,
  SUM(ebe.employer_contribution) as total_employer_cost,
  SUM(ebe.employee_contribution) as total_employee_contribution,
  SUM(ebe.total_premium) as total_premium_cost
FROM benefit_plans bp
LEFT JOIN employee_benefit_enrollments ebe ON ebe.benefit_plan_id = bp.id
WHERE bp.is_active = true
AND ebe.status = 'active'
GROUP BY bp.tenant_id, bp.id, bp.plan_name, bp.plan_type;

-- Enable RLS
ALTER TABLE benefit_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_benefit_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE benefit_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_encashment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE gratuity_calculations ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/benefits.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface BenefitPlan {
  id: string;
  planCode: string;
  planName: string;
  planType: string;
  description: string;
  coverageAmount: number;
  employerContribution: number;
  employeeContribution: number;
  isActive: boolean;
}

export interface Enrollment {
  id: string;
  employeeId: string;
  planName: string;
  enrollmentDate: string;
  status: string;
  employeeContribution: number;
  employerContribution: number;
}

export class BenefitsAPI {
  private supabase = createClient();

  async createBenefitPlan(params: {
    tenantId: string;
    planCode: string;
    planName: string;
    planType: string;
    description: string;
    employerContribution: number;
    employeeContribution: number;
    coverageAmount: number;
    effectiveFrom: Date;
  }): Promise<BenefitPlan> {
    const { data, error } = await this.supabase
      .from('benefit_plans')
      .insert({
        tenant_id: params.tenantId,
        plan_code: params.planCode,
        plan_name: params.planName,
        plan_type: params.planType,
        description: params.description,
        employer_contribution_type: 'fixed',
        employer_contribution_amount: params.employerContribution,
        employee_contribution_type: 'fixed',
        employee_contribution_amount: params.employeeContribution,
        coverage_amount: params.coverageAmount,
        effective_from: params.effectiveFrom.toISOString().split('T')[0],
        is_active: true,
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapPlan(data);
  }

  async enrollEmployee(params: {
    employeeId: string;
    benefitPlanId: string;
    enrollmentDate: Date;
    effectiveFrom: Date;
    dependents?: any[];
  }): Promise<Enrollment> {
    const { data: { user } } = await this.supabase.auth.getUser();

    // Get plan details for cost calculation
    const { data: plan } = await this.supabase
      .from('benefit_plans')
      .select('*')
      .eq('id', params.benefitPlanId)
      .single();

    if (!plan) throw new Error('Plan not found');

    const employeeContribution = plan.employee_contribution_amount || 0;
    const employerContribution = plan.employer_contribution_amount || 0;
    const totalPremium = employeeContribution + employerContribution;

    const { data, error } = await this.supabase
      .from('employee_benefit_enrollments')
      .insert({
        employee_id: params.employeeId,
        benefit_plan_id: params.benefitPlanId,
        enrollment_date: params.enrollmentDate.toISOString().split('T')[0],
        effective_from: params.effectiveFrom.toISOString().split('T')[0],
        dependents: params.dependents || [],
        dependent_count: params.dependents?.length || 0,
        employee_contribution: employeeContribution,
        employer_contribution: employerContribution,
        total_premium: totalPremium,
        approved_by: user?.id,
        approved_at: new Date().toISOString(),
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapEnrollment(data);
  }

  async getEmployeeBenefits(employeeId: string): Promise<Enrollment[]> {
    const { data, error } = await this.supabase
      .from('employee_benefit_enrollments')
      .select(`
        *,
        plan:benefit_plans(plan_name, plan_type)
      `)
      .eq('employee_id', employeeId)
      .eq('status', 'active');

    if (error) throw error;
    return (data || []).map(this.mapEnrollment);
  }

  async submitClaim(params: {
    enrollmentId: string;
    employeeId: string;
    benefitPlanId: string;
    claimType: string;
    claimedAmount: number;
    claimDescription: string;
    attachments?: any[];
  }) {
    const { data, error } = await this.supabase
      .from('benefit_claims')
      .insert({
        enrollment_id: params.enrollmentId,
        employee_id: params.employeeId,
        benefit_plan_id: params.benefitPlanId,
        claim_type: params.claimType,
        claim_date: new Date().toISOString().split('T')[0],
        claimed_amount: params.claimedAmount,
        claim_description: params.claimDescription,
        attachments: params.attachments || [],
        status: 'submitted',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async processLeaveEncashment(params: {
    employeeId: string;
    tenantId: string;
    financialYear: number;
    leaveType: string;
    eligibleDays: number;
    encashedDays: number;
  }) {
    // Calculate encashment amount
    const { data: amount, error: calcError } = await this.supabase.rpc(
      'calculate_leave_encashment',
      {
        p_employee_id: params.employeeId,
        p_leave_days: params.encashedDays,
        p_financial_year: params.financialYear,
      }
    );

    if (calcError) throw calcError;

    // Get per day rate
    const { data: payroll } = await this.supabase
      .from('employee_payroll_details')
      .select('basic_salary')
      .eq('employee_id', params.employeeId)
      .eq('is_active', true)
      .single();

    const perDayRate = payroll ? payroll.basic_salary / 30 : 0;

    const { data, error } = await this.supabase
      .from('leave_encashment_records')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        financial_year: params.financialYear,
        leave_type: params.leaveType,
        eligible_days: params.eligibleDays,
        encashed_days: params.encashedDays,
        per_day_rate: perDayRate,
        total_amount: amount,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async calculateGratuity(params: {
    employeeId: string;
    tenantId: string;
    dateOfExit: Date;
  }) {
    // Call gratuity calculation function
    const { data: amount, error: calcError } = await this.supabase.rpc(
      'calculate_gratuity',
      {
        p_employee_id: params.employeeId,
        p_date_of_exit: params.dateOfExit.toISOString().split('T')[0],
      }
    );

    if (calcError) throw calcError;

    // Get employee details
    const { data: employee } = await this.supabase
      .from('staff')
      .select('date_of_joining')
      .eq('id', params.employeeId)
      .single();

    const { data: payroll } = await this.supabase
      .from('employee_payroll_details')
      .select('basic_salary')
      .eq('employee_id', params.employeeId)
      .eq('is_active', true)
      .single();

    if (!employee || !payroll) throw new Error('Employee data not found');

    const yearsOfService =
      (params.dateOfExit.getTime() - new Date(employee.date_of_joining).getTime()) /
      (1000 * 60 * 60 * 24 * 365);

    const { data, error } = await this.supabase
      .from('gratuity_calculations')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        date_of_joining: employee.date_of_joining,
        date_of_exit: params.dateOfExit.toISOString().split('T')[0],
        years_of_service: yearsOfService,
        last_drawn_salary: payroll.basic_salary,
        calculated_amount: amount,
        payment_status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getBenefitCostSummary(tenantId: string) {
    const { data, error } = await this.supabase
      .from('benefit_cost_summary')
      .select('*')
      .eq('tenant_id', tenantId);

    if (error) throw error;
    return data;
  }

  private mapPlan(data: any): BenefitPlan {
    return {
      id: data.id,
      planCode: data.plan_code,
      planName: data.plan_name,
      planType: data.plan_type,
      description: data.description,
      coverageAmount: data.coverage_amount,
      employerContribution: data.employer_contribution_amount,
      employeeContribution: data.employee_contribution_amount,
      isActive: data.is_active,
    };
  }

  private mapEnrollment(data: any): Enrollment {
    return {
      id: data.id,
      employeeId: data.employee_id,
      planName: data.plan?.plan_name,
      enrollmentDate: data.enrollment_date,
      status: data.status,
      employeeContribution: data.employee_contribution,
      employerContribution: data.employer_contribution,
    };
  }
}

export const benefitsAPI = new BenefitsAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { BenefitsAPI } from '../benefits';

describe('BenefitsAPI', () => {
  it('creates benefit plan', async () => {
    const api = new BenefitsAPI();
    const plan = await api.createBenefitPlan({
      tenantId: 'test-tenant',
      planCode: 'HEALTH-01',
      planName: 'Health Insurance',
      planType: 'health_insurance',
      description: 'Comprehensive health coverage',
      employerContribution: 5000,
      employeeContribution: 1000,
      coverageAmount: 500000,
      effectiveFrom: new Date(),
    });

    expect(plan).toHaveProperty('id');
  });

  it('calculates leave encashment correctly', async () => {
    const api = new BenefitsAPI();
    const record = await api.processLeaveEncashment({
      employeeId: 'emp-1',
      tenantId: 'tenant-1',
      financialYear: 2025,
      leaveType: 'earned_leave',
      eligibleDays: 30,
      encashedDays: 15,
    });

    expect(record.total_amount).toBeGreaterThan(0);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Benefit plans configured
- [ ] Enrollment working
- [ ] Claims processing operational
- [ ] Leave encashment calculated
- [ ] Gratuity computation correct
- [ ] Cost tracking accurate
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-175 (Tax & Compliance)  
**Time**: 4 hours  
**AI-Ready**: 100%
