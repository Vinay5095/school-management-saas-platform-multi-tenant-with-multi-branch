# SPEC-411: Contractor Communication & Issue Tracking

> **Portal**: Contractor Portal  
> **Priority**: MEDIUM  
> **Estimated Time**: 6 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Communication hub and issue tracking system for contractors to report site issues, track resolution, communicate with project managers, access project announcements, and maintain communication logs with escalation support.

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


#### `contractor_messages`
```sql
CREATE TABLE contractor_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `site_issues`
```sql
CREATE TABLE site_issues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `issue_tracking`
```sql
CREATE TABLE issue_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `project_announcements`
```sql
CREATE TABLE project_announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `communication_logs`
```sql
CREATE TABLE communication_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `escalation_records`
```sql
CREATE TABLE escalation_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `meeting_minutes`
```sql
CREATE TABLE meeting_minutes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `contractor_messages`: Index on `created_at`, `created_by`, frequently queried fields
- `site_issues`: Index on `created_at`, `created_by`, frequently queried fields
- `issue_tracking`: Index on `created_at`, `created_by`, frequently queried fields
- `project_announcements`: Index on `created_at`, `created_by`, frequently queried fields
- `communication_logs`: Index on `created_at`, `created_by`, frequently queried fields
- `escalation_records`: Index on `created_at`, `created_by`, frequently queried fields
- `meeting_minutes`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE contractor_messages ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE site_issues ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE issue_tracking ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE project_announcements ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE communication_logs ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE escalation_records ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE meeting_minutes ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- contractor_messages policies
CREATE POLICY "Users can view own contractor_messages"
  ON contractor_messages FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own contractor_messages"
  ON contractor_messages FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own contractor_messages"
  ON contractor_messages FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- site_issues policies
CREATE POLICY "Users can view own site_issues"
  ON site_issues FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own site_issues"
  ON site_issues FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own site_issues"
  ON site_issues FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- issue_tracking policies
CREATE POLICY "Users can view own issue_tracking"
  ON issue_tracking FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own issue_tracking"
  ON issue_tracking FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own issue_tracking"
  ON issue_tracking FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- project_announcements policies
CREATE POLICY "Users can view own project_announcements"
  ON project_announcements FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own project_announcements"
  ON project_announcements FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own project_announcements"
  ON project_announcements FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- communication_logs policies
CREATE POLICY "Users can view own communication_logs"
  ON communication_logs FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own communication_logs"
  ON communication_logs FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own communication_logs"
  ON communication_logs FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- escalation_records policies
CREATE POLICY "Users can view own escalation_records"
  ON escalation_records FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own escalation_records"
  ON escalation_records FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own escalation_records"
  ON escalation_records FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- meeting_minutes policies
CREATE POLICY "Users can view own meeting_minutes"
  ON meeting_minutes FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own meeting_minutes"
  ON meeting_minutes FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own meeting_minutes"
  ON meeting_minutes FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `ContractorCommunicationIssueTrackingAPI`

**Location**: `src/lib/api/contractor-communication-issue-tracking-api.ts`

```typescript

export interface ContractorMessages {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface ContractorMessagesCreate {
  // Add relevant fields for creation
}

export interface ContractorMessagesUpdate {
  // Add relevant fields for update
}


export class ContractorCommunicationIssueTrackingAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('contractor_messages')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('contractor_messages')
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
      .from('contractor_messages')
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
      .from('contractor_messages')
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
      .from('contractor_messages')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const contractor_communication_issue_tracking_api = new ContractorCommunicationIssueTrackingAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `ContractorCommunicationIssueTracking`

**Location**: `src/pages/02-contractor-portal/contractor-communication-issue-tracking.tsx`

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
