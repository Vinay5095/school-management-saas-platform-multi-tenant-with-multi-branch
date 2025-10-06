# SPEC-412: Inspector Dashboard & Schedule Overview

> **Portal**: Inspector Portal  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Inspector dashboard displaying scheduled inspections, pending reports, compliance status, upcoming audits, inspection history, and quick inspection entry with calendar view and priority alerts.

---

## 🎯 SUCCESS CRITERIA

✅ Dashboard displays all key metrics accurately
✅ Real-time data updates working
✅ All widgets functional and customizable
✅ Quick actions work correctly
✅ Navigation to detailed views functional
✅ Performance metrics load efficiently

---

## 📊 DATABASE SCHEMA

### Tables Required


#### `inspector_dashboard_preferences`
```sql
CREATE TABLE inspector_dashboard_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspector_activity_log`
```sql
CREATE TABLE inspector_activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_calendar`
```sql
CREATE TABLE inspection_calendar (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `compliance_overview`
```sql
CREATE TABLE compliance_overview (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_alerts`
```sql
CREATE TABLE inspection_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `inspector_dashboard_preferences`: Index on `created_at`, `created_by`, frequently queried fields
- `inspector_activity_log`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_calendar`: Index on `created_at`, `created_by`, frequently queried fields
- `compliance_overview`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_alerts`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE inspector_dashboard_preferences ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspector_activity_log ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_calendar ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE compliance_overview ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_alerts ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- inspector_dashboard_preferences policies
CREATE POLICY "Users can view own inspector_dashboard_preferences"
  ON inspector_dashboard_preferences FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspector_dashboard_preferences"
  ON inspector_dashboard_preferences FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspector_dashboard_preferences"
  ON inspector_dashboard_preferences FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspector_activity_log policies
CREATE POLICY "Users can view own inspector_activity_log"
  ON inspector_activity_log FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspector_activity_log"
  ON inspector_activity_log FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspector_activity_log"
  ON inspector_activity_log FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_calendar policies
CREATE POLICY "Users can view own inspection_calendar"
  ON inspection_calendar FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_calendar"
  ON inspection_calendar FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_calendar"
  ON inspection_calendar FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- compliance_overview policies
CREATE POLICY "Users can view own compliance_overview"
  ON compliance_overview FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own compliance_overview"
  ON compliance_overview FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own compliance_overview"
  ON compliance_overview FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_alerts policies
CREATE POLICY "Users can view own inspection_alerts"
  ON inspection_alerts FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_alerts"
  ON inspection_alerts FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_alerts"
  ON inspection_alerts FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `InspectorDashboardScheduleOverviewAPI`

**Location**: `src/lib/api/inspector-dashboard-schedule-overview-api.ts`

```typescript

export interface InspectorDashboardPreferences {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface InspectorDashboardPreferencesCreate {
  // Add relevant fields for creation
}

export interface InspectorDashboardPreferencesUpdate {
  // Add relevant fields for update
}


export class InspectorDashboardScheduleOverviewAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('inspector_dashboard_preferences')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('inspector_dashboard_preferences')
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
      .from('inspector_dashboard_preferences')
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
      .from('inspector_dashboard_preferences')
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
      .from('inspector_dashboard_preferences')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const inspector_dashboard_schedule_overview_api = new InspectorDashboardScheduleOverviewAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `InspectorDashboardScheduleOverview`

**Location**: `src/pages/03-inspector-portal/inspector-dashboard-schedule-overview.tsx`

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

- **Dependencies**: Phase 1 (Foundation), Phase 2 (UI Components)
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
