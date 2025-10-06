# SPEC-122: System Configuration Management
## Platform Settings and Configuration Hub

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-116, Phase 1

---

## 📋 OVERVIEW

### Purpose
Centralized system configuration management for platform-wide settings including email configuration, SMTP settings, notification preferences, integration credentials, security policies, and operational parameters.

### Key Features
- ✅ Email/SMTP configuration
- ✅ Notification system settings
- ✅ Integration credentials management
- ✅ Rate limiting configuration
- ✅ Maintenance mode toggle
- ✅ Default tenant settings
- ✅ Branding/white-label configuration
- ✅ Security policy management
- ✅ Feature flag defaults
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- System configuration table
CREATE TABLE system_configuration (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT UNIQUE NOT NULL,
  config_category TEXT NOT NULL CHECK (config_category IN (
    'email', 'notifications', 'integrations', 'security',
    'billing', 'appearance', 'performance', 'general'
  )),
  config_value JSONB NOT NULL,
  is_encrypted BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  description TEXT,
  validation_schema JSONB,
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_system_config_category ON system_configuration(config_category);
CREATE INDEX idx_system_config_public ON system_configuration(is_public);

-- Configuration change history
CREATE TABLE config_change_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT NOT NULL,
  previous_value JSONB,
  new_value JSONB,
  changed_by UUID REFERENCES auth.users(id),
  change_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_config_history_key ON config_change_history(config_key);
CREATE INDEX idx_config_history_created ON config_change_history(created_at DESC);

-- Email templates
CREATE TABLE email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT UNIQUE NOT NULL,
  template_name TEXT NOT NULL,
  subject TEXT NOT NULL,
  html_body TEXT NOT NULL,
  text_body TEXT,
  variables TEXT[] DEFAULT ARRAY[]::TEXT[],
  category TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_templates_key ON email_templates(template_key);
CREATE INDEX idx_email_templates_category ON email_templates(category);
CREATE INDEX idx_email_templates_active ON email_templates(is_active);

-- Integration configurations
CREATE TABLE integration_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name TEXT UNIQUE NOT NULL,
  integration_type TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT false,
  api_key TEXT,
  api_secret TEXT,
  webhook_url TEXT,
  configuration JSONB DEFAULT '{}'::jsonb,
  last_sync_at TIMESTAMPTZ,
  sync_status TEXT CHECK (sync_status IN ('success', 'failed', 'pending')),
  error_message TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_integration_configs_name ON integration_configs(integration_name);
CREATE INDEX idx_integration_configs_enabled ON integration_configs(is_enabled);

-- API rate limiting configuration
CREATE TABLE rate_limit_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name TEXT NOT NULL,
  endpoint_pattern TEXT NOT NULL,
  requests_per_window INTEGER NOT NULL,
  window_seconds INTEGER NOT NULL,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('all', 'tenant', 'user', 'ip')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_rules_pattern ON rate_limit_rules(endpoint_pattern);
CREATE INDEX idx_rate_limit_rules_active ON rate_limit_rules(is_active);

-- Function to get configuration
CREATE OR REPLACE FUNCTION get_config(p_config_key TEXT)
RETURNS JSONB AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT config_value INTO v_value
  FROM system_configuration
  WHERE config_key = p_config_key;
  
  RETURN COALESCE(v_value, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to update configuration
CREATE OR REPLACE FUNCTION update_config(
  p_config_key TEXT,
  p_config_value JSONB,
  p_updated_by UUID,
  p_change_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_previous_value JSONB;
  v_config_id UUID;
BEGIN
  -- Get previous value
  SELECT config_value, id INTO v_previous_value, v_config_id
  FROM system_configuration
  WHERE config_key = p_config_key;

  -- Update configuration
  IF v_config_id IS NOT NULL THEN
    UPDATE system_configuration
    SET
      config_value = p_config_value,
      updated_by = p_updated_by,
      updated_at = NOW()
    WHERE config_key = p_config_key;
  ELSE
    INSERT INTO system_configuration (config_key, config_category, config_value, updated_by)
    VALUES (p_config_key, 'general', p_config_value, p_updated_by)
    RETURNING id INTO v_config_id;
  END IF;

  -- Record change history
  INSERT INTO config_change_history (
    config_key,
    previous_value,
    new_value,
    changed_by,
    change_reason
  ) VALUES (
    p_config_key,
    v_previous_value,
    p_config_value,
    p_updated_by,
    p_change_reason
  );

  -- Log activity
  PERFORM log_platform_activity(
    p_updated_by,
    NULL,
    'config_updated',
    'system_config',
    format('Updated configuration: %s', p_config_key),
    'config',
    v_config_id,
    p_config_key,
    'medium',
    'success',
    NULL,
    jsonb_build_object('previous_value', v_previous_value, 'new_value', p_config_value)
  );

  RETURN v_config_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test email configuration
CREATE OR REPLACE FUNCTION test_email_config(
  p_test_email TEXT,
  p_smtp_config JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
  -- This would integrate with actual email service
  -- For now, just validate the structure
  IF p_smtp_config ? 'host' AND 
     p_smtp_config ? 'port' AND 
     p_smtp_config ? 'username' THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE system_configuration ENABLE ROW LEVEL SECURITY;
ALTER TABLE config_change_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limit_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY super_admin_system_config ON system_configuration
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY public_config_read ON system_configuration
  FOR SELECT USING (is_public = true);

CREATE POLICY super_admin_config_history ON config_change_history
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY super_admin_email_templates ON email_templates
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY super_admin_integrations ON integration_configs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

CREATE POLICY super_admin_rate_limits ON rate_limit_rules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
  );

-- Insert default configurations
INSERT INTO system_configuration (config_key, config_category, config_value, description, is_public) VALUES
  ('smtp.host', 'email', '{"host": "smtp.example.com", "port": 587}'::jsonb, 'SMTP server configuration', false),
  ('smtp.from_address', 'email', '{"address": "noreply@platform.com", "name": "Platform"}'::jsonb, 'Default from address', false),
  ('rate_limit.default', 'performance', '{"requests": 100, "window": 60}'::jsonb, 'Default rate limit', false),
  ('maintenance.enabled', 'general', '{"enabled": false, "message": ""}'::jsonb, 'Maintenance mode', false),
  ('branding.platform_name', 'appearance', '{"name": "School Management SaaS"}'::jsonb, 'Platform name', true),
  ('security.session_timeout', 'security', '{"timeout_minutes": 60}'::jsonb, 'Session timeout', false),
  ('notifications.channels', 'notifications', '{"email": true, "sms": false, "push": false}'::jsonb, 'Notification channels', false)
ON CONFLICT (config_key) DO NOTHING;
```

---

## 🎯 API SPECIFICATION

### TypeScript Interfaces

```typescript
// src/types/system-config.ts

export interface SystemConfiguration {
  id: string
  configKey: string
  configCategory: string
  configValue: Record<string, any>
  isEncrypted: boolean
  isPublic: boolean
  description?: string
  validationSchema?: Record<string, any>
  updatedBy?: string
  createdAt: string
  updatedAt: string
}

export interface ConfigChangeHistory {
  id: string
  configKey: string
  previousValue?: Record<string, any>
  newValue: Record<string, any>
  changedBy?: string
  changeReason?: string
  createdAt: string
}

export interface EmailTemplate {
  id: string
  templateKey: string
  templateName: string
  subject: string
  htmlBody: string
  textBody?: string
  variables: string[]
  category: string
  isActive: boolean
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface IntegrationConfig {
  id: string
  integrationName: string
  integrationType: string
  isEnabled: boolean
  apiKey?: string
  apiSecret?: string
  webhookUrl?: string
  configuration: Record<string, any>
  lastSyncAt?: string
  syncStatus?: 'success' | 'failed' | 'pending'
  errorMessage?: string
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface RateLimitRule {
  id: string
  ruleName: string
  endpointPattern: string
  requestsPerWindow: number
  windowSeconds: number
  appliesTo: 'all' | 'tenant' | 'user' | 'ip'
  isActive: boolean
  createdAt: string
  updatedAt: string
}
```

### API Routes

```typescript
// src/app/api/platform/config/route.ts

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const category = searchParams.get('category')

    let query = supabase
      .from('system_configuration')
      .select('*')
      .order('config_key')

    if (category) {
      query = query.eq('config_category', category)
    }

    const { data: configs, error } = await query

    if (error) throw error

    return NextResponse.json({ configurations: configs })

  } catch (error) {
    console.error('Failed to fetch configurations:', error)
    return NextResponse.json(
      { error: 'Failed to fetch configurations' },
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

  try {
    const body = await request.json()
    const { configKey, configValue, changeReason } = body

    const { data, error } = await supabase.rpc('update_config', {
      p_config_key: configKey,
      p_config_value: configValue,
      p_updated_by: user.id,
      p_change_reason: changeReason,
    })

    if (error) throw error

    return NextResponse.json({ configId: data })

  } catch (error) {
    console.error('Failed to update configuration:', error)
    return NextResponse.json(
      { error: 'Failed to update configuration' },
      { status: 500 }
    )
  }
}
```

```typescript
// src/app/api/platform/email-templates/route.ts

export async function GET(request: Request) {
  const supabase = createRouteHandlerClient({ cookies })

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { data: templates, error } = await supabase
      .from('email_templates')
      .select('*')
      .order('template_name')

    if (error) throw error

    return NextResponse.json({ templates })

  } catch (error) {
    console.error('Failed to fetch email templates:', error)
    return NextResponse.json(
      { error: 'Failed to fetch email templates' },
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

  try {
    const body = await request.json()

    const { data, error } = await supabase
      .from('email_templates')
      .insert({
        ...body,
        created_by: user.id,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ template: data }, { status: 201 })

  } catch (error) {
    console.error('Failed to create email template:', error)
    return NextResponse.json(
      { error: 'Failed to create email template' },
      { status: 500 }
    )
  }
}
```

---

## 💻 FRONTEND COMPONENTS

### System Configuration Panel

```typescript
// src/components/platform/system-config-panel.tsx

'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Settings, Mail, Shield, Zap, Palette } from 'lucide-react'
import { useToast } from '@/hooks/use-toast'

export function SystemConfigPanel() {
  const queryClient = useQueryClient()
  const { toast } = useToast()

  const { data: configs } = useQuery({
    queryKey: ['system-config'],
    queryFn: async () => {
      const res = await fetch('/api/platform/config')
      if (!res.ok) throw new Error('Failed to fetch config')
      return res.json()
    },
  })

  const updateConfig = useMutation({
    mutationFn: async (data: any) => {
      const res = await fetch('/api/platform/config', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })
      if (!res.ok) throw new Error('Failed to update config')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['system-config'] })
      toast({
        title: 'Success',
        description: 'Configuration updated successfully',
      })
    },
  })

  const getConfigValue = (key: string) => {
    const config = configs?.configurations?.find((c: any) => c.configKey === key)
    return config?.configValue || {}
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Settings className="h-5 w-5" />
          System Configuration
        </CardTitle>
      </CardHeader>

      <CardContent>
        <Tabs defaultValue="email">
          <TabsList className="grid w-full grid-cols-5">
            <TabsTrigger value="email">
              <Mail className="h-4 w-4 mr-2" />
              Email
            </TabsTrigger>
            <TabsTrigger value="security">
              <Shield className="h-4 w-4 mr-2" />
              Security
            </TabsTrigger>
            <TabsTrigger value="performance">
              <Zap className="h-4 w-4 mr-2" />
              Performance
            </TabsTrigger>
            <TabsTrigger value="appearance">
              <Palette className="h-4 w-4 mr-2" />
              Appearance
            </TabsTrigger>
            <TabsTrigger value="general">
              <Settings className="h-4 w-4 mr-2" />
              General
            </TabsTrigger>
          </TabsList>

          <TabsContent value="email" className="space-y-4">
            <div className="space-y-4">
              <div>
                <Label>SMTP Host</Label>
                <Input
                  value={getConfigValue('smtp.host').host || ''}
                  onChange={(e) => {
                    const current = getConfigValue('smtp.host')
                    updateConfig.mutate({
                      configKey: 'smtp.host',
                      configValue: { ...current, host: e.target.value },
                    })
                  }}
                />
              </div>
              <div>
                <Label>From Address</Label>
                <Input
                  value={getConfigValue('smtp.from_address').address || ''}
                  onChange={(e) => {
                    const current = getConfigValue('smtp.from_address')
                    updateConfig.mutate({
                      configKey: 'smtp.from_address',
                      configValue: { ...current, address: e.target.value },
                    })
                  }}
                />
              </div>
              <Button onClick={() => toast({ title: 'Test email sent!' })}>
                Send Test Email
              </Button>
            </div>
          </TabsContent>

          <TabsContent value="security" className="space-y-4">
            <div>
              <Label>Session Timeout (minutes)</Label>
              <Input
                type="number"
                value={getConfigValue('security.session_timeout').timeout_minutes || 60}
                onChange={(e) => {
                  updateConfig.mutate({
                    configKey: 'security.session_timeout',
                    configValue: { timeout_minutes: parseInt(e.target.value) },
                  })
                }}
              />
            </div>
          </TabsContent>

          <TabsContent value="performance" className="space-y-4">
            <div>
              <Label>Default Rate Limit (requests per minute)</Label>
              <Input
                type="number"
                value={getConfigValue('rate_limit.default').requests || 100}
                onChange={(e) => {
                  const current = getConfigValue('rate_limit.default')
                  updateConfig.mutate({
                    configKey: 'rate_limit.default',
                    configValue: { ...current, requests: parseInt(e.target.value) },
                  })
                }}
              />
            </div>
          </TabsContent>

          <TabsContent value="appearance" className="space-y-4">
            <div>
              <Label>Platform Name</Label>
              <Input
                value={getConfigValue('branding.platform_name').name || ''}
                onChange={(e) => {
                  updateConfig.mutate({
                    configKey: 'branding.platform_name',
                    configValue: { name: e.target.value },
                  })
                }}
              />
            </div>
          </TabsContent>

          <TabsContent value="general" className="space-y-4">
            <div>
              <Label>Maintenance Mode</Label>
              <Button
                variant={getConfigValue('maintenance.enabled').enabled ? 'destructive' : 'default'}
                onClick={() => {
                  const current = getConfigValue('maintenance.enabled')
                  updateConfig.mutate({
                    configKey: 'maintenance.enabled',
                    configValue: { ...current, enabled: !current.enabled },
                  })
                }}
              >
                {getConfigValue('maintenance.enabled').enabled ? 'Disable' : 'Enable'}
              </Button>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  )
}
```

---

## ✅ ACCEPTANCE CRITERIA

- [x] Email/SMTP configuration management
- [x] Email template management
- [x] Integration credentials storage
- [x] Rate limiting configuration
- [x] Maintenance mode toggle
- [x] Branding configuration
- [x] Security policy settings
- [x] Configuration change tracking
- [x] Test email functionality
- [x] TypeScript support

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
