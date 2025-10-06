# SPEC-179: Employee Database & Profiles

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-179  
**Title**: Employee Database & Profile Management  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Employee Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-012  

---

## 📋 DESCRIPTION

Comprehensive employee database with detailed profiles, document management, career history, emergency contacts, skills tracking, certifications, and self-service profile updates with approval workflows.

---

## 🎯 SUCCESS CRITERIA

- [ ] Employee profiles complete
- [ ] Document management operational
- [ ] Career history tracked
- [ ] Skills matrix functional
- [ ] Certification tracking working
- [ ] Self-service updates enabled
- [ ] Search and filters working
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Employee Documents
CREATE TABLE IF NOT EXISTS employee_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Document details
  document_type VARCHAR(50) NOT NULL, -- resume, offer_letter, id_proof, address_proof, certificate, contract
  document_name VARCHAR(200) NOT NULL,
  document_number VARCHAR(100),
  
  -- File
  file_url TEXT NOT NULL,
  file_size_bytes BIGINT,
  file_type VARCHAR(50),
  
  -- Validity
  issue_date DATE,
  expiry_date DATE,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  
  -- Access control
  is_confidential BOOLEAN DEFAULT false,
  accessible_to VARCHAR(50)[] DEFAULT ARRAY['hr', 'employee'],
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON employee_documents(employee_id);
CREATE INDEX ON employee_documents(tenant_id);
CREATE INDEX ON employee_documents(expiry_date) WHERE expiry_date IS NOT NULL;

-- Emergency Contacts
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  
  -- Contact details
  contact_name VARCHAR(200) NOT NULL,
  relationship VARCHAR(50) NOT NULL,
  phone_primary VARCHAR(20) NOT NULL,
  phone_secondary VARCHAR(20),
  email VARCHAR(200),
  address TEXT,
  
  -- Priority
  is_primary BOOLEAN DEFAULT false,
  priority_order INTEGER DEFAULT 1,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON emergency_contacts(employee_id);

-- Employee Skills
CREATE TABLE IF NOT EXISTS employee_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Skill details
  skill_name VARCHAR(200) NOT NULL,
  skill_category VARCHAR(100), -- technical, soft_skill, language, certification
  proficiency_level VARCHAR(50), -- beginner, intermediate, advanced, expert
  
  -- Validation
  years_of_experience NUMERIC(4,1),
  last_used_date DATE,
  
  -- Verification
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  
  -- Source
  source VARCHAR(50), -- self_reported, manager_validated, assessment, certification
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON employee_skills(employee_id);
CREATE INDEX ON employee_skills(tenant_id, skill_category);

-- Employee Certifications
CREATE TABLE IF NOT EXISTS employee_certifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Certification details
  certification_name VARCHAR(200) NOT NULL,
  issuing_organization VARCHAR(200) NOT NULL,
  certification_number VARCHAR(100),
  
  -- Dates
  issue_date DATE NOT NULL,
  expiry_date DATE,
  
  -- Document
  certificate_url TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, expired, revoked
  
  -- Verification
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  
  -- Reminders
  renewal_reminder_sent BOOLEAN DEFAULT false,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON employee_certifications(employee_id);
CREATE INDEX ON employee_certifications(expiry_date) WHERE expiry_date IS NOT NULL;

-- Career History (Promotions, Transfers, Role Changes)
CREATE TABLE IF NOT EXISTS career_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Change details
  change_type VARCHAR(50) NOT NULL, -- promotion, transfer, role_change, department_change, salary_revision
  effective_date DATE NOT NULL,
  
  -- Previous state
  previous_designation VARCHAR(100),
  previous_department VARCHAR(100),
  previous_branch_id UUID REFERENCES branches(id),
  previous_salary NUMERIC(15,2),
  
  -- New state
  new_designation VARCHAR(100),
  new_department VARCHAR(100),
  new_branch_id UUID REFERENCES branches(id),
  new_salary NUMERIC(15,2),
  
  -- Reason
  reason TEXT,
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON career_history(employee_id, effective_date);

-- Profile Update Requests (Self-service with approval)
CREATE TABLE IF NOT EXISTS profile_update_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Update details
  field_name VARCHAR(100) NOT NULL, -- email, phone, address, emergency_contact
  current_value TEXT,
  requested_value TEXT NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
  
  -- Reason
  reason_for_change TEXT,
  rejection_reason TEXT,
  
  -- Approval
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  
  -- Supporting document
  supporting_document_url TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected'))
);

CREATE INDEX ON profile_update_requests(employee_id, status);

-- Function to check expiring documents/certifications
CREATE OR REPLACE FUNCTION get_expiring_documents(
  p_tenant_id UUID,
  p_days_before INTEGER DEFAULT 30
)
RETURNS TABLE (
  employee_id UUID,
  employee_name VARCHAR,
  document_type VARCHAR,
  document_name VARCHAR,
  expiry_date DATE,
  days_until_expiry INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ed.employee_id,
    s.full_name,
    ed.document_type,
    ed.document_name,
    ed.expiry_date,
    (ed.expiry_date - CURRENT_DATE)::INTEGER as days_until_expiry
  FROM employee_documents ed
  JOIN staff s ON s.id = ed.employee_id
  WHERE ed.tenant_id = p_tenant_id
  AND ed.expiry_date IS NOT NULL
  AND ed.expiry_date <= CURRENT_DATE + (p_days_before || ' days')::INTERVAL
  AND ed.expiry_date >= CURRENT_DATE
  
  UNION ALL
  
  SELECT
    ec.employee_id,
    s.full_name,
    'certification'::VARCHAR,
    ec.certification_name,
    ec.expiry_date,
    (ec.expiry_date - CURRENT_DATE)::INTEGER
  FROM employee_certifications ec
  JOIN staff s ON s.id = ec.employee_id
  WHERE ec.tenant_id = p_tenant_id
  AND ec.expiry_date IS NOT NULL
  AND ec.expiry_date <= CURRENT_DATE + (p_days_before || ' days')::INTERVAL
  AND ec.expiry_date >= CURRENT_DATE
  
  ORDER BY expiry_date;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update certification status
CREATE OR REPLACE FUNCTION update_certification_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expiry_date < CURRENT_DATE AND NEW.status = 'active' THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_certification_expiry
  BEFORE UPDATE ON employee_certifications
  FOR EACH ROW
  EXECUTE FUNCTION update_certification_status();

-- Enable RLS
ALTER TABLE employee_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE career_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_update_requests ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/employee-profiles.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface EmployeeProfile {
  id: string;
  fullName: string;
  employeeCode: string;
  designation: string;
  department: string;
  email: string;
  phone: string;
  dateOfJoining: string;
  status: string;
}

export interface EmployeeDocument {
  id: string;
  documentType: string;
  documentName: string;
  fileUrl: string;
  expiryDate?: string;
  isVerified: boolean;
}

export class EmployeeProfilesAPI {
  private supabase = createClient();

  async getEmployeeProfile(employeeId: string): Promise<EmployeeProfile> {
    const { data, error } = await this.supabase
      .from('staff')
      .select('*')
      .eq('id', employeeId)
      .single();

    if (error) throw error;

    return {
      id: data.id,
      fullName: data.full_name,
      employeeCode: data.employee_code,
      designation: data.designation,
      department: data.department,
      email: data.email,
      phone: data.phone,
      dateOfJoining: data.date_of_joining,
      status: data.status,
    };
  }

  async searchEmployees(params: {
    tenantId: string;
    query?: string;
    department?: string;
    status?: string;
    limit?: number;
  }): Promise<EmployeeProfile[]> {
    let query = this.supabase
      .from('staff')
      .select('*')
      .eq('tenant_id', params.tenantId);

    if (params.query) {
      query = query.or(`full_name.ilike.%${params.query}%,employee_code.ilike.%${params.query}%`);
    }

    if (params.department) {
      query = query.eq('department', params.department);
    }

    if (params.status) {
      query = query.eq('status', params.status);
    }

    if (params.limit) {
      query = query.limit(params.limit);
    }

    const { data, error } = await query.order('full_name');

    if (error) throw error;

    return (data || []).map(emp => ({
      id: emp.id,
      fullName: emp.full_name,
      employeeCode: emp.employee_code,
      designation: emp.designation,
      department: emp.department,
      email: emp.email,
      phone: emp.phone,
      dateOfJoining: emp.date_of_joining,
      status: emp.status,
    }));
  }

  async uploadDocument(params: {
    employeeId: string;
    tenantId: string;
    documentType: string;
    documentName: string;
    file: File;
    expiryDate?: Date;
  }): Promise<EmployeeDocument> {
    // Upload file to storage
    const filePath = `${params.tenantId}/${params.employeeId}/${Date.now()}_${params.file.name}`;
    const { data: uploadData, error: uploadError } = await this.supabase.storage
      .from('employee-documents')
      .upload(filePath, params.file);

    if (uploadError) throw uploadError;

    // Get public URL
    const { data: urlData } = this.supabase.storage
      .from('employee-documents')
      .getPublicUrl(filePath);

    // Create document record
    const { data, error } = await this.supabase
      .from('employee_documents')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        document_type: params.documentType,
        document_name: params.documentName,
        file_url: urlData.publicUrl,
        file_size_bytes: params.file.size,
        file_type: params.file.type,
        expiry_date: params.expiryDate?.toISOString().split('T')[0],
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      documentType: data.document_type,
      documentName: data.document_name,
      fileUrl: data.file_url,
      expiryDate: data.expiry_date,
      isVerified: data.is_verified,
    };
  }

  async getEmployeeDocuments(employeeId: string): Promise<EmployeeDocument[]> {
    const { data, error } = await this.supabase
      .from('employee_documents')
      .select('*')
      .eq('employee_id', employeeId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map(doc => ({
      id: doc.id,
      documentType: doc.document_type,
      documentName: doc.document_name,
      fileUrl: doc.file_url,
      expiryDate: doc.expiry_date,
      isVerified: doc.is_verified,
    }));
  }

  async addSkill(params: {
    employeeId: string;
    tenantId: string;
    skillName: string;
    skillCategory: string;
    proficiencyLevel: string;
    yearsOfExperience?: number;
  }) {
    const { data, error } = await this.supabase
      .from('employee_skills')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        skill_name: params.skillName,
        skill_category: params.skillCategory,
        proficiency_level: params.proficiencyLevel,
        years_of_experience: params.yearsOfExperience,
        source: 'self_reported',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getEmployeeSkills(employeeId: string) {
    const { data, error } = await this.supabase
      .from('employee_skills')
      .select('*')
      .eq('employee_id', employeeId)
      .order('proficiency_level', { ascending: false });

    if (error) throw error;

    return data.map(skill => ({
      id: skill.id,
      skillName: skill.skill_name,
      skillCategory: skill.skill_category,
      proficiencyLevel: skill.proficiency_level,
      yearsOfExperience: skill.years_of_experience,
      isVerified: skill.is_verified,
    }));
  }

  async addCertification(params: {
    employeeId: string;
    tenantId: string;
    certificationName: string;
    issuingOrganization: string;
    issueDate: Date;
    expiryDate?: Date;
    certificateUrl?: string;
  }) {
    const { data, error } = await this.supabase
      .from('employee_certifications')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        certification_name: params.certificationName,
        issuing_organization: params.issuingOrganization,
        issue_date: params.issueDate.toISOString().split('T')[0],
        expiry_date: params.expiryDate?.toISOString().split('T')[0],
        certificate_url: params.certificateUrl,
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async requestProfileUpdate(params: {
    employeeId: string;
    tenantId: string;
    fieldName: string;
    currentValue: string;
    requestedValue: string;
    reason: string;
  }) {
    const { data, error } = await this.supabase
      .from('profile_update_requests')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        field_name: params.fieldName,
        current_value: params.currentValue,
        requested_value: params.requestedValue,
        reason_for_change: params.reason,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getExpiringDocuments(params: {
    tenantId: string;
    daysBefore?: number;
  }) {
    const { data, error } = await this.supabase.rpc('get_expiring_documents', {
      p_tenant_id: params.tenantId,
      p_days_before: params.daysBefore || 30,
    });

    if (error) throw error;

    return data.map((item: any) => ({
      employeeId: item.employee_id,
      employeeName: item.employee_name,
      documentType: item.document_type,
      documentName: item.document_name,
      expiryDate: item.expiry_date,
      daysUntilExpiry: item.days_until_expiry,
    }));
  }

  async getCareerHistory(employeeId: string) {
    const { data, error } = await this.supabase
      .from('career_history')
      .select('*')
      .eq('employee_id', employeeId)
      .order('effective_date', { ascending: false });

    if (error) throw error;

    return data.map(record => ({
      id: record.id,
      changeType: record.change_type,
      effectiveDate: record.effective_date,
      previousDesignation: record.previous_designation,
      newDesignation: record.new_designation,
      reason: record.reason,
    }));
  }
}

export const employeeProfilesAPI = new EmployeeProfilesAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { EmployeeProfilesAPI } from '../employee-profiles';

describe('EmployeeProfilesAPI', () => {
  it('retrieves employee profile', async () => {
    const api = new EmployeeProfilesAPI();
    const profile = await api.getEmployeeProfile('emp-123');

    expect(profile).toHaveProperty('fullName');
    expect(profile).toHaveProperty('employeeCode');
  });

  it('searches employees correctly', async () => {
    const api = new EmployeeProfilesAPI();
    const results = await api.searchEmployees({
      tenantId: 'test-tenant',
      query: 'John',
    });

    expect(Array.isArray(results)).toBe(true);
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Employee profiles complete
- [ ] Document upload working
- [ ] Skills tracking functional
- [ ] Certifications managed
- [ ] Career history tracked
- [ ] Self-service updates enabled
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-180 (Recruitment)  
**Time**: 5 hours  
**AI-Ready**: 100%
