-- ==============================================
-- INITIAL SCHEMA MIGRATION
-- Migration: 001_initial_schema.sql
-- Created: October 4, 2025
-- Description: Complete multi-tenant school management database schema
-- ==============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create custom types
CREATE DOMAIN tenant_uuid AS UUID NOT NULL;

-- ==============================================
-- SYSTEM CONFIGURATION TABLES
-- ==============================================

-- Global system configuration (non-tenant specific)
CREATE TABLE IF NOT EXISTS system_config (
  id SERIAL PRIMARY KEY,
  category VARCHAR(100) NOT NULL,
  key VARCHAR(255) NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  data_type VARCHAR(50) NOT NULL DEFAULT 'string',
  is_public BOOLEAN NOT NULL DEFAULT false,
  is_required BOOLEAN NOT NULL DEFAULT false,
  validation_rules JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(category, key)
);

-- System-wide feature flags
CREATE TABLE IF NOT EXISTS feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  conditions JSONB,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Platform subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  display_name VARCHAR(200) NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2) NOT NULL DEFAULT 0,
  price_yearly DECIMAL(10,2) NOT NULL DEFAULT 0,
  max_students INTEGER,
  max_staff INTEGER,
  max_branches INTEGER,
  max_storage_gb INTEGER,
  max_api_calls_per_month INTEGER,
  features JSONB NOT NULL DEFAULT '[]',
  integrations JSONB NOT NULL DEFAULT '[]',
  trial_days INTEGER DEFAULT 14,
  is_public BOOLEAN NOT NULL DEFAULT true,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================
-- TENANT MANAGEMENT TABLES
-- ==============================================

-- Primary tenants table (schools/organizations)
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  display_name VARCHAR(300),
  description TEXT,
  logo_url TEXT,
  favicon_url TEXT,
  primary_color VARCHAR(7) DEFAULT '#2563eb',
  secondary_color VARCHAR(7) DEFAULT '#7c3aed',
  accent_color VARCHAR(7) DEFAULT '#059669',
  subdomain VARCHAR(100) UNIQUE,
  custom_domain VARCHAR(255),
  custom_domain_verified BOOLEAN NOT NULL DEFAULT false,
  contact_email VARCHAR(255) NOT NULL,
  contact_phone VARCHAR(50),
  contact_person VARCHAR(200),
  website VARCHAR(255),
  address_line1 VARCHAR(255),
  address_line2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(2) NOT NULL DEFAULT 'IN',
  postal_code VARCHAR(20),
  timezone VARCHAR(100) NOT NULL DEFAULT 'Asia/Kolkata',
  subscription_plan_id UUID REFERENCES subscription_plans(id),
  subscription_status VARCHAR(50) NOT NULL DEFAULT 'trial',
  subscription_start_date DATE,
  subscription_end_date DATE,
  trial_ends_at TIMESTAMP WITH TIME ZONE,
  current_students INTEGER DEFAULT 0,
  current_staff INTEGER DEFAULT 0,
  current_branches INTEGER DEFAULT 0,
  current_storage_gb DECIMAL(10,2) DEFAULT 0,
  settings JSONB NOT NULL DEFAULT '{}',
  features JSONB NOT NULL DEFAULT '[]',
  integrations JSONB NOT NULL DEFAULT '{}',
  academic_year_format VARCHAR(20) DEFAULT 'april_march',
  default_language VARCHAR(10) DEFAULT 'en',
  supported_languages JSONB DEFAULT '["en"]',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  is_verified BOOLEAN NOT NULL DEFAULT false,
  verification_token VARCHAR(255),
  last_activity_at TIMESTAMP WITH TIME ZONE,
  activated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT valid_colors CHECK (
    primary_color ~ '^#[0-9A-Fa-f]{6}$' AND
    secondary_color ~ '^#[0-9A-Fa-f]{6}$' AND
    accent_color ~ '^#[0-9A-Fa-f]{6}$'
  ),
  CONSTRAINT valid_subdomain CHECK (
    subdomain ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$' AND
    length(subdomain) >= 3 AND
    length(subdomain) <= 50
  )
);

-- Tenant subscription history
CREATE TABLE IF NOT EXISTS tenant_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  billing_cycle VARCHAR(20) NOT NULL DEFAULT 'monthly',
  amount_monthly DECIMAL(10,2) NOT NULL,
  amount_yearly DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  billing_email VARCHAR(255),
  payment_method JSONB,
  next_billing_date DATE,
  start_date DATE NOT NULL,
  end_date DATE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancellation_reason TEXT,
  created_by UUID,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tenant usage tracking
CREATE TABLE IF NOT EXISTS tenant_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  metric_name VARCHAR(100) NOT NULL,
  metric_value DECIMAL(12,2) NOT NULL DEFAULT 0,
  metric_unit VARCHAR(20),
  period_type VARCHAR(20) NOT NULL DEFAULT 'daily',
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  additional_data JSONB,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, metric_name, period_start, period_end)
);

-- ==============================================
-- ORGANIZATIONAL STRUCTURE TABLES
-- ==============================================

-- Branches (schools/campuses within a tenant)
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) NOT NULL,
  display_name VARCHAR(300),
  type VARCHAR(50) NOT NULL DEFAULT 'school',
  email VARCHAR(255),
  phone VARCHAR(50),
  fax VARCHAR(50),
  website VARCHAR(255),
  address_line1 VARCHAR(255),
  address_line2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(2) NOT NULL DEFAULT 'IN',
  postal_code VARCHAR(20),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  academic_year_start_month INTEGER DEFAULT 4 CHECK (academic_year_start_month >= 1 AND academic_year_start_month <= 12),
  academic_year_end_month INTEGER DEFAULT 3 CHECK (academic_year_end_month >= 1 AND academic_year_end_month <= 12),
  board_affiliation VARCHAR(100),
  recognition_number VARCHAR(100),
  principal_name VARCHAR(200),
  principal_email VARCHAR(255),
  principal_phone VARCHAR(50),
  total_classrooms INTEGER DEFAULT 0,
  total_labs INTEGER DEFAULT 0,
  library_capacity INTEGER DEFAULT 0,
  playground_area DECIMAL(8,2),
  transport_available BOOLEAN NOT NULL DEFAULT false,
  hostel_available BOOLEAN NOT NULL DEFAULT false,
  settings JSONB NOT NULL DEFAULT '{}',
  features JSONB NOT NULL DEFAULT '[]',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  is_main_branch BOOLEAN NOT NULL DEFAULT false,
  established_date DATE,
  accreditation_date DATE,
  last_inspection_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, code),
  UNIQUE(tenant_id, name)
);

-- Academic years
CREATE TABLE IF NOT EXISTS academic_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(150),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  term_structure VARCHAR(50) NOT NULL DEFAULT 'annual',
  total_terms INTEGER NOT NULL DEFAULT 1,
  status VARCHAR(50) NOT NULL DEFAULT 'upcoming',
  is_current BOOLEAN NOT NULL DEFAULT false,
  settings JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, name),
  CONSTRAINT end_after_start CHECK (end_date > start_date),
  CONSTRAINT valid_terms CHECK (total_terms >= 1 AND total_terms <= 6)
);

-- Academic terms/semesters
CREATE TABLE IF NOT EXISTS academic_terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(200),
  term_number INTEGER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  registration_start_date DATE,
  registration_end_date DATE,
  classes_start_date DATE,
  classes_end_date DATE,
  exam_start_date DATE,
  exam_end_date DATE,
  result_declaration_date DATE,
  status VARCHAR(50) NOT NULL DEFAULT 'upcoming',
  is_current BOOLEAN NOT NULL DEFAULT false,
  settings JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, academic_year_id, term_number),
  CONSTRAINT end_after_start CHECK (end_date > start_date),
  CONSTRAINT term_number_valid CHECK (term_number >= 1)
);

-- Classes/Grades
CREATE TABLE IF NOT EXISTS classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(200),
  code VARCHAR(20) NOT NULL,
  level INTEGER,
  category VARCHAR(50) DEFAULT 'academic',
  subjects JSONB NOT NULL DEFAULT '[]',
  streams JSONB DEFAULT '[]',
  max_students INTEGER DEFAULT 50,
  current_students INTEGER DEFAULT 0,
  settings JSONB NOT NULL DEFAULT '{}',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, branch_id, code),
  UNIQUE(tenant_id, branch_id, name),
  CONSTRAINT valid_level CHECK (level IS NULL OR (level >= 1 AND level <= 15))
);

-- Sections within classes
CREATE TABLE IF NOT EXISTS sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  display_name VARCHAR(100),
  max_students INTEGER DEFAULT 40,
  current_students INTEGER DEFAULT 0,
  class_teacher_id UUID,
  room_number VARCHAR(50),
  building VARCHAR(100),
  floor INTEGER,
  start_time TIME,
  end_time TIME,
  settings JSONB NOT NULL DEFAULT '{}',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, class_id, name)
);

-- ==============================================
-- USER MANAGEMENT TABLES
-- ==============================================

-- Core users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  display_name VARCHAR(300),
  full_name VARCHAR(400) GENERATED ALWAYS AS (
    TRIM(CONCAT(first_name, ' ', COALESCE(middle_name || ' ', ''), last_name))
  ) STORED,
  employee_id VARCHAR(100),
  student_id VARCHAR(100),
  admission_number VARCHAR(100),
  roll_number VARCHAR(50),
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(50),
  alternate_phone VARCHAR(50),
  emergency_contact_name VARCHAR(200),
  emergency_contact_phone VARCHAR(50),
  emergency_contact_relation VARCHAR(100),
  date_of_birth DATE,
  gender VARCHAR(20),
  blood_group VARCHAR(10),
  nationality VARCHAR(100) DEFAULT 'Indian',
  religion VARCHAR(100),
  caste VARCHAR(100),
  category VARCHAR(50),
  permanent_address JSONB,
  current_address JSONB,
  same_as_permanent BOOLEAN DEFAULT true,
  avatar_url TEXT,
  bio TEXT,
  primary_role VARCHAR(50) NOT NULL DEFAULT 'user',
  secondary_roles JSONB DEFAULT '[]',
  permissions JSONB DEFAULT '[]',
  language VARCHAR(10) DEFAULT 'en',
  timezone VARCHAR(100) DEFAULT 'Asia/Kolkata',
  theme VARCHAR(20) DEFAULT 'system',
  preferences JSONB NOT NULL DEFAULT '{}',
  email_verified_at TIMESTAMP WITH TIME ZONE,
  phone_verified_at TIMESTAMP WITH TIME ZONE,
  last_login_at TIMESTAMP WITH TIME ZONE,
  login_count INTEGER DEFAULT 0,
  password_changed_at TIMESTAMP WITH TIME ZONE,
  two_factor_enabled BOOLEAN NOT NULL DEFAULT false,
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, email),
  UNIQUE(tenant_id, employee_id),
  UNIQUE(tenant_id, student_id),
  UNIQUE(tenant_id, admission_number),
  CONSTRAINT valid_primary_role CHECK (primary_role IN ('admin', 'principal', 'teacher', 'student', 'parent', 'staff', 'user'))
);

-- User roles (for granular role management)
CREATE TABLE IF NOT EXISTS user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(100) NOT NULL,
  role_type VARCHAR(50) NOT NULL DEFAULT 'system',
  scope VARCHAR(100) NOT NULL DEFAULT 'tenant',
  scope_id UUID,
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  role_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, user_id, role, scope, scope_id)
);

-- User sessions and activity tracking
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  device_info JSONB,
  ip_address INET,
  user_agent TEXT,
  country VARCHAR(2),
  city VARCHAR(100),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  end_reason VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences and settings
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  key VARCHAR(200) NOT NULL,
  value JSONB NOT NULL,
  data_type VARCHAR(50) NOT NULL DEFAULT 'string',
  is_public BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, user_id, category, key)
);

-- ==============================================
-- STUDENT MANAGEMENT TABLES
-- ==============================================

-- Extended student information
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  admission_number VARCHAR(100) NOT NULL,
  roll_number VARCHAR(50),
  class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  academic_year_id UUID REFERENCES academic_years(id) ON DELETE SET NULL,
  admission_date DATE NOT NULL,
  admission_type VARCHAR(50) NOT NULL DEFAULT 'fresh',
  previous_school VARCHAR(300),
  transfer_certificate_number VARCHAR(100),
  migration_certificate_number VARCHAR(100),
  place_of_birth VARCHAR(200),
  mother_tongue VARCHAR(100),
  domicile VARCHAR(200),
  medical_conditions JSONB DEFAULT '[]',
  allergies JSONB DEFAULT '[]',
  medications JSONB DEFAULT '[]',
  doctor_name VARCHAR(200),
  doctor_phone VARCHAR(50),
  medical_emergency_contact JSONB,
  health_insurance_number VARCHAR(100),
  previous_class VARCHAR(100),
  previous_percentage DECIMAL(5,2),
  fee_category VARCHAR(100) DEFAULT 'regular',
  fee_concession_percentage DECIMAL(5,2) DEFAULT 0,
  fee_concession_reason TEXT,
  transport_required BOOLEAN DEFAULT false,
  pickup_point VARCHAR(300),
  drop_point VARCHAR(300),
  bus_route VARCHAR(100),
  hostel_required BOOLEAN DEFAULT false,
  hostel_room_number VARCHAR(50),
  hostel_block VARCHAR(50),
  settings JSONB NOT NULL DEFAULT '{}',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  status_reason TEXT,
  status_changed_at TIMESTAMP WITH TIME ZONE,
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
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  roll_number VARCHAR(50),
  attendance_percentage DECIMAL(5,2),
  total_working_days INTEGER DEFAULT 0,
  days_present INTEGER DEFAULT 0,
  days_absent INTEGER DEFAULT 0,
  conduct_grade VARCHAR(10),
  discipline_points INTEGER DEFAULT 0,
  extra_curricular_activities JSONB DEFAULT '[]',
  achievements JSONB DEFAULT '[]',
  promotion_status VARCHAR(50) DEFAULT 'pending',
  promotion_date DATE,
  promotion_remarks TEXT,
  overall_grade VARCHAR(10),
  overall_percentage DECIMAL(5,2),
  rank_in_class INTEGER,
  rank_in_section INTEGER,
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
  subject_code VARCHAR(50) NOT NULL,
  subject_name VARCHAR(200) NOT NULL,
  subject_type VARCHAR(50) NOT NULL DEFAULT 'core',
  credits INTEGER DEFAULT 0,
  teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  enrollment_date DATE DEFAULT CURRENT_DATE,
  withdrawal_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, academic_year_id, subject_code)
);

-- ==============================================
-- PARENT/GUARDIAN MANAGEMENT
-- ==============================================

-- Parents/Guardians information
CREATE TABLE IF NOT EXISTS guardians (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  full_name VARCHAR(400) GENERATED ALWAYS AS (
    TRIM(CONCAT(first_name, ' ', COALESCE(middle_name || ' ', ''), last_name))
  ) STORED,
  email VARCHAR(255),
  phone VARCHAR(50) NOT NULL,
  alternate_phone VARCHAR(50),
  whatsapp_number VARCHAR(50),
  date_of_birth DATE,
  gender VARCHAR(20),
  occupation VARCHAR(200),
  organization VARCHAR(300),
  designation VARCHAR(200),
  office_address TEXT,
  office_phone VARCHAR(50),
  annual_income DECIMAL(12,2),
  address JSONB,
  photo_url TEXT,
  emergency_contact_name VARCHAR(200),
  emergency_contact_phone VARCHAR(50),
  emergency_contact_relation VARCHAR(100),
  communication_preferences JSONB DEFAULT '{"email": true, "sms": true, "whatsapp": false}',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
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
  relationship VARCHAR(100) NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  is_emergency_contact BOOLEAN NOT NULL DEFAULT false,
  is_authorized_pickup BOOLEAN NOT NULL DEFAULT true,
  can_receive_academic_updates BOOLEAN NOT NULL DEFAULT true,
  can_receive_attendance_alerts BOOLEAN NOT NULL DEFAULT true,
  can_receive_fee_notifications BOOLEAN NOT NULL DEFAULT true,
  can_receive_disciplinary_notices BOOLEAN NOT NULL DEFAULT true,
  is_fee_payer BOOLEAN NOT NULL DEFAULT false,
  financial_responsibility_percentage DECIMAL(5,2) DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, guardian_id),
  CONSTRAINT valid_financial_percentage CHECK (financial_responsibility_percentage >= 0 AND financial_responsibility_percentage <= 100)
);

-- ==============================================
-- HELPER FUNCTIONS
-- ==============================================

-- Function to get current tenant ID
CREATE OR REPLACE FUNCTION get_current_tenant_id()
RETURNS UUID AS $$
BEGIN
  RETURN current_setting('app.current_tenant_id', true)::UUID;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to ensure tenant context
CREATE OR REPLACE FUNCTION ensure_tenant_context()
RETURNS UUID AS $$
DECLARE
  tenant_id UUID;
BEGIN
  tenant_id := get_current_tenant_id();
  
  IF tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant context set. Please set app.current_tenant_id';
  END IF;
  
  RETURN tenant_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to validate tenant context
CREATE OR REPLACE FUNCTION validate_tenant_context()
RETURNS TRIGGER AS $$
DECLARE
  current_tenant_id UUID;
BEGIN
  current_tenant_id := get_current_tenant_id();
  
  IF current_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Tenant context not set. Please set app.current_tenant_id';
  END IF;
  
  IF TG_OP = 'INSERT' THEN
    IF NEW.tenant_id IS NULL THEN
      NEW.tenant_id := current_tenant_id;
    ELSIF NEW.tenant_id != current_tenant_id THEN
      RAISE EXCEPTION 'Tenant ID mismatch. Expected: %, Got: %', current_tenant_id, NEW.tenant_id;
    END IF;
  END IF;
  
  IF TG_OP = 'UPDATE' THEN
    IF OLD.tenant_id != NEW.tenant_id THEN
      RAISE EXCEPTION 'Cannot change tenant_id from % to %', OLD.tenant_id, NEW.tenant_id;
    END IF;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- ENABLE ROW LEVEL SECURITY
-- ==============================================

-- Enable RLS on all tenant tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_academic_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_guardians ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- ROW LEVEL SECURITY POLICIES
-- ==============================================

-- Tenant table policies
CREATE POLICY tenant_isolation_tenants ON tenants
  FOR ALL TO authenticated
  USING (id = get_current_tenant_id());

-- Branch policies
CREATE POLICY tenant_isolation_branches ON branches
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Academic structure policies
CREATE POLICY tenant_isolation_academic_years ON academic_years
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_academic_terms ON academic_terms
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_classes ON classes
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_sections ON sections
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- User policies
CREATE POLICY tenant_isolation_users ON users
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_user_roles ON user_roles
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_user_sessions ON user_sessions
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_user_preferences ON user_preferences
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

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

-- Subscription and usage policies  
CREATE POLICY tenant_isolation_tenant_subscriptions ON tenant_subscriptions
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_tenant_usage ON tenant_usage
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- ==============================================
-- AUTOMATED TRIGGERS
-- ==============================================

-- Add updated_at triggers to all relevant tables
DO $$
DECLARE
  table_name TEXT;
  tables TEXT[] := ARRAY[
    'tenants', 'tenant_subscriptions', 'branches', 'academic_years', 
    'academic_terms', 'classes', 'sections', 'users', 'user_roles',
    'user_preferences', 'students', 'student_academic_records', 
    'student_subjects', 'guardians', 'student_guardians'
  ];
BEGIN
  FOREACH table_name IN ARRAY tables
  LOOP
    EXECUTE format('
      CREATE TRIGGER update_%s_updated_at
        BEFORE UPDATE ON %s
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    ', table_name, table_name);
  END LOOP;
END
$$;

-- Add tenant validation triggers
DO $$
DECLARE
  table_name TEXT;
  tenant_tables TEXT[] := ARRAY[
    'branches', 'academic_years', 'academic_terms', 'classes', 
    'sections', 'users', 'user_roles', 'user_preferences',
    'students', 'student_academic_records', 'student_subjects',
    'guardians', 'student_guardians'
  ];
BEGIN
  FOREACH table_name IN ARRAY tenant_tables
  LOOP
    EXECUTE format('
      CREATE TRIGGER validate_%s_tenant_context
        BEFORE INSERT OR UPDATE ON %s
        FOR EACH ROW
        EXECUTE FUNCTION validate_tenant_context()
    ', table_name, table_name);
  END LOOP;
END
$$;

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Grant permissions to service role (for migrations and admin operations)
GRANT ALL ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- ==============================================
-- MIGRATION COMPLETE
-- ==============================================

-- Log migration completion
INSERT INTO system_config (category, key, value, description) VALUES 
('migrations', '001_initial_schema', '{"completed_at": "2025-10-04", "version": "1.0", "tables_created": 25}', 'Initial schema migration completed');

-- Display summary
SELECT 
  'Migration 001_initial_schema.sql completed successfully!' as status,
  COUNT(*) as tables_created
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE' 
  AND table_name NOT LIKE 'pg_%';