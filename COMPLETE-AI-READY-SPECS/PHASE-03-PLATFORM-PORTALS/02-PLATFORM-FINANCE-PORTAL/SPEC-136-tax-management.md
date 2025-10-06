# SPEC-136: Tax Management and Compliance
## Tax Calculation, Collection, and Reporting

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 4-5 hours  
> **Dependencies**: SPEC-132, Phase 1

---

## 📋 OVERVIEW

### Purpose
Tax management system for calculating, collecting, and reporting taxes based on customer location, including support for VAT, GST, and sales tax.

### Key Features
- ✅ Automatic tax calculation
- ✅ Tax rate configuration
- ✅ VAT/GST support
- ✅ Tax exemption management
- ✅ Tax ID validation
- ✅ Reverse charge mechanism
- ✅ Tax reports and filings
- ✅ Multi-jurisdiction support
- ✅ Tax rate history
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Tax jurisdictions table
CREATE TABLE tax_jurisdictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE, -- 'US-NY', 'CA-ON', 'GB', etc.
  jurisdiction_type TEXT NOT NULL CHECK (jurisdiction_type IN ('country', 'state', 'province', 'city')),
  parent_jurisdiction_id UUID REFERENCES tax_jurisdictions(id),
  
  -- Tax settings
  is_active BOOLEAN DEFAULT TRUE,
  requires_tax_id BOOLEAN DEFAULT FALSE,
  reverse_charge_applicable BOOLEAN DEFAULT FALSE,
  
  -- Thresholds
  tax_threshold_amount DECIMAL(12, 2) DEFAULT 0,
  registration_threshold DECIMAL(12, 2),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tax rates table
CREATE TABLE tax_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(id) ON DELETE CASCADE,
  
  -- Rate details
  tax_type TEXT NOT NULL CHECK (tax_type IN ('vat', 'gst', 'sales_tax', 'service_tax')),
  rate DECIMAL(5, 4) NOT NULL, -- 0.2000 for 20%
  
  -- Applicability
  applies_to TEXT[] NOT NULL DEFAULT ARRAY['all'],
  
  -- Validity period
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Metadata
  description TEXT,
  regulation_reference TEXT,
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tax exemptions table
CREATE TABLE tax_exemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  jurisdiction_id UUID REFERENCES tax_jurisdictions(id),
  
  -- Exemption details
  exemption_type TEXT NOT NULL CHECK (exemption_type IN ('nonprofit', 'government', 'educational', 'resale', 'export')),
  tax_id_number TEXT,
  exemption_certificate_url TEXT,
  
  -- Validity
  valid_from DATE NOT NULL,
  valid_to DATE,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'expired')) DEFAULT 'pending',
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Function to calculate tax
CREATE OR REPLACE FUNCTION calculate_tax(
  p_amount DECIMAL(12, 2),
  p_customer_country TEXT,
  p_customer_state TEXT DEFAULT NULL,
  p_customer_tax_id TEXT DEFAULT NULL,
  p_product_type TEXT DEFAULT 'software'
)
RETURNS JSONB AS $$
DECLARE
  v_jurisdiction RECORD;
  v_tax_rate RECORD;
  v_tax_amount DECIMAL(12, 2) := 0;
  v_applicable_rate DECIMAL(5, 4) := 0;
  v_is_exempt BOOLEAN := FALSE;
BEGIN
  -- Tax calculation logic implementation
  -- Returns JSON with tax amount, rate, jurisdiction, etc.
  
  RETURN jsonb_build_object(
    'tax_amount', v_tax_amount,
    'tax_rate', v_applicable_rate,
    'jurisdiction', COALESCE(v_jurisdiction.name, 'Unknown'),
    'exempt', v_is_exempt
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔌 API ENDPOINTS

### POST /api/platform/tax/calculate
**Calculate tax for given parameters**
```typescript
interface CalculateTaxRequest {
  amount: number;
  customerCountry: string;
  customerState?: string;
  customerTaxId?: string;
  productType?: string;
  calculationDate?: string;
}

interface CalculateTaxResponse {
  taxAmount: number;
  taxRate: number;
  jurisdiction: string;
  jurisdictionId?: string;
  exempt: boolean;
  reason?: string;
}
```

### GET /api/platform/tax/jurisdictions
**List tax jurisdictions**
```typescript
interface ListTaxJurisdictionsResponse {
  jurisdictions: Array<{
    id: string;
    name: string;
    code: string;
    type: string;
    isActive: boolean;
    currentTaxRate?: number;
    requiresTaxId: boolean;
  }>;
}
```

---

## 🎨 REACT COMPONENTS

### TaxManagementDashboard
**Main tax management interface**
```typescript
const TaxManagementDashboard: React.FC = () => {
  const [jurisdictions, setJurisdictions] = useState<Array<any>>([]);
  const [exemptions, setExemptions] = useState<Array<any>>([]);
  const [loading, setLoading] = useState(true);
  
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Tax Management</h1>
          <p className="text-sm text-gray-500">
            Manage tax rates, jurisdictions, and exemptions
          </p>
        </div>
        
        <Button onClick={() => setShowTaxCalculator(true)}>
          <Calculator className="h-4 w-4 mr-2" />
          Tax Calculator
        </Button>
      </div>
      
      {/* Tax jurisdictions, rates, and exemptions management */}
    </div>
  );
};
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM
