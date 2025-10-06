# SPEC-402: Purchase Order Management System

> **Portal**: Vendor Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 8 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Complete purchase order lifecycle management allowing vendors to view, accept/reject orders, track delivery status, update shipping information, manage order modifications, and handle partial deliveries with real-time status updates.

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


#### `purchase_orders`
```sql
CREATE TABLE purchase_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `purchase_order_items`
```sql
CREATE TABLE purchase_order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `order_acceptance`
```sql
CREATE TABLE order_acceptance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `delivery_updates`
```sql
CREATE TABLE delivery_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `order_modifications`
```sql
CREATE TABLE order_modifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `delivery_schedule`
```sql
CREATE TABLE delivery_schedule (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `order_status_history`
```sql
CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `purchase_orders`: Index on `created_at`, `created_by`, frequently queried fields
- `purchase_order_items`: Index on `created_at`, `created_by`, frequently queried fields
- `order_acceptance`: Index on `created_at`, `created_by`, frequently queried fields
- `delivery_updates`: Index on `created_at`, `created_by`, frequently queried fields
- `order_modifications`: Index on `created_at`, `created_by`, frequently queried fields
- `delivery_schedule`: Index on `created_at`, `created_by`, frequently queried fields
- `order_status_history`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE order_acceptance ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE delivery_updates ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE order_modifications ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE delivery_schedule ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- purchase_orders policies
CREATE POLICY "Users can view own purchase_orders"
  ON purchase_orders FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own purchase_orders"
  ON purchase_orders FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own purchase_orders"
  ON purchase_orders FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- purchase_order_items policies
CREATE POLICY "Users can view own purchase_order_items"
  ON purchase_order_items FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own purchase_order_items"
  ON purchase_order_items FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own purchase_order_items"
  ON purchase_order_items FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- order_acceptance policies
CREATE POLICY "Users can view own order_acceptance"
  ON order_acceptance FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own order_acceptance"
  ON order_acceptance FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own order_acceptance"
  ON order_acceptance FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- delivery_updates policies
CREATE POLICY "Users can view own delivery_updates"
  ON delivery_updates FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own delivery_updates"
  ON delivery_updates FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own delivery_updates"
  ON delivery_updates FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- order_modifications policies
CREATE POLICY "Users can view own order_modifications"
  ON order_modifications FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own order_modifications"
  ON order_modifications FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own order_modifications"
  ON order_modifications FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- delivery_schedule policies
CREATE POLICY "Users can view own delivery_schedule"
  ON delivery_schedule FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own delivery_schedule"
  ON delivery_schedule FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own delivery_schedule"
  ON delivery_schedule FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- order_status_history policies
CREATE POLICY "Users can view own order_status_history"
  ON order_status_history FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own order_status_history"
  ON order_status_history FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own order_status_history"
  ON order_status_history FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `PurchaseOrderManagementSystemAPI`

**Location**: `src/lib/api/purchase-order-management-system-api.ts`

```typescript

export interface PurchaseOrders {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface PurchaseOrdersCreate {
  // Add relevant fields for creation
}

export interface PurchaseOrdersUpdate {
  // Add relevant fields for update
}


export class PurchaseOrderManagementSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('purchase_orders')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('purchase_orders')
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
      .from('purchase_orders')
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
      .from('purchase_orders')
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
      .from('purchase_orders')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const purchase_order_management_system_api = new PurchaseOrderManagementSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `PurchaseOrderManagementSystem`

**Location**: `src/pages/01-vendor-portal/purchase-order-management-system.tsx`

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
