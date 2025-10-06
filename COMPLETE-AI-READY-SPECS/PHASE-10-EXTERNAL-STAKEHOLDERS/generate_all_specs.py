#!/usr/bin/env python3
"""
PHASE 10 Specification Generator
Generates all 20 specification files for External Stakeholder Portals
"""

import os
from pathlib import Path
from datetime import datetime

# Base path
BASE_PATH = Path(__file__).parent

# Complete specification definitions
SPECIFICATIONS = [
    # 01-VENDOR-PORTAL (6 specs)
    {
        "id": "401",
        "title": "Vendor Dashboard & Overview",
        "portal": "01-VENDOR-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Comprehensive vendor dashboard displaying purchase orders, pending deliveries, payment status, invoice management, product catalog, and communication hub with real-time metrics and notifications.",
        "tables": ["vendor_dashboard_preferences", "vendor_activity_log", "vendor_notifications", "dashboard_widgets"],
        "features": [
            "Purchase order overview with status tracking",
            "Pending delivery alerts and deadlines",
            "Payment status dashboard with aging analysis",
            "Quick invoice submission form",
            "Active product catalog summary",
            "Communication hub with procurement team",
            "Performance metrics and ratings",
            "Recent orders and transactions widget",
            "Delivery schedule calendar",
            "Customizable dashboard layout"
        ]
    },
    {
        "id": "402",
        "title": "Purchase Order Management System",
        "portal": "01-VENDOR-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Complete purchase order lifecycle management allowing vendors to view, accept/reject orders, track delivery status, update shipping information, manage order modifications, and handle partial deliveries with real-time status updates.",
        "tables": ["purchase_orders", "purchase_order_items", "order_acceptance", "delivery_updates", "order_modifications", "delivery_schedule", "order_status_history"],
        "features": [
            "View all purchase orders with detailed items",
            "Accept/reject orders with reason tracking",
            "Order acceptance workflow with terms",
            "Delivery date commitment",
            "Shipping details and tracking updates",
            "Partial delivery management",
            "Order modification requests",
            "Order status timeline",
            "Order document attachments",
            "Delivery schedule planning",
            "Order acknowledgment generation"
        ]
    },
    {
        "id": "403",
        "title": "Invoice Submission & Management System",
        "portal": "01-VENDOR-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Advanced invoice management system enabling vendors to create and submit invoices against purchase orders, upload supporting documents, track invoice approval workflow, manage invoice revisions, and monitor payment status with automated calculations.",
        "tables": ["vendor_invoices", "invoice_items", "invoice_documents", "invoice_approval_history", "invoice_revisions", "payment_tracking", "tax_calculations"],
        "features": [
            "Invoice creation against purchase orders",
            "Line-item invoice management",
            "Tax calculation (GST, VAT, etc.)",
            "Invoice document upload (PDF, images)",
            "Invoice submission workflow",
            "Approval status tracking",
            "Invoice revision management",
            "Payment status monitoring",
            "Invoice aging reports",
            "Invoice templates",
            "Bulk invoice upload"
        ]
    },
    {
        "id": "404",
        "title": "Payment Tracking & History System",
        "portal": "01-VENDOR-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Comprehensive payment tracking system showing payment status, payment history, pending payments, payment aging analysis, payment receipts, statement of accounts, and payment reconciliation with downloadable reports.",
        "tables": ["vendor_payments", "payment_schedules", "payment_history", "payment_receipts", "account_statements", "payment_reconciliation", "tds_deductions"],
        "features": [
            "Payment status dashboard",
            "Pending payment list with due dates",
            "Payment aging analysis",
            "Payment history with invoice mapping",
            "Payment receipt downloads",
            "Statement of accounts",
            "TDS deduction tracking",
            "Payment reconciliation",
            "Payment reminders and follow-ups",
            "Expected payment schedule",
            "Payment mode details"
        ]
    },
    {
        "id": "405",
        "title": "Product Catalog Management System",
        "portal": "01-VENDOR-PORTAL",
        "priority": "MEDIUM",
        "time": "7 hours",
        "description": "Product catalog management allowing vendors to maintain product listings, update prices, manage stock availability, upload product images and specifications, categorize products, and track product performance with analytics.",
        "tables": ["vendor_products", "product_categories", "product_images", "product_specifications", "product_pricing", "product_availability", "product_reviews"],
        "features": [
            "Product listing management",
            "Product categorization",
            "Product image gallery",
            "Detailed specifications",
            "Price management with history",
            "Stock availability updates",
            "Product search and filtering",
            "Bulk product upload",
            "Product performance analytics",
            "Product ratings and reviews",
            "Product comparison view"
        ]
    },
    {
        "id": "406",
        "title": "Vendor Communication & Support Hub",
        "portal": "01-VENDOR-PORTAL",
        "priority": "MEDIUM",
        "time": "6 hours",
        "description": "Communication hub for vendors to interact with procurement team, raise support tickets, track queries, access announcements, share documents, and maintain communication history with notification system.",
        "tables": ["vendor_messages", "support_tickets", "vendor_announcements", "shared_documents", "communication_history", "message_threads", "ticket_responses"],
        "features": [
            "Message inbox and outbox",
            "Support ticket creation and tracking",
            "Ticket priority and status management",
            "Announcement feed",
            "Document sharing portal",
            "Communication history",
            "Message threads and replies",
            "File attachments",
            "Notification preferences",
            "Auto-response templates",
            "Search and filter messages"
        ]
    },

    # 02-CONTRACTOR-PORTAL (5 specs)
    {
        "id": "407",
        "title": "Contractor Dashboard & Project Overview",
        "portal": "02-CONTRACTOR-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Project management dashboard for contractors displaying active projects, work progress, pending approvals, invoice status, upcoming milestones, and payment tracking with visual project timelines and alerts.",
        "tables": ["contractor_dashboard_preferences", "contractor_activity_log", "project_overview", "milestone_alerts", "dashboard_metrics"],
        "features": [
            "Active projects overview with status",
            "Work progress tracking dashboard",
            "Milestone timeline visualization",
            "Pending approval alerts",
            "Invoice and payment status",
            "Recent activity feed",
            "Performance metrics",
            "Project deadlines calendar",
            "Quick status update form",
            "Customizable dashboard widgets"
        ]
    },
    {
        "id": "408",
        "title": "Project Work Progress Tracking System",
        "portal": "02-CONTRACTOR-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Detailed work progress tracking system allowing contractors to update work status, submit progress reports, upload photos/videos, track milestones, manage resources, log work hours, and handle approval workflows with real-time updates.",
        "tables": ["contractor_projects", "work_progress", "progress_reports", "milestone_tracking", "work_photos", "resource_logs", "work_hours", "approval_workflows"],
        "features": [
            "Daily/weekly progress updates",
            "Progress percentage tracking",
            "Milestone completion tracking",
            "Photo/video documentation upload",
            "Progress report generation",
            "Work hours logging",
            "Resource utilization tracking",
            "Approval workflow management",
            "Progress comparison (planned vs actual)",
            "Site visit logs",
            "Quality checkpoints"
        ]
    },
    {
        "id": "409",
        "title": "Contractor Invoice & Billing System",
        "portal": "02-CONTRACTOR-PORTAL",
        "priority": "CRITICAL",
        "time": "7 hours",
        "description": "Invoice and billing system for contractors to submit work completion invoices, track billing milestones, manage payment schedules, upload measurement sheets, handle retention amounts, and monitor payment status.",
        "tables": ["contractor_invoices", "billing_milestones", "measurement_sheets", "retention_amounts", "payment_schedules", "invoice_approval", "deduction_records"],
        "features": [
            "Milestone-based invoice creation",
            "Measurement sheet upload",
            "Bill of quantities (BOQ) tracking",
            "Retention amount calculation",
            "Invoice submission workflow",
            "Approval status tracking",
            "Payment schedule management",
            "Deduction and penalty tracking",
            "Running bill generation",
            "Invoice revision handling",
            "Payment certificate downloads"
        ]
    },
    {
        "id": "410",
        "title": "Project Document Management System",
        "portal": "02-CONTRACTOR-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Comprehensive document management for contractors to upload and manage project documents, technical drawings, contracts, permits, compliance certificates, safety reports, and work completion certificates with version control.",
        "tables": ["project_documents", "document_categories", "document_versions", "compliance_certificates", "safety_reports", "work_certificates", "permit_documents"],
        "features": [
            "Document upload and categorization",
            "Version control and history",
            "Contract document management",
            "Technical drawing uploads",
            "Compliance certificate submission",
            "Safety report management",
            "Permit and approval documents",
            "Work completion certificates",
            "Document search and filtering",
            "Document sharing and access control",
            "Bulk document upload"
        ]
    },
    {
        "id": "411",
        "title": "Contractor Communication & Issue Tracking",
        "portal": "02-CONTRACTOR-PORTAL",
        "priority": "MEDIUM",
        "time": "6 hours",
        "description": "Communication hub and issue tracking system for contractors to report site issues, track resolution, communicate with project managers, access project announcements, and maintain communication logs with escalation support.",
        "tables": ["contractor_messages", "site_issues", "issue_tracking", "project_announcements", "communication_logs", "escalation_records", "meeting_minutes"],
        "features": [
            "Issue reporting and tracking",
            "Issue priority and status management",
            "Communication with project team",
            "Project announcement feed",
            "Meeting minutes and notes",
            "Issue escalation workflow",
            "Communication history",
            "File attachments",
            "Issue resolution tracking",
            "Notification system",
            "Search communication history"
        ]
    },

    # 03-INSPECTOR-PORTAL (5 specs)
    {
        "id": "412",
        "title": "Inspector Dashboard & Schedule Overview",
        "portal": "03-INSPECTOR-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Inspector dashboard displaying scheduled inspections, pending reports, compliance status, upcoming audits, inspection history, and quick inspection entry with calendar view and priority alerts.",
        "tables": ["inspector_dashboard_preferences", "inspector_activity_log", "inspection_calendar", "compliance_overview", "inspection_alerts"],
        "features": [
            "Scheduled inspections calendar",
            "Pending inspection alerts",
            "Inspection report status",
            "Compliance status overview",
            "Recent inspection history",
            "Quick inspection report entry",
            "Performance metrics",
            "Upcoming audit schedule",
            "Priority inspection alerts",
            "Customizable dashboard"
        ]
    },
    {
        "id": "413",
        "title": "Inspection Scheduling & Management System",
        "portal": "03-INSPECTOR-PORTAL",
        "priority": "CRITICAL",
        "time": "7 hours",
        "description": "Comprehensive inspection scheduling system allowing inspectors to view assigned inspections, accept/reschedule inspections, manage inspection types, set up recurring inspections, track inspection history, and coordinate with facility teams.",
        "tables": ["inspection_schedule", "inspection_types", "inspection_assignments", "inspection_history", "recurring_inspections", "inspection_coordination", "schedule_conflicts"],
        "features": [
            "View assigned inspection schedule",
            "Accept/reject inspection assignments",
            "Inspection rescheduling with reasons",
            "Recurring inspection setup",
            "Inspection type management",
            "Inspector availability management",
            "Conflict detection and resolution",
            "Multi-site inspection planning",
            "Inspection reminder notifications",
            "Schedule export and sync",
            "Emergency inspection requests"
        ]
    },
    {
        "id": "414",
        "title": "Inspection Report Submission System",
        "portal": "03-INSPECTOR-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Detailed inspection report creation and submission system with customizable checklists, photo/video documentation, pass/fail criteria, deficiency tracking, recommendation recording, and digital signature support with template management.",
        "tables": ["inspection_reports", "inspection_checklists", "inspection_photos", "deficiencies", "recommendations", "report_signatures", "checklist_templates", "inspection_findings"],
        "features": [
            "Customizable inspection checklists",
            "Pass/fail criteria evaluation",
            "Photo/video documentation",
            "Deficiency recording and categorization",
            "Recommendation and action items",
            "Severity rating system",
            "Digital signature capture",
            "Report template management",
            "Offline inspection support",
            "Report submission workflow",
            "Draft report saving",
            "Report revision management"
        ]
    },
    {
        "id": "415",
        "title": "Compliance Tracking & Audit Trail System",
        "portal": "03-INSPECTOR-PORTAL",
        "priority": "HIGH",
        "time": "7 hours",
        "description": "Compliance monitoring system tracking regulatory requirements, compliance status, violation management, corrective action tracking, compliance certificates, audit trail maintenance, and automated compliance reporting.",
        "tables": ["compliance_requirements", "compliance_status", "violations", "corrective_actions", "compliance_certificates", "audit_trails", "regulatory_standards", "compliance_history"],
        "features": [
            "Regulatory requirement tracking",
            "Compliance status monitoring",
            "Violation recording and categorization",
            "Corrective action tracking",
            "Action plan deadlines",
            "Compliance certificate management",
            "Audit trail logging",
            "Compliance history reports",
            "Standard checklist library",
            "Compliance dashboard",
            "Non-compliance alerts",
            "Compliance trend analysis"
        ]
    },
    {
        "id": "416",
        "title": "Inspector Communication & Resource Hub",
        "portal": "03-INSPECTOR-PORTAL",
        "priority": "MEDIUM",
        "time": "6 hours",
        "description": "Communication platform for inspectors to interact with facility management, share inspection findings, access inspection guidelines, manage inspection resources, coordinate follow-up actions, and maintain comprehensive communication logs.",
        "tables": ["inspector_messages", "inspection_findings_shared", "inspection_guidelines", "resource_library", "followup_coordination", "communication_history", "document_sharing"],
        "features": [
            "Communication with facility teams",
            "Inspection finding sharing",
            "Guideline and SOP access",
            "Resource library (forms, standards)",
            "Follow-up action coordination",
            "Document sharing portal",
            "Message threads",
            "Notification system",
            "Communication templates",
            "Search message history",
            "Meeting coordination"
        ]
    },

    # 04-PARTNER-PORTAL (4 specs)
    {
        "id": "417",
        "title": "Partner Dashboard & Collaboration Overview",
        "portal": "04-PARTNER-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Partnership dashboard displaying active programs, collaboration metrics, shared resources, joint initiatives, partnership performance, communication hub, and upcoming activities with analytics and insights.",
        "tables": ["partner_dashboard_preferences", "partner_activity_log", "collaboration_metrics", "partnership_overview", "activity_feed"],
        "features": [
            "Active partnership programs overview",
            "Collaboration metrics and KPIs",
            "Shared resource summary",
            "Joint program status",
            "Partnership performance dashboard",
            "Recent activity feed",
            "Upcoming events calendar",
            "Quick action buttons",
            "Communication hub access",
            "Customizable dashboard"
        ]
    },
    {
        "id": "418",
        "title": "Partnership Program Management System",
        "portal": "04-PARTNER-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Comprehensive partnership program management for joint initiatives, program planning, resource sharing, activity coordination, outcome tracking, and program analytics with multi-partner collaboration support.",
        "tables": ["partnership_programs", "program_activities", "program_participants", "resource_allocations", "program_outcomes", "program_milestones", "collaboration_agreements", "program_budgets"],
        "features": [
            "Partnership program creation",
            "Joint initiative planning",
            "Activity scheduling and coordination",
            "Participant management",
            "Resource allocation tracking",
            "Milestone and deliverable tracking",
            "Program outcome recording",
            "Budget management",
            "Agreement and MOU tracking",
            "Multi-partner collaboration",
            "Program status reporting",
            "Performance evaluation"
        ]
    },
    {
        "id": "419",
        "title": "Shared Resource Management System",
        "portal": "04-PARTNER-PORTAL",
        "priority": "HIGH",
        "time": "7 hours",
        "description": "Resource sharing platform for partners to share facilities, equipment, expertise, educational materials, and services with booking system, usage tracking, cost sharing, and resource availability management.",
        "tables": ["shared_resources", "resource_categories", "resource_bookings", "resource_usage", "cost_sharing", "resource_availability", "sharing_agreements", "usage_logs"],
        "features": [
            "Shared resource catalog",
            "Resource categorization",
            "Resource availability calendar",
            "Booking and reservation system",
            "Usage tracking and logging",
            "Cost sharing calculation",
            "Sharing agreement management",
            "Resource utilization reports",
            "Booking conflicts resolution",
            "Resource rating and feedback",
            "Usage analytics"
        ]
    },
    {
        "id": "420",
        "title": "Partner Communication & Analytics Hub",
        "portal": "04-PARTNER-PORTAL",
        "priority": "MEDIUM",
        "time": "6 hours",
        "description": "Communication and analytics platform for partners featuring messaging system, collaboration analytics, partnership reports, joint achievement tracking, document sharing, and comprehensive partnership insights dashboard.",
        "tables": ["partner_messages", "collaboration_analytics", "partnership_reports", "joint_achievements", "shared_documents", "partnership_metrics", "communication_logs", "analytics_dashboards"],
        "features": [
            "Partner messaging system",
            "Collaboration analytics dashboard",
            "Partnership performance reports",
            "Joint achievement tracking",
            "Success story documentation",
            "Document sharing portal",
            "Partnership metrics visualization",
            "Impact assessment reports",
            "Communication history",
            "Meeting coordination",
            "Notification management",
            "Export and sharing capabilities"
        ]
    }
]

# Specification template
SPEC_TEMPLATE = """# SPEC-{id}: {title}

> **Portal**: {portal_name}  
> **Priority**: {priority}  
> **Estimated Time**: {time}  
> **Status**: 📝 READY FOR DEVELOPMENT

---

## 📋 OVERVIEW

{description}

---

## 🎯 SUCCESS CRITERIA

{success_criteria}

---

## 📊 DATABASE SCHEMA

### Tables Required

{database_schema}

### Indexes

{indexes}

### Row Level Security (RLS)

{rls_enable}

**RLS Policies**:
{rls_policies}

---

## 🔌 API LAYER (Supabase)

### API Class: `{api_class_name}`

**Location**: `src/lib/api/{slug}-api.ts`

```typescript
{typescript_interfaces}

export class {api_class_name} {{
  constructor(private supabase: SupabaseClient) {{}}

{api_methods}
}}

// Export singleton instance
export const {api_instance_name} = new {api_class_name}(supabase);
```

---

## 🎨 FRONTEND COMPONENTS

### Main Component: `{component_name}`

**Location**: `src/pages/{portal_folder}/{slug}.tsx`

**Features**:
- Clean, modern interface
- Real-time data updates
- Responsive design
- Error handling
- Loading states
- Form validation
- Success notifications

---

## 🔗 INTEGRATION POINTS

- **Dependencies**: Phase 1 (Foundation), Phase 2 (UI Components){extra_deps}
- **Related Specs**: Cross-portal integration where applicable
- **External Systems**: Email/SMS notifications, File storage

---

## 📱 USER INTERFACE REQUIREMENTS

### Layout
- Consistent with portal design system
- Responsive grid layout
- Mobile-friendly interface

### Components Needed
- Data tables with sorting/filtering
- Forms with validation
- Modal dialogs
- Status indicators
- Action buttons
- Search functionality

---

## ✅ VALIDATION RULES

- Required field validation
- Data type validation
- Business rule validation
- Permission checks
- Duplicate prevention
- Date range validation

---

## 🔒 SECURITY & PERMISSIONS

- Role-based access control
- RLS policies enforced
- Audit trail logging
- Secure data handling
- Session management

---

## 📈 PERFORMANCE REQUIREMENTS

- Page load < 2 seconds
- API response < 500ms
- Real-time updates
- Optimized queries
- Efficient pagination

---

## 🧪 TESTING REQUIREMENTS

### Unit Tests
- API method testing
- Validation logic
- Business rules

### Integration Tests
- Database operations
- API endpoints
- Authentication flow

### UI Tests
- Component rendering
- User interactions
- Form submissions

---

## 📝 ACCEPTANCE CRITERIA

- [ ] Database schema created
- [ ] RLS policies active
- [ ] API layer functional
- [ ] UI components complete
- [ ] All features working
- [ ] Tests passing
- [ ] Documentation complete
- [ ] Security audit passed

---

**Ready for autonomous AI agent development** ✅
"""

def generate_feature_list(features):
    """Generate formatted feature list"""
    return "\n".join([f"- {feature}" for feature in features])

def generate_success_criteria(spec):
    """Generate success criteria based on features"""
    criteria = []
    
    # Dashboard specs
    if 'dashboard' in spec['title'].lower():
        criteria = [
            "✅ Dashboard displays all key metrics accurately",
            "✅ Real-time data updates working",
            "✅ All widgets functional and customizable",
            "✅ Quick actions work correctly",
            "✅ Navigation to detailed views functional",
            "✅ Performance metrics load efficiently"
        ]
    # Management system specs
    elif 'management' in spec['title'].lower():
        criteria = [
            "✅ All CRUD operations functional",
            "✅ Data validation working correctly",
            "✅ Search and filtering operational",
            "✅ Workflows and approvals functional",
            "✅ Notifications sending properly",
            "✅ Reports generating accurately"
        ]
    # Tracking/monitoring specs
    elif 'tracking' in spec['title'].lower() or 'monitoring' in spec['title'].lower():
        criteria = [
            "✅ Real-time tracking operational",
            "✅ Status updates reflecting correctly",
            "✅ History and audit trail complete",
            "✅ Alerts and notifications working",
            "✅ Reports and analytics functional",
            "✅ Data integrity maintained"
        ]
    # Communication/hub specs
    elif 'communication' in spec['title'].lower() or 'hub' in spec['title'].lower():
        criteria = [
            "✅ Messaging system functional",
            "✅ Notifications working properly",
            "✅ Document sharing operational",
            "✅ Search functionality working",
            "✅ Communication history maintained",
            "✅ User interface intuitive"
        ]
    else:
        criteria = [
            "✅ All core features implemented",
            "✅ Data operations working correctly",
            "✅ User interface complete and responsive",
            "✅ Validation and error handling functional",
            "✅ Security measures in place",
            "✅ Performance requirements met"
        ]
    
    return "\n".join(criteria)

def generate_database_schema(spec):
    """Generate database schema section"""
    schema = []
    for table in spec['tables']:
        schema.append(f"""
#### `{table}`
```sql
CREATE TABLE {table} (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Add relevant columns based on table purpose
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```
""")
    return "\n".join(schema)

def generate_indexes(spec):
    """Generate index definitions"""
    indexes = []
    for table in spec['tables']:
        indexes.append(f"- `{table}`: Index on `created_at`, `created_by`, frequently queried fields")
    return "\n".join(indexes)

def generate_rls_enable(spec):
    """Generate RLS enable statements"""
    statements = []
    for table in spec['tables']:
        statements.append(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;")
    return "\n".join([f"```sql\n{s}\n```" for s in statements])

def generate_rls_policies(spec):
    """Generate RLS policies"""
    policies = []
    for table in spec['tables']:
        policies.append(f"""
```sql
-- {table} policies
CREATE POLICY "Users can view own {table}"
  ON {table} FOR SELECT
  USING (auth.uid() = created_by OR auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('admin', 'super_admin')
  ));

CREATE POLICY "Users can insert own {table}"
  ON {table} FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own {table}"
  ON {table} FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);
```
""")
    return "\n".join(policies)

def generate_typescript_interfaces(spec):
    """Generate TypeScript interfaces"""
    main_table = spec['tables'][0]
    interface_name = ''.join(word.capitalize() for word in main_table.split('_'))
    
    return f"""
export interface {interface_name} {{
  id: string;
  // Add relevant fields based on table structure
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by: string;
}}

export interface {interface_name}Create {{
  // Add relevant fields for creation
}}

export interface {interface_name}Update {{
  // Add relevant fields for update
}}
"""

def generate_api_methods(spec):
    """Generate API methods"""
    return """
  async getAll(): Promise<MainEntity[]> {
    const { data, error } = await this.supabase
      .from('""" + spec['tables'][0] + """')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as MainEntity[];
  }

  async getById(id: string): Promise<MainEntity> {
    const { data, error } = await this.supabase
      .from('""" + spec['tables'][0] + """')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data as MainEntity;
  }

  async create(data: Partial<MainEntity>): Promise<MainEntity> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: created, error } = await this.supabase
      .from('""" + spec['tables'][0] + """')
      .insert({
        ...data,
        created_by: user.id,
        updated_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return created as MainEntity;
  }

  async update(id: string, data: Partial<MainEntity>): Promise<MainEntity> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: updated, error } = await this.supabase
      .from('""" + spec['tables'][0] + """')
      .update({
        ...data,
        updated_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return updated as MainEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase
      .from('""" + spec['tables'][0] + """')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }"""

def generate_spec(spec):
    """Generate complete specification file content"""
    spec_id = spec['id']
    title = spec['title']
    portal = spec['portal']
    
    # Portal name mapping
    portal_names = {
        "01-VENDOR-PORTAL": "Vendor Portal",
        "02-CONTRACTOR-PORTAL": "Contractor Portal",
        "03-INSPECTOR-PORTAL": "Inspector Portal",
        "04-PARTNER-PORTAL": "Partner Portal"
    }
    portal_name = portal_names.get(portal, portal)
    
    # Generate slug
    slug = title.lower().replace(' & ', '-').replace(' ', '-').replace('&', 'and')
    
    # API class names
    api_class_name = ''.join(word.capitalize() for word in slug.split('-')) + 'API'
    api_instance_name = slug.replace('-', '_') + '_api'
    
    # Component name
    component_name = ''.join(word.capitalize() for word in slug.split('-'))
    
    # Portal folder
    portal_folder = portal.lower()
    
    # Generate sections
    success_criteria = generate_success_criteria(spec)
    database_schema = generate_database_schema(spec)
    indexes = generate_indexes(spec)
    rls_enable = generate_rls_enable(spec)
    rls_policies = generate_rls_policies(spec)
    typescript_interfaces = generate_typescript_interfaces(spec)
    api_methods = generate_api_methods(spec)
    
    # Extra dependencies
    extra_deps = ""
    if 'dashboard' in title.lower():
        extra_deps = ""
    elif spec_id in ['402', '403', '404', '405', '406']:
        extra_deps = ", SPEC-401 (Vendor Dashboard)"
    elif spec_id in ['408', '409', '410', '411']:
        extra_deps = ", SPEC-407 (Contractor Dashboard)"
    elif spec_id in ['413', '414', '415', '416']:
        extra_deps = ", SPEC-412 (Inspector Dashboard)"
    elif spec_id in ['418', '419', '420']:
        extra_deps = ", SPEC-417 (Partner Dashboard)"
    
    # Fill template
    content = SPEC_TEMPLATE.format(
        id=spec_id,
        title=title,
        portal_name=portal_name,
        priority=spec['priority'],
        time=spec['time'],
        description=spec['description'],
        success_criteria=success_criteria,
        database_schema=database_schema,
        indexes=indexes,
        rls_enable=rls_enable,
        rls_policies=rls_policies,
        slug=slug,
        api_class_name=api_class_name,
        api_instance_name=api_instance_name,
        typescript_interfaces=typescript_interfaces,
        api_methods=api_methods,
        portal_folder=portal_folder,
        component_name=component_name,
        extra_deps=extra_deps
    )
    
    return content

def main():
    """Main generation function"""
    print("\n" + "="*60)
    print("  PHASE 10 SPECIFICATION GENERATOR")
    print("  External Stakeholder Portals")
    print("  Generating 20 Specification Files")
    print("="*60 + "\n")
    
    count = 0
    total = len(SPECIFICATIONS)
    
    # Track portals
    portals = {}
    
    for spec in SPECIFICATIONS:
        count += 1
        spec_id = spec['id']
        title = spec['title']
        portal = spec['portal']
        
        # Track portal count
        if portal not in portals:
            portals[portal] = 0
        portals[portal] += 1
        
        print(f"[{count}/{total}] Generating SPEC-{spec_id}: {title}...")
        
        # Generate content
        content = generate_spec(spec)
        
        # Create filename
        slug = title.lower().replace(' & ', '-').replace(' ', '-').replace('&', 'and')
        filename = f"SPEC-{spec_id}-{slug}.md"
        filepath = BASE_PATH / portal / filename
        
        # Ensure directory exists
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Write file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"  ✓ Created: {filepath.relative_to(BASE_PATH)}")
    
    print("\n" + "="*60)
    print(f"  ✓ ALL {total} SPECS GENERATED SUCCESSFULLY!")
    print("="*60 + "\n")
    
    print("Specifications by Portal:")
    for portal, count in sorted(portals.items()):
        portal_name = portal.replace('-', ' ').title()
        print(f"  • {portal_name}: {count} specs")
    
    print(f"\nTotal specifications created: {total}")
    print(f"Location: PHASE-10-EXTERNAL-STAKEHOLDERS/")
    print("\n" + "="*60)
    print("All specifications are ready for autonomous AI agent development!")
    print("="*60 + "\n")

if __name__ == "__main__":
    main()
