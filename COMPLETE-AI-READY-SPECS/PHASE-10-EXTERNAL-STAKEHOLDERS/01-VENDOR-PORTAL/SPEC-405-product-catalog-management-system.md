# SPEC-405: Product Catalog Management System

> **Portal**: Vendor Portal  
> **Priority**: MEDIUM  
> **Estimated Time**: 7 hours  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

Product catalog management allowing vendors to maintain product listings, update prices, manage stock availability, upload product images and specifications, categorize products, and track product performance with analytics.

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


#### `vendor_products`
```sql
CREATE TABLE vendor_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `product_categories`
```sql
CREATE TABLE product_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `product_images`
```sql
CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `product_specifications`
```sql
CREATE TABLE product_specifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `product_pricing`
```sql
CREATE TABLE product_pricing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `product_availability`
```sql
CREATE TABLE product_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


#### `product_reviews`
```sql
CREATE TABLE product_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```


### Indexes

- `vendor_products`: Index on `created_at`, `created_by`, frequently queried fields
- `product_categories`: Index on `created_at`, `created_by`, frequently queried fields
- `product_images`: Index on `created_at`, `created_by`, frequently queried fields
- `product_specifications`: Index on `created_at`, `created_by`, frequently queried fields
- `product_pricing`: Index on `created_at`, `created_by`, frequently queried fields
- `product_availability`: Index on `created_at`, `created_by`, frequently queried fields
- `product_reviews`: Index on `created_at`, `created_by`, frequently queried fields

### Row Level Security (RLS)

```sql
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE product_specifications ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE product_pricing ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE product_availability ENABLE ROW LEVEL SECURITY;
```
```sql
ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;
```

**RLS Policies**:

```sql
-- vendor_products policies
CREATE POLICY "Users can view own vendor_products"
  ON vendor_products FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own vendor_products"
  ON vendor_products FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own vendor_products"
  ON vendor_products FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- product_categories policies
CREATE POLICY "Users can view own product_categories"
  ON product_categories FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own product_categories"
  ON product_categories FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own product_categories"
  ON product_categories FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- product_images policies
CREATE POLICY "Users can view own product_images"
  ON product_images FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own product_images"
  ON product_images FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own product_images"
  ON product_images FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- product_specifications policies
CREATE POLICY "Users can view own product_specifications"
  ON product_specifications FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own product_specifications"
  ON product_specifications FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own product_specifications"
  ON product_specifications FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- product_pricing policies
CREATE POLICY "Users can view own product_pricing"
  ON product_pricing FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own product_pricing"
  ON product_pricing FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own product_pricing"
  ON product_pricing FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- product_availability policies
CREATE POLICY "Users can view own product_availability"
  ON product_availability FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own product_availability"
  ON product_availability FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own product_availability"
  ON product_availability FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


```sql
-- product_reviews policies
CREATE POLICY "Users can view own product_reviews"
  ON product_reviews FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own product_reviews"
  ON product_reviews FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own product_reviews"
  ON product_reviews FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```


---

## 🔌 API LAYER (Supabase)

### API Class: `ProductCatalogManagementSystemAPI`

**Location**: `src/lib/api/product-catalog-management-system-api.ts`

```typescript

export interface VendorProducts {
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}

export interface VendorProductsCreate {
  // Add relevant fields for creation
}

export interface VendorProductsUpdate {
  // Add relevant fields for update
}


export class ProductCatalogManagementSystemAPI {
  constructor(private supabase: SupabaseClient) {}


  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('vendor_products')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('vendor_products')
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
      .from('vendor_products')
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
      .from('vendor_products')
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
      .from('vendor_products')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

// Export singleton instance
export const product_catalog_management_system_api = new ProductCatalogManagementSystemAPI(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `ProductCatalogManagementSystem`

**Location**: `src/pages/01-vendor-portal/product-catalog-management-system.tsx`

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
