# SPEC-390: Scholarship & Discount Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-390  
**Title**: Scholarship & Discount Management  
**Phase**: Phase 8 - Support Staff Portals  
**Portal**: ACCOUNTANT PORTAL  
**Category**: Operations & Management  
**Priority**: MEDIUM  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth), SPEC-382 (Accountant Dashboard)  

---

## 📋 DESCRIPTION

Comprehensive scholarship and discount management with scholarship tracking, discount rule engine, merit-based discounts, sibling discount automation, staff concession management, and scholarship reports.

---

## 🎯 SUCCESS CRITERIA

- [ ] Scholarship program management functional
- [ ] Discount rule configuration functional
- [ ] Merit-based discount automation functional
- [ ] Sibling discount calculation functional
- [ ] Staff child concession functional
- [ ] Scholarship application tracking functional
- [ ] Discount approval workflow functional
- [ ] Scholarship reports and analytics functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS scholarships (
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

CREATE TABLE IF NOT EXISTS discount_rules (
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

CREATE TABLE IF NOT EXISTS student_scholarships (
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

CREATE TABLE IF NOT EXISTS discount_applications (
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

CREATE TABLE IF NOT EXISTS scholarship_criteria (
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
CREATE INDEX idx_scholarships_tenant_branch ON scholarships(tenant_id, branch_id);
CREATE INDEX idx_scholarships_status ON scholarships(status);
CREATE INDEX idx_scholarships_created_at ON scholarships(created_at DESC);
CREATE INDEX idx_discount_rules_tenant_branch ON discount_rules(tenant_id, branch_id);
CREATE INDEX idx_discount_rules_status ON discount_rules(status);
CREATE INDEX idx_discount_rules_created_at ON discount_rules(created_at DESC);
CREATE INDEX idx_student_scholarships_tenant_branch ON student_scholarships(tenant_id, branch_id);
CREATE INDEX idx_student_scholarships_status ON student_scholarships(status);
CREATE INDEX idx_student_scholarships_created_at ON student_scholarships(created_at DESC);
CREATE INDEX idx_discount_applications_tenant_branch ON discount_applications(tenant_id, branch_id);
CREATE INDEX idx_discount_applications_status ON discount_applications(status);
CREATE INDEX idx_discount_applications_created_at ON discount_applications(created_at DESC);
CREATE INDEX idx_scholarship_criteria_tenant_branch ON scholarship_criteria(tenant_id, branch_id);
CREATE INDEX idx_scholarship_criteria_status ON scholarship_criteria(status);
CREATE INDEX idx_scholarship_criteria_created_at ON scholarship_criteria(created_at DESC);

-- Enable RLS
ALTER TABLE scholarships ENABLE ROW LEVEL SECURITY;
ALTER TABLE discount_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_scholarships ENABLE ROW LEVEL SECURITY;
ALTER TABLE discount_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE scholarship_criteria ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY scholarships_isolation ON scholarships
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY discount_rules_isolation ON discount_rules
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY student_scholarships_isolation ON student_scholarships
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY discount_applications_isolation ON discount_applications
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY scholarship_criteria_isolation ON scholarship_criteria
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-390-scholarship-discount-management.ts`)

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

export class SPEC390API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('scholarships')
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
      .from('scholarships')
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
      .from('scholarships')
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
      .from('scholarships')
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
      .from('scholarships')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec390API = new SPEC390API();
```

### React Component (`/components/02-accountant-portal/ScholarshipDiscountManagement.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function ScholarshipDiscountManagement() {
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
          <h1 className="text-3xl font-bold">Scholarship & Discount Management</h1>
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

### Unit Tests (`/tests/unit/spec-390-scholarship-discount-management.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec390API } from '@/lib/api/spec-390-scholarship-discount-management';

describe('SPEC-390: Scholarship & Discount Management API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec390API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec390API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec390API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec390API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { ScholarshipDiscountManagement } from '@/components/02-accountant-portal/ScholarshipDiscountManagement';

export default function Page() {
  return (
    <div className="container mx-auto">
      <ScholarshipDiscountManagement />
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
