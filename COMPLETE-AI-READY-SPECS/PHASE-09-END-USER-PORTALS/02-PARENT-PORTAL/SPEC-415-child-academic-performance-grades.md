# SPEC-415: Child Academic Performance & Grades

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-415  
**Title**: Child Academic Performance & Grades  
**Phase**: Phase 9 - End User Portals  
**Portal**: PARENT PORTAL  
**Category**: User Experience & Engagement  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 7 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth), SPEC-413 (Parent Dashboard)  

---

## 📋 DESCRIPTION

Comprehensive academic performance tracking with subject-wise marks, exam results, progress reports, grade trends, class comparison, teacher remarks, strengths/weaknesses analysis, and downloadable report cards.

---

## 🎯 SUCCESS CRITERIA

- [ ] Subject-wise marks and grades functional
- [ ] Exam results (all assessments) functional
- [ ] Progress reports by term functional
- [ ] Grade trend analysis functional
- [ ] Class rank and comparison functional
- [ ] Teacher remarks and feedback functional
- [ ] Strengths and weaknesses functional
- [ ] Assignment completion status functional
- [ ] Project marks and feedback functional
- [ ] Downloadable report cards functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS child_academic_performance (
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

CREATE TABLE IF NOT EXISTS exam_results_parent_view (
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

CREATE TABLE IF NOT EXISTS progress_reports (
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

CREATE TABLE IF NOT EXISTS grade_trends (
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

CREATE TABLE IF NOT EXISTS teacher_remarks (
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
CREATE INDEX idx_child_academic_performance_tenant_branch ON child_academic_performance(tenant_id, branch_id);
CREATE INDEX idx_child_academic_performance_user ON child_academic_performance(user_id);
CREATE INDEX idx_child_academic_performance_status ON child_academic_performance(status);
CREATE INDEX idx_child_academic_performance_created_at ON child_academic_performance(created_at DESC);
CREATE INDEX idx_exam_results_parent_view_tenant_branch ON exam_results_parent_view(tenant_id, branch_id);
CREATE INDEX idx_exam_results_parent_view_user ON exam_results_parent_view(user_id);
CREATE INDEX idx_exam_results_parent_view_status ON exam_results_parent_view(status);
CREATE INDEX idx_exam_results_parent_view_created_at ON exam_results_parent_view(created_at DESC);
CREATE INDEX idx_progress_reports_tenant_branch ON progress_reports(tenant_id, branch_id);
CREATE INDEX idx_progress_reports_user ON progress_reports(user_id);
CREATE INDEX idx_progress_reports_status ON progress_reports(status);
CREATE INDEX idx_progress_reports_created_at ON progress_reports(created_at DESC);
CREATE INDEX idx_grade_trends_tenant_branch ON grade_trends(tenant_id, branch_id);
CREATE INDEX idx_grade_trends_user ON grade_trends(user_id);
CREATE INDEX idx_grade_trends_status ON grade_trends(status);
CREATE INDEX idx_grade_trends_created_at ON grade_trends(created_at DESC);
CREATE INDEX idx_teacher_remarks_tenant_branch ON teacher_remarks(tenant_id, branch_id);
CREATE INDEX idx_teacher_remarks_user ON teacher_remarks(user_id);
CREATE INDEX idx_teacher_remarks_status ON teacher_remarks(status);
CREATE INDEX idx_teacher_remarks_created_at ON teacher_remarks(created_at DESC);

-- Enable RLS
ALTER TABLE child_academic_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_results_parent_view ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_remarks ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY child_academic_performance_user_isolation ON child_academic_performance
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY exam_results_parent_view_user_isolation ON exam_results_parent_view
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY progress_reports_user_isolation ON progress_reports
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY grade_trends_user_isolation ON grade_trends
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY teacher_remarks_user_isolation ON teacher_remarks
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-415-child-academic-performance-grades.ts`)

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

export class SPEC415API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('child_academic_performance')
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
      .from('child_academic_performance')
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
      .from('child_academic_performance')
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
      .from('child_academic_performance')
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
      .from('child_academic_performance')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec415API = new SPEC415API();
```

### React Component (`/components/02-parent-portal/ChildAcademicPerformanceGrades.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function ChildAcademicPerformanceGrades() {
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
          <h1 className="text-3xl font-bold">Child Academic Performance & Grades</h1>
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

### Unit Tests (`/tests/unit/spec-415-child-academic-performance-grades.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec415API } from '@/lib/api/spec-415-child-academic-performance-grades';

describe('SPEC-415: Child Academic Performance & Grades API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec415API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec415API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec415API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec415API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { ChildAcademicPerformanceGrades } from '@/components/02-parent-portal/ChildAcademicPerformanceGrades';

export default function Page() {
  return (
    <div className="container mx-auto">
      <ChildAcademicPerformanceGrades />
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
