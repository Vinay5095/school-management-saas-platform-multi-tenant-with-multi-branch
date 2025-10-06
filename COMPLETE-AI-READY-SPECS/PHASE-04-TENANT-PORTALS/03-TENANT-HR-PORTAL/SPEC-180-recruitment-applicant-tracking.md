# SPEC-180: Recruitment & Applicant Tracking

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-180  
**Title**: Recruitment & Applicant Tracking System (ATS)  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Recruitment  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-179  

---

## 📋 DESCRIPTION

Complete Applicant Tracking System with job posting, application management, interview scheduling, candidate evaluation, offer management, and recruitment analytics. Supports multiple hiring stages, collaborative hiring, and candidate communication.

---

## 🎯 SUCCESS CRITERIA

- [ ] Job posting management working
- [ ] Application tracking operational
- [ ] Interview scheduling functional
- [ ] Candidate evaluation working
- [ ] Offer management operational
- [ ] Recruitment pipeline visible
- [ ] Analytics available
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Job Openings
CREATE TABLE IF NOT EXISTS job_openings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Job details
  job_title VARCHAR(200) NOT NULL,
  job_code VARCHAR(50) UNIQUE NOT NULL,
  department VARCHAR(100) NOT NULL,
  employment_type VARCHAR(50) NOT NULL, -- permanent, contract, part_time, internship
  
  -- Position details
  number_of_positions INTEGER DEFAULT 1,
  positions_filled INTEGER DEFAULT 0,
  
  -- Job description
  job_description TEXT NOT NULL,
  responsibilities TEXT,
  requirements TEXT,
  qualifications TEXT,
  
  -- Compensation
  salary_min NUMERIC(15,2),
  salary_max NUMERIC(15,2),
  salary_currency VARCHAR(10) DEFAULT 'INR',
  
  -- Dates
  posted_date DATE NOT NULL DEFAULT CURRENT_DATE,
  application_deadline DATE,
  target_joining_date DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, open, on_hold, closed, cancelled
  
  -- Hiring team
  hiring_manager_id UUID REFERENCES auth.users(id),
  recruiter_id UUID REFERENCES auth.users(id),
  
  -- Settings
  is_internal_only BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT false,
  
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'open', 'on_hold', 'closed', 'cancelled'))
);

CREATE INDEX ON job_openings(tenant_id, status);
CREATE INDEX ON job_openings(job_code);

-- Job Applications
CREATE TABLE IF NOT EXISTS job_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_opening_id UUID NOT NULL REFERENCES job_openings(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Application details
  application_number VARCHAR(50) UNIQUE NOT NULL,
  application_date DATE NOT NULL DEFAULT CURRENT_DATE,
  application_source VARCHAR(50), -- career_site, referral, job_board, linkedin, direct
  
  -- Candidate details
  candidate_name VARCHAR(200) NOT NULL,
  candidate_email VARCHAR(200) NOT NULL,
  candidate_phone VARCHAR(20) NOT NULL,
  
  -- Resume
  resume_url TEXT NOT NULL,
  cover_letter TEXT,
  
  -- Experience
  total_experience_years NUMERIC(4,1),
  current_company VARCHAR(200),
  current_designation VARCHAR(200),
  current_ctc NUMERIC(15,2),
  expected_ctc NUMERIC(15,2),
  notice_period_days INTEGER,
  
  -- Additional
  portfolio_url TEXT,
  linkedin_url TEXT,
  other_documents JSONB,
  
  -- Screening
  current_stage VARCHAR(50) DEFAULT 'applied', -- applied, screening, interview, offer, hired, rejected
  screening_score INTEGER,
  screening_notes TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, shortlisted, rejected, withdrawn, hired
  rejection_reason TEXT,
  
  -- Assignment
  assigned_to UUID REFERENCES auth.users(id),
  
  -- Tracking
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  hired_as_employee_id UUID REFERENCES staff(id),
  
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_stage CHECK (current_stage IN ('applied', 'screening', 'interview', 'assessment', 'offer', 'hired', 'rejected'))
);

CREATE INDEX ON job_applications(job_opening_id);
CREATE INDEX ON job_applications(tenant_id, current_stage);
CREATE INDEX ON job_applications(candidate_email);

-- Interview Schedules
CREATE TABLE IF NOT EXISTS interview_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES job_applications(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Interview details
  interview_round VARCHAR(50) NOT NULL, -- screening, technical, hr, managerial, final
  interview_type VARCHAR(50) NOT NULL, -- phone, video, in_person
  
  -- Scheduling
  scheduled_date DATE NOT NULL,
  scheduled_time TIME NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  
  -- Location
  meeting_link TEXT,
  meeting_location TEXT,
  
  -- Interviewers
  interviewer_ids UUID[] NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled, rescheduled, no_show
  
  -- Feedback
  feedback_submitted BOOLEAN DEFAULT false,
  
  -- Notifications
  reminder_sent BOOLEAN DEFAULT false,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('scheduled', 'completed', 'cancelled', 'rescheduled', 'no_show'))
);

CREATE INDEX ON interview_schedules(application_id);
CREATE INDEX ON interview_schedules(scheduled_date, status);

-- Interview Feedback
CREATE TABLE IF NOT EXISTS interview_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_schedule_id UUID NOT NULL REFERENCES interview_schedules(id),
  application_id UUID NOT NULL REFERENCES job_applications(id),
  
  -- Interviewer
  interviewer_id UUID NOT NULL REFERENCES auth.users(id),
  interviewer_name VARCHAR(200),
  
  -- Rating
  overall_rating INTEGER NOT NULL, -- 1-5
  technical_rating INTEGER,
  communication_rating INTEGER,
  cultural_fit_rating INTEGER,
  
  -- Assessment
  strengths TEXT,
  weaknesses TEXT,
  detailed_feedback TEXT,
  
  -- Recommendation
  recommendation VARCHAR(50) NOT NULL, -- strong_yes, yes, maybe, no, strong_no
  
  -- Skills evaluated
  skills_evaluated JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_rating CHECK (overall_rating BETWEEN 1 AND 5),
  CONSTRAINT valid_recommendation CHECK (recommendation IN ('strong_yes', 'yes', 'maybe', 'no', 'strong_no'))
);

CREATE INDEX ON interview_feedback(application_id);

-- Job Offers
CREATE TABLE IF NOT EXISTS job_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES job_applications(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Offer details
  offer_letter_number VARCHAR(50) UNIQUE NOT NULL,
  designation VARCHAR(200) NOT NULL,
  department VARCHAR(100) NOT NULL,
  
  -- Compensation
  annual_ctc NUMERIC(15,2) NOT NULL,
  basic_salary NUMERIC(15,2) NOT NULL,
  allowances JSONB,
  
  -- Terms
  joining_date DATE NOT NULL,
  probation_period_months INTEGER DEFAULT 3,
  notice_period_months INTEGER DEFAULT 2,
  
  -- Documents
  offer_letter_url TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, sent, accepted, rejected, withdrawn
  sent_at TIMESTAMP WITH TIME ZONE,
  responded_at TIMESTAMP WITH TIME ZONE,
  
  -- Validity
  valid_until DATE,
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'withdrawn', 'expired'))
);

CREATE INDEX ON job_offers(application_id);
CREATE INDEX ON job_offers(status);

-- Function to generate application number
CREATE OR REPLACE FUNCTION generate_application_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.application_number := 'APP-' || 
    TO_CHAR(NOW(), 'YYYYMM') || '-' ||
    LPAD(NEXTVAL('application_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS application_seq;

CREATE TRIGGER set_application_number
  BEFORE INSERT ON job_applications
  FOR EACH ROW
  WHEN (NEW.application_number IS NULL OR NEW.application_number = '')
  EXECUTE FUNCTION generate_application_number();

-- Function to get recruitment pipeline
CREATE OR REPLACE FUNCTION get_recruitment_pipeline(
  p_tenant_id UUID,
  p_job_opening_id UUID DEFAULT NULL
)
RETURNS TABLE (
  stage VARCHAR,
  application_count BIGINT,
  avg_days_in_stage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ja.current_stage,
    COUNT(*) as application_count,
    AVG(EXTRACT(DAY FROM NOW() - ja.updated_at)) as avg_days_in_stage
  FROM job_applications ja
  WHERE ja.tenant_id = p_tenant_id
  AND (p_job_opening_id IS NULL OR ja.job_opening_id = p_job_opening_id)
  AND ja.status = 'active'
  GROUP BY ja.current_stage
  ORDER BY 
    CASE ja.current_stage
      WHEN 'applied' THEN 1
      WHEN 'screening' THEN 2
      WHEN 'interview' THEN 3
      WHEN 'assessment' THEN 4
      WHEN 'offer' THEN 5
      WHEN 'hired' THEN 6
      ELSE 7
    END;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE job_openings ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_offers ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/recruitment.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface JobOpening {
  id: string;
  jobTitle: string;
  jobCode: string;
  department: string;
  status: string;
  numberOfPositions: number;
  applicationCount?: number;
}

export interface Application {
  id: string;
  applicationNumber: string;
  candidateName: string;
  candidateEmail: string;
  currentStage: string;
  status: string;
  applicationDate: string;
}

export class RecruitmentAPI {
  private supabase = createClient();

  async createJobOpening(params: {
    tenantId: string;
    branchId?: string;
    jobTitle: string;
    department: string;
    employmentType: string;
    jobDescription: string;
    requirements: string;
    numberOfPositions: number;
    salaryMin?: number;
    salaryMax?: number;
    hiringManagerId?: string;
  }): Promise<JobOpening> {
    const jobCode = `JOB-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('job_openings')
      .insert({
        tenant_id: params.tenantId,
        branch_id: params.branchId,
        job_title: params.jobTitle,
        job_code: jobCode,
        department: params.department,
        employment_type: params.employmentType,
        job_description: params.jobDescription,
        requirements: params.requirements,
        number_of_positions: params.numberOfPositions,
        salary_min: params.salaryMin,
        salary_max: params.salaryMax,
        hiring_manager_id: params.hiringManagerId,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapJobOpening(data);
  }

  async submitApplication(params: {
    jobOpeningId: string;
    tenantId: string;
    candidateName: string;
    candidateEmail: string;
    candidatePhone: string;
    resumeFile: File;
    totalExperience?: number;
    expectedCTC?: number;
    coverLetter?: string;
  }): Promise<Application> {
    // Upload resume
    const resumePath = `resumes/${params.jobOpeningId}/${Date.now()}_${params.resumeFile.name}`;
    const { data: uploadData, error: uploadError } = await this.supabase.storage
      .from('recruitment')
      .upload(resumePath, params.resumeFile);

    if (uploadError) throw uploadError;

    const { data: urlData } = this.supabase.storage
      .from('recruitment')
      .getPublicUrl(resumePath);

    // Create application
    const { data, error } = await this.supabase
      .from('job_applications')
      .insert({
        job_opening_id: params.jobOpeningId,
        tenant_id: params.tenantId,
        candidate_name: params.candidateName,
        candidate_email: params.candidateEmail,
        candidate_phone: params.candidatePhone,
        resume_url: urlData.publicUrl,
        total_experience_years: params.totalExperience,
        expected_ctc: params.expectedCTC,
        cover_letter: params.coverLetter,
        current_stage: 'applied',
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapApplication(data);
  }

  async getApplicationsByJob(jobOpeningId: string): Promise<Application[]> {
    const { data, error } = await this.supabase
      .from('job_applications')
      .select('*')
      .eq('job_opening_id', jobOpeningId)
      .order('application_date', { ascending: false });

    if (error) throw error;
    return (data || []).map(this.mapApplication);
  }

  async updateApplicationStage(params: {
    applicationId: string;
    newStage: string;
    notes?: string;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('job_applications')
      .update({
        current_stage: params.newStage,
        screening_notes: params.notes,
        last_activity_at: new Date().toISOString(),
      })
      .eq('id', params.applicationId);

    if (error) throw error;
  }

  async scheduleInterview(params: {
    applicationId: string;
    tenantId: string;
    interviewRound: string;
    interviewType: string;
    scheduledDate: Date;
    scheduledTime: string;
    durationMinutes: number;
    interviewerIds: string[];
    meetingLink?: string;
  }) {
    const { data, error } = await this.supabase
      .from('interview_schedules')
      .insert({
        application_id: params.applicationId,
        tenant_id: params.tenantId,
        interview_round: params.interviewRound,
        interview_type: params.interviewType,
        scheduled_date: params.scheduledDate.toISOString().split('T')[0],
        scheduled_time: params.scheduledTime,
        duration_minutes: params.durationMinutes,
        interviewer_ids: params.interviewerIds,
        meeting_link: params.meetingLink,
        status: 'scheduled',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async submitInterviewFeedback(params: {
    interviewScheduleId: string;
    applicationId: string;
    overallRating: number;
    technicalRating?: number;
    communicationRating?: number;
    culturalFitRating?: number;
    strengths: string;
    weaknesses: string;
    recommendation: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('interview_feedback')
      .insert({
        interview_schedule_id: params.interviewScheduleId,
        application_id: params.applicationId,
        interviewer_id: user?.id,
        overall_rating: params.overallRating,
        technical_rating: params.technicalRating,
        communication_rating: params.communicationRating,
        cultural_fit_rating: params.culturalFitRating,
        strengths: params.strengths,
        weaknesses: params.weaknesses,
        recommendation: params.recommendation,
      })
      .select()
      .single();

    if (error) throw error;

    // Mark interview as completed
    await this.supabase
      .from('interview_schedules')
      .update({
        status: 'completed',
        feedback_submitted: true,
      })
      .eq('id', params.interviewScheduleId);

    return data;
  }

  async createJobOffer(params: {
    applicationId: string;
    tenantId: string;
    designation: string;
    department: string;
    annualCTC: number;
    basicSalary: number;
    joiningDate: Date;
    allowances?: any;
  }) {
    const offerNumber = `OFFER-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('job_offers')
      .insert({
        application_id: params.applicationId,
        tenant_id: params.tenantId,
        offer_letter_number: offerNumber,
        designation: params.designation,
        department: params.department,
        annual_ctc: params.annualCTC,
        basic_salary: params.basicSalary,
        joining_date: params.joiningDate.toISOString().split('T')[0],
        allowances: params.allowances,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getRecruitmentPipeline(params: {
    tenantId: string;
    jobOpeningId?: string;
  }) {
    const { data, error } = await this.supabase.rpc('get_recruitment_pipeline', {
      p_tenant_id: params.tenantId,
      p_job_opening_id: params.jobOpeningId,
    });

    if (error) throw error;

    return data.map((item: any) => ({
      stage: item.stage,
      applicationCount: item.application_count,
      avgDaysInStage: item.avg_days_in_stage,
    }));
  }

  private mapJobOpening(data: any): JobOpening {
    return {
      id: data.id,
      jobTitle: data.job_title,
      jobCode: data.job_code,
      department: data.department,
      status: data.status,
      numberOfPositions: data.number_of_positions,
    };
  }

  private mapApplication(data: any): Application {
    return {
      id: data.id,
      applicationNumber: data.application_number,
      candidateName: data.candidate_name,
      candidateEmail: data.candidate_email,
      currentStage: data.current_stage,
      status: data.status,
      applicationDate: data.application_date,
    };
  }
}

export const recruitmentAPI = new RecruitmentAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { RecruitmentAPI } from '../recruitment';

describe('RecruitmentAPI', () => {
  it('creates job opening', async () => {
    const api = new RecruitmentAPI();
    const job = await api.createJobOpening({
      tenantId: 'test-tenant',
      jobTitle: 'Software Engineer',
      department: 'Engineering',
      employmentType: 'permanent',
      jobDescription: 'Build amazing products',
      requirements: 'Bachelor degree',
      numberOfPositions: 2,
    });

    expect(job).toHaveProperty('id');
    expect(job.jobTitle).toBe('Software Engineer');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Job posting working
- [ ] Application tracking operational
- [ ] Interview scheduling functional
- [ ] Feedback collection working
- [ ] Offer management operational
- [ ] Pipeline analytics available
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-181 (Onboarding)  
**Time**: 5 hours  
**AI-Ready**: 100%
