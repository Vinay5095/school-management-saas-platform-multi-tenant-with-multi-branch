-- ==============================================
-- DEMO TENANTS SEED DATA
-- File: tenants.sql
-- Created: October 4, 2025
-- Description: Sample tenant data for demonstration purposes
-- ==============================================

-- Note: This file creates demo/sample tenants for testing and demonstration
-- In production, tenants will be created through the application interface

-- ==============================================
-- DEMO TENANT 1: Sunshine International School
-- ==============================================

-- Insert demo tenant 1
DO $$
DECLARE
  tenant_id UUID := gen_random_uuid();
  professional_plan_id UUID;
BEGIN
  -- Get professional plan ID
  SELECT id INTO professional_plan_id FROM subscription_plans WHERE name = 'professional';
  
  -- Insert tenant
  INSERT INTO tenants (
    id, name, slug, display_name, description,
    subdomain, contact_email, contact_phone, contact_person,
    website, address_line1, address_line2, city, state, country, postal_code,
    subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date,
    current_students, current_staff, current_branches,
    settings, features, status, is_verified, activated_at
  ) VALUES (
    tenant_id,
    'Sunshine International School',
    'sunshine-international',
    'Sunshine International School - Excellence in Education',
    'A premier educational institution committed to nurturing young minds with world-class facilities and innovative teaching methodologies.',
    'sunshine',
    'admin@sunshineintl.edu',
    '+91-11-45678900',
    'Dr. Priya Sharma',
    'https://sunshineintl.edu',
    'Sector 45, Educational Hub',
    'Near Metro Station',
    'Gurgaon',
    'HR',
    'IN',
    '122003',
    professional_plan_id,
    'active',
    CURRENT_DATE - INTERVAL '6 months',
    CURRENT_DATE + INTERVAL '6 months',
    450,
    65,
    2,
    '{
      "academic_year_format": "april_march",
      "default_language": "en",
      "supported_languages": ["en", "hi"],
      "theme": {
        "primary_color": "#1e40af",
        "secondary_color": "#7c3aed",
        "accent_color": "#059669"
      },
      "features": {
        "enable_online_classes": true,
        "enable_parent_portal": true,
        "enable_mobile_app": true,
        "enable_sms_notifications": true,
        "enable_fee_online_payment": true
      },
      "integrations": {
        "google_classroom": true,
        "zoom": true,
        "payment_gateway": "razorpay"
      }
    }',
    '["student_management", "staff_management", "attendance_tracking", "grade_management", "parent_portal", "advanced_reports", "fee_management", "library_management", "transport_management", "examination_management", "timetable_management"]',
    'active',
    true,
    CURRENT_DATE - INTERVAL '6 months'
  );
  
  -- Store tenant_id for use in other demo data
  PERFORM set_config('demo.sunshine_tenant_id', tenant_id::text, false);
END $$;

-- ==============================================
-- DEMO TENANT 2: Green Valley Public School
-- ==============================================

DO $$
DECLARE
  tenant_id UUID := gen_random_uuid();
  starter_plan_id UUID;
BEGIN
  -- Get starter plan ID
  SELECT id INTO starter_plan_id FROM subscription_plans WHERE name = 'starter';
  
  -- Insert tenant
  INSERT INTO tenants (
    id, name, slug, display_name, description,
    subdomain, contact_email, contact_phone, contact_person,
    website, address_line1, city, state, country, postal_code,
    subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date,
    current_students, current_staff, current_branches,
    settings, features, status, is_verified, activated_at
  ) VALUES (
    tenant_id,
    'Green Valley Public School',
    'green-valley-public',
    'Green Valley Public School - Growing Together',
    'A community-focused school dedicated to holistic education and character building with emphasis on environmental consciousness.',
    'greenvalley',
    'principal@greenvalley.edu.in',
    '+91-80-98765432',
    'Mr. Rajesh Kumar',
    'https://greenvalleypublic.edu.in',
    '123 Green Avenue, Whitefield',
    'Bangalore',
    'KA',
    'IN',
    '560066',
    starter_plan_id,
    'active',
    CURRENT_DATE - INTERVAL '3 months',
    CURRENT_DATE + INTERVAL '9 months',
    180,
    22,
    1,
    '{
      "academic_year_format": "april_march",
      "default_language": "en",
      "supported_languages": ["en", "kn"],
      "theme": {
        "primary_color": "#059669",
        "secondary_color": "#0d9488",
        "accent_color": "#84cc16"
      },
      "features": {
        "enable_online_classes": false,
        "enable_parent_portal": true,
        "enable_mobile_app": false,
        "enable_sms_notifications": true,
        "enable_fee_online_payment": false
      }
    }',
    '["student_management", "staff_management", "attendance_tracking", "grade_management", "parent_portal", "basic_reports", "fee_management"]',
    'active',
    true,
    CURRENT_DATE - INTERVAL '3 months'
  );
  
  -- Store tenant_id for use in other demo data
  PERFORM set_config('demo.greenvalley_tenant_id', tenant_id::text, false);
END $$;

-- ==============================================
-- DEMO TENANT 3: Elite Academy (Enterprise)
-- ==============================================

DO $$
DECLARE
  tenant_id UUID := gen_random_uuid();
  enterprise_plan_id UUID;
BEGIN
  -- Get enterprise plan ID
  SELECT id INTO enterprise_plan_id FROM subscription_plans WHERE name = 'enterprise';
  
  -- Insert tenant
  INSERT INTO tenants (
    id, name, slug, display_name, description,
    subdomain, contact_email, contact_phone, contact_person,
    website, address_line1, address_line2, city, state, country, postal_code,
    subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date,
    current_students, current_staff, current_branches,
    settings, features, status, is_verified, activated_at
  ) VALUES (
    tenant_id,
    'Elite Academy',
    'elite-academy',
    'Elite Academy - Excellence Redefined',
    'A premium educational institution with multiple campuses, offering comprehensive education from kindergarten to grade 12 with international curriculum options.',
    'elite',
    'director@eliteacademy.edu',
    '+91-22-67890123',
    'Dr. Anjali Mehta',
    'https://eliteacademy.edu',
    'Elite Education Complex, Bandra Kurla',
    'Corporate Park Road',
    'Mumbai',
    'MH',
    'IN',
    '400051',
    enterprise_plan_id,
    'active',
    CURRENT_DATE - INTERVAL '1 year',
    CURRENT_DATE + INTERVAL '1 year',
    1250,
    145,
    4,
    '{
      "academic_year_format": "april_march",
      "default_language": "en",
      "supported_languages": ["en", "hi", "mr"],
      "theme": {
        "primary_color": "#7c2d12",
        "secondary_color": "#a16207",
        "accent_color": "#dc2626"
      },
      "features": {
        "enable_online_classes": true,
        "enable_parent_portal": true,
        "enable_mobile_app": true,
        "enable_sms_notifications": true,
        "enable_whatsapp_notifications": true,
        "enable_fee_online_payment": true,
        "enable_biometric_attendance": true,
        "enable_transport_tracking": true,
        "enable_advanced_analytics": true
      },
      "integrations": {
        "google_classroom": true,
        "microsoft_teams": true,
        "zoom": true,
        "payment_gateway": "stripe",
        "sms_provider": "twilio",
        "email_provider": "sendgrid"
      },
      "custom_branding": {
        "logo_url": "https://eliteacademy.edu/logo.png",
        "favicon_url": "https://eliteacademy.edu/favicon.ico",
        "custom_css": true
      }
    }',
    '["student_management", "staff_management", "attendance_tracking", "grade_management", "parent_portal", "advanced_reports", "fee_management", "library_management", "transport_management", "examination_management", "timetable_management", "inventory_management", "hr_management", "accounting", "custom_fields", "api_access"]',
    'active',
    true,
    CURRENT_DATE - INTERVAL '1 year'
  );
  
  -- Store tenant_id for use in other demo data
  PERFORM set_config('demo.elite_tenant_id', tenant_id::text, false);
END $$;

-- ==============================================
-- DEMO TENANT 4: Little Stars Montessori (Free Plan)
-- ==============================================

DO $$
DECLARE
  tenant_id UUID := gen_random_uuid();
  free_plan_id UUID;
BEGIN
  -- Get free plan ID
  SELECT id INTO free_plan_id FROM subscription_plans WHERE name = 'free';
  
  -- Insert tenant
  INSERT INTO tenants (
    id, name, slug, display_name, description,
    subdomain, contact_email, contact_phone, contact_person,
    city, state, country, postal_code,
    subscription_plan_id, subscription_status, trial_ends_at,
    current_students, current_staff, current_branches,
    settings, features, status, is_verified, activated_at
  ) VALUES (
    tenant_id,
    'Little Stars Montessori',
    'little-stars-montessori',
    'Little Stars Montessori - Where Learning Begins',
    'A nurturing Montessori school for early childhood education, focusing on child-centered learning and development.',
    'littlestars',
    'director@littlestars.edu',
    '+91-44-87654321',
    'Ms. Sarah Thomas',
    'Chennai',
    'TN',
    'IN',
    '600028',
    free_plan_id,
    'trial',
    CURRENT_DATE + INTERVAL '7 days',
    35,
    8,
    1,
    '{
      "academic_year_format": "june_may",
      "default_language": "en",
      "supported_languages": ["en", "ta"],
      "theme": {
        "primary_color": "#ec4899",
        "secondary_color": "#8b5cf6",
        "accent_color": "#f59e0b"
      },
      "features": {
        "enable_online_classes": false,
        "enable_parent_portal": true,
        "enable_mobile_app": false,
        "enable_sms_notifications": false
      }
    }',
    '["student_management", "basic_attendance", "basic_grades", "parent_communication"]',
    'active',
    true,
    CURRENT_DATE - INTERVAL '7 days'
  );
  
  -- Store tenant_id for use in other demo data
  PERFORM set_config('demo.littlestars_tenant_id', tenant_id::text, false);
END $$;

-- ==============================================
-- TENANT SUBSCRIPTIONS HISTORY
-- ==============================================

-- Create subscription records for active tenants
INSERT INTO tenant_subscriptions (
  tenant_id, plan_id, status, billing_cycle, 
  amount_monthly, amount_yearly, currency,
  start_date, end_date, billing_email
)
SELECT 
  t.id,
  t.subscription_plan_id,
  'active',
  'yearly',
  sp.price_monthly,
  sp.price_yearly,
  'USD',
  t.subscription_start_date,
  t.subscription_end_date,
  t.contact_email
FROM tenants t
JOIN subscription_plans sp ON t.subscription_plan_id = sp.id
WHERE t.subscription_status = 'active' AND sp.name != 'free';

-- ==============================================
-- TENANT USAGE TRACKING (SAMPLE DATA)
-- ==============================================

-- Generate sample usage data for the last 30 days
DO $$
DECLARE
  tenant_rec RECORD;
  date_rec DATE;
BEGIN
  -- For each active tenant
  FOR tenant_rec IN 
    SELECT id, name, current_students, current_staff 
    FROM tenants 
    WHERE status = 'active'
  LOOP
    -- Generate daily usage data for last 30 days
    FOR date_rec IN 
      SELECT generate_series(CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '1 day', INTERVAL '1 day')::DATE
    LOOP
      -- Student count (with some variation)
      INSERT INTO tenant_usage (tenant_id, metric_name, metric_value, metric_unit, period_type, period_start, period_end)
      VALUES (
        tenant_rec.id,
        'active_students',
        tenant_rec.current_students + FLOOR(RANDOM() * 10 - 5),
        'count',
        'daily',
        date_rec,
        date_rec
      );
      
      -- Staff count
      INSERT INTO tenant_usage (tenant_id, metric_name, metric_value, metric_unit, period_type, period_start, period_end)
      VALUES (
        tenant_rec.id,
        'active_staff',
        tenant_rec.current_staff + FLOOR(RANDOM() * 3 - 1),
        'count',
        'daily',
        date_rec,
        date_rec
      );
      
      -- Storage usage (in GB)
      INSERT INTO tenant_usage (tenant_id, metric_name, metric_value, metric_unit, period_type, period_start, period_end)
      VALUES (
        tenant_rec.id,
        'storage_used',
        ROUND((RANDOM() * 5 + 1)::NUMERIC, 2),
        'GB',
        'daily',
        date_rec,
        date_rec
      );
      
      -- API calls
      INSERT INTO tenant_usage (tenant_id, metric_name, metric_value, metric_unit, period_type, period_start, period_end)
      VALUES (
        tenant_rec.id,
        'api_calls',
        FLOOR(RANDOM() * 500 + 100),
        'count',
        'daily',
        date_rec,
        date_rec
      );
      
      -- Login sessions
      INSERT INTO tenant_usage (tenant_id, metric_name, metric_value, metric_unit, period_type, period_start, period_end)
      VALUES (
        tenant_rec.id,
        'login_sessions',
        FLOOR(RANDOM() * (tenant_rec.current_students + tenant_rec.current_staff) * 0.3 + 10),
        'count',
        'daily',
        date_rec,
        date_rec
      );
    END LOOP;
  END LOOP;
END $$;

-- ==============================================
-- TENANT METADATA
-- ==============================================

-- Add some additional metadata for demo tenants
UPDATE tenants SET 
  settings = settings || '{"demo_data": true, "created_by": "seed_script", "sample_data_version": "1.0"}',
  description = description || ' [DEMO DATA]'
WHERE slug IN ('sunshine-international', 'green-valley-public', 'elite-academy', 'little-stars-montessori');

-- ==============================================
-- SUMMARY
-- ==============================================

-- Display tenant creation summary
SELECT 
  'Demo tenants created successfully!' as status,
  COUNT(*) as total_tenants,
  COUNT(*) FILTER (WHERE subscription_status = 'active') as active_tenants,
  COUNT(*) FILTER (WHERE subscription_status = 'trial') as trial_tenants,
  STRING_AGG(name, ', ') as tenant_names
FROM tenants
WHERE settings->>'demo_data' = 'true';

-- Display subscription summary
SELECT 
  sp.display_name as plan_name,
  COUNT(t.id) as tenant_count,
  SUM(t.current_students) as total_students,
  SUM(t.current_staff) as total_staff
FROM tenants t
JOIN subscription_plans sp ON t.subscription_plan_id = sp.id
WHERE t.settings->>'demo_data' = 'true'
GROUP BY sp.id, sp.display_name, sp.sort_order
ORDER BY sp.sort_order;