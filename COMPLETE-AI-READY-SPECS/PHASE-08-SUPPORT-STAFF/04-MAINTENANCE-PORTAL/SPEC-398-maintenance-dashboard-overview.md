# SPEC-398: Maintenance Dashboard & Overview

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-398  
**Title**: Maintenance Dashboard & Overview  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: MAINTENANCE PORTAL  
**Category**: Operations & Management  
**Priority**: HIGH  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth)  

---

## 📋 DESCRIPTION

Maintenance operations dashboard displaying work order queue, pending tasks by priority, asset status summary, maintenance schedule calendar, inventory alerts, and quick action panel.

---

## 🎯 SUCCESS CRITERIA

- [ ] Work order queue overview functional
- [ ] Pending tasks by priority/status functional
- [ ] Asset status summary functional
- [ ] Maintenance schedule calendar functional
- [ ] Inventory level alerts functional
- [ ] Quick actions panel functional
- [ ] Recent activities log functional
- [ ] Cost tracking overview functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS maintenance_dashboard_preferences (
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

CREATE TABLE IF NOT EXISTS maintenance_activity_log (
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

CREATE TABLE IF NOT EXISTS maintenance_metrics (
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

CREATE TABLE IF NOT EXISTS dashboard_alerts (
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
CREATE INDEX idx_maintenance_dashboard_preferences_tenant_branch ON maintenance_dashboard_preferences(tenant_id, branch_id);
CREATE INDEX idx_maintenance_dashboard_preferences_status ON maintenance_dashboard_preferences(status);
CREATE INDEX idx_maintenance_dashboard_preferences_created_at ON maintenance_dashboard_preferences(created_at DESC);
CREATE INDEX idx_maintenance_activity_log_tenant_branch ON maintenance_activity_log(tenant_id, branch_id);
CREATE INDEX idx_maintenance_activity_log_status ON maintenance_activity_log(status);
CREATE INDEX idx_maintenance_activity_log_created_at ON maintenance_activity_log(created_at DESC);
CREATE INDEX idx_maintenance_metrics_tenant_branch ON maintenance_metrics(tenant_id, branch_id);
CREATE INDEX idx_maintenance_metrics_status ON maintenance_metrics(status);
CREATE INDEX idx_maintenance_metrics_created_at ON maintenance_metrics(created_at DESC);
CREATE INDEX idx_dashboard_alerts_tenant_branch ON dashboard_alerts(tenant_id, branch_id);
CREATE INDEX idx_dashboard_alerts_status ON dashboard_alerts(status);
CREATE INDEX idx_dashboard_alerts_created_at ON dashboard_alerts(created_at DESC);

-- Enable RLS
ALTER TABLE maintenance_dashboard_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_alerts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY maintenance_dashboard_preferences_isolation ON maintenance_dashboard_preferences
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY maintenance_activity_log_isolation ON maintenance_activity_log
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY maintenance_metrics_isolation ON maintenance_metrics
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY dashboard_alerts_isolation ON dashboard_alerts
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-398-maintenance-dashboard-overview.ts`)

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

export class SPEC398API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('maintenance_dashboard_preferences')
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
      .from('maintenance_dashboard_preferences')
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
      .from('maintenance_dashboard_preferences')
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
      .from('maintenance_dashboard_preferences')
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
      .from('maintenance_dashboard_preferences')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec398API = new SPEC398API();
```

### React Component (`/components/04-maintenance-portal/MaintenanceDashboardOverview.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function MaintenanceDashboardOverview() {
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
          <h1 className="text-3xl font-bold">Maintenance Dashboard & Overview</h1>
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

### Unit Tests (`/tests/unit/spec-398-maintenance-dashboard-overview.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec398API } from '@/lib/api/spec-398-maintenance-dashboard-overview';

describe('SPEC-398: Maintenance Dashboard & Overview API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec398API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec398API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec398API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec398API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { MaintenanceDashboardOverview } from '@/components/04-maintenance-portal/MaintenanceDashboardOverview';

export default function Page() {
  return (
    <div className="container mx-auto">
      <MaintenanceDashboardOverview />
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
