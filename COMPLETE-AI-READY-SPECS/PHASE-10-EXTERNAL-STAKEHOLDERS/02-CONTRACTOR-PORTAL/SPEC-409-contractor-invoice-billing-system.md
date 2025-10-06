# SPEC-409: Contractor Invoice & Billing System

> **Portal**: Contractor Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 7 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Invoice and billing system for contractors to submit work completion invoices, track billing milestones, manage payment schedules, upload measurement sheets, handle retention amounts, and monitor payment status.

---

## 🎯 SUCCESS CRITERIA

✅ All core features implemented
✅ Data operations working correctly
✅ User interface complete and responsive
✅ Validation and error handling functional
✅ Security measures in place
✅ Performance requirements met

---

## 📊 DATABASE SCHEMA

### Tables Required


#### `contractor_invoices`
```sql
CREATE TABLE contractor_invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `billing_milestones`
```sql
CREATE TABLE billing_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `measurement_sheets`
```sql
CREATE TABLE measurement_sheets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `retention_amounts`
```sql
CREATE TABLE retention_amounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `payment_schedules`
```sql
CREATE TABLE payment_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `invoice_approval`
```sql
CREATE TABLE invoice_approval (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `deduction_records`
```sql
CREATE TABLE deduction_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `contractor_invoices`: Index on `created_at`, `created_by`, frequently queried fields
- `billing_milestones`: Index on `created_at`, `created_by`, frequently queried fields
- `measurement_sheets`: Index on `created_at`, `created_by`, frequently queried fields
- `retention_amounts`: Index on `created_at`, `created_by`, frequently queried fields
- `payment_schedules`: Index on `created_at`, `created_by`, frequently queried fields
- `invoice_approval`: Index on `created_at`, `created_by`, frequently queried fields
- `deduction_records`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE contractor_invoices ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE billing_milestones ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE measurement_sheets ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE retention_amounts ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE payment_schedules ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE invoice_approval ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE deduction_records ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- contractor_invoices policies
CREATE POLICY "Users can view own contractor_invoices"
  ON contractor_invoices FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own contractor_invoices"
  ON contractor_invoices FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own contractor_invoices"
  ON contractor_invoices FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- billing_milestones policies
CREATE POLICY "Users can view own billing_milestones"
  ON billing_milestones FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own billing_milestones"
  ON billing_milestones FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own billing_milestones"
  ON billing_milestones FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- measurement_sheets policies
CREATE POLICY "Users can view own measurement_sheets"
  ON measurement_sheets FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own measurement_sheets"
  ON measurement_sheets FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own measurement_sheets"
  ON measurement_sheets FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- retention_amounts policies
CREATE POLICY "Users can view own retention_amounts"
  ON retention_amounts FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own retention_amounts"
  ON retention_amounts FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own retention_amounts"
  ON retention_amounts FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- payment_schedules policies
CREATE POLICY "Users can view own payment_schedules"
  ON payment_schedules FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own payment_schedules"
  ON payment_schedules FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own payment_schedules"
  ON payment_schedules FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- invoice_approval policies
CREATE POLICY "Users can view own invoice_approval"
  ON invoice_approval FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own invoice_approval"
  ON invoice_approval FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own invoice_approval"
  ON invoice_approval FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- deduction_records policies
CREATE POLICY "Users can view own deduction_records"
  ON deduction_records FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own deduction_records"
  ON deduction_records FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own deduction_records"
  ON deduction_records FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `ContractorInvoiceBillingSystemAPI`

**Location**: `src/lib/api/contractor-invoice-billing-system-api.ts`

```typescript

export interface ContractorInvoices {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface ContractorInvoicesCreate {
  // Add relevant fields for creation
}

export interface ContractorInvoicesUpdate {
  // Add relevant fields for update
}


export class ContractorInvoiceBillingSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('contractor_invoices')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('contractor_invoices')
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
      .from('contractor_invoices')
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
      .from('contractor_invoices')
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
      .from('contractor_invoices')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const contractor_invoice_billing_system_api = new ContractorInvoiceBillingSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `ContractorInvoiceBillingSystem`

**Location**: `src/pages/02-contractor-portal/contractor-invoice-billing-system.tsx`

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

- **Dependencies**: Phase 1 (Foundation), Phase 2 (UI Components), SPEC-407 (Contractor Dashboard)
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
