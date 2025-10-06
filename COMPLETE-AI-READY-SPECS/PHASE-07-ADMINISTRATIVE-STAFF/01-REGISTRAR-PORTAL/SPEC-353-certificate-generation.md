# SPEC-353: Certificate Generation System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-353  
**Title**: Certificate Generation System  
**Phase**: Phase 7 - Administrative Staff Portals  
**Portal**: Registrar Portal  
**Category**: Certificate Management  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 10 hours  
**Dependencies**: SPEC-351, SPEC-352  

---

## 📋 DESCRIPTION

Automated certificate generation system supporting multiple certificate types (course completion, character, bonafide, migration, provisional), customizable templates, bulk generation, digital signatures, QR code verification, and PDF generation with watermarks.

---

## 🎯 SUCCESS CRITERIA

- [ ] Multiple certificate templates available
- [ ] Single and bulk certificate generation working
- [ ] Digital signature integration functional
- [ ] QR code verification system operational
- [ ] PDF generation with watermarks
- [ ] Template customization working
- [ ] Certificate request workflow complete
- [ ] Performance optimized (<5s per certificate)
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Certificate Templates
CREATE TABLE IF NOT EXISTS certificate_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Template details
  template_name VARCHAR(255) NOT NULL,
  template_type VARCHAR(100) NOT NULL, -- course_completion, character, bonafide, etc.
  template_code VARCHAR(50) UNIQUE NOT NULL,
  
  -- Template content
  header_html TEXT,
  body_template TEXT NOT NULL, -- With placeholders like {{student_name}}
  footer_html TEXT,
  
  -- Styling
  css_styles TEXT,
  page_size VARCHAR(20) DEFAULT 'A4', -- A4, Letter, etc.
  orientation VARCHAR(20) DEFAULT 'portrait', -- portrait, landscape
  
  -- Branding
  logo_url TEXT,
  seal_url TEXT,
  watermark_url TEXT,
  background_url TEXT,
  
  -- Signatures
  signature_fields JSONB DEFAULT '[]', -- Array of {label, position}
  
  -- Settings
  is_active BOOLEAN DEFAULT true,
  requires_approval BOOLEAN DEFAULT false,
  auto_generate_number BOOLEAN DEFAULT true,
  number_prefix VARCHAR(20),
  number_format VARCHAR(50) DEFAULT 'CERT-{{year}}-{{sequence}}',
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_template_type CHECK (
    template_type IN (
      'course_completion', 'character_certificate', 'bonafide_certificate',
      'migration_certificate', 'provisional_certificate', 'conduct_certificate',
      'study_certificate', 'leaving_certificate', 'custom'
    )
  )
);

CREATE INDEX ON certificate_templates(tenant_id, branch_id, template_type);
CREATE INDEX ON certificate_templates(template_code);

-- Certificate Requests
CREATE TABLE IF NOT EXISTS certificate_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Request details
  request_number VARCHAR(100) UNIQUE NOT NULL,
  student_id UUID NOT NULL REFERENCES students(id),
  template_id UUID NOT NULL REFERENCES certificate_templates(id),
  certificate_type VARCHAR(100) NOT NULL,
  
  -- Request info
  requested_by UUID NOT NULL REFERENCES auth.users(id), -- Student, parent, or admin
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  purpose TEXT,
  quantity INTEGER DEFAULT 1,
  
  -- Priority
  priority VARCHAR(20) DEFAULT 'normal', -- normal, urgent
  required_by DATE,
  
  -- Custom data
  custom_fields JSONB DEFAULT '{}', -- Additional data for template
  
  -- Status workflow
  status VARCHAR(50) DEFAULT 'pending',
  assigned_to UUID REFERENCES auth.users(id),
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Generation
  generated_at TIMESTAMP WITH TIME ZONE,
  generated_by UUID REFERENCES auth.users(id),
  certificate_number VARCHAR(100),
  certificate_url TEXT,
  qr_code_data TEXT,
  
  -- Issue
  issued_at TIMESTAMP WITH TIME ZONE,
  issued_by UUID REFERENCES auth.users(id),
  issued_to VARCHAR(255), -- Recipient name
  
  -- Payment (if applicable)
  payment_required BOOLEAN DEFAULT false,
  payment_amount DECIMAL(10,2),
  payment_status VARCHAR(20) DEFAULT 'pending',
  payment_id UUID,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (
    status IN ('pending', 'approved', 'rejected', 'in_progress', 'generated', 'issued', 'cancelled')
  ),
  CONSTRAINT valid_priority CHECK (
    priority IN ('normal', 'urgent')
  )
);

CREATE INDEX ON certificate_requests(tenant_id, branch_id, status);
CREATE INDEX ON certificate_requests(student_id);
CREATE INDEX ON certificate_requests(certificate_number);
CREATE INDEX ON certificate_requests(requested_at DESC);

-- Certificate Verification Log
CREATE TABLE IF NOT EXISTS certificate_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Certificate info
  certificate_number VARCHAR(100) NOT NULL,
  certificate_request_id UUID REFERENCES certificate_requests(id),
  
  -- Verification details
  verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_by VARCHAR(255), -- Name or organization
  verification_method VARCHAR(50), -- qr_code, manual, api
  ip_address INET,
  user_agent TEXT,
  
  -- Result
  verification_result VARCHAR(20) DEFAULT 'valid', -- valid, invalid, expired
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON certificate_verifications(certificate_number);
CREATE INDEX ON certificate_verifications(verified_at DESC);

-- Certificate Numbering Sequence
CREATE TABLE IF NOT EXISTS certificate_sequences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Sequence details
  template_id UUID NOT NULL REFERENCES certificate_templates(id),
  year INTEGER NOT NULL,
  current_sequence INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, template_id, year)
);

-- Function to generate certificate number
CREATE OR REPLACE FUNCTION generate_certificate_number(
  p_template_id UUID
)
RETURNS VARCHAR AS $$
DECLARE
  v_number VARCHAR(100);
  v_sequence INTEGER;
  v_format VARCHAR(50);
  v_prefix VARCHAR(20);
  v_year INTEGER;
  v_tenant_id UUID;
  v_branch_id UUID;
BEGIN
  -- Get session info
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  v_year := EXTRACT(YEAR FROM CURRENT_DATE);
  
  -- Get template format
  SELECT number_format, number_prefix
  INTO v_format, v_prefix
  FROM certificate_templates
  WHERE id = p_template_id;
  
  -- Get and increment sequence
  INSERT INTO certificate_sequences (tenant_id, branch_id, template_id, year, current_sequence)
  VALUES (v_tenant_id, v_branch_id, p_template_id, v_year, 1)
  ON CONFLICT (tenant_id, branch_id, template_id, year)
  DO UPDATE SET current_sequence = certificate_sequences.current_sequence + 1
  RETURNING current_sequence INTO v_sequence;
  
  -- Generate number from format
  v_number := v_format;
  v_number := REPLACE(v_number, '{{year}}', v_year::TEXT);
  v_number := REPLACE(v_number, '{{sequence}}', LPAD(v_sequence::TEXT, 5, '0'));
  v_number := REPLACE(v_number, '{{prefix}}', COALESCE(v_prefix, ''));
  
  RETURN v_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate certificate
CREATE OR REPLACE FUNCTION generate_certificate(
  p_request_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_certificate_number VARCHAR(100);
  v_template_id UUID;
  v_student_id UUID;
  v_qr_data JSON;
  v_generated_by UUID;
BEGIN
  v_generated_by := auth.uid();
  
  -- Get request details
  SELECT template_id, student_id
  INTO v_template_id, v_student_id
  FROM certificate_requests
  WHERE id = p_request_id;
  
  -- Generate certificate number
  v_certificate_number := generate_certificate_number(v_template_id);
  
  -- Create QR code data
  v_qr_data := json_build_object(
    'certificate_number', v_certificate_number,
    'student_id', v_student_id,
    'generated_at', NOW(),
    'verify_url', 'https://app.schoolms.com/verify/' || v_certificate_number
  );
  
  -- Update request
  UPDATE certificate_requests
  SET
    status = 'generated',
    certificate_number = v_certificate_number,
    qr_code_data = v_qr_data::TEXT,
    generated_at = NOW(),
    generated_by = v_generated_by,
    updated_at = NOW()
  WHERE id = p_request_id;
  
  RETURN json_build_object(
    'certificate_number', v_certificate_number,
    'qr_data', v_qr_data
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify certificate
CREATE OR REPLACE FUNCTION verify_certificate(
  p_certificate_number VARCHAR,
  p_verified_by VARCHAR DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_certificate RECORD;
  v_student RECORD;
  v_result JSON;
BEGIN
  -- Find certificate
  SELECT cr.*, s.student_name, s.student_code
  INTO v_certificate
  FROM certificate_requests cr
  JOIN students s ON cr.student_id = s.id
  WHERE cr.certificate_number = p_certificate_number;
  
  IF NOT FOUND THEN
    -- Log failed verification
    INSERT INTO certificate_verifications (
      tenant_id, certificate_number, verification_result, verified_by
    ) VALUES (
      current_setting('app.current_tenant_id', true)::UUID,
      p_certificate_number, 'invalid', p_verified_by
    );
    
    RETURN json_build_object(
      'valid', false,
      'message', 'Certificate not found'
    );
  END IF;
  
  -- Log successful verification
  INSERT INTO certificate_verifications (
    tenant_id, certificate_number, certificate_request_id,
    verification_result, verified_by
  ) VALUES (
    v_certificate.tenant_id, p_certificate_number, v_certificate.id,
    'valid', p_verified_by
  );
  
  -- Return certificate details
  v_result := json_build_object(
    'valid', true,
    'certificate_number', v_certificate.certificate_number,
    'certificate_type', v_certificate.certificate_type,
    'student_name', v_certificate.student_name,
    'student_code', v_certificate.student_code,
    'issued_at', v_certificate.issued_at,
    'issued_by', v_certificate.issued_by
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE certificate_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificate_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificate_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificate_sequences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY certificate_templates_isolation ON certificate_templates
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY certificate_requests_isolation ON certificate_requests
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/certificates.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import { generatePDF } from '@/lib/pdf-generator';

export interface CertificateTemplate {
  id: string;
  templateName: string;
  templateType: string;
  templateCode: string;
  bodyTemplate: string;
  isActive: boolean;
}

export interface CertificateRequest {
  id: string;
  requestNumber: string;
  studentId: string;
  studentName: string;
  certificateType: string;
  status: string;
  priority: string;
  requestedAt: string;
  certificateNumber?: string;
  certificateUrl?: string;
}

export class CertificatesAPI {
  private supabase = createClient();

  /**
   * Get certificate templates
   */
  async getTemplates(type?: string): Promise<CertificateTemplate[]> {
    let query = this.supabase
      .from('certificate_templates')
      .select('*')
      .eq('is_active', true);
    
    if (type) {
      query = query.eq('template_type', type);
    }

    const { data, error } = await query.order('template_name');
    if (error) throw error;
    
    return data.map(t => ({
      id: t.id,
      templateName: t.template_name,
      templateType: t.template_type,
      templateCode: t.template_code,
      bodyTemplate: t.body_template,
      isActive: t.is_active
    }));
  }

  /**
   * Create certificate request
   */
  async createRequest(params: {
    studentId: string;
    templateId: string;
    certificateType: string;
    purpose?: string;
    priority?: 'normal' | 'urgent';
    customFields?: Record<string, any>;
  }): Promise<CertificateRequest> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Generate request number
    const requestNumber = `REQ-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    const { data, error } = await this.supabase
      .from('certificate_requests')
      .insert({
        request_number: requestNumber,
        student_id: params.studentId,
        template_id: params.templateId,
        certificate_type: params.certificateType,
        requested_by: user.id,
        purpose: params.purpose,
        priority: params.priority || 'normal',
        custom_fields: params.customFields || {}
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapToCertificateRequest(data);
  }

  /**
   * Generate certificate
   */
  async generateCertificate(requestId: string): Promise<{
    certificateNumber: string;
    qrData: any;
  }> {
    const { data, error } = await this.supabase
      .rpc('generate_certificate', {
        p_request_id: requestId
      });

    if (error) throw error;
    return {
      certificateNumber: data.certificate_number,
      qrData: data.qr_data
    };
  }

  /**
   * Generate PDF
   */
  async generatePDF(requestId: string): Promise<Blob> {
    // Get certificate request with all details
    const { data: request, error } = await this.supabase
      .from('certificate_requests')
      .select(`
        *,
        student:students(*),
        template:certificate_templates(*)
      `)
      .eq('id', requestId)
      .single();

    if (error) throw error;

    // Generate PDF using template
    const pdfBlob = await generatePDF({
      template: request.template.body_template,
      data: {
        ...request.custom_fields,
        student_name: request.student.student_name,
        student_code: request.student.student_code,
        certificate_number: request.certificate_number,
        issue_date: new Date().toLocaleDateString(),
        qr_code_data: request.qr_code_data
      },
      styles: request.template.css_styles,
      watermark: request.template.watermark_url,
      pageSize: request.template.page_size
    });

    // Upload to storage
    const fileName = `certificates/${requestId}/${request.certificate_number}.pdf`;
    const { error: uploadError } = await this.supabase
      .storage
      .from('certificates')
      .upload(fileName, pdfBlob);

    if (uploadError) throw uploadError;

    // Update request with URL
    const { data: { publicUrl } } = this.supabase
      .storage
      .from('certificates')
      .getPublicUrl(fileName);

    await this.supabase
      .from('certificate_requests')
      .update({ certificate_url: publicUrl })
      .eq('id', requestId);

    return pdfBlob;
  }

  /**
   * Bulk generate certificates
   */
  async bulkGenerate(requestIds: string[]): Promise<void> {
    for (const requestId of requestIds) {
      await this.generateCertificate(requestId);
      await this.generatePDF(requestId);
    }
  }

  /**
   * Verify certificate
   */
  async verifyCertificate(certificateNumber: string): Promise<any> {
    const { data, error } = await this.supabase
      .rpc('verify_certificate', {
        p_certificate_number: certificateNumber
      });

    if (error) throw error;
    return data;
  }

  /**
   * Get pending requests
   */
  async getPendingRequests(): Promise<CertificateRequest[]> {
    const { data, error } = await this.supabase
      .from('certificate_requests')
      .select(`
        *,
        student:students(student_name, student_code)
      `)
      .in('status', ['pending', 'approved'])
      .order('priority', { ascending: false })
      .order('requested_at', { ascending: true });

    if (error) throw error;
    return data.map(this.mapToCertificateRequest);
  }

  private mapToCertificateRequest(data: any): CertificateRequest {
    return {
      id: data.id,
      requestNumber: data.request_number,
      studentId: data.student_id,
      studentName: data.student?.student_name,
      certificateType: data.certificate_type,
      status: data.status,
      priority: data.priority,
      requestedAt: data.requested_at,
      certificateNumber: data.certificate_number,
      certificateUrl: data.certificate_url
    };
  }
}

export const certificatesAPI = new CertificatesAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { certificatesAPI } from '@/lib/api/certificates';

describe('CertificatesAPI', () => {
  it('should create certificate request', async () => {
    const request = await certificatesAPI.createRequest({
      studentId: 'student-id',
      templateId: 'template-id',
      certificateType: 'course_completion',
      purpose: 'Job application'
    });
    
    expect(request.id).toBeDefined();
    expect(request.status).toBe('pending');
  });

  it('should generate certificate number', async () => {
    const result = await certificatesAPI.generateCertificate('request-id');
    expect(result.certificateNumber).toBeDefined();
    expect(result.qrData).toBeDefined();
  });
});
```

---

## ✅ DEFINITION OF DONE

- [ ] All database tables created
- [ ] Template management working
- [ ] Certificate generation functional
- [ ] PDF generation with QR codes
- [ ] Verification system operational
- [ ] Bulk generation working
- [ ] Tests passing (85%+ coverage)
- [ ] Performance optimized
