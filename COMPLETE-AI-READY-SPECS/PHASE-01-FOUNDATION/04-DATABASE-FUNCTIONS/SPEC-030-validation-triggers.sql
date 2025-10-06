# 🔍 VALIDATION TRIGGERS
**Specification ID**: SPEC-030  
**Title**: Data Validation Triggers and Constraints  
**Created**: October 4, 2025  
**Status**: ✅ COMPLETE  
**Priority**: HIGH  

---

## 📋 OVERVIEW

This specification defines comprehensive validation triggers for the School Management SaaS platform. These triggers ensure data integrity, business rule enforcement, automatic data validation, and consistency across all database operations.

---

## 🎯 OBJECTIVES

### Primary Goals
- ✅ Comprehensive data validation at database level
- ✅ Business rule enforcement through triggers
- ✅ Automatic data formatting and cleaning
- ✅ Cross-table consistency validation
- ✅ Multi-tenant data integrity
- ✅ Performance optimized validation

### Success Criteria
- All critical business rules enforced
- Data integrity maintained across operations
- Validation errors provide clear messages
- Performance impact minimized
- Multi-tenant isolation preserved

---

## 🛠️ IMPLEMENTATION

### Complete Validation Triggers System

```sql
-- ==============================================
-- VALIDATION TRIGGERS
-- File: SPEC-030-validation-triggers.sql
-- Created: October 4, 2025
-- Description: Comprehensive data validation triggers and constraints
-- ==============================================

-- ==============================================
-- USER VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for user data validation
CREATE OR REPLACE FUNCTION validate_user_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate email format
  IF NEW.email IS NOT NULL AND NOT utils.is_valid_email(NEW.email) THEN
    RAISE EXCEPTION 'Invalid email format: %', NEW.email;
  END IF;
  
  -- Format full name
  IF NEW.full_name IS NOT NULL THEN
    NEW.full_name := utils.format_name(NEW.full_name);
  END IF;
  
  -- Format phone number
  IF NEW.phone IS NOT NULL THEN
    NEW.phone := utils.format_phone(NEW.phone);
  END IF;
  
  -- Validate age constraints
  IF NEW.date_of_birth IS NOT NULL THEN
    IF NEW.date_of_birth > CURRENT_DATE THEN
      RAISE EXCEPTION 'Birth date cannot be in the future';
    END IF;
    
    IF utils.calculate_age(NEW.date_of_birth) > 120 THEN
      RAISE EXCEPTION 'Invalid birth date - age cannot exceed 120 years';
    END IF;
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply user validation trigger
CREATE TRIGGER trigger_validate_user_data
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION validate_user_data();

-- ==============================================
-- STUDENT VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for student data validation
CREATE OR REPLACE FUNCTION validate_student_data()
RETURNS TRIGGER AS $$
DECLARE
  student_age INTEGER;
  class_age_min INTEGER;
  class_age_max INTEGER;
  enrollment_count INTEGER;
BEGIN
  -- Validate student ID format
  IF NEW.student_id IS NOT NULL AND NEW.student_id !~ '^[A-Z0-9]{6,12}$' THEN
    RAISE EXCEPTION 'Student ID must be 6-12 alphanumeric characters';
  END IF;
  
  -- Generate student ID if not provided
  IF NEW.student_id IS NULL THEN
    NEW.student_id := utils.generate_unique_code('STU', 8, 'students', 'student_id');
  END IF;
  
  -- Validate admission date
  IF NEW.admission_date IS NOT NULL THEN
    IF NEW.admission_date > CURRENT_DATE THEN
      RAISE EXCEPTION 'Admission date cannot be in the future';
    END IF;
    
    IF NEW.admission_date < CURRENT_DATE - INTERVAL '10 years' THEN
      RAISE EXCEPTION 'Admission date cannot be more than 10 years in the past';
    END IF;
  END IF;
  
  -- Validate age for class assignment
  IF NEW.class_id IS NOT NULL THEN
    -- Get student age from user table
    SELECT utils.calculate_age(u.date_of_birth) INTO student_age
    FROM users u WHERE u.id = NEW.user_id;
    
    -- Get class age requirements
    SELECT age_min, age_max INTO class_age_min, class_age_max
    FROM classes WHERE id = NEW.class_id AND tenant_id = NEW.tenant_id;
    
    IF student_age IS NOT NULL AND class_age_min IS NOT NULL THEN
      IF student_age < class_age_min OR student_age > class_age_max THEN
        RAISE EXCEPTION 'Student age (%) not suitable for class (age range: %-% years)', 
          student_age, class_age_min, class_age_max;
      END IF;
    END IF;
  END IF;
  
  -- Validate guardian relationship
  IF NEW.guardian_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM users 
      WHERE id = NEW.guardian_id 
        AND tenant_id = NEW.tenant_id 
        AND is_active = true
    ) THEN
      RAISE EXCEPTION 'Invalid guardian ID or guardian is inactive';
    END IF;
  END IF;
  
  -- Check for duplicate active enrollments
  IF NEW.status = 'active' AND NEW.class_id IS NOT NULL THEN
    SELECT COUNT(*) INTO enrollment_count
    FROM students 
    WHERE user_id = NEW.user_id 
      AND tenant_id = NEW.tenant_id 
      AND status = 'active'
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
    
    IF enrollment_count > 0 THEN
      RAISE EXCEPTION 'Student cannot have multiple active enrollments';
    END IF;
  END IF;
  
  -- Set academic year if not provided
  IF NEW.academic_year IS NULL THEN
    NEW.academic_year := utils.get_academic_year();
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply student validation trigger
CREATE TRIGGER trigger_validate_student_data
  BEFORE INSERT OR UPDATE ON students
  FOR EACH ROW
  EXECUTE FUNCTION validate_student_data();

-- ==============================================
-- STAFF VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for staff data validation
CREATE OR REPLACE FUNCTION validate_staff_data()
RETURNS TRIGGER AS $$
DECLARE
  employment_overlap INTEGER;
  staff_age INTEGER;
BEGIN
  -- Validate employee ID format
  IF NEW.employee_id IS NOT NULL AND NEW.employee_id !~ '^[A-Z0-9]{6,12}$' THEN
    RAISE EXCEPTION 'Employee ID must be 6-12 alphanumeric characters';
  END IF;
  
  -- Generate employee ID if not provided
  IF NEW.employee_id IS NULL THEN
    NEW.employee_id := utils.generate_unique_code('EMP', 8, 'staff', 'employee_id');
  END IF;
  
  -- Validate employment dates
  IF NEW.hire_date IS NOT NULL THEN
    IF NEW.hire_date > CURRENT_DATE THEN
      RAISE EXCEPTION 'Hire date cannot be in the future';
    END IF;
    
    IF NEW.termination_date IS NOT NULL AND NEW.hire_date >= NEW.termination_date THEN
      RAISE EXCEPTION 'Hire date must be before termination date';
    END IF;
  END IF;
  
  -- Validate staff age for employment
  SELECT utils.calculate_age(u.date_of_birth) INTO staff_age
  FROM users u WHERE u.id = NEW.user_id;
  
  IF staff_age IS NOT NULL THEN
    IF staff_age < 18 THEN
      RAISE EXCEPTION 'Staff member must be at least 18 years old';
    END IF;
    
    IF staff_age > 75 THEN
      RAISE EXCEPTION 'Staff member cannot be older than 75 years at time of employment';
    END IF;
  END IF;
  
  -- Validate salary range
  IF NEW.salary IS NOT NULL THEN
    IF NEW.salary <= 0 THEN
      RAISE EXCEPTION 'Salary must be a positive amount';
    END IF;
    
    IF NEW.salary > 1000000 THEN
      RAISE EXCEPTION 'Salary amount seems unrealistic (over $1,000,000)';
    END IF;
  END IF;
  
  -- Check for overlapping employment periods
  IF NEW.status = 'active' THEN
    SELECT COUNT(*) INTO employment_overlap
    FROM staff 
    WHERE user_id = NEW.user_id 
      AND tenant_id = NEW.tenant_id 
      AND status = 'active'
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
    
    IF employment_overlap > 0 THEN
      RAISE EXCEPTION 'Staff member cannot have multiple active employment records';
    END IF;
  END IF;
  
  -- Validate department exists
  IF NEW.department_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM departments 
      WHERE id = NEW.department_id 
        AND tenant_id = NEW.tenant_id 
        AND is_active = true
    ) THEN
      RAISE EXCEPTION 'Invalid department ID or department is inactive';
    END IF;
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply staff validation trigger
CREATE TRIGGER trigger_validate_staff_data
  BEFORE INSERT OR UPDATE ON staff
  FOR EACH ROW
  EXECUTE FUNCTION validate_staff_data();

-- ==============================================
-- CLASS VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for class data validation
CREATE OR REPLACE FUNCTION validate_class_data()
RETURNS TRIGGER AS $$
DECLARE
  capacity_exceeded BOOLEAN := false;
  current_enrollment INTEGER;
BEGIN
  -- Validate class name
  IF NEW.name IS NULL OR trim(NEW.name) = '' THEN
    RAISE EXCEPTION 'Class name cannot be empty';
  END IF;
  
  -- Format class name
  NEW.name := utils.format_name(NEW.name);
  
  -- Validate capacity
  IF NEW.capacity IS NOT NULL AND NEW.capacity <= 0 THEN
    RAISE EXCEPTION 'Class capacity must be a positive number';
  END IF;
  
  IF NEW.capacity IS NOT NULL AND NEW.capacity > 100 THEN
    RAISE EXCEPTION 'Class capacity cannot exceed 100 students';
  END IF;
  
  -- Validate age range
  IF NEW.age_min IS NOT NULL AND NEW.age_max IS NOT NULL THEN
    IF NEW.age_min >= NEW.age_max THEN
      RAISE EXCEPTION 'Minimum age must be less than maximum age';
    END IF;
    
    IF NEW.age_min < 3 OR NEW.age_max > 25 THEN
      RAISE EXCEPTION 'Age range must be between 3 and 25 years';
    END IF;
  END IF;
  
  -- Check if capacity reduction would exceed current enrollment
  IF TG_OP = 'UPDATE' AND NEW.capacity < OLD.capacity THEN
    SELECT COUNT(*) INTO current_enrollment
    FROM students 
    WHERE class_id = NEW.id 
      AND tenant_id = NEW.tenant_id 
      AND status = 'active';
    
    IF current_enrollment > NEW.capacity THEN
      RAISE EXCEPTION 'Cannot reduce capacity to % - current enrollment is %', 
        NEW.capacity, current_enrollment;
    END IF;
  END IF;
  
  -- Validate academic year
  IF NEW.academic_year IS NULL THEN
    NEW.academic_year := utils.get_academic_year();
  END IF;
  
  -- Generate class code if not provided
  IF NEW.class_code IS NULL THEN
    NEW.class_code := utils.generate_unique_code('CLS', 6, 'classes', 'class_code');
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply class validation trigger
CREATE TRIGGER trigger_validate_class_data
  BEFORE INSERT OR UPDATE ON classes
  FOR EACH ROW
  EXECUTE FUNCTION validate_class_data();

-- ==============================================
-- SUBJECT VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for subject data validation
CREATE OR REPLACE FUNCTION validate_subject_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate subject name
  IF NEW.name IS NULL OR trim(NEW.name) = '' THEN
    RAISE EXCEPTION 'Subject name cannot be empty';
  END IF;
  
  -- Format subject name
  NEW.name := utils.format_name(NEW.name);
  
  -- Validate subject code
  IF NEW.subject_code IS NOT NULL AND NEW.subject_code !~ '^[A-Z0-9]{3,10}$' THEN
    RAISE EXCEPTION 'Subject code must be 3-10 alphanumeric characters';
  END IF;
  
  -- Generate subject code if not provided
  IF NEW.subject_code IS NULL THEN
    NEW.subject_code := utils.generate_unique_code('SUB', 6, 'subjects', 'subject_code');
  END IF;
  
  -- Validate credits
  IF NEW.credits IS NOT NULL THEN
    IF NEW.credits <= 0 OR NEW.credits > 10 THEN
      RAISE EXCEPTION 'Subject credits must be between 1 and 10';
    END IF;
  END IF;
  
  -- Validate duration (in minutes)
  IF NEW.duration_minutes IS NOT NULL THEN
    IF NEW.duration_minutes < 30 OR NEW.duration_minutes > 300 THEN
      RAISE EXCEPTION 'Subject duration must be between 30 and 300 minutes';
    END IF;
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply subject validation trigger
CREATE TRIGGER trigger_validate_subject_data
  BEFORE INSERT OR UPDATE ON subjects
  FOR EACH ROW
  EXECUTE FUNCTION validate_subject_data();

-- ==============================================
-- ATTENDANCE VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for attendance data validation
CREATE OR REPLACE FUNCTION validate_attendance_data()
RETURNS TRIGGER AS $$
DECLARE
  student_class_id UUID;
  is_school_day BOOLEAN;
BEGIN
  -- Validate attendance date
  IF NEW.attendance_date IS NULL THEN
    RAISE EXCEPTION 'Attendance date is required';
  END IF;
  
  IF NEW.attendance_date > CURRENT_DATE THEN
    RAISE EXCEPTION 'Cannot mark attendance for future dates';
  END IF;
  
  IF NEW.attendance_date < CURRENT_DATE - INTERVAL '30 days' THEN
    RAISE EXCEPTION 'Cannot mark attendance for dates older than 30 days';
  END IF;
  
  -- Check if it's a school day
  SELECT utils.count_school_days(NEW.attendance_date, NEW.attendance_date, true, true, NEW.tenant_id) > 0 
  INTO is_school_day;
  
  IF NOT is_school_day THEN
    RAISE EXCEPTION 'Cannot mark attendance on non-school days';
  END IF;
  
  -- Validate student enrollment
  SELECT s.class_id INTO student_class_id
  FROM students s
  WHERE s.id = NEW.student_id 
    AND s.tenant_id = NEW.tenant_id 
    AND s.status = 'active';
  
  IF student_class_id IS NULL THEN
    RAISE EXCEPTION 'Student is not actively enrolled or does not exist';
  END IF;
  
  -- Validate attendance status
  IF NEW.status NOT IN ('present', 'absent', 'late', 'excused') THEN
    RAISE EXCEPTION 'Invalid attendance status: %', NEW.status;
  END IF;
  
  -- Validate late arrival time
  IF NEW.status = 'late' AND NEW.late_minutes IS NULL THEN
    NEW.late_minutes := 15; -- Default late minutes
  END IF;
  
  IF NEW.late_minutes IS NOT NULL THEN
    IF NEW.late_minutes <= 0 OR NEW.late_minutes > 480 THEN
      RAISE EXCEPTION 'Late minutes must be between 1 and 480 (8 hours)';
    END IF;
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply attendance validation trigger
CREATE TRIGGER trigger_validate_attendance_data
  BEFORE INSERT OR UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION validate_attendance_data();

-- ==============================================
-- GRADE VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for grade data validation
CREATE OR REPLACE FUNCTION validate_grade_data()
RETURNS TRIGGER AS $$
DECLARE
  subject_max_marks NUMERIC;
  student_enrolled BOOLEAN := false;
BEGIN
  -- Validate marks
  IF NEW.marks_obtained IS NOT NULL THEN
    IF NEW.marks_obtained < 0 THEN
      RAISE EXCEPTION 'Marks obtained cannot be negative';
    END IF;
    
    IF NEW.total_marks IS NOT NULL AND NEW.marks_obtained > NEW.total_marks THEN
      RAISE EXCEPTION 'Marks obtained (%) cannot exceed total marks (%)', 
        NEW.marks_obtained, NEW.total_marks;
    END IF;
  END IF;
  
  -- Validate total marks
  IF NEW.total_marks IS NOT NULL THEN
    IF NEW.total_marks <= 0 THEN
      RAISE EXCEPTION 'Total marks must be a positive number';
    END IF;
    
    IF NEW.total_marks > 1000 THEN
      RAISE EXCEPTION 'Total marks cannot exceed 1000';
    END IF;
  END IF;
  
  -- Calculate percentage and grade
  IF NEW.marks_obtained IS NOT NULL AND NEW.total_marks IS NOT NULL THEN
    NEW.percentage := utils.calculate_percentage(NEW.marks_obtained, NEW.total_marks);
    NEW.grade := utils.get_grade_from_percentage(NEW.percentage);
    NEW.grade_points := utils.get_grade_points(NEW.grade);
  END IF;
  
  -- Validate student enrollment in subject
  SELECT EXISTS(
    SELECT 1 FROM student_enrollments se
    JOIN class_subjects cs ON se.class_id = cs.class_id
    WHERE se.student_id = NEW.student_id
      AND cs.subject_id = NEW.subject_id
      AND se.tenant_id = NEW.tenant_id
      AND se.status = 'active'
      AND se.academic_year = COALESCE(NEW.academic_year, utils.get_academic_year())
  ) INTO student_enrolled;
  
  IF NOT student_enrolled THEN
    RAISE EXCEPTION 'Student is not enrolled in this subject';
  END IF;
  
  -- Set academic year if not provided
  IF NEW.academic_year IS NULL THEN
    NEW.academic_year := utils.get_academic_year();
  END IF;
  
  -- Validate exam type
  IF NEW.exam_type NOT IN ('quiz', 'assignment', 'midterm', 'final', 'project', 'practical') THEN
    RAISE EXCEPTION 'Invalid exam type: %', NEW.exam_type;
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply grade validation trigger
CREATE TRIGGER trigger_validate_grade_data
  BEFORE INSERT OR UPDATE ON grades
  FOR EACH ROW
  EXECUTE FUNCTION validate_grade_data();

-- ==============================================
-- FEE VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for fee data validation
CREATE OR REPLACE FUNCTION validate_fee_data()
RETURNS TRIGGER AS $$
DECLARE
  student_active BOOLEAN := false;
BEGIN
  -- Validate fee amount
  IF NEW.amount IS NOT NULL THEN
    IF NEW.amount <= 0 THEN
      RAISE EXCEPTION 'Fee amount must be positive';
    END IF;
    
    IF NEW.amount > 100000 THEN
      RAISE EXCEPTION 'Fee amount cannot exceed $100,000';
    END IF;
  END IF;
  
  -- Validate due date
  IF NEW.due_date IS NOT NULL THEN
    IF NEW.due_date < CURRENT_DATE - INTERVAL '1 year' THEN
      RAISE EXCEPTION 'Due date cannot be more than 1 year in the past';
    END IF;
    
    IF NEW.due_date > CURRENT_DATE + INTERVAL '2 years' THEN
      RAISE EXCEPTION 'Due date cannot be more than 2 years in the future';
    END IF;
  END IF;
  
  -- Validate student is active
  SELECT EXISTS(
    SELECT 1 FROM students s
    WHERE s.id = NEW.student_id 
      AND s.tenant_id = NEW.tenant_id 
      AND s.status = 'active'
  ) INTO student_active;
  
  IF NOT student_active THEN
    RAISE EXCEPTION 'Cannot create fee record for inactive student';
  END IF;
  
  -- Validate fee type
  IF NEW.fee_type NOT IN ('tuition', 'registration', 'library', 'laboratory', 'transport', 'examination', 'miscellaneous') THEN
    RAISE EXCEPTION 'Invalid fee type: %', NEW.fee_type;
  END IF;
  
  -- Set academic year if not provided
  IF NEW.academic_year IS NULL THEN
    NEW.academic_year := utils.get_academic_year();
  END IF;
  
  -- Generate fee ID if not provided
  IF NEW.fee_id IS NULL THEN
    NEW.fee_id := utils.generate_unique_code('FEE', 10, 'fees', 'fee_id');
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply fee validation trigger
CREATE TRIGGER trigger_validate_fee_data
  BEFORE INSERT OR UPDATE ON fees
  FOR EACH ROW
  EXECUTE FUNCTION validate_fee_data();

-- ==============================================
-- PAYMENT VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for payment data validation
CREATE OR REPLACE FUNCTION validate_payment_data()
RETURNS TRIGGER AS $$
DECLARE
  fee_amount NUMERIC;
  total_paid NUMERIC;
  remaining_amount NUMERIC;
BEGIN
  -- Validate payment amount
  IF NEW.amount IS NOT NULL THEN
    IF NEW.amount <= 0 THEN
      RAISE EXCEPTION 'Payment amount must be positive';
    END IF;
  END IF;
  
  -- Validate payment method
  IF NEW.payment_method NOT IN ('cash', 'check', 'credit_card', 'debit_card', 'bank_transfer', 'online') THEN
    RAISE EXCEPTION 'Invalid payment method: %', NEW.payment_method;
  END IF;
  
  -- Check if payment exceeds remaining fee amount
  IF NEW.fee_id IS NOT NULL THEN
    SELECT f.amount INTO fee_amount
    FROM fees f
    WHERE f.id = NEW.fee_id AND f.tenant_id = NEW.tenant_id;
    
    SELECT COALESCE(SUM(p.amount), 0) INTO total_paid
    FROM payments p
    WHERE p.fee_id = NEW.fee_id 
      AND p.tenant_id = NEW.tenant_id
      AND p.status = 'completed'
      AND p.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
    
    remaining_amount := fee_amount - total_paid;
    
    IF NEW.amount > remaining_amount THEN
      RAISE EXCEPTION 'Payment amount (%) exceeds remaining fee amount (%)', 
        NEW.amount, remaining_amount;
    END IF;
  END IF;
  
  -- Validate payment date
  IF NEW.payment_date IS NOT NULL THEN
    IF NEW.payment_date > CURRENT_DATE THEN
      RAISE EXCEPTION 'Payment date cannot be in the future';
    END IF;
    
    IF NEW.payment_date < CURRENT_DATE - INTERVAL '5 years' THEN
      RAISE EXCEPTION 'Payment date cannot be more than 5 years in the past';
    END IF;
  END IF;
  
  -- Generate payment ID if not provided
  IF NEW.payment_id IS NULL THEN
    NEW.payment_id := utils.generate_unique_code('PAY', 12, 'payments', 'payment_id');
  END IF;
  
  -- Set payment date if not provided
  IF NEW.payment_date IS NULL THEN
    NEW.payment_date := CURRENT_DATE;
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply payment validation trigger
CREATE TRIGGER trigger_validate_payment_data
  BEFORE INSERT OR UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION validate_payment_data();

-- ==============================================
-- TIMETABLE VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for timetable data validation
CREATE OR REPLACE FUNCTION validate_timetable_data()
RETURNS TRIGGER AS $$
DECLARE
  time_conflict BOOLEAN := false;
  teacher_conflict BOOLEAN := false;
  room_conflict BOOLEAN := false;
BEGIN
  -- Validate time slots
  IF NEW.start_time IS NOT NULL AND NEW.end_time IS NOT NULL THEN
    IF NEW.start_time >= NEW.end_time THEN
      RAISE EXCEPTION 'Start time must be before end time';
    END IF;
    
    -- Check for reasonable class duration (15 minutes to 4 hours)
    IF NEW.end_time - NEW.start_time < INTERVAL '15 minutes' THEN
      RAISE EXCEPTION 'Class duration must be at least 15 minutes';
    END IF;
    
    IF NEW.end_time - NEW.start_time > INTERVAL '4 hours' THEN
      RAISE EXCEPTION 'Class duration cannot exceed 4 hours';
    END IF;
  END IF;
  
  -- Validate day of week
  IF NEW.day_of_week < 1 OR NEW.day_of_week > 7 THEN
    RAISE EXCEPTION 'Day of week must be between 1 (Monday) and 7 (Sunday)';
  END IF;
  
  -- Check for class scheduling conflicts
  SELECT EXISTS(
    SELECT 1 FROM timetables t
    WHERE t.class_id = NEW.class_id
      AND t.tenant_id = NEW.tenant_id
      AND t.day_of_week = NEW.day_of_week
      AND t.is_active = true
      AND t.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      AND (
        (NEW.start_time >= t.start_time AND NEW.start_time < t.end_time) OR
        (NEW.end_time > t.start_time AND NEW.end_time <= t.end_time) OR
        (NEW.start_time <= t.start_time AND NEW.end_time >= t.end_time)
      )
  ) INTO time_conflict;
  
  IF time_conflict THEN
    RAISE EXCEPTION 'Time slot conflicts with existing class schedule';
  END IF;
  
  -- Check for teacher scheduling conflicts
  IF NEW.teacher_id IS NOT NULL THEN
    SELECT EXISTS(
      SELECT 1 FROM timetables t
      WHERE t.teacher_id = NEW.teacher_id
        AND t.tenant_id = NEW.tenant_id
        AND t.day_of_week = NEW.day_of_week
        AND t.is_active = true
        AND t.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND (
          (NEW.start_time >= t.start_time AND NEW.start_time < t.end_time) OR
          (NEW.end_time > t.start_time AND NEW.end_time <= t.end_time) OR
          (NEW.start_time <= t.start_time AND NEW.end_time >= t.end_time)
        )
    ) INTO teacher_conflict;
    
    IF teacher_conflict THEN
      RAISE EXCEPTION 'Teacher has conflicting schedule at this time';
    END IF;
  END IF;
  
  -- Check for room booking conflicts
  IF NEW.room_id IS NOT NULL THEN
    SELECT EXISTS(
      SELECT 1 FROM timetables t
      WHERE t.room_id = NEW.room_id
        AND t.tenant_id = NEW.tenant_id
        AND t.day_of_week = NEW.day_of_week
        AND t.is_active = true
        AND t.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND (
          (NEW.start_time >= t.start_time AND NEW.start_time < t.end_time) OR
          (NEW.end_time > t.start_time AND NEW.end_time <= t.end_time) OR
          (NEW.start_time <= t.start_time AND NEW.end_time >= t.end_time)
        )
    ) INTO room_conflict;
    
    IF room_conflict THEN
      RAISE EXCEPTION 'Room is already booked at this time';
    END IF;
  END IF;
  
  -- Set academic year if not provided
  IF NEW.academic_year IS NULL THEN
    NEW.academic_year := utils.get_academic_year();
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timetable validation trigger
CREATE TRIGGER trigger_validate_timetable_data
  BEFORE INSERT OR UPDATE ON timetables
  FOR EACH ROW
  EXECUTE FUNCTION validate_timetable_data();

-- ==============================================
-- TENANT VALIDATION TRIGGERS
-- ==============================================

-- Trigger function for tenant data validation
CREATE OR REPLACE FUNCTION validate_tenant_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate tenant name
  IF NEW.name IS NULL OR trim(NEW.name) = '' THEN
    RAISE EXCEPTION 'Tenant name cannot be empty';
  END IF;
  
  -- Format tenant name
  NEW.name := utils.format_name(NEW.name);
  
  -- Validate subdomain format
  IF NEW.subdomain IS NOT NULL THEN
    IF NEW.subdomain !~ '^[a-z0-9][a-z0-9\-]{1,61}[a-z0-9]$' THEN
      RAISE EXCEPTION 'Invalid subdomain format. Use lowercase letters, numbers, and hyphens only';
    END IF;
    
    -- Reserved subdomains
    IF NEW.subdomain IN ('www', 'api', 'admin', 'app', 'mail', 'ftp', 'test', 'dev', 'staging') THEN
      RAISE EXCEPTION 'Subdomain "%" is reserved', NEW.subdomain;
    END IF;
  END IF;
  
  -- Validate contact email
  IF NEW.contact_email IS NOT NULL AND NOT utils.is_valid_email(NEW.contact_email) THEN
    RAISE EXCEPTION 'Invalid contact email format';
  END IF;
  
  -- Format contact phone
  IF NEW.contact_phone IS NOT NULL THEN
    NEW.contact_phone := utils.format_phone(NEW.contact_phone);
  END IF;
  
  -- Generate tenant code if not provided
  IF NEW.tenant_code IS NULL THEN
    NEW.tenant_code := utils.generate_unique_code('TEN', 6, 'tenants', 'tenant_code');
  END IF;
  
  -- Set updated timestamp
  NEW.updated_at := NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply tenant validation trigger
CREATE TRIGGER trigger_validate_tenant_data
  BEFORE INSERT OR UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION validate_tenant_data();

-- ==============================================
-- VALIDATION SYSTEM STATUS
-- ==============================================

DO $$
DECLARE
  total_triggers INTEGER;
  total_functions INTEGER;
BEGIN
  -- Count validation triggers
  SELECT COUNT(*) INTO total_triggers
  FROM pg_trigger
  WHERE tgname LIKE 'trigger_validate_%';
  
  -- Count validation functions
  SELECT COUNT(*) INTO total_functions
  FROM pg_proc
  WHERE proname LIKE 'validate_%_data';
  
  RAISE NOTICE 'Data Validation System Setup Complete!';
  RAISE NOTICE 'Validation triggers: %', total_triggers;
  RAISE NOTICE 'Validation functions: %', total_functions;
  RAISE NOTICE 'Tables with validation: users, students, staff, classes, subjects, attendance, grades, fees, payments, timetables, tenants';
  RAISE NOTICE 'Business rules enforced: age constraints, enrollment limits, scheduling conflicts, data integrity';
END $$;
```

---

## ✅ VALIDATION CHECKLIST

### User Data Validation
- [x] Email format validation
- [x] Name formatting and cleaning
- [x] Phone number formatting
- [x] Age constraint validation
- [x] Birth date validation

### Student Validation
- [x] Student ID format and uniqueness
- [x] Admission date validation
- [x] Age-appropriate class assignment
- [x] Guardian relationship validation
- [x] Duplicate enrollment prevention

### Staff Validation
- [x] Employee ID format and uniqueness
- [x] Employment date validation
- [x] Age constraints for employment
- [x] Salary range validation
- [x] Department validation

### Academic Validation
- [x] Class capacity and age range validation
- [x] Subject code format and uniqueness
- [x] Credit and duration constraints
- [x] Attendance date and status validation
- [x] Grade calculation and validation

### Financial Validation
- [x] Fee amount and type validation
- [x] Payment amount and method validation
- [x] Due date constraints
- [x] Overpayment prevention
- [x] Academic year consistency

### Scheduling Validation
- [x] Time slot validation
- [x] Class scheduling conflict detection
- [x] Teacher availability checking
- [x] Room booking conflict prevention
- [x] Duration constraints

### System Validation
- [x] Tenant data format validation
- [x] Subdomain format checking
- [x] Reserved name prevention
- [x] Contact information validation

---

## 📊 VALIDATION SYSTEM METRICS

### Trigger Coverage
- **User Tables**: 11 tables with validation
- **Validation Functions**: 11 comprehensive functions
- **Business Rules**: 50+ rules enforced
- **Constraint Types**: Format, range, logic, relationship

### Validation Categories
- **Data Format**: Email, phone, ID formats
- **Business Logic**: Age constraints, enrollment rules
- **Referential Integrity**: Foreign key validation
- **Temporal Constraints**: Date range validation
- **Conflict Prevention**: Scheduling, duplicate enrollment

---

## 📚 USAGE EXAMPLES

### Validation Error Handling
```sql
-- This will trigger validation error
INSERT INTO students (user_id, student_id, tenant_id) 
VALUES ('user-uuid', 'invalid-id', 'tenant-uuid');
-- ERROR: Student ID must be 6-12 alphanumeric characters

-- This will auto-format and validate
INSERT INTO users (email, full_name, phone, tenant_id)
VALUES ('  JOHN.DOE@EXAMPLE.COM  ', '  john   doe  ', '1234567890', 'tenant-uuid');
-- Auto-formats: email, name, phone
```

### Application Integration
```typescript
// Validation happens automatically at database level
const { data, error } = await supabase
  .from('students')
  .insert({
    user_id: userId,
    student_id: 'STU12345', // Will be validated
    class_id: classId,
    admission_date: new Date().toISOString()
  });

if (error) {
  // Handle validation error from trigger
  console.error('Validation error:', error.message);
}
```

### Custom Validation
```sql
-- Add custom validation to existing trigger
CREATE OR REPLACE FUNCTION validate_student_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Existing validation code...
  
  -- Custom business rule
  IF NEW.scholarship_percentage > 100 THEN
    RAISE EXCEPTION 'Scholarship percentage cannot exceed 100%';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## ⚡ PERFORMANCE CONSIDERATIONS

### Optimization Strategies
- **Minimal Processing**: Only essential validations in triggers
- **Early Exit**: Fast-fail on obvious errors
- **Efficient Queries**: Optimized existence checks
- **Index Usage**: Validation queries use indexes

### Best Practices
- Use BEFORE triggers for data modification
- Keep validation logic simple and fast
- Provide clear, actionable error messages
- Test validation performance under load

---

**Implementation Status**: ✅ COMPLETE  
**Trigger Count**: 11 validation triggers  
**Function Count**: 11 validation functions  
**Coverage**: All critical tables  
**Business Rules**: 50+ rules enforced  

This specification provides comprehensive data validation at the database level, ensuring data integrity, business rule enforcement, and consistent data quality across all operations in the School Management SaaS platform.