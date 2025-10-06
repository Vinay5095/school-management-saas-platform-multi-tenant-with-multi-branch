# SPEC-408: Project Work Progress Tracking System

> **Portal**: Contractor Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 8 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Detailed work progress tracking system allowing contractors to update work status, submit progress reports, upload photos/videos, track milestones, manage resources, log work hours, and handle approval workflows with real-time updates.

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


#### `contractor_projects`
```sql
CREATE TABLE contractor_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `work_progress`
```sql
CREATE TABLE work_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `progress_reports`
```sql
CREATE TABLE progress_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `milestone_tracking`
```sql
CREATE TABLE milestone_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `work_photos`
```sql
CREATE TABLE work_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_logs`
```sql
CREATE TABLE resource_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `work_hours`
```sql
CREATE TABLE work_hours (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `approval_workflows`
```sql
CREATE TABLE approval_workflows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `contractor_projects`: Index on `created_at`, `created_by`, frequently queried fields
- `work_progress`: Index on `created_at`, `created_by`, frequently queried fields
- `progress_reports`: Index on `created_at`, `created_by`, frequently queried fields
- `milestone_tracking`: Index on `created_at`, `created_by`, frequently queried fields
- `work_photos`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_logs`: Index on `created_at`, `created_by`, frequently queried fields
- `work_hours`: Index on `created_at`, `created_by`, frequently queried fields
- `approval_workflows`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE contractor_projects ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE work_progress ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE progress_reports ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE milestone_tracking ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE work_photos ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_logs ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE work_hours ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE approval_workflows ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- contractor_projects policies
CREATE POLICY "Users can view own contractor_projects"
  ON contractor_projects FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own contractor_projects"
  ON contractor_projects FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own contractor_projects"
  ON contractor_projects FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- work_progress policies
CREATE POLICY "Users can view own work_progress"
  ON work_progress FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own work_progress"
  ON work_progress FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own work_progress"
  ON work_progress FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- progress_reports policies
CREATE POLICY "Users can view own progress_reports"
  ON progress_reports FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own progress_reports"
  ON progress_reports FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own progress_reports"
  ON progress_reports FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- milestone_tracking policies
CREATE POLICY "Users can view own milestone_tracking"
  ON milestone_tracking FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own milestone_tracking"
  ON milestone_tracking FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own milestone_tracking"
  ON milestone_tracking FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- work_photos policies
CREATE POLICY "Users can view own work_photos"
  ON work_photos FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own work_photos"
  ON work_photos FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own work_photos"
  ON work_photos FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_logs policies
CREATE POLICY "Users can view own resource_logs"
  ON resource_logs FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_logs"
  ON resource_logs FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_logs"
  ON resource_logs FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- work_hours policies
CREATE POLICY "Users can view own work_hours"
  ON work_hours FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own work_hours"
  ON work_hours FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own work_hours"
  ON work_hours FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- approval_workflows policies
CREATE POLICY "Users can view own approval_workflows"
  ON approval_workflows FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own approval_workflows"
  ON approval_workflows FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own approval_workflows"
  ON approval_workflows FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `ProjectWorkProgressTrackingSystemAPI`

**Location**: `src/lib/api/project-work-progress-tracking-system-api.ts`

```typescript

export interface ContractorProjects {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface ContractorProjectsCreate {
  // Add relevant fields for creation
}

export interface ContractorProjectsUpdate {
  // Add relevant fields for update
}


export class ProjectWorkProgressTrackingSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('contractor_projects')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('contractor_projects')
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
      .from('contractor_projects')
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
      .from('contractor_projects')
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
      .from('contractor_projects')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const project_work_progress_tracking_system_api = new ProjectWorkProgressTrackingSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `ProjectWorkProgressTrackingSystem`

**Location**: `src/pages/02-contractor-portal/project-work-progress-tracking-system.tsx`

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
