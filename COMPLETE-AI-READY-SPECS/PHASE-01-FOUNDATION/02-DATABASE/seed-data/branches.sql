-- ==============================================
-- DEMO BRANCHES SEED DATA
-- File: branches.sql
-- Created: October 4, 2025
-- Description: Sample branch data for demo tenants
-- ==============================================

-- ==============================================
-- BRANCHES FOR SUNSHINE INTERNATIONAL SCHOOL
-- ==============================================

DO $$
DECLARE
  sunshine_tenant_id UUID;
  branch_id UUID;
BEGIN
  -- Get Sunshine tenant ID
  SELECT id INTO sunshine_tenant_id FROM tenants WHERE slug = 'sunshine-international';
  
  -- Main Branch - Gurgaon Campus
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone, website,
    address_line1, address_line2, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), sunshine_tenant_id,
    'Sunshine International - Main Campus',
    'SIS-MAIN',
    'Sunshine International School - Main Campus, Gurgaon',
    'school',
    'main@sunshineintl.edu',
    '+91-11-45678900',
    'https://sunshineintl.edu',
    'Sector 45, Educational Hub',
    'Near Metro Station',
    'Gurgaon', 'HR', 'IN', '122003',
    28.4595, 77.0266,
    4, 3,
    'CBSE',
    'CBSE/DEL/07/2018/12345',
    'Dr. Priya Sharma',
    'principal.main@sunshineintl.edu',
    '+91-11-45678901',
    24, 6, 5000, 2500.00,
    true, false,
    true, '2018-04-01', 'active'
  );
  
  -- Branch 2 - Noida Campus
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone,
    address_line1, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), sunshine_tenant_id,
    'Sunshine International - Noida Campus',
    'SIS-NOIDA',
    'Sunshine International School - Noida Campus',
    'school',
    'noida@sunshineintl.edu',
    '+91-120-98765432',
    'Plot 123, Sector 62',
    'Noida', 'UP', 'IN', '201301',
    28.6139, 77.3910,
    4, 3,
    'CBSE',
    'CBSE/UP/07/2019/67890',
    'Mr. Amit Gupta',
    'principal.noida@sunshineintl.edu',
    '+91-120-98765433',
    18, 4, 3000, 1800.00,
    true, false,
    false, '2019-04-01', 'active'
  );
END $$;

-- ==============================================
-- BRANCHES FOR GREEN VALLEY PUBLIC SCHOOL
-- ==============================================

DO $$
DECLARE
  greenvalley_tenant_id UUID;
BEGIN
  -- Get Green Valley tenant ID
  SELECT id INTO greenvalley_tenant_id FROM tenants WHERE slug = 'green-valley-public';
  
  -- Single Main Branch
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone, website,
    address_line1, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), greenvalley_tenant_id,
    'Green Valley Public School',
    'GVPS-MAIN',
    'Green Valley Public School - Whitefield Campus',
    'school',
    'principal@greenvalley.edu.in',
    '+91-80-98765432',
    'https://greenvalleypublic.edu.in',
    '123 Green Avenue, Whitefield',
    'Bangalore', 'KA', 'IN', '560066',
    12.9698, 77.7500,
    4, 3,
    'State Board',
    'KAR/BLR/2015/54321',
    'Mr. Rajesh Kumar',
    'principal@greenvalley.edu.in',
    '+91-80-98765432',
    15, 2, 2000, 1200.00,
    true, false,
    true, '2015-06-01', 'active'
  );
END $$;

-- ==============================================
-- BRANCHES FOR ELITE ACADEMY (MULTIPLE CAMPUSES)
-- ==============================================

DO $$
DECLARE
  elite_tenant_id UUID;
BEGIN
  -- Get Elite Academy tenant ID
  SELECT id INTO elite_tenant_id FROM tenants WHERE slug = 'elite-academy';
  
  -- Main Branch - Mumbai Bandra
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone, website,
    address_line1, address_line2, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), elite_tenant_id,
    'Elite Academy - Bandra Campus',
    'EA-BKC',
    'Elite Academy - Bandra Kurla Complex, Mumbai',
    'school',
    'bandra@eliteacademy.edu',
    '+91-22-67890123',
    'https://eliteacademy.edu',
    'Elite Education Complex, Bandra Kurla',
    'Corporate Park Road',
    'Mumbai', 'MH', 'IN', '400051',
    19.0596, 72.8656,
    4, 3,
    'CBSE',
    'CBSE/MH/05/2010/11111',
    'Dr. Anjali Mehta',
    'principal.bandra@eliteacademy.edu',
    '+91-22-67890124',
    30, 8, 8000, 3000.00,
    true, true,
    true, '2010-04-01', 'active'
  );
  
  -- Branch 2 - Pune Campus
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone,
    address_line1, address_line2, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), elite_tenant_id,
    'Elite Academy - Pune Campus',
    'EA-PUNE',
    'Elite Academy - Hinjewadi, Pune',
    'school',
    'pune@eliteacademy.edu',
    '+91-20-87654321',
    'Elite Square, Hinjewadi Phase 2',
    'IT Park Road',
    'Pune', 'MH', 'IN', '411057',
    18.5904, 73.7394,
    4, 3,
    'CBSE',
    'CBSE/MH/05/2012/22222',
    'Dr. Suresh Patil',
    'principal.pune@eliteacademy.edu',
    '+91-20-87654322',
    25, 6, 6000, 2200.00,
    true, false,
    false, '2012-04-01', 'active'
  );
  
  -- Branch 3 - Delhi Campus
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone,
    address_line1, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), elite_tenant_id,
    'Elite Academy - Delhi Campus',
    'EA-DEL',
    'Elite Academy - Vasant Kunj, Delhi',
    'school',
    'delhi@eliteacademy.edu',
    '+91-11-76543210',
    'C-4/5, Vasant Kunj',
    'New Delhi', 'DL', 'IN', '110070',
    28.5245, 77.1595,
    4, 3,
    'CBSE',
    'CBSE/DEL/05/2015/33333',
    'Ms. Kavita Singh',
    'principal.delhi@eliteacademy.edu',
    '+91-11-76543211',
    22, 5, 5000, 2000.00,
    true, false,
    false, '2015-04-01', 'active'
  );
  
  -- Branch 4 - Bangalore Campus
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone,
    address_line1, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), elite_tenant_id,
    'Elite Academy - Bangalore Campus',
    'EA-BLR',
    'Elite Academy - Electronic City, Bangalore',
    'school',
    'bangalore@eliteacademy.edu',
    '+91-80-65432109',
    'Electronic City Phase 1',
    'Bangalore', 'KA', 'IN', '560100',
    12.8456, 77.6603,
    4, 3,
    'CBSE',
    'CBSE/KAR/05/2017/44444',
    'Dr. Ramesh Rao',
    'principal.bangalore@eliteacademy.edu',
    '+91-80-65432110',
    28, 7, 7000, 2800.00,
    true, false,
    false, '2017-04-01', 'active'
  );
END $$;

-- ==============================================
-- BRANCHES FOR LITTLE STARS MONTESSORI
-- ==============================================

DO $$
DECLARE
  littlestars_tenant_id UUID;
BEGIN
  -- Get Little Stars tenant ID
  SELECT id INTO littlestars_tenant_id FROM tenants WHERE slug = 'little-stars-montessori';
  
  -- Single Main Branch
  INSERT INTO branches (
    id, tenant_id, name, code, display_name, type,
    email, phone,
    address_line1, city, state, country, postal_code,
    latitude, longitude,
    academic_year_start_month, academic_year_end_month,
    board_affiliation, recognition_number,
    principal_name, principal_email, principal_phone,
    total_classrooms, total_labs, library_capacity, playground_area,
    transport_available, hostel_available,
    is_main_branch, established_date, status
  ) VALUES (
    gen_random_uuid(), littlestars_tenant_id,
    'Little Stars Montessori School',
    'LSM-MAIN',
    'Little Stars Montessori - T. Nagar Campus',
    'preschool',
    'director@littlestars.edu',
    '+91-44-87654321',
    '456 Montessori Lane, T. Nagar',
    'Chennai', 'TN', 'IN', '600028',
    13.0407, 80.2341,
    6, 5,
    'Montessori',
    'TN/CHE/2020/55555',
    'Ms. Sarah Thomas',
    'director@littlestars.edu',
    '+91-44-87654321',
    8, 0, 500, 800.00,
    false, false,
    true, '2020-06-01', 'active'
  );
END $$;

-- ==============================================
-- ACADEMIC YEARS FOR ALL BRANCHES
-- ==============================================

-- Create academic years for all branches
DO $$
DECLARE
  branch_rec RECORD;
  current_year_id UUID;
  previous_year_id UUID;
  next_year_id UUID;
BEGIN
  FOR branch_rec IN 
    SELECT b.id as branch_id, b.tenant_id, b.name, b.academic_year_start_month
    FROM branches b
    WHERE b.status = 'active'
  LOOP
    -- Previous Academic Year (2023-24)
    previous_year_id := gen_random_uuid();
    INSERT INTO academic_years (
      id, tenant_id, branch_id, name, display_name,
      start_date, end_date, term_structure, total_terms,
      status, is_current
    ) VALUES (
      previous_year_id, branch_rec.tenant_id, branch_rec.branch_id,
      '2023-24', 'Academic Year 2023-2024',
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2023-04-01'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2023-06-01'
        ELSE DATE '2023-01-01'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-03-31'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-05-31'
        ELSE DATE '2023-12-31'
      END,
      'semester', 2,
      'completed', false
    );
    
    -- Current Academic Year (2024-25)
    current_year_id := gen_random_uuid();
    INSERT INTO academic_years (
      id, tenant_id, branch_id, name, display_name,
      start_date, end_date, term_structure, total_terms,
      status, is_current
    ) VALUES (
      current_year_id, branch_rec.tenant_id, branch_rec.branch_id,
      '2024-25', 'Academic Year 2024-2025',
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-04-01'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-06-01'
        ELSE DATE '2024-01-01'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2025-03-31'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2025-05-31'
        ELSE DATE '2024-12-31'
      END,
      'semester', 2,
      'active', true
    );
    
    -- Next Academic Year (2025-26)
    next_year_id := gen_random_uuid();
    INSERT INTO academic_years (
      id, tenant_id, branch_id, name, display_name,
      start_date, end_date, term_structure, total_terms,
      status, is_current
    ) VALUES (
      next_year_id, branch_rec.tenant_id, branch_rec.branch_id,
      '2025-26', 'Academic Year 2025-2026',
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2025-04-01'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2025-06-01'
        ELSE DATE '2025-01-01'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2026-03-31'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2026-05-31'
        ELSE DATE '2025-12-31'
      END,
      'semester', 2,
      'upcoming', false
    );
    
    -- Create academic terms for current year
    INSERT INTO academic_terms (
      tenant_id, academic_year_id, name, display_name, term_number,
      start_date, end_date, 
      classes_start_date, classes_end_date,
      exam_start_date, exam_end_date,
      status, is_current
    ) VALUES 
    -- First Term
    (
      branch_rec.tenant_id, current_year_id,
      'Term 1', 'First Term 2024-25', 1,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-04-01'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-06-01'
        ELSE DATE '2024-01-01'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-09-30'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-11-30'
        ELSE DATE '2024-06-30'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-04-15'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-06-15'
        ELSE DATE '2024-01-15'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-09-15'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-11-15'
        ELSE DATE '2024-06-15'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-09-20'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-11-20'
        ELSE DATE '2024-06-20'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-09-30'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-11-30'
        ELSE DATE '2024-06-30'
      END,
      'completed', false
    ),
    -- Second Term
    (
      branch_rec.tenant_id, current_year_id,
      'Term 2', 'Second Term 2024-25', 2,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-10-01'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-12-01'
        ELSE DATE '2024-07-01'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2025-03-31'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2025-05-31'
        ELSE DATE '2024-12-31'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2024-10-15'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2024-12-15'
        ELSE DATE '2024-07-15'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2025-03-15'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2025-05-15'
        ELSE DATE '2024-12-15'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2025-03-01'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2025-05-01'
        ELSE DATE '2024-12-01'
      END,
      CASE 
        WHEN branch_rec.academic_year_start_month = 4 THEN DATE '2025-03-15'
        WHEN branch_rec.academic_year_start_month = 6 THEN DATE '2025-05-15'
        ELSE DATE '2024-12-15'
      END,
      'active', true
    );
  END LOOP;
END $$;

-- ==============================================
-- CLASSES FOR ALL BRANCHES
-- ==============================================

-- Create classes for each branch based on their type
DO $$
DECLARE
  branch_rec RECORD;
  class_configs JSONB;
BEGIN
  FOR branch_rec IN 
    SELECT b.id as branch_id, b.tenant_id, b.name, b.type
    FROM branches b
    WHERE b.status = 'active'
  LOOP
    -- Define class structure based on branch type
    IF branch_rec.type = 'preschool' THEN
      -- Preschool classes (Little Stars Montessori)
      class_configs := '[
        {"name": "Toddlers", "code": "TOD", "level": 1, "max_students": 12},
        {"name": "Nursery", "code": "NUR", "level": 2, "max_students": 15},
        {"name": "Junior KG", "code": "JKG", "level": 3, "max_students": 18},
        {"name": "Senior KG", "code": "SKG", "level": 4, "max_students": 20}
      ]';
    ELSE
      -- Regular school classes
      class_configs := '[
        {"name": "Nursery", "code": "NUR", "level": 0, "max_students": 25},
        {"name": "LKG", "code": "LKG", "level": 1, "max_students": 30},
        {"name": "UKG", "code": "UKG", "level": 2, "max_students": 30},
        {"name": "Class 1", "code": "C1", "level": 3, "max_students": 35},
        {"name": "Class 2", "code": "C2", "level": 4, "max_students": 35},
        {"name": "Class 3", "code": "C3", "level": 5, "max_students": 35},
        {"name": "Class 4", "code": "C4", "level": 6, "max_students": 40},
        {"name": "Class 5", "code": "C5", "level": 7, "max_students": 40},
        {"name": "Class 6", "code": "C6", "level": 8, "max_students": 40},
        {"name": "Class 7", "code": "C7", "level": 9, "max_students": 40},
        {"name": "Class 8", "code": "C8", "level": 10, "max_students": 45},
        {"name": "Class 9", "code": "C9", "level": 11, "max_students": 45},
        {"name": "Class 10", "code": "C10", "level": 12, "max_students": 45},
        {"name": "Class 11", "code": "C11", "level": 13, "max_students": 50},
        {"name": "Class 12", "code": "C12", "level": 14, "max_students": 50}
      ]';
    END IF;
    
    -- Insert classes for this branch
    INSERT INTO classes (
      tenant_id, branch_id, name, code, display_name, level, 
      max_students, current_students, category, status
    )
    SELECT 
      branch_rec.tenant_id,
      branch_rec.branch_id,
      (config->>'name')::VARCHAR,
      (config->>'code')::VARCHAR,
      (config->>'name')::VARCHAR || ' - ' || branch_rec.name,
      (config->>'level')::INTEGER,
      (config->>'max_students')::INTEGER,
      0,
      'academic',
      'active'
    FROM jsonb_array_elements(class_configs) AS config;
  END LOOP;
END $$;

-- ==============================================
-- SECTIONS FOR CLASSES
-- ==============================================

-- Create sections for each class
DO $$
DECLARE
  class_rec RECORD;
  section_names VARCHAR[] := ARRAY['A', 'B', 'C', 'D', 'E'];
  section_name VARCHAR;
  i INTEGER;
BEGIN
  FOR class_rec IN 
    SELECT c.id as class_id, c.tenant_id, c.name, c.level, c.max_students
    FROM classes c
    WHERE c.status = 'active'
  LOOP
    -- Determine number of sections based on class level
    FOR i IN 1..CASE 
      WHEN class_rec.level <= 2 THEN 1  -- Nursery, LKG, UKG: 1 section
      WHEN class_rec.level <= 7 THEN 2  -- Class 1-5: 2 sections
      WHEN class_rec.level <= 12 THEN 3 -- Class 6-10: 3 sections
      ELSE 2                            -- Class 11-12: 2 sections
    END
    LOOP
      section_name := section_names[i];
      
      INSERT INTO sections (
        tenant_id, class_id, name, display_name,
        max_students, current_students, status
      ) VALUES (
        class_rec.tenant_id,
        class_rec.class_id,
        section_name,
        class_rec.name || ' - Section ' || section_name,
        LEAST(class_rec.max_students / 2, 40), -- Divide max students by expected sections, cap at 40
        0,
        'active'
      );
    END LOOP;
  END LOOP;
END $$;

-- ==============================================
-- UPDATE BRANCH STATISTICS
-- ==============================================

-- Update branch statistics based on created classes and sections
UPDATE branches SET
  total_classrooms = (
    SELECT COUNT(*) FROM sections s 
    JOIN classes c ON s.class_id = c.id 
    WHERE c.branch_id = branches.id AND s.status = 'active'
  );

-- ==============================================
-- SUMMARY REPORT
-- ==============================================

-- Display branch creation summary
SELECT 
  'Demo branches created successfully!' as status,
  COUNT(*) as total_branches,
  SUM(total_classrooms) as total_classrooms,
  SUM(total_labs) as total_labs,
  SUM(library_capacity) as total_library_capacity
FROM branches 
WHERE tenant_id IN (
  SELECT id FROM tenants WHERE settings->>'demo_data' = 'true'
);

-- Display academic structure summary
SELECT 
  t.name as tenant_name,
  COUNT(DISTINCT b.id) as branches,
  COUNT(DISTINCT ay.id) as academic_years,
  COUNT(DISTINCT c.id) as classes,
  COUNT(DISTINCT s.id) as sections
FROM tenants t
LEFT JOIN branches b ON t.id = b.tenant_id
LEFT JOIN academic_years ay ON b.id = ay.branch_id
LEFT JOIN classes c ON b.id = c.branch_id
LEFT JOIN sections s ON c.id = s.class_id
WHERE t.settings->>'demo_data' = 'true'
GROUP BY t.id, t.name
ORDER BY t.name;