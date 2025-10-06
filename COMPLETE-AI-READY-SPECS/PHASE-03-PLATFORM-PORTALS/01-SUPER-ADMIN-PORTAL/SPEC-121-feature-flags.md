# SPEC-121: Feature Flag Management
## Dynamic Feature Control System

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-117, Phase 1

---

## 📋 OVERVIEW

### Purpose
Centralized feature flag management system allowing super admins to control feature availability globally or per-tenant, enabling gradual rollouts, A/B testing, and emergency feature toggles.

### Key Features
- ✅ Global feature flags
- ✅ Per-tenant feature overrides
- ✅ Feature flag history tracking
- ✅ Percentage-based rollouts
- ✅ Scheduled feature releases
- ✅ Emergency kill switches
- ✅ A/B testing support
- ✅ Feature dependencies
- ✅ Real-time flag updates
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Feature flags table
CREATE TABLE feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  enabled BOOLEAN NOT NULL DEFAULT false,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
  target_tenants UUID[],
  exclude_tenants UUID[],
  requires_flags TEXT[],
  metadata JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  enabled_at TIMESTAMPTZ,
  disabled_at TIMESTAMPTZ
);

-- Tenant feature overrides
CREATE TABLE tenant_feature_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  feature_flag_key TEXT NOT NULL REFERENCES feature_flags(key) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL,
  reason TEXT,
  set_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  UNIQUE(tenant_id, feature_flag_key)
);

CREATE INDEX idx_tenant_feature_overrides_tenant ON tenant_feature_overrides(tenant_id);
CREATE INDEX idx_tenant_feature_overrides_flag ON tenant_feature_overrides(feature_flag_key);

-- Feature flag history
CREATE TABLE feature_flag_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_flag_key TEXT NOT NULL,
  action TEXT NOT NULL,
  previous_state JSONB,
  new_state JSONB,
  changed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_feature_flag_history_key ON feature_flag_history(feature_flag_key);
CREATE INDEX idx_feature_flag_history_created ON feature_flag_history(created_at DESC);

-- Function to check if feature is enabled for tenant
CREATE OR REPLACE FUNCTION is_feature_enabled(
  p_tenant_id UUID,
  p_feature_key TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_override BOOLEAN;
  v_global_enabled BOOLEAN;
  v_rollout_percentage INTEGER;
  v_target_tenants UUID[];
  v_exclude_tenants UUID[];
BEGIN
  -- Check for tenant-specific override
  SELECT enabled INTO v_override
  FROM tenant_feature_overrides
  WHERE tenant_id = p_tenant_id
    AND feature_flag_key = p_feature_key
    AND (expires_at IS NULL OR expires_at > NOW());
  
  IF FOUND THEN
    RETURN v_override;
  END IF;

  -- Get global flag settings
  SELECT enabled, rollout_percentage, target_tenants, exclude_tenants
  INTO v_global_enabled, v_rollout_percentage, v_target_tenants, v_exclude_tenants
  FROM feature_flags
  WHERE key = p_feature_key;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Check if tenant is excluded
  IF p_tenant_id = ANY(v_exclude_tenants) THEN
    RETURN false;
  END IF;

  -- Check if tenant is specifically targeted
  IF array_length(v_target_tenants, 1) > 0 THEN
    RETURN p_tenant_id = ANY(v_target_tenants);
  END IF;

  -- Check rollout percentage
  IF v_rollout_percentage < 100 THEN
    -- Use hash to consistently assign tenant to rollout group
    IF (hashtext(p_tenant_id::text) % 100) < v_rollout_percentage THEN
      RETURN v_global_enabled;
    END IF;
    RETURN false;
  END IF;

  RETURN v_global_enabled;
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## 🎯 API SPECIFICATION

```typescript
// src/types/feature-flag.ts

export interface FeatureFlag {
  id: string
  key: string
  name: string
  description?: string
  enabled: boolean
  rolloutPercentage: number
  targetTenants: string[]
  excludeTenants: string[]
  requiresFlags: string[]
  metadata: Record<string, any>
  createdBy?: string
  createdAt: string
  updatedAt: string
  enabledAt?: string
  disabledAt?: string
}

export interface TenantFeatureOverride {
  id: string
  tenantId: string
  featureFlagKey: string
  enabled: boolean
  reason?: string
  setBy?: string
  createdAt: string
  expiresAt?: string
}

export interface FeatureFlagFormData {
  key: string
  name: string
  description?: string
  enabled: boolean
  rolloutPercentage?: number
  targetTenants?: string[]
  excludeTenants?: string[]
  requiresFlags?: string[]
}
```

### API Routes

```typescript
// src/app/api/platform/feature-flags/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: flags, error } = await supabase
    .from('feature_flags')
    .select('*')
    .order('name')

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ flags })
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const body = await request.json()

  const { data: flag, error } = await supabase
    .from('feature_flags')
    .insert({
      key: body.key,
      name: body.name,
      description: body.description,
      enabled: body.enabled,
      rollout_percentage: body.rolloutPercentage || 0,
      target_tenants: body.targetTenants || [],
      exclude_tenants: body.excludeTenants || [],
      requires_flags: body.requiresFlags || [],
      created_by: user.id,
    })
    .select()
    .single()

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  // Log history
  await supabase.from('feature_flag_history').insert({
    feature_flag_key: flag.key,
    action: 'created',
    new_state: flag,
    changed_by: user.id,
  })

  return NextResponse.json({ flag }, { status: 201 })
}
```

---

[Full implementation with frontend components, testing - ~1600+ lines]

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
