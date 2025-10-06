# SPEC-385: Fee Defaulter Tracking & Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-385  
**Title**: Fee Defaulter Tracking & Management  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: ACCOUNTANT PORTAL  
**Category**: Operations & Management  
**Priority**: HIGH  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth), SPEC-382 (Accountant Dashboard)  

---

## 📋 DESCRIPTION

Comprehensive defaulter tracking with automated list generation based on due dates, automated reminder system (email/SMS), payment follow-up scheduling, overdue tracking, payment plan creation, and parent communication logging.

---

## 🎯 SUCCESS CRITERIA

- [ ] Automated defaulter list generation functional
- [ ] Overdue amount calculation with late fees functional
- [ ] Automated payment reminders (email/SMS) functional
- [ ] Payment follow-up scheduling functional
- [ ] Payment plan creation for defaulters functional
- [ ] Communication history tracking functional
- [ ] Defaulter reports by class/amount functional
- [ ] Escalation workflows functional
- [ ] Parent communication templates functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS fee_defaulters (
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

CREATE TABLE IF NOT EXISTS payment_reminders (
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

CREATE TABLE IF NOT EXISTS payment_plans (
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

CREATE TABLE IF NOT EXISTS communication_log (
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

CREATE TABLE IF NOT EXISTS defaulter_history (
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

CREATE TABLE IF NOT EXISTS reminder_templates (
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
CREATE INDEX idx_fee_defaulters_tenant_branch ON fee_defaulters(tenant_id, branch_id);
CREATE INDEX idx_fee_defaulters_status ON fee_defaulters(status);
CREATE INDEX idx_fee_defaulters_created_at ON fee_defaulters(created_at DESC);
CREATE INDEX idx_payment_reminders_tenant_branch ON payment_reminders(tenant_id, branch_id);
CREATE INDEX idx_payment_reminders_status ON payment_reminders(status);
CREATE INDEX idx_payment_reminders_created_at ON payment_reminders(created_at DESC);
CREATE INDEX idx_payment_plans_tenant_branch ON payment_plans(tenant_id, branch_id);
CREATE INDEX idx_payment_plans_status ON payment_plans(status);
CREATE INDEX idx_payment_plans_created_at ON payment_plans(created_at DESC);
CREATE INDEX idx_communication_log_tenant_branch ON communication_log(tenant_id, branch_id);
CREATE INDEX idx_communication_log_status ON communication_log(status);
CREATE INDEX idx_communication_log_created_at ON communication_log(created_at DESC);
CREATE INDEX idx_defaulter_history_tenant_branch ON defaulter_history(tenant_id, branch_id);
CREATE INDEX idx_defaulter_history_status ON defaulter_history(status);
CREATE INDEX idx_defaulter_history_created_at ON defaulter_history(created_at DESC);
CREATE INDEX idx_reminder_templates_tenant_branch ON reminder_templates(tenant_id, branch_id);
CREATE INDEX idx_reminder_templates_status ON reminder_templates(status);
CREATE INDEX idx_reminder_templates_created_at ON reminder_templates(created_at DESC);

-- Enable RLS
ALTER TABLE fee_defaulters ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE defaulter_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY fee_defaulters_isolation ON fee_defaulters
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY payment_reminders_isolation ON payment_reminders
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY payment_plans_isolation ON payment_plans
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY communication_log_isolation ON communication_log
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY defaulter_history_isolation ON defaulter_history
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY reminder_templates_isolation ON reminder_templates
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-385-fee-defaulter-tracking-management.ts`)

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

export class SPEC385API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('fee_defaulters')
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
      .from('fee_defaulters')
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
      .from('fee_defaulters')
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
      .from('fee_defaulters')
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
      .from('fee_defaulters')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec385API = new SPEC385API();
```

### React Component (`/components/02-accountant-portal/FeeDefaulterTrackingManagement.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function FeeDefaulterTrackingManagement() {
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
          <h1 className="text-3xl font-bold">Fee Defaulter Tracking & Management</h1>
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

### Unit Tests (`/tests/unit/spec-385-fee-defaulter-tracking-management.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec385API } from '@/lib/api/spec-385-fee-defaulter-tracking-management';

describe('SPEC-385: Fee Defaulter Tracking & Management API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec385API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec385API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec385API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec385API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { FeeDefaulterTrackingManagement } from '@/components/02-accountant-portal/FeeDefaulterTrackingManagement';

export default function Page() {
  return (
    <div className="container mx-auto">
      <FeeDefaulterTrackingManagement />
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
