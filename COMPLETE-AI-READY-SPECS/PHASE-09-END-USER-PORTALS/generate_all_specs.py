#!/usr/bin/env python3
"""
PHASE 9 - END USER PORTALS Specification Generator
Generates all 30 specification files for Student, Parent & Alumni Portals
"""

import os
from pathlib import Path
from datetime import datetime

# Base path
BASE_PATH = Path(__file__).parent

# Complete specification definitions for PHASE 9
SPECIFICATIONS = [
    # ==========================================
    # STUDENT PORTAL (12 Specifications)
    # ==========================================
    {
        "id": "401",
        "title": "Student Dashboard & Overview",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "6 hours",
        "description": "Comprehensive student dashboard displaying today's schedule, pending assignments, upcoming exams, recent grades, attendance summary, notifications, announcements, and quick action buttons for common tasks.",
        "tables": ["student_dashboard_preferences", "student_activity_log", "dashboard_widgets", "quick_actions", "notification_preferences"],
        "features": [
            "Personalized dashboard with student info",
            "Today's class schedule with timing",
            "Pending assignments list with due dates",
            "Upcoming exams and tests",
            "Recent grades and marks",
            "Attendance summary (monthly)",
            "School announcements feed",
            "Quick actions (pay fees, apply leave, etc.)",
            "Notification center",
            "Customizable widget layout"
        ]
    },
    {
        "id": "402",
        "title": "Student Profile & Academic Information",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "5 hours",
        "description": "Complete student profile management with personal information, academic details, parent/guardian information, emergency contacts, photo upload, ID card download, and profile editing capabilities.",
        "tables": ["student_profiles", "student_documents", "emergency_contacts", "student_preferences", "profile_history"],
        "features": [
            "View personal information",
            "Academic details (class, section, roll number)",
            "Parent/guardian information",
            "Emergency contacts",
            "Profile photo upload",
            "ID card generation and download",
            "Address and contact details",
            "Edit profile (with approval)",
            "Document uploads (certificates, etc.)",
            "Profile completion status"
        ]
    },
    {
        "id": "403",
        "title": "Class Timetable & Schedule Viewer",
        "portal": "01-STUDENT-PORTAL",
        "priority": "HIGH",
        "time": "5 hours",
        "description": "Interactive class timetable viewer with daily, weekly, and monthly views, subject-wise schedule, teacher information, room numbers, period timings, and calendar integration with export options.",
        "tables": ["class_timetables", "timetable_periods", "subject_schedule", "timetable_changes", "holiday_calendar"],
        "features": [
            "Daily class schedule view",
            "Weekly timetable grid",
            "Subject-wise schedule",
            "Teacher and room information",
            "Period timings display",
            "Break times highlighted",
            "Holiday calendar integration",
            "Timetable change notifications",
            "Export to calendar (iCal)",
            "Print timetable option"
        ]
    },
    {
        "id": "404",
        "title": "Attendance Tracking & History",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "6 hours",
        "description": "Comprehensive attendance tracking system with daily attendance view, monthly summary, subject-wise attendance, attendance percentage calculation, leave history, and attendance reports with visual analytics.",
        "tables": ["student_attendance", "attendance_summary", "leave_applications", "attendance_alerts", "attendance_reports"],
        "features": [
            "Daily attendance view",
            "Monthly attendance calendar",
            "Subject-wise attendance",
            "Attendance percentage calculation",
            "Present/absent/late status",
            "Leave applications history",
            "Attendance alerts and warnings",
            "Attendance reports (monthly, term)",
            "Visual attendance charts",
            "Attendance comparison by term"
        ]
    },
    {
        "id": "405",
        "title": "Grades & Marks Viewer",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "7 hours",
        "description": "Complete grade book system displaying subject-wise marks, exam results, internal assessments, project marks, grade calculation, cumulative GPA, rank display, progress tracking, and downloadable mark sheets.",
        "tables": ["student_grades", "exam_results", "internal_marks", "grade_calculations", "mark_sheets", "grade_history"],
        "features": [
            "Subject-wise marks display",
            "Exam results (unit tests, midterm, final)",
            "Internal assessment marks",
            "Assignment and project marks",
            "Grade calculation and GPA",
            "Class rank display",
            "Progress tracking over terms",
            "Mark sheet download (PDF)",
            "Subject-wise performance charts",
            "Comparative analysis"
        ]
    },
    {
        "id": "406",
        "title": "Assignment Submission & Management",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Complete assignment management system with assignment listing, submission interface, file upload, deadline tracking, submission status, teacher feedback viewing, revision submission, and grade viewing.",
        "tables": ["assignments", "assignment_submissions", "submission_files", "assignment_feedback", "submission_history"],
        "features": [
            "View assigned work by subject",
            "Assignment details and instructions",
            "File upload for submissions",
            "Multiple file attachment support",
            "Deadline tracking and reminders",
            "Submission status (submitted, pending, late)",
            "View teacher feedback and comments",
            "Marks received on assignments",
            "Revision submission capability",
            "Assignment history and archive"
        ]
    },
    {
        "id": "407",
        "title": "Study Materials & Resources Access",
        "portal": "01-STUDENT-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Digital library of study materials with subject-wise organization, file download, video lectures, reference materials, notes, presentations, e-books, search functionality, and recent materials feed.",
        "tables": ["study_materials", "material_categories", "material_access_log", "bookmarked_materials", "material_ratings"],
        "features": [
            "Subject-wise material organization",
            "Download study materials (PDF, docs)",
            "Video lecture access",
            "Reference materials and notes",
            "PowerPoint presentations",
            "E-books and digital textbooks",
            "Search and filter materials",
            "Bookmark favorite materials",
            "Recent uploads feed",
            "Material rating and feedback"
        ]
    },
    {
        "id": "408",
        "title": "Online Exam & Assessment Portal",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "10 hours",
        "description": "Comprehensive online examination system with exam scheduling, test taking interface, multiple question types (MCQ, descriptive, true/false), timer, auto-submit, answer review, instant results for objective tests, and exam history.",
        "tables": ["online_exams", "exam_questions", "student_answers", "exam_results", "exam_sessions", "exam_logs"],
        "features": [
            "View scheduled online exams",
            "Exam instructions and guidelines",
            "Test taking interface",
            "Multiple question types (MCQ, descriptive)",
            "True/False questions",
            "Exam timer with warnings",
            "Auto-submit on timeout",
            "Save draft answers",
            "Review answers before submit",
            "Instant results for objective tests",
            "Exam history and past results"
        ]
    },
    {
        "id": "409",
        "title": "Fee Payment & Financial Management",
        "portal": "01-STUDENT-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Complete fee management with online payment gateway integration, fee structure viewing, pending dues, payment history, receipt download, installment tracking, multiple payment methods, and payment reminders.",
        "tables": ["student_fees", "fee_payments", "payment_transactions", "fee_receipts", "payment_reminders", "fee_installments"],
        "features": [
            "View fee structure",
            "Pending dues display",
            "Online payment (multiple gateways)",
            "Payment methods (card, UPI, net banking)",
            "Payment confirmation",
            "Receipt download (PDF)",
            "Payment history",
            "Installment tracking",
            "Fee reminders and notifications",
            "Scholarship/discount display"
        ]
    },
    {
        "id": "410",
        "title": "Library Management & Book Access",
        "portal": "01-STUDENT-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Digital library interface showing issued books, due dates, book search, reservation system, reading history, fine tracking, renewal requests, e-library access, and reading recommendations.",
        "tables": ["library_books", "book_issues", "book_reservations", "library_fines", "reading_history", "book_reviews"],
        "features": [
            "View issued books with due dates",
            "Book search and browse",
            "Reserve available books",
            "Reading history",
            "Fine tracking and payment",
            "Renewal requests",
            "E-library access (digital books)",
            "Book reviews and ratings",
            "Reading recommendations",
            "Library card details"
        ]
    },
    {
        "id": "411",
        "title": "Leave Application & Request Management",
        "portal": "01-STUDENT-PORTAL",
        "priority": "HIGH",
        "time": "5 hours",
        "description": "Leave application system with form submission, leave type selection, date range, reason, document attachment, approval status tracking, leave history, and automated notifications.",
        "tables": ["student_leave_applications", "leave_types", "leave_approvals", "leave_documents", "leave_balance"],
        "features": [
            "Apply for leave (sick, casual, etc.)",
            "Select leave date range",
            "Reason for leave",
            "Upload supporting documents",
            "View approval status",
            "Leave history",
            "Leave balance tracking",
            "Withdrawal of leave application",
            "Approval notifications",
            "Leave policy information"
        ]
    },
    {
        "id": "412",
        "title": "Feedback, Complaints & Support System",
        "portal": "01-STUDENT-PORTAL",
        "priority": "MEDIUM",
        "time": "5 hours",
        "description": "Student feedback and complaint management with multiple categories, ticket submission, status tracking, admin responses, feedback forms, rating system, and support ticket history.",
        "tables": ["student_feedback", "complaint_tickets", "feedback_categories", "ticket_responses", "feedback_ratings"],
        "features": [
            "Submit feedback on courses/teachers",
            "Complaint ticket system",
            "Category selection (academic, facility, etc.)",
            "Track ticket status",
            "View admin responses",
            "Rating system for services",
            "Anonymous feedback option",
            "Feedback history",
            "Support ticket escalation",
            "FAQ section"
        ]
    },
    
    # ==========================================
    # PARENT PORTAL (12 Specifications)
    # ==========================================
    {
        "id": "413",
        "title": "Parent Dashboard & Children Overview",
        "portal": "02-PARENT-PORTAL",
        "priority": "CRITICAL",
        "time": "6 hours",
        "description": "Comprehensive parent dashboard with multiple children selector, overview of each child's attendance, grades, pending fees, upcoming events, recent activities, notifications, and quick action buttons.",
        "tables": ["parent_dashboard_preferences", "parent_activity_log", "children_selector", "dashboard_alerts", "parent_notifications"],
        "features": [
            "Multiple children selector/switcher",
            "Overview cards per child",
            "Attendance summary for each child",
            "Recent grades and marks",
            "Pending fee amounts",
            "Upcoming events and exams",
            "Recent activities feed",
            "School announcements",
            "Quick actions (pay fees, contact teacher)",
            "Notification center"
        ]
    },
    {
        "id": "414",
        "title": "Child Attendance Monitoring & Alerts",
        "portal": "02-PARENT-PORTAL",
        "priority": "CRITICAL",
        "time": "6 hours",
        "description": "Real-time attendance monitoring system with daily attendance notifications, monthly calendar view, subject-wise attendance, attendance percentage, absence alerts, pattern analysis, and attendance reports.",
        "tables": ["child_attendance_tracking", "attendance_alerts", "absence_notifications", "attendance_patterns", "attendance_reports"],
        "features": [
            "Real-time attendance notifications",
            "Daily attendance status",
            "Monthly attendance calendar",
            "Subject-wise attendance view",
            "Attendance percentage tracking",
            "Absence alerts and warnings",
            "Late arrival notifications",
            "Attendance pattern analysis",
            "Comparison with class average",
            "Downloadable attendance reports"
        ]
    },
    {
        "id": "415",
        "title": "Child Academic Performance & Grades",
        "portal": "02-PARENT-PORTAL",
        "priority": "CRITICAL",
        "time": "7 hours",
        "description": "Comprehensive academic performance tracking with subject-wise marks, exam results, progress reports, grade trends, class comparison, teacher remarks, strengths/weaknesses analysis, and downloadable report cards.",
        "tables": ["child_academic_performance", "exam_results_parent_view", "progress_reports", "grade_trends", "teacher_remarks"],
        "features": [
            "Subject-wise marks and grades",
            "Exam results (all assessments)",
            "Progress reports by term",
            "Grade trend analysis",
            "Class rank and comparison",
            "Teacher remarks and feedback",
            "Strengths and weaknesses",
            "Assignment completion status",
            "Project marks and feedback",
            "Downloadable report cards"
        ]
    },
    {
        "id": "416",
        "title": "Teacher Communication & Messaging",
        "portal": "02-PARENT-PORTAL",
        "priority": "HIGH",
        "time": "7 hours",
        "description": "Direct communication system with teachers including messaging, chat interface, scheduled meetings, conversation history, teacher availability, read receipts, attachment support, and broadcast messages from school.",
        "tables": ["parent_teacher_messages", "message_threads", "scheduled_meetings", "message_attachments", "communication_log"],
        "features": [
            "Direct messaging to teachers",
            "Chat interface with threads",
            "Schedule parent-teacher meetings",
            "View teacher availability",
            "Message history per teacher",
            "Read receipts and status",
            "File attachment support",
            "Broadcast messages from school",
            "Emergency contact feature",
            "Translation support"
        ]
    },
    {
        "id": "417",
        "title": "Fee Payment & Financial Tracking",
        "portal": "02-PARENT-PORTAL",
        "priority": "CRITICAL",
        "time": "8 hours",
        "description": "Complete financial management with fee structure viewing, pending dues for all children, online payment gateway, payment history, receipt management, installment tracking, auto-payment setup, and fee reminders.",
        "tables": ["parent_fee_tracking", "child_fee_payments", "payment_transactions", "fee_receipts", "payment_reminders", "auto_payment_setup"],
        "features": [
            "View fee structure per child",
            "Pending dues (all children)",
            "Pay fees online (multiple children)",
            "Payment gateway integration",
            "Payment confirmation",
            "Download receipts (PDF)",
            "Payment history (all children)",
            "Installment tracking",
            "Auto-payment setup",
            "Fee reminders and alerts"
        ]
    },
    {
        "id": "418",
        "title": "Event Calendar & Notifications",
        "portal": "02-PARENT-PORTAL",
        "priority": "HIGH",
        "time": "5 hours",
        "description": "School event calendar with upcoming events, parent-teacher meetings, holidays, exam schedules, extracurricular activities, RSVP functionality, event reminders, and calendar integration.",
        "tables": ["school_events", "event_registrations", "event_reminders", "event_attendance", "event_calendar"],
        "features": [
            "School event calendar",
            "Upcoming events feed",
            "Parent-teacher meeting schedule",
            "Holidays and breaks",
            "Exam and assessment dates",
            "Extracurricular activities",
            "RSVP for events",
            "Event reminders and notifications",
            "Export to personal calendar",
            "Event photo gallery"
        ]
    },
    {
        "id": "419",
        "title": "Assignment & Homework Tracking",
        "portal": "02-PARENT-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Homework and assignment monitoring with pending assignments list, submission status, teacher feedback, completion percentage, overdue alerts, subject-wise tracking, and assignment history.",
        "tables": ["child_assignments_tracking", "assignment_status", "homework_feedback", "completion_tracking", "overdue_alerts"],
        "features": [
            "View child's pending assignments",
            "Subject-wise assignment list",
            "Due dates and deadlines",
            "Submission status tracking",
            "Teacher feedback on assignments",
            "Marks received",
            "Overdue assignment alerts",
            "Completion percentage",
            "Assignment history",
            "Download assignment details"
        ]
    },
    {
        "id": "420",
        "title": "Behavioral Reports & Discipline Tracking",
        "portal": "02-PARENT-PORTAL",
        "priority": "MEDIUM",
        "time": "5 hours",
        "description": "Student behavior monitoring with conduct reports, discipline incidents, positive behavior recognition, teacher observations, counselor notes, improvement tracking, and behavioral trend analysis.",
        "tables": ["behavioral_reports", "discipline_incidents", "positive_recognition", "teacher_observations", "counselor_notes"],
        "features": [
            "Behavioral conduct reports",
            "Discipline incident notifications",
            "Positive behavior recognition",
            "Teacher observations",
            "Counselor notes and recommendations",
            "Behavioral trend analysis",
            "Improvement tracking",
            "Parent acknowledgment",
            "Action plan monitoring",
            "Behavioral history"
        ]
    },
    {
        "id": "421",
        "title": "Health & Medical Records Access",
        "portal": "02-PARENT-PORTAL",
        "priority": "MEDIUM",
        "time": "5 hours",
        "description": "Medical information management with health records, vaccination history, medical conditions, allergies, medication tracking, sick leave history, health checkup reports, and emergency contact updates.",
        "tables": ["student_health_records", "vaccination_history", "medical_conditions", "medication_tracking", "health_checkups"],
        "features": [
            "View child's health records",
            "Vaccination history",
            "Medical conditions and allergies",
            "Current medications",
            "Sick leave history",
            "Health checkup reports",
            "Update medical information",
            "Emergency contact management",
            "Doctor's recommendations",
            "Health alerts and reminders"
        ]
    },
    {
        "id": "422",
        "title": "Transport & Bus Tracking",
        "portal": "02-PARENT-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "School transport management with real-time bus tracking, route information, pickup/drop timings, bus attendance, driver details, GPS tracking, arrival alerts, and transport fee management.",
        "tables": ["transport_assignments", "bus_tracking", "route_details", "transport_attendance", "transport_alerts"],
        "features": [
            "Real-time bus tracking (GPS)",
            "View assigned route and bus",
            "Pickup and drop timings",
            "Bus attendance tracking",
            "Driver and conductor details",
            "Bus arrival alerts",
            "Route map view",
            "Transport fee information",
            "Change route requests",
            "Emergency contact (driver)"
        ]
    },
    {
        "id": "423",
        "title": "Progress Reports & Report Cards",
        "portal": "02-PARENT-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Comprehensive progress reporting with term-wise report cards, cumulative progress, subject-wise analysis, teacher comments, areas of improvement, comparison charts, and downloadable PDF reports.",
        "tables": ["progress_reports", "report_cards", "term_summaries", "teacher_comments", "comparative_analysis"],
        "features": [
            "Term-wise report cards",
            "Cumulative progress tracking",
            "Subject-wise performance analysis",
            "Teacher comments and remarks",
            "Areas of improvement",
            "Strengths highlighted",
            "Grade comparison by term",
            "Visual progress charts",
            "Download report cards (PDF)",
            "Historical performance data"
        ]
    },
    {
        "id": "424",
        "title": "Parent Concern & Support System",
        "portal": "02-PARENT-PORTAL",
        "priority": "MEDIUM",
        "time": "5 hours",
        "description": "Parent support system with concern submission, ticket tracking, category-wise organization, priority levels, admin responses, resolution status, feedback mechanism, and support history.",
        "tables": ["parent_concerns", "support_tickets", "concern_categories", "ticket_responses", "resolution_tracking"],
        "features": [
            "Submit concerns and queries",
            "Category selection (academic, transport, etc.)",
            "Priority level indication",
            "Track ticket status",
            "View admin responses",
            "Attach supporting documents",
            "Resolution status",
            "Feedback on resolution",
            "Concern history",
            "FAQ and help center"
        ]
    },
    
    # ==========================================
    # ALUMNI PORTAL (6 Specifications)
    # ==========================================
    {
        "id": "425",
        "title": "Alumni Dashboard & Profile",
        "portal": "03-ALUMNI-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Alumni dashboard with profile management, professional information, career updates, batch details, achievements showcase, networking stats, event calendar, and alumni directory access.",
        "tables": ["alumni_profiles", "professional_info", "achievements", "batch_details", "alumni_activity_log"],
        "features": [
            "Personalized alumni dashboard",
            "Profile management (personal & professional)",
            "Current employment details",
            "Career progression timeline",
            "Achievements showcase",
            "Batch and year information",
            "Alumni statistics",
            "Upcoming alumni events",
            "Recent alumni news",
            "Quick networking actions"
        ]
    },
    {
        "id": "426",
        "title": "Alumni Directory & Networking",
        "portal": "03-ALUMNI-PORTAL",
        "priority": "HIGH",
        "time": "7 hours",
        "description": "Searchable alumni directory with advanced filters, batch-wise grouping, location mapping, professional networking, connection requests, messaging system, and alumni groups.",
        "tables": ["alumni_directory", "alumni_connections", "alumni_groups", "connection_requests", "alumni_messages"],
        "features": [
            "Searchable alumni directory",
            "Filter by batch, year, location, profession",
            "Batch-wise alumni groups",
            "Location-based search and mapping",
            "Send connection requests",
            "Alumni messaging system",
            "Professional networking",
            "Industry-wise grouping",
            "Alumni success stories",
            "Privacy settings for profile"
        ]
    },
    {
        "id": "427",
        "title": "Alumni Events & Reunions",
        "portal": "03-ALUMNI-PORTAL",
        "priority": "HIGH",
        "time": "6 hours",
        "description": "Event management system with alumni events calendar, reunion planning, event registration, RSVP tracking, event photos and memories, attendance history, and event feedback.",
        "tables": ["alumni_events", "event_registrations", "event_attendance", "event_photos", "event_feedback"],
        "features": [
            "Alumni events calendar",
            "Reunion events and planning",
            "Event registration and RSVP",
            "Ticket booking for paid events",
            "Event details and schedule",
            "Attendance tracking",
            "Event photo gallery",
            "Share event memories",
            "Event reminders",
            "Post-event feedback"
        ]
    },
    {
        "id": "428",
        "title": "Job Board & Career Services",
        "portal": "03-ALUMNI-PORTAL",
        "priority": "MEDIUM",
        "time": "7 hours",
        "description": "Alumni job board with job postings, internship opportunities, referral system, career mentorship matching, job search filters, application tracking, and alumni-to-alumni hiring.",
        "tables": ["job_postings", "job_applications", "mentorship_programs", "referrals", "career_services"],
        "features": [
            "Alumni job board",
            "Post job opportunities",
            "Internship listings",
            "Job search and filters",
            "Apply for jobs",
            "Referral system",
            "Career mentorship matching",
            "Mentor-mentee connections",
            "Application tracking",
            "Alumni company directory"
        ]
    },
    {
        "id": "429",
        "title": "Donation & Contribution System",
        "portal": "03-ALUMNI-PORTAL",
        "priority": "MEDIUM",
        "time": "7 hours",
        "description": "Alumni donation platform with multiple causes, online payment gateway, donation history, tax receipts, recurring donations, fundraising campaigns, donor recognition, and contribution tracking.",
        "tables": ["donations", "donation_campaigns", "donation_transactions", "tax_receipts", "donor_recognition"],
        "features": [
            "View donation causes and campaigns",
            "Make donations online",
            "One-time and recurring donations",
            "Payment gateway integration",
            "Donation history",
            "Tax receipt download",
            "Fundraising campaigns",
            "Campaign progress tracking",
            "Donor recognition and acknowledgment",
            "Corporate matching programs"
        ]
    },
    {
        "id": "430",
        "title": "Alumni News, Awards & Recognition",
        "portal": "03-ALUMNI-PORTAL",
        "priority": "MEDIUM",
        "time": "5 hours",
        "description": "Alumni engagement platform with news feed, success stories, alumni awards, achievement recognition, testimonials, photo gallery, blog section, and social media integration.",
        "tables": ["alumni_news", "success_stories", "alumni_awards", "testimonials", "photo_gallery"],
        "features": [
            "Alumni news feed",
            "Success stories and achievements",
            "Alumni awards and honors",
            "Recognition programs",
            "Submit achievements",
            "Testimonials and reviews",
            "Photo gallery of events",
            "Alumni blog section",
            "Social media integration",
            "Newsletter subscription"
        ]
    }
]

# Specification template (same as Phase 8)
SPEC_TEMPLATE = """# SPEC-{id}: {title}

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-{id}  
**Title**: {title}  
**Phase**: Phase 9 - End User Portals  
**Portal**: {portal_name}  
**Category**: User Experience & Engagement  
**Priority**: {priority}  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: {time}  
**Dependencies**: SPEC-011 (Multi-tenant), SPEC-013 (Auth){extra_deps}  

---

## 📋 DESCRIPTION

{description}

---

## 🎯 SUCCESS CRITERIA

{success_criteria}
- [ ] Mobile responsive layout verified
- [ ] Performance optimized (<2s load time)
- [ ] All tests passing (85%+ coverage)
- [ ] Security audit completed
- [ ] Documentation complete

---

## 🗄️ DATABASE SCHEMA

```sql
{database_schema}

-- Indexes
{indexes}

-- Enable RLS
{rls_enable}

-- RLS Policies
{rls_policies}
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/spec-{id}-{slug}.ts`)

```typescript
import {{ createClient }} from '@/lib/supabase/client';

{typescript_interfaces}

export class {api_class_name} {{
  private supabase = createClient();

{api_methods}
}}

export const {api_instance_name} = new {api_class_name}();
```

### React Component (`/components/{portal_folder}/{component_name}.tsx`)

```typescript
'use client';

import React, {{ useState, useEffect }} from 'react';
import {{ Card, CardContent, CardHeader, CardTitle }} from '@/components/ui/card';
import {{ Button }} from '@/components/ui/button';
import {{ Input }} from '@/components/ui/input';
import {{ useToast }} from '@/components/ui/use-toast';
import {{ Search, Plus, Edit, Trash2 }} from 'lucide-react';

export function {component_name}() {{
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const {{ toast }} = useToast();

  useEffect(() => {{
    loadData();
  }}, []);

  const loadData = async () => {{
    try {{
      setLoading(true);
      // Load data using API
      setItems([]);
    }} catch (error: any) {{
      toast({{
        title: 'Error',
        description: error.message,
        variant: 'destructive'
      }});
    }} finally {{
      setLoading(false);
    }}
  }};

  return (
    <div className="space-y-6 p-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">{title}</h1>
          <p className="text-muted-foreground">Manage and track operations</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Add New
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search..."
                  value={{searchQuery}}
                  onChange={{(e) => setSearchQuery(e.target.value)}}
                  className="pl-10"
                />
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {{loading ? (
            <div className="text-center py-8">Loading...</div>
          ) : items.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No records found
            </div>
          ) : (
            <div className="space-y-2">
              {{items.map((item) => (
                <div key={{item.id}} className="flex items-center justify-between p-4 border rounded-lg">
                  <div>
                    <p className="font-medium">{{item.name}}</p>
                    <p className="text-sm text-muted-foreground">{{item.description}}</p>
                  </div>
                  <div className="flex gap-2">
                    <Button size="sm" variant="outline">
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button size="sm" variant="outline">
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}}
            </div>
          )}}
        </CardContent>
      </Card>
    </div>
  );
}}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/spec-{id}-{slug}.test.ts`)

```typescript
import {{ describe, it, expect, beforeEach, vi }} from 'vitest';
import {{ {api_instance_name} }} from '@/lib/api/spec-{id}-{slug}';

describe('SPEC-{id}: {title} API', () => {{
  beforeEach(() => {{
    vi.clearAllMocks();
  }});

  describe('CRUD Operations', () => {{
    it('should fetch all records', async () => {{
      const result = await {api_instance_name}.getAll();
      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('total');
    }});

    it('should create new record', async () => {{
      const newItem = {{
        name: 'Test Item',
        description: 'Test Description'
      }};
      const created = await {api_instance_name}.create(newItem);
      expect(created).toHaveProperty('id');
    }});

    it('should update existing record', async () => {{
      const updated = await {api_instance_name}.update('test-id', {{
        name: 'Updated Name'
      }});
      expect(updated.name).toBe('Updated Name');
    }});

    it('should delete record', async () => {{
      await expect({api_instance_name}.delete('test-id')).resolves.not.toThrow();
    }});
  }});
}});
```

---

## 📚 USAGE EXAMPLE

```typescript
import {{ {component_name} }} from '@/components/{portal_folder}/{component_name}';

export default function Page() {{
  return (
    <div className="container mx-auto">
      <{component_name} />
    </div>
  );
}}
```

---

## 🔒 SECURITY

- **Row Level Security (RLS)** enforced on all tables
- User-specific data access (student/parent/alumni only sees their data)
- Parent can only access their children's data
- Secure authentication required
- Input validation on all operations
- Activity logging for audit trail

---

## 📊 PERFORMANCE

- **Page Load**: < 2 seconds
- **Search**: < 500ms
- **Create/Update**: < 1 second
- **Database Queries**: Indexed and optimized
- **Pagination**: Server-side for large datasets
- **Caching**: For frequently accessed data

---

## ✅ DEFINITION OF DONE

- [ ] All database tables and indexes created
- [ ] RLS policies implemented and tested
- [ ] API client fully implemented with TypeScript types
- [ ] React component with full functionality
- [ ] Search and filter working
- [ ] Unit tests passing (85%+ coverage)
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation complete
- [ ] User acceptance testing passed
"""

def generate_table_schema(table_name, spec_id):
    """Generate basic table schema"""
    return f"""CREATE TABLE IF NOT EXISTS {table_name} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID REFERENCES students(id),
  user_id UUID REFERENCES auth.users(id),
  name VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT {{}},
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);"""

def generate_spec(spec):
    """Generate a complete specification file"""
    spec_id = spec['id']
    title = spec['title']
    portal = spec['portal']
    portal_name = portal.replace('-', ' ').replace('01', '').replace('02', '').replace('03', '').strip()
    portal_folder = portal.lower().replace('portal', 'portal')
    
    # Generate slug
    slug = title.lower().replace(' & ', '-').replace(' ', '-').replace('&', 'and')
    
    # Generate success criteria
    success_criteria = '\n'.join([f"- [ ] {feature} functional" for feature in spec['features']])
    
    # Generate database schema
    database_schema = '\n\n'.join([generate_table_schema(table, spec_id) for table in spec['tables']])
    
    # Generate indexes
    indexes = '\n'.join([f"CREATE INDEX idx_{table}_tenant_branch ON {table}(tenant_id, branch_id);\nCREATE INDEX idx_{table}_user ON {table}(user_id);\nCREATE INDEX idx_{table}_status ON {table}(status);\nCREATE INDEX idx_{table}_created_at ON {table}(created_at DESC);" for table in spec['tables']])
    
    # Generate RLS enable
    rls_enable = '\n'.join([f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;" for table in spec['tables']])
    
    # Generate RLS policies
    rls_policies = '\n\n'.join([f"""CREATE POLICY {table}_user_isolation ON {table}
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
    AND user_id = auth.uid()
  );""" for table in spec['tables']])
    
    # Generate API class name
    api_class_name = f"SPEC{spec_id}API"
    api_instance_name = f"spec{spec_id}API"
    
    # Generate component name
    component_name = ''.join([word.capitalize() for word in slug.split('-')])
    
    # Generate TypeScript interfaces
    typescript_interfaces = f"""export interface MainEntity {{
  id: string;
  tenantId: string;
  branchId: string;
  userId: string;
  name: string;
  description: string;
  status: string;
  metadata?: Record<string, any>;
  createdAt: string;
  updatedAt: string;
}}"""
    
    # Generate API methods
    api_methods = """  async getAll(page: number = 1, limit: number = 20): Promise<{
    data: MainEntity[];
    total: number;
  }> {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await this.supabase
      .from('""" + spec['tables'][0] + """')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(start, end);

    if (error) throw error;
    
    return {
      data: data as MainEntity[],
      total: count || 0
    };
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
        user_id: user.id,
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
    
    # Extra dependencies
    extra_deps = ""
    if 'dashboard' in title.lower():
        extra_deps = ""
    elif int(spec_id) >= 402 and int(spec_id) <= 412:
        extra_deps = ", SPEC-401 (Student Dashboard)"
    elif int(spec_id) >= 414 and int(spec_id) <= 424:
        extra_deps = ", SPEC-413 (Parent Dashboard)"
    elif int(spec_id) >= 426 and int(spec_id) <= 430:
        extra_deps = ", SPEC-425 (Alumni Dashboard)"
    
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
    print("  PHASE 9 - END USER PORTALS SPECIFICATION GENERATOR")
    print("  Generating 30 Specification Files")
    print("="*60 + "\n")
    
    count = 0
    total = len(SPECIFICATIONS)
    
    for spec in SPECIFICATIONS:
        count += 1
        spec_id = spec['id']
        title = spec['title']
        portal = spec['portal']
        
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
    print(f"Total specifications created: {total}")
    print(f"Location: PHASE-09-END-USER-PORTALS/")
    print("\nPortal Breakdown:")
    print("  • Student Portal: 12 specifications (SPEC-401 to SPEC-412)")
    print("  • Parent Portal: 12 specifications (SPEC-413 to SPEC-424)")
    print("  • Alumni Portal: 6 specifications (SPEC-425 to SPEC-430)")
    print("\nAll specifications are ready for autonomous AI agent development!")

if __name__ == "__main__":
    main()
