# SPEC-404: Payment Tracking & History System

> **Portal**: Vendor Portal  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Comprehensive payment tracking system showing payment status, payment history, pending payments, payment aging analysis, payment receipts, statement of accounts, and payment reconciliation with downloadable reports.

---

## 🎯 SUCCESS CRITERIA

✅ Real-time tracking operational
✅ Status updates reflecting correctly
✅ History and audit trail complete
✅ Alerts and notifications working
✅ Reports and analytics functional
✅ Data integrity maintained

---

## 📊 DATABASE SCHEMA

### Tables Required


#### `vendor_payments`
```sql
CREATE TABLE vendor_payments (
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


#### `payment_history`
```sql
CREATE TABLE payment_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `payment_receipts`
```sql
CREATE TABLE payment_receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `account_statements`
```sql
CREATE TABLE account_statements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `payment_reconciliation`
```sql
CREATE TABLE payment_reconciliation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `tds_deductions`
```sql
CREATE TABLE tds_deductions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `vendor_payments`: Index on `created_at`, `created_by`, frequently queried fields
- `payment_schedules`: Index on `created_at`, `created_by`, frequently queried fields
- `payment_history`: Index on `created_at`, `created_by`, frequently queried fields
- `payment_receipts`: Index on `created_at`, `created_by`, frequently queried fields
- `account_statements`: Index on `created_at`, `created_by`, frequently queried fields
- `payment_reconciliation`: Index on `created_at`, `created_by`, frequently queried fields
- `tds_deductions`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE vendor_payments ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE payment_schedules ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE payment_receipts ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE account_statements ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE payment_reconciliation ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE tds_deductions ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- vendor_payments policies
CREATE POLICY "Users can view own vendor_payments"
  ON vendor_payments FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_payments"
  ON vendor_payments FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_payments"
  ON vendor_payments FOR UPDATE
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
-- payment_history policies
CREATE POLICY "Users can view own payment_history"
  ON payment_history FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own payment_history"
  ON payment_history FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own payment_history"
  ON payment_history FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- payment_receipts policies
CREATE POLICY "Users can view own payment_receipts"
  ON payment_receipts FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own payment_receipts"
  ON payment_receipts FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own payment_receipts"
  ON payment_receipts FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- account_statements policies
CREATE POLICY "Users can view own account_statements"
  ON account_statements FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own account_statements"
  ON account_statements FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own account_statements"
  ON account_statements FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- payment_reconciliation policies
CREATE POLICY "Users can view own payment_reconciliation"
  ON payment_reconciliation FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own payment_reconciliation"
  ON payment_reconciliation FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own payment_reconciliation"
  ON payment_reconciliation FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- tds_deductions policies
CREATE POLICY "Users can view own tds_deductions"
  ON tds_deductions FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own tds_deductions"
  ON tds_deductions FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own tds_deductions"
  ON tds_deductions FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `PaymentTrackingHistorySystemAPI`

**Location**: `src/lib/api/payment-tracking-history-system-api.ts`

```typescript

export interface VendorPayments {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface VendorPaymentsCreate {
  // Add relevant fields for creation
}

export interface VendorPaymentsUpdate {
  // Add relevant fields for update
}


export class PaymentTrackingHistorySystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('vendor_payments')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('vendor_payments')
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
      .from('vendor_payments')
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
      .from('vendor_payments')
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
      .from('vendor_payments')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const payment_tracking_history_system_api = new PaymentTrackingHistorySystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `PaymentTrackingHistorySystem`

**Location**: `src/pages/01-vendor-portal/payment-tracking-history-system.tsx`

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
