# SPEC-418: Partnership Program Management System

> **Portal**: Partner Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 8 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Comprehensive partnership program management for joint initiatives, program planning, resource sharing, activity coordination, outcome tracking, and program analytics with multi-partner collaboration support.

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


#### `partnership_programs`
```sql
CREATE TABLE partnership_programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `program_activities`
```sql
CREATE TABLE program_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `program_participants`
```sql
CREATE TABLE program_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_allocations`
```sql
CREATE TABLE resource_allocations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `program_outcomes`
```sql
CREATE TABLE program_outcomes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `program_milestones`
```sql
CREATE TABLE program_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `collaboration_agreements`
```sql
CREATE TABLE collaboration_agreements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `program_budgets`
```sql
CREATE TABLE program_budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `partnership_programs`: Index on `created_at`, `created_by`, frequently queried fields
- `program_activities`: Index on `created_at`, `created_by`, frequently queried fields
- `program_participants`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_allocations`: Index on `created_at`, `created_by`, frequently queried fields
- `program_outcomes`: Index on `created_at`, `created_by`, frequently queried fields
- `program_milestones`: Index on `created_at`, `created_by`, frequently queried fields
- `collaboration_agreements`: Index on `created_at`, `created_by`, frequently queried fields
- `program_budgets`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE partnership_programs ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE program_activities ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE program_participants ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_allocations ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE program_outcomes ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE program_milestones ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE collaboration_agreements ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE program_budgets ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- partnership_programs policies
CREATE POLICY "Users can view own partnership_programs"
  ON partnership_programs FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own partnership_programs"
  ON partnership_programs FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own partnership_programs"
  ON partnership_programs FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- program_activities policies
CREATE POLICY "Users can view own program_activities"
  ON program_activities FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own program_activities"
  ON program_activities FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own program_activities"
  ON program_activities FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- program_participants policies
CREATE POLICY "Users can view own program_participants"
  ON program_participants FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own program_participants"
  ON program_participants FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own program_participants"
  ON program_participants FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_allocations policies
CREATE POLICY "Users can view own resource_allocations"
  ON resource_allocations FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_allocations"
  ON resource_allocations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_allocations"
  ON resource_allocations FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- program_outcomes policies
CREATE POLICY "Users can view own program_outcomes"
  ON program_outcomes FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own program_outcomes"
  ON program_outcomes FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own program_outcomes"
  ON program_outcomes FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- program_milestones policies
CREATE POLICY "Users can view own program_milestones"
  ON program_milestones FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own program_milestones"
  ON program_milestones FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own program_milestones"
  ON program_milestones FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- collaboration_agreements policies
CREATE POLICY "Users can view own collaboration_agreements"
  ON collaboration_agreements FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own collaboration_agreements"
  ON collaboration_agreements FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own collaboration_agreements"
  ON collaboration_agreements FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- program_budgets policies
CREATE POLICY "Users can view own program_budgets"
  ON program_budgets FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own program_budgets"
  ON program_budgets FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own program_budgets"
  ON program_budgets FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `PartnershipProgramManagementSystemAPI`

**Location**: `src/lib/api/partnership-program-management-system-api.ts`

```typescript

export interface PartnershipPrograms {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface PartnershipProgramsCreate {
  // Add relevant fields for creation
}

export interface PartnershipProgramsUpdate {
  // Add relevant fields for update
}


export class PartnershipProgramManagementSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('partnership_programs')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('partnership_programs')
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
      .from('partnership_programs')
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
      .from('partnership_programs')
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
      .from('partnership_programs')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const partnership_program_management_system_api = new PartnershipProgramManagementSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `PartnershipProgramManagementSystem`

**Location**: `src/pages/04-partner-portal/partnership-program-management-system.tsx`

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
