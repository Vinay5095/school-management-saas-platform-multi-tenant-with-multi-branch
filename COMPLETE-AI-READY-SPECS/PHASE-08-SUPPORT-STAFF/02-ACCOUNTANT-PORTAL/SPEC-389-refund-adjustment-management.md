# SPEC-389: Refund & Adjustment Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-389  
**Title**: Refund & Adjustment Management  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: ACCOUNTANT PORTAL  
**Category**: Operations & Management  
**Priority**: MEDIUM  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth), SPEC-382 (Accountant Dashboard)  

---

## 📋 DESCRIPTION

Refund and fee adjustment management with request creation, approval workflow, credit note generation, refund payment processing, adjustment tracking, and comprehensive refund history.

---

## 🎯 SUCCESS CRITERIA

- [ ] Refund request creation with reasons functional
- [ ] Multi-level refund approval functional
- [ ] Fee adjustment entries functional
- [ ] Credit note generation functional
- [ ] Refund payment processing functional
- [ ] Adjustment history tracking functional
- [ ] Refund reports functional
- [ ] Approval workflow customization functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS refund_requests (
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

CREATE TABLE IF NOT EXISTS fee_adjustments (
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

CREATE TABLE IF NOT EXISTS credit_notes (
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

CREATE TABLE IF NOT EXISTS refund_payments (
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

CREATE TABLE IF NOT EXISTS adjustment_approvals (
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
CREATE INDEX idx_refund_requests_tenant_branch ON refund_requests(tenant_id, branch_id);
CREATE INDEX idx_refund_requests_status ON refund_requests(status);
CREATE INDEX idx_refund_requests_created_at ON refund_requests(created_at DESC);
CREATE INDEX idx_fee_adjustments_tenant_branch ON fee_adjustments(tenant_id, branch_id);
CREATE INDEX idx_fee_adjustments_status ON fee_adjustments(status);
CREATE INDEX idx_fee_adjustments_created_at ON fee_adjustments(created_at DESC);
CREATE INDEX idx_credit_notes_tenant_branch ON credit_notes(tenant_id, branch_id);
CREATE INDEX idx_credit_notes_status ON credit_notes(status);
CREATE INDEX idx_credit_notes_created_at ON credit_notes(created_at DESC);
CREATE INDEX idx_refund_payments_tenant_branch ON refund_payments(tenant_id, branch_id);
CREATE INDEX idx_refund_payments_status ON refund_payments(status);
CREATE INDEX idx_refund_payments_created_at ON refund_payments(created_at DESC);
CREATE INDEX idx_adjustment_approvals_tenant_branch ON adjustment_approvals(tenant_id, branch_id);
CREATE INDEX idx_adjustment_approvals_status ON adjustment_approvals(status);
CREATE INDEX idx_adjustment_approvals_created_at ON adjustment_approvals(created_at DESC);

-- Enable RLS
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE adjustment_approvals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY refund_requests_isolation ON refund_requests
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY fee_adjustments_isolation ON fee_adjustments
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY credit_notes_isolation ON credit_notes
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY refund_payments_isolation ON refund_payments
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY adjustment_approvals_isolation ON adjustment_approvals
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-389-refund-adjustment-management.ts`)

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

export class SPEC389API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('refund_requests')
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
      .from('refund_requests')
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
      .from('refund_requests')
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
      .from('refund_requests')
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
      .from('refund_requests')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec389API = new SPEC389API();
```

### React Component (`/components/02-accountant-portal/RefundAdjustmentManagement.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function RefundAdjustmentManagement() {
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
          <h1 className="text-3xl font-bold">Refund & Adjustment Management</h1>
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

### Unit Tests (`/tests/unit/spec-389-refund-adjustment-management.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec389API } from '@/lib/api/spec-389-refund-adjustment-management';

describe('SPEC-389: Refund & Adjustment Management API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec389API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec389API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec389API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec389API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { RefundAdjustmentManagement } from '@/components/02-accountant-portal/RefundAdjustmentManagement';

export default function Page() {
  return (
    <div className="container mx-auto">
      <RefundAdjustmentManagement />
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
