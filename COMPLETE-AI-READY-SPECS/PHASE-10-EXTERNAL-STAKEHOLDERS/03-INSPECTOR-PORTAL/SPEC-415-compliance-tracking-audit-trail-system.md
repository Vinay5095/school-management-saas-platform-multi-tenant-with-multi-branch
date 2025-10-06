# SPEC-415: Compliance Tracking & Audit Trail System

> **Portal**: Inspector Portal  
> **Priority**: HIGH  
> **Estimated Time**: 7 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Compliance monitoring system tracking regulatory requirements, compliance status, violation management, corrective action tracking, compliance certificates, audit trail maintenance, and automated compliance reporting.

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


#### `compliance_requirements`
```sql
CREATE TABLE compliance_requirements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `compliance_status`
```sql
CREATE TABLE compliance_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `violations`
```sql
CREATE TABLE violations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `corrective_actions`
```sql
CREATE TABLE corrective_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `compliance_certificates`
```sql
CREATE TABLE compliance_certificates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `audit_trails`
```sql
CREATE TABLE audit_trails (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `regulatory_standards`
```sql
CREATE TABLE regulatory_standards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `compliance_history`
```sql
CREATE TABLE compliance_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `compliance_requirements`: Index on `created_at`, `created_by`, frequently queried fields
- `compliance_status`: Index on `created_at`, `created_by`, frequently queried fields
- `violations`: Index on `created_at`, `created_by`, frequently queried fields
- `corrective_actions`: Index on `created_at`, `created_by`, frequently queried fields
- `compliance_certificates`: Index on `created_at`, `created_by`, frequently queried fields
- `audit_trails`: Index on `created_at`, `created_by`, frequently queried fields
- `regulatory_standards`: Index on `created_at`, `created_by`, frequently queried fields
- `compliance_history`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE compliance_requirements ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE compliance_status ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE violations ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE corrective_actions ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE compliance_certificates ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE audit_trails ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE regulatory_standards ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE compliance_history ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- compliance_requirements policies
CREATE POLICY "Users can view own compliance_requirements"
  ON compliance_requirements FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own compliance_requirements"
  ON compliance_requirements FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own compliance_requirements"
  ON compliance_requirements FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- compliance_status policies
CREATE POLICY "Users can view own compliance_status"
  ON compliance_status FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own compliance_status"
  ON compliance_status FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own compliance_status"
  ON compliance_status FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- violations policies
CREATE POLICY "Users can view own violations"
  ON violations FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own violations"
  ON violations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own violations"
  ON violations FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- corrective_actions policies
CREATE POLICY "Users can view own corrective_actions"
  ON corrective_actions FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own corrective_actions"
  ON corrective_actions FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own corrective_actions"
  ON corrective_actions FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- compliance_certificates policies
CREATE POLICY "Users can view own compliance_certificates"
  ON compliance_certificates FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own compliance_certificates"
  ON compliance_certificates FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own compliance_certificates"
  ON compliance_certificates FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- audit_trails policies
CREATE POLICY "Users can view own audit_trails"
  ON audit_trails FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own audit_trails"
  ON audit_trails FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own audit_trails"
  ON audit_trails FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- regulatory_standards policies
CREATE POLICY "Users can view own regulatory_standards"
  ON regulatory_standards FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own regulatory_standards"
  ON regulatory_standards FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own regulatory_standards"
  ON regulatory_standards FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- compliance_history policies
CREATE POLICY "Users can view own compliance_history"
  ON compliance_history FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own compliance_history"
  ON compliance_history FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own compliance_history"
  ON compliance_history FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `ComplianceTrackingAuditTrailSystemAPI`

**Location**: `src/lib/api/compliance-tracking-audit-trail-system-api.ts`

```typescript

export interface ComplianceRequirements {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface ComplianceRequirementsCreate {
  // Add relevant fields for creation
}

export interface ComplianceRequirementsUpdate {
  // Add relevant fields for update
}


export class ComplianceTrackingAuditTrailSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('compliance_requirements')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('compliance_requirements')
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
      .from('compliance_requirements')
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
      .from('compliance_requirements')
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
      .from('compliance_requirements')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const compliance_tracking_audit_trail_system_api = new ComplianceTrackingAuditTrailSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `ComplianceTrackingAuditTrailSystem`

**Location**: `src/pages/03-inspector-portal/compliance-tracking-audit-trail-system.tsx`

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
