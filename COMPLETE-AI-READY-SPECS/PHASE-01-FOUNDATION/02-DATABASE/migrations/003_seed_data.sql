-- ==============================================
-- SEED DATA MIGRATION
-- Migration: 003_seed_data.sql
-- Created: October 4, 2025
-- Description: Initial seed data for multi-tenant school management system
-- ==============================================

-- ==============================================
-- SYSTEM CONFIGURATION SEED DATA
-- ==============================================

-- Insert system-wide configurations
INSERT INTO system_config (category, key, value, description, data_type, is_public, is_required) VALUES
-- Application settings
('app', 'name', '"School Management Pro"', 'Application name', 'string', true, true),
('app', 'version', '"1.0.0"', 'Application version', 'string', true, true),
('app', 'description', '"Comprehensive Multi-Tenant School Management System"', 'Application description', 'string', true, false),
('app', 'support_email', '"support@schoolmanagementpro.com"', 'Support contact email', 'string', true, true),
('app', 'support_phone', '"+1-800-SCHOOL"', 'Support contact phone', 'string', true, false),

-- Default settings
('defaults', 'timezone', '"Asia/Kolkata"', 'Default timezone', 'string', true, true),
('defaults', 'language', '"en"', 'Default language', 'string', true, true),
('defaults', 'currency', '"USD"', 'Default currency', 'string', true, true),
('defaults', 'date_format', '"YYYY-MM-DD"', 'Default date format', 'string', true, true),
('defaults', 'academic_year_format', '"april_march"', 'Default academic year format', 'string', true, true),

-- Email settings
('email', 'provider', '"supabase"', 'Email service provider', 'string', false, true),
('email', 'from_name', '"School Management Pro"', 'Default sender name', 'string', false, true),
('email', 'from_email', '"noreply@schoolmanagementpro.com"', 'Default sender email', 'string', false, true),
('email', 'support_email', '"support@schoolmanagementpro.com"', 'Support email address', 'string', false, true),

-- Security settings
('security', 'password_min_length', '8', 'Minimum password length', 'number', true, true),
('security', 'password_require_uppercase', 'true', 'Require uppercase in password', 'boolean', true, true),
('security', 'password_require_lowercase', 'true', 'Require lowercase in password', 'boolean', true, true),
('security', 'password_require_numbers', 'true', 'Require numbers in password', 'boolean', true, true),
('security', 'password_require_symbols', 'false', 'Require symbols in password', 'boolean', true, true),
('security', 'session_timeout_minutes', '480', 'Session timeout in minutes (8 hours)', 'number', true, true),
('security', 'max_login_attempts', '5', 'Maximum login attempts before lockout', 'number', true, true),
('security', 'lockout_duration_minutes', '30', 'Account lockout duration in minutes', 'number', true, true),

-- File upload settings
('uploads', 'max_file_size_mb', '10', 'Maximum file upload size in MB', 'number', true, true),
('uploads', 'allowed_image_types', '["jpg", "jpeg", "png", "gif", "webp"]', 'Allowed image file types', 'array', true, true),
('uploads', 'allowed_document_types', '["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx"]', 'Allowed document file types', 'array', true, true),
('uploads', 'storage_provider', '"supabase"', 'File storage provider', 'string', false, true),

-- API settings
('api', 'rate_limit_requests_per_minute', '100', 'API rate limit per minute', 'number', true, true),
('api', 'rate_limit_requests_per_hour', '1000', 'API rate limit per hour', 'number', true, true),
('api', 'enable_cors', 'true', 'Enable CORS for API', 'boolean', false, true),
('api', 'cors_origins', '["http://localhost:3000", "https://schoolmanagementpro.com"]', 'Allowed CORS origins', 'array', false, true),

-- Business rules
('business', 'max_students_per_section', '40', 'Maximum students per section', 'number', true, true),
('business', 'max_subjects_per_student', '15', 'Maximum subjects per student', 'number', true, true),
('business', 'attendance_late_threshold_minutes', '15', 'Late attendance threshold in minutes', 'number', true, true),
('business', 'fee_due_reminder_days', '7', 'Days before fee due date to send reminder', 'number', true, true),
('business', 'grade_calculation_method', '"weighted_average"', 'Grade calculation method', 'string', true, true);

-- ==============================================
-- SUBSCRIPTION PLANS SEED DATA
-- ==============================================

-- Insert subscription plans
INSERT INTO subscription_plans (
  id, name, display_name, description, 
  price_monthly, price_yearly, 
  max_students, max_staff, max_branches, max_storage_gb, max_api_calls_per_month,
  features, integrations, trial_days, is_public, is_active, sort_order
) VALUES
-- Free Plan
(
  gen_random_uuid(),
  'free',
  'Free Plan',
  'Perfect for small schools getting started with basic features',
  0.00, 0.00,
  50, 10, 1, 1, 1000,
  '["student_management", "basic_attendance", "basic_grades", "parent_communication"]',
  '["email"]',
  14, true, true, 1
),

-- Starter Plan
(
  gen_random_uuid(),
  'starter',
  'Starter Plan',
  'Ideal for small to medium schools with essential management features',
  29.99, 299.99,
  200, 25, 2, 5, 5000,
  '["student_management", "staff_management", "attendance_tracking", "grade_management", "parent_portal", "basic_reports", "fee_management"]',
  '["email", "sms"]',
  14, true, true, 2
),

-- Professional Plan
(
  gen_random_uuid(),
  'professional',
  'Professional Plan',
  'Comprehensive features for growing educational institutions',
  79.99, 799.99,
  500, 75, 5, 20, 15000,
  '["student_management", "staff_management", "attendance_tracking", "grade_management", "parent_portal", "advanced_reports", "fee_management", "library_management", "transport_management", "examination_management", "timetable_management"]',
  '["email", "sms", "whatsapp", "google_classroom"]',
  14, true, true, 3
),

-- Enterprise Plan
(
  gen_random_uuid(),
  'enterprise',
  'Enterprise Plan',
  'Full-featured solution for large schools and multi-campus institutions',
  199.99, 1999.99,
  2000, 200, 20, 100, 50000,
  '["student_management", "staff_management", "attendance_tracking", "grade_management", "parent_portal", "advanced_reports", "fee_management", "library_management", "transport_management", "examination_management", "timetable_management", "inventory_management", "hr_management", "accounting", "custom_fields", "api_access", "white_labeling"]',
  '["email", "sms", "whatsapp", "google_classroom", "microsoft_teams", "zoom", "custom_integrations"]',
  30, true, true, 4
),

-- Custom Plan
(
  gen_random_uuid(),
  'custom',
  'Custom Plan',
  'Tailored solution for specific requirements - contact sales',
  0.00, 0.00,
  NULL, NULL, NULL, NULL, NULL,
  '["everything", "custom_development", "dedicated_support", "training", "data_migration"]',
  '["all_available", "custom_integrations"]',
  30, true, true, 5
);

-- ==============================================
-- FEATURE FLAGS SEED DATA
-- ==============================================

-- Insert feature flags
INSERT INTO feature_flags (name, description, is_enabled, conditions, rollout_percentage) VALUES
('enable_sms_notifications', 'Enable SMS notifications for parents and students', true, '{}', 100),
('enable_whatsapp_integration', 'Enable WhatsApp integration for communication', false, '{"plan": ["professional", "enterprise", "custom"]}', 0),
('enable_biometric_attendance', 'Enable biometric attendance tracking', false, '{"plan": ["enterprise", "custom"]}', 25),
('enable_ai_grade_predictions', 'Enable AI-powered grade predictions', false, '{"plan": ["enterprise", "custom"]}', 10),
('enable_mobile_app', 'Enable mobile app access', true, '{}', 100),
('enable_parent_app', 'Enable dedicated parent mobile app', true, '{"plan": ["starter", "professional", "enterprise", "custom"]}', 80),
('enable_teacher_app', 'Enable dedicated teacher mobile app', true, '{"plan": ["professional", "enterprise", "custom"]}', 70),
('enable_advanced_analytics', 'Enable advanced analytics and insights', false, '{"plan": ["professional", "enterprise", "custom"]}', 50),
('enable_custom_fields', 'Enable custom fields for forms', false, '{"plan": ["enterprise", "custom"]}', 100),
('enable_api_access', 'Enable API access for integrations', false, '{"plan": ["enterprise", "custom"]}', 100),
('enable_white_labeling', 'Enable white-label customization', false, '{"plan": ["custom"]}', 100),
('enable_multi_language', 'Enable multi-language support', true, '{}', 80),
('enable_dark_mode', 'Enable dark mode interface', true, '{}', 100),
('enable_offline_mode', 'Enable offline mode for mobile apps', false, '{}', 30),
('enable_backup_notifications', 'Enable automated backup notifications', true, '{"plan": ["professional", "enterprise", "custom"]}', 100);

-- ==============================================
-- SYSTEM USERS SEED DATA
-- ==============================================

-- Note: These are system-level users, not tenant-specific
-- Actual user creation will be handled by the authentication system

-- ==============================================
-- REFERENCE DATA SEED
-- ==============================================

-- Common reference data that tenants can use

-- Academic levels/standards reference
INSERT INTO system_config (category, key, value, description, data_type, is_public) VALUES
('reference', 'indian_academic_levels', 
 '[
   {"code": "nursery", "name": "Nursery", "level": 0},
   {"code": "lkg", "name": "Lower KG", "level": 1},
   {"code": "ukg", "name": "Upper KG", "level": 2},
   {"code": "class_1", "name": "Class 1", "level": 3},
   {"code": "class_2", "name": "Class 2", "level": 4},
   {"code": "class_3", "name": "Class 3", "level": 5},
   {"code": "class_4", "name": "Class 4", "level": 6},
   {"code": "class_5", "name": "Class 5", "level": 7},
   {"code": "class_6", "name": "Class 6", "level": 8},
   {"code": "class_7", "name": "Class 7", "level": 9},
   {"code": "class_8", "name": "Class 8", "level": 10},
   {"code": "class_9", "name": "Class 9", "level": 11},
   {"code": "class_10", "name": "Class 10", "level": 12},
   {"code": "class_11", "name": "Class 11", "level": 13},
   {"code": "class_12", "name": "Class 12", "level": 14}
 ]',
 'Indian academic levels reference', 'array', true),

('reference', 'subject_categories',
 '[
   {"code": "core", "name": "Core Subject", "required": true},
   {"code": "elective", "name": "Elective Subject", "required": false},
   {"code": "language", "name": "Language", "required": true},
   {"code": "mathematics", "name": "Mathematics", "required": true},
   {"code": "science", "name": "Science", "required": true},
   {"code": "social_science", "name": "Social Science", "required": true},
   {"code": "arts", "name": "Arts & Crafts", "required": false},
   {"code": "physical_education", "name": "Physical Education", "required": true},
   {"code": "computer_science", "name": "Computer Science", "required": false},
   {"code": "vocational", "name": "Vocational Training", "required": false}
 ]',
 'Subject categories reference', 'array', true),

('reference', 'grading_systems',
 '[
   {"code": "percentage", "name": "Percentage (0-100)", "min": 0, "max": 100},
   {"code": "cgpa_10", "name": "CGPA (0-10)", "min": 0, "max": 10},
   {"code": "gpa_4", "name": "GPA (0-4)", "min": 0, "max": 4},
   {"code": "letter_grade", "name": "Letter Grade (A-F)", "grades": ["A+", "A", "B+", "B", "C+", "C", "D", "F"]},
   {"code": "cbse", "name": "CBSE Grading", "grades": ["A1", "A2", "B1", "B2", "C1", "C2", "D", "E"]}
 ]',
 'Grading systems reference', 'array', true),

('reference', 'indian_states',
 '[
   {"code": "AN", "name": "Andaman and Nicobar Islands"},
   {"code": "AP", "name": "Andhra Pradesh"},
   {"code": "AR", "name": "Arunachal Pradesh"},
   {"code": "AS", "name": "Assam"},
   {"code": "BR", "name": "Bihar"},
   {"code": "CH", "name": "Chandigarh"},
   {"code": "CG", "name": "Chhattisgarh"},
   {"code": "DN", "name": "Dadra and Nagar Haveli"},
   {"code": "DD", "name": "Daman and Diu"},
   {"code": "DL", "name": "Delhi"},
   {"code": "GA", "name": "Goa"},
   {"code": "GJ", "name": "Gujarat"},
   {"code": "HR", "name": "Haryana"},
   {"code": "HP", "name": "Himachal Pradesh"},
   {"code": "JK", "name": "Jammu and Kashmir"},
   {"code": "JH", "name": "Jharkhand"},
   {"code": "KA", "name": "Karnataka"},
   {"code": "KL", "name": "Kerala"},
   {"code": "LD", "name": "Lakshadweep"},
   {"code": "MP", "name": "Madhya Pradesh"},
   {"code": "MH", "name": "Maharashtra"},
   {"code": "MN", "name": "Manipur"},
   {"code": "ML", "name": "Meghalaya"},
   {"code": "MZ", "name": "Mizoram"},
   {"code": "NL", "name": "Nagaland"},
   {"code": "OR", "name": "Odisha"},
   {"code": "PY", "name": "Puducherry"},
   {"code": "PB", "name": "Punjab"},
   {"code": "RJ", "name": "Rajasthan"},
   {"code": "SK", "name": "Sikkim"},
   {"code": "TN", "name": "Tamil Nadu"},
   {"code": "TS", "name": "Telangana"},
   {"code": "TR", "name": "Tripura"},
   {"code": "UP", "name": "Uttar Pradesh"},
   {"code": "UK", "name": "Uttarakhand"},
   {"code": "WB", "name": "West Bengal"}
 ]',
 'Indian states and union territories', 'array', true);

-- ==============================================
-- DEMO/SAMPLE DATA PREPARATION
-- ==============================================

-- Note: The actual demo tenant data will be created in separate files
-- This section prepares the system for demo data creation

-- Mark system as ready for tenant creation
INSERT INTO system_config (category, key, value, description) VALUES
('system', 'ready_for_tenants', 'true', 'System is ready for tenant creation'),
('system', 'demo_data_available', 'true', 'Demo data scripts are available'),
('system', 'seed_data_version', '"1.0.0"', 'Version of seed data');

-- ==============================================
-- USEFUL STORED PROCEDURES FOR SEED DATA
-- ==============================================

-- Function to create academic year based on format
CREATE OR REPLACE FUNCTION generate_academic_year_name(start_date DATE, format_type VARCHAR DEFAULT 'april_march')
RETURNS VARCHAR AS $$
DECLARE
  start_year INTEGER;
  end_year INTEGER;
  year_name VARCHAR;
BEGIN
  start_year := EXTRACT(YEAR FROM start_date);
  
  CASE format_type
    WHEN 'april_march' THEN
      end_year := start_year + 1;
      year_name := start_year || '-' || LPAD((end_year % 100)::TEXT, 2, '0');
    WHEN 'january_december' THEN
      year_name := start_year::TEXT;
    WHEN 'june_may' THEN
      end_year := start_year + 1;
      year_name := start_year || '-' || LPAD((end_year % 100)::TEXT, 2, '0');
    ELSE
      year_name := start_year::TEXT;
  END CASE;
  
  RETURN year_name;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get subscription plan by name
CREATE OR REPLACE FUNCTION get_subscription_plan_id(plan_name VARCHAR)
RETURNS UUID AS $$
DECLARE
  plan_id UUID;
BEGIN
  SELECT id INTO plan_id FROM subscription_plans WHERE name = plan_name AND is_active = true;
  RETURN plan_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to generate unique tenant slug
CREATE OR REPLACE FUNCTION generate_unique_slug(base_name VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
  base_slug VARCHAR;
  final_slug VARCHAR;
  counter INTEGER := 0;
  slug_exists BOOLEAN;
BEGIN
  -- Convert to lowercase and replace spaces/special chars with hyphens
  base_slug := LOWER(TRIM(REGEXP_REPLACE(base_name, '[^a-zA-Z0-9\s]', '', 'g')));
  base_slug := REGEXP_REPLACE(base_slug, '\s+', '-', 'g');
  base_slug := TRIM(base_slug, '-');
  
  -- Ensure minimum length
  IF LENGTH(base_slug) < 3 THEN
    base_slug := base_slug || '-school';
  END IF;
  
  final_slug := base_slug;
  
  -- Check if slug exists and increment if needed
  LOOP
    SELECT EXISTS(SELECT 1 FROM tenants WHERE slug = final_slug) INTO slug_exists;
    EXIT WHEN NOT slug_exists;
    
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- MIGRATION COMPLETION
-- ==============================================

-- Log seed data migration completion
INSERT INTO system_config (category, key, value, description) VALUES 
('migrations', '003_seed_data', 
 '{"completed_at": "2025-10-04", "version": "1.0", "configs_inserted": 40, "plans_inserted": 5, "flags_inserted": 15}', 
 'Seed data migration completed');

-- Display seed data summary
SELECT 
  'Migration 003_seed_data.sql completed successfully!' as status,
  (SELECT COUNT(*) FROM system_config WHERE category != 'migrations') as system_configs,
  (SELECT COUNT(*) FROM subscription_plans) as subscription_plans,
  (SELECT COUNT(*) FROM feature_flags) as feature_flags,
  'System ready for tenant creation' as next_step;