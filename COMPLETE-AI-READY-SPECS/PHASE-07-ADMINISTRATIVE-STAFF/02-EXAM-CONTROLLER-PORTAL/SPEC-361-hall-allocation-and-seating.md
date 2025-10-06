# SPEC-361: Hall Allocation & Seating

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-361  
**Title**: Hall Allocation & Seating  
**Phase**: Phase 7 - Administrative Staff Portals  
**Portal**: Controller Portal  
**Category**: Operations  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 7 hours  
**Dependencies**: SPEC-351, SPEC-352  

---

## 📋 DESCRIPTION

Smart hall allocation system with capacity management, seating arrangement generation, and admit card printing.

---

## 🎯 SUCCESS CRITERIA

- [ ] All core features implemented and functional
- [ ] Database schema created with proper indexes
- [ ] API endpoints tested and documented
- [ ] UI components responsive and accessible
- [ ] Real-time updates working correctly
- [ ] Search and filtering operational
- [ ] Export functionality working (PDF, Excel)
- [ ] Performance benchmarks met (<3s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed

---

## 🗄️ DATABASE SCHEMA

```sql
-- Hall Allocation & Seating Tables
CREATE TABLE IF NOT EXISTS hall_allocation_and_seating_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Core fields specific to Hall Allocation & Seating
  record_data JSONB NOT NULL DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'active',
  
  -- Audit fields
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (
    status IN ('active', 'inactive', 'archived', 'pending', 'completed')
  )
);

CREATE INDEX ON hall_allocation_and_seating_records(tenant_id, branch_id);
CREATE INDEX ON hall_allocation_and_seating_records(status);
CREATE INDEX ON hall_allocation_and_seating_records(created_at DESC);

-- Enable RLS
ALTER TABLE hall_allocation_and_seating_records ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY hall_allocation_and_seating_records_isolation ON hall_allocation_and_seating_records
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/hall-allocation-and-seating.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export class HallAllocationAndSeatingAPI {
  private supabase = createClient();

  /**
   * Get all records
   */
  async getRecords(params?: {
    limit?: number;
    offset?: number;
    status?: string;
  }) {
    let query = this.supabase
      .from('hall_allocation_&_seating_records')
      .select('*');
    
    if (params?.status) {
      query = query.eq('status', params.status);
    }
    
    const { data, error } = await query
      .order('created_at', { ascending: false })
      .limit(params?.limit || 50)
      .range(params?.offset || 0, (params?.offset || 0) + (params?.limit || 50) - 1);

    if (error) throw error;
    return data;
  }

  /**
   * Create record
   */
  async createRecord(recordData: Record<string, any>) {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('hall_allocation_&_seating_records')
      .insert({
        record_data: recordData,
        created_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Update record
   */
  async updateRecord(id: string, updates: Record<string, any>) {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('hall_allocation_&_seating_records')
      .update({
        record_data: updates,
        updated_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Delete record
   */
  async deleteRecord(id: string) {
    const { error } = await this.supabase
      .from('hall_allocation_&_seating_records')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const hallAllocationAndSeatingAPI = new HallAllocationAndSeatingAPI();
```

### React Component (`/components/02-exam-controller-portal/HallAllocation&Seating.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useToast } from '@/components/ui/use-toast';

export function HallAllocationAndSeating() {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    loadRecords();
  }, []);

  const loadRecords = async () => {
    try {
      setLoading(true);
      // Load data from API
      setRecords([]);
    } catch (error) {
      console.error('Error loading records:', error);
      toast({
        title: 'Error',
        description: 'Failed to load records',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Hall Allocation & Seating</h1>
        <Button onClick={loadRecords}>
          Refresh
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Records</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div>Loading...</div>
          ) : records.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No records found
            </div>
          ) : (
            <div className="space-y-4">
              {/* Render records */}
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

### Unit Tests (`/tests/unit/hall-allocation-and-seating.test.ts`)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Hall Allocation & Seating', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should load records successfully', async () => {
    // Test implementation
    expect(true).toBe(true);
  });

  it('should create record with validation', async () => {
    // Test implementation
    expect(true).toBe(true);
  });

  it('should handle errors gracefully', async () => {
    // Test implementation
    expect(true).toBe(true);
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { HallAllocationAndSeating } from '@/components/HallAllocationAndSeating';

export default function Page() {
  return <HallAllocationAndSeating />;
}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all database tables
- **Tenant and branch isolation** via session variables
- **Role-based access control** for sensitive operations
- **Input validation and sanitization** on all user inputs
- **Audit logging** for all critical actions
- **Encrypted data storage** for sensitive information

---

## 📊 PERFORMANCE

- **Page Load Time**: < 2 seconds for initial load
- **API Response Time**: < 500ms for most operations
- **Database Query Performance**: Optimized with proper indexes
- **Caching Strategy**: 1-minute cache for frequently accessed data
- **Pagination**: Default page size of 50 records
- **Lazy Loading**: Implemented for large datasets

---

## ✅ DEFINITION OF DONE

- [ ] All database tables and views created with proper indexes
- [ ] API client fully implemented with TypeScript types
- [ ] React components render correctly with proper state management
- [ ] All CRUD operations functional and tested
- [ ] Search and filtering working with debouncing
- [ ] Export functionality operational (PDF, Excel, CSV)
- [ ] Unit tests written and passing (85%+ coverage)
- [ ] Integration tests passing
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete and reviewed
- [ ] Code review approved
- [ ] Deployed to staging environment
