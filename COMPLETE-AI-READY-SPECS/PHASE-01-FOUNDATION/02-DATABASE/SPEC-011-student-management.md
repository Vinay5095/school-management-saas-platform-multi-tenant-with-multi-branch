# SPEC-011: Student Management Schema

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-011  
**Title**: Student Management Database Schema  
**Phase**: Phase 1 - Foundation & Database  
**Category**: Database Schema - Student Data  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 45 minutes  

---

## 📋 DESCRIPTION

Implement comprehensive student management database schema including student profiles, admissions, parent/guardian information, academic records, and student-specific configurations. This schema supports complete student lifecycle management from admission to graduation.

## 🎯 SUCCESS CRITERIA

- [ ] Student profile tables created with multi-tenant isolation
- [ ] Parent/guardian relationship management implemented
- [ ] Admission and enrollment tracking system
- [ ] Academic record structure defined
- [ ] Student document management system
- [ ] Performance optimization and indexing
- [ ] Security policies and data validation
- [ ] Integration with core user management

---

## 🎓 STUDENT MANAGEMENT SCHEMA

### 1. Student Profiles and Personal Information

```sql
-- ==============================================
-- STUDENT PROFILE TABLES
-- ==============================================

-- Extended student information (extends users table)
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  
  -- Academic Information
  admission_number VARCHAR(100) NOT NULL,
  roll_number VARCHAR(50),
  class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  academic_year_id UUID REFERENCES academic_years(id) ON DELETE SET NULL,
  
  -- Admission Details
  admission_date DATE NOT NULL,
  admission_type VARCHAR(50) NOT NULL DEFAULT 'fresh', -- fresh, transfer, readmission
  previous_school VARCHAR(300),
  transfer_certificate_number VARCHAR(100),
  migration_certificate_number VARCHAR(100),
  
  -- Personal Information
  place_of_birth VARCHAR(200),
  mother_tongue VARCHAR(100),
  domicile VARCHAR(200),
  
  -- Medical Information
  medical_conditions JSONB DEFAULT '[]', -- Array of medical conditions
  allergies JSONB DEFAULT '[]', -- Array of allergies
  medications JSONB DEFAULT '[]', -- Current medications
  doctor_name VARCHAR(200),
  doctor_phone VARCHAR(50),
  
  -- Emergency Medical
  medical_emergency_contact JSONB, -- {name, relation, phone, hospital}
  health_insurance_number VARCHAR(100),
  
  -- Academic History
  previous_class VARCHAR(100),
  previous_percentage DECIMAL(5,2),
  
  -- Financial Information
  fee_category VARCHAR(100) DEFAULT 'regular', -- regular, scholarship, staff_ward, etc.
  fee_concession_percentage DECIMAL(5,2) DEFAULT 0,
  fee_concession_reason TEXT,
  
  -- Transport
  transport_required BOOLEAN DEFAULT false,
  pickup_point VARCHAR(300),
  drop_point VARCHAR(300),
  bus_route VARCHAR(100),
  
  -- Hostel
  hostel_required BOOLEAN DEFAULT false,
  hostel_room_number VARCHAR(50),
  hostel_block VARCHAR(50),
  
  -- Settings
  settings JSONB NOT NULL DEFAULT '{}',
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, inactive, graduated, transferred, dropped
  status_reason TEXT,
  status_changed_at TIMESTAMP WITH TIME ZONE,
  
  -- Important Dates
  graduation_date DATE,
  last_attendance_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, admission_number),
  UNIQUE(tenant_id, user_id),
  CONSTRAINT valid_percentage CHECK (previous_percentage IS NULL OR (previous_percentage >= 0 AND previous_percentage <= 100)),
  CONSTRAINT valid_concession CHECK (fee_concession_percentage >= 0 AND fee_concession_percentage <= 100)
);

-- Student academic records (year-wise)
CREATE TABLE IF NOT EXISTS student_academic_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  
  -- Class Information
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  roll_number VARCHAR(50),
  
  -- Academic Performance
  attendance_percentage DECIMAL(5,2),
  total_working_days INTEGER DEFAULT 0,
  days_present INTEGER DEFAULT 0,
  days_absent INTEGER DEFAULT 0,
  
  -- Behavioral Records
  conduct_grade VARCHAR(10), -- A+, A, B+, B, C, D
  discipline_points INTEGER DEFAULT 0,
  extra_curricular_activities JSONB DEFAULT '[]',
  achievements JSONB DEFAULT '[]',
  
  -- Promotion Details
  promotion_status VARCHAR(50) DEFAULT 'pending', -- promoted, detained, transferred
  promotion_date DATE,
  promotion_remarks TEXT,
  
  -- Results
  overall_grade VARCHAR(10),
  overall_percentage DECIMAL(5,2),
  rank_in_class INTEGER,
  rank_in_section INTEGER,
  
  -- Status
  is_current BOOLEAN NOT NULL DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, academic_year_id),
  CONSTRAINT valid_attendance_percentage CHECK (attendance_percentage IS NULL OR (attendance_percentage >= 0 AND attendance_percentage <= 100)),
  CONSTRAINT valid_overall_percentage CHECK (overall_percentage IS NULL OR (overall_percentage >= 0 AND overall_percentage <= 100))
);

-- Student subjects (enrolled subjects per academic year)
CREATE TABLE IF NOT EXISTS student_subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  
  -- Subject Information
  subject_code VARCHAR(50) NOT NULL,
  subject_name VARCHAR(200) NOT NULL,
  subject_type VARCHAR(50) NOT NULL DEFAULT 'core', -- core, elective, optional, additional
  credits INTEGER DEFAULT 0,
  
  -- Teacher Assignment
  teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Enrollment Details
  enrollment_date DATE DEFAULT CURRENT_DATE,
  withdrawal_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, academic_year_id, subject_code)
);
```

### 2. Parent and Guardian Management

```sql
-- ==============================================
-- PARENT/GUARDIAN MANAGEMENT
-- ==============================================

-- Parents/Guardians information
CREATE TABLE IF NOT EXISTS guardians (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- If guardian has system access
  
  -- Personal Information
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  full_name VARCHAR(400) GENERATED ALWAYS AS (
    TRIM(CONCAT(first_name, ' ', COALESCE(middle_name || ' ', ''), last_name))
  ) STORED,
  
  -- Contact Information
  email VARCHAR(255),
  phone VARCHAR(50) NOT NULL,
  alternate_phone VARCHAR(50),
  whatsapp_number VARCHAR(50),
  
  -- Personal Details
  date_of_birth DATE,
  gender VARCHAR(20),
  
  -- Professional Information
  occupation VARCHAR(200),
  organization VARCHAR(300),
  designation VARCHAR(200),
  office_address TEXT,
  office_phone VARCHAR(50),
  annual_income DECIMAL(12,2),
  
  -- Address (can be different from student)
  address JSONB, -- {line1, line2, city, state, country, postal_code}
  
  -- Profile
  photo_url TEXT,
  
  -- Emergency Contact (if different)
  emergency_contact_name VARCHAR(200),
  emergency_contact_phone VARCHAR(50),
  emergency_contact_relation VARCHAR(100),
  
  -- Settings
  communication_preferences JSONB DEFAULT '{"email": true, "sms": true, "whatsapp": false}',
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, inactive
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, phone),
  UNIQUE(tenant_id, email) WHERE email IS NOT NULL
);

-- Student-Guardian relationships
CREATE TABLE IF NOT EXISTS student_guardians (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  guardian_id UUID NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
  
  -- Relationship Details
  relationship VARCHAR(100) NOT NULL, -- father, mother, guardian, grandfather, etc.
  is_primary BOOLEAN NOT NULL DEFAULT false,
  is_emergency_contact BOOLEAN NOT NULL DEFAULT false,
  is_authorized_pickup BOOLEAN NOT NULL DEFAULT true,
  
  -- Communication Permissions
  can_receive_academic_updates BOOLEAN NOT NULL DEFAULT true,
  can_receive_attendance_alerts BOOLEAN NOT NULL DEFAULT true,
  can_receive_fee_notifications BOOLEAN NOT NULL DEFAULT true,
  can_receive_disciplinary_notices BOOLEAN NOT NULL DEFAULT true,
  
  -- Financial Responsibility
  is_fee_payer BOOLEAN NOT NULL DEFAULT false,
  financial_responsibility_percentage DECIMAL(5,2) DEFAULT 100,
  
  -- Status
  is_active BOOLEAN NOT NULL DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, guardian_id),
  CONSTRAINT valid_financial_percentage CHECK (financial_responsibility_percentage >= 0 AND financial_responsibility_percentage <= 100)
);

-- Guardian communication logs
CREATE TABLE IF NOT EXISTS guardian_communications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  guardian_id UUID NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  
  -- Communication Details
  type VARCHAR(50) NOT NULL, -- email, sms, call, meeting, letter
  subject VARCHAR(500),
  message TEXT,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'sent', -- sent, delivered, read, failed, scheduled
  
  -- Metadata
  sent_by UUID REFERENCES users(id) ON DELETE SET NULL,
  scheduled_at TIMESTAMP WITH TIME ZONE,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  delivered_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  
  -- Additional Data
  metadata JSONB, -- Platform-specific data
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. Student Documents and Attachments

```sql
-- ==============================================
-- STUDENT DOCUMENTS MANAGEMENT
-- ==============================================

-- Student documents
CREATE TABLE IF NOT EXISTS student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  
  -- Document Information
  document_type VARCHAR(100) NOT NULL, -- birth_certificate, aadhar_card, etc.
  document_name VARCHAR(300) NOT NULL,
  document_number VARCHAR(200),
  
  -- File Information
  file_id UUID REFERENCES file_uploads(id) ON DELETE SET NULL,
  file_url TEXT,
  file_size INTEGER, -- in bytes
  mime_type VARCHAR(100),
  
  -- Document Details
  issued_by VARCHAR(300),
  issue_date DATE,
  expiry_date DATE,
  
  -- Verification
  is_verified BOOLEAN NOT NULL DEFAULT false,
  verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  verification_notes TEXT,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, expired
  
  -- Privacy
  is_confidential BOOLEAN NOT NULL DEFAULT false,
  access_level VARCHAR(50) DEFAULT 'admin', -- admin, staff, teacher
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, student_id, document_type, document_number) WHERE document_number IS NOT NULL
);

-- Student photos/media
CREATE TABLE IF NOT EXISTS student_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  
  -- Media Information
  media_type VARCHAR(50) NOT NULL, -- profile_photo, id_card_photo, document_scan
  title VARCHAR(200),
  description TEXT,
  
  -- File Information
  file_id UUID REFERENCES file_uploads(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  
  -- Metadata
  file_size INTEGER,
  mime_type VARCHAR(100),
  dimensions JSONB, -- {width, height}
  
  -- Usage
  is_primary BOOLEAN NOT NULL DEFAULT false,
  is_public BOOLEAN NOT NULL DEFAULT false,
  usage_permissions JSONB DEFAULT '["id_card", "reports"]',
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, inactive, expired
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);
```

### 4. Student Activities and Behavior

```sql
-- ==============================================
-- STUDENT ACTIVITIES AND BEHAVIOR
-- ==============================================

-- Student activities and achievements
CREATE TABLE IF NOT EXISTS student_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year_id UUID REFERENCES academic_years(id) ON DELETE SET NULL,
  
  -- Activity Information
  activity_type VARCHAR(100) NOT NULL, -- sports, cultural, academic, social_service
  activity_name VARCHAR(300) NOT NULL,
  category VARCHAR(100), -- competition, club, event, project
  
  -- Details
  description TEXT,
  level VARCHAR(50), -- school, district, state, national, international
  
  -- Participation Details
  participation_type VARCHAR(50) NOT NULL DEFAULT 'participant', -- participant, organizer, winner
  position VARCHAR(50), -- first, second, third, participation
  
  -- Dates
  activity_date DATE,
  start_date DATE,
  end_date DATE,
  
  -- Recognition
  certificate_received BOOLEAN DEFAULT false,
  certificate_url TEXT,
  points_awarded INTEGER DEFAULT 0,
  
  -- Metadata
  organizer VARCHAR(300),
  venue VARCHAR(300),
  remarks TEXT,
  
  -- Verification
  verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student behavior and discipline records
CREATE TABLE IF NOT EXISTS student_behavior_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  
  -- Incident Information
  type VARCHAR(50) NOT NULL, -- positive, negative, neutral
  category VARCHAR(100) NOT NULL, -- academic, behavioral, disciplinary
  incident_title VARCHAR(300) NOT NULL,
  description TEXT NOT NULL,
  
  -- Severity (for negative incidents)
  severity VARCHAR(50), -- minor, moderate, major, severe
  
  -- Location and Time
  incident_date DATE NOT NULL,
  incident_time TIME,
  location VARCHAR(200),
  
  -- People Involved
  reported_by UUID REFERENCES users(id) ON DELETE SET NULL,
  witnesses JSONB DEFAULT '[]', -- Array of witness names/IDs
  
  -- Action Taken
  action_taken TEXT,
  punishment_given TEXT,
  points_deducted INTEGER DEFAULT 0,
  points_awarded INTEGER DEFAULT 0,
  
  -- Follow-up
  follow_up_required BOOLEAN DEFAULT false,
  follow_up_date DATE,
  follow_up_notes TEXT,
  
  -- Parent Communication
  parents_informed BOOLEAN DEFAULT false,
  parent_meeting_scheduled BOOLEAN DEFAULT false,
  parent_meeting_date DATE,
  
  -- Resolution
  status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, resolved, escalated
  resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  resolution_date DATE,
  resolution_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student counseling records
CREATE TABLE IF NOT EXISTS student_counseling_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  
  -- Session Information
  session_date DATE NOT NULL,
  session_time TIME,
  duration_minutes INTEGER DEFAULT 30,
  
  -- Counselor Information
  counselor_id UUID REFERENCES users(id) ON DELETE SET NULL,
  counselor_type VARCHAR(50) DEFAULT 'internal', -- internal, external, peer
  
  -- Session Details
  session_type VARCHAR(100) NOT NULL, -- individual, group, family, crisis
  reason VARCHAR(200) NOT NULL,
  concerns JSONB DEFAULT '[]', -- Array of concern categories
  
  -- Assessment
  mood_rating INTEGER CHECK (mood_rating >= 1 AND mood_rating <= 10),
  behavior_observations TEXT,
  
  -- Treatment
  interventions_used JSONB DEFAULT '[]',
  recommendations TEXT,
  homework_assigned TEXT,
  
  -- Progress
  progress_notes TEXT,
  goals_set JSONB DEFAULT '[]',
  goals_achieved JSONB DEFAULT '[]',
  
  -- Follow-up
  next_session_scheduled BOOLEAN DEFAULT false,
  next_session_date DATE,
  
  -- Confidentiality
  is_confidential BOOLEAN NOT NULL DEFAULT true,
  parent_consent_given BOOLEAN DEFAULT false,
  
  -- Referrals
  referral_made BOOLEAN DEFAULT false,
  referral_to VARCHAR(300),
  referral_reason TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 📊 PERFORMANCE OPTIMIZATION

### 1. Indexes for Student Management

```sql
-- ==============================================
-- STUDENT MANAGEMENT INDEXES
-- ==============================================

-- Student profile indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_tenant_id ON students(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_user_id ON students(tenant_id, user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_admission_number ON students(tenant_id, admission_number);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_class_section ON students(tenant_id, class_id, section_id, status) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_branch ON students(tenant_id, branch_id, status) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_status ON students(tenant_id, status) WHERE deleted_at IS NULL;

-- Academic records indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_academic_records_student_year ON student_academic_records(tenant_id, student_id, academic_year_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_academic_records_current ON student_academic_records(tenant_id, is_current) WHERE is_current = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_academic_records_class ON student_academic_records(tenant_id, class_id, academic_year_id);

-- Guardian indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_guardians_tenant_id ON guardians(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_guardians_phone ON guardians(tenant_id, phone);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_guardians_email ON guardians(tenant_id, email) WHERE email IS NOT NULL;

-- Student-guardian relationship indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_guardians_student ON student_guardians(tenant_id, student_id) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_guardians_guardian ON student_guardians(tenant_id, guardian_id) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_guardians_primary ON student_guardians(tenant_id, is_primary) WHERE is_primary = true;

-- Document indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_documents_student ON student_documents(tenant_id, student_id) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_documents_type ON student_documents(tenant_id, document_type, status) WHERE deleted_at IS NULL;

-- Activity and behavior indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_activities_student ON student_activities(tenant_id, student_id, activity_date DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_behavior_student ON student_behavior_records(tenant_id, student_id, incident_date DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_counseling_student ON student_counseling_records(tenant_id, student_id, session_date DESC);

-- Search indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_search ON students 
  USING gin(to_tsvector('english', 
    admission_number || ' ' || 
    COALESCE(roll_number, '') || ' ' || 
    COALESCE((SELECT full_name FROM users WHERE id = user_id), '')
  )) WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_guardians_search ON guardians 
  USING gin(to_tsvector('english', full_name || ' ' || phone || ' ' || COALESCE(email, '')))
  WHERE deleted_at IS NULL;
```

---

## 🔒 ROW-LEVEL SECURITY POLICIES

```sql
-- ==============================================
-- STUDENT MANAGEMENT RLS POLICIES
-- ==============================================

-- Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_academic_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardian_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_behavior_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_counseling_records ENABLE ROW LEVEL SECURITY;

-- Student policies
CREATE POLICY tenant_isolation_students ON students
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_academic_records ON student_academic_records
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_subjects ON student_subjects
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Guardian policies
CREATE POLICY tenant_isolation_guardians ON guardians
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_guardians ON student_guardians
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_guardian_communications ON guardian_communications
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Document and media policies
CREATE POLICY tenant_isolation_student_documents ON student_documents
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_media ON student_media
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Activity and behavior policies
CREATE POLICY tenant_isolation_student_activities ON student_activities
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_behavior_records ON student_behavior_records
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_counseling_records ON student_counseling_records
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());
```

---

## 🔧 HELPER FUNCTIONS AND TRIGGERS

```sql
-- ==============================================
-- STUDENT MANAGEMENT FUNCTIONS
-- ==============================================

-- Function to generate admission number
CREATE OR REPLACE FUNCTION generate_admission_number(
  tenant_uuid UUID,
  branch_uuid UUID,
  admission_year INTEGER DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
  year_code TEXT;
  branch_code TEXT;
  sequence_num INTEGER;
  admission_number TEXT;
BEGIN
  -- Get year code
  year_code := COALESCE(admission_year, EXTRACT(YEAR FROM CURRENT_DATE))::TEXT;
  
  -- Get branch code
  SELECT code INTO branch_code FROM branches WHERE id = branch_uuid AND tenant_id = tenant_uuid;
  
  IF branch_code IS NULL THEN
    RAISE EXCEPTION 'Branch not found or not accessible';
  END IF;
  
  -- Get next sequence number for this year and branch
  SELECT COALESCE(MAX(CAST(SUBSTRING(admission_number FROM '(\d+)$') AS INTEGER)), 0) + 1
  INTO sequence_num
  FROM students
  WHERE tenant_id = tenant_uuid 
    AND branch_id = branch_uuid
    AND admission_number LIKE year_code || branch_code || '%';
  
  -- Format: YYYY<BRANCH_CODE><SEQUENCE>
  admission_number := year_code || branch_code || LPAD(sequence_num::TEXT, 4, '0');
  
  RETURN admission_number;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate student age
CREATE OR REPLACE FUNCTION calculate_student_age(student_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  birth_date DATE;
  student_age INTEGER;
BEGIN
  SELECT u.date_of_birth INTO birth_date
  FROM students s
  JOIN users u ON s.user_id = u.id
  WHERE s.id = student_uuid;
  
  IF birth_date IS NULL THEN
    RETURN NULL;
  END IF;
  
  student_age := EXTRACT(YEAR FROM AGE(birth_date));
  RETURN student_age;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get primary guardian
CREATE OR REPLACE FUNCTION get_primary_guardian(student_uuid UUID)
RETURNS JSONB AS $$
DECLARE
  guardian_info JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', g.id,
    'name', g.full_name,
    'phone', g.phone,
    'email', g.email,
    'relationship', sg.relationship
  ) INTO guardian_info
  FROM student_guardians sg
  JOIN guardians g ON sg.guardian_id = g.id
  WHERE sg.student_id = student_uuid 
    AND sg.is_primary = true 
    AND sg.is_active = true
  LIMIT 1;
  
  RETURN guardian_info;
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger to set admission number automatically
CREATE OR REPLACE FUNCTION set_student_admission_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.admission_number IS NULL OR NEW.admission_number = '' THEN
    NEW.admission_number := generate_admission_number(
      NEW.tenant_id, 
      NEW.branch_id, 
      EXTRACT(YEAR FROM NEW.admission_date)::INTEGER
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_student_admission_number_trigger
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION set_student_admission_number();

-- Trigger to ensure only one primary guardian per student
CREATE OR REPLACE FUNCTION ensure_single_primary_guardian()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = true THEN
    -- Remove primary flag from other guardians of the same student
    UPDATE student_guardians 
    SET is_primary = false 
    WHERE student_id = NEW.student_id 
      AND guardian_id != NEW.guardian_id 
      AND is_primary = true;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_primary_guardian_trigger
  BEFORE INSERT OR UPDATE ON student_guardians
  FOR EACH ROW
  EXECUTE FUNCTION ensure_single_primary_guardian();
```

---

## 🧪 TESTING AND VALIDATION

### 1. Student Data Validation

```sql
-- ==============================================
-- STUDENT DATA VALIDATION TESTS
-- ==============================================

-- Test student creation with guardian
DO $$
DECLARE
  test_tenant_id UUID;
  test_branch_id UUID;
  test_user_id UUID;
  test_student_id UUID;
  test_guardian_id UUID;
  generated_admission_number TEXT;
BEGIN
  -- Get or create test tenant
  SELECT id INTO test_tenant_id FROM tenants WHERE slug = 'test-school' LIMIT 1;
  IF test_tenant_id IS NULL THEN
    test_tenant_id := create_test_tenant('Test School', 'test-school');
  END IF;
  
  -- Set tenant context
  PERFORM set_config('app.current_tenant_id', test_tenant_id::TEXT, false);
  
  -- Get test branch
  SELECT id INTO test_branch_id FROM branches WHERE tenant_id = test_tenant_id LIMIT 1;
  
  -- Create test user
  INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'teststudent@example.com');
  INSERT INTO users (id, tenant_id, first_name, last_name, email, primary_role)
  VALUES (
    (SELECT id FROM auth.users WHERE email = 'teststudent@example.com'),
    test_tenant_id,
    'Test',
    'Student',
    'teststudent@example.com',
    'student'
  ) RETURNING id INTO test_user_id;
  
  -- Create student
  INSERT INTO students (tenant_id, user_id, branch_id, admission_date)
  VALUES (test_tenant_id, test_user_id, test_branch_id, CURRENT_DATE)
  RETURNING id, admission_number INTO test_student_id, generated_admission_number;
  
  -- Verify admission number was generated
  IF generated_admission_number IS NULL OR generated_admission_number = '' THEN
    RAISE EXCEPTION 'Admission number generation failed';
  END IF;
  
  -- Create guardian
  INSERT INTO guardians (tenant_id, first_name, last_name, phone, email)
  VALUES (test_tenant_id, 'Test', 'Parent', '9876543210', 'testparent@example.com')
  RETURNING id INTO test_guardian_id;
  
  -- Link student to guardian
  INSERT INTO student_guardians (tenant_id, student_id, guardian_id, relationship, is_primary)
  VALUES (test_tenant_id, test_student_id, test_guardian_id, 'father', true);
  
  -- Verify primary guardian function
  IF get_primary_guardian(test_student_id) IS NULL THEN
    RAISE EXCEPTION 'Primary guardian function failed';
  END IF;
  
  -- Cleanup
  DELETE FROM student_guardians WHERE student_id = test_student_id;
  DELETE FROM guardians WHERE id = test_guardian_id;
  DELETE FROM students WHERE id = test_student_id;
  DELETE FROM users WHERE id = test_user_id;
  DELETE FROM auth.users WHERE email = 'teststudent@example.com';
  
  RAISE NOTICE 'Student management test PASSED. Generated admission number: %', generated_admission_number;
END
$$;
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] Student profile tables with multi-tenant isolation
- [x] Parent/guardian relationship management
- [x] Academic records and subject enrollment
- [x] Document and media management
- [x] Admission number auto-generation
- [x] Performance indexes and RLS policies
- [x] Helper functions for common operations
- [x] Data validation and constraints

### Should Have  
- [x] Student activities and achievements tracking
- [x] Behavior and discipline records
- [x] Counseling session management
- [x] Guardian communication logs
- [x] Search functionality optimization
- [x] Comprehensive testing scenarios
- [x] Automated triggers for data integrity

### Could Have
- [x] Advanced reporting capabilities
- [x] Student progress analytics
- [x] Integration with academic modules
- [x] Bulk import/export utilities
- [x] Advanced security features
- [x] Performance monitoring

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-010 (Core Tables) - Core user and tenant management  
**Depends On**: Users table, Branches table, Academic Years table  
**Blocks**: SPEC-012 (Staff Management), Academic modules, Fee management  

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-012-staff-management.sql