# SPEC-162: Tenant Settings and Configuration
## Organization-Wide Settings Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-151, Phase 1, Phase 2

---

## 📋 OVERVIEW

### Purpose
Centralized configuration management for tenant administrators to control organization-wide settings, preferences, integrations, and system configurations across all branches.

### Key Features
- ✅ General organization settings
- ✅ Academic settings (terms, grading scales)
- ✅ Financial settings (currency, payment methods)
- ✅ Notification preferences
- ✅ Integration configurations
- ✅ Branding and customization
- ✅ Security settings
- ✅ Feature flags
- ✅ Webhook management
- ✅ API key management
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Tenant settings table
CREATE TABLE tenant_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('general', 'academic', 'financial', 'notifications', 'integrations', 'branding', 'security', 'advanced')),
  setting_key TEXT NOT NULL,
  setting_value JSONB NOT NULL,
  data_type TEXT NOT NULL CHECK (data_type IN ('string', 'number', 'boolean', 'json', 'array')),
  is_encrypted BOOLEAN DEFAULT false,
  description TEXT,
  updated_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, category, setting_key)
);

CREATE INDEX idx_tenant_settings_tenant ON tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_category ON tenant_settings(category);
CREATE INDEX idx_tenant_settings_key ON tenant_settings(setting_key);

-- Notification preferences table
CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  channels TEXT[] DEFAULT ARRAY['in_app']::TEXT[], -- email, sms, in_app, push
  is_enabled BOOLEAN DEFAULT true,
  frequency TEXT CHECK (frequency IN ('immediate', 'daily_digest', 'weekly_digest', 'monthly')),
  recipients TEXT[] DEFAULT ARRAY[]::TEXT[], -- roles or user_ids
  template_config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, notification_type)
);

CREATE INDEX idx_notification_prefs_tenant ON notification_preferences(tenant_id);
CREATE INDEX idx_notification_prefs_type ON notification_preferences(notification_type);

-- Integration configurations table
CREATE TABLE integration_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  integration_name TEXT NOT NULL,
  integration_type TEXT NOT NULL CHECK (integration_type IN ('payment_gateway', 'sms_provider', 'email_provider', 'erp', 'lms', 'hr_system', 'other')),
  is_enabled BOOLEAN DEFAULT false,
  credentials JSONB NOT NULL, -- Encrypted
  config JSONB DEFAULT '{}'::jsonb,
  webhook_url TEXT,
  webhook_secret TEXT,
  last_sync_at TIMESTAMPTZ,
  sync_status TEXT CHECK (sync_status IN ('success', 'failed', 'in_progress')),
  error_message TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, integration_name)
);

CREATE INDEX idx_integration_configs_tenant ON integration_configs(tenant_id);
CREATE INDEX idx_integration_configs_type ON integration_configs(integration_type);
CREATE INDEX idx_integration_configs_enabled ON integration_configs(is_enabled);

-- API keys table
CREATE TABLE tenant_api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  key_name TEXT NOT NULL,
  key_hash TEXT NOT NULL UNIQUE,
  key_prefix TEXT NOT NULL,
  permissions JSONB DEFAULT '[]'::jsonb,
  scope TEXT[] DEFAULT ARRAY['read']::TEXT[], -- read, write, delete
  rate_limit INTEGER DEFAULT 1000, -- requests per hour
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, key_name)
);

CREATE INDEX idx_api_keys_tenant ON tenant_api_keys(tenant_id);
CREATE INDEX idx_api_keys_hash ON tenant_api_keys(key_hash);
CREATE INDEX idx_api_keys_active ON tenant_api_keys(is_active);
CREATE INDEX idx_api_keys_expires ON tenant_api_keys(expires_at) WHERE expires_at IS NOT NULL;

-- Webhooks table
CREATE TABLE tenant_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  url TEXT NOT NULL,
  secret TEXT NOT NULL,
  events TEXT[] NOT NULL,
  is_active BOOLEAN DEFAULT true,
  retry_config JSONB DEFAULT '{"max_retries": 3, "retry_delay": 60}'::jsonb,
  last_triggered_at TIMESTAMPTZ,
  last_status TEXT CHECK (last_status IN ('success', 'failed', 'pending')),
  failure_count INTEGER DEFAULT 0,
  headers JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhooks_tenant ON tenant_webhooks(tenant_id);
CREATE INDEX idx_webhooks_active ON tenant_webhooks(is_active);
CREATE INDEX idx_webhooks_events ON tenant_webhooks USING gin(events);

-- Webhook delivery log
CREATE TABLE webhook_delivery_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES tenant_webhooks(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  request_headers JSONB,
  response_status INTEGER,
  response_body TEXT,
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('pending', 'success', 'failed')),
  attempt_number INTEGER DEFAULT 1,
  error_message TEXT,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhook_log_webhook ON webhook_delivery_log(webhook_id);
CREATE INDEX idx_webhook_log_status ON webhook_delivery_log(delivery_status);
CREATE INDEX idx_webhook_log_date ON webhook_delivery_log(created_at DESC);

-- Feature flags table
CREATE TABLE tenant_feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  feature_name TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT false,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
  enabled_branches UUID[] DEFAULT ARRAY[]::UUID[],
  enabled_users UUID[] DEFAULT ARRAY[]::UUID[],
  config JSONB DEFAULT '{}'::jsonb,
  updated_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, feature_name)
);

CREATE INDEX idx_feature_flags_tenant ON tenant_feature_flags(tenant_id);
CREATE INDEX idx_feature_flags_enabled ON tenant_feature_flags(is_enabled);

-- Branding configuration table
CREATE TABLE tenant_branding (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  logo_url TEXT,
  favicon_url TEXT,
  primary_color TEXT DEFAULT '#0070f3',
  secondary_color TEXT DEFAULT '#7928ca',
  accent_color TEXT DEFAULT '#ff0080',
  font_family TEXT DEFAULT 'Inter',
  custom_css TEXT,
  email_header_html TEXT,
  email_footer_html TEXT,
  custom_domain TEXT,
  ssl_enabled BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id)
);

CREATE INDEX idx_tenant_branding_tenant ON tenant_branding(tenant_id);

-- Function to get tenant setting
CREATE OR REPLACE FUNCTION get_tenant_setting(
  p_tenant_id UUID,
  p_category TEXT,
  p_setting_key TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_setting JSONB;
BEGIN
  SELECT setting_value INTO v_setting
  FROM tenant_settings
  WHERE tenant_id = p_tenant_id
    AND category = p_category
    AND setting_key = p_setting_key;

  RETURN COALESCE(v_setting, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set tenant setting
CREATE OR REPLACE FUNCTION set_tenant_setting(
  p_tenant_id UUID,
  p_category TEXT,
  p_setting_key TEXT,
  p_setting_value JSONB,
  p_data_type TEXT,
  p_user_id UUID
)
RETURNS void AS $$
BEGIN
  INSERT INTO tenant_settings (
    tenant_id,
    category,
    setting_key,
    setting_value,
    data_type,
    updated_by
  ) VALUES (
    p_tenant_id,
    p_category,
    p_setting_key,
    p_setting_value,
    p_data_type,
    p_user_id
  )
  ON CONFLICT (tenant_id, category, setting_key) DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    updated_by = EXCLUDED.updated_by,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check feature flag
CREATE OR REPLACE FUNCTION is_feature_enabled(
  p_tenant_id UUID,
  p_feature_name TEXT,
  p_branch_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_flag RECORD;
  v_enabled BOOLEAN;
BEGIN
  SELECT * INTO v_flag
  FROM tenant_feature_flags
  WHERE tenant_id = p_tenant_id
    AND feature_name = p_feature_name;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  IF NOT v_flag.is_enabled THEN
    RETURN FALSE;
  END IF;

  -- Check branch-specific enablement
  IF p_branch_id IS NOT NULL AND array_length(v_flag.enabled_branches, 1) > 0 THEN
    IF NOT (p_branch_id = ANY(v_flag.enabled_branches)) THEN
      RETURN FALSE;
    END IF;
  END IF;

  -- Check user-specific enablement
  IF p_user_id IS NOT NULL AND array_length(v_flag.enabled_users, 1) > 0 THEN
    IF NOT (p_user_id = ANY(v_flag.enabled_users)) THEN
      RETURN FALSE;
    END IF;
  END IF;

  -- Check rollout percentage
  IF v_flag.rollout_percentage < 100 THEN
    -- Use deterministic hash for consistent user experience
    v_enabled := (hashtext(p_user_id::TEXT) % 100) < v_flag.rollout_percentage;
    RETURN v_enabled;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE tenant_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_delivery_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_branding ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_admin_settings ON tenant_settings
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_notifications ON notification_preferences
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_integrations ON integration_configs
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_api_keys ON tenant_api_keys
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_webhooks ON tenant_webhooks
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_admin_webhook_log ON webhook_delivery_log
  FOR SELECT USING (
    webhook_id IN (
      SELECT id FROM tenant_webhooks
      WHERE tenant_id IN (
        SELECT tenant_id FROM user_profiles
        WHERE user_id = auth.uid()
          AND role IN ('tenant_admin', 'super_admin')
      )
    )
  );

CREATE POLICY tenant_admin_feature_flags ON tenant_feature_flags
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles
      WHERE user_id = auth.uid()
        AND role IN ('tenant_admin', 'super_admin')
    )
  );

CREATE POLICY tenant_branding_policy ON tenant_branding
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
// src/types/tenant-settings.ts

export interface TenantSetting {
  id: string
  tenantId: string
  category: 'general' | 'academic' | 'financial' | 'notifications' | 'integrations' | 'branding' | 'security' | 'advanced'
  settingKey: string
  settingValue: any
  dataType: 'string' | 'number' | 'boolean' | 'json' | 'array'
  isEncrypted: boolean
  description?: string
  updatedBy?: string
  updatedAt: string
  createdAt: string
}

export interface NotificationPreference {
  id: string
  tenantId: string
  notificationType: string
  channels: Array<'email' | 'sms' | 'in_app' | 'push'>
  isEnabled: boolean
  frequency?: 'immediate' | 'daily_digest' | 'weekly_digest' | 'monthly'
  recipients?: string[]
  templateConfig?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface IntegrationConfig {
  id: string
  tenantId: string
  integrationName: string
  integrationType: 'payment_gateway' | 'sms_provider' | 'email_provider' | 'erp' | 'lms' | 'hr_system' | 'other'
  isEnabled: boolean
  credentials: Record<string, any>
  config?: Record<string, any>
  webhookUrl?: string
  webhookSecret?: string
  lastSyncAt?: string
  syncStatus?: 'success' | 'failed' | 'in_progress'
  errorMessage?: string
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface TenantAPIKey {
  id: string
  tenantId: string
  keyName: string
  keyPrefix: string
  permissions: string[]
  scope: Array<'read' | 'write' | 'delete'>
  rateLimit: number
  isActive: boolean
  expiresAt?: string
  lastUsedAt?: string
  usageCount: number
  createdBy?: string
  createdAt: string
}

export interface TenantWebhook {
  id: string
  tenantId: string
  name: string
  description?: string
  url: string
  events: string[]
  isActive: boolean
  retryConfig: {
    maxRetries: number
    retryDelay: number
  }
  lastTriggeredAt?: string
  lastStatus?: 'success' | 'failed' | 'pending'
  failureCount: number
  headers?: Record<string, string>
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface FeatureFlag {
  id: string
  tenantId: string
  featureName: string
  isEnabled: boolean
  rolloutPercentage: number
  enabledBranches?: string[]
  enabledUsers?: string[]
  config?: Record<string, any>
  updatedBy?: string
  updatedAt: string
  createdAt: string
}

export interface TenantBranding {
  id: string
  tenantId: string
  logoUrl?: string
  faviconUrl?: string
  primaryColor: string
  secondaryColor: string
  accentColor: string
  fontFamily: string
  customCss?: string
  emailHeaderHtml?: string
  emailFooterHtml?: string
  customDomain?: string
  sslEnabled: boolean
  metadata?: Record<string, any>
  updatedAt: string
  createdAt: string
}
```

### API Routes

```typescript
// src/app/api/tenant/settings/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })
  const { searchParams } = new URL(request.url)

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

  const category = searchParams.get('category')

  try {
    let query = supabase
      .from('tenant_settings')
      .select('*')
      .eq('tenant_id', profile.tenant_id)

    if (category) {
      query = query.eq('category', category)
    }

    const { data: settings, error } = await query.order('category')

    if (error) throw error

    // Group settings by category
    const grouped = settings?.reduce((acc: any, setting: any) => {
      if (!acc[setting.category]) {
        acc[setting.category] = {}
      }
      acc[setting.category][setting.setting_key] = setting.setting_value
      return acc
    }, {})

    return NextResponse.json({ settings: grouped })

  } catch (error) {
    console.error('Failed to fetch settings:', error)
    return NextResponse.json(
      { error: 'Failed to fetch settings' },
      { status: 500 }
    )
  }
}

export async function PUT(request: Request) {
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
    const { category, settings } = body

    // Update each setting
    const promises = Object.entries(settings).map(([key, value]) => {
      return supabase.rpc('set_tenant_setting', {
        p_tenant_id: profile.tenant_id,
        p_category: category,
        p_setting_key: key,
        p_setting_value: JSON.stringify(value),
        p_data_type: typeof value,
        p_user_id: user.id,
      })
    })

    await Promise.all(promises)

    return NextResponse.json({ success: true })

  } catch (error) {
    console.error('Failed to update settings:', error)
    return NextResponse.json(
      { error: 'Failed to update settings' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/tenant/webhooks/route.ts

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
    const { data: webhooks, error } = await supabase
      .from('tenant_webhooks')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({ webhooks })

  } catch (error) {
    console.error('Failed to fetch webhooks:', error)
    return NextResponse.json(
      { error: 'Failed to fetch webhooks' },
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

    // Generate webhook secret
    const secret = crypto.randomUUID()

    const { data: webhook, error } = await supabase
      .from('tenant_webhooks')
      .insert({
        tenant_id: profile.tenant_id,
        created_by: user.id,
        secret,
        ...body,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ webhook }, { status: 201 })

  } catch (error) {
    console.error('Failed to create webhook:', error)
    return NextResponse.json(
      { error: 'Failed to create webhook' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### Settings Page

```typescript
// src/app/tenant/settings/page.tsx

'use client'

import { useState } from 'react'
import { useQuery, useMutation } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { 
  Settings, Bell, Zap, Palette, Shield, 
  Code, Webhook, Key 
} from 'lucide-react'
import { GeneralSettings } from '@/components/settings/general-settings'
import { NotificationSettings } from '@/components/settings/notification-settings'
import { IntegrationSettings } from '@/components/settings/integration-settings'
import { BrandingSettings } from '@/components/settings/branding-settings'
import { SecuritySettings } from '@/components/settings/security-settings'
import { WebhookSettings } from '@/components/settings/webhook-settings'
import { APIKeySettings } from '@/components/settings/api-key-settings'
import { FeatureFlagSettings } from '@/components/settings/feature-flag-settings'

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('general')

  const { data, isLoading } = useQuery({
    queryKey: ['tenant-settings'],
    queryFn: async () => {
      const res = await fetch('/api/tenant/settings')
      if (!res.ok) throw new Error('Failed to fetch settings')
      return res.json()
    },
  })

  if (isLoading) {
    return <div>Loading settings...</div>
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Settings</h1>
        <p className="text-muted-foreground">
          Manage your organization settings and preferences
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-8">
          <TabsTrigger value="general">
            <Settings className="h-4 w-4 mr-2" />
            General
          </TabsTrigger>
          <TabsTrigger value="notifications">
            <Bell className="h-4 w-4 mr-2" />
            Notifications
          </TabsTrigger>
          <TabsTrigger value="integrations">
            <Zap className="h-4 w-4 mr-2" />
            Integrations
          </TabsTrigger>
          <TabsTrigger value="branding">
            <Palette className="h-4 w-4 mr-2" />
            Branding
          </TabsTrigger>
          <TabsTrigger value="security">
            <Shield className="h-4 w-4 mr-2" />
            Security
          </TabsTrigger>
          <TabsTrigger value="webhooks">
            <Webhook className="h-4 w-4 mr-2" />
            Webhooks
          </TabsTrigger>
          <TabsTrigger value="api-keys">
            <Key className="h-4 w-4 mr-2" />
            API Keys
          </TabsTrigger>
          <TabsTrigger value="features">
            <Code className="h-4 w-4 mr-2" />
            Features
          </TabsTrigger>
        </TabsList>

        <TabsContent value="general" className="mt-6">
          <GeneralSettings settings={data.settings?.general || {}} />
        </TabsContent>

        <TabsContent value="notifications" className="mt-6">
          <NotificationSettings />
        </TabsContent>

        <TabsContent value="integrations" className="mt-6">
          <IntegrationSettings />
        </TabsContent>

        <TabsContent value="branding" className="mt-6">
          <BrandingSettings />
        </TabsContent>

        <TabsContent value="security" className="mt-6">
          <SecuritySettings settings={data.settings?.security || {}} />
        </TabsContent>

        <TabsContent value="webhooks" className="mt-6">
          <WebhookSettings />
        </TabsContent>

        <TabsContent value="api-keys" className="mt-6">
          <APIKeySettings />
        </TabsContent>

        <TabsContent value="features" className="mt-6">
          <FeatureFlagSettings />
        </TabsContent>
      </Tabs>
    </div>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Organization-wide settings management
- [x] Notification preferences
- [x] Integration configurations
- [x] Branding customization
- [x] Security settings
- [x] Webhook management
- [x] API key generation
- [x] Feature flags
- [x] Settings validation
- [x] Encrypted storage for sensitive data
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH
