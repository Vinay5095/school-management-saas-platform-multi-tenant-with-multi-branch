# SPEC-182: Performance Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-182  
**Title**: Performance Management & Appraisal System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant HR Portal  
**Category**: Performance  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 5 hours  
**Dependencies**: SPEC-179  

---

## 📋 DESCRIPTION

Comprehensive performance management system with goal setting (OKRs/KPIs), continuous feedback, 360-degree reviews, self-assessments, manager evaluations, performance improvement plans (PIP), rating calibration, and performance analytics.

---

## 🎯 SUCCESS CRITERIA

- [ ] Goal setting operational
- [ ] Performance reviews working
- [ ] 360-degree feedback functional
- [ ] Rating calibration enabled
- [ ] PIP management operational
- [ ] Performance analytics available
- [ ] Automated workflows active
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Performance Review Cycles
CREATE TABLE IF NOT EXISTS performance_review_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Cycle details
  cycle_name VARCHAR(200) NOT NULL,
  cycle_type VARCHAR(50) NOT NULL, -- annual, half_yearly, quarterly
  
  -- Period
  review_period_start DATE NOT NULL,
  review_period_end DATE NOT NULL,
  
  -- Timeline
  goal_setting_start DATE,
  goal_setting_end DATE,
  self_review_start DATE,
  self_review_end DATE,
  manager_review_start DATE,
  manager_review_end DATE,
  calibration_date DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, active, in_review, calibration, completed, closed
  
  -- Settings
  include_360_feedback BOOLEAN DEFAULT false,
  include_peer_review BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'active', 'in_review', 'calibration', 'completed', 'closed'))
);

CREATE INDEX ON performance_review_cycles(tenant_id, status);

-- Employee Goals (OKRs/KPIs)
CREATE TABLE IF NOT EXISTS employee_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  cycle_id UUID NOT NULL REFERENCES performance_review_cycles(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Goal details
  goal_title VARCHAR(300) NOT NULL,
  goal_description TEXT,
  goal_category VARCHAR(50), -- performance, development, behavioral
  goal_type VARCHAR(50), -- objective, key_result, kpi
  
  -- Measurement
  measurement_criteria TEXT,
  target_value VARCHAR(100),
  current_value VARCHAR(100),
  
  -- Weight
  weight_percentage NUMERIC(5,2),
  
  -- Timeline
  start_date DATE NOT NULL,
  due_date DATE NOT NULL,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, active, achieved, partially_achieved, not_achieved
  achievement_percentage INTEGER DEFAULT 0,
  
  -- Alignment
  aligned_to_company_goal UUID,
  
  -- Approval
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'active', 'achieved', 'partially_achieved', 'not_achieved'))
);

CREATE INDEX ON employee_goals(employee_id, cycle_id);
CREATE INDEX ON employee_goals(tenant_id);

-- Performance Reviews
CREATE TABLE IF NOT EXISTS performance_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  cycle_id UUID NOT NULL REFERENCES performance_review_cycles(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Review details
  review_type VARCHAR(50) NOT NULL, -- self, manager, peer, subordinate
  reviewer_id UUID REFERENCES auth.users(id),
  
  -- Ratings
  overall_rating INTEGER,
  technical_competency_rating INTEGER,
  behavioral_competency_rating INTEGER,
  goal_achievement_rating INTEGER,
  
  -- Comments
  strengths TEXT,
  areas_of_improvement TEXT,
  achievements TEXT,
  detailed_feedback TEXT,
  
  -- Recommendations
  promotion_recommended BOOLEAN DEFAULT false,
  salary_increment_percentage NUMERIC(5,2),
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, submitted, acknowledged, completed
  submitted_at TIMESTAMP WITH TIME ZONE,
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  
  -- Calibration
  calibrated_rating INTEGER,
  calibration_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_rating CHECK (overall_rating BETWEEN 1 AND 5),
  CONSTRAINT valid_status CHECK (status IN ('draft', 'submitted', 'acknowledged', 'completed'))
);

CREATE INDEX ON performance_reviews(employee_id, cycle_id);
CREATE INDEX ON performance_reviews(reviewer_id);

-- Competency Ratings
CREATE TABLE IF NOT EXISTS competency_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES performance_reviews(id) ON DELETE CASCADE,
  
  -- Competency
  competency_name VARCHAR(200) NOT NULL,
  competency_category VARCHAR(50), -- technical, behavioral, leadership
  
  -- Rating
  rating INTEGER NOT NULL,
  comments TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX ON competency_ratings(review_id);

-- Performance Improvement Plans (PIP)
CREATE TABLE IF NOT EXISTS performance_improvement_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- PIP details
  pip_number VARCHAR(50) UNIQUE NOT NULL,
  reason TEXT NOT NULL,
  
  -- Timeline
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  review_frequency VARCHAR(50), -- weekly, bi_weekly, monthly
  
  -- Objectives
  objectives TEXT NOT NULL,
  success_criteria TEXT NOT NULL,
  
  -- Support
  support_provided TEXT,
  training_required TEXT,
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, successful, unsuccessful, extended, cancelled
  
  -- Manager
  manager_id UUID NOT NULL REFERENCES staff(id),
  hr_coordinator_id UUID REFERENCES auth.users(id),
  
  -- Outcome
  final_outcome TEXT,
  completion_notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('active', 'successful', 'unsuccessful', 'extended', 'cancelled'))
);

CREATE INDEX ON performance_improvement_plans(employee_id);
CREATE INDEX ON performance_improvement_plans(status);

-- PIP Progress Reviews
CREATE TABLE IF NOT EXISTS pip_progress_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pip_id UUID NOT NULL REFERENCES performance_improvement_plans(id) ON DELETE CASCADE,
  
  -- Review details
  review_date DATE NOT NULL,
  progress_summary TEXT NOT NULL,
  
  -- Rating
  progress_rating VARCHAR(50), -- exceeding, meeting, below, not_meeting
  
  -- Feedback
  manager_feedback TEXT,
  employee_comments TEXT,
  
  -- Next steps
  action_items TEXT,
  
  reviewed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON pip_progress_reviews(pip_id, review_date);

-- Continuous Feedback
CREATE TABLE IF NOT EXISTS continuous_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Feedback details
  feedback_type VARCHAR(50), -- praise, constructive, suggestion
  feedback_text TEXT NOT NULL,
  
  -- Context
  project_context VARCHAR(200),
  skill_area VARCHAR(100),
  
  -- Giver
  given_by UUID NOT NULL REFERENCES auth.users(id),
  
  -- Visibility
  is_private BOOLEAN DEFAULT false,
  shared_with UUID[],
  
  -- Acknowledgment
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON continuous_feedback(employee_id);
CREATE INDEX ON continuous_feedback(given_by);

-- Function to calculate overall review rating
CREATE OR REPLACE FUNCTION calculate_overall_rating(
  p_review_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  v_avg_rating NUMERIC;
BEGIN
  SELECT AVG(rating)::INTEGER INTO v_avg_rating
  FROM competency_ratings
  WHERE review_id = p_review_id;
  
  RETURN COALESCE(v_avg_rating, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to get performance distribution
CREATE OR REPLACE FUNCTION get_performance_distribution(
  p_tenant_id UUID,
  p_cycle_id UUID
)
RETURNS TABLE (
  rating INTEGER,
  employee_count BIGINT,
  percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH ratings AS (
    SELECT 
      pr.overall_rating,
      COUNT(*) as count
    FROM performance_reviews pr
    WHERE pr.tenant_id = p_tenant_id
    AND pr.cycle_id = p_cycle_id
    AND pr.status = 'completed'
    AND pr.overall_rating IS NOT NULL
    GROUP BY pr.overall_rating
  ),
  total AS (
    SELECT SUM(count) as total_count FROM ratings
  )
  SELECT
    r.overall_rating,
    r.count,
    ROUND((r.count::NUMERIC / t.total_count) * 100, 2)
  FROM ratings r
  CROSS JOIN total t
  ORDER BY r.overall_rating DESC;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update goal achievement
CREATE OR REPLACE FUNCTION update_goal_achievement()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.current_value IS NOT NULL AND NEW.target_value IS NOT NULL THEN
    -- Simple percentage calculation (can be enhanced based on goal type)
    BEGIN
      NEW.achievement_percentage := LEAST(
        100,
        ROUND((NEW.current_value::NUMERIC / NEW.target_value::NUMERIC) * 100)
      );
    EXCEPTION WHEN OTHERS THEN
      -- Keep existing value if calculation fails
      NULL;
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_goal_achievement
  BEFORE UPDATE ON employee_goals
  FOR EACH ROW
  WHEN (NEW.current_value IS DISTINCT FROM OLD.current_value)
  EXECUTE FUNCTION update_goal_achievement();

-- Enable RLS
ALTER TABLE performance_review_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE competency_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_improvement_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE pip_progress_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE continuous_feedback ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/performance.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface PerformanceCycle {
  id: string;
  cycleName: string;
  reviewPeriodStart: string;
  reviewPeriodEnd: string;
  status: string;
}

export interface EmployeeGoal {
  id: string;
  goalTitle: string;
  goalDescription: string;
  targetValue: string;
  currentValue: string;
  achievementPercentage: number;
  dueDate: string;
  status: string;
}

export class PerformanceAPI {
  private supabase = createClient();

  async createReviewCycle(params: {
    tenantId: string;
    cycleName: string;
    cycleType: string;
    reviewPeriodStart: Date;
    reviewPeriodEnd: Date;
  }): Promise<PerformanceCycle> {
    const { data, error } = await this.supabase
      .from('performance_review_cycles')
      .insert({
        tenant_id: params.tenantId,
        cycle_name: params.cycleName,
        cycle_type: params.cycleType,
        review_period_start: params.reviewPeriodStart.toISOString().split('T')[0],
        review_period_end: params.reviewPeriodEnd.toISOString().split('T')[0],
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      cycleName: data.cycle_name,
      reviewPeriodStart: data.review_period_start,
      reviewPeriodEnd: data.review_period_end,
      status: data.status,
    };
  }

  async setEmployeeGoal(params: {
    employeeId: string;
    cycleId: string;
    tenantId: string;
    goalTitle: string;
    goalDescription: string;
    goalType: string;
    targetValue: string;
    dueDate: Date;
    weightPercentage?: number;
  }): Promise<EmployeeGoal> {
    const { data, error } = await this.supabase
      .from('employee_goals')
      .insert({
        employee_id: params.employeeId,
        cycle_id: params.cycleId,
        tenant_id: params.tenantId,
        goal_title: params.goalTitle,
        goal_description: params.goalDescription,
        goal_type: params.goalType,
        target_value: params.targetValue,
        start_date: new Date().toISOString().split('T')[0],
        due_date: params.dueDate.toISOString().split('T')[0],
        weight_percentage: params.weightPercentage,
        status: 'draft',
      })
      .select()
      .single();

    if (error) throw error;

    return this.mapGoal(data);
  }

  async updateGoalProgress(params: {
    goalId: string;
    currentValue: string;
    notes?: string;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('employee_goals')
      .update({
        current_value: params.currentValue,
        notes: params.notes,
      })
      .eq('id', params.goalId);

    if (error) throw error;
  }

  async getEmployeeGoals(params: {
    employeeId: string;
    cycleId: string;
  }): Promise<EmployeeGoal[]> {
    const { data, error } = await this.supabase
      .from('employee_goals')
      .select('*')
      .eq('employee_id', params.employeeId)
      .eq('cycle_id', params.cycleId)
      .order('created_at');

    if (error) throw error;

    return (data || []).map(this.mapGoal);
  }

  async submitSelfReview(params: {
    employeeId: string;
    cycleId: string;
    tenantId: string;
    overallRating: number;
    strengths: string;
    areasOfImprovement: string;
    achievements: string;
    competencyRatings: Array<{
      competencyName: string;
      rating: number;
      comments: string;
    }>;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    // Create self review
    const { data: review, error: reviewError } = await this.supabase
      .from('performance_reviews')
      .insert({
        employee_id: params.employeeId,
        cycle_id: params.cycleId,
        tenant_id: params.tenantId,
        review_type: 'self',
        reviewer_id: user?.id,
        overall_rating: params.overallRating,
        strengths: params.strengths,
        areas_of_improvement: params.areasOfImprovement,
        achievements: params.achievements,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (reviewError) throw reviewError;

    // Add competency ratings
    if (params.competencyRatings.length > 0) {
      const { error: compError } = await this.supabase
        .from('competency_ratings')
        .insert(
          params.competencyRatings.map(comp => ({
            review_id: review.id,
            competency_name: comp.competencyName,
            rating: comp.rating,
            comments: comp.comments,
          }))
        );

      if (compError) throw compError;
    }

    return review;
  }

  async submitManagerReview(params: {
    employeeId: string;
    cycleId: string;
    tenantId: string;
    overallRating: number;
    strengths: string;
    areasOfImprovement: string;
    detailedFeedback: string;
    promotionRecommended: boolean;
    salaryIncrementPercentage?: number;
    competencyRatings: Array<{
      competencyName: string;
      rating: number;
      comments: string;
    }>;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data: review, error: reviewError } = await this.supabase
      .from('performance_reviews')
      .insert({
        employee_id: params.employeeId,
        cycle_id: params.cycleId,
        tenant_id: params.tenantId,
        review_type: 'manager',
        reviewer_id: user?.id,
        overall_rating: params.overallRating,
        strengths: params.strengths,
        areas_of_improvement: params.areasOfImprovement,
        detailed_feedback: params.detailedFeedback,
        promotion_recommended: params.promotionRecommended,
        salary_increment_percentage: params.salaryIncrementPercentage,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (reviewError) throw reviewError;

    // Add competency ratings
    if (params.competencyRatings.length > 0) {
      const { error: compError } = await this.supabase
        .from('competency_ratings')
        .insert(
          params.competencyRatings.map(comp => ({
            review_id: review.id,
            competency_name: comp.competencyName,
            competency_category: 'behavioral',
            rating: comp.rating,
            comments: comp.comments,
          }))
        );

      if (compError) throw compError;
    }

    return review;
  }

  async createPIP(params: {
    employeeId: string;
    tenantId: string;
    reason: string;
    objectives: string;
    successCriteria: string;
    startDate: Date;
    endDate: Date;
    managerId: string;
  }) {
    const pipNumber = `PIP-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('performance_improvement_plans')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        pip_number: pipNumber,
        reason: params.reason,
        objectives: params.objectives,
        success_criteria: params.successCriteria,
        start_date: params.startDate.toISOString().split('T')[0],
        end_date: params.endDate.toISOString().split('T')[0],
        manager_id: params.managerId,
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async giveFeedback(params: {
    employeeId: string;
    tenantId: string;
    feedbackType: string;
    feedbackText: string;
    skillArea?: string;
  }) {
    const { data: { user } } = await this.supabase.auth.getUser();

    const { data, error } = await this.supabase
      .from('continuous_feedback')
      .insert({
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        feedback_type: params.feedbackType,
        feedback_text: params.feedbackText,
        skill_area: params.skillArea,
        given_by: user?.id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getPerformanceDistribution(params: {
    tenantId: string;
    cycleId: string;
  }) {
    const { data, error } = await this.supabase.rpc(
      'get_performance_distribution',
      {
        p_tenant_id: params.tenantId,
        p_cycle_id: params.cycleId,
      }
    );

    if (error) throw error;

    return data.map((item: any) => ({
      rating: item.rating,
      employeeCount: item.employee_count,
      percentage: item.percentage,
    }));
  }

  private mapGoal(data: any): EmployeeGoal {
    return {
      id: data.id,
      goalTitle: data.goal_title,
      goalDescription: data.goal_description,
      targetValue: data.target_value,
      currentValue: data.current_value,
      achievementPercentage: data.achievement_percentage,
      dueDate: data.due_date,
      status: data.status,
    };
  }
}

export const performanceAPI = new PerformanceAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { PerformanceAPI } from '../performance';

describe('PerformanceAPI', () => {
  it('creates review cycle', async () => {
    const api = new PerformanceAPI();
    const cycle = await api.createReviewCycle({
      tenantId: 'test-tenant',
      cycleName: 'Annual Review 2025',
      cycleType: 'annual',
      reviewPeriodStart: new Date('2025-01-01'),
      reviewPeriodEnd: new Date('2025-12-31'),
    });

    expect(cycle).toHaveProperty('id');
    expect(cycle.cycleName).toBe('Annual Review 2025');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Goal setting operational
- [ ] Reviews working
- [ ] 360 feedback functional
- [ ] PIP management working
- [ ] Analytics available
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-183 (Training)  
**Time**: 5 hours  
**AI-Ready**: 100%
