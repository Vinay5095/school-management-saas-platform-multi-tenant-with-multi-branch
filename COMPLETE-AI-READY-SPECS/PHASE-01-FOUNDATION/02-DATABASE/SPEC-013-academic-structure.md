# SPEC-013: Academic Structure Schema

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-013  
**Title**: Academic Structure Database Schema  
**Phase**: Phase 1 - Foundation & Database  
**Category**: Database Schema - Academic Framework  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 55 minutes  

---

## 📋 DESCRIPTION

Implement comprehensive academic structure database schema including subjects, curricula, timetables, examination systems, grading schemes, and academic calendar management. This schema forms the foundation for all academic operations in the school management system.

## 🎯 SUCCESS CRITERIA

- [ ] Subject and curriculum management system
- [ ] Timetable and schedule management
- [ ] Examination and assessment framework
- [ ] Grading and evaluation system
- [ ] Academic calendar with events
- [ ] Class and section organization
- [ ] Teacher-subject assignments
- [ ] Multi-tenant isolation and performance optimization

---

## 📚 ACADEMIC STRUCTURE SCHEMA

### 1. Subject and Curriculum Management

```sql
-- ==============================================
-- SUBJECT AND CURRICULUM MANAGEMENT
-- ==============================================

-- Subjects master table
CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Subject Information
  subject_name VARCHAR(300) NOT NULL,
  subject_code VARCHAR(50) NOT NULL,
  short_name VARCHAR(100),
  description TEXT,
  
  -- Academic Classification
  subject_type VARCHAR(50) NOT NULL DEFAULT 'core', -- core, elective, optional, additional, extra_curricular
  subject_category VARCHAR(100) NOT NULL, -- languages, mathematics, sciences, social_studies, arts, sports
  
  -- Academic Structure
  applicable_classes JSONB NOT NULL DEFAULT '[]', -- Array of class levels [1,2,3,...,12]
  board_syllabus VARCHAR(100), -- CBSE, ICSE, State Board, etc.
  
  -- Subject Details
  theory_marks INTEGER DEFAULT 100,
  practical_marks INTEGER DEFAULT 0,
  total_marks INTEGER GENERATED ALWAYS AS (theory_marks + practical_marks) STORED,
  passing_marks INTEGER,
  
  -- Teaching Requirements
  periods_per_week INTEGER DEFAULT 1,
  teaching_hours_per_period DECIMAL(3,1) DEFAULT 1.0,
  total_teaching_hours DECIMAL(4,1) GENERATED ALWAYS AS (periods_per_week * teaching_hours_per_period) STORED,
  
  -- Prerequisites and Dependencies
  prerequisite_subjects JSONB DEFAULT '[]', -- Array of subject IDs
  
  -- Resources
  textbooks JSONB DEFAULT '[]', -- Array of textbook information
  reference_books JSONB DEFAULT '[]',
  online_resources JSONB DEFAULT '[]',
  
  -- Lab Requirements
  requires_lab BOOLEAN DEFAULT false,
  lab_equipment_required JSONB DEFAULT '[]',
  safety_requirements TEXT,
  
  -- Assessment Configuration
  assessment_pattern JSONB DEFAULT '{}', -- {internal: 20, external: 80, practical: 20}
  grading_scheme VARCHAR(100) DEFAULT 'percentage', -- percentage, grades, points
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  academic_year_introduced INTEGER,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(tenant_id, subject_code),
  UNIQUE(tenant_id, subject_name),
  CONSTRAINT valid_marks CHECK (theory_marks >= 0 AND practical_marks >= 0),
  CONSTRAINT valid_passing_marks CHECK (passing_marks IS NULL OR passing_marks <= (theory_marks + practical_marks))
);

-- Subject-class mapping (which subjects are taught in which classes)
CREATE TABLE IF NOT EXISTS class_subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  
  -- Subject Configuration for this class
  periods_per_week INTEGER NOT NULL DEFAULT 1,
  theory_marks INTEGER,
  practical_marks INTEGER,
  passing_marks INTEGER,
  
  -- Assessment Weightage
  internal_assessment_weightage DECIMAL(5,2) DEFAULT 20.0, -- Percentage
  external_assessment_weightage DECIMAL(5,2) DEFAULT 80.0,
  
  -- Teacher Assignment
  primary_teacher_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  assistant_teachers JSONB DEFAULT '[]', -- Array of staff IDs
  
  -- Subject Status
  is_compulsory BOOLEAN DEFAULT true,
  is_graded BOOLEAN DEFAULT true,
  
  -- Timing
  effective_from DATE,
  effective_to DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, class_id, subject_id, academic_year_id),
  CONSTRAINT valid_weightage CHECK (
    internal_assessment_weightage + external_assessment_weightage = 100
  )
);

-- Curriculum and syllabus management
CREATE TABLE IF NOT EXISTS curriculum (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  
  -- Curriculum Information
  curriculum_name VARCHAR(300) NOT NULL,
  curriculum_version VARCHAR(50) DEFAULT '1.0',
  board_approved BOOLEAN DEFAULT false,
  
  -- Syllabus Structure
  units JSONB NOT NULL DEFAULT '[]', -- Array of curriculum units
  learning_objectives JSONB DEFAULT '[]',
  learning_outcomes JSONB DEFAULT '[]',
  
  -- Time Allocation
  total_teaching_hours INTEGER NOT NULL,
  theory_hours INTEGER DEFAULT 0,
  practical_hours INTEGER DEFAULT 0,
  
  -- Assessment Pattern
  assessment_criteria JSONB DEFAULT '{}',
  evaluation_methods JSONB DEFAULT '[]',
  
  -- Resources and Materials
  prescribed_textbooks JSONB DEFAULT '[]',
  reference_materials JSONB DEFAULT '[]',
  digital_resources JSONB DEFAULT '[]',
  
  -- Implementation
  implementation_guidelines TEXT,
  teaching_methodology TEXT,
  
  -- Status and Approval
  status VARCHAR(50) NOT NULL DEFAULT 'draft', -- draft, approved, implemented, revised
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_date DATE,
  
  -- Version Control
  previous_version_id UUID REFERENCES curriculum(id) ON DELETE SET NULL,
  revision_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, subject_id, class_id, academic_year_id)
);

-- Curriculum units/chapters/topics
CREATE TABLE IF NOT EXISTS curriculum_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  curriculum_id UUID NOT NULL REFERENCES curriculum(id) ON DELETE CASCADE,
  
  -- Unit Information
  unit_number INTEGER NOT NULL,
  unit_name VARCHAR(300) NOT NULL,
  unit_description TEXT,
  
  -- Time Allocation
  allocated_hours INTEGER NOT NULL DEFAULT 1,
  theory_hours INTEGER DEFAULT 0,
  practical_hours INTEGER DEFAULT 0,
  
  -- Learning Details
  learning_objectives JSONB DEFAULT '[]',
  key_concepts JSONB DEFAULT '[]',
  topics JSONB DEFAULT '[]', -- Detailed topics within the unit
  
  -- Assessment
  assessment_weightage DECIMAL(5,2) DEFAULT 0, -- Percentage weightage in final assessment
  suggested_activities JSONB DEFAULT '[]',
  
  -- Resources
  reference_materials JSONB DEFAULT '[]',
  multimedia_resources JSONB DEFAULT '[]',
  
  -- Prerequisites
  prerequisite_units JSONB DEFAULT '[]', -- Array of unit IDs that should be completed first
  
  -- Implementation
  teaching_strategy TEXT,
  difficulty_level VARCHAR(50) DEFAULT 'medium', -- easy, medium, hard
  
  -- Status
  completion_status VARCHAR(50) DEFAULT 'not_started', -- not_started, in_progress, completed
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, curriculum_id, unit_number)
);
```

### 2. Timetable and Schedule Management

```sql
-- ==============================================
-- TIMETABLE AND SCHEDULE MANAGEMENT
-- ==============================================

-- Time slots (periods) configuration
CREATE TABLE IF NOT EXISTS time_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  
  -- Slot Information
  slot_name VARCHAR(100) NOT NULL, -- Period 1, Period 2, Assembly, Break, etc.
  slot_number INTEGER NOT NULL,
  slot_type VARCHAR(50) NOT NULL DEFAULT 'academic', -- academic, break, assembly, sports, etc.
  
  -- Timing
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (end_time - start_time))/60
  ) STORED,
  
  -- Days Applicable
  applicable_days JSONB NOT NULL DEFAULT '[1,2,3,4,5,6]', -- 1=Monday, 7=Sunday
  
  -- Configuration
  is_active BOOLEAN DEFAULT true,
  is_break BOOLEAN DEFAULT false,
  allows_scheduling BOOLEAN DEFAULT true,
  
  -- Academic Year
  academic_year_id UUID REFERENCES academic_years(id) ON DELETE CASCADE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, branch_id, slot_number, academic_year_id),
  CONSTRAINT end_after_start CHECK (end_time > start_time)
);

-- Class timetables
CREATE TABLE IF NOT EXISTS class_timetables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  section_id UUID REFERENCES sections(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  
  -- Timetable Information
  timetable_name VARCHAR(200) NOT NULL,
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'draft', -- draft, active, inactive, archived
  
  -- Approval
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, class_id, section_id, academic_year_id, effective_from)
);

-- Individual timetable entries
CREATE TABLE IF NOT EXISTS timetable_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  timetable_id UUID NOT NULL REFERENCES class_timetables(id) ON DELETE CASCADE,
  time_slot_id UUID NOT NULL REFERENCES time_slots(id) ON DELETE CASCADE,
  
  -- Schedule Details
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7), -- 1=Monday
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  teacher_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  
  -- Location
  room_number VARCHAR(100),
  building VARCHAR(200),
  venue_type VARCHAR(50) DEFAULT 'classroom', -- classroom, lab, playground, auditorium
  
  -- Special Configurations
  is_substitution BOOLEAN DEFAULT false,
  original_teacher_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  substitution_reason TEXT,
  
  -- Entry Type
  entry_type VARCHAR(50) NOT NULL DEFAULT 'regular', -- regular, exam, event, holiday
  special_notes TEXT,
  
  -- Recurrence (for recurring entries)
  recurrence_pattern VARCHAR(50) DEFAULT 'weekly', -- weekly, biweekly, monthly, once
  recurrence_end_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, timetable_id, time_slot_id, day_of_week)
);

-- Teacher timetables (automatically generated from class timetables)
CREATE TABLE IF NOT EXISTS teacher_timetables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  
  -- Generated Timetable Summary
  total_periods_per_week INTEGER DEFAULT 0,
  subjects_taught JSONB DEFAULT '[]', -- Array of subject IDs
  classes_taught JSONB DEFAULT '[]', -- Array of class/section combinations
  
  -- Workload Analysis
  workload_hours_per_week DECIMAL(4,1) DEFAULT 0,
  free_periods_per_week INTEGER DEFAULT 0,
  
  -- Generated At
  last_generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, teacher_id, academic_year_id)
);
```

### 3. Examination and Assessment Framework

```sql
-- ==============================================
-- EXAMINATION AND ASSESSMENT FRAMEWORK
-- ==============================================

-- Examination types and patterns
CREATE TABLE IF NOT EXISTS examination_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Examination Information
  exam_name VARCHAR(200) NOT NULL,
  exam_code VARCHAR(50) NOT NULL,
  description TEXT,
  
  -- Examination Pattern
  exam_pattern VARCHAR(100) NOT NULL, -- written, oral, practical, project, online
  exam_category VARCHAR(100) NOT NULL, -- unit_test, monthly, quarterly, half_yearly, annual
  
  -- Weightage and Marks
  total_marks INTEGER NOT NULL DEFAULT 100,
  weightage_percentage DECIMAL(5,2) NOT NULL DEFAULT 100, -- Weightage in final result
  passing_marks INTEGER,
  
  -- Duration and Format
  duration_minutes INTEGER DEFAULT 180, -- 3 hours default
  question_paper_format JSONB DEFAULT '{}', -- Structure of question paper
  
  -- Applicability
  applicable_classes JSONB NOT NULL DEFAULT '[]', -- Array of class levels
  applicable_subjects JSONB DEFAULT '[]', -- If specific to certain subjects
  
  -- Rules and Instructions
  exam_instructions TEXT,
  evaluation_criteria TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, exam_code)
);

-- Examination schedules
CREATE TABLE IF NOT EXISTS examinations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  academic_term_id UUID REFERENCES academic_terms(id) ON DELETE SET NULL,
  examination_type_id UUID NOT NULL REFERENCES examination_types(id) ON DELETE CASCADE,
  
  -- Examination Details
  exam_name VARCHAR(300) NOT NULL,
  exam_session VARCHAR(100), -- March 2024, Final Exam 2024, etc.
  
  -- Schedule
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  -- Registration
  registration_start_date DATE,
  registration_end_date DATE,
  registration_fee DECIMAL(10,2) DEFAULT 0,
  
  -- Result Declaration
  result_declaration_date DATE,
  result_published BOOLEAN DEFAULT false,
  result_published_date DATE,
  
  -- Applicable Scope
  applicable_classes JSONB NOT NULL DEFAULT '[]', -- Array of class IDs
  applicable_branches JSONB DEFAULT '[]', -- If multi-branch
  
  -- Configuration
  settings JSONB DEFAULT '{}', -- Exam-specific settings
  instructions TEXT,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'scheduled', -- scheduled, ongoing, completed, cancelled
  
  -- Approval
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_date DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT end_after_start CHECK (end_date >= start_date)
);

-- Individual exam papers/subjects within an examination
CREATE TABLE IF NOT EXISTS exam_papers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  examination_id UUID NOT NULL REFERENCES examinations(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  
  -- Paper Details
  paper_name VARCHAR(300),
  paper_code VARCHAR(100),
  
  -- Exam Schedule
  exam_date DATE NOT NULL,
  exam_time TIME NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 180,
  
  -- Venue
  exam_hall VARCHAR(200),
  building VARCHAR(200),
  seating_arrangement VARCHAR(100), -- roll_number, alphabetical, random
  
  -- Paper Configuration
  total_marks INTEGER NOT NULL,
  passing_marks INTEGER,
  question_paper_url TEXT, -- Link to question paper file
  
  -- Evaluation
  evaluation_type VARCHAR(50) DEFAULT 'manual', -- manual, automated, mixed
  evaluator_ids JSONB DEFAULT '[]', -- Array of staff IDs who will evaluate
  
  -- Answer Sheets
  answer_sheet_format VARCHAR(50) DEFAULT 'physical', -- physical, digital, omr
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'scheduled', -- scheduled, ongoing, completed, cancelled
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, examination_id, subject_id, class_id)
);

-- Student exam registrations
CREATE TABLE IF NOT EXISTS student_exam_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  examination_id UUID NOT NULL REFERENCES examinations(id) ON DELETE CASCADE,
  
  -- Registration Details
  registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
  registration_number VARCHAR(100),
  
  -- Subjects Registered
  registered_subjects JSONB NOT NULL DEFAULT '[]', -- Array of subject IDs
  
  -- Fees
  registration_fee DECIMAL(10,2) DEFAULT 0,
  fee_paid BOOLEAN DEFAULT false,
  fee_payment_date DATE,
  fee_receipt_number VARCHAR(100),
  
  -- Hall Ticket
  hall_ticket_number VARCHAR(100),
  hall_ticket_generated BOOLEAN DEFAULT false,
  hall_ticket_generated_date DATE,
  
  -- Status
  registration_status VARCHAR(50) NOT NULL DEFAULT 'registered', -- registered, confirmed, cancelled
  
  -- Special Accommodations
  special_requirements JSONB DEFAULT '[]', -- Array of special needs
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, examination_id)
);
```

### 4. Grading and Evaluation System

```sql
-- ==============================================
-- GRADING AND EVALUATION SYSTEM
-- ==============================================

-- Grading schemes
CREATE TABLE IF NOT EXISTS grading_schemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Scheme Information
  scheme_name VARCHAR(200) NOT NULL,
  scheme_code VARCHAR(50) NOT NULL,
  description TEXT,
  
  -- Scheme Type
  scheme_type VARCHAR(50) NOT NULL DEFAULT 'letter', -- letter, numeric, percentage, points
  
  -- Grade Ranges (for letter/numeric grades)
  grade_ranges JSONB NOT NULL DEFAULT '[]', -- Array of grade definitions
  
  -- Configuration
  uses_gpa BOOLEAN DEFAULT false,
  gpa_scale DECIMAL(3,2) DEFAULT 4.0, -- 4.0, 10.0, etc.
  
  -- Applicability
  applicable_classes JSONB DEFAULT '[]', -- Array of class levels
  default_for_classes JSONB DEFAULT '[]',
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, scheme_code)
);

-- Individual grades within a grading scheme
CREATE TABLE IF NOT EXISTS grades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  grading_scheme_id UUID NOT NULL REFERENCES grading_schemes(id) ON DELETE CASCADE,
  
  -- Grade Information
  grade_name VARCHAR(10) NOT NULL, -- A+, A, B+, B, etc. or 1st, 2nd, etc.
  grade_description VARCHAR(200), -- Excellent, Good, Satisfactory, etc.
  
  -- Grade Range
  min_marks DECIMAL(5,2) NOT NULL,
  max_marks DECIMAL(5,2) NOT NULL,
  
  -- Grade Value
  grade_points DECIMAL(4,2), -- For GPA calculation
  percentage_equivalent DECIMAL(5,2), -- Equivalent percentage
  
  -- Display Order
  sort_order INTEGER NOT NULL DEFAULT 1,
  
  -- Status
  is_passing_grade BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, grading_scheme_id, grade_name),
  CONSTRAINT valid_range CHECK (max_marks >= min_marks)
);

-- Student exam results
CREATE TABLE IF NOT EXISTS student_exam_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  exam_paper_id UUID NOT NULL REFERENCES exam_papers(id) ON DELETE CASCADE,
  
  -- Marks Details
  marks_obtained DECIMAL(6,2),
  total_marks INTEGER NOT NULL,
  percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN total_marks > 0 THEN (marks_obtained * 100.0 / total_marks)
      ELSE NULL
    END
  ) STORED,
  
  -- Grade Information
  grade VARCHAR(10),
  grade_points DECIMAL(4,2),
  
  -- Status
  result_status VARCHAR(50) NOT NULL DEFAULT 'pass', -- pass, fail, absent, detained
  
  -- Evaluation Details
  evaluated_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  evaluation_date DATE,
  evaluation_notes TEXT,
  
  -- Answer Sheet Information
  answer_sheet_number VARCHAR(100),
  answer_sheet_url TEXT, -- Scanned copy if digital
  
  -- Verification
  verified_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  verification_date DATE,
  
  -- Re-evaluation
  reevaluation_requested BOOLEAN DEFAULT false,
  reevaluation_marks DECIMAL(6,2),
  reevaluation_reason TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, exam_paper_id),
  CONSTRAINT valid_marks CHECK (marks_obtained >= 0 AND marks_obtained <= total_marks)
);

-- Consolidated student results (term/annual)
CREATE TABLE IF NOT EXISTS student_consolidated_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  examination_id UUID NOT NULL REFERENCES examinations(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  
  -- Overall Performance
  total_marks_obtained DECIMAL(8,2) NOT NULL DEFAULT 0,
  total_maximum_marks INTEGER NOT NULL DEFAULT 0,
  overall_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN total_maximum_marks > 0 THEN (total_marks_obtained * 100.0 / total_maximum_marks)
      ELSE NULL
    END
  ) STORED,
  
  -- Grade and GPA
  overall_grade VARCHAR(10),
  gpa DECIMAL(4,2),
  
  -- Subject-wise Results Summary
  subject_results JSONB NOT NULL DEFAULT '{}', -- Subject-wise marks and grades
  
  -- Performance Analysis
  subjects_passed INTEGER DEFAULT 0,
  subjects_failed INTEGER DEFAULT 0,
  
  -- Rank and Position
  class_rank INTEGER,
  section_rank INTEGER,
  total_students_in_class INTEGER,
  
  -- Result Status
  result_status VARCHAR(50) NOT NULL DEFAULT 'pass', -- pass, fail, compartment, detained
  promotion_status VARCHAR(50) DEFAULT 'promoted', -- promoted, detained, repeat
  
  -- Comments and Remarks
  teacher_remarks TEXT,
  principal_remarks TEXT,
  
  -- Result Declaration
  result_declared BOOLEAN DEFAULT false,
  result_declaration_date DATE,
  result_card_generated BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(tenant_id, student_id, examination_id)
);
```

---

## 📊 PERFORMANCE OPTIMIZATION

### 1. Indexes for Academic Structure

```sql
-- ==============================================
-- ACADEMIC STRUCTURE INDEXES
-- ==============================================

-- Subject indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subjects_tenant_id ON subjects(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subjects_code ON subjects(tenant_id, subject_code) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subjects_category ON subjects(tenant_id, subject_category, is_active);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subjects_type ON subjects(tenant_id, subject_type, is_active);

-- Class-subject mapping indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_subjects_class ON class_subjects(tenant_id, class_id, academic_year_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_subjects_subject ON class_subjects(tenant_id, subject_id, academic_year_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_subjects_teacher ON class_subjects(tenant_id, primary_teacher_id) WHERE primary_teacher_id IS NOT NULL;

-- Curriculum indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_curriculum_subject_class ON curriculum(tenant_id, subject_id, class_id, academic_year_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_curriculum_status ON curriculum(tenant_id, status);

-- Timetable indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_time_slots_branch ON time_slots(tenant_id, branch_id, academic_year_id, is_active);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_timetables_class ON class_timetables(tenant_id, class_id, section_id, academic_year_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_timetable_entries_timetable ON timetable_entries(tenant_id, timetable_id, day_of_week);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_timetable_entries_teacher ON timetable_entries(tenant_id, teacher_id) WHERE teacher_id IS NOT NULL;

-- Examination indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_examinations_academic_year ON examinations(tenant_id, academic_year_id, status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_papers_examination ON exam_papers(tenant_id, examination_id, exam_date);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_papers_subject_class ON exam_papers(tenant_id, subject_id, class_id);

-- Results indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_exam_results_student ON student_exam_results(tenant_id, student_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_exam_results_paper ON student_exam_results(tenant_id, exam_paper_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_consolidated_results_student ON student_consolidated_results(tenant_id, student_id, examination_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_student_consolidated_results_class ON student_consolidated_results(tenant_id, class_id, examination_id, class_rank);

-- Search indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subjects_search ON subjects 
  USING gin(to_tsvector('english', subject_name || ' ' || subject_code || ' ' || COALESCE(short_name, '')))
  WHERE deleted_at IS NULL;
```

---

## 🔒 ROW-LEVEL SECURITY POLICIES

```sql
-- ==============================================
-- ACADEMIC STRUCTURE RLS POLICIES
-- ==============================================

-- Enable RLS on all academic tables
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE examination_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE examinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_exam_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_consolidated_results ENABLE ROW LEVEL SECURITY;

-- Academic structure policies
CREATE POLICY tenant_isolation_subjects ON subjects
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_class_subjects ON class_subjects
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_curriculum ON curriculum
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_curriculum_units ON curriculum_units
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Timetable policies
CREATE POLICY tenant_isolation_time_slots ON time_slots
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_class_timetables ON class_timetables
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_timetable_entries ON timetable_entries
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_teacher_timetables ON teacher_timetables
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Examination policies
CREATE POLICY tenant_isolation_examination_types ON examination_types
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_examinations ON examinations
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_exam_papers ON exam_papers
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_exam_registrations ON student_exam_registrations
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

-- Grading and results policies
CREATE POLICY tenant_isolation_grading_schemes ON grading_schemes
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_grades ON grades
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_exam_results ON student_exam_results
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());

CREATE POLICY tenant_isolation_student_consolidated_results ON student_consolidated_results
  FOR ALL TO authenticated
  USING (tenant_id = get_current_tenant_id());
```

---

## 🔧 HELPER FUNCTIONS AND TRIGGERS

```sql
-- ==============================================
-- ACADEMIC STRUCTURE FUNCTIONS
-- ==============================================

-- Function to generate hall ticket number
CREATE OR REPLACE FUNCTION generate_hall_ticket_number(
  tenant_uuid UUID,
  examination_uuid UUID,
  student_uuid UUID
)
RETURNS TEXT AS $$
DECLARE
  exam_code TEXT;
  year_code TEXT;
  sequence_num INTEGER;
  hall_ticket_number TEXT;
BEGIN
  -- Get examination code and year
  SELECT 
    et.exam_code,
    EXTRACT(YEAR FROM e.start_date)
  INTO exam_code, year_code
  FROM examinations e 
  JOIN examination_types et ON e.examination_type_id = et.id
  WHERE e.id = examination_uuid AND e.tenant_id = tenant_uuid;
  
  -- Get next sequence number
  SELECT COALESCE(MAX(CAST(SUBSTRING(hall_ticket_number FROM '\d+$') AS INTEGER)), 0) + 1
  INTO sequence_num
  FROM student_exam_registrations
  WHERE tenant_id = tenant_uuid 
    AND examination_id = examination_uuid
    AND hall_ticket_number IS NOT NULL;
  
  -- Format: YYYY<EXAM_CODE><SEQUENCE>
  hall_ticket_number := year_code || exam_code || LPAD(sequence_num::TEXT, 6, '0');
  
  RETURN hall_ticket_number;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate GPA
CREATE OR REPLACE FUNCTION calculate_gpa(
  student_uuid UUID,
  examination_uuid UUID
)
RETURNS DECIMAL(4,2) AS $$
DECLARE
  total_credits INTEGER := 0;
  weighted_points DECIMAL(8,2) := 0;
  gpa_result DECIMAL(4,2);
BEGIN
  -- Calculate weighted GPA based on subject credits and grade points
  SELECT 
    SUM(s.credits),
    SUM(s.credits * r.grade_points)
  INTO total_credits, weighted_points
  FROM student_exam_results r
  JOIN exam_papers ep ON r.exam_paper_id = ep.id
  JOIN subjects s ON ep.subject_id = s.id
  WHERE r.student_id = student_uuid 
    AND ep.examination_id = examination_uuid
    AND r.grade_points IS NOT NULL;
  
  IF total_credits > 0 THEN
    gpa_result := weighted_points / total_credits;
  ELSE
    gpa_result := NULL;
  END IF;
  
  RETURN gpa_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to update consolidated results
CREATE OR REPLACE FUNCTION update_consolidated_results()
RETURNS TRIGGER AS $$
DECLARE
  total_marks DECIMAL(8,2);
  max_marks INTEGER;
  student_gpa DECIMAL(4,2);
BEGIN
  -- Calculate totals from individual exam results
  SELECT 
    SUM(r.marks_obtained),
    SUM(r.total_marks)
  INTO total_marks, max_marks
  FROM student_exam_results r
  JOIN exam_papers ep ON r.exam_paper_id = ep.id
  WHERE r.student_id = NEW.student_id 
    AND ep.examination_id = (
      SELECT examination_id FROM exam_papers WHERE id = NEW.exam_paper_id
    );
  
  -- Calculate GPA
  student_gpa := calculate_gpa(NEW.student_id, (
    SELECT examination_id FROM exam_papers WHERE id = NEW.exam_paper_id
  ));
  
  -- Update or insert consolidated result
  INSERT INTO student_consolidated_results (
    tenant_id, student_id, examination_id, class_id,
    total_marks_obtained, total_maximum_marks, gpa
  )
  SELECT 
    NEW.tenant_id, NEW.student_id, ep.examination_id, ep.class_id,
    total_marks, max_marks, student_gpa
  FROM exam_papers ep
  WHERE ep.id = NEW.exam_paper_id
  ON CONFLICT (tenant_id, student_id, examination_id) 
  DO UPDATE SET
    total_marks_obtained = EXCLUDED.total_marks_obtained,
    total_maximum_marks = EXCLUDED.total_maximum_marks,
    gpa = EXCLUDED.gpa,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_consolidated_results_trigger
  AFTER INSERT OR UPDATE ON student_exam_results
  FOR EACH ROW
  EXECUTE FUNCTION update_consolidated_results();

-- Trigger to set hall ticket number automatically
CREATE OR REPLACE FUNCTION set_hall_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.hall_ticket_number IS NULL OR NEW.hall_ticket_number = '' THEN
    NEW.hall_ticket_number := generate_hall_ticket_number(
      NEW.tenant_id, 
      NEW.examination_id,
      NEW.student_id
    );
    NEW.hall_ticket_generated := true;
    NEW.hall_ticket_generated_date := CURRENT_DATE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_hall_ticket_number_trigger
  BEFORE INSERT OR UPDATE ON student_exam_registrations
  FOR EACH ROW
  WHEN (NEW.registration_status = 'confirmed')
  EXECUTE FUNCTION set_hall_ticket_number();
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] Subject and curriculum management system
- [x] Timetable creation and management
- [x] Examination framework with scheduling
- [x] Grading schemes and evaluation system
- [x] Student result management
- [x] Multi-tenant isolation and security
- [x] Performance optimization with indexes
- [x] Automated calculations and triggers

### Should Have  
- [x] Academic calendar integration
- [x] Teacher workload analysis
- [x] Curriculum unit tracking
- [x] Examination registration system
- [x] Result analytics and ranking
- [x] Hall ticket generation
- [x] GPA calculation system

### Could Have
- [x] Advanced timetable optimization
- [x] Question paper management
- [x] Online examination support
- [x] Result publication system
- [x] Performance trend analysis
- [x] Curriculum compliance tracking

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-010 (Core Tables), SPEC-011 (Students), SPEC-012 (Staff)  
**Depends On**: Academic years, Classes, Students, Teachers  
**Blocks**: Attendance system, Fee management, Report generation  

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-014-attendance-system.sql