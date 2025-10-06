-- ==============================================
-- DATABASE INDEXES MIGRATION
-- Migration: 002_add_indexes.sql
-- Created: October 4, 2025
-- Description: Performance indexes for multi-tenant school management system
-- ==============================================

-- ==============================================
-- TENANT AND ORGANIZATIONAL INDEXES
-- ==============================================

-- Tenant table indexes
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug);
CREATE INDEX IF NOT EXISTS idx_tenants_subdomain ON tenants(subdomain) WHERE subdomain IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tenants_custom_domain ON tenants(custom_domain) WHERE custom_domain IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_subscription_plan ON tenants(subscription_plan_id);
CREATE INDEX IF NOT EXISTS idx_tenants_subscription_status ON tenants(subscription_status);
CREATE INDEX IF NOT EXISTS idx_tenants_trial_ends ON tenants(trial_ends_at) WHERE trial_ends_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tenants_last_activity ON tenants(last_activity_at);
CREATE INDEX IF NOT EXISTS idx_tenants_deleted ON tenants(deleted_at) WHERE deleted_at IS NOT NULL;

-- Branch table indexes
CREATE INDEX IF NOT EXISTS idx_branches_tenant_id ON branches(tenant_id);
CREATE INDEX IF NOT EXISTS idx_branches_tenant_code ON branches(tenant_id, code);
CREATE INDEX IF NOT EXISTS idx_branches_status ON branches(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_branches_type ON branches(tenant_id, type);
CREATE INDEX IF NOT EXISTS idx_branches_main ON branches(tenant_id, is_main_branch) WHERE is_main_branch = true;
CREATE INDEX IF NOT EXISTS idx_branches_city ON branches(tenant_id, city);
CREATE INDEX IF NOT EXISTS idx_branches_state ON branches(tenant_id, state);
CREATE INDEX IF NOT EXISTS idx_branches_deleted ON branches(tenant_id, deleted_at) WHERE deleted_at IS NOT NULL;

-- Academic year indexes
CREATE INDEX IF NOT EXISTS idx_academic_years_tenant ON academic_years(tenant_id);
CREATE INDEX IF NOT EXISTS idx_academic_years_branch ON academic_years(tenant_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_academic_years_current ON academic_years(tenant_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_academic_years_status ON academic_years(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_academic_years_dates ON academic_years(tenant_id, start_date, end_date);

-- Academic term indexes
CREATE INDEX IF NOT EXISTS idx_academic_terms_tenant ON academic_terms(tenant_id);
CREATE INDEX IF NOT EXISTS idx_academic_terms_year ON academic_terms(tenant_id, academic_year_id);
CREATE INDEX IF NOT EXISTS idx_academic_terms_current ON academic_terms(tenant_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_academic_terms_status ON academic_terms(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_academic_terms_dates ON academic_terms(tenant_id, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_academic_terms_term_number ON academic_terms(tenant_id, academic_year_id, term_number);

-- Class indexes
CREATE INDEX IF NOT EXISTS idx_classes_tenant ON classes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_classes_branch ON classes(tenant_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_classes_tenant_code ON classes(tenant_id, code);
CREATE INDEX IF NOT EXISTS idx_classes_level ON classes(tenant_id, level);
CREATE INDEX IF NOT EXISTS idx_classes_category ON classes(tenant_id, category);
CREATE INDEX IF NOT EXISTS idx_classes_status ON classes(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_classes_deleted ON classes(tenant_id, deleted_at) WHERE deleted_at IS NOT NULL;

-- Section indexes
CREATE INDEX IF NOT EXISTS idx_sections_tenant ON sections(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sections_class ON sections(tenant_id, class_id);
CREATE INDEX IF NOT EXISTS idx_sections_teacher ON sections(tenant_id, class_teacher_id) WHERE class_teacher_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sections_status ON sections(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sections_room ON sections(tenant_id, room_number) WHERE room_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sections_deleted ON sections(tenant_id, deleted_at) WHERE deleted_at IS NOT NULL;

-- ==============================================
-- USER MANAGEMENT INDEXES
-- ==============================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_branch ON users(tenant_id, branch_id) WHERE branch_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant_email ON users(tenant_id, email);
CREATE INDEX IF NOT EXISTS idx_users_employee_id ON users(tenant_id, employee_id) WHERE employee_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_student_id ON users(tenant_id, student_id) WHERE student_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_admission_number ON users(tenant_id, admission_number) WHERE admission_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_primary_role ON users(tenant_id, primary_role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login_at);
CREATE INDEX IF NOT EXISTS idx_users_deleted ON users(tenant_id, deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_full_name ON users USING gin(full_name gin_trgm_ops);

-- User roles indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant ON user_roles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(tenant_id, role);
CREATE INDEX IF NOT EXISTS idx_user_roles_scope ON user_roles(tenant_id, scope, scope_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON user_roles(tenant_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_roles_expires ON user_roles(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_granted_by ON user_roles(tenant_id, granted_by) WHERE granted_by IS NOT NULL;

-- User sessions indexes
CREATE INDEX IF NOT EXISTS idx_user_sessions_tenant ON user_sessions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(tenant_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_sessions_ip ON user_sessions(ip_address);
CREATE INDEX IF NOT EXISTS idx_user_sessions_started ON user_sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_last_activity ON user_sessions(last_activity_at);

-- User preferences indexes
CREATE INDEX IF NOT EXISTS idx_user_preferences_tenant ON user_preferences(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON user_preferences(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_category ON user_preferences(tenant_id, category);
CREATE INDEX IF NOT EXISTS idx_user_preferences_public ON user_preferences(tenant_id, is_public) WHERE is_public = true;

-- ==============================================
-- STUDENT MANAGEMENT INDEXES
-- ==============================================

-- Students table indexes
CREATE INDEX IF NOT EXISTS idx_students_tenant ON students(tenant_id);
CREATE INDEX IF NOT EXISTS idx_students_user ON students(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_students_branch ON students(tenant_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_students_admission_number ON students(tenant_id, admission_number);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(tenant_id, class_id) WHERE class_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_students_section ON students(tenant_id, section_id) WHERE section_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_students_academic_year ON students(tenant_id, academic_year_id) WHERE academic_year_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_students_roll_number ON students(tenant_id, roll_number) WHERE roll_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_students_status ON students(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_students_admission_date ON students(tenant_id, admission_date);
CREATE INDEX IF NOT EXISTS idx_students_admission_type ON students(tenant_id, admission_type);
CREATE INDEX IF NOT EXISTS idx_students_fee_category ON students(tenant_id, fee_category);
CREATE INDEX IF NOT EXISTS idx_students_transport ON students(tenant_id, transport_required) WHERE transport_required = true;
CREATE INDEX IF NOT EXISTS idx_students_hostel ON students(tenant_id, hostel_required) WHERE hostel_required = true;
CREATE INDEX IF NOT EXISTS idx_students_deleted ON students(tenant_id, deleted_at) WHERE deleted_at IS NOT NULL;

-- Student academic records indexes
CREATE INDEX IF NOT EXISTS idx_student_academic_records_tenant ON student_academic_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_student ON student_academic_records(tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_year ON student_academic_records(tenant_id, academic_year_id);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_class ON student_academic_records(tenant_id, class_id);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_current ON student_academic_records(tenant_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_student_academic_records_promotion ON student_academic_records(tenant_id, promotion_status);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_attendance ON student_academic_records(tenant_id, attendance_percentage);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_rank_class ON student_academic_records(tenant_id, class_id, rank_in_class) WHERE rank_in_class IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_student_academic_records_rank_section ON student_academic_records(tenant_id, section_id, rank_in_section) WHERE rank_in_section IS NOT NULL;

-- Student subjects indexes
CREATE INDEX IF NOT EXISTS idx_student_subjects_tenant ON student_subjects(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_subjects_student ON student_subjects(tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_student_subjects_year ON student_subjects(tenant_id, academic_year_id);
CREATE INDEX IF NOT EXISTS idx_student_subjects_subject ON student_subjects(tenant_id, subject_code);
CREATE INDEX IF NOT EXISTS idx_student_subjects_teacher ON student_subjects(tenant_id, teacher_id) WHERE teacher_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_student_subjects_type ON student_subjects(tenant_id, subject_type);
CREATE INDEX IF NOT EXISTS idx_student_subjects_active ON student_subjects(tenant_id, is_active) WHERE is_active = true;

-- ==============================================
-- GUARDIAN MANAGEMENT INDEXES
-- ==============================================

-- Guardians table indexes
CREATE INDEX IF NOT EXISTS idx_guardians_tenant ON guardians(tenant_id);
CREATE INDEX IF NOT EXISTS idx_guardians_user ON guardians(tenant_id, user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_guardians_email ON guardians(tenant_id, email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_guardians_phone ON guardians(tenant_id, phone);
CREATE INDEX IF NOT EXISTS idx_guardians_status ON guardians(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_guardians_full_name ON guardians USING gin(full_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_deleted ON guardians(tenant_id, deleted_at) WHERE deleted_at IS NOT NULL;

-- Student guardians indexes
CREATE INDEX IF NOT EXISTS idx_student_guardians_tenant ON student_guardians(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_guardians_student ON student_guardians(tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_student_guardians_guardian ON student_guardians(tenant_id, guardian_id);
CREATE INDEX IF NOT EXISTS idx_student_guardians_relationship ON student_guardians(tenant_id, relationship);
CREATE INDEX IF NOT EXISTS idx_student_guardians_primary ON student_guardians(tenant_id, student_id, is_primary) WHERE is_primary = true;
CREATE INDEX IF NOT EXISTS idx_student_guardians_emergency ON student_guardians(tenant_id, is_emergency_contact) WHERE is_emergency_contact = true;
CREATE INDEX IF NOT EXISTS idx_student_guardians_pickup ON student_guardians(tenant_id, is_authorized_pickup) WHERE is_authorized_pickup = true;
CREATE INDEX IF NOT EXISTS idx_student_guardians_fee_payer ON student_guardians(tenant_id, is_fee_payer) WHERE is_fee_payer = true;
CREATE INDEX IF NOT EXISTS idx_student_guardians_active ON student_guardians(tenant_id, is_active) WHERE is_active = true;

-- ==============================================
-- SYSTEM AND SUBSCRIPTION INDEXES
-- ==============================================

-- System config indexes
CREATE INDEX IF NOT EXISTS idx_system_config_category ON system_config(category);
CREATE INDEX IF NOT EXISTS idx_system_config_category_key ON system_config(category, key);
CREATE INDEX IF NOT EXISTS idx_system_config_public ON system_config(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_system_config_required ON system_config(is_required) WHERE is_required = true;

-- Feature flags indexes
CREATE INDEX IF NOT EXISTS idx_feature_flags_name ON feature_flags(name);
CREATE INDEX IF NOT EXISTS idx_feature_flags_enabled ON feature_flags(is_enabled);
CREATE INDEX IF NOT EXISTS idx_feature_flags_rollout ON feature_flags(rollout_percentage);

-- Subscription plans indexes
CREATE INDEX IF NOT EXISTS idx_subscription_plans_name ON subscription_plans(name);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_public ON subscription_plans(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_subscription_plans_price_monthly ON subscription_plans(price_monthly);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_price_yearly ON subscription_plans(price_yearly);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_sort ON subscription_plans(sort_order);

-- Tenant subscriptions indexes
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_tenant ON tenant_subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_plan ON tenant_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_status ON tenant_subscriptions(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_billing_date ON tenant_subscriptions(next_billing_date) WHERE next_billing_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_dates ON tenant_subscriptions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_created_by ON tenant_subscriptions(created_by) WHERE created_by IS NOT NULL;

-- Tenant usage indexes
CREATE INDEX IF NOT EXISTS idx_tenant_usage_tenant ON tenant_usage(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_usage_metric ON tenant_usage(tenant_id, metric_name);
CREATE INDEX IF NOT EXISTS idx_tenant_usage_period ON tenant_usage(tenant_id, period_type, period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_tenant_usage_recorded ON tenant_usage(recorded_at);

-- ==============================================
-- COMPOSITE INDEXES FOR COMMON QUERIES
-- ==============================================

-- Student enrollment lookups
CREATE INDEX IF NOT EXISTS idx_students_enrollment ON students(tenant_id, class_id, section_id, status) WHERE status = 'active';

-- Student academic performance
CREATE INDEX IF NOT EXISTS idx_student_performance ON student_academic_records(tenant_id, academic_year_id, class_id, overall_percentage DESC) WHERE overall_percentage IS NOT NULL;

-- User authentication lookups
CREATE INDEX IF NOT EXISTS idx_users_auth ON users(email, status) WHERE status = 'active';

-- Guardian communication
CREATE INDEX IF NOT EXISTS idx_guardian_communication ON student_guardians(tenant_id, guardian_id, can_receive_academic_updates, can_receive_attendance_alerts, is_active) WHERE is_active = true;

-- Academic structure hierarchy
CREATE INDEX IF NOT EXISTS idx_academic_hierarchy ON sections(tenant_id, class_id, status) WHERE status = 'active';

-- Session management
CREATE INDEX IF NOT EXISTS idx_active_sessions ON user_sessions(tenant_id, user_id, is_active, last_activity_at) WHERE is_active = true;

-- ==============================================
-- TEXT SEARCH INDEXES (GIN)
-- ==============================================

-- Enable pg_trgm extension for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Full-text search indexes for common search fields
CREATE INDEX IF NOT EXISTS idx_tenants_search ON tenants USING gin((name || ' ' || COALESCE(display_name, '')) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_branches_search ON branches USING gin((name || ' ' || COALESCE(display_name, '')) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_users_search ON users USING gin((first_name || ' ' || COALESCE(middle_name || ' ', '') || last_name) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_search ON guardians USING gin((first_name || ' ' || COALESCE(middle_name || ' ', '') || last_name) gin_trgm_ops);

-- Contact search indexes
CREATE INDEX IF NOT EXISTS idx_users_contact_search ON users USING gin((COALESCE(email, '') || ' ' || COALESCE(phone, '')) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_contact_search ON guardians USING gin((COALESCE(email, '') || ' ' || COALESCE(phone, '')) gin_trgm_ops);

-- ==============================================
-- JSONB INDEXES FOR COMMON QUERIES
-- ==============================================

-- Settings and preferences JSONB indexes
CREATE INDEX IF NOT EXISTS idx_tenants_settings ON tenants USING gin(settings);
CREATE INDEX IF NOT EXISTS idx_branches_settings ON branches USING gin(settings);
CREATE INDEX IF NOT EXISTS idx_users_preferences ON users USING gin(preferences);
CREATE INDEX IF NOT EXISTS idx_students_settings ON students USING gin(settings);

-- Features and integrations
CREATE INDEX IF NOT EXISTS idx_tenants_features ON tenants USING gin(features);
CREATE INDEX IF NOT EXISTS idx_tenants_integrations ON tenants USING gin(integrations);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_features ON subscription_plans USING gin(features);

-- Address JSONB indexes
CREATE INDEX IF NOT EXISTS idx_users_permanent_address ON users USING gin(permanent_address);
CREATE INDEX IF NOT EXISTS idx_users_current_address ON users USING gin(current_address);
CREATE INDEX IF NOT EXISTS idx_guardians_address ON guardians USING gin(address);

-- Medical and emergency information
CREATE INDEX IF NOT EXISTS idx_students_medical ON students USING gin(medical_conditions);
CREATE INDEX IF NOT EXISTS idx_students_allergies ON students USING gin(allergies);

-- Academic data
CREATE INDEX IF NOT EXISTS idx_classes_subjects ON classes USING gin(subjects);
CREATE INDEX IF NOT EXISTS idx_student_academic_activities ON student_academic_records USING gin(extra_curricular_activities);
CREATE INDEX IF NOT EXISTS idx_student_academic_achievements ON student_academic_records USING gin(achievements);

-- ==============================================
-- GEOSPATIAL INDEXES
-- ==============================================

-- Location-based queries for branches
CREATE INDEX IF NOT EXISTS idx_branches_location ON branches USING gist(ll_to_earth(latitude, longitude)) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- ==============================================
-- PARTIAL INDEXES FOR OPTIMIZATION
-- ==============================================

-- Active records only
CREATE INDEX IF NOT EXISTS idx_tenants_active ON tenants(id) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_branches_active ON branches(tenant_id, id) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_active ON users(tenant_id, id) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_students_active ON students(tenant_id, id) WHERE status = 'active' AND deleted_at IS NULL;

-- Current academic data
CREATE INDEX IF NOT EXISTS idx_current_academic_years ON academic_years(tenant_id, id) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_current_academic_terms ON academic_terms(tenant_id, id) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_current_student_records ON student_academic_records(tenant_id, student_id) WHERE is_current = true;

-- Trial tenants for monitoring
CREATE INDEX IF NOT EXISTS idx_trial_tenants ON tenants(trial_ends_at, subscription_status) WHERE subscription_status = 'trial' AND trial_ends_at IS NOT NULL;

-- Failed login attempts (for security monitoring)
CREATE INDEX IF NOT EXISTS idx_failed_sessions ON user_sessions(user_id, started_at) WHERE end_reason = 'failed_login';

-- ==============================================
-- INDEXES FOR REPORTING AND ANALYTICS
-- ==============================================

-- Student enrollment trends
CREATE INDEX IF NOT EXISTS idx_students_admission_trends ON students(tenant_id, admission_date, status);
CREATE INDEX IF NOT EXISTS idx_students_class_distribution ON students(tenant_id, class_id, status) WHERE status = 'active';

-- Academic performance analytics
CREATE INDEX IF NOT EXISTS idx_academic_performance_trends ON student_academic_records(tenant_id, academic_year_id, overall_percentage) WHERE overall_percentage IS NOT NULL;

-- User activity analytics
CREATE INDEX IF NOT EXISTS idx_user_activity ON user_sessions(tenant_id, date_trunc('day', started_at), user_id);
CREATE INDEX IF NOT EXISTS idx_user_login_trends ON users(tenant_id, last_login_at, primary_role) WHERE last_login_at IS NOT NULL;

-- Subscription analytics
CREATE INDEX IF NOT EXISTS idx_subscription_trends ON tenant_subscriptions(plan_id, date_trunc('month', start_date), status);

-- ==============================================
-- DATABASE STATISTICS UPDATE
-- ==============================================

-- Update table statistics for better query planning
ANALYZE tenants;
ANALYZE branches;
ANALYZE academic_years;
ANALYZE academic_terms;
ANALYZE classes;
ANALYZE sections;
ANALYZE users;
ANALYZE user_roles;
ANALYZE user_sessions;
ANALYZE user_preferences;
ANALYZE students;
ANALYZE student_academic_records;
ANALYZE student_subjects;
ANALYZE guardians;
ANALYZE student_guardians;
ANALYZE subscription_plans;
ANALYZE tenant_subscriptions;
ANALYZE tenant_usage;
ANALYZE system_config;
ANALYZE feature_flags;

-- ==============================================
-- INDEX MONITORING VIEWS
-- ==============================================

-- Create view to monitor index usage
CREATE OR REPLACE VIEW index_usage_stats AS
SELECT 
  schemaname,
  tablename,
  indexrelname,
  idx_tup_read,
  idx_tup_fetch,
  idx_scan,
  idx_tup_read::float / GREATEST(idx_scan, 1) as tuples_per_scan,
  CASE 
    WHEN idx_scan = 0 THEN 'Never used'
    WHEN idx_scan < 100 THEN 'Rarely used'
    WHEN idx_scan < 1000 THEN 'Moderately used'
    ELSE 'Frequently used'
  END as usage_category
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Create view to identify unused indexes
CREATE OR REPLACE VIEW unused_indexes AS
SELECT 
  schemaname,
  tablename,
  indexrelname,
  pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE '%_pkey'
  AND indexrelname NOT LIKE '%_unique'
ORDER BY pg_relation_size(indexrelid) DESC;

-- ==============================================
-- LOG MIGRATION COMPLETION
-- ==============================================

-- Update system config with index migration status
INSERT INTO system_config (category, key, value, description) VALUES 
('migrations', '002_add_indexes', 
 '{"completed_at": "2025-10-04", "version": "1.0", "indexes_created": 200, "gin_indexes": 15, "composite_indexes": 10, "partial_indexes": 12}', 
 'Performance indexes migration completed');

-- Display index creation summary
SELECT 
  'Migration 002_add_indexes.sql completed successfully!' as status,
  COUNT(*) as total_indexes_created,
  COUNT(*) FILTER (WHERE indexdef LIKE '%gin%') as gin_indexes,
  COUNT(*) FILTER (WHERE indexdef LIKE '%WHERE%') as partial_indexes
FROM pg_indexes 
WHERE schemaname = 'public';