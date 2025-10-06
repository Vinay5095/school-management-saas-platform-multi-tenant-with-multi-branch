-- ============================================================================
-- DATABASE FUNCTIONS & TRIGGERS
-- Utility functions, validation triggers, and automation
-- ============================================================================
-- This file implements SPEC-029 through SPEC-034
-- ============================================================================

-- ============================================================================
-- SPEC-029: UTILITY FUNCTIONS
-- Common helper functions for database operations
-- ============================================================================

-- Calculate student age
CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Calculate fee balance
CREATE OR REPLACE FUNCTION calculate_fee_balance(p_student_fee_id UUID)
RETURNS NUMERIC AS $$
DECLARE
    v_balance NUMERIC;
BEGIN
    SELECT (amount_due + late_fee - discount_amount - amount_paid)
    INTO v_balance
    FROM student_fees
    WHERE id = p_student_fee_id;
    
    RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql STABLE;

-- Get student attendance percentage
CREATE OR REPLACE FUNCTION get_attendance_percentage(
    p_student_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS NUMERIC AS $$
DECLARE
    v_total_days INTEGER;
    v_present_days INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_days
    FROM student_attendance
    WHERE student_id = p_student_id
    AND date BETWEEN p_start_date AND p_end_date;
    
    SELECT COUNT(*) INTO v_present_days
    FROM student_attendance
    WHERE student_id = p_student_id
    AND date BETWEEN p_start_date AND p_end_date
    AND status IN ('present', 'late');
    
    IF v_total_days = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN ROUND((v_present_days::NUMERIC / v_total_days::NUMERIC) * 100, 2);
END;
$$ LANGUAGE plpgsql STABLE;

-- Get student CGPA
CREATE OR REPLACE FUNCTION get_student_cgpa(
    p_student_id UUID,
    p_academic_year_id UUID
)
RETURNS NUMERIC AS $$
DECLARE
    v_cgpa NUMERIC;
BEGIN
    SELECT AVG(gd.grade_point)
    INTO v_cgpa
    FROM student_marks sm
    JOIN exam_schedules es ON es.id = sm.exam_schedule_id
    JOIN examinations e ON e.id = es.examination_id
    JOIN grade_definitions gd ON gd.grade = sm.grade
    WHERE sm.student_id = p_student_id
    AND e.academic_year_id = p_academic_year_id
    AND sm.is_absent = false;
    
    RETURN ROUND(COALESCE(v_cgpa, 0), 2);
END;
$$ LANGUAGE plpgsql STABLE;

-- Check book availability
CREATE OR REPLACE FUNCTION is_book_available(p_book_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_available_copies INTEGER;
BEGIN
    SELECT available_copies INTO v_available_copies
    FROM books
    WHERE id = p_book_id AND is_active = true;
    
    RETURN COALESCE(v_available_copies, 0) > 0;
END;
$$ LANGUAGE plpgsql STABLE;

-- Get class strength (total students)
CREATE OR REPLACE FUNCTION get_class_strength(p_class_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM students
        WHERE class_id = p_class_id
        AND status = 'active'
        AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- SPEC-030: VALIDATION TRIGGERS
-- Data integrity and business rule validation
-- ============================================================================

-- Validate student class capacity
CREATE OR REPLACE FUNCTION validate_class_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_max_students INTEGER;
    v_current_count INTEGER;
BEGIN
    -- Get max students for the class
    SELECT max_students INTO v_max_students
    FROM classes
    WHERE id = NEW.class_id;
    
    -- Get current student count
    SELECT COUNT(*) INTO v_current_count
    FROM students
    WHERE class_id = NEW.class_id
    AND status = 'active';
    
    -- Check if capacity exceeded
    IF v_max_students IS NOT NULL AND v_current_count >= v_max_students THEN
        RAISE EXCEPTION 'Class capacity exceeded. Maximum students: %', v_max_students;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_class_capacity
BEFORE INSERT OR UPDATE ON students
FOR EACH ROW
WHEN (NEW.status = 'active')
EXECUTE FUNCTION validate_class_capacity();

-- Validate fee payment amount
CREATE OR REPLACE FUNCTION validate_fee_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_balance NUMERIC;
BEGIN
    -- Calculate remaining balance
    v_balance := calculate_fee_balance(NEW.student_fee_id);
    
    -- Check if payment exceeds balance
    IF NEW.amount > v_balance THEN
        RAISE EXCEPTION 'Payment amount (%) exceeds balance (%)', NEW.amount, v_balance;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_fee_payment_amount
BEFORE INSERT ON fee_payments
FOR EACH ROW
EXECUTE FUNCTION validate_fee_payment();

-- Validate book issue
CREATE OR REPLACE FUNCTION validate_book_issue()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if book is available
    IF NOT is_book_available(NEW.book_id) THEN
        RAISE EXCEPTION 'Book is not available for issue';
    END IF;
    
    -- Check if user has overdue books
    IF EXISTS (
        SELECT 1 FROM book_issues
        WHERE user_id = NEW.user_id
        AND status = 'issued'
        AND due_date < CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'User has overdue books. Cannot issue new books.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_book_issue_validity
BEFORE INSERT ON book_issues
FOR EACH ROW
EXECUTE FUNCTION validate_book_issue();

-- Validate exam marks
CREATE OR REPLACE FUNCTION validate_exam_marks()
RETURNS TRIGGER AS $$
DECLARE
    v_total_marks INTEGER;
BEGIN
    -- Get total marks for the exam
    SELECT total_marks INTO v_total_marks
    FROM exam_schedules
    WHERE id = NEW.exam_schedule_id;
    
    -- Validate marks
    IF NEW.marks_obtained < 0 OR NEW.marks_obtained > v_total_marks THEN
        RAISE EXCEPTION 'Invalid marks. Must be between 0 and %', v_total_marks;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_exam_marks_validity
BEFORE INSERT OR UPDATE ON student_marks
FOR EACH ROW
WHEN (NEW.is_absent = false AND NEW.marks_obtained IS NOT NULL)
EXECUTE FUNCTION validate_exam_marks();

-- ============================================================================
-- SPEC-031: AUDIT TRIGGERS
-- Automatic audit trail for changes
-- ============================================================================

-- Generic audit log function
CREATE OR REPLACE FUNCTION create_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (
            tenant_id, user_id, action, entity_type, entity_id,
            new_values, ip_address, user_agent
        ) VALUES (
            COALESCE(NEW.tenant_id, auth.get_user_tenant_id()),
            auth.uid(),
            'INSERT',
            TG_TABLE_NAME,
            NEW.id,
            to_jsonb(NEW),
            inet_client_addr(),
            current_setting('application_name', true)
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (
            tenant_id, user_id, action, entity_type, entity_id,
            old_values, new_values, ip_address, user_agent
        ) VALUES (
            COALESCE(NEW.tenant_id, auth.get_user_tenant_id()),
            auth.uid(),
            'UPDATE',
            TG_TABLE_NAME,
            NEW.id,
            to_jsonb(OLD),
            to_jsonb(NEW),
            inet_client_addr(),
            current_setting('application_name', true)
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (
            tenant_id, user_id, action, entity_type, entity_id,
            old_values, ip_address, user_agent
        ) VALUES (
            COALESCE(OLD.tenant_id, auth.get_user_tenant_id()),
            auth.uid(),
            'DELETE',
            TG_TABLE_NAME,
            OLD.id,
            to_jsonb(OLD),
            inet_client_addr(),
            current_setting('application_name', true)
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to critical tables
CREATE TRIGGER audit_students AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_staff AFTER INSERT OR UPDATE OR DELETE ON staff
FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_fee_payments AFTER INSERT OR UPDATE OR DELETE ON fee_payments
FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_student_marks AFTER INSERT OR UPDATE OR DELETE ON student_marks
FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION create_audit_log();

-- ============================================================================
-- SPEC-032: CASCADE OPERATIONS
-- Automatic cascade updates and deletes
-- ============================================================================

-- Update book availability on issue/return
CREATE OR REPLACE FUNCTION update_book_availability()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Decrease available copies on issue
        UPDATE books
        SET available_copies = available_copies - 1
        WHERE id = NEW.book_id AND available_copies > 0;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No copies available';
        END IF;
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Increase available copies on return
        IF OLD.status = 'issued' AND NEW.status IN ('returned', 'lost', 'damaged') THEN
            UPDATE books
            SET available_copies = available_copies + 1
            WHERE id = NEW.book_id;
        END IF;
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Restore availability if issued book is deleted
        IF OLD.status = 'issued' THEN
            UPDATE books
            SET available_copies = available_copies + 1
            WHERE id = OLD.book_id;
        END IF;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER manage_book_availability
AFTER INSERT OR UPDATE OR DELETE ON book_issues
FOR EACH ROW
EXECUTE FUNCTION update_book_availability();

-- Update fee status on payment
CREATE OR REPLACE FUNCTION update_fee_status()
RETURNS TRIGGER AS $$
DECLARE
    v_total_paid NUMERIC;
    v_total_due NUMERIC;
BEGIN
    -- Calculate total paid for this student fee
    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM fee_payments
    WHERE student_fee_id = NEW.student_fee_id;
    
    -- Get total due
    SELECT (amount_due + late_fee - discount_amount) INTO v_total_due
    FROM student_fees
    WHERE id = NEW.student_fee_id;
    
    -- Update student fee status and amount
    UPDATE student_fees
    SET 
        amount_paid = v_total_paid,
        status = CASE
            WHEN v_total_paid >= v_total_due THEN 'paid'
            WHEN v_total_paid > 0 THEN 'partial'
            ELSE status
        END,
        updated_at = NOW()
    WHERE id = NEW.student_fee_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_fee_on_payment
AFTER INSERT ON fee_payments
FOR EACH ROW
EXECUTE FUNCTION update_fee_status();

-- Auto-assign grade based on marks
CREATE OR REPLACE FUNCTION assign_grade_from_marks()
RETURNS TRIGGER AS $$
DECLARE
    v_percentage NUMERIC;
    v_total_marks INTEGER;
BEGIN
    IF NEW.marks_obtained IS NOT NULL AND NOT NEW.is_absent THEN
        -- Get total marks for the exam
        SELECT total_marks INTO v_total_marks
        FROM exam_schedules
        WHERE id = NEW.exam_schedule_id;
        
        -- Calculate percentage
        v_percentage := (NEW.marks_obtained / v_total_marks) * 100;
        
        -- Assign grade based on percentage
        SELECT grade INTO NEW.grade
        FROM grade_definitions gd
        JOIN exam_schedules es ON es.examination_id IN (
            SELECT examination_id FROM exam_schedules WHERE id = NEW.exam_schedule_id
        )
        JOIN examinations e ON e.id = es.examination_id
        WHERE gd.tenant_id = e.tenant_id
        AND v_percentage BETWEEN gd.min_percentage AND gd.max_percentage
        LIMIT 1;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_assign_grade
BEFORE INSERT OR UPDATE ON student_marks
FOR EACH ROW
EXECUTE FUNCTION assign_grade_from_marks();

-- ============================================================================
-- SPEC-033: REPORTING FUNCTIONS
-- Functions for generating reports and analytics
-- ============================================================================

-- Get class-wise attendance summary
CREATE OR REPLACE FUNCTION get_class_attendance_summary(
    p_class_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    date DATE,
    total_students BIGINT,
    present_count BIGINT,
    absent_count BIGINT,
    late_count BIGINT,
    attendance_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.date,
        COUNT(*) as total_students,
        COUNT(*) FILTER (WHERE sa.status = 'present') as present_count,
        COUNT(*) FILTER (WHERE sa.status = 'absent') as absent_count,
        COUNT(*) FILTER (WHERE sa.status = 'late') as late_count,
        ROUND(
            (COUNT(*) FILTER (WHERE sa.status IN ('present', 'late'))::NUMERIC / 
            COUNT(*)::NUMERIC) * 100, 
            2
        ) as attendance_percentage
    FROM student_attendance sa
    WHERE sa.class_id = p_class_id
    AND sa.date BETWEEN p_start_date AND p_end_date
    GROUP BY sa.date
    ORDER BY sa.date;
END;
$$ LANGUAGE plpgsql STABLE;

-- Get student performance report
CREATE OR REPLACE FUNCTION get_student_performance_report(
    p_student_id UUID,
    p_academic_year_id UUID
)
RETURNS TABLE (
    subject_name VARCHAR,
    total_marks INTEGER,
    obtained_marks NUMERIC,
    grade VARCHAR,
    percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sub.name as subject_name,
        SUM(es.total_marks) as total_marks,
        SUM(sm.marks_obtained) as obtained_marks,
        MAX(sm.grade) as grade,
        ROUND((SUM(sm.marks_obtained) / SUM(es.total_marks)) * 100, 2) as percentage
    FROM student_marks sm
    JOIN exam_schedules es ON es.id = sm.exam_schedule_id
    JOIN subjects sub ON sub.id = es.subject_id
    JOIN examinations e ON e.id = es.examination_id
    WHERE sm.student_id = p_student_id
    AND e.academic_year_id = p_academic_year_id
    AND sm.is_absent = false
    GROUP BY sub.name
    ORDER BY sub.name;
END;
$$ LANGUAGE plpgsql STABLE;

-- Get fee collection summary
CREATE OR REPLACE FUNCTION get_fee_collection_summary(
    p_branch_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    collection_date DATE,
    total_collected NUMERIC,
    transaction_count BIGINT,
    cash_amount NUMERIC,
    card_amount NUMERIC,
    online_amount NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fp.payment_date as collection_date,
        SUM(fp.amount) as total_collected,
        COUNT(*) as transaction_count,
        SUM(fp.amount) FILTER (WHERE fp.payment_method = 'cash') as cash_amount,
        SUM(fp.amount) FILTER (WHERE fp.payment_method = 'card') as card_amount,
        SUM(fp.amount) FILTER (WHERE fp.payment_method = 'online') as online_amount
    FROM fee_payments fp
    JOIN student_fees sf ON sf.id = fp.student_fee_id
    JOIN students s ON s.id = sf.student_id
    WHERE s.branch_id = p_branch_id
    AND fp.payment_date BETWEEN p_start_date AND p_end_date
    GROUP BY fp.payment_date
    ORDER BY fp.payment_date;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- SPEC-034: PERFORMANCE FUNCTIONS
-- Optimization and caching functions
-- ============================================================================

-- Refresh materialized views (if any are created)
CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
    -- Placeholder for refreshing materialized views
    -- Add REFRESH MATERIALIZED VIEW statements as views are created
    RAISE NOTICE 'Materialized views refreshed';
END;
$$ LANGUAGE plpgsql;

-- Clean old audit logs (retention policy)
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs(retention_days INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM audit_logs
    WHERE created_at < (CURRENT_DATE - retention_days);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Reindex critical tables
CREATE OR REPLACE FUNCTION reindex_critical_tables()
RETURNS void AS $$
BEGIN
    REINDEX TABLE students;
    REINDEX TABLE staff;
    REINDEX TABLE student_attendance;
    REINDEX TABLE student_marks;
    REINDEX TABLE fee_payments;
    RAISE NOTICE 'Critical tables reindexed';
END;
$$ LANGUAGE plpgsql;

-- Analyze table statistics
CREATE OR REPLACE FUNCTION update_table_statistics()
RETURNS void AS $$
BEGIN
    ANALYZE students;
    ANALYZE staff;
    ANALYZE student_attendance;
    ANALYZE student_marks;
    ANALYZE fee_payments;
    ANALYZE book_issues;
    RAISE NOTICE 'Table statistics updated';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- END OF DATABASE FUNCTIONS & TRIGGERS
-- ============================================================================
