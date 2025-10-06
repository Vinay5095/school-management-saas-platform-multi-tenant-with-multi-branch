# SPEC-425: Alumni Dashboard & Profile

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-425  
**Title**: Alumni Dashboard & Profile  
**Phase**: Phase 9 - End User Portals  
**Portal**: ALUMNI PORTAL  
**Category**: User Experience & Engagement  
**Priority**: HIGH  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth)  

---

## 📋 DESCRIPTION

Alumni dashboard with profile management, professional information, career updates, batch details, achievements showcase, networking stats, event calendar, and alumni directory access.

---

## 🎯 SUCCESS CRITERIA

- [ ] Personalized alumni dashboard functional
- [ ] Profile management (personal & professional) functional
- [ ] Current employment details functional
- [ ] Career progression timeline functional
- [ ] Achievements showcase functional
- [ ] Batch and year information functional
- [ ] Alumni statistics functional
- [ ] Upcoming alumni events functional
- [ ] Recent alumni news functional
- [ ] Quick networking actions functional
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
CREATE TABLE IF NOT EXISTS alumni_profiles (
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

CREATE TABLE IF NOT EXISTS professional_info (
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

CREATE TABLE IF NOT EXISTS achievements (
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

CREATE TABLE IF NOT EXISTS batch_details (
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

CREATE TABLE IF NOT EXISTS alumni_activity_log (
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
CREATE INDEX idx_alumni_profiles_tenant_branch ON alumni_profiles(tenant_id, branch_id);
CREATE INDEX idx_alumni_profiles_user ON alumni_profiles(user_id);
CREATE INDEX idx_alumni_profiles_status ON alumni_profiles(status);
CREATE INDEX idx_alumni_profiles_created_at ON alumni_profiles(created_at DESC);
CREATE INDEX idx_professional_info_tenant_branch ON professional_info(tenant_id, branch_id);
CREATE INDEX idx_professional_info_user ON professional_info(user_id);
CREATE INDEX idx_professional_info_status ON professional_info(status);
CREATE INDEX idx_professional_info_created_at ON professional_info(created_at DESC);
CREATE INDEX idx_achievements_tenant_branch ON achievements(tenant_id, branch_id);
CREATE INDEX idx_achievements_user ON achievements(user_id);
CREATE INDEX idx_achievements_status ON achievements(status);
CREATE INDEX idx_achievements_created_at ON achievements(created_at DESC);
CREATE INDEX idx_batch_details_tenant_branch ON batch_details(tenant_id, branch_id);
CREATE INDEX idx_batch_details_user ON batch_details(user_id);
CREATE INDEX idx_batch_details_status ON batch_details(status);
CREATE INDEX idx_batch_details_created_at ON batch_details(created_at DESC);
CREATE INDEX idx_alumni_activity_log_tenant_branch ON alumni_activity_log(tenant_id, branch_id);
CREATE INDEX idx_alumni_activity_log_user ON alumni_activity_log(user_id);
CREATE INDEX idx_alumni_activity_log_status ON alumni_activity_log(status);
CREATE INDEX idx_alumni_activity_log_created_at ON alumni_activity_log(created_at DESC);

-- Enable RLS
ALTER TABLE alumni_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE professional_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY alumni_profiles_user_isolation ON alumni_profiles
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY professional_info_user_isolation ON professional_info
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY achievements_user_isolation ON achievements
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY batch_details_user_isolation ON batch_details
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );

CREATE POLICY alumni_activity_log_user_isolation ON alumni_activity_log
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-425-alumni-dashboard-profile.ts`)

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

export class SPEC425API {
  private supabase = createClient();

  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('alumni_profiles')
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
      .from('alumni_profiles')
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
      .from('alumni_profiles')
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
      .from('alumni_profiles')
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
      .from('alumni_profiles')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const spec425API = new SPEC425API();
```

### React Component (`/components/03-alumni-portal/AlumniDashboardProfile.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/use-toast';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';

export function AlumniDashboardProfile() {
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
          <h1 className="text-3xl font-bold">Alumni Dashboard & Profile</h1>
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

### Unit Tests (`/tests/unit/spec-425-alumni-dashboard-profile.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { spec425API } from '@/lib/api/spec-425-alumni-dashboard-profile';

describe('SPEC-425: Alumni Dashboard & Profile API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CRUD Operations', () => {
    it('should fetch all records', async () => {
      const result = await spec425API.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    });

    it('should create new record', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test Description'
      };
      const created = await spec425API.create(newItem);
      expect(created).toHaveProperty('id');
    });

    it('should update existing record', async () => {
      const updated = await spec425API.update('test-id', {
        name: 'Updated Name'
      });
      expect(updated.name).toBe('Updated Name');
    });

    it('should delete record', async () => {
      await expect(spec425API.delete('test-id')).resolves.not.toThrow();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { AlumniDashboardProfile } from '@/components/03-alumni-portal/AlumniDashboardProfile';

export default function Page() {
  return (
    <div className="container mx-auto">
      <AlumniDashboardProfile />
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
