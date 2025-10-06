# SPEC-132: Ticket Management Dashboard

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-132  
**Title**: Support Ticket Management Dashboard  
**Phase**: Phase 3 - Platform Portals  
**Portal**: Platform Support Portal  
**Category**: Frontend Component  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-131 (Database Schema)  

---

## 📋 DESCRIPTION

Build a comprehensive ticket management dashboard for support agents to view, filter, search, and manage support tickets efficiently. The dashboard provides real-time ticket queue views, SLA monitoring, quick actions, and performance metrics.

---

## 🎯 SUCCESS CRITERIA

- [ ] Dashboard displays ticket queue with real-time updates
- [ ] Advanced filtering and search working correctly
- [ ] Bulk actions functional
- [ ] SLA indicators showing accurately
- [ ] Quick actions responsive
- [ ] Performance metrics displaying correctly
- [ ] Responsive design working on all devices
- [ ] All accessibility requirements met (WCAG 2.1 AA)
- [ ] Unit tests passing (85%+ coverage)
- [ ] E2E tests passing

---

## 🎨 UI/UX DESIGN

### Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│ Header: Platform Support Portal                    [Profile]│
├─────────────────────────────────────────────────────────────┤
│ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐│
│ │  My Queue  │ │ Unassigned │ │   All     │ │  Closed    ││
│ │    42      │ │     18     │ │   156     │ │    89      ││
│ └────────────┘ └────────────┘ └────────────┘ └────────────┘│
├─────────────────────────────────────────────────────────────┤
│ [Search...] [Status▾] [Priority▾] [Category▾] [Date Range▾]│
│                                           [Bulk Actions▾] [+]│
├────────┬────────────────────────────────────────────────────┤
│        │ Ticket#   Subject            Status  Priority  SLA │
│ Sidebar│ ──────────────────────────────────────────────────│
│        │ □ TKT-001 Login not working   Open    Critical  🔴│
│ - My   │ □ TKT-002 Billing question    Open    High      🟡│
│ Queue  │ □ TKT-003 Feature request     New     Medium    🟢│
│        │ □ TKT-004 Report issue        Progress Low      🟢│
│ - Un-  │ ⋮                                                  │
│ assigned                                                     │
│        │                                                     │
│ - All  │                              [Load More]           │
│ Tickets│                                                     │
│        │                                                     │
│ - SLA  │                                                     │
│ Breach │                                                     │
└────────┴────────────────────────────────────────────────────┘
```

### Color Coding

**Priority Colors:**
- 🔴 Critical: Red (#DC2626)
- 🟠 High: Orange (#F59E0B)
- 🔵 Medium: Blue (#3B82F6)
- ⚪ Low: Gray (#6B7280)

**SLA Status:**
- 🔴 Breached: Red background
- 🟡 Warning (< 20% time left): Yellow background
- 🟢 On Track: Green indicator

**Status Colors:**
- New: Blue
- Open: Green
- In Progress: Purple
- Waiting: Orange
- Resolved: Gray
- Closed: Dark Gray

---

## 💻 IMPLEMENTATION

### 1. API Client (`/lib/api/support-tickets.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import type { 
  SupportTicket, 
  TicketFilters, 
  TicketStats,
  BulkActionResult 
} from '@/types/support';

export class SupportTicketsAPI {
  private supabase = createClient();

  /**
   * Fetch tickets with filters and pagination
   */
  async getTickets(
    filters: TicketFilters,
    page: number = 1,
    pageSize: number = 50
  ): Promise<{
    data: SupportTicket[];
    count: number;
    hasMore: boolean;
  }> {
    let query = this.supabase
      .from('support_tickets')
      .select(`
        *,
        category:support_ticket_categories(*),
        customer:auth.users!customer_id(id, email, full_name),
        assigned_user:auth.users!assigned_to(id, email, full_name),
        messages:ticket_messages(count)
      `, { count: 'exact' });

    // Apply filters
    if (filters.status && filters.status.length > 0) {
      query = query.in('status', filters.status);
    }

    if (filters.priority && filters.priority.length > 0) {
      query = query.in('priority', filters.priority);
    }

    if (filters.assignedTo === 'me') {
      const { data: { user } } = await this.supabase.auth.getUser();
      query = query.eq('assigned_to', user?.id);
    } else if (filters.assignedTo === 'unassigned') {
      query = query.is('assigned_to', null);
    } else if (filters.assignedTo) {
      query = query.eq('assigned_to', filters.assignedTo);
    }

    if (filters.categoryId) {
      query = query.eq('category_id', filters.categoryId);
    }

    if (filters.tenantId) {
      query = query.eq('tenant_id', filters.tenantId);
    }

    if (filters.search) {
      query = query.or(`subject.ilike.%${filters.search}%,description.ilike.%${filters.search}%,ticket_number.ilike.%${filters.search}%`);
    }

    if (filters.slaStatus) {
      if (filters.slaStatus === 'breached') {
        query = query
          .is('first_response_at', null)
          .lt('sla_target_response', new Date().toISOString());
      } else if (filters.slaStatus === 'warning') {
        const warningTime = new Date(Date.now() + 30 * 60000).toISOString();
        query = query
          .is('first_response_at', null)
          .lt('sla_target_response', warningTime)
          .gte('sla_target_response', new Date().toISOString());
      }
    }

    if (filters.dateFrom) {
      query = query.gte('created_at', filters.dateFrom);
    }

    if (filters.dateTo) {
      query = query.lte('created_at', filters.dateTo);
    }

    // Sorting
    const sortField = filters.sortBy || 'created_at';
    const sortOrder = filters.sortOrder || 'desc';
    query = query.order(sortField, { ascending: sortOrder === 'asc' });

    // Pagination
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      data: data || [],
      count: count || 0,
      hasMore: count ? count > page * pageSize : false,
    };
  }

  /**
   * Get ticket statistics
   */
  async getTicketStats(): Promise<TicketStats> {
    const { data: { user } } = await this.supabase.auth.getUser();

    const [
      myQueue,
      unassigned,
      allOpen,
      slaBreached,
      resolvedToday,
    ] = await Promise.all([
      // My queue
      this.supabase
        .from('support_tickets')
        .select('id', { count: 'exact', head: true })
        .eq('assigned_to', user?.id)
        .in('status', ['new', 'open', 'in_progress']),

      // Unassigned
      this.supabase
        .from('support_tickets')
        .select('id', { count: 'exact', head: true })
        .is('assigned_to', null)
        .in('status', ['new', 'open']),

      // All open
      this.supabase
        .from('support_tickets')
        .select('id', { count: 'exact', head: true })
        .in('status', ['new', 'open', 'in_progress']),

      // SLA breached
      this.supabase
        .from('support_tickets')
        .select('id', { count: 'exact', head: true })
        .is('first_response_at', null)
        .lt('sla_target_response', new Date().toISOString())
        .in('status', ['new', 'open', 'in_progress']),

      // Resolved today
      this.supabase
        .from('support_tickets')
        .select('id', { count: 'exact', head: true })
        .eq('assigned_to', user?.id)
        .gte('resolved_at', new Date().setHours(0, 0, 0, 0)),
    ]);

    return {
      myQueue: myQueue.count || 0,
      unassigned: unassigned.count || 0,
      allOpen: allOpen.count || 0,
      slaBreached: slaBreached.count || 0,
      resolvedToday: resolvedToday.count || 0,
    };
  }

  /**
   * Bulk update tickets
   */
  async bulkUpdate(
    ticketIds: string[],
    updates: Partial<SupportTicket>
  ): Promise<BulkActionResult> {
    const { data, error } = await this.supabase
      .from('support_tickets')
      .update(updates)
      .in('id', ticketIds)
      .select('id');

    if (error) throw error;

    return {
      success: true,
      updatedCount: data?.length || 0,
      failedCount: ticketIds.length - (data?.length || 0),
    };
  }

  /**
   * Assign ticket to agent
   */
  async assignTicket(ticketId: string, agentId: string | null): Promise<void> {
    const { error } = await this.supabase
      .from('support_tickets')
      .update({
        assigned_to: agentId,
        assigned_at: agentId ? new Date().toISOString() : null,
      })
      .eq('id', ticketId);

    if (error) throw error;
  }

  /**
   * Update ticket status
   */
  async updateStatus(ticketId: string, status: string): Promise<void> {
    const updates: any = { status };

    if (status === 'resolved') {
      updates.resolved_at = new Date().toISOString();
    } else if (status === 'closed') {
      updates.closed_at = new Date().toISOString();
    }

    const { error } = await this.supabase
      .from('support_tickets')
      .update(updates)
      .eq('id', ticketId);

    if (error) throw error;
  }

  /**
   * Subscribe to real-time ticket updates
   */
  subscribeToTickets(
    filters: TicketFilters,
    callback: (payload: any) => void
  ) {
    let channel = this.supabase
      .channel('ticket-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'support_tickets',
        },
        callback
      );

    // Apply filters to subscription if needed
    if (filters.assignedTo === 'me') {
      // Filter handled client-side after receiving update
    }

    channel.subscribe();

    return () => {
      channel.unsubscribe();
    };
  }
}

export const supportTicketsAPI = new SupportTicketsAPI();
```

### 2. Type Definitions (`/types/support.ts`)

```typescript
export interface SupportTicket {
  id: string;
  ticket_number: string;
  tenant_id: string;
  customer_id: string;
  customer_name: string;
  customer_email: string;
  subject: string;
  description: string;
  category_id: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  status: 'new' | 'open' | 'in_progress' | 'waiting_customer' | 'waiting_internal' | 'resolved' | 'closed' | 'cancelled';
  assigned_to: string | null;
  assigned_at: string | null;
  team: string | null;
  sla_target_response: string;
  sla_target_resolution: string;
  first_response_at: string | null;
  resolved_at: string | null;
  closed_at: string | null;
  response_time_minutes: number | null;
  resolution_time_minutes: number | null;
  reopened_count: number;
  satisfaction_rating: number | null;
  satisfaction_comment: string | null;
  source: string;
  tags: string[];
  custom_fields: Record<string, any>;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
  last_activity_at: string;
  
  // Relations
  category?: TicketCategory;
  customer?: User;
  assigned_user?: User;
  messages?: { count: number };
}

export interface TicketCategory {
  id: string;
  name: string;
  slug: string;
  description: string;
  color: string;
  icon: string;
}

export interface TicketFilters {
  status?: string[];
  priority?: string[];
  assignedTo?: string | 'me' | 'unassigned';
  categoryId?: string;
  tenantId?: string;
  search?: string;
  slaStatus?: 'breached' | 'warning' | 'on_track';
  dateFrom?: string;
  dateTo?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface TicketStats {
  myQueue: number;
  unassigned: number;
  allOpen: number;
  slaBreached: number;
  resolvedToday: number;
}

export interface BulkActionResult {
  success: boolean;
  updatedCount: number;
  failedCount: number;
}

export interface User {
  id: string;
  email: string;
  full_name: string;
}
```

### 3. Main Dashboard Component (`/app/(portal)/support/tickets/page.tsx`)

```typescript
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { supportTicketsAPI } from '@/lib/api/support-tickets';
import { TicketList } from '@/components/support/TicketList';
import { TicketFilters as FilterComponent } from '@/components/support/TicketFilters';
import { TicketStats as StatsCards } from '@/components/support/TicketStats';
import { BulkActionsBar } from '@/components/support/BulkActionsBar';
import { Button } from '@/components/ui/button';
import { Plus, RefreshCw } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import type { SupportTicket, TicketFilters, TicketStats } from '@/types/support';

export default function TicketsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { toast } = useToast();

  // State
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [stats, setStats] = useState<TicketStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [selectedTickets, setSelectedTickets] = useState<Set<string>>(new Set());

  // Filters from URL params
  const [filters, setFilters] = useState<TicketFilters>(() => {
    const status = searchParams.get('status')?.split(',') || undefined;
    const priority = searchParams.get('priority')?.split(',') || undefined;
    const assignedTo = searchParams.get('assigned') || 'me';
    const categoryId = searchParams.get('category') || undefined;
    const search = searchParams.get('q') || undefined;
    const slaStatus = searchParams.get('sla') as any || undefined;

    return {
      status,
      priority,
      assignedTo,
      categoryId,
      search,
      slaStatus,
      sortBy: 'created_at',
      sortOrder: 'desc',
    };
  });

  // Load tickets
  const loadTickets = useCallback(async (pageNum: number = 1, append: boolean = false) => {
    try {
      if (!append) setLoading(true);
      
      const result = await supportTicketsAPI.getTickets(filters, pageNum);
      
      setTickets(prev => append ? [...prev, ...result.data] : result.data);
      setHasMore(result.hasMore);
      setPage(pageNum);
    } catch (error) {
      console.error('Error loading tickets:', error);
      toast({
        title: 'Error',
        description: 'Failed to load tickets. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [filters, toast]);

  // Load stats
  const loadStats = useCallback(async () => {
    try {
      const statsData = await supportTicketsAPI.getTicketStats();
      setStats(statsData);
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  }, []);

  // Initial load
  useEffect(() => {
    loadTickets();
    loadStats();
  }, [loadTickets, loadStats]);

  // Real-time updates
  useEffect(() => {
    const unsubscribe = supportTicketsAPI.subscribeToTickets(filters, (payload) => {
      console.log('Ticket updated:', payload);
      
      // Refresh tickets and stats
      loadTickets(1, false);
      loadStats();
    });

    return () => {
      unsubscribe();
    };
  }, [filters, loadTickets, loadStats]);

  // Handle filter changes
  const handleFilterChange = (newFilters: Partial<TicketFilters>) => {
    const updated = { ...filters, ...newFilters };
    setFilters(updated);
    
    // Update URL params
    const params = new URLSearchParams();
    if (updated.status) params.set('status', updated.status.join(','));
    if (updated.priority) params.set('priority', updated.priority.join(','));
    if (updated.assignedTo) params.set('assigned', updated.assignedTo);
    if (updated.categoryId) params.set('category', updated.categoryId);
    if (updated.search) params.set('q', updated.search);
    if (updated.slaStatus) params.set('sla', updated.slaStatus);
    
    router.push(`/support/tickets?${params.toString()}`);
  };

  // Handle refresh
  const handleRefresh = () => {
    setRefreshing(true);
    loadTickets(1, false);
    loadStats();
  };

  // Handle load more
  const handleLoadMore = () => {
    loadTickets(page + 1, true);
  };

  // Handle ticket selection
  const handleSelectTicket = (ticketId: string, selected: boolean) => {
    setSelectedTickets(prev => {
      const newSet = new Set(prev);
      if (selected) {
        newSet.add(ticketId);
      } else {
        newSet.delete(ticketId);
      }
      return newSet;
    });
  };

  // Handle select all
  const handleSelectAll = (selected: boolean) => {
    if (selected) {
      setSelectedTickets(new Set(tickets.map(t => t.id)));
    } else {
      setSelectedTickets(new Set());
    }
  };

  // Handle bulk actions
  const handleBulkAction = async (action: string, value?: any) => {
    try {
      const ticketIds = Array.from(selectedTickets);
      
      let updates: any = {};
      if (action === 'assign') {
        updates.assigned_to = value;
        updates.assigned_at = new Date().toISOString();
      } else if (action === 'status') {
        updates.status = value;
      } else if (action === 'priority') {
        updates.priority = value;
      }

      await supportTicketsAPI.bulkUpdate(ticketIds, updates);

      toast({
        title: 'Success',
        description: `Updated ${ticketIds.length} ticket(s)`,
      });

      // Clear selection and refresh
      setSelectedTickets(new Set());
      loadTickets(1, false);
      loadStats();
    } catch (error) {
      console.error('Bulk action error:', error);
      toast({
        title: 'Error',
        description: 'Failed to update tickets',
        variant: 'destructive',
      });
    }
  };

  return (
    <div className="flex h-screen flex-col">
      {/* Header */}
      <div className="border-b bg-white px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Support Tickets</h1>
            <p className="text-sm text-gray-500">
              Manage and track customer support requests
            </p>
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={handleRefresh}
              disabled={refreshing}
            >
              <RefreshCw className={`mr-2 h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
            <Button
              size="sm"
              onClick={() => router.push('/support/tickets/new')}
            >
              <Plus className="mr-2 h-4 w-4" />
              New Ticket
            </Button>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      {stats && (
        <div className="border-b bg-gray-50 px-6 py-4">
          <StatsCards stats={stats} onStatClick={handleFilterChange} />
        </div>
      )}

      {/* Filters */}
      <div className="border-b bg-white px-6 py-4">
        <FilterComponent
          filters={filters}
          onChange={handleFilterChange}
        />
      </div>

      {/* Bulk Actions Bar */}
      {selectedTickets.size > 0 && (
        <BulkActionsBar
          selectedCount={selectedTickets.size}
          onAction={handleBulkAction}
          onClear={() => setSelectedTickets(new Set())}
        />
      )}

      {/* Ticket List */}
      <div className="flex-1 overflow-auto">
        <TicketList
          tickets={tickets}
          loading={loading}
          selectedTickets={selectedTickets}
          onSelectTicket={handleSelectTicket}
          onSelectAll={handleSelectAll}
          onTicketClick={(ticket) => router.push(`/support/tickets/${ticket.id}`)}
        />

        {/* Load More */}
        {hasMore && !loading && (
          <div className="flex justify-center p-6">
            <Button variant="outline" onClick={handleLoadMore}>
              Load More
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
```

### 4. Stats Cards Component (`/components/support/TicketStats.tsx`)

```typescript
'use client';

import { Card } from '@/components/ui/card';
import { AlertCircle, Clock, Inbox, CheckCircle2 } from 'lucide-react';
import type { TicketStats } from '@/types/support';

interface TicketStatsProps {
  stats: TicketStats;
  onStatClick: (filters: any) => void;
}

export function TicketStats({ stats, onStatClick }: TicketStatsProps) {
  const statCards = [
    {
      label: 'My Queue',
      value: stats.myQueue,
      icon: Inbox,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      onClick: () => onStatClick({ assignedTo: 'me', status: ['new', 'open', 'in_progress'] }),
    },
    {
      label: 'Unassigned',
      value: stats.unassigned,
      icon: AlertCircle,
      color: 'text-orange-600',
      bgColor: 'bg-orange-50',
      onClick: () => onStatClick({ assignedTo: 'unassigned', status: ['new', 'open'] }),
    },
    {
      label: 'All Open',
      value: stats.allOpen,
      icon: Clock,
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
      onClick: () => onStatClick({ status: ['new', 'open', 'in_progress'] }),
    },
    {
      label: 'SLA Breached',
      value: stats.slaBreached,
      icon: AlertCircle,
      color: 'text-red-600',
      bgColor: 'bg-red-50',
      onClick: () => onStatClick({ slaStatus: 'breached' }),
    },
    {
      label: 'Resolved Today',
      value: stats.resolvedToday,
      icon: CheckCircle2,
      color: 'text-green-600',
      bgColor: 'bg-green-50',
      onClick: () => {},
    },
  ];

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
      {statCards.map((stat) => {
        const Icon = stat.icon;
        return (
          <Card
            key={stat.label}
            className="cursor-pointer transition-all hover:shadow-md"
            onClick={stat.onClick}
          >
            <div className="p-4">
              <div className="flex items-center justify-between">
                <div className={`rounded-lg p-2 ${stat.bgColor}`}>
                  <Icon className={`h-5 w-5 ${stat.color}`} />
                </div>
                <span className="text-2xl font-bold">{stat.value}</span>
              </div>
              <div className="mt-2">
                <p className="text-sm font-medium text-gray-600">{stat.label}</p>
              </div>
            </div>
          </Card>
        );
      })}
    </div>
  );
}
```

### 5. Filters Component (`/components/support/TicketFilters.tsx`)

```typescript
'use client';

import { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Search, X } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import type { TicketFilters } from '@/types/support';

interface TicketFiltersProps {
  filters: TicketFilters;
  onChange: (filters: Partial<TicketFilters>) => void;
}

export function TicketFilters({ filters, onChange }: TicketFiltersProps) {
  const [searchInput, setSearchInput] = useState(filters.search || '');

  const handleSearch = () => {
    onChange({ search: searchInput || undefined });
  };

  const handleClearFilter = (key: keyof TicketFilters) => {
    onChange({ [key]: undefined });
  };

  const activeFilterCount = [
    filters.status?.length,
    filters.priority?.length,
    filters.assignedTo && filters.assignedTo !== 'me' ? 1 : 0,
    filters.categoryId ? 1 : 0,
    filters.slaStatus ? 1 : 0,
    filters.search ? 1 : 0,
  ].reduce((sum, val) => sum + (val || 0), 0);

  return (
    <div className="space-y-4">
      {/* Search */}
      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Search tickets by subject, description, or number..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            className="pl-10"
          />
        </div>
        <Button onClick={handleSearch}>Search</Button>
      </div>

      {/* Filter Dropdowns */}
      <div className="flex flex-wrap gap-2">
        {/* Status */}
        <Select
          value={filters.status?.[0] || 'all'}
          onValueChange={(value) =>
            onChange({ status: value === 'all' ? undefined : [value] })
          }
        >
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="new">New</SelectItem>
            <SelectItem value="open">Open</SelectItem>
            <SelectItem value="in_progress">In Progress</SelectItem>
            <SelectItem value="waiting_customer">Waiting Customer</SelectItem>
            <SelectItem value="resolved">Resolved</SelectItem>
            <SelectItem value="closed">Closed</SelectItem>
          </SelectContent>
        </Select>

        {/* Priority */}
        <Select
          value={filters.priority?.[0] || 'all'}
          onValueChange={(value) =>
            onChange({ priority: value === 'all' ? undefined : [value] })
          }
        >
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="Priority" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Priorities</SelectItem>
            <SelectItem value="critical">Critical</SelectItem>
            <SelectItem value="high">High</SelectItem>
            <SelectItem value="medium">Medium</SelectItem>
            <SelectItem value="low">Low</SelectItem>
          </SelectContent>
        </Select>

        {/* Assignment */}
        <Select
          value={filters.assignedTo || 'me'}
          onValueChange={(value) => onChange({ assignedTo: value })}
        >
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="Assignment" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="me">My Tickets</SelectItem>
            <SelectItem value="unassigned">Unassigned</SelectItem>
            <SelectItem value="all">All Tickets</SelectItem>
          </SelectContent>
        </Select>

        {/* SLA Status */}
        <Select
          value={filters.slaStatus || 'all'}
          onValueChange={(value) =>
            onChange({ slaStatus: value === 'all' ? undefined : (value as any) })
          }
        >
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="SLA Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All SLA</SelectItem>
            <SelectItem value="breached">Breached</SelectItem>
            <SelectItem value="warning">Warning</SelectItem>
            <SelectItem value="on_track">On Track</SelectItem>
          </SelectContent>
        </Select>

        {/* Clear Filters */}
        {activeFilterCount > 0 && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onChange({
              status: undefined,
              priority: undefined,
              assignedTo: 'me',
              categoryId: undefined,
              slaStatus: undefined,
              search: undefined,
            })}
          >
            <X className="mr-1 h-4 w-4" />
            Clear All ({activeFilterCount})
          </Button>
        )}
      </div>

      {/* Active Filters */}
      {activeFilterCount > 0 && (
        <div className="flex flex-wrap gap-2">
          {filters.search && (
            <Badge variant="secondary">
              Search: {filters.search}
              <X
                className="ml-1 h-3 w-3 cursor-pointer"
                onClick={() => {
                  setSearchInput('');
                  handleClearFilter('search');
                }}
              />
            </Badge>
          )}
          {filters.status?.map((status) => (
            <Badge key={status} variant="secondary">
              Status: {status}
              <X
                className="ml-1 h-3 w-3 cursor-pointer"
                onClick={() => handleClearFilter('status')}
              />
            </Badge>
          ))}
          {filters.priority?.map((priority) => (
            <Badge key={priority} variant="secondary">
              Priority: {priority}
              <X
                className="ml-1 h-3 w-3 cursor-pointer"
                onClick={() => handleClearFilter('priority')}
              />
            </Badge>
          ))}
        </div>
      )}
    </div>
  );
}
```

### 6. Ticket List Component (`/components/support/TicketList.tsx`)

```typescript
'use client';

import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { formatDistanceToNow } from 'date-fns';
import { AlertCircle, Clock, MessageCircle } from 'lucide-react';
import type { SupportTicket } from '@/types/support';
import { Skeleton } from '@/components/ui/skeleton';

interface TicketListProps {
  tickets: SupportTicket[];
  loading: boolean;
  selectedTickets: Set<string>;
  onSelectTicket: (ticketId: string, selected: boolean) => void;
  onSelectAll: (selected: boolean) => void;
  onTicketClick: (ticket: SupportTicket) => void;
}

export function TicketList({
  tickets,
  loading,
  selectedTickets,
  onSelectTicket,
  onSelectAll,
  onTicketClick,
}: TicketListProps) {
  const getPriorityColor = (priority: string) => {
    const colors = {
      critical: 'bg-red-100 text-red-800 border-red-200',
      high: 'bg-orange-100 text-orange-800 border-orange-200',
      medium: 'bg-blue-100 text-blue-800 border-blue-200',
      low: 'bg-gray-100 text-gray-800 border-gray-200',
    };
    return colors[priority as keyof typeof colors] || colors.medium;
  };

  const getStatusColor = (status: string) => {
    const colors = {
      new: 'bg-blue-100 text-blue-800',
      open: 'bg-green-100 text-green-800',
      in_progress: 'bg-purple-100 text-purple-800',
      waiting_customer: 'bg-yellow-100 text-yellow-800',
      waiting_internal: 'bg-orange-100 text-orange-800',
      resolved: 'bg-gray-100 text-gray-800',
      closed: 'bg-gray-100 text-gray-600',
      cancelled: 'bg-red-100 text-red-800',
    };
    return colors[status as keyof typeof colors] || colors.open;
  };

  const getSLAStatus = (ticket: SupportTicket) => {
    if (ticket.first_response_at) return null;
    
    const now = new Date();
    const target = new Date(ticket.sla_target_response);
    const minutesLeft = (target.getTime() - now.getTime()) / 60000;

    if (minutesLeft < 0) {
      return { status: 'breached', color: 'text-red-600', icon: AlertCircle };
    } else if (minutesLeft < 30) {
      return { status: 'warning', color: 'text-orange-600', icon: Clock };
    }
    return null;
  };

  if (loading && tickets.length === 0) {
    return (
      <div className="space-y-2 p-4">
        {[...Array(10)].map((_, i) => (
          <Skeleton key={i} className="h-20 w-full" />
        ))}
      </div>
    );
  }

  if (tickets.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <AlertCircle className="h-12 w-12 text-gray-400" />
        <h3 className="mt-4 text-lg font-medium text-gray-900">No tickets found</h3>
        <p className="mt-2 text-sm text-gray-500">
          Try adjusting your filters or create a new ticket
        </p>
      </div>
    );
  }

  const allSelected = tickets.length > 0 && tickets.every(t => selectedTickets.has(t.id));

  return (
    <div className="divide-y">
      {/* Header */}
      <div className="flex items-center gap-4 bg-gray-50 px-6 py-3 text-sm font-medium text-gray-700">
        <Checkbox
          checked={allSelected}
          onCheckedChange={(checked) => onSelectAll(!!checked)}
        />
        <div className="w-32">Ticket #</div>
        <div className="flex-1">Subject</div>
        <div className="w-32">Status</div>
        <div className="w-32">Priority</div>
        <div className="w-40">Created</div>
        <div className="w-20 text-center">SLA</div>
      </div>

      {/* Ticket Rows */}
      {tickets.map((ticket) => {
        const slaStatus = getSLAStatus(ticket);
        const isSelected = selectedTickets.has(ticket.id);

        return (
          <div
            key={ticket.id}
            className={`flex items-center gap-4 px-6 py-4 transition-colors hover:bg-gray-50 ${
              isSelected ? 'bg-blue-50' : ''
            }`}
          >
            <Checkbox
              checked={isSelected}
              onCheckedChange={(checked) => onSelectTicket(ticket.id, !!checked)}
              onClick={(e) => e.stopPropagation()}
            />
            
            <div
              className="flex flex-1 cursor-pointer items-center gap-4"
              onClick={() => onTicketClick(ticket)}
            >
              {/* Ticket Number */}
              <div className="w-32">
                <span className="font-mono text-sm font-medium text-gray-900">
                  {ticket.ticket_number}
                </span>
              </div>

              {/* Subject */}
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-gray-900">{ticket.subject}</span>
                  {ticket.messages && ticket.messages.count > 0 && (
                    <span className="flex items-center text-xs text-gray-500">
                      <MessageCircle className="mr-1 h-3 w-3" />
                      {ticket.messages.count}
                    </span>
                  )}
                </div>
                <div className="mt-1 text-sm text-gray-500">
                  {ticket.customer_name} • {ticket.customer_email}
                </div>
              </div>

              {/* Status */}
              <div className="w-32">
                <Badge className={getStatusColor(ticket.status)}>
                  {ticket.status.replace('_', ' ')}
                </Badge>
              </div>

              {/* Priority */}
              <div className="w-32">
                <Badge className={getPriorityColor(ticket.priority)}>
                  {ticket.priority}
                </Badge>
              </div>

              {/* Created */}
              <div className="w-40 text-sm text-gray-500">
                {formatDistanceToNow(new Date(ticket.created_at), { addSuffix: true })}
              </div>

              {/* SLA Indicator */}
              <div className="w-20 text-center">
                {slaStatus && (
                  <slaStatus.icon className={`h-5 w-5 ${slaStatus.color}`} />
                )}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/app/(portal)/support/tickets/__tests__/page.test.tsx`)

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import TicketsPage from '../page';
import { supportTicketsAPI } from '@/lib/api/support-tickets';

// Mock dependencies
vi.mock('@/lib/api/support-tickets');
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn() }),
  useSearchParams: () => new URLSearchParams(),
}));

describe('TicketsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders ticket dashboard', async () => {
    vi.mocked(supportTicketsAPI.getTickets).mockResolvedValue({
      data: [],
      count: 0,
      hasMore: false,
    });
    
    vi.mocked(supportTicketsAPI.getTicketStats).mockResolvedValue({
      myQueue: 5,
      unassigned: 3,
      allOpen: 10,
      slaBreached: 2,
      resolvedToday: 8,
    });

    render(<TicketsPage />);

    await waitFor(() => {
      expect(screen.getByText('Support Tickets')).toBeInTheDocument();
    });
  });

  it('displays ticket statistics', async () => {
    vi.mocked(supportTicketsAPI.getTickets).mockResolvedValue({
      data: [],
      count: 0,
      hasMore: false,
    });
    
    vi.mocked(supportTicketsAPI.getTicketStats).mockResolvedValue({
      myQueue: 5,
      unassigned: 3,
      allOpen: 10,
      slaBreached: 2,
      resolvedToday: 8,
    });

    render(<TicketsPage />);

    await waitFor(() => {
      expect(screen.getByText('5')).toBeInTheDocument();
      expect(screen.getByText('My Queue')).toBeInTheDocument();
    });
  });

  it('handles ticket selection', async () => {
    const mockTickets = [
      {
        id: '1',
        ticket_number: 'TKT-001',
        subject: 'Test ticket',
        status: 'open',
        priority: 'high',
        // ... other fields
      },
    ];

    vi.mocked(supportTicketsAPI.getTickets).mockResolvedValue({
      data: mockTickets,
      count: 1,
      hasMore: false,
    });

    render(<TicketsPage />);

    await waitFor(() => {
      const checkbox = screen.getAllByRole('checkbox')[1]; // First ticket checkbox
      fireEvent.click(checkbox);
      expect(checkbox).toBeChecked();
    });
  });

  it('applies filters correctly', async () => {
    const getTicketsSpy = vi.mocked(supportTicketsAPI.getTickets);
    getTicketsSpy.mockResolvedValue({
      data: [],
      count: 0,
      hasMore: false,
    });

    render(<TicketsPage />);

    // Change status filter
    const statusSelect = screen.getByRole('combobox', { name: /status/i });
    fireEvent.change(statusSelect, { target: { value: 'open' } });

    await waitFor(() => {
      expect(getTicketsSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          status: ['open'],
        }),
        1
      );
    });
  });
});
```

---

## 📈 PERFORMANCE OPTIMIZATION

### Optimization Strategies

1. **Virtual Scrolling**: Implement for large ticket lists
2. **Debounced Search**: Prevent excessive API calls
3. **Optimistic Updates**: Update UI immediately
4. **Caching**: Cache frequently accessed data
5. **Lazy Loading**: Load ticket details on demand
6. **Web Workers**: Process large datasets off main thread

---

## ♿ ACCESSIBILITY

- **Keyboard Navigation**: Full keyboard support (Tab, Enter, Space)
- **Screen Readers**: ARIA labels for all interactive elements
- **Focus Management**: Clear focus indicators
- **Color Contrast**: WCAG AA compliant (4.5:1)
- **Semantic HTML**: Proper heading hierarchy
- **Alt Text**: Descriptive text for icons

---

## ✅ VALIDATION CHECKLIST

- [ ] Dashboard loads within 1 second
- [ ] Real-time updates working
- [ ] Filters apply correctly
- [ ] Bulk actions functional
- [ ] SLA indicators accurate
- [ ] Responsive on all devices
- [ ] Keyboard navigation working
- [ ] Screen reader compatible
- [ ] All unit tests passing
- [ ] E2E tests passing
- [ ] Performance targets met
- [ ] Security audit passed

---

**Status**: ✅ Complete and Ready for Implementation  
**Next Step**: SPEC-133 (Ticket Details & Resolution)  
**Estimated Implementation Time**: 4 hours  
**AI-Ready**: 100% - All details specified for autonomous development
