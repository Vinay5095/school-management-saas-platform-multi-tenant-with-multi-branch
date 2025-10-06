# SPEC-128: Email Templates Management
## Platform Email Template System and Communication Management

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-116, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive email template management system for creating, editing, and managing all platform email communications including transactional emails, notifications, and marketing campaigns.

### Key Features
- ✅ Visual email template editor
- ✅ Pre-built template library
- ✅ Template versioning system
- ✅ Multi-language support
- ✅ Dynamic content variables
- ✅ Email preview and testing
- ✅ Template categorization
- ✅ Automated email workflows
- ✅ Delivery tracking and analytics
- ✅ SMTP configuration management
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Email templates
CREATE TABLE email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name TEXT UNIQUE NOT NULL,
  template_key TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL CHECK (category IN (
    'authentication', 'billing', 'notifications', 'marketing', 
    'system', 'onboarding', 'support'
  )),
  subject TEXT NOT NULL,
  html_content TEXT NOT NULL,
  text_content TEXT,
  variables JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  is_system BOOLEAN DEFAULT FALSE,
  language_code TEXT DEFAULT 'en',
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Template versions for change tracking
CREATE TABLE email_template_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES email_templates(id),
  version_number INTEGER NOT NULL,
  subject TEXT NOT NULL,
  html_content TEXT NOT NULL,
  text_content TEXT,
  variables JSONB DEFAULT '[]'::jsonb,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(template_id, version_number)
);

-- Email sending configuration
CREATE TABLE email_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  configuration_name TEXT UNIQUE NOT NULL,
  provider TEXT NOT NULL CHECK (provider IN ('smtp', 'sendgrid', 'mailgun', 'ses')),
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Email sending logs
CREATE TABLE email_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES email_templates(id),
  recipient_email TEXT NOT NULL,
  recipient_name TEXT,
  subject TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
  provider_message_id TEXT,
  error_message TEXT,
  variables_used JSONB DEFAULT '{}'::jsonb,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  delivered_at TIMESTAMP WITH TIME ZONE,
  opened_at TIMESTAMP WITH TIME ZONE,
  clicked_at TIMESTAMP WITH TIME ZONE
);

-- Email template categories
CREATE TABLE email_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name TEXT UNIQUE NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- Template localization
CREATE TABLE email_template_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES email_templates(id),
  language_code TEXT NOT NULL,
  subject TEXT NOT NULL,
  html_content TEXT NOT NULL,
  text_content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(template_id, language_code)
);

-- Indexes
CREATE INDEX idx_email_templates_category ON email_templates(category);
CREATE INDEX idx_email_templates_active ON email_templates(is_active);
CREATE INDEX idx_email_logs_template_status ON email_logs(template_id, status);
CREATE INDEX idx_email_logs_recipient ON email_logs(recipient_email);
CREATE INDEX idx_email_logs_sent_at ON email_logs(sent_at);
```

---

## 🎨 UI COMPONENTS

### Email Templates Dashboard
```tsx
// components/admin/email/EmailTemplatesDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { EmailTemplateEditor } from './EmailTemplateEditor';
import { EmailPreview } from './EmailPreview';
import { EmailAnalytics } from './EmailAnalytics';
import { 
  Mail, 
  Plus, 
  Search, 
  Filter,
  Eye,
  Edit,
  Copy,
  Trash2,
  Send
} from 'lucide-react';

interface EmailTemplate {
  id: string;
  template_name: string;
  template_key: string;
  category: string;
  subject: string;
  is_active: boolean;
  is_system: boolean;
  language_code: string;
  created_at: string;
  updated_at: string;
}

export function EmailTemplatesDashboard() {
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTemplate, setSelectedTemplate] = useState<EmailTemplate | null>(null);
  const [showEditor, setShowEditor] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [filters, setFilters] = useState({
    category: '',
    search: '',
    language: 'en'
  });

  useEffect(() => {
    loadTemplates();
  }, [filters]);

  const loadTemplates = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filters.category) params.append('category', filters.category);
      if (filters.search) params.append('search', filters.search);
      if (filters.language) params.append('language', filters.language);
      
      const response = await fetch(`/api/admin/email/templates?${params}`);
      const data = await response.json();
      setTemplates(data.templates || []);
    } catch (error) {
      console.error('Failed to load email templates:', error);
    } finally {
      setLoading(false);
    }
  };

  const createNewTemplate = () => {
    setSelectedTemplate(null);
    setShowEditor(true);
  };

  const editTemplate = (template: EmailTemplate) => {
    setSelectedTemplate(template);
    setShowEditor(true);
  };

  const previewTemplate = (template: EmailTemplate) => {
    setSelectedTemplate(template);
    setShowPreview(true);
  };

  const duplicateTemplate = async (template: EmailTemplate) => {
    try {
      const response = await fetch('/api/admin/email/templates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...template,
          template_name: `${template.template_name} (Copy)`,
          template_key: `${template.template_key}_copy_${Date.now()}`,
          id: undefined
        })
      });
      
      if (response.ok) {
        loadTemplates();
      }
    } catch (error) {
      console.error('Failed to duplicate template:', error);
    }
  };

  const deleteTemplate = async (templateId: string) => {
    if (!confirm('Are you sure you want to delete this template?')) return;
    
    try {
      const response = await fetch(`/api/admin/email/templates/${templateId}`, {
        method: 'DELETE'
      });
      
      if (response.ok) {
        loadTemplates();
      }
    } catch (error) {
      console.error('Failed to delete template:', error);
    }
  };

  const getCategoryColor = (category: string) => {
    const colors = {
      'authentication': 'bg-blue-100 text-blue-800',
      'billing': 'bg-green-100 text-green-800',
      'notifications': 'bg-yellow-100 text-yellow-800',
      'marketing': 'bg-purple-100 text-purple-800',
      'system': 'bg-gray-100 text-gray-800',
      'onboarding': 'bg-indigo-100 text-indigo-800',
      'support': 'bg-orange-100 text-orange-800'
    };
    return colors[category as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  if (showEditor) {
    return (
      <EmailTemplateEditor
        template={selectedTemplate}
        onClose={() => {
          setShowEditor(false);
          setSelectedTemplate(null);
          loadTemplates();
        }}
      />
    );
  }

  if (showPreview && selectedTemplate) {
    return (
      <EmailPreview
        template={selectedTemplate}
        onClose={() => {
          setShowPreview(false);
          setSelectedTemplate(null);
        }}
      />
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Email Templates</h1>
          <p className="text-gray-600">Manage platform email templates and communications</p>
        </div>
        <Button onClick={createNewTemplate}>
          <Plus className="w-4 h-4 mr-2" />
          New Template
        </Button>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <Input
                placeholder="Search templates..."
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                className="pl-10"
              />
            </div>
            
            <Select value={filters.category} onValueChange={(value) => setFilters({ ...filters, category: value })}>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="All Categories" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">All Categories</SelectItem>
                <SelectItem value="authentication">Authentication</SelectItem>
                <SelectItem value="billing">Billing</SelectItem>
                <SelectItem value="notifications">Notifications</SelectItem>
                <SelectItem value="marketing">Marketing</SelectItem>
                <SelectItem value="system">System</SelectItem>
                <SelectItem value="onboarding">Onboarding</SelectItem>
                <SelectItem value="support">Support</SelectItem>
              </SelectContent>
            </Select>
            
            <Select value={filters.language} onValueChange={(value) => setFilters({ ...filters, language: value })}>
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="en">English</SelectItem>
                <SelectItem value="es">Spanish</SelectItem>
                <SelectItem value="fr">French</SelectItem>
                <SelectItem value="de">German</SelectItem>
              </SelectContent>
            </Select>
            
            <Button variant="outline" onClick={loadTemplates}>
              <Filter className="w-4 h-4 mr-2" />
              Refresh
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Templates Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-full text-center py-12">Loading templates...</div>
        ) : templates.length === 0 ? (
          <div className="col-span-full text-center py-12 text-gray-500">
            No templates found. Create your first template to get started.
          </div>
        ) : (
          templates.map((template) => (
            <Card key={template.id} className="hover:shadow-md transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-lg">{template.template_name}</CardTitle>
                    <CardDescription className="mt-1">
                      {template.template_key}
                    </CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    {template.is_system && (
                      <Badge variant="secondary" className="text-xs">System</Badge>
                    )}
                    <Badge 
                      variant={template.is_active ? "default" : "secondary"}
                      className="text-xs"
                    >
                      {template.is_active ? 'Active' : 'Inactive'}
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              
              <CardContent className="space-y-3">
                <div className="flex items-center gap-2">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getCategoryColor(template.category)}`}>
                    {template.category}
                  </span>
                  <span className="text-xs text-gray-500">
                    {template.language_code.toUpperCase()}
                  </span>
                </div>
                
                <div className="text-sm">
                  <div className="font-medium text-gray-700">Subject:</div>
                  <div className="text-gray-600 truncate">{template.subject}</div>
                </div>
                
                <div className="text-xs text-gray-500">
                  Updated: {new Date(template.updated_at).toLocaleDateString()}
                </div>
                
                <div className="flex items-center gap-2 pt-2 border-t">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => previewTemplate(template)}
                  >
                    <Eye className="w-3 h-3 mr-1" />
                    Preview
                  </Button>
                  
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => editTemplate(template)}
                    disabled={template.is_system}
                  >
                    <Edit className="w-3 h-3 mr-1" />
                    Edit
                  </Button>
                  
                  <div className="flex gap-1 ml-auto">
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => duplicateTemplate(template)}
                    >
                      <Copy className="w-3 h-3" />
                    </Button>
                    
                    {!template.is_system && (
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => deleteTemplate(template.id)}
                      >
                        <Trash2 className="w-3 h-3" />
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">{templates.length}</div>
            <p className="text-xs text-muted-foreground">Total Templates</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {templates.filter(t => t.is_active).length}
            </div>
            <p className="text-xs text-muted-foreground">Active Templates</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {new Set(templates.map(t => t.category)).size}
            </div>
            <p className="text-xs text-muted-foreground">Categories</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {new Set(templates.map(t => t.language_code)).size}
            </div>
            <p className="text-xs text-muted-foreground">Languages</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
```

### Email Template Editor
```tsx
// components/admin/email/EmailTemplateEditor.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { 
  Save, 
  X, 
  Eye, 
  Code, 
  Type,
  Plus,
  Minus
} from 'lucide-react';

interface EmailTemplate {
  id?: string;
  template_name: string;
  template_key: string;
  category: string;
  subject: string;
  html_content: string;
  text_content?: string;
  variables: string[];
  is_active: boolean;
  language_code: string;
}

interface EmailTemplateEditorProps {
  template: EmailTemplate | null;
  onClose: () => void;
}

export function EmailTemplateEditor({ template, onClose }: EmailTemplateEditorProps) {
  const [formData, setFormData] = useState<EmailTemplate>({
    template_name: '',
    template_key: '',
    category: 'notifications',
    subject: '',
    html_content: '',
    text_content: '',
    variables: [],
    is_active: true,
    language_code: 'en'
  });
  const [saving, setSaving] = useState(false);
  const [previewData, setPreviewData] = useState<Record<string, string>>({});
  const [newVariable, setNewVariable] = useState('');\n\n  useEffect(() => {\n    if (template) {\n      setFormData({\n        ...template,\n        variables: template.variables || []\n      });\n      \n      // Initialize preview data with sample values for variables\n      const sampleData: Record<string, string> = {};\n      (template.variables || []).forEach(variable => {\n        sampleData[variable] = `Sample ${variable}`;\n      });\n      setPreviewData(sampleData);\n    }\n  }, [template]);\n\n  const handleSave = async () => {\n    setSaving(true);\n    try {\n      const url = template \n        ? `/api/admin/email/templates/${template.id}`\n        : '/api/admin/email/templates';\n      \n      const method = template ? 'PUT' : 'POST';\n      \n      const response = await fetch(url, {\n        method,\n        headers: { 'Content-Type': 'application/json' },\n        body: JSON.stringify(formData)\n      });\n      \n      if (response.ok) {\n        onClose();\n      } else {\n        console.error('Failed to save template');\n      }\n    } catch (error) {\n      console.error('Error saving template:', error);\n    } finally {\n      setSaving(false);\n    }\n  };\n\n  const addVariable = () => {\n    if (newVariable && !formData.variables.includes(newVariable)) {\n      setFormData({\n        ...formData,\n        variables: [...formData.variables, newVariable]\n      });\n      setPreviewData({\n        ...previewData,\n        [newVariable]: `Sample ${newVariable}`\n      });\n      setNewVariable('');\n    }\n  };\n\n  const removeVariable = (variable: string) => {\n    setFormData({\n      ...formData,\n      variables: formData.variables.filter(v => v !== variable)\n    });\n    const newPreviewData = { ...previewData };\n    delete newPreviewData[variable];\n    setPreviewData(newPreviewData);\n  };\n\n  const renderPreview = (content: string) => {\n    let rendered = content;\n    Object.entries(previewData).forEach(([key, value]) => {\n      const regex = new RegExp(`{{\\\\s*${key}\\\\s*}}`, 'g');\n      rendered = rendered.replace(regex, value);\n    });\n    return rendered;\n  };\n\n  return (\n    <div className=\"space-y-6\">\n      {/* Header */}\n      <div className=\"flex items-center justify-between\">\n        <div>\n          <h1 className=\"text-3xl font-bold\">\n            {template ? 'Edit Template' : 'Create Template'}\n          </h1>\n          <p className=\"text-gray-600\">\n            {template ? `Editing: ${template.template_name}` : 'Create a new email template'}\n          </p>\n        </div>\n        <div className=\"flex gap-2\">\n          <Button variant=\"outline\" onClick={onClose}>\n            <X className=\"w-4 h-4 mr-2\" />\n            Cancel\n          </Button>\n          <Button onClick={handleSave} disabled={saving}>\n            <Save className=\"w-4 h-4 mr-2\" />\n            {saving ? 'Saving...' : 'Save Template'}\n          </Button>\n        </div>\n      </div>\n\n      <div className=\"grid grid-cols-1 lg:grid-cols-3 gap-6\">\n        {/* Template Form */}\n        <div className=\"lg:col-span-2 space-y-6\">\n          <Card>\n            <CardHeader>\n              <CardTitle>Template Details</CardTitle>\n            </CardHeader>\n            <CardContent className=\"space-y-4\">\n              <div className=\"grid grid-cols-2 gap-4\">\n                <div>\n                  <label className=\"text-sm font-medium\">Template Name</label>\n                  <Input\n                    value={formData.template_name}\n                    onChange={(e) => setFormData({ ...formData, template_name: e.target.value })}\n                    placeholder=\"Enter template name\"\n                  />\n                </div>\n                <div>\n                  <label className=\"text-sm font-medium\">Template Key</label>\n                  <Input\n                    value={formData.template_key}\n                    onChange={(e) => setFormData({ ...formData, template_key: e.target.value })}\n                    placeholder=\"unique_template_key\"\n                  />\n                </div>\n              </div>\n              \n              <div className=\"grid grid-cols-3 gap-4\">\n                <div>\n                  <label className=\"text-sm font-medium\">Category</label>\n                  <Select \n                    value={formData.category} \n                    onValueChange={(value) => setFormData({ ...formData, category: value })}\n                  >\n                    <SelectTrigger>\n                      <SelectValue />\n                    </SelectTrigger>\n                    <SelectContent>\n                      <SelectItem value=\"authentication\">Authentication</SelectItem>\n                      <SelectItem value=\"billing\">Billing</SelectItem>\n                      <SelectItem value=\"notifications\">Notifications</SelectItem>\n                      <SelectItem value=\"marketing\">Marketing</SelectItem>\n                      <SelectItem value=\"system\">System</SelectItem>\n                      <SelectItem value=\"onboarding\">Onboarding</SelectItem>\n                      <SelectItem value=\"support\">Support</SelectItem>\n                    </SelectContent>\n                  </Select>\n                </div>\n                \n                <div>\n                  <label className=\"text-sm font-medium\">Language</label>\n                  <Select \n                    value={formData.language_code} \n                    onValueChange={(value) => setFormData({ ...formData, language_code: value })}\n                  >\n                    <SelectTrigger>\n                      <SelectValue />\n                    </SelectTrigger>\n                    <SelectContent>\n                      <SelectItem value=\"en\">English</SelectItem>\n                      <SelectItem value=\"es\">Spanish</SelectItem>\n                      <SelectItem value=\"fr\">French</SelectItem>\n                      <SelectItem value=\"de\">German</SelectItem>\n                    </SelectContent>\n                  </Select>\n                </div>\n                \n                <div className=\"flex items-end\">\n                  <label className=\"flex items-center space-x-2\">\n                    <input\n                      type=\"checkbox\"\n                      checked={formData.is_active}\n                      onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}\n                      className=\"rounded\"\n                    />\n                    <span className=\"text-sm font-medium\">Active</span>\n                  </label>\n                </div>\n              </div>\n              \n              <div>\n                <label className=\"text-sm font-medium\">Subject Line</label>\n                <Input\n                  value={formData.subject}\n                  onChange={(e) => setFormData({ ...formData, subject: e.target.value })}\n                  placeholder=\"Enter email subject\"\n                />\n              </div>\n            </CardContent>\n          </Card>\n\n          {/* Content Editor */}\n          <Card>\n            <CardHeader>\n              <CardTitle>Email Content</CardTitle>\n            </CardHeader>\n            <CardContent>\n              <Tabs defaultValue=\"html\">\n                <TabsList>\n                  <TabsTrigger value=\"html\">\n                    <Code className=\"w-4 h-4 mr-2\" />\n                    HTML\n                  </TabsTrigger>\n                  <TabsTrigger value=\"text\">\n                    <Type className=\"w-4 h-4 mr-2\" />\n                    Plain Text\n                  </TabsTrigger>\n                </TabsList>\n                \n                <TabsContent value=\"html\" className=\"mt-4\">\n                  <Textarea\n                    value={formData.html_content}\n                    onChange={(e) => setFormData({ ...formData, html_content: e.target.value })}\n                    placeholder=\"Enter HTML content...\"\n                    className=\"min-h-[400px] font-mono text-sm\"\n                  />\n                </TabsContent>\n                \n                <TabsContent value=\"text\" className=\"mt-4\">\n                  <Textarea\n                    value={formData.text_content || ''}\n                    onChange={(e) => setFormData({ ...formData, text_content: e.target.value })}\n                    placeholder=\"Enter plain text content...\"\n                    className=\"min-h-[400px]\"\n                  />\n                </TabsContent>\n              </Tabs>\n            </CardContent>\n          </Card>\n        </div>\n\n        {/* Sidebar */}\n        <div className=\"space-y-6\">\n          {/* Variables */}\n          <Card>\n            <CardHeader>\n              <CardTitle className=\"text-lg\">Variables</CardTitle>\n            </CardHeader>\n            <CardContent className=\"space-y-4\">\n              <div className=\"flex gap-2\">\n                <Input\n                  value={newVariable}\n                  onChange={(e) => setNewVariable(e.target.value)}\n                  placeholder=\"Variable name\"\n                  onKeyPress={(e) => e.key === 'Enter' && addVariable()}\n                />\n                <Button size=\"sm\" onClick={addVariable}>\n                  <Plus className=\"w-4 h-4\" />\n                </Button>\n              </div>\n              \n              <div className=\"space-y-2\">\n                {formData.variables.map((variable) => (\n                  <div key={variable} className=\"flex items-center justify-between p-2 bg-gray-50 rounded\">\n                    <code className=\"text-sm\">{{{{ {variable} }}}}</code>\n                    <Button \n                      size=\"sm\" \n                      variant=\"ghost\" \n                      onClick={() => removeVariable(variable)}\n                    >\n                      <Minus className=\"w-3 h-3\" />\n                    </Button>\n                  </div>\n                ))}\n              </div>\n              \n              {formData.variables.length === 0 && (\n                <p className=\"text-sm text-gray-500\">No variables defined</p>\n              )}\n            </CardContent>\n          </Card>\n\n          {/* Preview Data */}\n          <Card>\n            <CardHeader>\n              <CardTitle className=\"text-lg\">Preview Data</CardTitle>\n            </CardHeader>\n            <CardContent className=\"space-y-3\">\n              {formData.variables.map((variable) => (\n                <div key={variable}>\n                  <label className=\"text-xs font-medium text-gray-700\">{variable}</label>\n                  <Input\n                    value={previewData[variable] || ''}\n                    onChange={(e) => setPreviewData({ \n                      ...previewData, \n                      [variable]: e.target.value \n                    })}\n                    placeholder={`Sample ${variable}`}\n                    className=\"text-sm\"\n                  />\n                </div>\n              ))}\n            </CardContent>\n          </Card>\n\n          {/* Quick Actions */}\n          <Card>\n            <CardHeader>\n              <CardTitle className=\"text-lg\">Quick Actions</CardTitle>\n            </CardHeader>\n            <CardContent className=\"space-y-2\">\n              <Button variant=\"outline\" className=\"w-full\" size=\"sm\">\n                <Eye className=\"w-4 h-4 mr-2\" />\n                Preview Email\n              </Button>\n              <Button variant=\"outline\" className=\"w-full\" size=\"sm\">\n                Send Test Email\n              </Button>\n            </CardContent>\n          </Card>\n        </div>\n      </div>\n    </div>\n  );\n}\n```\n\n---\n\n## 🔧 API ROUTES\n\n### Email Templates API\n```typescript\n// app/api/admin/email/templates/route.ts\nimport { NextRequest, NextResponse } from 'next/server';\nimport { createClient } from '@/lib/supabase/server';\nimport { requireSuperAdmin } from '@/lib/auth/require-roles';\n\nexport async function GET(request: NextRequest) {\n  try {\n    await requireSuperAdmin();\n    const supabase = createClient();\n\n    const { searchParams } = new URL(request.url);\n    const category = searchParams.get('category');\n    const search = searchParams.get('search');\n    const language = searchParams.get('language') || 'en';\n\n    let query = supabase\n      .from('email_templates')\n      .select('*')\n      .eq('language_code', language)\n      .order('created_at', { ascending: false });\n\n    if (category) {\n      query = query.eq('category', category);\n    }\n\n    if (search) {\n      query = query.or(`template_name.ilike.%${search}%,subject.ilike.%${search}%`);\n    }\n\n    const { data: templates, error } = await query;\n\n    if (error) {\n      console.error('Database error:', error);\n      return NextResponse.json({ error: 'Failed to fetch templates' }, { status: 500 });\n    }\n\n    return NextResponse.json({ templates: templates || [] });\n  } catch (error) {\n    console.error('Failed to fetch email templates:', error);\n    return NextResponse.json(\n      { error: 'Failed to fetch email templates' },\n      { status: 500 }\n    );\n  }\n}\n\nexport async function POST(request: NextRequest) {\n  try {\n    await requireSuperAdmin();\n    const supabase = createClient();\n    const user = await supabase.auth.getUser();\n    const body = await request.json();\n\n    // Check if template key is unique\n    const { data: existing } = await supabase\n      .from('email_templates')\n      .select('id')\n      .eq('template_key', body.template_key)\n      .single();\n\n    if (existing) {\n      return NextResponse.json(\n        { error: 'Template key already exists' },\n        { status: 400 }\n      );\n    }\n\n    const { data: template, error } = await supabase\n      .from('email_templates')\n      .insert({\n        ...body,\n        created_by: user.data.user?.id\n      })\n      .select()\n      .single();\n\n    if (error) {\n      console.error('Database error:', error);\n      return NextResponse.json({ error: 'Failed to create template' }, { status: 500 });\n    }\n\n    // Create initial version\n    await supabase\n      .from('email_template_versions')\n      .insert({\n        template_id: template.id,\n        version_number: 1,\n        subject: template.subject,\n        html_content: template.html_content,\n        text_content: template.text_content,\n        variables: template.variables,\n        created_by: user.data.user?.id\n      });\n\n    return NextResponse.json(template, { status: 201 });\n  } catch (error) {\n    console.error('Failed to create email template:', error);\n    return NextResponse.json(\n      { error: 'Failed to create email template' },\n      { status: 500 }\n    );\n  }\n}\n```\n\n### Email Sending API\n```typescript\n// app/api/admin/email/send/route.ts\nimport { NextRequest, NextResponse } from 'next/server';\nimport { createClient } from '@/lib/supabase/server';\nimport { requireSuperAdmin } from '@/lib/auth/require-roles';\nimport { sendTemplatedEmail } from '@/lib/email/sender';\n\nexport async function POST(request: NextRequest) {\n  try {\n    await requireSuperAdmin();\n    const body = await request.json();\n    const { templateKey, recipientEmail, recipientName, variables } = body;\n\n    const result = await sendTemplatedEmail({\n      templateKey,\n      recipientEmail,\n      recipientName,\n      variables\n    });\n\n    return NextResponse.json(result);\n  } catch (error) {\n    console.error('Failed to send email:', error);\n    return NextResponse.json(\n      { error: 'Failed to send email' },\n      { status: 500 }\n    );\n  }\n}\n```\n\n---\n\n## ⚙️ EMAIL UTILITIES\n\n### Email Sender Service\n```typescript\n// lib/email/sender.ts\nimport { createClient } from '@/lib/supabase/server';\nimport nodemailer from 'nodemailer';\n\ninterface EmailOptions {\n  templateKey: string;\n  recipientEmail: string;\n  recipientName?: string;\n  variables?: Record<string, string>;\n}\n\nexport async function sendTemplatedEmail(options: EmailOptions) {\n  const supabase = createClient();\n  \n  try {\n    // Get email template\n    const { data: template, error: templateError } = await supabase\n      .from('email_templates')\n      .select('*')\n      .eq('template_key', options.templateKey)\n      .eq('is_active', true)\n      .single();\n\n    if (templateError || !template) {\n      throw new Error(`Template not found: ${options.templateKey}`);\n    }\n\n    // Get email configuration\n    const { data: config, error: configError } = await supabase\n      .from('email_configurations')\n      .select('*')\n      .eq('is_default', true)\n      .eq('is_active', true)\n      .single();\n\n    if (configError || !config) {\n      throw new Error('No active email configuration found');\n    }\n\n    // Process template variables\n    const processedSubject = processTemplate(template.subject, options.variables || {});\n    const processedHtmlContent = processTemplate(template.html_content, options.variables || {});\n    const processedTextContent = template.text_content \n      ? processTemplate(template.text_content, options.variables || {})\n      : undefined;\n\n    // Create transporter based on configuration\n    const transporter = createTransporter(config);\n\n    // Send email\n    const result = await transporter.sendMail({\n      from: config.configuration.from || process.env.SMTP_FROM,\n      to: options.recipientEmail,\n      subject: processedSubject,\n      html: processedHtmlContent,\n      text: processedTextContent\n    });\n\n    // Log email sending\n    await supabase\n      .from('email_logs')\n      .insert({\n        template_id: template.id,\n        recipient_email: options.recipientEmail,\n        recipient_name: options.recipientName,\n        subject: processedSubject,\n        status: 'sent',\n        provider_message_id: result.messageId,\n        variables_used: options.variables || {}\n      });\n\n    return {\n      success: true,\n      messageId: result.messageId\n    };\n  } catch (error) {\n    console.error('Error sending email:', error);\n    \n    // Log failed email attempt\n    await supabase\n      .from('email_logs')\n      .insert({\n        template_id: null,\n        recipient_email: options.recipientEmail,\n        recipient_name: options.recipientName,\n        subject: 'Failed to send',\n        status: 'failed',\n        error_message: error.message,\n        variables_used: options.variables || {}\n      });\n\n    return {\n      success: false,\n      error: error.message\n    };\n  }\n}\n\nfunction processTemplate(template: string, variables: Record<string, string>): string {\n  let processed = template;\n  \n  Object.entries(variables).forEach(([key, value]) => {\n    const regex = new RegExp(`{{\\\\s*${key}\\\\s*}}`, 'g');\n    processed = processed.replace(regex, value);\n  });\n  \n  return processed;\n}\n\nfunction createTransporter(config: any) {\n  const configuration = config.configuration;\n  \n  switch (config.provider) {\n    case 'smtp':\n      return nodemailer.createTransporter({\n        host: configuration.host,\n        port: configuration.port,\n        secure: configuration.secure,\n        auth: {\n          user: configuration.username,\n          pass: configuration.password\n        }\n      });\n    \n    case 'sendgrid':\n      return nodemailer.createTransporter({\n        service: 'SendGrid',\n        auth: {\n          user: 'apikey',\n          pass: configuration.apiKey\n        }\n      });\n    \n    default:\n      throw new Error(`Unsupported email provider: ${config.provider}`);\n  }\n}\n```\n\n---\n\n## 📋 TESTING REQUIREMENTS\n\n### Email Templates Tests\n```typescript\n// __tests__/admin/email/EmailTemplatesDashboard.test.tsx\nimport { render, screen, fireEvent, waitFor } from '@testing-library/react';\nimport { EmailTemplatesDashboard } from '@/components/admin/email/EmailTemplatesDashboard';\n\nconst mockTemplates = [\n  {\n    id: '1',\n    template_name: 'Welcome Email',\n    template_key: 'welcome_email',\n    category: 'onboarding',\n    subject: 'Welcome to our platform!',\n    is_active: true,\n    is_system: false,\n    language_code: 'en',\n    created_at: '2025-01-01T00:00:00Z',\n    updated_at: '2025-01-01T00:00:00Z'\n  }\n];\n\ndescribe('EmailTemplatesDashboard', () => {\n  beforeEach(() => {\n    global.fetch = jest.fn().mockResolvedValue({\n      json: () => Promise.resolve({ templates: mockTemplates })\n    });\n  });\n\n  it('renders email templates dashboard', async () => {\n    render(<EmailTemplatesDashboard />);\n    \n    await waitFor(() => {\n      expect(screen.getByText('Email Templates')).toBeInTheDocument();\n    });\n  });\n\n  it('displays email templates', async () => {\n    render(<EmailTemplatesDashboard />);\n    \n    await waitFor(() => {\n      expect(screen.getByText('Welcome Email')).toBeInTheDocument();\n      expect(screen.getByText('welcome_email')).toBeInTheDocument();\n    });\n  });\n\n  it('filters templates by category', async () => {\n    render(<EmailTemplatesDashboard />);\n    \n    await waitFor(() => {\n      const categorySelect = screen.getByRole('combobox');\n      fireEvent.click(categorySelect);\n      \n      const onboardingOption = screen.getByText('Onboarding');\n      fireEvent.click(onboardingOption);\n    });\n    \n    expect(global.fetch).toHaveBeenCalledWith(\n      expect.stringContaining('category=onboarding')\n    );\n  });\n});\n```\n\n---\n\n## 🔐 PERMISSIONS & ROLES\n\n### Required Permissions\n- **Super Admin**: Full access to all email template features\n- **Marketing Manager**: Create and edit marketing templates\n- **Support Manager**: Edit support and notification templates\n\n### Role-based Access Control\n```sql\n-- Email template management permissions\nINSERT INTO role_permissions (role_name, permission) VALUES\n('super_admin', 'email:manage_all'),\n('super_admin', 'email:create_templates'),\n('super_admin', 'email:edit_system_templates'),\n('super_admin', 'email:send_test_emails'),\n('marketing_manager', 'email:manage_marketing'),\n('marketing_manager', 'email:create_templates'),\n('support_manager', 'email:manage_support'),\n('support_manager', 'email:edit_notifications');\n```\n\n---\n\n**Status**: ✅ READY FOR IMPLEMENTATION  \n**Last Updated**: January 5, 2025  \n**Version**: 1.0.0  \n**Priority**: MEDIUM