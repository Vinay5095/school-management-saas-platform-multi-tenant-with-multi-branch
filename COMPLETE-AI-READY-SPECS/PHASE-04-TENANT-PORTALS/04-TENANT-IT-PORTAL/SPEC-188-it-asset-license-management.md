# SPEC-188: IT Asset & License Management

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-188  
**Title**: IT Asset & License Management System  
**Phase**: Phase 4 - Tenant Portals  
**Portal**: Tenant IT Portal  
**Category**: Asset Management  
**Priority**: HIGH  
**Status**: ✅ COMPLETE  
**Estimated Time**: 4 hours  
**Dependencies**: SPEC-179  

---

## 📋 DESCRIPTION

Complete IT asset management with hardware inventory, software licenses, warranty tracking, depreciation calculation, asset assignment, maintenance schedules, and vendor management.

---

## 🎯 SUCCESS CRITERIA

- [ ] Asset inventory operational
- [ ] License tracking working
- [ ] Warranty monitoring functional
- [ ] Depreciation calculated
- [ ] Assignment tracking complete
- [ ] Maintenance scheduled
- [ ] Alerts automated
- [ ] All tests passing (85%+ coverage)

---

## 🗄️ DATABASE SCHEMA

```sql
-- IT Assets
CREATE TABLE IF NOT EXISTS it_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Asset details
  asset_name VARCHAR(200) NOT NULL,
  asset_code VARCHAR(50) UNIQUE NOT NULL,
  asset_type VARCHAR(50) NOT NULL, -- hardware, software, network, mobile, peripheral
  asset_category VARCHAR(100), -- laptop, desktop, server, router, license
  
  -- Description
  manufacturer VARCHAR(200),
  model_name VARCHAR(200),
  serial_number VARCHAR(200),
  
  -- Purchase
  purchase_date DATE,
  purchase_cost NUMERIC(15,2),
  purchase_order_number VARCHAR(100),
  vendor_id UUID REFERENCES vendors(id),
  
  -- Warranty
  warranty_start_date DATE,
  warranty_end_date DATE,
  warranty_type VARCHAR(50), -- manufacturer, extended, none
  
  -- Depreciation
  depreciation_method VARCHAR(50) DEFAULT 'straight_line', -- straight_line, declining_balance
  useful_life_years INTEGER DEFAULT 3,
  salvage_value NUMERIC(15,2) DEFAULT 0,
  current_value NUMERIC(15,2),
  
  -- Assignment
  assigned_to UUID REFERENCES staff(id),
  assigned_date DATE,
  assignment_status VARCHAR(50) DEFAULT 'available', -- available, assigned, in_maintenance, retired
  
  -- Location
  location_building VARCHAR(200),
  location_floor VARCHAR(100),
  location_room VARCHAR(100),
  
  -- Configuration
  specifications JSONB, -- {ram: "16GB", storage: "512GB SSD", etc}
  installed_software JSONB,
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, inactive, retired, lost, stolen
  condition VARCHAR(50), -- excellent, good, fair, poor
  
  -- Maintenance
  last_maintenance_date DATE,
  next_maintenance_date DATE,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('active', 'inactive', 'retired', 'lost', 'stolen')),
  CONSTRAINT valid_assignment_status CHECK (assignment_status IN ('available', 'assigned', 'in_maintenance', 'retired'))
);

CREATE INDEX ON it_assets(tenant_id);
CREATE INDEX ON it_assets(asset_type);
CREATE INDEX ON it_assets(assigned_to);
CREATE INDEX ON it_assets(warranty_end_date);

-- Software Licenses
CREATE TABLE IF NOT EXISTS software_licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- License details
  software_name VARCHAR(200) NOT NULL,
  license_key VARCHAR(500),
  license_type VARCHAR(50), -- perpetual, subscription, trial
  
  -- Version
  version_number VARCHAR(50),
  
  -- Licensing
  license_count INTEGER NOT NULL,
  licenses_used INTEGER DEFAULT 0,
  licenses_available INTEGER GENERATED ALWAYS AS (license_count - licenses_used) STORED,
  
  -- Vendor
  vendor_id UUID REFERENCES vendors(id),
  vendor_contact VARCHAR(200),
  
  -- Dates
  purchase_date DATE,
  activation_date DATE,
  expiry_date DATE,
  
  -- Cost
  purchase_cost NUMERIC(15,2),
  annual_renewal_cost NUMERIC(15,2),
  
  -- Renewal
  is_auto_renewal BOOLEAN DEFAULT false,
  renewal_reminder_days INTEGER DEFAULT 30,
  
  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, expired, cancelled
  
  -- Documents
  license_document_url TEXT,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('active', 'expired', 'cancelled'))
);

CREATE INDEX ON software_licenses(tenant_id);
CREATE INDEX ON software_licenses(expiry_date);

-- License Assignments
CREATE TABLE IF NOT EXISTS license_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  license_id UUID NOT NULL REFERENCES software_licenses(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES staff(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Assignment
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  deactivated_date DATE,
  
  -- Installation
  installed_on_asset_id UUID REFERENCES it_assets(id),
  installation_date DATE,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(license_id, employee_id, is_active)
);

CREATE INDEX ON license_assignments(license_id);
CREATE INDEX ON license_assignments(employee_id);

-- Asset Maintenance
CREATE TABLE IF NOT EXISTS asset_maintenance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id UUID NOT NULL REFERENCES it_assets(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Maintenance details
  maintenance_type VARCHAR(50) NOT NULL, -- preventive, corrective, upgrade
  maintenance_title VARCHAR(200) NOT NULL,
  maintenance_description TEXT,
  
  -- Schedule
  scheduled_date DATE NOT NULL,
  completed_date DATE,
  
  -- Assignment
  assigned_to_technician UUID REFERENCES staff(id),
  
  -- Cost
  maintenance_cost NUMERIC(12,2),
  
  -- Status
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
  
  -- Resolution
  resolution_notes TEXT,
  
  -- Parts
  parts_replaced JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled'))
);

CREATE INDEX ON asset_maintenance(asset_id);
CREATE INDEX ON asset_maintenance(scheduled_date, status);

-- Vendors
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  
  -- Vendor details
  vendor_name VARCHAR(200) NOT NULL,
  vendor_code VARCHAR(50) UNIQUE NOT NULL,
  vendor_type VARCHAR(100), -- hardware, software, service_provider
  
  -- Contact
  contact_person VARCHAR(200),
  email VARCHAR(200),
  phone VARCHAR(20),
  address TEXT,
  
  -- Contract
  contract_start_date DATE,
  contract_end_date DATE,
  contract_value NUMERIC(15,2),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Rating
  service_rating INTEGER, -- 1-5
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON vendors(tenant_id);

-- Function to calculate asset depreciation
CREATE OR REPLACE FUNCTION calculate_asset_depreciation(
  p_asset_id UUID
)
RETURNS NUMERIC AS $$
DECLARE
  v_asset RECORD;
  v_years_elapsed NUMERIC;
  v_annual_depreciation NUMERIC;
  v_current_value NUMERIC;
BEGIN
  SELECT * INTO v_asset
  FROM it_assets
  WHERE id = p_asset_id;
  
  IF v_asset.purchase_date IS NULL OR v_asset.purchase_cost IS NULL THEN
    RETURN v_asset.purchase_cost;
  END IF;
  
  -- Calculate years elapsed
  v_years_elapsed := EXTRACT(YEAR FROM AGE(CURRENT_DATE, v_asset.purchase_date)) + 
                     (EXTRACT(MONTH FROM AGE(CURRENT_DATE, v_asset.purchase_date))::NUMERIC / 12);
  
  -- Straight line depreciation
  IF v_asset.depreciation_method = 'straight_line' THEN
    v_annual_depreciation := (v_asset.purchase_cost - COALESCE(v_asset.salvage_value, 0)) / 
                             NULLIF(v_asset.useful_life_years, 0);
    v_current_value := v_asset.purchase_cost - (v_annual_depreciation * v_years_elapsed);
    v_current_value := GREATEST(v_current_value, COALESCE(v_asset.salvage_value, 0));
  ELSE
    -- Default to purchase cost
    v_current_value := v_asset.purchase_cost;
  END IF;
  
  -- Update asset
  UPDATE it_assets
  SET current_value = v_current_value
  WHERE id = p_asset_id;
  
  RETURN v_current_value;
END;
$$ LANGUAGE plpgsql;

-- Function to get expiring warranties and licenses
CREATE OR REPLACE FUNCTION get_expiring_warranties_licenses(
  p_tenant_id UUID,
  p_days_before INTEGER DEFAULT 30
)
RETURNS TABLE (
  item_type VARCHAR,
  item_name VARCHAR,
  expiry_date DATE,
  days_until_expiry INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    'warranty'::VARCHAR,
    ia.asset_name,
    ia.warranty_end_date,
    (ia.warranty_end_date - CURRENT_DATE)::INTEGER
  FROM it_assets ia
  WHERE ia.tenant_id = p_tenant_id
  AND ia.warranty_end_date IS NOT NULL
  AND ia.warranty_end_date <= CURRENT_DATE + (p_days_before || ' days')::INTERVAL
  AND ia.warranty_end_date >= CURRENT_DATE
  AND ia.status = 'active'
  
  UNION ALL
  
  SELECT
    'license'::VARCHAR,
    sl.software_name,
    sl.expiry_date,
    (sl.expiry_date - CURRENT_DATE)::INTEGER
  FROM software_licenses sl
  WHERE sl.tenant_id = p_tenant_id
  AND sl.expiry_date IS NOT NULL
  AND sl.expiry_date <= CURRENT_DATE + (p_days_before || ' days')::INTERVAL
  AND sl.expiry_date >= CURRENT_DATE
  AND sl.status = 'active'
  
  ORDER BY expiry_date;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update license count
CREATE OR REPLACE FUNCTION update_license_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.is_active = true THEN
    UPDATE software_licenses
    SET licenses_used = licenses_used + 1
    WHERE id = NEW.license_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.is_active = true AND NEW.is_active = false THEN
    UPDATE software_licenses
    SET licenses_used = licenses_used - 1
    WHERE id = NEW.license_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_license_usage
  AFTER INSERT OR UPDATE ON license_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_license_count();

-- Enable RLS
ALTER TABLE it_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE software_licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE license_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
```

---

## 💻 IMPLEMENTATION

### API Client (`/lib/api/it-assets.ts`)

```typescript
import { createClient } from '@/lib/supabase/client';

export interface ITAsset {
  id: string;
  assetName: string;
  assetCode: string;
  assetType: string;
  status: string;
  assignedTo?: string;
  currentValue?: number;
}

export interface SoftwareLicense {
  id: string;
  softwareName: string;
  licenseType: string;
  licenseCount: number;
  licensesUsed: number;
  licensesAvailable: number;
  expiryDate?: string;
  status: string;
}

export class ITAssetsAPI {
  private supabase = createClient();

  async createAsset(params: {
    tenantId: string;
    assetName: string;
    assetType: string;
    assetCategory: string;
    manufacturer?: string;
    modelName?: string;
    serialNumber?: string;
    purchaseDate?: Date;
    purchaseCost?: number;
    vendorId?: string;
  }): Promise<ITAsset> {
    const assetCode = `AST-${Date.now()}`;

    const { data, error } = await this.supabase
      .from('it_assets')
      .insert({
        tenant_id: params.tenantId,
        asset_name: params.assetName,
        asset_code: assetCode,
        asset_type: params.assetType,
        asset_category: params.assetCategory,
        manufacturer: params.manufacturer,
        model_name: params.modelName,
        serial_number: params.serialNumber,
        purchase_date: params.purchaseDate?.toISOString().split('T')[0],
        purchase_cost: params.purchaseCost,
        vendor_id: params.vendorId,
        status: 'active',
        assignment_status: 'available',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      assetName: data.asset_name,
      assetCode: data.asset_code,
      assetType: data.asset_type,
      status: data.status,
      currentValue: data.current_value,
    };
  }

  async assignAsset(params: {
    assetId: string;
    employeeId: string;
    assignedDate?: Date;
  }): Promise<void> {
    const { error } = await this.supabase
      .from('it_assets')
      .update({
        assigned_to: params.employeeId,
        assigned_date: (params.assignedDate || new Date()).toISOString().split('T')[0],
        assignment_status: 'assigned',
      })
      .eq('id', params.assetId);

    if (error) throw error;
  }

  async getAssets(params: {
    tenantId: string;
    assetType?: string;
    status?: string;
  }): Promise<ITAsset[]> {
    let query = this.supabase
      .from('it_assets')
      .select('*')
      .eq('tenant_id', params.tenantId);

    if (params.assetType) {
      query = query.eq('asset_type', params.assetType);
    }

    if (params.status) {
      query = query.eq('status', params.status);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map(asset => ({
      id: asset.id,
      assetName: asset.asset_name,
      assetCode: asset.asset_code,
      assetType: asset.asset_type,
      status: asset.status,
      assignedTo: asset.assigned_to,
      currentValue: asset.current_value,
    }));
  }

  async calculateDepreciation(assetId: string): Promise<number> {
    const { data, error } = await this.supabase.rpc('calculate_asset_depreciation', {
      p_asset_id: assetId,
    });

    if (error) throw error;
    return data;
  }

  async createSoftwareLicense(params: {
    tenantId: string;
    softwareName: string;
    licenseType: string;
    licenseCount: number;
    expiryDate?: Date;
    purchaseCost?: number;
    annualRenewalCost?: number;
  }): Promise<SoftwareLicense> {
    const { data, error } = await this.supabase
      .from('software_licenses')
      .insert({
        tenant_id: params.tenantId,
        software_name: params.softwareName,
        license_type: params.licenseType,
        license_count: params.licenseCount,
        expiry_date: params.expiryDate?.toISOString().split('T')[0],
        purchase_cost: params.purchaseCost,
        annual_renewal_cost: params.annualRenewalCost,
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      softwareName: data.software_name,
      licenseType: data.license_type,
      licenseCount: data.license_count,
      licensesUsed: data.licenses_used,
      licensesAvailable: data.licenses_available,
      expiryDate: data.expiry_date,
      status: data.status,
    };
  }

  async assignLicense(params: {
    licenseId: string;
    employeeId: string;
    tenantId: string;
    installedOnAssetId?: string;
  }) {
    const { data, error } = await this.supabase
      .from('license_assignments')
      .insert({
        license_id: params.licenseId,
        employee_id: params.employeeId,
        tenant_id: params.tenantId,
        installed_on_asset_id: params.installedOnAssetId,
        is_active: true,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getLicenses(tenantId: string): Promise<SoftwareLicense[]> {
    const { data, error } = await this.supabase
      .from('software_licenses')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('software_name');

    if (error) throw error;

    return (data || []).map(license => ({
      id: license.id,
      softwareName: license.software_name,
      licenseType: license.license_type,
      licenseCount: license.license_count,
      licensesUsed: license.licenses_used,
      licensesAvailable: license.licenses_available,
      expiryDate: license.expiry_date,
      status: license.status,
    }));
  }

  async scheduleMaintenance(params: {
    assetId: string;
    tenantId: string;
    maintenanceType: string;
    maintenanceTitle: string;
    scheduledDate: Date;
    assignedToTechnician?: string;
  }) {
    const { data, error } = await this.supabase
      .from('asset_maintenance')
      .insert({
        asset_id: params.assetId,
        tenant_id: params.tenantId,
        maintenance_type: params.maintenanceType,
        maintenance_title: params.maintenanceTitle,
        scheduled_date: params.scheduledDate.toISOString().split('T')[0],
        assigned_to_technician: params.assignedToTechnician,
        status: 'scheduled',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getExpiringItems(params: {
    tenantId: string;
    daysBefore?: number;
  }) {
    const { data, error } = await this.supabase.rpc(
      'get_expiring_warranties_licenses',
      {
        p_tenant_id: params.tenantId,
        p_days_before: params.daysBefore || 30,
      }
    );

    if (error) throw error;

    return data.map((item: any) => ({
      itemType: item.item_type,
      itemName: item.item_name,
      expiryDate: item.expiry_date,
      daysUntilExpiry: item.days_until_expiry,
    }));
  }
}

export const itAssetsAPI = new ITAssetsAPI();
```

---

## 🧪 TESTING

```typescript
import { describe, it, expect } from 'vitest';
import { ITAssetsAPI } from '../it-assets';

describe('ITAssetsAPI', () => {
  it('creates IT asset', async () => {
    const api = new ITAssetsAPI();
    const asset = await api.createAsset({
      tenantId: 'test-tenant',
      assetName: 'MacBook Pro',
      assetType: 'hardware',
      assetCategory: 'laptop',
    });

    expect(asset).toHaveProperty('id');
    expect(asset.assetCode).toContain('AST-');
  });
});
```

---

## ✅ VALIDATION CHECKLIST

- [ ] Assets tracked
- [ ] Licenses managed
- [ ] Assignments working
- [ ] Depreciation calculated
- [ ] Maintenance scheduled
- [ ] Expiry alerts sent
- [ ] Tests passing

---

**Status**: ✅ Complete  
**Next**: SPEC-189 (IT Helpdesk)  
**Time**: 4 hours  
**AI-Ready**: 100%
