# SPEC-400: Asset & Inventory Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-400  
**Title**: Asset & Inventory Management System  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: MAINTENANCE PORTAL  
**Category**: Operations & Management  
**Priority**: MEDIUM  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 8 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth), SPEC-398 (Maintenance Dashboard)  

---

## 📋 DESCRIPTION

Complete asset and inventory management with asset registry, maintenance history per asset, inventory tracking, location management, vendor management, purchase orders, QR code generation, and spare parts tracking.

---

## 🎯 SUCCESS CRITERIA

- [ ] Asset registry and tagging functional
- [ ] Maintenance history per asset functional
- [ ] Inventory tracking with stock levels functional
- [ ] Asset location management functional
- [ ] Vendor management functional
- [ ] Purchase order creation functional
- [ ] QR code generation for assets functional
- [ ] Spare parts tracking functional
- [ ] Stock movement tracking functional
- [ ] Asset depreciation tracking functional
- [ ] Inventory reports functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS asset_maintenance_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS asset_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_assets_tenant_branch ON assets(tenant_id, branch_id);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_created_at ON assets(created_at DESC);
CREATE INDEX idx_asset_maintenance_history_tenant_branch ON asset_maintenance_history(tenant_id, branch_id);
CREATE INDEX idx_asset_maintenance_history_status ON asset_maintenance_history(status);
CREATE INDEX idx_asset_maintenance_history_created_at ON asset_maintenance_history(created_at DESC);
CREATE INDEX idx_inventory_items_tenant_branch ON inventory_items(tenant_id, branch_id);
CREATE INDEX idx_inventory_items_status ON inventory_items(status);
CREATE INDEX idx_inventory_items_created_at ON inventory_items(created_at DESC);
CREATE INDEX idx_vendors_tenant_branch ON vendors(tenant_id, branch_id);
CREATE INDEX idx_vendors_status ON vendors(status);
CREATE INDEX idx_vendors_created_at ON vendors(created_at DESC);
CREATE INDEX idx_purchase_orders_tenant_branch ON purchase_orders(tenant_id, branch_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_orders_created_at ON purchase_orders(created_at DESC);
CREATE INDEX idx_asset_locations_tenant_branch ON asset_locations(tenant_id, branch_id);
CREATE INDEX idx_asset_locations_status ON asset_locations(status);
CREATE INDEX idx_asset_locations_created_at ON asset_locations(created_at DESC);
CREATE INDEX idx_stock_movements_tenant_branch ON stock_movements(tenant_id, branch_id);
CREATE INDEX idx_stock_movements_status ON stock_movements(status);
CREATE INDEX idx_stock_movements_created_at ON stock_movements(created_at DESC);

-- Enable RLS
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_maintenance_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY assets_isolation ON assets
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY asset_maintenance_history_isolation ON asset_maintenance_history
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY inventory_items_isolation ON inventory_items
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY vendors_isolation ON vendors
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY purchase_orders_isolation ON purchase_orders
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY asset_locations_isolation ON asset_locations
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY stock_movements_isolation ON stock_movements
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-400-asset-inventory-management-system.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface MainEntity {
  id: string;
  tenantId: string;
  branchId: string;
  name: string;
  description: string;
  status: string;
  metadata?: Record<string, any>;
  createdAt: string;
  updatedAt: string;
}

export class SPEC400API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('assets')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(start, end);

    if (error) throw error;
    
    return {
      data: data as MainEntity[],
      total: count || 0
    };
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('assets')
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
      .from('assets')
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
      .from('assets')
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
      .from('assets')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec400API = new SPEC400API();
```

### React Component (`/components/04-maintenance-portal/AssetInventoryManagementSystem.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function AssetInventoryManagementSystem() {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const { toast } = useToast();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      // Load data using API
      setItems([]);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Asset & Inventory Management System</h1>
          <p className="text-muted-foreground">Manage and track operations</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Add New
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8">Loading...</div>
          ) : items.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No records found
            </div>
          ) : (
            <div className="space-y-2">
              {items.map((item) => (
                <div key={item.id} className="flex items-center justify-between p-4 border rounded-lg">
                  <div>
                    <p className="font-medium">{item.name}</p>
                    <p className="text-sm text-muted-foreground">{item.description}</p>
                  </div>
                  <div className="flex gap-2">
                    <Button size="sm" variant="outline">
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button size="sm" variant="outline">
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/spec-400-asset-inventory-management-system.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec400API } from '@/lib/api/spec-400-asset-inventory-management-system';

describe('SPEC-400: Asset & Inventory Management System API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec400API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec400API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec400API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec400API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { AssetInventoryManagementSystem } from '@/components/04-maintenance-portal/AssetInventoryManagementSystem';

export default function Page() {
  return (
    <div className="container mx-auto">
      <AssetInventoryManagementSystem />
    </div>
  );
}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all tables
- Tenant and branch isolation via session variables
- User-specific data access based on roles
- Activity logging for audit trail
- Input validation on all operations
- Sensitive data encryption at rest

---

## 📊 PERFORMANCE

- **Page Load**: < 2 seconds
- **Search**: < 500ms
- **Create/Update**: < 1 second
- **Database Queries**: Indexed and optimized
- **Pagination**: Server-side for large datasets

---

## ✅ DEFINITION OF DONE

- [ ] All database tables and indexes created
- [ ] RLS policies implemented and tested
- [ ] API client fully implemented with TypeScript types
- [ ] React component with full CRUD operations
- [ ] Search and filter functionality working
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete
