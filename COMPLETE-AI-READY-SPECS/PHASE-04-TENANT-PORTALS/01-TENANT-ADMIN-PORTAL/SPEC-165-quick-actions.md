# SPEC-165: Quick Actions Dashboard
## Frequently Used Actions and Shortcuts

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 3-4 hours  
> **Dependencies**: SPEC-151, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Quick access dashboard widget providing tenant administrators with one-click shortcuts to frequently used actions, recent items, and contextual recommendations to improve workflow efficiency.

### Key Features
- ✅ Customizable quick action buttons
- ✅ Recent items access
- ✅ Frequently used features
- ✅ Contextual recommendations
- ✅ Keyboard shortcuts
- ✅ Search functionality
- ✅ Pinned actions
- ✅ Usage analytics
- ✅ Drag-and-drop customization
- ✅ Role-based actions
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Quick actions table
CREATE TABLE quick_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  action_key TEXT NOT NULL,
  action_name TEXT NOT NULL,
  action_description TEXT,
  action_type TEXT NOT NULL CHECK (action_type IN ('navigation', 'modal', 'api_call', 'external_link', 'command')),
  action_url TEXT,
  action_icon TEXT,
  action_color TEXT,
  action_params JSONB DEFAULT '{}'::jsonb,
  required_permissions TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_system_action BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, action_key)
);

CREATE INDEX idx_quick_actions_tenant ON quick_actions(tenant_id);
CREATE INDEX idx_quick_actions_active ON quick_actions(is_active);
CREATE INDEX idx_quick_actions_order ON quick_actions(display_order);

-- User quick actions (pinned/customized)
CREATE TABLE user_quick_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES quick_actions(id) ON DELETE CASCADE,
  is_pinned BOOLEAN DEFAULT true,
  custom_label TEXT,
  custom_icon TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, action_id)
);

CREATE INDEX idx_user_quick_actions_user ON user_quick_actions(user_id);
CREATE INDEX idx_user_quick_actions_tenant ON user_quick_actions(tenant_id);
CREATE INDEX idx_user_quick_actions_action ON user_quick_actions(action_id);
CREATE INDEX idx_user_quick_actions_order ON user_quick_actions(display_order);

-- Action usage statistics
CREATE TABLE action_usage_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES quick_actions(id) ON DELETE CASCADE,
  usage_count INTEGER DEFAULT 1,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb,
  UNIQUE(user_id, action_id)
);

CREATE INDEX idx_action_stats_user ON action_usage_stats(user_id);
CREATE INDEX idx_action_stats_tenant ON action_usage_stats(tenant_id);
CREATE INDEX idx_action_stats_action ON action_usage_stats(action_id);
CREATE INDEX idx_action_stats_count ON action_usage_stats(usage_count DESC);
CREATE INDEX idx_action_stats_last_used ON action_usage_stats(last_used_at DESC);

-- Recent items table
CREATE TABLE user_recent_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL,
  item_id UUID NOT NULL,
  item_name TEXT NOT NULL,
  item_url TEXT NOT NULL,
  item_icon TEXT,
  item_metadata JSONB DEFAULT '{}'::jsonb,
  accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recent_items_user ON user_recent_items(user_id);
CREATE INDEX idx_recent_items_tenant ON user_recent_items(tenant_id);
CREATE INDEX idx_recent_items_type ON user_recent_items(item_type);
CREATE INDEX idx_recent_items_accessed ON user_recent_items(accessed_at DESC);

-- Keyboard shortcuts table
CREATE TABLE keyboard_shortcuts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES quick_actions(id) ON DELETE CASCADE,
  shortcut_key TEXT NOT NULL,
  modifiers TEXT[] DEFAULT ARRAY[]::TEXT[], -- ctrl, alt, shift, meta
  description TEXT,
  is_custom BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, shortcut_key, modifiers)
);

CREATE INDEX idx_keyboard_shortcuts_tenant ON keyboard_shortcuts(tenant_id);
CREATE INDEX idx_keyboard_shortcuts_action ON keyboard_shortcuts(action_id);
CREATE INDEX idx_keyboard_shortcuts_active ON keyboard_shortcuts(is_active);

-- Function to track action usage
CREATE OR REPLACE FUNCTION track_action_usage(
  p_user_id UUID,
  p_tenant_id UUID,
  p_action_id UUID
)
RETURNS void AS $$
BEGIN
  INSERT INTO action_usage_stats (
    user_id,
    tenant_id,
    action_id,
    usage_count,
    last_used_at
  ) VALUES (
    p_user_id,
    p_tenant_id,
    p_action_id,
    1,
    NOW()
  )
  ON CONFLICT (user_id, action_id) DO UPDATE SET
    usage_count = action_usage_stats.usage_count + 1,
    last_used_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add recent item
CREATE OR REPLACE FUNCTION add_recent_item(
  p_user_id UUID,
  p_tenant_id UUID,
  p_item_type TEXT,
  p_item_id UUID,
  p_item_name TEXT,
  p_item_url TEXT,
  p_item_icon TEXT DEFAULT NULL,
  p_item_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS void AS $$
BEGIN
  -- Insert new recent item
  INSERT INTO user_recent_items (
    user_id,
    tenant_id,
    item_type,
    item_id,
    item_name,
    item_url,
    item_icon,
    item_metadata
  ) VALUES (
    p_user_id,
    p_tenant_id,
    p_item_type,
    p_item_id,
    p_item_name,
    p_item_url,
    p_item_icon,
    p_item_metadata
  );

  -- Keep only last 50 recent items per user
  DELETE FROM user_recent_items
  WHERE id IN (
    SELECT id
    FROM user_recent_items
    WHERE user_id = p_user_id
    ORDER BY accessed_at DESC
    OFFSET 50
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user recommended actions
CREATE OR REPLACE FUNCTION get_recommended_actions(
  p_user_id UUID,
  p_tenant_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  action_id UUID,
  action_name TEXT,
  action_url TEXT,
  action_icon TEXT,
  usage_count INTEGER,
  recommendation_score DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  WITH user_stats AS (
    SELECT
      aus.action_id,
      qa.action_name,
      qa.action_url,
      qa.action_icon,
      aus.usage_count,
      aus.last_used_at,
      -- Calculate recommendation score based on:
      -- 40% usage frequency
      -- 30% recency
      -- 30% not already pinned
      (
        (aus.usage_count::DECIMAL / NULLIF((SELECT MAX(usage_count) FROM action_usage_stats WHERE user_id = p_user_id), 0)) * 0.4 +
        (EXTRACT(EPOCH FROM (NOW() - aus.last_used_at)) / NULLIF(EXTRACT(EPOCH FROM (NOW() - (SELECT MIN(last_used_at) FROM action_usage_stats WHERE user_id = p_user_id))), 0)) * 0.3 +
        (CASE WHEN uqa.id IS NULL THEN 0.3 ELSE 0 END)
      ) as score
    FROM action_usage_stats aus
    JOIN quick_actions qa ON qa.id = aus.action_id
    LEFT JOIN user_quick_actions uqa ON uqa.user_id = aus.user_id AND uqa.action_id = aus.action_id
    WHERE aus.user_id = p_user_id
      AND aus.tenant_id = p_tenant_id
      AND qa.is_active = true
  )
  SELECT
    us.action_id,
    us.action_name,
    us.action_url,
    us.action_icon,
    us.usage_count::INTEGER,
    us.score::DECIMAL
  FROM user_stats us
  ORDER BY us.score DESC, us.usage_count DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get frequently used actions
CREATE OR REPLACE FUNCTION get_frequently_used_actions(
  p_user_id UUID,
  p_tenant_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  action_id UUID,
  action_name TEXT,
  action_url TEXT,
  action_icon TEXT,
  usage_count INTEGER,
  last_used_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    qa.id,
    qa.action_name,
    qa.action_url,
    qa.action_icon,
    aus.usage_count::INTEGER,
    aus.last_used_at
  FROM action_usage_stats aus
  JOIN quick_actions qa ON qa.id = aus.action_id
  WHERE aus.user_id = p_user_id
    AND aus.tenant_id = p_tenant_id
    AND qa.is_active = true
  ORDER BY aus.usage_count DESC, aus.last_used_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE quick_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_quick_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE action_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recent_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE keyboard_shortcuts ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_quick_actions ON quick_actions
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
    )
    OR is_system_action = true
  );

CREATE POLICY users_own_quick_actions ON user_quick_actions
  FOR ALL USING (
    user_id = auth.uid()
  );

CREATE POLICY users_own_action_stats ON action_usage_stats
  FOR ALL USING (
    user_id = auth.uid()
  );

CREATE POLICY users_own_recent_items ON user_recent_items
  FOR ALL USING (
    user_id = auth.uid()
  );

CREATE POLICY tenant_keyboard_shortcuts ON keyboard_shortcuts
  FOR SELECT USING (
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
// src/types/quick-actions.ts

export interface QuickAction {
  id: string
  tenantId?: string
  actionKey: string
  actionName: string
  actionDescription?: string
  actionType: 'navigation' | 'modal' | 'api_call' | 'external_link' | 'command'
  actionUrl?: string
  actionIcon?: string
  actionColor?: string
  actionParams?: Record<string, any>
  requiredPermissions?: string[]
  isSystemAction: boolean
  isActive: boolean
  displayOrder: number
  metadata?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface UserQuickAction {
  id: string
  userId: string
  tenantId: string
  actionId: string
  isPinned: boolean
  customLabel?: string
  customIcon?: string
  displayOrder: number
  action?: QuickAction
  createdAt: string
  updatedAt: string
}

export interface ActionUsageStats {
  id: string
  userId: string
  tenantId: string
  actionId: string
  usageCount: number
  lastUsedAt: string
  metadata?: Record<string, any>
}

export interface RecentItem {
  id: string
  userId: string
  tenantId: string
  itemType: string
  itemId: string
  itemName: string
  itemUrl: string
  itemIcon?: string
  itemMetadata?: Record<string, any>
  accessedAt: string
}

export interface KeyboardShortcut {
  id: string
  tenantId?: string
  actionId: string
  shortcutKey: string
  modifiers: string[]
  description?: string
  isCustom: boolean
  isActive: boolean
  createdAt: string
}

export interface QuickActionsDashboard {
  pinnedActions: UserQuickAction[]
  frequentlyUsed: Array<QuickAction & { usageCount: number }>
  recommended: Array<QuickAction & { recommendationScore: number }>
  recentItems: RecentItem[]
  shortcuts: KeyboardShortcut[]
}
```

### API Routes

```typescript
// src/app/api/quick-actions/dashboard/route.ts

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
    .select('tenant_id')
    .eq('user_id', user.id)
    .single()

  try {
    // Get pinned actions
    const { data: pinnedActions } = await supabase
      .from('user_quick_actions')
      .select(`
        *,
        action:quick_actions (*)
      `)
      .eq('user_id', user.id)
      .eq('is_pinned', true)
      .order('display_order')

    // Get frequently used actions
    const { data: frequentlyUsed } = await supabase.rpc(
      'get_frequently_used_actions',
      {
        p_user_id: user.id,
        p_tenant_id: profile.tenant_id,
        p_limit: 10,
      }
    )

    // Get recommended actions
    const { data: recommended } = await supabase.rpc(
      'get_recommended_actions',
      {
        p_user_id: user.id,
        p_tenant_id: profile.tenant_id,
        p_limit: 10,
      }
    )

    // Get recent items
    const { data: recentItems } = await supabase
      .from('user_recent_items')
      .select('*')
      .eq('user_id', user.id)
      .order('accessed_at', { ascending: false })
      .limit(20)

    // Get keyboard shortcuts
    const { data: shortcuts } = await supabase
      .from('keyboard_shortcuts')
      .select(`
        *,
        action:quick_actions (*)
      `)
      .eq('tenant_id', profile.tenant_id)
      .eq('is_active', true)

    return NextResponse.json({
      pinnedActions: pinnedActions || [],
      frequentlyUsed: frequentlyUsed || [],
      recommended: recommended || [],
      recentItems: recentItems || [],
      shortcuts: shortcuts || [],
    })

  } catch (error) {
    console.error('Failed to fetch quick actions dashboard:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dashboard' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/quick-actions/[id]/use/route.ts

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
    const { error } = await supabase.rpc('track_action_usage', {
      p_user_id: user.id,
      p_tenant_id: profile.tenant_id,
      p_action_id: params.id,
    })

    if (error) throw error

    return NextResponse.json({ success: true })

  } catch (error) {
    console.error('Failed to track action usage:', error)
    return NextResponse.json(
      { error: 'Failed to track usage' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/quick-actions/pin/route.ts

export async function POST(request: Request) {
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
    const { actionId, isPinned } = body

    if (isPinned) {
      const { data, error } = await supabase
        .from('user_quick_actions')
        .insert({
          user_id: user.id,
          tenant_id: profile.tenant_id,
          action_id: actionId,
          is_pinned: true,
        })
        .select()
        .single()

      if (error) throw error

      return NextResponse.json({ action: data }, { status: 201 })
    } else {
      const { error } = await supabase
        .from('user_quick_actions')
        .delete()
        .eq('user_id', user.id)
        .eq('action_id', actionId)

      if (error) throw error

      return NextResponse.json({ success: true })
    }

  } catch (error) {
    console.error('Failed to toggle pin:', error)
    return NextResponse.json(
      { error: 'Failed to toggle pin' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/recent-items/route.ts

export async function POST(request: Request) {
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

    const { error } = await supabase.rpc('add_recent_item', {
      p_user_id: user.id,
      p_tenant_id: profile.tenant_id,
      p_item_type: body.itemType,
      p_item_id: body.itemId,
      p_item_name: body.itemName,
      p_item_url: body.itemUrl,
      p_item_icon: body.itemIcon,
      p_item_metadata: body.itemMetadata,
    })

    if (error) throw error

    return NextResponse.json({ success: true })

  } catch (error) {
    console.error('Failed to add recent item:', error)
    return NextResponse.json(
      { error: 'Failed to add recent item' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Quick Actions Dashboard Widget

```typescript
// src/components/quick-actions/quick-actions-dashboard.tsx

'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  Zap, Star, Clock, TrendingUp, 
  Pin, MoreVertical, Search 
} from 'lucide-react'
import { cn } from '@/lib/utils'

export function QuickActionsDashboard() {
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['quick-actions-dashboard'],
    queryFn: async () => {
      const res = await fetch('/api/quick-actions/dashboard')
      if (!res.ok) throw new Error('Failed to fetch dashboard')
      return res.json()
    },
  })

  const trackUsage = useMutation({
    mutationFn: async (actionId: string) => {
      const res = await fetch(`/api/quick-actions/${actionId}/use`, {
        method: 'POST',
      })
      if (!res.ok) throw new Error('Failed to track usage')
      return res.json()
    },
  })

  const togglePin = useMutation({
    mutationFn: async ({ actionId, isPinned }: { actionId: string; isPinned: boolean }) => {
      const res = await fetch('/api/quick-actions/pin', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ actionId, isPinned }),
      })
      if (!res.ok) throw new Error('Failed to toggle pin')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['quick-actions-dashboard'] })
    },
  })

  const handleActionClick = (action: any) => {
    trackUsage.mutate(action.id)
    
    if (action.actionType === 'navigation' && action.actionUrl) {
      window.location.href = action.actionUrl
    } else if (action.actionType === 'external_link' && action.actionUrl) {
      window.open(action.actionUrl, '_blank')
    }
    // Handle other action types
  }

  if (isLoading) {
    return <div>Loading...</div>
  }

  return (
    <div className="space-y-6">
      {/* Pinned Actions */}
      {data.pinnedActions?.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Pin className="h-5 w-5" />
              Pinned Actions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {data.pinnedActions.map((item: any) => (
                <Button
                  key={item.id}
                  variant="outline"
                  className="h-20 flex-col gap-2"
                  onClick={() => handleActionClick(item.action)}
                >
                  <div className={cn(
                    "h-8 w-8 rounded-full flex items-center justify-center",
                    item.action.actionColor || "bg-primary"
                  )}>
                    {item.action.actionIcon}
                  </div>
                  <span className="text-sm">{item.customLabel || item.action.actionName}</span>
                </Button>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Frequently Used */}
      {data.frequentlyUsed?.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              Frequently Used
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {data.frequentlyUsed.map((action: any) => (
                <div
                  key={action.action_id}
                  className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 cursor-pointer"
                  onClick={() => handleActionClick(action)}
                >
                  <div className="flex items-center gap-3">
                    <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                      {action.action_icon}
                    </div>
                    <div>
                      <p className="font-medium">{action.action_name}</p>
                      <p className="text-xs text-muted-foreground">
                        Used {action.usage_count} times
                      </p>
                    </div>
                  </div>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={(e) => {
                      e.stopPropagation()
                      togglePin.mutate({ actionId: action.action_id, isPinned: true })
                    }}
                  >
                    <Pin className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recent Items */}
      {data.recentItems?.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Recent Items
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {data.recentItems.slice(0, 10).map((item: any) => (
                <a
                  key={item.id}
                  href={item.item_url}
                  className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50"
                >
                  <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center">
                    {item.item_icon || <Zap className="h-4 w-4" />}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-sm">{item.item_name}</p>
                    <p className="text-xs text-muted-foreground capitalize">
                      {item.item_type}
                    </p>
                  </div>
                </a>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recommended Actions */}
      {data.recommended?.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Star className="h-5 w-5" />
              Recommended for You
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              {data.recommended.slice(0, 6).map((action: any) => (
                <Button
                  key={action.action_id}
                  variant="outline"
                  className="h-16 justify-start gap-3"
                  onClick={() => handleActionClick(action)}
                >
                  <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                    {action.action_icon}
                  </div>
                  <span className="text-sm">{action.action_name}</span>
                </Button>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Customizable quick action buttons
- [x] Recent items tracking
- [x] Frequently used actions
- [x] Contextual recommendations
- [x] Pin/unpin actions
- [x] Usage analytics
- [x] Keyboard shortcuts support
- [x] Role-based action visibility
- [x] Drag-and-drop customization
- [x] One-click access to common tasks
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
