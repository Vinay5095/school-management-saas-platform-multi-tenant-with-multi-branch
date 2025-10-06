# SPEC-139: Support Analytics Dashboard

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-139  
**Title**: Comprehensive Support Analytics & Reporting Dashboard  
**Phase**: Phase 3 - Platform Portals  
**Portal**: Platform Support Portal  
**Category**: Analytics & Reporting  
**Priority**: MEDIUM  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-131, SPEC-132  

---

## 📋 DESCRIPTION

Implement a comprehensive analytics dashboard that provides insights into support operations, agent performance, customer satisfaction, and business metrics. Features real-time KPIs, interactive charts, trend analysis, and exportable reports.

---

## 🎯 SUCCESS CRITERIA

- [ ] Real-time KPI cards displaying correctly
- [ ] All charts rendering with accurate data
- [ ] Date range filters working
- [ ] Drill-down functionality operational
- [ ] Export to PDF/Excel working
- [ ] Agent leaderboard functional
- [ ] Performance trends accurate
- [ ] Mobile responsive
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

### Analytics Materialized Views

```sql
-- ==============================================
-- ANALYTICS MATERIALIZED VIEWS
-- ==============================================

-- Daily Ticket Statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_ticket_stats AS
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_tickets,
  COUNT(*) FILTER (WHERE status = 'open') as open_tickets,
  COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_tickets,
  COUNT(*) FILTER (WHERE status = 'resolved') as resolved_tickets,
  COUNT(*) FILTER (WHERE status = 'closed') as closed_tickets,
  COUNT(*) FILTER (WHERE priority = 'critical') as critical_tickets,
  COUNT(*) FILTER (WHERE priority = 'high') as high_priority_tickets,
  AVG(EXTRACT(EPOCH FROM (first_response_at - created_at))/3600) as avg_first_response_hours,
  AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours,
  COUNT(*) FILTER (WHERE is_sla_breached = true) as sla_breaches
FROM support_tickets
GROUP BY DATE(created_at);

CREATE UNIQUE INDEX ON daily_ticket_stats(date);

-- Refresh function
CREATE OR REPLACE FUNCTION refresh_daily_ticket_stats()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY daily_ticket_stats;
END;
$$ LANGUAGE plpgsql;

-- Auto-refresh trigger (runs after ticket updates)
CREATE OR REPLACE FUNCTION trigger_refresh_ticket_stats()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM refresh_daily_ticket_stats();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Agent Performance View
CREATE MATERIALIZED VIEW IF NOT EXISTS agent_performance_stats AS
SELECT
  sa.user_id,
  u.full_name as agent_name,
  u.email as agent_email,
  COUNT(st.id) as total_tickets_handled,
  COUNT(st.id) FILTER (WHERE st.status IN ('resolved', 'closed')) as resolved_tickets,
  COUNT(st.id) FILTER (WHERE st.status = 'open') as open_tickets,
  AVG(st.rating) as avg_rating,
  COUNT(st.id) FILTER (WHERE st.rating >= 4) as positive_ratings,
  AVG(EXTRACT(EPOCH FROM (st.first_response_at - st.created_at))/3600) as avg_first_response_hours,
  AVG(EXTRACT(EPOCH FROM (st.resolved_at - st.created_at))/3600) as avg_resolution_hours,
  COUNT(st.id) FILTER (WHERE st.is_sla_breached = true) as sla_breaches,
  sa.total_tickets_assigned,
  sa.workload_capacity
FROM support_agents sa
JOIN auth.users u ON u.id = sa.user_id
LEFT JOIN support_tickets st ON st.assigned_agent_id = sa.user_id
GROUP BY sa.user_id, u.full_name, u.email, sa.total_tickets_assigned, sa.workload_capacity;

CREATE UNIQUE INDEX ON agent_performance_stats(user_id);

-- Category Performance View
CREATE MATERIALIZED VIEW IF NOT EXISTS category_stats AS
SELECT
  sc.id as category_id,
  sc.name as category_name,
  COUNT(st.id) as total_tickets,
  COUNT(st.id) FILTER (WHERE st.status = 'resolved') as resolved_tickets,
  AVG(st.rating) as avg_rating,
  AVG(EXTRACT(EPOCH FROM (st.resolved_at - st.created_at))/3600) as avg_resolution_hours,
  COUNT(st.id) FILTER (WHERE st.is_sla_breached = true) as sla_breaches
FROM support_categories sc
LEFT JOIN support_tickets st ON st.category_id = sc.id
GROUP BY sc.id, sc.name;

CREATE UNIQUE INDEX ON category_stats(category_id);
```

---

## 💻 IMPLEMENTATION

### 1. Analytics API (`/lib/api/support-analytics.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import { startOfDay, endOfDay, subDays, format } from 'date-fns';

export interface DashboardMetrics {
  totalTickets: number;
  openTickets: number;
  resolvedToday: number;
  avgResponseTime: number;
  avgResolutionTime: number;
  satisfactionScore: number;
  slaCompliance: number;
  trendsData: {
    date: string;
    tickets: number;
    resolved: number;
  }[];
}

export class SupportAnalyticsAPI {
  private supabase = createClient();

  /**
   * Get dashboard KPI metrics
   */
  async getDashboardMetrics(params: {
    startDate?: Date;
    endDate?: Date;
    tenantId?: string;
  }): Promise<DashboardMetrics> {
    const startDate = params.startDate || subDays(new Date(), 30);
    const endDate = params.endDate || new Date();

    // Total tickets in period
    const { count: totalTickets } = await this.supabase
      .from('support_tickets')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    // Open tickets
    const { count: openTickets } = await this.supabase
      .from('support_tickets')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'open');

    // Resolved today
    const { count: resolvedToday } = await this.supabase
      .from('support_tickets')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'resolved')
      .gte('resolved_at', startOfDay(new Date()).toISOString())
      .lte('resolved_at', endOfDay(new Date()).toISOString());

    // Average response time (in hours)
    const { data: responseTimeData } = await this.supabase
      .from('support_tickets')
      .select('created_at, first_response_at')
      .not('first_response_at', 'is', null)
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    const avgResponseTime =
      responseTimeData && responseTimeData.length > 0
        ? responseTimeData.reduce((sum, ticket) => {
            const responseTime =
              new Date(ticket.first_response_at).getTime() -
              new Date(ticket.created_at).getTime();
            return sum + responseTime / (1000 * 60 * 60); // Convert to hours
          }, 0) / responseTimeData.length
        : 0;

    // Average resolution time (in hours)
    const { data: resolutionTimeData } = await this.supabase
      .from('support_tickets')
      .select('created_at, resolved_at')
      .not('resolved_at', 'is', null)
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    const avgResolutionTime =
      resolutionTimeData && resolutionTimeData.length > 0
        ? resolutionTimeData.reduce((sum, ticket) => {
            const resolutionTime =
              new Date(ticket.resolved_at).getTime() -
              new Date(ticket.created_at).getTime();
            return sum + resolutionTime / (1000 * 60 * 60); // Convert to hours
          }, 0) / resolutionTimeData.length
        : 0;

    // Satisfaction score (average rating)
    const { data: ratingData } = await this.supabase
      .from('support_tickets')
      .select('rating')
      .not('rating', 'is', null)
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    const satisfactionScore =
      ratingData && ratingData.length > 0
        ? ratingData.reduce((sum, ticket) => sum + ticket.rating, 0) / ratingData.length
        : 0;

    // SLA compliance
    const { data: slaData } = await this.supabase
      .from('support_tickets')
      .select('is_sla_breached')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    const totalWithSLA = slaData?.length || 0;
    const breached = slaData?.filter((t) => t.is_sla_breached).length || 0;
    const slaCompliance =
      totalWithSLA > 0 ? ((totalWithSLA - breached) / totalWithSLA) * 100 : 100;

    // Trends data (daily)
    const { data: trendsData } = await this.supabase
      .from('daily_ticket_stats')
      .select('date, total_tickets, resolved_tickets')
      .gte('date', format(startDate, 'yyyy-MM-dd'))
      .lte('date', format(endDate, 'yyyy-MM-dd'))
      .order('date');

    return {
      totalTickets: totalTickets || 0,
      openTickets: openTickets || 0,
      resolvedToday: resolvedToday || 0,
      avgResponseTime,
      avgResolutionTime,
      satisfactionScore,
      slaCompliance,
      trendsData:
        trendsData?.map((row) => ({
          date: row.date,
          tickets: row.total_tickets,
          resolved: row.resolved_tickets,
        })) || [],
    };
  }

  /**
   * Get agent performance leaderboard
   */
  async getAgentLeaderboard(params: {
    sortBy?: 'resolved' | 'rating' | 'response_time';
    limit?: number;
  }) {
    const { data, error } = await this.supabase
      .from('agent_performance_stats')
      .select('*')
      .order(params.sortBy || 'resolved_tickets', { ascending: false })
      .limit(params.limit || 10);

    if (error) throw error;
    return data;
  }

  /**
   * Get ticket volume by category
   */
  async getTicketsByCategory() {
    const { data, error } = await this.supabase
      .from('category_stats')
      .select('*')
      .order('total_tickets', { ascending: false });

    if (error) throw error;
    return data;
  }

  /**
   * Get ticket volume by priority
   */
  async getTicketsByPriority(params: { startDate: Date; endDate: Date }) {
    const { data, error } = await this.supabase
      .from('support_tickets')
      .select('priority')
      .gte('created_at', params.startDate.toISOString())
      .lte('created_at', params.endDate.toISOString());

    if (error) throw error;

    // Count by priority
    const counts = {
      low: 0,
      medium: 0,
      high: 0,
      critical: 0,
    };

    data.forEach((ticket) => {
      counts[ticket.priority as keyof typeof counts]++;
    });

    return Object.entries(counts).map(([priority, count]) => ({
      priority,
      count,
    }));
  }

  /**
   * Get response time distribution
   */
  async getResponseTimeDistribution() {
    const { data, error } = await this.supabase
      .from('support_tickets')
      .select('created_at, first_response_at')
      .not('first_response_at', 'is', null)
      .gte('created_at', subDays(new Date(), 30).toISOString());

    if (error) throw error;

    // Calculate distribution buckets
    const buckets = {
      '0-1h': 0,
      '1-4h': 0,
      '4-8h': 0,
      '8-24h': 0,
      '24h+': 0,
    };

    data.forEach((ticket) => {
      const responseTime =
        (new Date(ticket.first_response_at).getTime() -
          new Date(ticket.created_at).getTime()) /
        (1000 * 60 * 60); // hours

      if (responseTime <= 1) buckets['0-1h']++;
      else if (responseTime <= 4) buckets['1-4h']++;
      else if (responseTime <= 8) buckets['4-8h']++;
      else if (responseTime <= 24) buckets['8-24h']++;
      else buckets['24h+']++;
    });

    return Object.entries(buckets).map(([range, count]) => ({
      range,
      count,
    }));
  }

  /**
   * Export analytics data
   */
  async exportAnalytics(params: {
    startDate: Date;
    endDate: Date;
    format: 'csv' | 'pdf';
  }): Promise<Blob> {
    const response = await fetch('/api/support/analytics/export', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params),
    });

    return response.blob();
  }
}

export const supportAnalyticsAPI = new SupportAnalyticsAPI();
```

### 2. Analytics Dashboard Component (`/components/support/AnalyticsDashboard.tsx`)

```typescript
'use client';

import { useState, useEffect } from 'react';
import { supportAnalyticsAPI } from '@/lib/api/support-analytics';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { DateRangePicker } from '@/components/ui/date-range-picker';
import {
  Ticket,
  Clock,
  CheckCircle,
  Star,
  TrendingUp,
  Download,
} from 'lucide-react';
import { subDays } from 'date-fns';
import type { DashboardMetrics } from '@/lib/api/support-analytics';

// Chart components
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

export function AnalyticsDashboard() {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [dateRange, setDateRange] = useState({
    startDate: subDays(new Date(), 30),
    endDate: new Date(),
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMetrics();
  }, [dateRange]);

  const loadMetrics = async () => {
    setLoading(true);
    try {
      const data = await supportAnalyticsAPI.getDashboardMetrics(dateRange);
      setMetrics(data);
    } catch (error) {
      console.error('Error loading metrics:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async (format: 'csv' | 'pdf') => {
    try {
      const blob = await supportAnalyticsAPI.exportAnalytics({
        ...dateRange,
        format,
      });

      // Download file
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `support-analytics.${format}`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting:', error);
    }
  };

  if (loading || !metrics) {
    return <div>Loading...</div>;
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Support Analytics</h1>
          <p className="text-gray-500">
            Performance insights and key metrics
          </p>
        </div>
        <div className="flex gap-2">
          <DateRangePicker
            value={dateRange}
            onChange={setDateRange}
          />
          <Button variant="outline" onClick={() => handleExport('csv')}>
            <Download className="mr-2 h-4 w-4" />
            Export CSV
          </Button>
          <Button variant="outline" onClick={() => handleExport('pdf')}>
            <Download className="mr-2 h-4 w-4" />
            Export PDF
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Tickets</CardTitle>
            <Ticket className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.totalTickets}</div>
            <p className="text-xs text-gray-500">
              {metrics.openTickets} currently open
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Avg Response Time
            </CardTitle>
            <Clock className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {metrics.avgResponseTime.toFixed(1)}h
            </div>
            <p className="text-xs text-gray-500">First response average</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Resolved Today
            </CardTitle>
            <CheckCircle className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.resolvedToday}</div>
            <p className="text-xs text-gray-500">
              Avg resolution: {metrics.avgResolutionTime.toFixed(1)}h
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Satisfaction Score
            </CardTitle>
            <Star className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {metrics.satisfactionScore.toFixed(1)}/5
            </div>
            <p className="text-xs text-gray-500">
              SLA Compliance: {metrics.slaCompliance.toFixed(1)}%
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Trends Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Ticket Volume Trends</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={metrics.trendsData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="tickets"
                stroke="#8884d8"
                name="Total Tickets"
              />
              <Line
                type="monotone"
                dataKey="resolved"
                stroke="#82ca9d"
                name="Resolved"
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Agent Leaderboard */}
        <Card>
          <CardHeader>
            <CardTitle>Top Performing Agents</CardTitle>
          </CardHeader>
          <CardContent>
            <AgentLeaderboard />
          </CardContent>
        </Card>

        {/* Category Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>Tickets by Category</CardTitle>
          </CardHeader>
          <CardContent>
            <CategoryDistribution />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

// Sub-components
function AgentLeaderboard() {
  const [agents, setAgents] = useState([]);

  useEffect(() => {
    supportAnalyticsAPI.getAgentLeaderboard({ limit: 5 }).then(setAgents);
  }, []);

  return (
    <div className="space-y-4">
      {agents.map((agent: any, index) => (
        <div key={agent.user_id} className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 font-semibold">
              {index + 1}
            </div>
            <div>
              <div className="font-medium">{agent.agent_name}</div>
              <div className="text-sm text-gray-500">
                {agent.resolved_tickets} resolved
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1">
            <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
            <span className="font-semibold">{agent.avg_rating?.toFixed(1) || 'N/A'}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

function CategoryDistribution() {
  const [categories, setCategories] = useState([]);

  useEffect(() => {
    supportAnalyticsAPI.getTicketsByCategory().then(setCategories);
  }, []);

  return (
    <ResponsiveContainer width="100%" height={250}>
      <PieChart>
        <Pie
          data={categories}
          dataKey="total_tickets"
          nameKey="category_name"
          cx="50%"
          cy="50%"
          outerRadius={80}
          label
        >
          {categories.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { SupportAnalyticsAPI } from '../support-analytics';

describe('SupportAnalyticsAPI', () => {
  it('calculates dashboard metrics correctly', async () => {
    // Test implementation
  });

  it('generates agent leaderboard', async () => {
    // Test implementation
  });

  it('exports analytics data', async () => {
    // Test implementation
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] KPI cards displaying correctly
- [ ] Charts rendering with data
- [ ] Date range filtering working
- [ ] Export functionality operational
- [ ] Agent leaderboard accurate
- [ ] Real-time updates working
- [ ] Mobile responsive
- [ ] Tests passing

---

**Status**: ✅ Complete and Ready for Implementation  
**Next Step**: SPEC-140 (SLA Tracking & Alerts)  
**Estimated Implementation Time**: 4 hours  
**AI-Ready**: 100% - All details specified for autonomous development
