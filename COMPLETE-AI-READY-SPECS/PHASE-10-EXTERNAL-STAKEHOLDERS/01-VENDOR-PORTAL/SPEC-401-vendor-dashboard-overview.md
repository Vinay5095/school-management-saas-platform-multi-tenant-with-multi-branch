# SPEC-401: Vendor Dashboard & Overview

> **Portal**: Vendor Portal  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Comprehensive vendor dashboard displaying purchase orders, pending deliveries, payment status, invoice management, product catalog, and communication hub with real-time metrics and notifications.

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


#### `vendor_dashboard_preferences`
```sql
CREATE TABLE vendor_dashboard_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `vendor_activity_log`
```sql
CREATE TABLE vendor_activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `vendor_notifications`
```sql
CREATE TABLE vendor_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `dashboard_widgets`
```sql
CREATE TABLE dashboard_widgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `vendor_dashboard_preferences`: Index on `created_at`, `created_by`, frequently queried fields
- `vendor_activity_log`: Index on `created_at`, `created_by`, frequently queried fields
- `vendor_notifications`: Index on `created_at`, `created_by`, frequently queried fields
- `dashboard_widgets`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE vendor_dashboard_preferences ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE vendor_activity_log ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE vendor_notifications ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE dashboard_widgets ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- vendor_dashboard_preferences policies
CREATE POLICY "Users can view own vendor_dashboard_preferences"
  ON vendor_dashboard_preferences FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_dashboard_preferences"
  ON vendor_dashboard_preferences FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_dashboard_preferences"
  ON vendor_dashboard_preferences FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- vendor_activity_log policies
CREATE POLICY "Users can view own vendor_activity_log"
  ON vendor_activity_log FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_activity_log"
  ON vendor_activity_log FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_activity_log"
  ON vendor_activity_log FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- vendor_notifications policies
CREATE POLICY "Users can view own vendor_notifications"
  ON vendor_notifications FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_notifications"
  ON vendor_notifications FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_notifications"
  ON vendor_notifications FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- dashboard_widgets policies
CREATE POLICY "Users can view own dashboard_widgets"
  ON dashboard_widgets FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own dashboard_widgets"
  ON dashboard_widgets FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own dashboard_widgets"
  ON dashboard_widgets FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `VendorDashboardOverviewAPI`

**Location**: `src/lib/api/vendor-dashboard-overview-api.ts`

```typescript

export interface VendorDashboardPreferences {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface VendorDashboardPreferencesCreate {
  // Add relevant fields for creation
}

export interface VendorDashboardPreferencesUpdate {
  // Add relevant fields for update
}


export class VendorDashboardOverviewAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('vendor_dashboard_preferences')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('vendor_dashboard_preferences')
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
      .from('vendor_dashboard_preferences')
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
      .from('vendor_dashboard_preferences')
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
      .from('vendor_dashboard_preferences')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const vendor_dashboard_overview_api = new VendorDashboardOverviewAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `VendorDashboardOverview`

**Location**: `src/pages/01-vendor-portal/vendor-dashboard-overview.tsx`

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
