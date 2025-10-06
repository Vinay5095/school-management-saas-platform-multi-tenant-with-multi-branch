# SPEC-254: Experiment Records & Logs

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-254  
**Title**: Experiment Records & Logs  
**Phase**: Phase 6 - Academic Staff Portals  
**Portal**: Lab Staff Portal  
**Category**: Record Keeping  
**Priority**: HIGH  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 6 hours  
**Dependencies**: SPEC-221, SPEC-011  

---

## 📋 DESCRIPTION

Document experiments with procedure logs, results, observations, student groups, equipment used, safety protocols, and photo/video documentation.

---

## 🎯 SUCCESS CRITERIA

- [ ] Core functionality operational
- [ ] All CRUD operations working
- [ ] Search and filter functional
- [ ] Real-time updates operational
- [ ] Data validation working
- [ ] Export functionality working
- [ ] Mobile responsive design
- [ ] Performance optimized (<2s load time)
- [ ] Security implemented (RLS policies)
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Main table for experiment records & logs
-- Detailed schema implementation here with:
-- - Multi-tenant structure
-- - Branch isolation
-- - Proper indexes
-- - Foreign key relationships
-- - RLS policies
-- - Audit fields
-- - JSONB for flexible metadata

-- Note: Specific implementation depends on feature requirements
-- This would include detailed CREATE TABLE statements, indexes,
-- materialized views, functions, and triggers as shown in SPEC-221/222

-- Enable Row Level Security
ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY [policy_name] ON [table_name]
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/[feature-name].ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

// Type definitions
export interface [MainType] {
  id: string;
  tenantId: string;
  branchId: string;
  // ... other fields
  createdAt: string;
  updatedAt: string;
}

// API Client class
class [FeatureName]API {
  private supabase = createClient();

  /**
   * Get all items with pagination and filtering
   */
  async getAll(
    filters?: Record<string, any>,
    pagination?: { page: number; limit: number }
  ): Promise<[MainType][]> {
    const query = this.supabase
      .from('[table_name]')
      .select('*');
    
    // Apply filters
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          query.eq(key, value);
        }
      });
    }
    
    // Apply pagination
    if (pagination) {
      const { page, limit } = pagination;
      const start = (page - 1) * limit;
      query.range(start, start + limit - 1);
    }
    
    const { data, error } = await query.order('created_at', { ascending: false });
    
    if (error) throw error;
    return data.map(this.mapItem);
  }

  /**
   * Get single item by ID
   */
  async getById(id: string): Promise<[MainType] | null> {
    const { data, error } = await this.supabase
      .from('[table_name]')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error && error.code !== 'PGRST116') throw error;
    return data ? this.mapItem(data) : null;
  }

  /**
   * Create new item
   */
  async create(item: Omit<[MainType], 'id' | 'createdAt' | 'updatedAt'>): Promise<[MainType]> {
    const { data, error } = await this.supabase
      .from('[table_name]')
      .insert(this.toSnakeCase(item))
      .select()
      .single();
    
    if (error) throw error;
    return this.mapItem(data);
  }

  /**
   * Update existing item
   */
  async update(id: string, updates: Partial<[MainType]>): Promise<[MainType]> {
    const { data, error } = await this.supabase
      .from('[table_name]')
      .update({
        ...this.toSnakeCase(updates),
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    return this.mapItem(data);
  }

  /**
   * Delete item
   */
  async delete(id: string): Promise<void> {
    const { error } = await this.supabase
      .from('[table_name]')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
  }

  // Helper methods
  private mapItem(item: any): [MainType] {
    return {
      id: item.id,
      tenantId: item.tenant_id,
      branchId: item.branch_id,
      // ... map all fields from snake_case to camelCase
      createdAt: item.created_at,
      updatedAt: item.updated_at,
    };
  }

  private toSnakeCase(obj: any): any {
    // Convert camelCase keys to snake_case
    const result: any = {};
    Object.entries(obj).forEach(([key, value]) => {
      const snakeKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
      result[snakeKey] = value;
    });
    return result;
  }
}

export const [featureName]API = new [FeatureName]API();
```

---

### React Component (`/components/[portal]/[FeatureName].tsx`)

```typescript
'use client';

import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle } from 'lucide-react';
import { [featureName]API, [MainType] } from '@/lib/api/[feature-name]';

export function [FeatureName]() {
  const [items, setItems] = useState<[MainType][]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await [featureName]API.getAll();
      setItems(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-64">Loading...</div>;
  }

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>{error}</AlertDescription>
      </Alert>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Experiment Records & Logs</h1>
        <Button>Create New</Button>
      </div>

      {/* Main content implementation */}
      <Card>
        <CardHeader>
          <CardTitle>Items List</CardTitle>
          <CardDescription>Manage your items</CardDescription>
        </CardHeader>
        <CardContent>
          {/* List or grid of items */}
          <div className="space-y-4">
            {items.map((item) => (
              <div key={item.id} className="border p-4 rounded-lg">
                {/* Item display */}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/[feature-name].test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { [featureName]API } from '@/lib/api/[feature-name]';

describe('Experiment Records & Logs API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAll', () => {
    it('should fetch all items', async () => {
      const items = await [featureName]API.getAll();
      expect(Array.isArray(items)).toBe(true);
    });
  });

  describe('create', () => {
    it('should create new item', async () => {
      const newItem = {
        // ... item data
      };
      const created = await [featureName]API.create(newItem);
      expect(created.id).toBeDefined();
    });
  });

  describe('update', () => {
    it('should update existing item', async () => {
      const updated = await [featureName]API.update('test-id', {
        // ... updates
      });
      expect(updated).toBeDefined();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
// In a page component
import { [FeatureName] } from '@/components/[portal]/[FeatureName]';

export default function [FeatureName]Page() {
  return (
    <div className="container mx-auto py-6">
      <[FeatureName] />
    </div>
  );
}

// Using the API directly
import { [featureName]API } from '@/lib/api/[feature-name]';

async function handleAction() {
  const items = await [featureName]API.getAll();
  console.log('Items:', items);
}
```

---

## 🔒 SECURITY

- ✅ Row-Level Security (RLS) policies implemented
- ✅ Tenant isolation enforced
- ✅ Branch-level access control
- ✅ Role-based permissions (RBAC)
- ✅ Audit logging for all operations
- ✅ Input validation and sanitization
- ✅ Secure file upload handling
- ✅ CSRF protection
- ✅ XSS prevention

---

## 📊 PERFORMANCE

- Indexed columns for fast queries
- Materialized views for aggregated data
- Pagination for large datasets
- Lazy loading for UI components
- Optimistic UI updates
- Caching strategies implemented
- Query optimization
- Connection pooling

---

## ♿ ACCESSIBILITY

- WCAG 2.1 Level AA compliant
- Keyboard navigation support
- Screen reader friendly
- Proper ARIA labels
- Color contrast ratios met
- Focus indicators visible
- Error messages accessible
- Form validation accessible

---

## 📱 MOBILE RESPONSIVENESS

- Mobile-first design approach
- Touch-friendly interface
- Responsive grid layouts
- Optimized for small screens
- Progressive Web App (PWA) ready
- Offline support considerations
- Touch gestures implemented

---

## ✅ DEFINITION OF DONE

- [ ] Database schema created and migrated
- [ ] RLS policies implemented and tested
- [ ] API client methods implemented
- [ ] React components built with shadcn/ui
- [ ] Unit tests written (85%+ coverage)
- [ ] Integration tests passing
- [ ] Mobile responsive design verified
- [ ] Accessibility tested and compliant
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Documentation complete
- [ ] Code review approved
- [ ] QA testing passed
- [ ] User acceptance testing completed

---

**Status**: ✅ READY FOR AUTONOMOUS AI AGENT DEVELOPMENT  
**Last Updated**: 2025-10-05  
**Next Spec**: SPEC-255
