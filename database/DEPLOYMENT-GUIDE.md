# 🚀 Database Deployment Guide

## Prerequisites

- Access to Supabase SQL Editor: https://supabase.com/dashboard/project/yduvzuklowctiyxxbzch/sql
- Service role key configured (already in .env.local)

## 📝 Deployment Steps

### Step 1: Execute Schema (Create Tables)

1. Open Supabase SQL Editor
2. Copy the contents of `database/complete-schema.sql`
3. Paste into SQL Editor
4. Click "Run" button
5. **Expected result**: ~30 tables created successfully

**Verify:**
- Go to "Table Editor" tab
- You should see: tenants, branches, users, students, parents, staff, etc.

---

### Step 2: Execute RLS Policies (Security)

**⚠️ IMPORTANT: Fixed auth schema permission issue**

The RLS policies have been updated to use `public` schema instead of `auth` schema to avoid permission errors.

1. Stay in Supabase SQL Editor
2. Copy the contents of `database/policies/rls-policies.sql`
3. Paste into SQL Editor
4. Click "Run" button
5. **Expected result**: 60+ RLS policies created successfully

**Verify:**
- Go to "Authentication" → "Policies"
- You should see policies for each table
- Functions should be in "Database" → "Functions" tab

---

### Step 3: Execute Functions & Triggers

1. Stay in Supabase SQL Editor
2. Copy the contents of `database/functions/database-functions.sql`
3. Paste into SQL Editor
4. Click "Run" button
5. **Expected result**: 20+ functions and 12 triggers created

**Verify:**
- Go to "Database" → "Functions"
- You should see: calculate_age, calculate_fee_balance, get_attendance_percentage, etc.

---

## 🔍 Verification Checklist

After deployment, verify the following:

### Tables Created (30+)
- [x] tenants
- [x] branches
- [x] users
- [x] students
- [x] parents
- [x] student_parents
- [x] staff
- [x] academic_years
- [x] classes
- [x] sections
- [x] subjects
- [x] class_subjects
- [x] student_attendance
- [x] staff_attendance
- [x] timetables
- [x] examinations
- [x] exam_schedules
- [x] student_marks
- [x] grade_definitions
- [x] fee_categories
- [x] fee_structures
- [x] student_fees
- [x] fee_payments
- [x] books
- [x] book_issues
- [x] vehicles
- [x] routes
- [x] student_transport
- [x] announcements
- [x] messages
- [x] audit_logs

### Helper Functions (6)
- [x] public.get_user_tenant_id()
- [x] public.get_user_branch_id()
- [x] public.get_user_role()
- [x] public.is_super_admin()
- [x] public.is_tenant_admin()
- [x] public.is_branch_admin()

### RLS Policies (60+)
- [x] Tenant isolation policies
- [x] Branch access policies
- [x] Student data protection
- [x] Staff data protection
- [x] Financial data security
- [x] Audit trail protection

### Business Logic Functions (20+)
- [x] calculate_age()
- [x] calculate_fee_balance()
- [x] get_attendance_percentage()
- [x] get_student_cgpa()
- [x] is_book_available()
- [x] get_class_strength()
- [x] Validation triggers (4)
- [x] Audit triggers (5)
- [x] Cascade triggers (3)
- [x] Reporting functions (3)
- [x] Performance functions (4)

---

## ⚠️ Troubleshooting

### Error: "permission denied for schema auth"

**Solution**: ✅ **FIXED** - The RLS policies file has been updated to use `public` schema instead of `auth` schema.

If you see this error:
```
ERROR: 42501: permission denied for schema auth
```

**It means you're using an old version of the file.** Make sure to use the latest `rls-policies.sql` from this commit.

---

### Error: "relation already exists"

This means the table/function was already created. Options:
1. Drop the existing object first: `DROP TABLE table_name CASCADE;`
2. Or modify the SQL to use `CREATE OR REPLACE` where applicable
3. Or start fresh by dropping all objects

---

### Error: "syntax error at or near..."

Check that you copied the ENTIRE file content without truncation. SQL files must be executed completely.

---

## 🧪 Test Deployment

After successful deployment, test the system:

### 1. Test User Registration

```bash
npm run dev
# Visit http://localhost:3000/auth/register
```

Try creating a new user account. It should:
- Create a record in `auth.users` (Supabase Auth)
- Trigger any necessary hooks
- Allow login afterward

### 2. Test Authentication

```bash
# Visit http://localhost:3000/auth/login
```

Try logging in with the created user. It should:
- Authenticate successfully
- Redirect to homepage or dashboard
- Session should persist

### 3. Test RLS Policies

Create a test query in SQL Editor:
```sql
-- This should only return data for the current user's tenant
SELECT * FROM students WHERE tenant_id = public.get_user_tenant_id();
```

---

## 🎯 Success Indicators

When deployment is successful, you should see:

1. **In Supabase Dashboard:**
   - 30+ tables in Table Editor
   - 60+ RLS policies in Authentication → Policies
   - 20+ functions in Database → Functions
   - No errors in SQL Editor

2. **In Application:**
   - User registration works
   - User login works
   - Session persists
   - Protected routes work

---

## 📚 Additional Resources

- **Supabase SQL Editor**: https://supabase.com/dashboard/project/yduvzuklowctiyxxbzch/sql
- **Supabase Docs - RLS**: https://supabase.com/docs/guides/auth/row-level-security
- **Supabase Docs - Functions**: https://supabase.com/docs/guides/database/functions

---

## 🆘 Need Help?

If you encounter issues:

1. Check Supabase logs in Dashboard → Logs
2. Review error messages carefully
3. Ensure you're running SQL as the database owner (default)
4. Try executing files one section at a time
5. Use transactions for safe testing:
   ```sql
   BEGIN;
   -- your SQL here
   ROLLBACK; -- or COMMIT if successful
   ```

---

**Deployment Status**: Ready for execution  
**Last Updated**: October 6, 2025  
**Schema Version**: 1.0.0
