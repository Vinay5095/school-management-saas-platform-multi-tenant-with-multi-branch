# SPEC-160: Strategic Planning Tools
## Long-term Planning, Goal Setting, and KPI Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-151, SPEC-159, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Comprehensive strategic planning toolkit for tenant administrators to set organizational goals, define KPIs, track progress, and manage long-term initiatives across all branches.

### Key Features
- ✅ Strategic plan creation and management
- ✅ SMART goal setting
- ✅ KPI definition and tracking
- ✅ Milestone management
- ✅ Initiative tracking
- ✅ Progress visualization
- ✅ Branch-level goal alignment
- ✅ Performance dashboards
- ✅ Quarterly/annual reviews
- ✅ Goal dependencies
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Strategic plans table
CREATE TABLE strategic_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  vision_statement TEXT,
  mission_statement TEXT,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('annual', 'multi_year', 'quarterly', 'custom')),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'completed', 'cancelled')) DEFAULT 'draft',
  overall_progress DECIMAL(5, 2) DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_strategic_plans_tenant ON strategic_plans(tenant_id);
CREATE INDEX idx_strategic_plans_status ON strategic_plans(status);
CREATE INDEX idx_strategic_plans_dates ON strategic_plans(start_date, end_date);

-- Strategic goals table
CREATE TABLE strategic_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES strategic_plans(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  parent_goal_id UUID REFERENCES strategic_goals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('financial', 'academic', 'operational', 'hr', 'infrastructure', 'technology', 'marketing', 'other')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  target_type TEXT NOT NULL CHECK (target_type IN ('organization', 'branches', 'specific_branches')),
  target_branches UUID[] DEFAULT ARRAY[]::UUID[],
  start_date DATE NOT NULL,
  target_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'on_track', 'at_risk', 'delayed', 'completed', 'cancelled')) DEFAULT 'not_started',
  progress DECIMAL(5, 2) DEFAULT 0,
  is_smart BOOLEAN DEFAULT false, -- Specific, Measurable, Achievable, Relevant, Time-bound
  smart_criteria JSONB DEFAULT '{}'::jsonb,
  assigned_to UUID REFERENCES auth.users(id),
  owner_id UUID REFERENCES auth.users(id),
  dependencies UUID[] DEFAULT ARRAY[]::UUID[],
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_strategic_goals_plan ON strategic_goals(plan_id);
CREATE INDEX idx_strategic_goals_tenant ON strategic_goals(tenant_id);
CREATE INDEX idx_strategic_goals_parent ON strategic_goals(parent_goal_id);
CREATE INDEX idx_strategic_goals_status ON strategic_goals(status);
CREATE INDEX idx_strategic_goals_target_date ON strategic_goals(target_date);
CREATE INDEX idx_strategic_goals_category ON strategic_goals(category);

-- KPIs (Key Performance Indicators) table
CREATE TABLE kpis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID REFERENCES strategic_goals(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  metric_type TEXT NOT NULL CHECK (metric_type IN ('number', 'percentage', 'currency', 'ratio', 'boolean')),
  measurement_unit TEXT,
  baseline_value DECIMAL(12, 2),
  target_value DECIMAL(12, 2) NOT NULL,
  current_value DECIMAL(12, 2) DEFAULT 0,
  threshold_warning DECIMAL(12, 2),
  threshold_critical DECIMAL(12, 2),
  measurement_frequency TEXT CHECK (measurement_frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'annual')),
  data_source TEXT,
  calculation_method TEXT,
  is_cumulative BOOLEAN DEFAULT false,
  status TEXT CHECK (status IN ('on_track', 'at_risk', 'critical', 'achieved')) DEFAULT 'on_track',
  last_measured_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kpis_goal ON kpis(goal_id);
CREATE INDEX idx_kpis_tenant ON kpis(tenant_id);
CREATE INDEX idx_kpis_status ON kpis(status);

-- KPI measurements table
CREATE TABLE kpi_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kpi_id UUID NOT NULL REFERENCES kpis(id) ON DELETE CASCADE,
  measurement_date DATE NOT NULL,
  value DECIMAL(12, 2) NOT NULL,
  notes TEXT,
  measured_by UUID REFERENCES auth.users(id),
  verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(kpi_id, measurement_date)
);

CREATE INDEX idx_kpi_measurements_kpi ON kpi_measurements(kpi_id);
CREATE INDEX idx_kpi_measurements_date ON kpi_measurements(measurement_date DESC);

-- Milestones table
CREATE TABLE strategic_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES strategic_goals(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE NOT NULL,
  completion_date DATE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'missed', 'cancelled')) DEFAULT 'pending',
  deliverables JSONB DEFAULT '[]'::jsonb,
  assigned_to UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_milestones_goal ON strategic_milestones(goal_id);
CREATE INDEX idx_milestones_tenant ON strategic_milestones(tenant_id);
CREATE INDEX idx_milestones_status ON strategic_milestones(status);
CREATE INDEX idx_milestones_due_date ON strategic_milestones(due_date);

-- Initiatives table
CREATE TABLE strategic_initiatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES strategic_goals(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  initiative_type TEXT NOT NULL CHECK (initiative_type IN ('project', 'program', 'campaign', 'process_improvement', 'other')),
  budget_allocated DECIMAL(12, 2),
  budget_spent DECIMAL(12, 2) DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('planning', 'in_progress', 'on_hold', 'completed', 'cancelled')) DEFAULT 'planning',
  progress DECIMAL(5, 2) DEFAULT 0,
  owner_id UUID REFERENCES auth.users(id),
  team_members UUID[] DEFAULT ARRAY[]::UUID[],
  expected_outcomes TEXT[],
  actual_outcomes TEXT[],
  risks JSONB DEFAULT '[]'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_initiatives_goal ON strategic_initiatives(goal_id);
CREATE INDEX idx_initiatives_tenant ON strategic_initiatives(tenant_id);
CREATE INDEX idx_initiatives_status ON strategic_initiatives(status);
CREATE INDEX idx_initiatives_owner ON strategic_initiatives(owner_id);

-- Progress updates table
CREATE TABLE goal_progress_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES strategic_goals(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  update_type TEXT NOT NULL CHECK (update_type IN ('progress', 'status_change', 'milestone', 'issue', 'note')),
  progress_value DECIMAL(5, 2),
  status TEXT,
  title TEXT,
  description TEXT NOT NULL,
  achievements TEXT[],
  challenges TEXT[],
  next_steps TEXT[],
  attachments JSONB DEFAULT '[]'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_progress_updates_goal ON goal_progress_updates(goal_id);
CREATE INDEX idx_progress_updates_tenant ON goal_progress_updates(tenant_id);
CREATE INDEX idx_progress_updates_date ON goal_progress_updates(created_at DESC);

-- Function to calculate goal progress
CREATE OR REPLACE FUNCTION calculate_goal_progress(
  p_goal_id UUID
)
RETURNS DECIMAL(5, 2) AS $$
DECLARE
  v_progress DECIMAL(5, 2);
  v_kpi_progress DECIMAL(5, 2);
  v_milestone_progress DECIMAL(5, 2);
  v_initiative_progress DECIMAL(5, 2);
BEGIN
  -- Calculate progress from KPIs
  SELECT AVG(
    CASE 
      WHEN k.target_value = 0 THEN 0
      ELSE (k.current_value / k.target_value * 100)
    END
  ) INTO v_kpi_progress
  FROM kpis k
  WHERE k.goal_id = p_goal_id;

  -- Calculate progress from milestones
  SELECT 
    (COUNT(*) FILTER (WHERE status = 'completed')::DECIMAL / 
     NULLIF(COUNT(*), 0) * 100)
  INTO v_milestone_progress
  FROM strategic_milestones
  WHERE goal_id = p_goal_id;

  -- Calculate progress from initiatives
  SELECT AVG(progress)
  INTO v_initiative_progress
  FROM strategic_initiatives
  WHERE goal_id = p_goal_id;

  -- Weighted average (40% KPIs, 30% Milestones, 30% Initiatives)
  v_progress := COALESCE(
    (v_kpi_progress * 0.4) + 
    (v_milestone_progress * 0.3) + 
    (v_initiative_progress * 0.3),
    0
  );

  -- Update goal progress
  UPDATE strategic_goals
  SET 
    progress = v_progress,
    status = CASE
      WHEN v_progress = 100 THEN 'completed'
      WHEN v_progress >= 75 THEN 'on_track'
      WHEN v_progress >= 50 THEN 'in_progress'
      WHEN v_progress < 50 AND target_date < CURRENT_DATE THEN 'delayed'
      ELSE 'at_risk'
    END,
    updated_at = NOW()
  WHERE id = p_goal_id;

  RETURN v_progress;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update plan progress
CREATE OR REPLACE FUNCTION update_plan_progress(
  p_plan_id UUID
)
RETURNS DECIMAL(5, 2) AS $$
DECLARE
  v_progress DECIMAL(5, 2);
BEGIN
  SELECT AVG(progress)
  INTO v_progress
  FROM strategic_goals
  WHERE plan_id = p_plan_id
    AND deleted_at IS NULL;

  UPDATE strategic_plans
  SET 
    overall_progress = COALESCE(v_progress, 0),
    updated_at = NOW()
  WHERE id = p_plan_id;

  RETURN COALESCE(v_progress, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update goal progress on KPI measurement
CREATE OR REPLACE FUNCTION trigger_update_goal_progress()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM calculate_goal_progress(
    (SELECT goal_id FROM kpis WHERE id = NEW.kpi_id)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_progress_on_kpi_measurement
AFTER INSERT OR UPDATE ON kpi_measurements
FOR EACH ROW
EXECUTE FUNCTION trigger_update_goal_progress();

-- Trigger to update plan progress on goal update
CREATE OR REPLACE FUNCTION trigger_update_plan_progress()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_plan_progress(NEW.plan_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_plan_on_goal_change
AFTER UPDATE ON strategic_goals
FOR EACH ROW
WHEN (OLD.progress IS DISTINCT FROM NEW.progress)
EXECUTE FUNCTION trigger_update_plan_progress();

-- RLS Policies
ALTER TABLE strategic_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE strategic_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpis ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE strategic_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE strategic_initiatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_progress_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_admin_strategic_plans ON strategic_plans
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_strategic_goals ON strategic_goals
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_kpis ON kpis
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_kpi_measurements ON kpi_measurements
  FOR ALL USING (
    kpi_id IN (
      SELECT id FROM kpis
      WHERE tenant_id IN (
        SELECT tenant_id FROM user_profiles
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY tenant_milestones ON strategic_milestones
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_initiatives ON strategic_initiatives
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY tenant_progress_updates ON goal_progress_updates
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
  );
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/strategic-planning.ts

export interface StrategicPlan {
  id: string
  tenantId: string
  title: string
  description?: string
  visionStatement?: string
  missionStatement?: string
  planType: 'annual' | 'multi_year' | 'quarterly' | 'custom'
  startDate: string
  endDate: string
  status: 'draft' | 'active' | 'completed' | 'cancelled'
  overallProgress: number
  createdBy?: string
  approvedBy?: string
  approvedAt?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface StrategicGoal {
  id: string
  planId: string
  tenantId: string
  parentGoalId?: string
  title: string
  description?: string
  category: 'financial' | 'academic' | 'operational' | 'hr' | 'infrastructure' | 'technology' | 'marketing' | 'other'
  priority: 'low' | 'medium' | 'high' | 'critical'
  targetType: 'organization' | 'branches' | 'specific_branches'
  targetBranches?: string[]
  startDate: string
  targetDate: string
  status: 'not_started' | 'in_progress' | 'on_track' | 'at_risk' | 'delayed' | 'completed' | 'cancelled'
  progress: number
  isSmart: boolean
  smartCriteria?: {
    specific: string
    measurable: string
    achievable: string
    relevant: string
    timeBound: string
  }
  assignedTo?: string
  ownerId?: string
  dependencies?: string[]
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface KPI {
  id: string
  goalId?: string
  tenantId: string
  name: string
  description?: string
  metricType: 'number' | 'percentage' | 'currency' | 'ratio' | 'boolean'
  measurementUnit?: string
  baselineValue?: number
  targetValue: number
  currentValue: number
  thresholdWarning?: number
  thresholdCritical?: number
  measurementFrequency?: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'annual'
  dataSource?: string
  calculationMethod?: string
  isCumulative: boolean
  status: 'on_track' | 'at_risk' | 'critical' | 'achieved'
  lastMeasuredAt?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface KPIMeasurement {
  id: string
  kpiId: string
  measurementDate: string
  value: number
  notes?: string
  measuredBy?: string
  verified: boolean
  verifiedBy?: string
  verifiedAt?: string
  metadata?: Record<string, any>
  createdAt: string
}

export interface StrategicMilestone {
  id: string
  goalId: string
  tenantId: string
  title: string
  description?: string
  dueDate: string
  completionDate?: string
  status: 'pending' | 'in_progress' | 'completed' | 'missed' | 'cancelled'
  deliverables?: Array<{ name: string; completed: boolean }>
  assignedTo?: string
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface StrategicInitiative {
  id: string
  goalId: string
  tenantId: string
  title: string
  description?: string
  initiativeType: 'project' | 'program' | 'campaign' | 'process_improvement' | 'other'
  budgetAllocated?: number
  budgetSpent: number
  startDate: string
  endDate: string
  status: 'planning' | 'in_progress' | 'on_hold' | 'completed' | 'cancelled'
  progress: number
  ownerId?: string
  teamMembers?: string[]
  expectedOutcomes?: string[]
  actualOutcomes?: string[]
  risks?: Array<{ risk: string; severity: string; mitigation: string }>
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}
```

### API Routes

```typescript
// src/app/api/tenant/strategic-plans/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const { data: plans, error } = await supabase
      .from('strategic_plans')
      .select(`
        *,
        creator:auth.users!created_by (
          id,
          email,
          user_metadata
        ),
        goals:strategic_goals (
          id,
          title,
          status,
          progress
        )
      `)
      .eq('tenant_id', profile.tenant_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({ plans })

  } catch (error) {
    console.error('Failed to fetch strategic plans:', error)
    return NextResponse.json(
      { error: 'Failed to fetch strategic plans' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id, role')
    .eq('user_id', user.id)
    .single()

  if (!profile || profile.role !== 'tenant_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const body = await request.json()

    const { data: plan, error } = await supabase
      .from('strategic_plans')
      .insert({
        tenant_id: profile.tenant_id,
        created_by: user.id,
        ...body,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ plan }, { status: 201 })

  } catch (error) {
    console.error('Failed to create strategic plan:', error)
    return NextResponse.json(
      { error: 'Failed to create strategic plan' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/strategic-plans/[id]/goals/route.ts

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { data: goals, error } = await supabase
      .from('strategic_goals')
      .select(`
        *,
        assignedUser:auth.users!assigned_to (
          id,
          email,
          user_metadata
        ),
        owner:auth.users!owner_id (
          id,
          email,
          user_metadata
        ),
        kpis:kpis (
          id,
          name,
          current_value,
          target_value,
          status
        ),
        milestones:strategic_milestones (
          id,
          title,
          status,
          due_date
        ),
        initiatives:strategic_initiatives (
          id,
          title,
          status,
          progress
        )
      `)
      .eq('plan_id', params.id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({ goals })

  } catch (error) {
    console.error('Failed to fetch goals:', error)
    return NextResponse.json(
      { error: 'Failed to fetch goals' },
      { status: 500 }
    )
  }
}

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('tenant_id')
    .eq('user_id', user.id)
    .single()

  try {
    const body = await request.json()

    const { data: goal, error } = await supabase
      .from('strategic_goals')
      .insert({
        plan_id: params.id,
        tenant_id: profile.tenant_id,
        ...body,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ goal }, { status: 201 })

  } catch (error) {
    console.error('Failed to create goal:', error)
    return NextResponse.json(
      { error: 'Failed to create goal' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Strategic Planning Dashboard

```typescript
// src/app/tenant/strategic-planning/page.tsx

'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Progress } from '@/components/ui/progress'
import { Badge } from '@/components/ui/badge'
import { 
  Target, TrendingUp, CheckCircle, AlertTriangle, 
  Plus, Calendar 
} from 'lucide-react'
import { CreatePlanDialog } from '@/components/strategic/create-plan-dialog'
import { GoalsList } from '@/components/strategic/goals-list'
import { KPIDashboard } from '@/components/strategic/kpi-dashboard'

export default function StrategicPlanningPage() {
  const [isCreateOpen, setIsCreateOpen] = useState(false)

  const { data, isLoading } = useQuery({
    queryKey: ['strategic-plans'],
    queryFn: async () => {
      const res = await fetch('/api/tenant/strategic-plans')
      if (!res.ok) throw new Error('Failed to fetch plans')
      return res.json()
    },
  })

  if (isLoading) {
    return <div>Loading...</div>
  }

  const activePlan = data.plans?.find((p: any) => p.status === 'active')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Strategic Planning</h1>
          <p className="text-muted-foreground">
            Long-term goals and organizational strategy
          </p>
        </div>
        <Button onClick={() => setIsCreateOpen(true)}>
          <Plus className="h-4 w-4 mr-2" />
          New Strategic Plan
        </Button>
      </div>

      {activePlan && (
        <>
          {/* Active Plan Overview */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>{activePlan.title}</CardTitle>
                  <p className="text-sm text-muted-foreground">
                    {new Date(activePlan.start_date).getFullYear()} - {new Date(activePlan.end_date).getFullYear()}
                  </p>
                </div>
                <Badge variant="success">Active</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium">Overall Progress</span>
                    <span className="text-2xl font-bold">
                      {activePlan.overall_progress.toFixed(0)}%
                    </span>
                  </div>
                  <Progress value={activePlan.overall_progress} className="h-3" />
                </div>

                <div className="grid grid-cols-4 gap-4 pt-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Total Goals</p>
                    <p className="text-2xl font-bold">{activePlan.goals?.length || 0}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">On Track</p>
                    <p className="text-2xl font-bold text-green-600">
                      {activePlan.goals?.filter((g: any) => g.status === 'on_track').length || 0}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">At Risk</p>
                    <p className="text-2xl font-bold text-yellow-600">
                      {activePlan.goals?.filter((g: any) => g.status === 'at_risk').length || 0}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Completed</p>
                    <p className="text-2xl font-bold text-blue-600">
                      {activePlan.goals?.filter((g: any) => g.status === 'completed').length || 0}
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Goals and KPIs */}
          <Tabs defaultValue="goals">
            <TabsList>
              <TabsTrigger value="goals">Goals</TabsTrigger>
              <TabsTrigger value="kpis">KPIs</TabsTrigger>
              <TabsTrigger value="initiatives">Initiatives</TabsTrigger>
              <TabsTrigger value="milestones">Milestones</TabsTrigger>
            </TabsList>

            <TabsContent value="goals" className="mt-6">
              <GoalsList planId={activePlan.id} />
            </TabsContent>

            <TabsContent value="kpis" className="mt-6">
              <KPIDashboard planId={activePlan.id} />
            </TabsContent>

            <TabsContent value="initiatives" className="mt-6">
              {/* Initiatives list component */}
            </TabsContent>

            <TabsContent value="milestones" className="mt-6">
              {/* Milestones list component */}
            </TabsContent>
          </Tabs>
        </>
      )}

      <CreatePlanDialog
        open={isCreateOpen}
        onOpenChange={setIsCreateOpen}
      />
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Create and manage strategic plans
- [x] Define SMART goals
- [x] Track KPIs with measurements
- [x] Manage milestones and initiatives
- [x] Automated progress calculation
- [x] Branch-level goal alignment
- [x] Progress visualization
- [x] Goal dependencies tracking
- [x] Performance dashboards
- [x] Progress updates and notes
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
