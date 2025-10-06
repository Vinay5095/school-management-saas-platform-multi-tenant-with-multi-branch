# SPEC-403: Invoice Submission & Management System

> **Portal**: Vendor Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 8 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Advanced invoice management system enabling vendors to create and submit invoices against purchase orders, upload supporting documents, track invoice approval workflow, manage invoice revisions, and monitor payment status with automated calculations.

---

## 🎯 SUCCESS CRITERIA

✅ All CRUD operations functional
✅ Data validation working correctly
✅ Search and filtering operational
✅ Workflows and approvals functional
✅ Notifications sending properly
✅ Reports generating accurately

---

## 📊 DATABASE SCHEMA

### Tables Required


#### `vendor_invoices`
```sql
CREATE TABLE vendor_invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `invoice_items`
```sql
CREATE TABLE invoice_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `invoice_documents`
```sql
CREATE TABLE invoice_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `invoice_approval_history`
```sql
CREATE TABLE invoice_approval_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `invoice_revisions`
```sql
CREATE TABLE invoice_revisions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `payment_tracking`
```sql
CREATE TABLE payment_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `tax_calculations`
```sql
CREATE TABLE tax_calculations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `vendor_invoices`: Index on `created_at`, `created_by`, frequently queried fields
- `invoice_items`: Index on `created_at`, `created_by`, frequently queried fields
- `invoice_documents`: Index on `created_at`, `created_by`, frequently queried fields
- `invoice_approval_history`: Index on `created_at`, `created_by`, frequently queried fields
- `invoice_revisions`: Index on `created_at`, `created_by`, frequently queried fields
- `payment_tracking`: Index on `created_at`, `created_by`, frequently queried fields
- `tax_calculations`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE vendor_invoices ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE invoice_documents ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE invoice_approval_history ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE invoice_revisions ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE payment_tracking ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE tax_calculations ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- vendor_invoices policies
CREATE POLICY "Users can view own vendor_invoices"
  ON vendor_invoices FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_invoices"
  ON vendor_invoices FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_invoices"
  ON vendor_invoices FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- invoice_items policies
CREATE POLICY "Users can view own invoice_items"
  ON invoice_items FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own invoice_items"
  ON invoice_items FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own invoice_items"
  ON invoice_items FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- invoice_documents policies
CREATE POLICY "Users can view own invoice_documents"
  ON invoice_documents FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own invoice_documents"
  ON invoice_documents FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own invoice_documents"
  ON invoice_documents FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- invoice_approval_history policies
CREATE POLICY "Users can view own invoice_approval_history"
  ON invoice_approval_history FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own invoice_approval_history"
  ON invoice_approval_history FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own invoice_approval_history"
  ON invoice_approval_history FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- invoice_revisions policies
CREATE POLICY "Users can view own invoice_revisions"
  ON invoice_revisions FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own invoice_revisions"
  ON invoice_revisions FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own invoice_revisions"
  ON invoice_revisions FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- payment_tracking policies
CREATE POLICY "Users can view own payment_tracking"
  ON payment_tracking FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own payment_tracking"
  ON payment_tracking FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own payment_tracking"
  ON payment_tracking FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- tax_calculations policies
CREATE POLICY "Users can view own tax_calculations"
  ON tax_calculations FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own tax_calculations"
  ON tax_calculations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own tax_calculations"
  ON tax_calculations FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `InvoiceSubmissionManagementSystemAPI`

**Location**: `src/lib/api/invoice-submission-management-system-api.ts`

```typescript

export interface VendorInvoices {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface VendorInvoicesCreate {
  // Add relevant fields for creation
}

export interface VendorInvoicesUpdate {
  // Add relevant fields for update
}


export class InvoiceSubmissionManagementSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('vendor_invoices')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('vendor_invoices')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data as MainEntity;
  }

  async create(data: Partial<MainEntity>): Promise<MainEntity> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: created, error } = await this.supabase
      .from('vendor_invoices')
      .insert({
        ...data,
        created_by: user.id,
        updated_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return created as MainEntity;
  }

  async update(id: string, data: Partial<MainEntity>): Promise<MainEntity> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: updated, error } = await this.supabase
      .from('vendor_invoices')
      .update({
        ...data,
        updated_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return updated as MainEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase
      .from('vendor_invoices')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const invoice_submission_management_system_api = new InvoiceSubmissionManagementSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `InvoiceSubmissionManagementSystem`

**Location**: `src/pages/01-vendor-portal/invoice-submission-management-system.tsx`

**Features**:
- Clean, modern interface
- Real-time data updates
- Responsive design
- Error handling
- Loading states
- Form validation
- Success notifications

---

## 🔗 INTEGRATION POINTS

- **Dependencies**: Phase 1 (Foundation), Phase 2 (UI Components), SPEC-401 (Vendor Dashboard)
- **Related Specs**: Cross-portal integration where applicable
- **External Systems**: Email/SMS notifications, File storage

---

## 📱 USER INTERFACE REQUIREMENTS

### Layout
- Consistent with portal design system
- Responsive grid layout
- Mobile-friendly interface

### Components Needed
- Data tables with sorting/filtering
- Forms with validation
- Modal dialogs
- Status indicators
- Action buttons
- Search functionality

---

## ✅ VALIDATION RULES

- Required field validation
- Data type validation
- Business rule validation
- Permission checks
- Duplicate prevention
- Date range validation

---

## 🔒 SECURITY & PERMISSIONS

- Role-based access control
- RLS policies enforced
- Audit trail logging
- Secure data handling
- Session management

---

## 📈 PERFORMANCE REQUIREMENTS

- Page load < 2 seconds
- API response < 500ms
- Real-time updates
- Optimized queries
- Efficient pagination

---

## 🧪 TESTING REQUIREMENTS

### Unit Tests
- API method testing
- Validation logic
- Business rules

### Integration Tests
- Database operations
- API endpoints
- Authentication flow

### UI Tests
- Component rendering
- User interactions
- Form submissions

---

## 📝 ACCEPTANCE CRITERIA

- [ ] Database schema created
- [ ] RLS policies active
- [ ] API layer functional
- [ ] UI components complete
- [ ] All features working
- [ ] Tests passing
- [ ] Documentation complete
- [ ] Security audit passed

---

**Ready for autonomous AI agent development** ✅
