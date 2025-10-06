# SPEC-413: Inspection Scheduling & Management System

> **Portal**: Inspector Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 7 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Comprehensive inspection scheduling system allowing inspectors to view assigned inspections, accept/reschedule inspections, manage inspection types, set up recurring inspections, track inspection history, and coordinate with facility teams.

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


#### `inspection_schedule`
```sql
CREATE TABLE inspection_schedule (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_types`
```sql
CREATE TABLE inspection_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_assignments`
```sql
CREATE TABLE inspection_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_history`
```sql
CREATE TABLE inspection_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `recurring_inspections`
```sql
CREATE TABLE recurring_inspections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_coordination`
```sql
CREATE TABLE inspection_coordination (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `schedule_conflicts`
```sql
CREATE TABLE schedule_conflicts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `inspection_schedule`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_types`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_assignments`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_history`: Index on `created_at`, `created_by`, frequently queried fields
- `recurring_inspections`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_coordination`: Index on `created_at`, `created_by`, frequently queried fields
- `schedule_conflicts`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE inspection_schedule ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_types ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_assignments ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_history ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE recurring_inspections ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_coordination ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE schedule_conflicts ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- inspection_schedule policies
CREATE POLICY "Users can view own inspection_schedule"
  ON inspection_schedule FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_schedule"
  ON inspection_schedule FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_schedule"
  ON inspection_schedule FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_types policies
CREATE POLICY "Users can view own inspection_types"
  ON inspection_types FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_types"
  ON inspection_types FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_types"
  ON inspection_types FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_assignments policies
CREATE POLICY "Users can view own inspection_assignments"
  ON inspection_assignments FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_assignments"
  ON inspection_assignments FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_assignments"
  ON inspection_assignments FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_history policies
CREATE POLICY "Users can view own inspection_history"
  ON inspection_history FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_history"
  ON inspection_history FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_history"
  ON inspection_history FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- recurring_inspections policies
CREATE POLICY "Users can view own recurring_inspections"
  ON recurring_inspections FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own recurring_inspections"
  ON recurring_inspections FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own recurring_inspections"
  ON recurring_inspections FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_coordination policies
CREATE POLICY "Users can view own inspection_coordination"
  ON inspection_coordination FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_coordination"
  ON inspection_coordination FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_coordination"
  ON inspection_coordination FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- schedule_conflicts policies
CREATE POLICY "Users can view own schedule_conflicts"
  ON schedule_conflicts FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own schedule_conflicts"
  ON schedule_conflicts FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own schedule_conflicts"
  ON schedule_conflicts FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `InspectionSchedulingManagementSystemAPI`

**Location**: `src/lib/api/inspection-scheduling-management-system-api.ts`

```typescript

export interface InspectionSchedule {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface InspectionScheduleCreate {
  // Add relevant fields for creation
}

export interface InspectionScheduleUpdate {
  // Add relevant fields for update
}


export class InspectionSchedulingManagementSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('inspection_schedule')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('inspection_schedule')
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
      .from('inspection_schedule')
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
      .from('inspection_schedule')
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
      .from('inspection_schedule')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const inspection_scheduling_management_system_api = new InspectionSchedulingManagementSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `InspectionSchedulingManagementSystem`

**Location**: `src/pages/03-inspector-portal/inspection-scheduling-management-system.tsx`

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

- **Dependencies**: Phase 1 (Foundation), Phase 2 (UI Components), SPEC-412 (Inspector Dashboard)
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
