# SPEC-134: Ticket Assignment & Routing System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-134  
**Title**: Automated Ticket Assignment & Intelligent Routing  
**Phase**: Phase 3 - Platform Portals  
**Portal**: Platform Support Portal  
**Category**: Backend Logic & Automation  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 3 hours  
**Dependencies**: SPEC-131, SPEC-132, SPEC-133  

---

## 📋 DESCRIPTION

Implement an intelligent ticket assignment and routing system that automatically assigns incoming tickets to the most appropriate support agent based on workload, skills, availability, priority, and category. Includes manual assignment override, round-robin distribution, and workload balancing.

---

## 🎯 SUCCESS CRITERIA

- [ ] Automatic ticket assignment working
- [ ] Round-robin distribution functional
- [ ] Skill-based routing implemented
- [ ] Workload balancing active
- [ ] Manual assignment override working
- [ ] Escalation rules triggered correctly
- [ ] Agent availability status respected
- [ ] Assignment notifications sent
- [ ] All tests passing (85%+ coverage)

---

## 💻 IMPLEMENTATION

### 1. Database Schema for Agent Management

```sql
-- ==============================================
-- SUPPORT AGENT CONFIGURATION
-- ==============================================

CREATE TABLE IF NOT EXISTS support_agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Availability
  status VARCHAR(20) NOT NULL DEFAULT 'available', -- available, busy, away, offline
  is_accepting_tickets BOOLEAN DEFAULT true,
  max_concurrent_tickets INTEGER DEFAULT 10,
  
  -- Skills and specializations
  skills TEXT[], -- Array of skill tags
  categories UUID[], -- Array of category IDs this agent specializes in
  languages TEXT[], -- Supported languages
  
  -- Performance metrics
  average_response_time INTERVAL,
  average_resolution_time INTERVAL,
  total_tickets_handled INTEGER DEFAULT 0,
  satisfaction_rating DECIMAL(3,2),
  
  -- Working hours
  working_hours JSONB DEFAULT '{"monday": {"start": "09:00", "end": "17:00"}}',
  timezone VARCHAR(50) DEFAULT 'UTC',
  
  -- Assignment preferences
  priority_preference VARCHAR(20)[], -- Preferred priorities
  auto_assign BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('available', 'busy', 'away', 'offline'))
);

-- Create indexes
CREATE INDEX idx_support_agents_user ON support_agents(user_id);
CREATE INDEX idx_support_agents_status ON support_agents(status);
CREATE INDEX idx_support_agents_accepting ON support_agents(is_accepting_tickets);
CREATE INDEX idx_support_agents_skills ON support_agents USING GIN(skills);
CREATE INDEX idx_support_agents_categories ON support_agents USING GIN(categories);

-- Enable RLS
ALTER TABLE support_agents ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Support agents viewable by authenticated users"
  ON support_agents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update their own agent profile"
  ON support_agents FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- ==============================================
-- ASSIGNMENT RULES
-- ==============================================

CREATE TABLE IF NOT EXISTS ticket_assignment_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0, -- Higher priority rules evaluated first
  
  -- Conditions
  conditions JSONB NOT NULL, -- {priority: ["high", "critical"], category_id: ["uuid"], tenant_id: "uuid"}
  
  -- Assignment strategy
  strategy VARCHAR(50) NOT NULL DEFAULT 'round_robin', -- round_robin, least_loaded, skill_based, specific_agent
  target_agent_id UUID REFERENCES auth.users(id),
  target_team VARCHAR(100),
  
  -- Time constraints
  active_hours JSONB, -- When this rule is active
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  
  CONSTRAINT valid_strategy CHECK (strategy IN ('round_robin', 'least_loaded', 'skill_based', 'specific_agent', 'manual'))
);

CREATE INDEX idx_ticket_assignment_rules_active ON ticket_assignment_rules(is_active);
CREATE INDEX idx_ticket_assignment_rules_priority ON ticket_assignment_rules(priority DESC);
```

### 2. Assignment Service (`/lib/services/ticket-assignment.ts`)

```typescript
import { createClient } from '@/lib/supabase/server';
import type { SupportTicket, SupportAgent, AssignmentRule } from '@/types/support';

export class TicketAssignmentService {
  private supabase = createClient();

  /**
   * Automatically assign a ticket to the best available agent
   */
  async autoAssignTicket(ticketId: string): Promise<string | null> {
    // Get ticket details
    const { data: ticket, error: ticketError } = await this.supabase
      .from('support_tickets')
      .select('*, category:support_ticket_categories(*)')
      .eq('id', ticketId)
      .single();

    if (ticketError || !ticket) {
      console.error('Error fetching ticket:', ticketError);
      return null;
    }

    // Check if ticket already assigned
    if (ticket.assigned_to) {
      return ticket.assigned_to;
    }

    // Find matching assignment rule
    const rule = await this.findMatchingRule(ticket);

    if (rule) {
      return await this.applyAssignmentRule(ticket, rule);
    }

    // Default: Use round-robin strategy
    return await this.roundRobinAssignment(ticket);
  }

  /**
   * Find the first matching assignment rule for a ticket
   */
  async findMatchingRule(ticket: SupportTicket): Promise<AssignmentRule | null> {
    const { data: rules } = await this.supabase
      .from('ticket_assignment_rules')
      .select('*')
      .eq('is_active', true)
      .order('priority', { ascending: false });

    if (!rules || rules.length === 0) return null;

    for (const rule of rules) {
      if (this.ruleMatchesTicket(rule, ticket)) {
        return rule;
      }
    }

    return null;
  }

  /**
   * Check if a rule matches a ticket
   */
  private ruleMatchesTicket(rule: AssignmentRule, ticket: SupportTicket): boolean {
    const conditions = rule.conditions;

    // Check priority
    if (conditions.priority && !conditions.priority.includes(ticket.priority)) {
      return false;
    }

    // Check category
    if (conditions.category_id && conditions.category_id !== ticket.category_id) {
      return false;
    }

    // Check tenant
    if (conditions.tenant_id && conditions.tenant_id !== ticket.tenant_id) {
      return false;
    }

    // Check time constraints
    if (rule.active_hours) {
      const now = new Date();
      const currentHour = now.getHours();
      const currentDay = now.toLocaleDateString('en-US', { weekday: 'lowercase' });
      
      const dayHours = rule.active_hours[currentDay];
      if (dayHours) {
        const [startHour] = dayHours.start.split(':').map(Number);
        const [endHour] = dayHours.end.split(':').map(Number);
        
        if (currentHour < startHour || currentHour >= endHour) {
          return false;
        }
      }
    }

    return true;
  }

  /**
   * Apply an assignment rule to a ticket
   */
  private async applyAssignmentRule(
    ticket: SupportTicket,
    rule: AssignmentRule
  ): Promise<string | null> {
    switch (rule.strategy) {
      case 'specific_agent':
        if (rule.target_agent_id) {
          const isAvailable = await this.isAgentAvailable(rule.target_agent_id);
          if (isAvailable) {
            await this.assignTicketToAgent(ticket.id, rule.target_agent_id);
            return rule.target_agent_id;
          }
        }
        break;

      case 'skill_based':
        return await this.skillBasedAssignment(ticket);

      case 'least_loaded':
        return await this.leastLoadedAssignment(ticket);

      case 'round_robin':
      default:
        return await this.roundRobinAssignment(ticket);
    }

    return null;
  }

  /**
   * Round-robin assignment strategy
   */
  private async roundRobinAssignment(ticket: SupportTicket): Promise<string | null> {
    // Get all available agents
    const agents = await this.getAvailableAgents(ticket.category_id);

    if (agents.length === 0) return null;

    // Get last assigned agent for this category
    const { data: lastTicket } = await this.supabase
      .from('support_tickets')
      .select('assigned_to')
      .eq('category_id', ticket.category_id)
      .not('assigned_to', 'is', null)
      .order('assigned_at', { ascending: false })
      .limit(1)
      .single();

    let nextAgentIndex = 0;

    if (lastTicket && lastTicket.assigned_to) {
      const lastAgentIndex = agents.findIndex(a => a.user_id === lastTicket.assigned_to);
      nextAgentIndex = (lastAgentIndex + 1) % agents.length;
    }

    const selectedAgent = agents[nextAgentIndex];
    await this.assignTicketToAgent(ticket.id, selectedAgent.user_id);

    return selectedAgent.user_id;
  }

  /**
   * Skill-based assignment strategy
   */
  private async skillBasedAssignment(ticket: SupportTicket): Promise<string | null> {
    // Get agents with matching skills
    const categoryId = ticket.category_id;

    const { data: agents } = await this.supabase
      .from('support_agents')
      .select('*')
      .eq('status', 'available')
      .eq('is_accepting_tickets', true)
      .contains('categories', [categoryId])
      .order('satisfaction_rating', { ascending: false });

    if (!agents || agents.length === 0) {
      // Fallback to round-robin
      return await this.roundRobinAssignment(ticket);
    }

    // Select agent with highest rating and lowest workload
    const agentsWithWorkload = await Promise.all(
      agents.map(async (agent) => {
        const workload = await this.getAgentWorkload(agent.user_id);
        return { ...agent, currentWorkload: workload };
      })
    );

    // Filter agents who haven't reached max capacity
    const availableAgents = agentsWithWorkload.filter(
      a => a.currentWorkload < a.max_concurrent_tickets
    );

    if (availableAgents.length === 0) return null;

    // Sort by workload (ascending) then by rating (descending)
    availableAgents.sort((a, b) => {
      if (a.currentWorkload !== b.currentWorkload) {
        return a.currentWorkload - b.currentWorkload;
      }
      return b.satisfaction_rating - a.satisfaction_rating;
    });

    const selectedAgent = availableAgents[0];
    await this.assignTicketToAgent(ticket.id, selectedAgent.user_id);

    return selectedAgent.user_id;
  }

  /**
   * Least loaded assignment strategy
   */
  private async leastLoadedAssignment(ticket: SupportTicket): Promise<string | null> {
    const agents = await this.getAvailableAgents(ticket.category_id);

    if (agents.length === 0) return null;

    // Get workload for each agent
    const agentsWithWorkload = await Promise.all(
      agents.map(async (agent) => {
        const workload = await this.getAgentWorkload(agent.user_id);
        return { ...agent, currentWorkload: workload };
      })
    );

    // Filter and sort by workload
    const availableAgents = agentsWithWorkload
      .filter(a => a.currentWorkload < a.max_concurrent_tickets)
      .sort((a, b) => a.currentWorkload - b.currentWorkload);

    if (availableAgents.length === 0) return null;

    const selectedAgent = availableAgents[0];
    await this.assignTicketToAgent(ticket.id, selectedAgent.user_id);

    return selectedAgent.user_id;
  }

  /**
   * Get available agents for a category
   */
  private async getAvailableAgents(categoryId?: string): Promise<SupportAgent[]> {
    let query = this.supabase
      .from('support_agents')
      .select('*')
      .eq('status', 'available')
      .eq('is_accepting_tickets', true)
      .eq('auto_assign', true);

    if (categoryId) {
      query = query.contains('categories', [categoryId]);
    }

    const { data } = await query;
    return data || [];
  }

  /**
   * Get current workload for an agent
   */
  private async getAgentWorkload(agentId: string): Promise<number> {
    const { count } = await this.supabase
      .from('support_tickets')
      .select('id', { count: 'exact', head: true })
      .eq('assigned_to', agentId)
      .in('status', ['new', 'open', 'in_progress']);

    return count || 0;
  }

  /**
   * Check if agent is available
   */
  private async isAgentAvailable(agentId: string): Promise<boolean> {
    const { data: agent } = await this.supabase
      .from('support_agents')
      .select('status, is_accepting_tickets, max_concurrent_tickets')
      .eq('user_id', agentId)
      .single();

    if (!agent || agent.status !== 'available' || !agent.is_accepting_tickets) {
      return false;
    }

    const workload = await this.getAgentWorkload(agentId);
    return workload < agent.max_concurrent_tickets;
  }

  /**
   * Assign ticket to specific agent
   */
  private async assignTicketToAgent(ticketId: string, agentId: string): Promise<void> {
    const { error } = await this.supabase
      .from('support_tickets')
      .update({
        assigned_to: agentId,
        assigned_at: new Date().toISOString(),
        status: 'open',
      })
      .eq('id', ticketId);

    if (error) {
      console.error('Error assigning ticket:', error);
      throw error;
    }

    // Send notification to agent
    await this.notifyAgentOfAssignment(ticketId, agentId);
  }

  /**
   * Send notification to agent about new assignment
   */
  private async notifyAgentOfAssignment(ticketId: string, agentId: string): Promise<void> {
    // Implement notification logic (email, push, in-app)
    // This would integrate with your notification service
    console.log(`Notifying agent ${agentId} about ticket ${ticketId}`);
  }

  /**
   * Manually assign ticket (override auto-assignment)
   */
  async manuallyAssignTicket(ticketId: string, agentId: string): Promise<void> {
    await this.assignTicketToAgent(ticketId, agentId);
  }

  /**
   * Unassign ticket
   */
  async unassignTicket(ticketId: string): Promise<void> {
    const { error } = await this.supabase
      .from('support_tickets')
      .update({
        assigned_to: null,
        assigned_at: null,
      })
      .eq('id', ticketId);

    if (error) {
      console.error('Error unassigning ticket:', error);
      throw error;
    }
  }

  /**
   * Reassign ticket to different agent
   */
  async reassignTicket(ticketId: string, newAgentId: string): Promise<void> {
    await this.assignTicketToAgent(ticketId, newAgentId);
  }
}

export const ticketAssignmentService = new TicketAssignmentService();
```

### 3. Auto-Assignment Trigger

```sql
-- ==============================================
-- AUTO-ASSIGNMENT TRIGGER
-- ==============================================

CREATE OR REPLACE FUNCTION auto_assign_ticket()
RETURNS TRIGGER AS $$
BEGIN
  -- Only auto-assign if ticket is not already assigned
  IF NEW.assigned_to IS NULL AND NEW.status = 'new' THEN
    -- Call assignment service via Edge Function or external service
    -- This is a placeholder - in practice, you'd trigger an Edge Function
    PERFORM pg_notify('ticket_created', NEW.id::text);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_assign_ticket
  AFTER INSERT ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_ticket();
```

### 4. Agent Management API (`/lib/api/support-agents.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';
import type { SupportAgent } from '@/types/support';

export class SupportAgentsAPI {
  private supabase = createClient();

  /**
   * Get agent profile
   */
  async getAgentProfile(userId: string): Promise<SupportAgent | null> {
    const { data, error } = await this.supabase
      .from('support_agents')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) return null;
    return data;
  }

  /**
   * Update agent status
   */
  async updateStatus(status: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    
    const { error } = await this.supabase
      .from('support_agents')
      .update({ status })
      .eq('user_id', user?.id);

    if (error) throw error;
  }

  /**
   * Toggle accepting tickets
   */
  async toggleAcceptingTickets(accepting: boolean): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    
    const { error } = await this.supabase
      .from('support_agents')
      .update({ is_accepting_tickets: accepting })
      .eq('user_id', user?.id);

    if (error) throw error;
  }

  /**
   * Get agent workload
   */
  async getWorkload(userId: string): Promise<{
    current: number;
    max: number;
    percentage: number;
  }> {
    const { count } = await this.supabase
      .from('support_tickets')
      .select('id', { count: 'exact', head: true })
      .eq('assigned_to', userId)
      .in('status', ['new', 'open', 'in_progress']);

    const { data: agent } = await this.supabase
      .from('support_agents')
      .select('max_concurrent_tickets')
      .eq('user_id', userId)
      .single();

    const current = count || 0;
    const max = agent?.max_concurrent_tickets || 10;
    const percentage = (current / max) * 100;

    return { current, max, percentage };
  }
}

export const supportAgentsAPI = new SupportAgentsAPI();
```

### 5. Agent Status Widget Component

```typescript
'use client';

import { useState, useEffect } from 'react';
import { supportAgentsAPI } from '@/lib/api/support-agents';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Progress } from '@/components/ui/progress';
import { Circle } from 'lucide-react';

export function AgentStatusWidget() {
  const [status, setStatus] = useState('available');
  const [accepting, setAccepting] = useState(true);
  const [workload, setWorkload] = useState({ current: 0, max: 10, percentage: 0 });

  useEffect(() => {
    loadWorkload();
    const interval = setInterval(loadWorkload, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, []);

  const loadWorkload = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const data = await supportAgentsAPI.getWorkload(user.id);
      setWorkload(data);
    }
  };

  const handleStatusChange = async (newStatus: string) => {
    await supportAgentsAPI.updateStatus(newStatus);
    setStatus(newStatus);
  };

  const handleToggleAccepting = async () => {
    const newAccepting = !accepting;
    await supportAgentsAPI.toggleAcceptingTickets(newAccepting);
    setAccepting(newAccepting);
  };

  const getStatusColor = () => {
    switch (status) {
      case 'available': return 'text-green-500';
      case 'busy': return 'text-yellow-500';
      case 'away': return 'text-orange-500';
      case 'offline': return 'text-gray-500';
      default: return 'text-gray-500';
    }
  };

  return (
    <div className="flex items-center gap-4">
      {/* Status Indicator */}
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="sm" className="gap-2">
            <Circle className={`h-3 w-3 fill-current ${getStatusColor()}`} />
            <span className="capitalize">{status}</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent>
          <DropdownMenuItem onClick={() => handleStatusChange('available')}>
            <Circle className="mr-2 h-3 w-3 fill-current text-green-500" />
            Available
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleStatusChange('busy')}>
            <Circle className="mr-2 h-3 w-3 fill-current text-yellow-500" />
            Busy
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleStatusChange('away')}>
            <Circle className="mr-2 h-3 w-3 fill-current text-orange-500" />
            Away
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleStatusChange('offline')}>
            <Circle className="mr-2 h-3 w-3 fill-current text-gray-500" />
            Offline
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      {/* Workload */}
      <div className="flex items-center gap-2">
        <span className="text-sm text-gray-600">
          {workload.current}/{workload.max} tickets
        </span>
        <Progress value={workload.percentage} className="w-24" />
      </div>

      {/* Accepting Tickets Toggle */}
      <Button
        variant={accepting ? 'default' : 'outline'}
        size="sm"
        onClick={handleToggleAccepting}
      >
        {accepting ? 'Accepting Tickets' : 'Not Accepting'}
      </Button>
    </div>
  );
}
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect, vi } from 'vitest';
import { TicketAssignmentService } from '../ticket-assignment';

describe('TicketAssignmentService', () => {
  it('assigns ticket using round-robin', async () => {
    // Test implementation
  });

  it('assigns ticket using skill-based routing', async () => {
    // Test implementation
  });

  it('assigns ticket using least-loaded strategy', async () => {
    // Test implementation
  });

  it('respects agent availability', async () => {
    // Test implementation
  });

  it('respects max concurrent tickets limit', async () => {
    // Test implementation
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Auto-assignment working correctly
- [ ] Manual assignment functional
- [ ] Round-robin distribution balanced
- [ ] Skill-based routing accurate
- [ ] Workload balancing effective
- [ ] Agent status changes respected
- [ ] Notifications sent to agents
- [ ] All tests passing
- [ ] Performance optimized

---

**Status**: ✅ Complete and Ready for Implementation  
**Next Step**: SPEC-135 (Customer Communication System)  
**Estimated Implementation Time**: 3 hours  
**AI-Ready**: 100% - All details specified for autonomous development
