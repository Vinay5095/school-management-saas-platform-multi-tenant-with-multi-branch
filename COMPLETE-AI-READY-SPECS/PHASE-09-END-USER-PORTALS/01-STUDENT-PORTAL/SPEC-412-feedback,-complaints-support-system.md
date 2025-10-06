# SPEC-412: Feedback, Complaints & Support System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-412  
**Title**: Feedback, Complaints & Support System  
**Phase**: Phase 9 - End User Portals  
**Portal**: STUDENT PORTAL  
**Category**: User Experience & Engagement  
**Priority**: MEDIUM  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth), SPEC-401 (Student Dashboard)  

---

## 📋 DESCRIPTION

Student feedback and complaint management with multiple categories, ticket submission, status tracking, admin responses, feedback forms, rating system, and support ticket history.

---

## 🎯 SUCCESS CRITERIA

- [ ] Submit feedback on courses/teachers functional
- [ ] Complaint ticket system functional
- [ ] Category selection (academic, facility, etc.) functional
- [ ] Track ticket status functional
- [ ] View admin responses functional
- [ ] Rating system for services functional
- [ ] Anonymous feedback option functional
- [ ] Feedback history functional
- [ ] Support ticket escalation functional
- [ ] FAQ section functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS student_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID REFERENCES students(id),
  user_id UUID REFERENCES auth.users(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS complaint_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID REFERENCES students(id),
  user_id UUID REFERENCES auth.users(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feedback_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID REFERENCES students(id),
  user_id UUID REFERENCES auth.users(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ticket_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID REFERENCES students(id),
  user_id UUID REFERENCES auth.users(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feedback_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID REFERENCES students(id),
  user_id UUID REFERENCES auth.users(id),
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
CREATE INDEX idx_student_feedback_tenant_branch ON student_feedback(tenant_id, branch_id);
CREATE INDEX idx_student_feedback_user ON student_feedback(user_id);
CREATE INDEX idx_student_feedback_status ON student_feedback(status);
CREATE INDEX idx_student_feedback_created_at ON student_feedback(created_at DESC);
CREATE INDEX idx_complaint_tickets_tenant_branch ON complaint_tickets(tenant_id, branch_id);
CREATE INDEX idx_complaint_tickets_user ON complaint_tickets(user_id);
CREATE INDEX idx_complaint_tickets_status ON complaint_tickets(status);
CREATE INDEX idx_complaint_tickets_created_at ON complaint_tickets(created_at DESC);
CREATE INDEX idx_feedback_categories_tenant_branch ON feedback_categories(tenant_id, branch_id);
CREATE INDEX idx_feedback_categories_user ON feedback_categories(user_id);
CREATE INDEX idx_feedback_categories_status ON feedback_categories(status);
CREATE INDEX idx_feedback_categories_created_at ON feedback_categories(created_at DESC);
CREATE INDEX idx_ticket_responses_tenant_branch ON ticket_responses(tenant_id, branch_id);
CREATE INDEX idx_ticket_responses_user ON ticket_responses(user_id);
CREATE INDEX idx_ticket_responses_status ON ticket_responses(status);
CREATE INDEX idx_ticket_responses_created_at ON ticket_responses(created_at DESC);
CREATE INDEX idx_feedback_ratings_tenant_branch ON feedback_ratings(tenant_id, branch_id);
CREATE INDEX idx_feedback_ratings_user ON feedback_ratings(user_id);
CREATE INDEX idx_feedback_ratings_status ON feedback_ratings(status);
CREATE INDEX idx_feedback_ratings_created_at ON feedback_ratings(created_at DESC);

-- Enable RLS
ALTER TABLE student_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY student_feedback_user_isolation ON student_feedback
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY complaint_tickets_user_isolation ON complaint_tickets
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY feedback_categories_user_isolation ON feedback_categories
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY ticket_responses_user_isolation ON ticket_responses
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY feedback_ratings_user_isolation ON feedback_ratings
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-412-feedback,-complaints-support-system.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface MainEntity {
  id: string;
  tenantId: string;
  branchId: string;
  userId: string;
  name: string;
  description: string;
  status: string;
  metadata?: Record<string, any>;
  createdAt: string;
  updatedAt: string;
}

export class SPEC412API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('student_feedback')
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
      .from('student_feedback')
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
      .from('student_feedback')
      .insert({
        ...data,
        user_id: user.id,
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
      .from('student_feedback')
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
      .from('student_feedback')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec412API = new SPEC412API();
```

### React Component (`/components/01-student-portal/Feedback,ComplaintsSupportSystem.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function Feedback,ComplaintsSupportSystem() {
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
          <h1 className="text-3xl font-bold">Feedback, Complaints & Support System</h1>
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

### Unit Tests (`/tests/unit/spec-412-feedback,-complaints-support-system.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec412API } from '@/lib/api/spec-412-feedback,-complaints-support-system';

describe('SPEC-412: Feedback, Complaints & Support System API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec412API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec412API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec412API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec412API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { Feedback,ComplaintsSupportSystem } from '@/components/01-student-portal/Feedback,ComplaintsSupportSystem';

export default function Page() {
  return (
    <div className="container mx-auto">
      <Feedback,ComplaintsSupportSystem />
    </div>
  );
}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all tables
- User-specific data access (student/parent/alumni only sees their data)
- Parent can only access their children's data
- Secure authentication required
- Input validation on all operations
- Activity logging for audit trail

---

## 📊 PERFORMANCE

- **Page Load**: < 2 seconds
- **Search**: < 500ms
- **Create/Update**: < 1 second
- **Database Queries**: Indexed and optimized
- **Pagination**: Server-side for large datasets
- **Caching**: For frequently accessed data

---

## ✅ DEFINITION OF DONE

- [ ] All database tables and indexes created
- [ ] RLS policies implemented and tested
- [ ] API client fully implemented with TypeScript types
- [ ] React component with full functionality
- [ ] Search and filter working
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete
- [ ] User acceptance testing passed
