# SPEC-125: Backup and Data Management
## Platform Backup, Restore, and Data Operations

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6-7 hours  
> **Dependencies**: SPEC-116, SPEC-117, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive automated backup management, data export/import functionality, tenant data migration tools, and disaster recovery operations for platform data protection.

### Key Features
- ✅ Automated scheduled backups
- ✅ Manual backup triggers
- ✅ Backup restore operations
- ✅ Tenant data export/import
- ✅ Data migration wizard
- ✅ Point-in-time recovery
- ✅ Backup verification and integrity checks
- ✅ Storage management
- ✅ Disaster recovery procedures
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Backup configurations
CREATE TABLE backup_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  configuration_name TEXT UNIQUE NOT NULL,
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'incremental', 'differential')),
  schedule_cron TEXT NOT NULL,
  retention_days INTEGER NOT NULL DEFAULT 30,
  compression_enabled BOOLEAN DEFAULT TRUE,
  encryption_enabled BOOLEAN DEFAULT TRUE,
  storage_location TEXT NOT NULL,
  includes_tenant_data BOOLEAN DEFAULT TRUE,
  includes_system_data BOOLEAN DEFAULT TRUE,
  includes_logs BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Backup execution history
CREATE TABLE backup_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  configuration_id UUID REFERENCES backup_configurations(id),
  backup_type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  file_path TEXT,
  file_size BIGINT,
  compressed_size BIGINT,
  tenant_count INTEGER,
  table_count INTEGER,
  record_count BIGINT,
  checksum TEXT,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Restore operations
CREATE TABLE restore_operations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_execution_id UUID REFERENCES backup_executions(id),
  restore_type TEXT NOT NULL CHECK (restore_type IN ('full', 'selective', 'tenant_only')),
  target_tenant_id UUID REFERENCES tenants(id),
  restore_point TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
  progress_percentage INTEGER DEFAULT 0,
  tables_to_restore TEXT[],
  exclude_tables TEXT[],
  preserve_ids BOOLEAN DEFAULT FALSE,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  initiated_by UUID NOT NULL REFERENCES users(id),
  error_message TEXT,
  restored_records JSONB DEFAULT '{}'::jsonb
);

-- Data migration jobs
CREATE TABLE migration_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  migration_name TEXT NOT NULL,
  migration_type TEXT NOT NULL CHECK (migration_type IN ('tenant_copy', 'data_import', 'data_export', 'tenant_merge')),
  source_tenant_id UUID REFERENCES tenants(id),
  target_tenant_id UUID REFERENCES tenants(id),
  source_file_path TEXT,
  target_file_path TEXT,
  mapping_configuration JSONB DEFAULT '{}'::jsonb,
  transformation_rules JSONB DEFAULT '[]'::jsonb,
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
  progress_percentage INTEGER DEFAULT 0,
  records_processed INTEGER DEFAULT 0,
  records_total INTEGER DEFAULT 0,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  initiated_by UUID NOT NULL REFERENCES users(id),
  error_message TEXT,
  validation_results JSONB DEFAULT '{}'::jsonb
);

-- Storage management
CREATE TABLE backup_storage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_name TEXT UNIQUE NOT NULL,
  storage_type TEXT NOT NULL CHECK (storage_type IN ('local', 's3', 'azure', 'gcp')),
  storage_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  total_capacity BIGINT,
  used_space BIGINT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_health_check TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_backup_executions_config_status ON backup_executions(configuration_id, status);
CREATE INDEX idx_backup_executions_started_at ON backup_executions(started_at);
CREATE INDEX idx_restore_operations_status ON restore_operations(status);
CREATE INDEX idx_migration_jobs_status ON migration_jobs(status);
```

---

## 🎨 UI COMPONENTS

### Backup Management Dashboard
```tsx
// components/admin/backup/BackupDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { 
  Database, 
  Download, 
  Upload, 
  RefreshCw, 
  Calendar,
  HardDrive,
  Shield,
  CheckCircle,
  XCircle,
  Clock
} from 'lucide-react';

interface BackupExecution {
  id: string;
  backup_type: string;
  status: string;
  started_at: string;
  completed_at?: string;
  file_size?: number;
  error_message?: string;
}

interface BackupConfiguration {
  id: string;
  configuration_name: string;
  backup_type: string;
  schedule_cron: string;
  retention_days: number;
  storage_location: string;
  is_active: boolean;
}

export function BackupDashboard() {
  const [backups, setBackups] = useState<BackupExecution[]>([]);
  const [configurations, setConfigurations] = useState<BackupConfiguration[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadBackupData();
  }, []);

  const loadBackupData = async () => {
    try {
      const [backupsRes, configsRes] = await Promise.all([
        fetch('/api/admin/backup/executions'),
        fetch('/api/admin/backup/configurations')
      ]);
      
      const backupsData = await backupsRes.json();
      const configsData = await configsRes.json();
      
      setBackups(backupsData.executions || []);
      setConfigurations(configsData.configurations || []);
    } catch (error) {
      console.error('Failed to load backup data:', error);
    } finally {
      setLoading(false);
    }
  };

  const triggerBackup = async (configId: string) => {
    try {
      await fetch('/api/admin/backup/trigger', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ configurationId: configId })
      });
      loadBackupData();
    } catch (error) {
      console.error('Failed to trigger backup:', error);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'failed': return <XCircle className="w-4 h-4 text-red-500" />;
      case 'running': return <RefreshCw className="w-4 h-4 text-blue-500 animate-spin" />;
      default: return <Clock className="w-4 h-4 text-gray-500" />;
    }
  };

  const formatFileSize = (bytes: number) => {
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    if (bytes === 0) return '0 Bytes';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  if (loading) {
    return <div className="flex items-center justify-center h-96">Loading backup data...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Backup Management</h1>
          <p className="text-gray-600">Manage platform backups, restore operations, and data migrations</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={loadBackupData}>
            <RefreshCw className="w-4 h-4 mr-2" />
            Refresh
          </Button>
          <Button>
            <Database className="w-4 h-4 mr-2" />
            New Backup
          </Button>
        </div>
      </div>

      <Tabs defaultValue="executions">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="executions">Recent Backups</TabsTrigger>
          <TabsTrigger value="configurations">Configurations</TabsTrigger>
          <TabsTrigger value="restore">Restore</TabsTrigger>
          <TabsTrigger value="migration">Migration</TabsTrigger>
          <TabsTrigger value="storage">Storage</TabsTrigger>
        </TabsList>

        <TabsContent value="executions">
          <Card>
            <CardHeader>
              <CardTitle>Recent Backup Executions</CardTitle>
              <CardDescription>Latest backup operations and their status</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {backups.map((backup) => (
                  <div key={backup.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-4">
                      {getStatusIcon(backup.status)}
                      <div>
                        <div className="font-medium">{backup.backup_type} Backup</div>
                        <div className="text-sm text-gray-500">
                          Started: {new Date(backup.started_at).toLocaleString()}
                        </div>
                        {backup.completed_at && (
                          <div className="text-sm text-gray-500">
                            Duration: {Math.round((new Date(backup.completed_at).getTime() - new Date(backup.started_at).getTime()) / 1000 / 60)}m
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <Badge variant={backup.status === 'completed' ? 'default' : backup.status === 'failed' ? 'destructive' : 'secondary'}>
                        {backup.status}
                      </Badge>
                      {backup.file_size && (
                        <div className="text-sm text-gray-500 mt-1">
                          {formatFileSize(backup.file_size)}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="configurations">
          <Card>
            <CardHeader>
              <CardTitle>Backup Configurations</CardTitle>
              <CardDescription>Manage automated backup schedules and settings</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {configurations.map((config) => (
                  <div key={config.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-4">
                      <Calendar className="w-5 h-5 text-blue-500" />
                      <div>
                        <div className="font-medium">{config.configuration_name}</div>
                        <div className="text-sm text-gray-500">
                          Schedule: {config.schedule_cron} | Retention: {config.retention_days} days
                        </div>
                        <div className="text-sm text-gray-500">
                          Type: {config.backup_type} | Storage: {config.storage_location}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={config.is_active ? 'default' : 'secondary'}>
                        {config.is_active ? 'Active' : 'Inactive'}
                      </Badge>
                      <Button 
                        size="sm" 
                        onClick={() => triggerBackup(config.id)}
                        disabled={!config.is_active}
                      >
                        Run Now
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="restore">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Point-in-Time Recovery</CardTitle>
                <CardDescription>Restore data to a specific point in time</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Select Backup</label>
                  <select className="w-full p-2 border rounded">
                    <option>Select a backup to restore from...</option>
                    {backups.filter(b => b.status === 'completed').map(backup => (
                      <option key={backup.id} value={backup.id}>
                        {backup.backup_type} - {new Date(backup.started_at).toLocaleDateString()}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Restore Type</label>
                  <select className="w-full p-2 border rounded">
                    <option value="full">Full Restore</option>
                    <option value="selective">Selective Restore</option>
                    <option value="tenant_only">Tenant Data Only</option>
                  </select>
                </div>
                <Button className="w-full">
                  <Download className="w-4 h-4 mr-2" />
                  Start Restore
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Active Restore Operations</CardTitle>
                <CardDescription>Currently running restore operations</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center text-gray-500 py-8">
                  No active restore operations
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="migration">
          <Card>
            <CardHeader>
              <CardTitle>Data Migration Tools</CardTitle>
              <CardDescription>Import, export, and migrate tenant data</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Button variant="outline" className="h-24 flex-col">
                  <Upload className="w-6 h-6 mb-2" />
                  Import Data
                </Button>
                <Button variant="outline" className="h-24 flex-col">
                  <Download className="w-6 h-6 mb-2" />
                  Export Data
                </Button>
                <Button variant="outline" className="h-24 flex-col">
                  <RefreshCw className="w-6 h-6 mb-2" />
                  Migrate Tenant
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="storage">
          <Card>
            <CardHeader>
              <CardTitle>Storage Management</CardTitle>
              <CardDescription>Monitor backup storage usage and health</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-4">
                    <HardDrive className="w-5 h-5 text-blue-500" />
                    <div>
                      <div className="font-medium">Primary Storage</div>
                      <div className="text-sm text-gray-500">Local filesystem backup storage</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium">2.3 TB / 5.0 TB</div>
                    <Progress value={46} className="w-24 mt-1" />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

---

## 🔧 API ROUTES

### Backup Trigger API
```typescript
// app/api/admin/backup/trigger/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';
import { triggerBackupJob } from '@/lib/backup/scheduler';

export async function POST(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const { configurationId } = await request.json();
    
    const supabase = createClient();
    
    // Get backup configuration
    const { data: config, error: configError } = await supabase
      .from('backup_configurations')
      .select('*')
      .eq('id', configurationId)
      .eq('is_active', true)
      .single();
    
    if (configError || !config) {
      return NextResponse.json(
        { error: 'Backup configuration not found or inactive' },
        { status: 404 }
      );
    }
    
    // Create backup execution record
    const { data: execution, error: executionError } = await supabase
      .from('backup_executions')
      .insert({
        configuration_id: configurationId,
        backup_type: config.backup_type,
        status: 'pending'
      })
      .select()
      .single();
    
    if (executionError) {
      return NextResponse.json(
        { error: 'Failed to create backup execution record' },
        { status: 500 }
      );
    }
    
    // Trigger backup job asynchronously
    triggerBackupJob(execution.id, config);
    
    return NextResponse.json({ 
      executionId: execution.id,
      status: 'started' 
    });
  } catch (error) {
    console.error('Failed to trigger backup:', error);
    return NextResponse.json(
      { error: 'Failed to trigger backup' },
      { status: 500 }
    );
  }
}
```

### Backup Executions API
```typescript
// app/api/admin/backup/executions/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '50');
    const status = searchParams.get('status');

    let query = supabase
      .from('backup_executions')
      .select(`
        *,
        configuration:backup_configurations(configuration_name)
      `)
      .order('started_at', { ascending: false })
      .limit(limit);

    if (status) {
      query = query.eq('status', status);
    }

    const { data: executions, error } = await query;

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to fetch backup executions' }, { status: 500 });
    }

    return NextResponse.json({ executions: executions || [] });
  } catch (error) {
    console.error('Failed to fetch backup executions:', error);
    return NextResponse.json(
      { error: 'Failed to fetch backup executions' },
      { status: 500 }
    );
  }
}
```

---

## ⚙️ BACKUP UTILITIES

### Backup Scheduler
```typescript
// lib/backup/scheduler.ts
import { createClient } from '@/lib/supabase/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import { createHash } from 'crypto';
import * as fs from 'fs';
import * as path from 'path';

const execAsync = promisify(exec);

export async function triggerBackupJob(executionId: string, config: any) {
  const supabase = createClient();
  
  try {
    // Update status to running
    await supabase
      .from('backup_executions')
      .update({ status: 'running', started_at: new Date().toISOString() })
      .eq('id', executionId);
    
    // Generate backup file path
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFileName = `backup_${config.backup_type}_${timestamp}.sql`;
    const backupPath = path.join(config.storage_location, backupFileName);
    
    // Create backup directory if it doesn't exist
    const backupDir = path.dirname(backupPath);
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }
    
    // Create backup command based on type
    let backupCommand = '';
    
    if (config.backup_type === 'full') {
      backupCommand = `pg_dump "${process.env.DATABASE_URL}" --verbose --clean --no-owner --no-privileges > "${backupPath}"`;
    } else if (config.backup_type === 'incremental') {
      backupCommand = await generateIncrementalBackupCommand(backupPath, config);
    } else if (config.backup_type === 'differential') {
      backupCommand = await generateDifferentialBackupCommand(backupPath, config);
    }
    
    // Execute backup
    console.log('Executing backup command:', backupCommand);
    const { stdout, stderr } = await execAsync(backupCommand);
    
    if (stderr && !stderr.includes('NOTICE')) {
      throw new Error(`Backup command error: ${stderr}`);
    }
    
    // Verify backup file was created
    if (!fs.existsSync(backupPath)) {
      throw new Error('Backup file was not created');
    }
    
    // Get file stats
    const stats = fs.statSync(backupPath);
    const fileSize = stats.size;
    
    if (fileSize === 0) {
      throw new Error('Backup file is empty');
    }
    
    // Calculate checksum
    const checksum = await calculateFileChecksum(backupPath);
    
    // Compress if enabled
    let compressedSize = fileSize;
    let finalPath = backupPath;
    
    if (config.compression_enabled) {
      const compressedPath = `${backupPath}.gz`;
      await execAsync(`gzip "${backupPath}"`);
      
      if (fs.existsSync(compressedPath)) {
        compressedSize = fs.statSync(compressedPath).size;
        finalPath = compressedPath;
      }
    }
    
    // Encrypt if enabled
    if (config.encryption_enabled) {
      finalPath = await encryptBackupFile(finalPath);
    }
    
    // Get backup metadata
    const metadata = await getBackupMetadata(config);
    
    // Update execution record with success
    await supabase
      .from('backup_executions')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        file_path: finalPath,
        file_size: fileSize,
        compressed_size: compressedSize,
        checksum: checksum,
        ...metadata
      })
      .eq('id', executionId);
    
    console.log(`Backup completed successfully: ${finalPath}`);
    
  } catch (error) {
    console.error('Backup job failed:', error);
    
    // Update execution record with error
    await supabase
      .from('backup_executions')
      .update({
        status: 'failed',
        completed_at: new Date().toISOString(),
        error_message: error.message
      })
      .eq('id', executionId);
  }
}

async function generateIncrementalBackupCommand(backupPath: string, config: any): Promise<string> {
  // Find last successful backup
  const supabase = createClient();
  const { data: lastBackup } = await supabase
    .from('backup_executions')
    .select('completed_at')
    .eq('configuration_id', config.id)
    .eq('status', 'completed')
    .order('completed_at', { ascending: false })
    .limit(1)
    .single();
  
  const sinceDate = lastBackup ? lastBackup.completed_at : '1970-01-01';
  
  return `pg_dump "${process.env.DATABASE_URL}" --data-only --inserts --where="updated_at > '${sinceDate}'" > "${backupPath}"`;
}

async function generateDifferentialBackupCommand(backupPath: string, config: any): Promise<string> {
  // Find last full backup
  const supabase = createClient();
  const { data: lastFullBackup } = await supabase
    .from('backup_executions')
    .select('completed_at')
    .eq('configuration_id', config.id)
    .eq('backup_type', 'full')
    .eq('status', 'completed')
    .order('completed_at', { ascending: false })
    .limit(1)
    .single();
  
  const sinceDate = lastFullBackup ? lastFullBackup.completed_at : '1970-01-01';
  
  return `pg_dump "${process.env.DATABASE_URL}" --data-only --inserts --where="updated_at > '${sinceDate}'" > "${backupPath}"`;
}

async function calculateFileChecksum(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256');
    const stream = fs.createReadStream(filePath);
    
    stream.on('data', data => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

async function encryptBackupFile(filePath: string): Promise<string> {
  const encryptionKey = process.env.BACKUP_ENCRYPTION_KEY;
  if (!encryptionKey) {
    throw new Error('BACKUP_ENCRYPTION_KEY environment variable not set');
  }
  
  const encryptedPath = `${filePath}.enc`;
  
  // Use OpenSSL for encryption
  await execAsync(`openssl enc -aes-256-cbc -salt -in "${filePath}" -out "${encryptedPath}" -pass pass:"${encryptionKey}"`);
  
  // Remove original file
  fs.unlinkSync(filePath);
  
  return encryptedPath;
}

async function getBackupMetadata(config: any): Promise<any> {
  const supabase = createClient();
  
  // Get tenant count
  const { count: tenantCount } = await supabase
    .from('tenants')
    .select('*', { count: 'exact' });
  
  // Get user count
  const { count: userCount } = await supabase
    .from('users')
    .select('*', { count: 'exact' });
  
  // Get approximate table count (this is a simplified version)
  const tableCount = 50; // This would be calculated dynamically in a real implementation
  
  return {
    tenant_count: tenantCount || 0,
    record_count: userCount || 0,
    table_count: tableCount
  };
}
```

---

## 📋 TESTING REQUIREMENTS

### Backup Dashboard Tests
```typescript
// __tests__/admin/backup/BackupDashboard.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BackupDashboard } from '@/components/admin/backup/BackupDashboard';

jest.mock('next/navigation');

const mockBackupExecutions = [
  {
    id: '1',
    backup_type: 'full',
    status: 'completed',
    started_at: '2025-01-05T10:00:00Z',
    completed_at: '2025-01-05T10:30:00Z',
    file_size: 1048576
  },
  {
    id: '2',
    backup_type: 'incremental',
    status: 'running',
    started_at: '2025-01-05T11:00:00Z'
  }
];

const mockConfigurations = [
  {
    id: '1',
    configuration_name: 'Daily Full Backup',
    backup_type: 'full',
    schedule_cron: '0 2 * * *',
    retention_days: 30,
    storage_location: '/backups',
    is_active: true
  }
];

describe('BackupDashboard', () => {
  beforeEach(() => {
    global.fetch = jest.fn()
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ executions: mockBackupExecutions })
      })
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ configurations: mockConfigurations })
      });
  });

  it('renders backup management interface', async () => {
    render(<BackupDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Backup Management')).toBeInTheDocument();
    });
  });

  it('displays backup executions', async () => {
    render(<BackupDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('full Backup')).toBeInTheDocument();
      expect(screen.getByText('incremental Backup')).toBeInTheDocument();
    });
  });

  it('displays backup configurations', async () => {
    render(<BackupDashboard />);
    
    // Switch to configurations tab
    fireEvent.click(screen.getByText('Configurations'));
    
    await waitFor(() => {
      expect(screen.getByText('Daily Full Backup')).toBeInTheDocument();
    });
  });

  it('triggers manual backup', async () => {
    const mockTrigger = jest.fn().mockResolvedValue({
      json: () => Promise.resolve({ status: 'started' })
    });
    
    global.fetch = jest.fn()
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ executions: mockBackupExecutions })
      })
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ configurations: mockConfigurations })
      })
      .mockImplementationOnce(mockTrigger);
    
    render(<BackupDashboard />);
    
    // Switch to configurations tab
    fireEvent.click(screen.getByText('Configurations'));
    
    await waitFor(() => {
      const runButton = screen.getByText('Run Now');
      fireEvent.click(runButton);
    });
    
    expect(mockTrigger).toHaveBeenCalledWith('/api/admin/backup/trigger', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ configurationId: '1' })
    });
  });
});
```

### API Tests
```typescript
// __tests__/api/admin/backup/trigger.test.ts
import { POST } from '@/app/api/admin/backup/trigger/route';
import { createMocks } from 'node-mocks-http';

jest.mock('@/lib/auth/require-roles');
jest.mock('@/lib/supabase/server');
jest.mock('@/lib/backup/scheduler');

describe('/api/admin/backup/trigger', () => {
  it('triggers backup for valid configuration', async () => {
    const { req } = createMocks({
      method: 'POST',
      body: { configurationId: 'test-config-id' }
    });
    
    const response = await POST(req as any);
    const data = await response.json();
    
    expect(response.status).toBe(200);
    expect(data).toHaveProperty('executionId');
    expect(data.status).toBe('started');
  });
  
  it('returns 404 for invalid configuration', async () => {
    const { req } = createMocks({
      method: 'POST',
      body: { configurationId: 'invalid-id' }
    });
    
    // Mock supabase to return null
    const response = await POST(req as any);
    
    expect(response.status).toBe(404);
  });
});
```

---

## 🔐 PERMISSIONS & ROLES

### Required Permissions
- **Super Admin**: Full access to all backup features
- **Platform Operator**: Trigger manual backups, view execution status
- **Read-Only Admin**: View backup history and configurations

### Role-based Access Control
```sql
-- Backup management permissions
INSERT INTO role_permissions (role_name, permission) VALUES
('super_admin', 'backup:manage_all'),
('super_admin', 'backup:trigger_manual'),
('super_admin', 'backup:restore_data'),
('super_admin', 'backup:manage_storage'),
('platform_operator', 'backup:trigger_manual'),
('platform_operator', 'backup:view_status'),
('read_only_admin', 'backup:view_history');
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: HIGH