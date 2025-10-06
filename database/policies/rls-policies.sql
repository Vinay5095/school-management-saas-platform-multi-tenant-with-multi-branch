-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Multi-Tenant Isolation & Role-Based Access Control
-- ============================================================================
-- This file implements SPEC-021 through SPEC-028
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE examinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_marks ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_transport ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SPEC-021: AUTH HELPER FUNCTIONS
-- Functions to get current user context
-- ============================================================================

-- Get current user's tenant_id
CREATE OR REPLACE FUNCTION public.get_user_tenant_id()
RETURNS UUID AS $$
BEGIN
    RETURN (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's branch_id
CREATE OR REPLACE FUNCTION public.get_user_branch_id()
RETURNS UUID AS $$
BEGIN
    RETURN (auth.jwt() -> 'app_metadata' ->> 'branch_id')::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's role
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
BEGIN
    RETURN auth.jwt() -> 'app_metadata' ->> 'role';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is super admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role() = 'super_admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is tenant admin
CREATE OR REPLACE FUNCTION public.is_tenant_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role() IN ('super_admin', 'tenant_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is branch admin
CREATE OR REPLACE FUNCTION public.is_branch_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role() IN ('super_admin', 'tenant_admin', 'branch_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SPEC-022: TENANT ISOLATION POLICIES
-- Ensure strict tenant-level data isolation
-- ============================================================================

-- Tenants: Super admins see all, others see only their tenant
CREATE POLICY tenant_isolation_policy ON tenants
    FOR ALL
    USING (
        public.is_super_admin() 
        OR id = public.get_user_tenant_id()
    );

-- Branches: Tenant-level isolation
CREATE POLICY branch_tenant_isolation_policy ON branches
    FOR ALL
    USING (
        public.is_super_admin()
        OR tenant_id = public.get_user_tenant_id()
    );

-- Users: Tenant-level isolation
CREATE POLICY user_tenant_isolation_policy ON users
    FOR ALL
    USING (
        public.is_super_admin()
        OR tenant_id = public.get_user_tenant_id()
    );

-- ============================================================================
-- SPEC-023: RBAC (ROLE-BASED ACCESS CONTROL) POLICIES
-- Define access based on user roles
-- ============================================================================

-- Students: Can read own data, admins can manage
CREATE POLICY student_select_policy ON students
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR user_id = auth.uid()
        OR user_id IN (
            SELECT parent_id FROM student_parents 
            WHERE student_id = id
        )
    );

CREATE POLICY student_insert_policy ON students
    FOR INSERT
    WITH CHECK (public.is_branch_admin());

CREATE POLICY student_update_policy ON students
    FOR UPDATE
    USING (public.is_branch_admin());

CREATE POLICY student_delete_policy ON students
    FOR DELETE
    USING (public.is_tenant_admin());

-- Staff: Can read own data, admins can manage
CREATE POLICY staff_select_policy ON staff
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR user_id = auth.uid()
    );

CREATE POLICY staff_insert_policy ON staff
    FOR INSERT
    WITH CHECK (public.is_branch_admin());

CREATE POLICY staff_update_policy ON staff
    FOR UPDATE
    USING (public.is_branch_admin());

CREATE POLICY staff_delete_policy ON staff
    FOR DELETE
    USING (public.is_tenant_admin());

-- ============================================================================
-- SPEC-024: BRANCH ACCESS POLICIES
-- Branch-level data isolation
-- ============================================================================

-- Academic years: Branch-level access
CREATE POLICY academic_year_branch_policy ON academic_years
    FOR ALL
    USING (
        public.is_super_admin()
        OR (tenant_id = public.get_user_tenant_id() 
            AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id()))
    );

-- Classes: Branch-level access
CREATE POLICY class_branch_policy ON classes
    FOR ALL
    USING (
        public.is_super_admin()
        OR (tenant_id = public.get_user_tenant_id() 
            AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id()))
    );

-- Subjects: Branch-level access
CREATE POLICY subject_branch_policy ON subjects
    FOR ALL
    USING (
        public.is_super_admin()
        OR (tenant_id = public.get_user_tenant_id() 
            AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id()))
    );

-- ============================================================================
-- SPEC-025: STUDENT DATA POLICIES
-- Protect student information
-- ============================================================================

-- Student attendance: Students/parents read-only, teachers/admins manage
CREATE POLICY student_attendance_select_policy ON student_attendance
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR student_id IN (
            SELECT s.id FROM students s WHERE s.user_id = auth.uid()
        )
        OR student_id IN (
            SELECT sp.student_id FROM student_parents sp
            JOIN parents p ON p.id = sp.parent_id
            WHERE p.user_id = auth.uid()
        )
        OR marked_by IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid()
        )
    );

CREATE POLICY student_attendance_insert_policy ON student_attendance
    FOR INSERT
    WITH CHECK (
        public.is_branch_admin()
        OR marked_by IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid() AND st.is_teaching_staff = true
        )
    );

-- Student marks: Controlled access
CREATE POLICY student_marks_select_policy ON student_marks
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR student_id IN (
            SELECT s.id FROM students s WHERE s.user_id = auth.uid()
        )
        OR student_id IN (
            SELECT sp.student_id FROM student_parents sp
            JOIN parents p ON p.id = sp.parent_id
            WHERE p.user_id = auth.uid()
        )
        OR entered_by IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid()
        )
    );

CREATE POLICY student_marks_insert_policy ON student_marks
    FOR INSERT
    WITH CHECK (
        public.is_branch_admin()
        OR entered_by IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid() AND st.is_teaching_staff = true
        )
    );

-- ============================================================================
-- SPEC-026: STAFF DATA POLICIES
-- Protect staff information
-- ============================================================================

-- Staff attendance: Self and admins
CREATE POLICY staff_attendance_select_policy ON staff_attendance
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR staff_id IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid()
        )
    );

CREATE POLICY staff_attendance_insert_policy ON staff_attendance
    FOR INSERT
    WITH CHECK (
        staff_id IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid()
        )
        OR public.is_branch_admin()
    );

-- Timetables: Teachers see own schedules, admins manage all
CREATE POLICY timetable_select_policy ON timetables
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR teacher_id IN (
            SELECT st.id FROM staff st WHERE st.user_id = auth.uid()
        )
        OR class_id IN (
            SELECT s.class_id FROM students s WHERE s.user_id = auth.uid()
        )
    );

CREATE POLICY timetable_manage_policy ON timetables
    FOR ALL
    USING (public.is_branch_admin());

-- ============================================================================
-- SPEC-027: FINANCIAL DATA POLICIES
-- Strict access control for financial information
-- ============================================================================

-- Fee categories: Admins only
CREATE POLICY fee_category_policy ON fee_categories
    FOR ALL
    USING (public.is_branch_admin());

-- Fee structures: Admins only
CREATE POLICY fee_structure_policy ON fee_structures
    FOR ALL
    USING (public.is_branch_admin());

-- Student fees: Students/parents read-only, admins/accountants manage
CREATE POLICY student_fees_select_policy ON student_fees
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR student_id IN (
            SELECT s.id FROM students s WHERE s.user_id = auth.uid()
        )
        OR student_id IN (
            SELECT sp.student_id FROM student_parents sp
            JOIN parents p ON p.id = sp.parent_id
            WHERE p.user_id = auth.uid()
        )
    );

CREATE POLICY student_fees_manage_policy ON student_fees
    FOR ALL
    USING (
        public.is_branch_admin()
        OR public.get_user_role() = 'staff' -- Accountants have staff role
    );

-- Fee payments: Restricted access
CREATE POLICY fee_payment_select_policy ON fee_payments
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR student_fee_id IN (
            SELECT sf.id FROM student_fees sf
            JOIN students s ON s.id = sf.student_id
            WHERE s.user_id = auth.uid()
        )
        OR student_fee_id IN (
            SELECT sf.id FROM student_fees sf
            JOIN students s ON s.id = sf.student_id
            JOIN student_parents sp ON sp.student_id = s.id
            JOIN parents p ON p.id = sp.parent_id
            WHERE p.user_id = auth.uid()
        )
    );

CREATE POLICY fee_payment_insert_policy ON fee_payments
    FOR INSERT
    WITH CHECK (
        public.is_branch_admin()
        OR public.get_user_role() = 'staff'
    );

-- ============================================================================
-- SPEC-028: AUDIT TRAIL POLICIES
-- Audit logs are append-only and readable by admins
-- ============================================================================

-- Audit logs: Admins can read, system can write
CREATE POLICY audit_log_select_policy ON audit_logs
    FOR SELECT
    USING (public.is_tenant_admin());

CREATE POLICY audit_log_insert_policy ON audit_logs
    FOR INSERT
    WITH CHECK (true); -- Allow system to insert

-- Prevent updates and deletes on audit logs
CREATE POLICY audit_log_no_update_policy ON audit_logs
    FOR UPDATE
    USING (false);

CREATE POLICY audit_log_no_delete_policy ON audit_logs
    FOR DELETE
    USING (false);

-- ============================================================================
-- COMMUNICATION POLICIES
-- Announcements and messages
-- ============================================================================

-- Announcements: Everyone can read, admins can manage
CREATE POLICY announcement_select_policy ON announcements
    FOR SELECT
    USING (
        tenant_id = public.get_user_tenant_id()
        AND (branch_id IS NULL OR branch_id = public.get_user_branch_id())
        AND published_at IS NOT NULL
        AND (expires_at IS NULL OR expires_at > NOW())
    );

CREATE POLICY announcement_manage_policy ON announcements
    FOR ALL
    USING (public.is_branch_admin());

-- Messages: Sender and recipient only
CREATE POLICY message_select_policy ON messages
    FOR SELECT
    USING (
        tenant_id = public.get_user_tenant_id()
        AND (sender_id = auth.uid() OR recipient_id = auth.uid())
    );

CREATE POLICY message_insert_policy ON messages
    FOR INSERT
    WITH CHECK (
        tenant_id = public.get_user_tenant_id()
        AND sender_id = auth.uid()
    );

-- ============================================================================
-- LIBRARY POLICIES
-- Book management and circulation
-- ============================================================================

-- Books: Everyone can read, admins manage
CREATE POLICY book_select_policy ON books
    FOR SELECT
    USING (
        tenant_id = public.get_user_tenant_id()
        AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id())
    );

CREATE POLICY book_manage_policy ON books
    FOR ALL
    USING (public.is_branch_admin());

-- Book issues: Users see own issues, librarians see all
CREATE POLICY book_issue_select_policy ON book_issues
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR public.is_branch_admin()
        OR public.get_user_role() = 'staff' -- Librarians
    );

CREATE POLICY book_issue_manage_policy ON book_issues
    FOR ALL
    USING (
        public.is_branch_admin()
        OR public.get_user_role() = 'staff'
    );

-- ============================================================================
-- TRANSPORT POLICIES
-- Vehicle and route management
-- ============================================================================

-- Vehicles: Branch-level access
CREATE POLICY vehicle_policy ON vehicles
    FOR ALL
    USING (
        public.is_super_admin()
        OR (tenant_id = public.get_user_tenant_id() 
            AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id()))
    );

-- Routes: Branch-level access
CREATE POLICY route_policy ON routes
    FOR ALL
    USING (
        public.is_super_admin()
        OR (tenant_id = public.get_user_tenant_id() 
            AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id()))
    );

-- Student transport: Students/parents read, admins manage
CREATE POLICY student_transport_select_policy ON student_transport
    FOR SELECT
    USING (
        public.is_branch_admin()
        OR student_id IN (
            SELECT s.id FROM students s WHERE s.user_id = auth.uid()
        )
        OR student_id IN (
            SELECT sp.student_id FROM student_parents sp
            JOIN parents p ON p.id = sp.parent_id
            WHERE p.user_id = auth.uid()
        )
    );

CREATE POLICY student_transport_manage_policy ON student_transport
    FOR ALL
    USING (public.is_branch_admin());

-- ============================================================================
-- EXAMINATION POLICIES
-- Exam management and results
-- ============================================================================

-- Examinations: Admins manage, teachers/students read
CREATE POLICY examination_select_policy ON examinations
    FOR SELECT
    USING (
        tenant_id = public.get_user_tenant_id()
        AND (public.is_tenant_admin() OR branch_id = public.get_user_branch_id())
    );

CREATE POLICY examination_manage_policy ON examinations
    FOR ALL
    USING (public.is_branch_admin());

-- Exam schedules: Teachers and students can read, admins manage
CREATE POLICY exam_schedule_select_policy ON exam_schedules
    FOR SELECT
    USING (
        examination_id IN (
            SELECT e.id FROM examinations e
            WHERE e.tenant_id = public.get_user_tenant_id()
        )
    );

CREATE POLICY exam_schedule_manage_policy ON exam_schedules
    FOR ALL
    USING (public.is_branch_admin());

-- ============================================================================
-- END OF RLS POLICIES
-- ============================================================================
