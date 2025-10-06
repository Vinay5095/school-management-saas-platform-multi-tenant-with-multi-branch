# SPEC-419: Shared Resource Management System

> **Portal**: Partner Portal  
> **Priority**: HIGH  
> **Estimated Time**: 7 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Resource sharing platform for partners to share facilities, equipment, expertise, educational materials, and services with booking system, usage tracking, cost sharing, and resource availability management.

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


#### `shared_resources`
```sql
CREATE TABLE shared_resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_categories`
```sql
CREATE TABLE resource_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_bookings`
```sql
CREATE TABLE resource_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_usage`
```sql
CREATE TABLE resource_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `cost_sharing`
```sql
CREATE TABLE cost_sharing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_availability`
```sql
CREATE TABLE resource_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `sharing_agreements`
```sql
CREATE TABLE sharing_agreements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `usage_logs`
```sql
CREATE TABLE usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `shared_resources`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_categories`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_bookings`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_usage`: Index on `created_at`, `created_by`, frequently queried fields
- `cost_sharing`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_availability`: Index on `created_at`, `created_by`, frequently queried fields
- `sharing_agreements`: Index on `created_at`, `created_by`, frequently queried fields
- `usage_logs`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE shared_resources ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_categories ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_bookings ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_usage ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE cost_sharing ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_availability ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE sharing_agreements ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- shared_resources policies
CREATE POLICY "Users can view own shared_resources"
  ON shared_resources FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own shared_resources"
  ON shared_resources FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own shared_resources"
  ON shared_resources FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_categories policies
CREATE POLICY "Users can view own resource_categories"
  ON resource_categories FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_categories"
  ON resource_categories FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_categories"
  ON resource_categories FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_bookings policies
CREATE POLICY "Users can view own resource_bookings"
  ON resource_bookings FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_bookings"
  ON resource_bookings FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_bookings"
  ON resource_bookings FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_usage policies
CREATE POLICY "Users can view own resource_usage"
  ON resource_usage FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_usage"
  ON resource_usage FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_usage"
  ON resource_usage FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- cost_sharing policies
CREATE POLICY "Users can view own cost_sharing"
  ON cost_sharing FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own cost_sharing"
  ON cost_sharing FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own cost_sharing"
  ON cost_sharing FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_availability policies
CREATE POLICY "Users can view own resource_availability"
  ON resource_availability FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_availability"
  ON resource_availability FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_availability"
  ON resource_availability FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- sharing_agreements policies
CREATE POLICY "Users can view own sharing_agreements"
  ON sharing_agreements FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own sharing_agreements"
  ON sharing_agreements FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own sharing_agreements"
  ON sharing_agreements FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- usage_logs policies
CREATE POLICY "Users can view own usage_logs"
  ON usage_logs FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own usage_logs"
  ON usage_logs FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own usage_logs"
  ON usage_logs FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `SharedResourceManagementSystemAPI`

**Location**: `src/lib/api/shared-resource-management-system-api.ts`

```typescript

export interface SharedResources {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface SharedResourcesCreate {
  // Add relevant fields for creation
}

export interface SharedResourcesUpdate {
  // Add relevant fields for update
}


export class SharedResourceManagementSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('shared_resources')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('shared_resources')
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
      .from('shared_resources')
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
      .from('shared_resources')
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
      .from('shared_resources')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const shared_resource_management_system_api = new SharedResourceManagementSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `SharedResourceManagementSystem`

**Location**: `src/pages/04-partner-portal/shared-resource-management-system.tsx`

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

- **Dependencies**: Phase 1 (Foundation), Phase 2 (UI Components), SPEC-417 (Partner Dashboard)
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
