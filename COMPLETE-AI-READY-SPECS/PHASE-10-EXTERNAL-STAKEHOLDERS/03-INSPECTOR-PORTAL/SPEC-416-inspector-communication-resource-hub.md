# SPEC-416: Inspector Communication & Resource Hub

> **Portal**: Inspector Portal  
> **Priority**: MEDIUM  
> **Estimated Time**: 6 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Communication platform for inspectors to interact with facility management, share inspection findings, access inspection guidelines, manage inspection resources, coordinate follow-up actions, and maintain comprehensive communication logs.

---

## 🎯 SUCCESS CRITERIA

✅ Messaging system functional
✅ Notifications working properly
✅ Document sharing operational
✅ Search functionality working
✅ Communication history maintained
✅ User interface intuitive

---

## 📊 DATABASE SCHEMA

### Tables Required


#### `inspector_messages`
```sql
CREATE TABLE inspector_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_findings_shared`
```sql
CREATE TABLE inspection_findings_shared (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `inspection_guidelines`
```sql
CREATE TABLE inspection_guidelines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `resource_library`
```sql
CREATE TABLE resource_library (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `followup_coordination`
```sql
CREATE TABLE followup_coordination (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `communication_history`
```sql
CREATE TABLE communication_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `document_sharing`
```sql
CREATE TABLE document_sharing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `inspector_messages`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_findings_shared`: Index on `created_at`, `created_by`, frequently queried fields
- `inspection_guidelines`: Index on `created_at`, `created_by`, frequently queried fields
- `resource_library`: Index on `created_at`, `created_by`, frequently queried fields
- `followup_coordination`: Index on `created_at`, `created_by`, frequently queried fields
- `communication_history`: Index on `created_at`, `created_by`, frequently queried fields
- `document_sharing`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE inspector_messages ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_findings_shared ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE inspection_guidelines ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE resource_library ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE followup_coordination ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE communication_history ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE document_sharing ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- inspector_messages policies
CREATE POLICY "Users can view own inspector_messages"
  ON inspector_messages FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspector_messages"
  ON inspector_messages FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspector_messages"
  ON inspector_messages FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_findings_shared policies
CREATE POLICY "Users can view own inspection_findings_shared"
  ON inspection_findings_shared FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_findings_shared"
  ON inspection_findings_shared FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_findings_shared"
  ON inspection_findings_shared FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- inspection_guidelines policies
CREATE POLICY "Users can view own inspection_guidelines"
  ON inspection_guidelines FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own inspection_guidelines"
  ON inspection_guidelines FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own inspection_guidelines"
  ON inspection_guidelines FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- resource_library policies
CREATE POLICY "Users can view own resource_library"
  ON resource_library FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own resource_library"
  ON resource_library FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own resource_library"
  ON resource_library FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- followup_coordination policies
CREATE POLICY "Users can view own followup_coordination"
  ON followup_coordination FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own followup_coordination"
  ON followup_coordination FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own followup_coordination"
  ON followup_coordination FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- communication_history policies
CREATE POLICY "Users can view own communication_history"
  ON communication_history FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own communication_history"
  ON communication_history FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own communication_history"
  ON communication_history FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- document_sharing policies
CREATE POLICY "Users can view own document_sharing"
  ON document_sharing FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own document_sharing"
  ON document_sharing FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own document_sharing"
  ON document_sharing FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `InspectorCommunicationResourceHubAPI`

**Location**: `src/lib/api/inspector-communication-resource-hub-api.ts`

```typescript

export interface InspectorMessages {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface InspectorMessagesCreate {
  // Add relevant fields for creation
}

export interface InspectorMessagesUpdate {
  // Add relevant fields for update
}


export class InspectorCommunicationResourceHubAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('inspector_messages')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('inspector_messages')
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
      .from('inspector_messages')
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
      .from('inspector_messages')
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
      .from('inspector_messages')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const inspector_communication_resource_hub_api = new InspectorCommunicationResourceHubAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `InspectorCommunicationResourceHub`

**Location**: `src/pages/03-inspector-portal/inspector-communication-resource-hub.tsx`

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
