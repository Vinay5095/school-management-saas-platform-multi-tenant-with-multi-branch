# SPEC-352: Student Records Management System

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-352  
**Title**: Student Records Management System  
**Phase**: Phase 7 - Administrative Staff Portals  
**Portal**: Registrar Portal  
**Category**: Records Management  
**Priority**: CRITICAL  
**Status**: ✅ READY FOR DEVELOPMENT  
**Estimated Time**: 8 hours  
**Dependencies**: SPEC-011, SPEC-351  

---

## 📋 DESCRIPTION

Comprehensive student records management system for maintaining complete academic records, personal information, attendance history, grade records, disciplinary records, and document management. Includes advanced search, filtering, bulk operations, and audit trails.

---

## 🎯 SUCCESS CRITERIA

- [ ] Complete student record viewing with all academic history
- [ ] Advanced search and filtering operational
- [ ] Record editing with validation and approval workflow
- [ ] Document upload and management working
- [ ] Audit trail tracking all changes
- [ ] Bulk operations for record updates
- [ ] Export functionality (PDF, Excel, CSV)
- [ ] Performance optimized for large datasets
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- Student Records Extended View
CREATE OR REPLACE VIEW student_complete_records AS
SELECT
  s.id,
  s.tenant_id,
  s.branch_id,
  s.student_code,
  s.student_name,
  s.date_of_birth,
  s.gender,
  s.email,
  s.phone,
  s.address,
  s.admission_date,
  s.status,
  s.photo_url,
  
  -- Guardian info
  s.guardian_name,
  s.guardian_phone,
  s.guardian_email,
  s.guardian_relationship,
  
  -- Current class
  c.class_name as current_class,
  c.section as current_section,
  c.grade_level,
  
  -- Academic performance
  (SELECT AVG(grade_percentage) 
   FROM grades WHERE student_id = s.id) as overall_average,
  
  -- Attendance
  (SELECT COUNT(*) FROM attendance_records 
   WHERE student_id = s.id AND status = 'present') as total_present,
  (SELECT COUNT(*) FROM attendance_records 
   WHERE student_id = s.id) as total_days,
  
  -- Documents
  (SELECT COUNT(*) FROM student_documents 
   WHERE student_id = s.id) as total_documents,
  
  -- Disciplinary
  (SELECT COUNT(*) FROM disciplinary_records 
   WHERE student_id = s.id) as disciplinary_count,
  
  s.created_at,
  s.updated_at
  
FROM students s
LEFT JOIN student_class_assignments sca ON s.id = sca.student_id AND sca.status = 'active'
LEFT JOIN classes c ON sca.class_id = c.id;

-- Student Record Change Log
CREATE TABLE IF NOT EXISTS student_record_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID NOT NULL REFERENCES students(id),
  
  -- Change details
  changed_by UUID NOT NULL REFERENCES auth.users(id),
  change_type VARCHAR(50) NOT NULL, -- update, create, delete, status_change
  field_name VARCHAR(100),
  old_value TEXT,
  new_value TEXT,
  
  -- Approval workflow
  requires_approval BOOLEAN DEFAULT false,
  approval_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  approval_notes TEXT,
  
  -- Metadata
  change_reason TEXT,
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_change_type CHECK (
    change_type IN ('update', 'create', 'delete', 'status_change', 'document_added')
  ),
  CONSTRAINT valid_approval_status CHECK (
    approval_status IN ('pending', 'approved', 'rejected', 'not_required')
  )
);

CREATE INDEX ON student_record_changes(tenant_id, branch_id, student_id);
CREATE INDEX ON student_record_changes(changed_by);
CREATE INDEX ON student_record_changes(approval_status);
CREATE INDEX ON student_record_changes(created_at DESC);

-- Student Documents
CREATE TABLE IF NOT EXISTS student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID NOT NULL REFERENCES students(id),
  
  -- Document details
  document_type VARCHAR(100) NOT NULL, -- birth_certificate, photo, id_proof, etc.
  document_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  mime_type VARCHAR(100),
  
  -- Metadata
  uploaded_by UUID NOT NULL REFERENCES auth.users(id),
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  is_verified BOOLEAN DEFAULT false,
  
  -- Additional info
  document_number VARCHAR(100),
  issue_date DATE,
  expiry_date DATE,
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_document_type CHECK (
    document_type IN (
      'birth_certificate', 'photo', 'id_proof', 'address_proof',
      'previous_school_certificate', 'medical_certificate', 
      'cast_certificate', 'income_certificate', 'other'
    )
  )
);

CREATE INDEX ON student_documents(tenant_id, branch_id, student_id);
CREATE INDEX ON student_documents(document_type);
CREATE INDEX ON student_documents(is_verified);

-- Student Notes
CREATE TABLE IF NOT EXISTS student_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  student_id UUID NOT NULL REFERENCES students(id),
  
  -- Note details
  note_type VARCHAR(50) NOT NULL, -- general, medical, academic, behavioral
  note_title VARCHAR(255) NOT NULL,
  note_content TEXT NOT NULL,
  
  -- Privacy
  is_confidential BOOLEAN DEFAULT false,
  visible_to VARCHAR(50)[] DEFAULT ARRAY['registrar', 'principal'], -- who can see
  
  -- Author
  created_by UUID NOT NULL REFERENCES auth.users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_note_type CHECK (
    note_type IN ('general', 'medical', 'academic', 'behavioral', 'family')
  )
);

CREATE INDEX ON student_notes(tenant_id, branch_id, student_id);
CREATE INDEX ON student_notes(note_type);
CREATE INDEX ON student_notes(created_at DESC);

-- Function to update student record with audit
CREATE OR REPLACE FUNCTION update_student_record(
  p_student_id UUID,
  p_field_name VARCHAR,
  p_new_value TEXT,
  p_change_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_change_id UUID;
  v_old_value TEXT;
  v_requires_approval BOOLEAN;
  v_tenant_id UUID;
  v_branch_id UUID;
  v_changed_by UUID;
BEGIN
  -- Get session info
  v_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
  v_branch_id := current_setting('app.current_branch_id', true)::UUID;
  v_changed_by := auth.uid();
  
  -- Get old value
  EXECUTE format('SELECT %I FROM students WHERE id = $1', p_field_name)
  INTO v_old_value
  USING p_student_id;
  
  -- Determine if approval is required (sensitive fields)
  v_requires_approval := p_field_name IN ('student_name', 'date_of_birth', 'status');
  
  -- Log the change
  INSERT INTO student_record_changes (
    tenant_id, branch_id, student_id, changed_by,
    change_type, field_name, old_value, new_value,
    requires_approval, approval_status, change_reason
  ) VALUES (
    v_tenant_id, v_branch_id, p_student_id, v_changed_by,
    'update', p_field_name, v_old_value, p_new_value,
    v_requires_approval,
    CASE WHEN v_requires_approval THEN 'pending' ELSE 'not_required' END,
    p_change_reason
  ) RETURNING id INTO v_change_id;
  
  -- If no approval required, update immediately
  IF NOT v_requires_approval THEN
    EXECUTE format('UPDATE students SET %I = $1, updated_at = NOW() WHERE id = $2', p_field_name)
    USING p_new_value, p_student_id;
  END IF;
  
  RETURN v_change_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search students
CREATE OR REPLACE FUNCTION search_students(
  p_search_term TEXT DEFAULT NULL,
  p_class_id UUID DEFAULT NULL,
  p_status VARCHAR DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  student_code VARCHAR,
  student_name VARCHAR,
  current_class VARCHAR,
  status VARCHAR,
  overall_average NUMERIC,
  total_documents INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    scr.id,
    scr.student_code,
    scr.student_name,
    scr.current_class || ' ' || scr.current_section as current_class,
    scr.status,
    scr.overall_average,
    scr.total_documents
  FROM student_complete_records scr
  WHERE scr.tenant_id = current_setting('app.current_tenant_id')::UUID
    AND scr.branch_id = current_setting('app.current_branch_id')::UUID
    AND (p_search_term IS NULL OR (
      scr.student_name ILIKE '%' || p_search_term || '%' OR
      scr.student_code ILIKE '%' || p_search_term || '%' OR
      scr.email ILIKE '%' || p_search_term || '%'
    ))
    AND (p_status IS NULL OR scr.status = p_status)
  ORDER BY scr.student_name
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE student_record_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY student_record_changes_isolation ON student_record_changes
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY student_documents_isolation ON student_documents
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );

CREATE POLICY student_notes_isolation ON student_notes
  FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id')::UUID
    AND branch_id = current_setting('app.current_branch_id')::UUID
  );
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/student-records.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface StudentRecord {
  id: string;
  studentCode: string;
  studentName: string;
  dateOfBirth: string;
  gender: string;
  email: string;
  phone: string;
  address: string;
  admissionDate: string;
  status: string;
  photoUrl?: string;
  guardianName: string;
  guardianPhone: string;
  guardianEmail: string;
  currentClass: string;
  currentSection: string;
  gradeLevel: number;
  overallAverage: number;
  totalPresent: number;
  totalDays: number;
  totalDocuments: number;
  disciplinaryCount: number;
}

export interface StudentDocument {
  id: string;
  documentType: string;
  documentName: string;
  fileUrl: string;
  fileSize: number;
  mimeType: string;
  uploadedBy: string;
  verifiedBy?: string;
  verifiedAt?: string;
  isVerified: boolean;
  documentNumber?: string;
  issueDate?: string;
  expiryDate?: string;
  notes?: string;
  createdAt: string;
}

export interface StudentNote {
  id: string;
  noteType: string;
  noteTitle: string;
  noteContent: string;
  isConfidential: boolean;
  visibleTo: string[];
  createdBy: string;
  createdAt: string;
}

export interface RecordChange {
  id: string;
  changeType: string;
  fieldName: string;
  oldValue: string;
  newValue: string;
  requiresApproval: boolean;
  approvalStatus: string;
  changeReason?: string;
  createdAt: string;
}

export class StudentRecordsAPI {
  private supabase = createClient();

  /**
   * Search students
   */
  async searchStudents(params: {
    searchTerm?: string;
    classId?: string;
    status?: string;
    limit?: number;
    offset?: number;
  }): Promise<StudentRecord[]> {
    const { data, error } = await this.supabase.rpc('search_students', {
      p_search_term: params.searchTerm || null,
      p_class_id: params.classId || null,
      p_status: params.status || null,
      p_limit: params.limit || 50,
      p_offset: params.offset || 0
    });

    if (error) throw error;
    return data;
  }

  /**
   * Get complete student record
   */
  async getStudentRecord(studentId: string): Promise<StudentRecord> {
    const { data, error } = await this.supabase
      .from('student_complete_records')
      .select('*')
      .eq('id', studentId)
      .single();

    if (error) throw error;
    return this.mapToStudentRecord(data);
  }

  /**
   * Update student record field
   */
  async updateStudentField(
    studentId: string,
    fieldName: string,
    newValue: any,
    changeReason?: string
  ): Promise<string> {
    const { data, error } = await this.supabase.rpc('update_student_record', {
      p_student_id: studentId,
      p_field_name: fieldName,
      p_new_value: String(newValue),
      p_change_reason: changeReason
    });

    if (error) throw error;
    return data; // Returns change ID
  }

  /**
   * Get student documents
   */
  async getStudentDocuments(studentId: string): Promise<StudentDocument[]> {
    const { data, error } = await this.supabase
      .from('student_documents')
      .select('*')
      .eq('student_id', studentId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data.map(this.mapToStudentDocument);
  }

  /**
   * Upload student document
   */
  async uploadDocument(
    studentId: string,
    file: File,
    documentType: string,
    metadata?: {
      documentNumber?: string;
      issueDate?: string;
      expiryDate?: string;
      notes?: string;
    }
  ): Promise<StudentDocument> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Upload file to storage
    const fileName = `${studentId}/${documentType}/${Date.now()}-${file.name}`;
    const { data: uploadData, error: uploadError } = await this.supabase
      .storage
      .from('student-documents')
      .upload(fileName, file);

    if (uploadError) throw uploadError;

    // Get public URL
    const { data: { publicUrl } } = this.supabase
      .storage
      .from('student-documents')
      .getPublicUrl(fileName);

    // Create document record
    const { data, error } = await this.supabase
      .from('student_documents')
      .insert({
        student_id: studentId,
        document_type: documentType,
        document_name: file.name,
        file_url: publicUrl,
        file_size: file.size,
        mime_type: file.type,
        uploaded_by: user.id,
        document_number: metadata?.documentNumber,
        issue_date: metadata?.issueDate,
        expiry_date: metadata?.expiryDate,
        notes: metadata?.notes
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapToStudentDocument(data);
  }

  /**
   * Verify document
   */
  async verifyDocument(documentId: string): Promise<void> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await this.supabase
      .from('student_documents')
      .update({
        is_verified: true,
        verified_by: user.id,
        verified_at: new Date().toISOString()
      })
      .eq('id', documentId);

    if (error) throw error;
  }

  /**
   * Get student notes
   */
  async getStudentNotes(studentId: string): Promise<StudentNote[]> {
    const { data, error } = await this.supabase
      .from('student_notes')
      .select('*')
      .eq('student_id', studentId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data.map(this.mapToStudentNote);
  }

  /**
   * Add student note
   */
  async addNote(
    studentId: string,
    noteType: string,
    title: string,
    content: string,
    isConfidential: boolean = false
  ): Promise<StudentNote> {
    const { data: { user } } = await this.supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await this.supabase
      .from('student_notes')
      .insert({
        student_id: studentId,
        note_type: noteType,
        note_title: title,
        note_content: content,
        is_confidential: isConfidential,
        created_by: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return this.mapToStudentNote(data);
  }

  /**
   * Get record change history
   */
  async getChangeHistory(studentId: string): Promise<RecordChange[]> {
    const { data, error } = await this.supabase
      .from('student_record_changes')
      .select('*')
      .eq('student_id', studentId)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    return data.map(this.mapToRecordChange);
  }

  /**
   * Export student records
   */
  async exportRecords(studentIds: string[], format: 'pdf' | 'excel' | 'csv'): Promise<Blob> {
    const { data, error } = await this.supabase.functions.invoke('export-student-records', {
      body: { studentIds, format }
    });

    if (error) throw error;
    return data;
  }

  // Mapping helpers
  private mapToStudentRecord(data: any): StudentRecord {
    return {
      id: data.id,
      studentCode: data.student_code,
      studentName: data.student_name,
      dateOfBirth: data.date_of_birth,
      gender: data.gender,
      email: data.email,
      phone: data.phone,
      address: data.address,
      admissionDate: data.admission_date,
      status: data.status,
      photoUrl: data.photo_url,
      guardianName: data.guardian_name,
      guardianPhone: data.guardian_phone,
      guardianEmail: data.guardian_email,
      currentClass: data.current_class,
      currentSection: data.current_section,
      gradeLevel: data.grade_level,
      overallAverage: data.overall_average,
      totalPresent: data.total_present,
      totalDays: data.total_days,
      totalDocuments: data.total_documents,
      disciplinaryCount: data.disciplinary_count
    };
  }

  private mapToStudentDocument(data: any): StudentDocument {
    return {
      id: data.id,
      documentType: data.document_type,
      documentName: data.document_name,
      fileUrl: data.file_url,
      fileSize: data.file_size,
      mimeType: data.mime_type,
      uploadedBy: data.uploaded_by,
      verifiedBy: data.verified_by,
      verifiedAt: data.verified_at,
      isVerified: data.is_verified,
      documentNumber: data.document_number,
      issueDate: data.issue_date,
      expiryDate: data.expiry_date,
      notes: data.notes,
      createdAt: data.created_at
    };
  }

  private mapToStudentNote(data: any): StudentNote {
    return {
      id: data.id,
      noteType: data.note_type,
      noteTitle: data.note_title,
      noteContent: data.note_content,
      isConfidential: data.is_confidential,
      visibleTo: data.visible_to,
      createdBy: data.created_by,
      createdAt: data.created_at
    };
  }

  private mapToRecordChange(data: any): RecordChange {
    return {
      id: data.id,
      changeType: data.change_type,
      fieldName: data.field_name,
      oldValue: data.old_value,
      newValue: data.new_value,
      requiresApproval: data.requires_approval,
      approvalStatus: data.approval_status,
      changeReason: data.change_reason,
      createdAt: data.created_at
    };
  }
}

export const studentRecordsAPI = new StudentRecordsAPI();
```

### React Component (`/components/registrar/StudentRecordsManager.tsx`)

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Search, 
  Filter, 
  Download, 
  FileText, 
  Upload,
  Edit,
  History,
  Eye
} from 'lucide-react';
import { studentRecordsAPI, type StudentRecord } from '@/lib/api/student-records';
import { useToast } from '@/components/ui/use-toast';
import { useDebounce } from '@/hooks/use-debounce';

export function StudentRecordsManager() {
  const [students, setStudents] = useState<StudentRecord[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(false);
  const [selectedStudent, setSelectedStudent] = useState<StudentRecord | null>(null);
  const { toast } = useToast();
  
  const debouncedSearch = useDebounce(searchTerm, 300);

  useEffect(() => {
    searchStudents();
  }, [debouncedSearch]);

  const searchStudents = async () => {
    try {
      setLoading(true);
      const results = await studentRecordsAPI.searchStudents({
        searchTerm: debouncedSearch,
        limit: 50
      });
      setStudents(results);
    } catch (error) {
      console.error('Error searching students:', error);
      toast({
        title: 'Error',
        description: 'Failed to search students',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Student Records</h1>
        <Button>
          <Download className="h-4 w-4 mr-2" />
          Export Records
        </Button>
      </div>

      {/* Search and Filter */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by name, code, or email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Button variant="outline">
              <Filter className="h-4 w-4 mr-2" />
              Filters
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Results */}
      <div className="grid grid-cols-1 gap-4">
        {loading ? (
          <div>Loading...</div>
        ) : students.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center text-muted-foreground">
              No students found
            </CardContent>
          </Card>
        ) : (
          students.map((student) => (
            <StudentRecordCard
              key={student.id}
              student={student}
              onSelect={() => setSelectedStudent(student)}
            />
          ))
        )}
      </div>
    </div>
  );
}

function StudentRecordCard({ student, onSelect }: { student: StudentRecord; onSelect: () => void }) {
  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={onSelect}>
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
              {student.photoUrl ? (
                <img src={student.photoUrl} alt={student.studentName} className="w-full h-full rounded-full" />
              ) : (
                <span className="text-lg font-bold">{student.studentName[0]}</span>
              )}
            </div>
            <div>
              <h3 className="font-semibold">{student.studentName}</h3>
              <p className="text-sm text-muted-foreground">
                {student.studentCode} • {student.currentClass}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-sm font-medium">Average: {student.overallAverage.toFixed(1)}%</p>
              <p className="text-xs text-muted-foreground">
                {student.totalDocuments} documents
              </p>
            </div>
            <Badge>{student.status}</Badge>
            <Button size="sm" variant="outline">
              <Eye className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
```

---

## 🧪 TESTING

### Unit Tests (`/tests/unit/student-records.test.ts`)

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { studentRecordsAPI } from '@/lib/api/student-records';

describe('StudentRecordsAPI', () => {
  describe('searchStudents', () => {
    it('should search students by name', async () => {
      const results = await studentRecordsAPI.searchStudents({
        searchTerm: 'John',
        limit: 10
      });
      
      expect(Array.isArray(results)).toBe(true);
      expect(results.length).toBeLessThanOrEqual(10);
    });
  });

  describe('updateStudentField', () => {
    it('should update student field and create audit log', async () => {
      const changeId = await studentRecordsAPI.updateStudentField(
        'student-id',
        'phone',
        '1234567890',
        'Phone number update'
      );
      
      expect(changeId).toBeDefined();
    });
  });
});
```

---

## 📚 USAGE EXAMPLE

```typescript
import { StudentRecordsManager } from '@/components/registrar/StudentRecordsManager';

export default function RecordsPage() {
  return <StudentRecordsManager />;
}
```

---

## 🔒 SECURITY

- Row Level Security enforced on all tables
- Audit trail for all changes
- Approval workflow for sensitive fields
- Document access control
- Confidential notes protection

---

## 📊 PERFORMANCE

- Indexed search queries
- Pagination for large datasets
- Debounced search input
- Lazy loading for documents
- Cached recent searches

---

## ✅ DEFINITION OF DONE

- [ ] All database schema created
- [ ] API client fully implemented
- [ ] Search and filtering working
- [ ] Document management operational
- [ ] Audit trail tracking all changes
- [ ] Tests passing (85%+ coverage)
- [ ] Performance optimized
- [ ] Security audit completed
