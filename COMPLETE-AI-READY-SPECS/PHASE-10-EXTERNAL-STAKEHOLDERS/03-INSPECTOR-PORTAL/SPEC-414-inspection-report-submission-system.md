# SPEC-414: Inspection Report Submission System

> **Portal**: Inspector Portal  
> **Priority**: CRITICAL  
> **Estimated Time**: 8 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Detailed inspection report creation and submission system with customizable checklists, photo/video documentation, pass/fail criteria, deficiency tracking, recommendation recording, and digital signature support with template management.

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


#### `inspection_reports`
```sql
CREATE TABLE inspection_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_checklists`
```sql
CREATE TABLE inspection_checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_photos`
```sql
CREATE TABLE inspection_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `deficiencies`
```sql
CREATE TABLE deficiencies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `recommendations`
```sql
CREATE TABLE recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `report_signatures`
```sql
CREATE TABLE report_signatures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `checklist_templates`
```sql
CREATE TABLE checklist_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_findings`
```sql
CREATE TABLE inspection_findings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `inspection_reports`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_checklists`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_photos`: Index on `created_at`, `created_by`, frequently queried fields
- `deficiencies`: Index on `created_at`, `created_by`, frequently queried fields
- `recommendations`: Index on `created_at`, `created_by`, frequently queried fields
- `report_signatures`: Index on `created_at`, `created_by`, frequently queried fields
- `checklist_templates`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_findings`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE inspection_reports ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_checklists ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_photos ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE deficiencies ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE report_signatures ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE checklist_templates ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_findings ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- inspection_reports policies
CREATE POLICY "Users can view own inspection_reports"
  ON inspection_reports FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_reports"
  ON inspection_reports FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_reports"
  ON inspection_reports FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_checklists policies
CREATE POLICY "Users can view own inspection_checklists"
  ON inspection_checklists FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_checklists"
  ON inspection_checklists FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_checklists"
  ON inspection_checklists FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_photos policies
CREATE POLICY "Users can view own inspection_photos"
  ON inspection_photos FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_photos"
  ON inspection_photos FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_photos"
  ON inspection_photos FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- deficiencies policies
CREATE POLICY "Users can view own deficiencies"
  ON deficiencies FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own deficiencies"
  ON deficiencies FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own deficiencies"
  ON deficiencies FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- recommendations policies
CREATE POLICY "Users can view own recommendations"
  ON recommendations FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own recommendations"
  ON recommendations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own recommendations"
  ON recommendations FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- report_signatures policies
CREATE POLICY "Users can view own report_signatures"
  ON report_signatures FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own report_signatures"
  ON report_signatures FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own report_signatures"
  ON report_signatures FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- checklist_templates policies
CREATE POLICY "Users can view own checklist_templates"
  ON checklist_templates FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own checklist_templates"
  ON checklist_templates FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own checklist_templates"
  ON checklist_templates FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_findings policies
CREATE POLICY "Users can view own inspection_findings"
  ON inspection_findings FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_findings"
  ON inspection_findings FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_findings"
  ON inspection_findings FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `InspectionReportSubmissionSystemAPI`

**Location**: `src/lib/api/inspection-report-submission-system-api.ts`

```typescript

export interface InspectionReports {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface InspectionReportsCreate {
  // Add relevant fields for creation
}

export interface InspectionReportsUpdate {
  // Add relevant fields for update
}


export class InspectionReportSubmissionSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('inspection_reports')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('inspection_reports')
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
      .from('inspection_reports')
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
      .from('inspection_reports')
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
      .from('inspection_reports')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const inspection_report_submission_system_api = new InspectionReportSubmissionSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `InspectionReportSubmissionSystem`

**Location**: `src/pages/03-inspector-portal/inspection-report-submission-system.tsx`

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
