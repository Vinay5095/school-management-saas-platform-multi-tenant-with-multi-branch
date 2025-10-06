# SPEC-406: Vendor Communication & Support Hub

> **Portal**: Vendor Portal  
> **Priority**: MEDIUM  
> **Estimated Time**: 6 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Communication hub for vendors to interact with procurement team, raise support tickets, track queries, access announcements, share documents, and maintain communication history with notification system.

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


#### `vendor_messages`
```sql
CREATE TABLE vendor_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `support_tickets`
```sql
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `vendor_announcements`
```sql
CREATE TABLE vendor_announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `shared_documents`
```sql
CREATE TABLE shared_documents (
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


#### `message_threads`
```sql
CREATE TABLE message_threads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `ticket_responses`
```sql
CREATE TABLE ticket_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `vendor_messages`: Index on `created_at`, `created_by`, frequently queried fields
- `support_tickets`: Index on `created_at`, `created_by`, frequently queried fields
- `vendor_announcements`: Index on `created_at`, `created_by`, frequently queried fields
- `shared_documents`: Index on `created_at`, `created_by`, frequently queried fields
- `communication_history`: Index on `created_at`, `created_by`, frequently queried fields
- `message_threads`: Index on `created_at`, `created_by`, frequently queried fields
- `ticket_responses`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE vendor_messages ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE vendor_announcements ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE shared_documents ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE communication_history ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE message_threads ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE ticket_responses ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- vendor_messages policies
CREATE POLICY "Users can view own vendor_messages"
  ON vendor_messages FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_messages"
  ON vendor_messages FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_messages"
  ON vendor_messages FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- support_tickets policies
CREATE POLICY "Users can view own support_tickets"
  ON support_tickets FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own support_tickets"
  ON support_tickets FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own support_tickets"
  ON support_tickets FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- vendor_announcements policies
CREATE POLICY "Users can view own vendor_announcements"
  ON vendor_announcements FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_announcements"
  ON vendor_announcements FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_announcements"
  ON vendor_announcements FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- shared_documents policies
CREATE POLICY "Users can view own shared_documents"
  ON shared_documents FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own shared_documents"
  ON shared_documents FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own shared_documents"
  ON shared_documents FOR UPDATE
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
-- message_threads policies
CREATE POLICY "Users can view own message_threads"
  ON message_threads FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own message_threads"
  ON message_threads FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own message_threads"
  ON message_threads FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- ticket_responses policies
CREATE POLICY "Users can view own ticket_responses"
  ON ticket_responses FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own ticket_responses"
  ON ticket_responses FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own ticket_responses"
  ON ticket_responses FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `VendorCommunicationSupportHubAPI`

**Location**: `src/lib/api/vendor-communication-support-hub-api.ts`

```typescript

export interface VendorMessages {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface VendorMessagesCreate {
  // Add relevant fields for creation
}

export interface VendorMessagesUpdate {
  // Add relevant fields for update
}


export class VendorCommunicationSupportHubAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('vendor_messages')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('vendor_messages')
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
      .from('vendor_messages')
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
      .from('vendor_messages')
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
      .from('vendor_messages')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const vendor_communication_support_hub_api = new VendorCommunicationSupportHubAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `VendorCommunicationSupportHub`

**Location**: `src/pages/01-vendor-portal/vendor-communication-support-hub.tsx`

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
