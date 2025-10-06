-- ==============================================
-- DEMO USERS SEED DATA
-- File: test-users.sql
-- Created: October 4, 2025
-- Description: Sample user data for demo tenants (all user types)
-- ==============================================

-- Note: This file creates demo users for testing purposes
-- Passwords will be handled by Supabase Auth system
-- This creates the profile data that extends auth.users

-- ==============================================
-- DEMO USERS FOR SUNSHINE INTERNATIONAL SCHOOL
-- ==============================================

DO $$
DECLARE
  sunshine_tenant_id UUID;
  main_branch_id UUID;
  noida_branch_id UUID;
  current_year_id UUID;
  class_1a_id UUID;
  class_2a_id UUID;
  class_6a_id UUID;
  class_9a_id UUID;
  section_1a_id UUID;
  section_2a_id UUID;
  section_6a_id UUID;
  section_9a_id UUID;
  
  -- User IDs (would be created by Supabase Auth in real scenario)
  admin_user_id UUID := gen_random_uuid();
  principal_user_id UUID := gen_random_uuid();
  teacher1_user_id UUID := gen_random_uuid();
  teacher2_user_id UUID := gen_random_uuid();
  teacher3_user_id UUID := gen_random_uuid();
  student1_user_id UUID := gen_random_uuid();
  student2_user_id UUID := gen_random_uuid();
  student3_user_id UUID := gen_random_uuid();
  student4_user_id UUID := gen_random_uuid();
  parent1_user_id UUID := gen_random_uuid();
  parent2_user_id UUID := gen_random_uuid();
  staff1_user_id UUID := gen_random_uuid();
  staff2_user_id UUID := gen_random_uuid();
BEGIN
  -- Get Sunshine International School IDs
  SELECT id INTO sunshine_tenant_id FROM tenants WHERE slug = 'sunshine-international';
  SELECT id INTO main_branch_id FROM branches WHERE tenant_id = sunshine_tenant_id AND code = 'SIS-MAIN';
  SELECT id INTO noida_branch_id FROM branches WHERE tenant_id = sunshine_tenant_id AND code = 'SIS-NOIDA';
  SELECT id INTO current_year_id FROM academic_years WHERE tenant_id = sunshine_tenant_id AND is_current = true LIMIT 1;
  
  -- Get class and section IDs
  SELECT c.id, s.id INTO class_1a_id, section_1a_id 
  FROM classes c JOIN sections s ON c.id = s.class_id 
  WHERE c.tenant_id = sunshine_tenant_id AND c.code = 'C1' AND s.name = 'A' LIMIT 1;
  
  SELECT c.id, s.id INTO class_2a_id, section_2a_id 
  FROM classes c JOIN sections s ON c.id = s.class_id 
  WHERE c.tenant_id = sunshine_tenant_id AND c.code = 'C2' AND s.name = 'A' LIMIT 1;
  
  SELECT c.id, s.id INTO class_6a_id, section_6a_id 
  FROM classes c JOIN sections s ON c.id = s.class_id 
  WHERE c.tenant_id = sunshine_tenant_id AND c.code = 'C6' AND s.name = 'A' LIMIT 1;
  
  SELECT c.id, s.id INTO class_9a_id, section_9a_id 
  FROM classes c JOIN sections s ON c.id = s.class_id 
  WHERE c.tenant_id = sunshine_tenant_id AND c.code = 'C9' AND s.name = 'A' LIMIT 1;

  -- ==============================================
  -- ADMIN USERS
  -- ==============================================
  
  -- Super Admin
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role, secondary_roles,
    permissions, status, email_verified_at, joined_at
  ) VALUES (
    admin_user_id, sunshine_tenant_id, main_branch_id,
    'Arjun', 'Sharma', 'admin@sunshineintl.edu', '+91-11-45678901',
    'SIS-EMP-001', '1985-03-15', 'male', 'admin',
    '["principal", "teacher", "staff"]',
    '["all"]',
    'active', NOW(), NOW() - INTERVAL '6 months'
  );
  
  -- ==============================================
  -- PRINCIPAL
  -- ==============================================
  
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    principal_user_id, sunshine_tenant_id, main_branch_id,
    'Priya', 'Sharma', 'principal.main@sunshineintl.edu', '+91-11-45678902',
    'SIS-EMP-002', '1978-07-22', 'female', 'principal',
    'active', NOW(), NOW() - INTERVAL '6 months'
  );
  
  -- ==============================================
  -- TEACHERS
  -- ==============================================
  
  -- Math Teacher
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, middle_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    teacher1_user_id, sunshine_tenant_id, main_branch_id,
    'Rajesh', 'Kumar', 'Singh', 'rajesh.kumar@sunshineintl.edu', '+91-11-45678903',
    'SIS-EMP-003', '1982-11-30', 'male', 'teacher',
    'active', NOW(), NOW() - INTERVAL '5 months'
  );
  
  -- English Teacher
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    teacher2_user_id, sunshine_tenant_id, main_branch_id,
    'Meera', 'Gupta', 'meera.gupta@sunshineintl.edu', '+91-11-45678904',
    'SIS-EMP-004', '1987-05-18', 'female', 'teacher',
    'active', NOW(), NOW() - INTERVAL '4 months'
  );
  
  -- Science Teacher (Noida Branch)
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    teacher3_user_id, sunshine_tenant_id, noida_branch_id,
    'Suresh', 'Patel', 'suresh.patel@sunshineintl.edu', '+91-120-98765434',
    'SIS-EMP-005', '1984-09-12', 'male', 'teacher',
    'active', NOW(), NOW() - INTERVAL '3 months'
  );
  
  -- ==============================================
  -- STUDENTS
  -- ==============================================
  
  -- Student 1 - Class 1A
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    student_id, admission_number, date_of_birth, gender, blood_group,
    primary_role, status, joined_at
  ) VALUES (
    student1_user_id, sunshine_tenant_id, main_branch_id,
    'Aarav', 'Agarwal', 'aarav.agarwal@student.sunshineintl.edu', NULL,
    'SIS-STU-001', 'SIS-2024-001', '2017-04-10', 'male', 'B+',
    'student', 'active', NOW() - INTERVAL '6 months'
  );
  
  -- Student 2 - Class 2A  
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    student_id, admission_number, date_of_birth, gender, blood_group,
    primary_role, status, joined_at
  ) VALUES (
    student2_user_id, sunshine_tenant_id, main_branch_id,
    'Ananya', 'Sharma', 'ananya.sharma@student.sunshineintl.edu', NULL,
    'SIS-STU-002', 'SIS-2024-002', '2016-08-25', 'female', 'A+',
    'student', 'active', NOW() - INTERVAL '6 months'
  );
  
  -- Student 3 - Class 6A
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    student_id, admission_number, date_of_birth, gender, blood_group,
    primary_role, status, joined_at
  ) VALUES (
    student3_user_id, sunshine_tenant_id, main_branch_id,
    'Ishaan', 'Verma', 'ishaan.verma@student.sunshineintl.edu', '+91-98765-43211',
    'SIS-STU-003', 'SIS-2024-003', '2012-12-03', 'male', 'O+',
    'student', 'active', NOW() - INTERVAL '6 months'
  );
  
  -- Student 4 - Class 9A
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    student_id, admission_number, date_of_birth, gender, blood_group,
    primary_role, status, joined_at
  ) VALUES (
    student4_user_id, sunshine_tenant_id, main_branch_id,
    'Kavya', 'Singh', 'kavya.singh@student.sunshineintl.edu', '+91-98765-43212',
    'SIS-STU-004', 'SIS-2024-004', '2009-06-15', 'female', 'AB+',
    'student', 'active', NOW() - INTERVAL '6 months'
  );
  
  -- ==============================================
  -- PARENTS
  -- ==============================================
  
  -- Parent 1 (Father of Aarav)
  INSERT INTO users (
    id, tenant_id, first_name, last_name, email, phone,
    date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    parent1_user_id, sunshine_tenant_id,
    'Vikash', 'Agarwal', 'vikash.agarwal@gmail.com', '+91-98765-11111',
    '1985-01-20', 'male', 'parent',
    'active', NOW(), NOW() - INTERVAL '6 months'
  );
  
  -- Parent 2 (Mother of Ananya)
  INSERT INTO users (
    id, tenant_id, first_name, last_name, email, phone,
    date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    parent2_user_id, sunshine_tenant_id,
    'Deepika', 'Sharma', 'deepika.sharma@yahoo.com', '+91-98765-22222',
    '1987-09-12', 'female', 'parent',
    'active', NOW(), NOW() - INTERVAL '6 months'
  );
  
  -- ==============================================
  -- SUPPORT STAFF
  -- ==============================================
  
  -- Librarian
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    staff1_user_id, sunshine_tenant_id, main_branch_id,
    'Sunita', 'Rao', 'sunita.rao@sunshineintl.edu', '+91-11-45678905',
    'SIS-EMP-006', '1975-03-08', 'female', 'staff',
    'active', NOW(), NOW() - INTERVAL '4 months'
  );
  
  -- Accountant
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    staff2_user_id, sunshine_tenant_id, main_branch_id,
    'Ramesh', 'Chand', 'ramesh.chand@sunshineintl.edu', '+91-11-45678906',
    'SIS-EMP-007', '1980-11-22', 'male', 'staff',
    'active', NOW(), NOW() - INTERVAL '2 months'
  );
  
  -- ==============================================
  -- STUDENT RECORDS
  -- ==============================================
  
  -- Create student records
  INSERT INTO students (
    tenant_id, user_id, branch_id, admission_number, roll_number,
    class_id, section_id, academic_year_id, admission_date, admission_type,
    fee_category, transport_required, status
  ) VALUES 
  (sunshine_tenant_id, student1_user_id, main_branch_id, 'SIS-2024-001', '001', 
   class_1a_id, section_1a_id, current_year_id, '2024-04-01', 'fresh',
   'regular', false, 'active'),
  (sunshine_tenant_id, student2_user_id, main_branch_id, 'SIS-2024-002', '002', 
   class_2a_id, section_2a_id, current_year_id, '2024-04-01', 'fresh',
   'regular', true, 'active'),
  (sunshine_tenant_id, student3_user_id, main_branch_id, 'SIS-2024-003', '003', 
   class_6a_id, section_6a_id, current_year_id, '2024-04-01', 'transfer',
   'regular', true, 'active'),
  (sunshine_tenant_id, student4_user_id, main_branch_id, 'SIS-2024-004', '004', 
   class_9a_id, section_9a_id, current_year_id, '2024-04-01', 'fresh',
   'scholarship', false, 'active');
  
  -- ==============================================
  -- GUARDIAN RECORDS
  -- ==============================================
  
  -- Create guardian records
  INSERT INTO guardians (
    tenant_id, user_id, first_name, last_name, email, phone,
    date_of_birth, gender, occupation, organization, annual_income,
    status
  ) VALUES 
  (sunshine_tenant_id, parent1_user_id, 'Vikash', 'Agarwal', 'vikash.agarwal@gmail.com', '+91-98765-11111',
   '1985-01-20', 'male', 'Software Engineer', 'TechCorp India', 1200000, 'active'),
  (sunshine_tenant_id, NULL, 'Priya', 'Agarwal', 'priya.agarwal@gmail.com', '+91-98765-11112',
   '1987-05-15', 'female', 'Teacher', 'Delhi Public School', 800000, 'active'),
  (sunshine_tenant_id, parent2_user_id, 'Deepika', 'Sharma', 'deepika.sharma@yahoo.com', '+91-98765-22222',
   '1987-09-12', 'female', 'Doctor', 'AIIMS Delhi', 1500000, 'active'),
  (sunshine_tenant_id, NULL, 'Rohit', 'Sharma', 'rohit.sharma@gmail.com', '+91-98765-22223',
   '1985-03-25', 'male', 'Business Owner', 'Sharma Enterprises', 2000000, 'active');
  
  -- Link students to guardians
  INSERT INTO student_guardians (
    tenant_id, student_id, guardian_id, relationship, is_primary, 
    is_emergency_contact, is_fee_payer, financial_responsibility_percentage
  )
  SELECT 
    sunshine_tenant_id,
    s.id,
    g.id,
    CASE 
      WHEN g.first_name = 'Vikash' THEN 'father'
      WHEN g.first_name = 'Priya' THEN 'mother'
      WHEN g.first_name = 'Deepika' THEN 'mother'
      WHEN g.first_name = 'Rohit' THEN 'father'
    END,
    CASE 
      WHEN g.first_name IN ('Vikash', 'Deepika') THEN true
      ELSE false
    END,
    true,
    CASE 
      WHEN g.first_name IN ('Vikash', 'Rohit') THEN true
      ELSE false
    END,
    CASE 
      WHEN g.first_name IN ('Vikash', 'Deepika') THEN 60
      ELSE 40
    END
  FROM students s, guardians g
  WHERE s.tenant_id = sunshine_tenant_id 
    AND g.tenant_id = sunshine_tenant_id
    AND (
      (s.admission_number = 'SIS-2024-001' AND g.last_name = 'Agarwal') OR
      (s.admission_number = 'SIS-2024-002' AND g.last_name = 'Sharma')
    );
  
  -- ==============================================
  -- USER ROLES
  -- ==============================================
  
  -- Assign roles to users
  INSERT INTO user_roles (tenant_id, user_id, role, role_type, scope, granted_by) VALUES
  (sunshine_tenant_id, admin_user_id, 'super_admin', 'system', 'tenant', admin_user_id),
  (sunshine_tenant_id, principal_user_id, 'principal', 'system', 'branch', admin_user_id),
  (sunshine_tenant_id, teacher1_user_id, 'mathematics_teacher', 'academic', 'branch', principal_user_id),
  (sunshine_tenant_id, teacher1_user_id, 'class_teacher', 'academic', 'section', principal_user_id),
  (sunshine_tenant_id, teacher2_user_id, 'english_teacher', 'academic', 'branch', principal_user_id),
  (sunshine_tenant_id, teacher3_user_id, 'science_teacher', 'academic', 'branch', principal_user_id),
  (sunshine_tenant_id, staff1_user_id, 'librarian', 'operational', 'branch', principal_user_id),
  (sunshine_tenant_id, staff2_user_id, 'accountant', 'operational', 'branch', principal_user_id);
  
  -- Update section class teachers
  UPDATE sections SET class_teacher_id = teacher1_user_id 
  WHERE id = section_1a_id;
  
  UPDATE sections SET class_teacher_id = teacher2_user_id 
  WHERE id = section_2a_id;
  
END $$;

-- ==============================================
-- DEMO USERS FOR GREEN VALLEY PUBLIC SCHOOL
-- ==============================================

DO $$
DECLARE
  greenvalley_tenant_id UUID;
  main_branch_id UUID;
  current_year_id UUID;
  
  admin_user_id UUID := gen_random_uuid();
  principal_user_id UUID := gen_random_uuid();
  teacher1_user_id UUID := gen_random_uuid();
  student1_user_id UUID := gen_random_uuid();
  student2_user_id UUID := gen_random_uuid();
  parent1_user_id UUID := gen_random_uuid();
BEGIN
  -- Get Green Valley Public School IDs
  SELECT id INTO greenvalley_tenant_id FROM tenants WHERE slug = 'green-valley-public';
  SELECT id INTO main_branch_id FROM branches WHERE tenant_id = greenvalley_tenant_id LIMIT 1;
  SELECT id INTO current_year_id FROM academic_years WHERE tenant_id = greenvalley_tenant_id AND is_current = true LIMIT 1;
  
  -- Admin
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    admin_user_id, greenvalley_tenant_id, main_branch_id,
    'Rajesh', 'Kumar', 'admin@greenvalley.edu.in', '+91-80-98765433',
    'GVPS-EMP-001', '1980-05-12', 'male', 'admin',
    'active', NOW(), NOW() - INTERVAL '3 months'
  );
  
  -- Principal (same as admin in this small school)
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    principal_user_id, greenvalley_tenant_id, main_branch_id,
    'Rajesh', 'Kumar', 'principal@greenvalley.edu.in', '+91-80-98765432',
    'GVPS-EMP-001', '1980-05-12', 'male', 'principal',
    'active', NOW(), NOW() - INTERVAL '3 months'
  );
  
  -- Teacher
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    teacher1_user_id, greenvalley_tenant_id, main_branch_id,
    'Lakshmi', 'Devi', 'lakshmi.devi@greenvalley.edu.in', '+91-80-98765434',
    'GVPS-EMP-002', '1985-08-20', 'female', 'teacher',
    'active', NOW(), NOW() - INTERVAL '2 months'
  );
  
  -- Students
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email,
    student_id, admission_number, date_of_birth, gender, blood_group,
    primary_role, status, joined_at
  ) VALUES 
  (student1_user_id, greenvalley_tenant_id, main_branch_id,
   'Kiran', 'Raj', 'kiran.raj@student.greenvalley.edu.in',
   'GVPS-STU-001', 'GVPS-2024-001', '2016-07-15', 'male', 'B+',
   'student', 'active', NOW() - INTERVAL '3 months'),
  (student2_user_id, greenvalley_tenant_id, main_branch_id,
   'Sneha', 'Kumari', 'sneha.kumari@student.greenvalley.edu.in',
   'GVPS-STU-002', 'GVPS-2024-002', '2015-11-30', 'female', 'A+',
   'student', 'active', NOW() - INTERVAL '3 months');
  
  -- Parent
  INSERT INTO users (
    id, tenant_id, first_name, last_name, email, phone,
    date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    parent1_user_id, greenvalley_tenant_id,
    'Suresh', 'Raj', 'suresh.raj@gmail.com', '+91-98765-33333',
    '1982-12-10', 'male', 'parent',
    'active', NOW(), NOW() - INTERVAL '3 months'
  );
  
END $$;

-- ==============================================
-- DEMO USERS FOR ELITE ACADEMY (ENTERPRISE)
-- ==============================================

DO $$
DECLARE
  elite_tenant_id UUID;
  main_branch_id UUID;
  
  admin_user_id UUID := gen_random_uuid();
  principal_user_id UUID := gen_random_uuid();
  teacher1_user_id UUID := gen_random_uuid();
  teacher2_user_id UUID := gen_random_uuid();
  student1_user_id UUID := gen_random_uuid();
  student2_user_id UUID := gen_random_uuid();
  student3_user_id UUID := gen_random_uuid();
  parent1_user_id UUID := gen_random_uuid();
  staff1_user_id UUID := gen_random_uuid();
BEGIN
  -- Get Elite Academy IDs
  SELECT id INTO elite_tenant_id FROM tenants WHERE slug = 'elite-academy';
  SELECT id INTO main_branch_id FROM branches WHERE tenant_id = elite_tenant_id AND is_main_branch = true;
  
  -- System Administrator
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role, secondary_roles,
    status, email_verified_at, joined_at
  ) VALUES (
    admin_user_id, elite_tenant_id, main_branch_id,
    'Vikram', 'Mehta', 'admin@eliteacademy.edu', '+91-22-67890125',
    'EA-EMP-001', '1975-12-05', 'male', 'admin', '["principal"]',
    'active', NOW(), NOW() - INTERVAL '1 year'
  );
  
  -- Principal
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    principal_user_id, elite_tenant_id, main_branch_id,
    'Anjali', 'Mehta', 'principal@eliteacademy.edu', '+91-22-67890124',
    'EA-EMP-002', '1970-06-18', 'female', 'principal',
    'active', NOW(), NOW() - INTERVAL '1 year'
  );
  
  -- Senior Teachers
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES 
  (teacher1_user_id, elite_tenant_id, main_branch_id,
   'Dr. Ravi', 'Shankar', 'ravi.shankar@eliteacademy.edu', '+91-22-67890126',
   'EA-EMP-003', '1978-04-22', 'male', 'teacher',
   'active', NOW(), NOW() - INTERVAL '8 months'),
  (teacher2_user_id, elite_tenant_id, main_branch_id,
   'Prof. Sita', 'Devi', 'sita.devi@eliteacademy.edu', '+91-22-67890127',
   'EA-EMP-004', '1975-09-15', 'female', 'teacher',
   'active', NOW(), NOW() - INTERVAL '10 months');
  
  -- Premium Students
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    student_id, admission_number, date_of_birth, gender, blood_group,
    primary_role, status, joined_at
  ) VALUES 
  (student1_user_id, elite_tenant_id, main_branch_id,
   'Aarush', 'Kapoor', 'aarush.kapoor@student.eliteacademy.edu', '+91-98765-44444',
   'EA-STU-001', 'EA-2024-001', '2010-02-28', 'male', 'O+',
   'student', 'active', NOW() - INTERVAL '1 year'),
  (student2_user_id, elite_tenant_id, main_branch_id,
   'Aisha', 'Shah', 'aisha.shah@student.eliteacademy.edu', '+91-98765-44445',
   'EA-STU-002', 'EA-2024-002', '2011-10-12', 'female', 'A+',
   'student', 'active', NOW() - INTERVAL '1 year'),
  (student3_user_id, elite_tenant_id, main_branch_id,
   'Arjun', 'Singhania', 'arjun.singhania@student.eliteacademy.edu', '+91-98765-44446',
   'EA-STU-003', 'EA-2024-003', '2008-07-08', 'male', 'B+',
   'student', 'active', NOW() - INTERVAL '1 year');
  
  -- Premium Parent
  INSERT INTO users (
    id, tenant_id, first_name, last_name, email, phone,
    date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    parent1_user_id, elite_tenant_id,
    'Rajat', 'Kapoor', 'rajat.kapoor@kapoorcorp.com', '+91-98765-55555',
    '1980-01-15', 'male', 'parent',
    'active', NOW(), NOW() - INTERVAL '1 year'
  );
  
  -- Senior Staff
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    staff1_user_id, elite_tenant_id, main_branch_id,
    'Mohan', 'Lal', 'mohan.lal@eliteacademy.edu', '+91-22-67890128',
    'EA-EMP-005', '1972-08-30', 'male', 'staff',
    'active', NOW(), NOW() - INTERVAL '6 months'
  );
  
END $$;

-- ==============================================
-- DEMO USERS FOR LITTLE STARS MONTESSORI
-- ==============================================

DO $$
DECLARE
  littlestars_tenant_id UUID;
  main_branch_id UUID;
  
  admin_user_id UUID := gen_random_uuid();
  teacher1_user_id UUID := gen_random_uuid();
  student1_user_id UUID := gen_random_uuid();
  parent1_user_id UUID := gen_random_uuid();
BEGIN
  -- Get Little Stars IDs
  SELECT id INTO littlestars_tenant_id FROM tenants WHERE slug = 'little-stars-montessori';
  SELECT id INTO main_branch_id FROM branches WHERE tenant_id = littlestars_tenant_id LIMIT 1;
  
  -- Director (Admin + Principal)
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role, secondary_roles,
    status, email_verified_at, joined_at
  ) VALUES (
    admin_user_id, littlestars_tenant_id, main_branch_id,
    'Sarah', 'Thomas', 'director@littlestars.edu', '+91-44-87654321',
    'LSM-EMP-001', '1985-04-25', 'female', 'admin', '["principal", "teacher"]',
    'active', NOW(), NOW() - INTERVAL '7 days'
  );
  
  -- Montessori Teacher
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name, email, phone,
    employee_id, date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    teacher1_user_id, littlestars_tenant_id, main_branch_id,
    'Radha', 'Krishnan', 'radha.krishnan@littlestars.edu', '+91-44-87654322',
    'LSM-EMP-002', '1990-11-10', 'female', 'teacher',
    'active', NOW(), NOW() - INTERVAL '5 days'
  );
  
  -- Young Student
  INSERT INTO users (
    id, tenant_id, branch_id, first_name, last_name,
    student_id, admission_number, date_of_birth, gender,
    primary_role, status, joined_at
  ) VALUES (
    student1_user_id, littlestars_tenant_id, main_branch_id,
    'Arya', 'Menon', 
    'LSM-STU-001', 'LSM-2024-001', '2020-03-18', 'female',
    'student', 'active', NOW() - INTERVAL '7 days'
  );
  
  -- Parent
  INSERT INTO users (
    id, tenant_id, first_name, last_name, email, phone,
    date_of_birth, gender, primary_role,
    status, email_verified_at, joined_at
  ) VALUES (
    parent1_user_id, littlestars_tenant_id,
    'Pradeep', 'Menon', 'pradeep.menon@techstart.com', '+91-98765-66666',
    '1988-07-22', 'male', 'parent',
    'active', NOW(), NOW() - INTERVAL '7 days'
  );
  
END $$;

-- ==============================================
-- CREATE SAMPLE USER SESSIONS (RECENT ACTIVITY)
-- ==============================================

-- Create recent login sessions for active users
INSERT INTO user_sessions (
  tenant_id, user_id, session_token, device_info, ip_address, 
  user_agent, started_at, last_activity_at, is_active
)
SELECT 
  u.tenant_id,
  u.id,
  'demo_session_' || u.id::text,
  '{"device": "Desktop", "os": "Windows 11", "browser": "Chrome"}',
  '192.168.1.' || (RANDOM() * 254 + 1)::INTEGER,
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  NOW() - INTERVAL '2 hours',
  NOW() - INTERVAL '15 minutes',
  CASE WHEN RANDOM() < 0.7 THEN true ELSE false END
FROM users u
WHERE u.primary_role IN ('admin', 'principal', 'teacher')
  AND u.status = 'active'
LIMIT 20;

-- ==============================================
-- SET USER PREFERENCES
-- ==============================================

-- Set common user preferences
INSERT INTO user_preferences (tenant_id, user_id, category, key, value, data_type)
SELECT 
  u.tenant_id,
  u.id,
  'ui',
  'theme',
  '"light"',
  'string'
FROM users u
WHERE u.status = 'active'
UNION ALL
SELECT 
  u.tenant_id,
  u.id,
  'ui',
  'language',
  '"en"',
  'string'
FROM users u
WHERE u.status = 'active'
UNION ALL
SELECT 
  u.tenant_id,
  u.id,
  'notifications',
  'email_enabled',
  'true',
  'boolean'
FROM users u
WHERE u.status = 'active';

-- ==============================================
-- UPDATE TENANT STATISTICS
-- ==============================================

-- Update tenant user counts
UPDATE tenants SET 
  current_students = (
    SELECT COUNT(*) FROM users 
    WHERE tenant_id = tenants.id AND primary_role = 'student' AND status = 'active'
  ),
  current_staff = (
    SELECT COUNT(*) FROM users 
    WHERE tenant_id = tenants.id AND primary_role IN ('admin', 'principal', 'teacher', 'staff') AND status = 'active'
  )
WHERE id IN (
  SELECT DISTINCT tenant_id FROM users WHERE settings IS NULL OR settings->>'demo_data' != 'false'
);

-- ==============================================
-- SUMMARY REPORT
-- ==============================================

-- Display user creation summary
SELECT 
  'Demo users created successfully!' as status,
  COUNT(*) as total_users,
  COUNT(*) FILTER (WHERE primary_role = 'admin') as admins,
  COUNT(*) FILTER (WHERE primary_role = 'principal') as principals,  
  COUNT(*) FILTER (WHERE primary_role = 'teacher') as teachers,
  COUNT(*) FILTER (WHERE primary_role = 'student') as students,
  COUNT(*) FILTER (WHERE primary_role = 'parent') as parents,
  COUNT(*) FILTER (WHERE primary_role = 'staff') as staff
FROM users u
JOIN tenants t ON u.tenant_id = t.id
WHERE t.settings->>'demo_data' = 'true';

-- Display tenant-wise user distribution
SELECT 
  t.name as tenant_name,
  COUNT(*) FILTER (WHERE u.primary_role = 'admin') as admins,
  COUNT(*) FILTER (WHERE u.primary_role = 'principal') as principals,
  COUNT(*) FILTER (WHERE u.primary_role = 'teacher') as teachers,
  COUNT(*) FILTER (WHERE u.primary_role = 'student') as students,
  COUNT(*) FILTER (WHERE u.primary_role = 'parent') as parents,
  COUNT(*) FILTER (WHERE u.primary_role = 'staff') as staff,
  COUNT(*) as total_users
FROM tenants t
LEFT JOIN users u ON t.id = u.tenant_id AND u.status = 'active'
WHERE t.settings->>'demo_data' = 'true'
GROUP BY t.id, t.name
ORDER BY t.name;