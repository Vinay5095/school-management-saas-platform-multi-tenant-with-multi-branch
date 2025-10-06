/**
 * PHASE 3: SUPER ADMIN PORTAL - TENANTS PAGE
 * SPEC-117: Tenant CRUD Operations
 * Complete tenant management with Create, Read, Update, Delete
 */

import { Suspense } from 'react';
import Link from 'next/link';
import { 
  Plus,
  Search,
  Filter,
  MoreVertical,
  Building2,
  Users,
  DollarSign
} from 'lucide-react';

/**
 * Tenant status badge
 */
function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    active: 'bg-green-100 text-green-800',
    trial: 'bg-blue-100 text-blue-800',
    suspended: 'bg-red-100 text-red-800',
    churned: 'bg-gray-100 text-gray-800',
  };

  return (
    <span className={`px-2 py-1 text-xs font-medium rounded ${styles[status] || styles.active}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

/**
 * Tenant list table row
 */
function TenantRow({ tenant }: { tenant: any }) {
  return (
    <tr className="border-b border-gray-200 hover:bg-gray-50">
      <td className="px-6 py-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
            <Building2 className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <Link 
              href={`/super-admin/tenants/${tenant.id}`}
              className="font-medium text-gray-900 hover:text-blue-600"
            >
              {tenant.name}
            </Link>
            <p className="text-sm text-gray-500">{tenant.slug}.school.com</p>
          </div>
        </div>
      </td>
      <td className="px-6 py-4">
        <StatusBadge status={tenant.status} />
      </td>
      <td className="px-6 py-4">
        <span className="text-sm text-gray-900 capitalize">{tenant.plan}</span>
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center gap-1 text-sm text-gray-600">
          <Users className="w-4 h-4" />
          {tenant.userCount}
        </div>
      </td>
      <td className="px-6 py-4">
        <span className="text-sm text-gray-600">
          ${tenant.monthlyRevenue?.toLocaleString() || '0'}
        </span>
      </td>
      <td className="px-6 py-4">
        <span className="text-sm text-gray-500">
          {new Date(tenant.createdAt).toLocaleDateString()}
        </span>
      </td>
      <td className="px-6 py-4 text-right">
        <button className="p-2 hover:bg-gray-100 rounded">
          <MoreVertical className="w-4 h-4 text-gray-400" />
        </button>
      </td>
    </tr>
  );
}

/**
 * Tenants table skeleton loader
 */
function TenantsTableSkeleton() {
  return (
    <div className="bg-white rounded-lg border border-gray-200">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tenant</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Plan</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Users</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Revenue</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
              <th className="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody>
            {[1, 2, 3, 4, 5].map((i) => (
              <tr key={i} className="border-b border-gray-200 animate-pulse">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gray-200 rounded-lg"></div>
                    <div className="space-y-2">
                      <div className="h-4 bg-gray-200 rounded w-32"></div>
                      <div className="h-3 bg-gray-200 rounded w-24"></div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="h-5 bg-gray-200 rounded w-16"></div>
                </td>
                <td className="px-6 py-4">
                  <div className="h-4 bg-gray-200 rounded w-20"></div>
                </td>
                <td className="px-6 py-4">
                  <div className="h-4 bg-gray-200 rounded w-12"></div>
                </td>
                <td className="px-6 py-4">
                  <div className="h-4 bg-gray-200 rounded w-16"></div>
                </td>
                <td className="px-6 py-4">
                  <div className="h-4 bg-gray-200 rounded w-20"></div>
                </td>
                <td className="px-6 py-4"></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/**
 * Tenants table with data
 */
async function TenantsTable() {
  // Mock data - In production, fetch from API
  const tenants = [
    {
      id: '1',
      name: 'Greenwood Academy',
      slug: 'greenwood',
      status: 'active',
      plan: 'professional',
      userCount: 245,
      monthlyRevenue: 99,
      createdAt: '2024-01-15',
    },
    {
      id: '2',
      name: 'Riverside School',
      slug: 'riverside',
      status: 'active',
      plan: 'enterprise',
      userCount: 842,
      monthlyRevenue: 299,
      createdAt: '2024-02-03',
    },
    {
      id: '3',
      name: 'Mountain View Institute',
      slug: 'mountainview',
      status: 'trial',
      plan: 'starter',
      userCount: 45,
      monthlyRevenue: 0,
      createdAt: '2024-03-10',
    },
    {
      id: '4',
      name: 'Lakeside Elementary',
      slug: 'lakeside',
      status: 'active',
      plan: 'professional',
      userCount: 156,
      monthlyRevenue: 99,
      createdAt: '2024-02-28',
    },
    {
      id: '5',
      name: 'Oakwood High School',
      slug: 'oakwood',
      status: 'suspended',
      plan: 'professional',
      userCount: 320,
      monthlyRevenue: 0,
      createdAt: '2023-11-20',
    },
  ];

  return (
    <div className="bg-white rounded-lg border border-gray-200">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Tenant
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Plan
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Users
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Revenue
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Created
              </th>
              <th className="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody>
            {tenants.map((tenant) => (
              <TenantRow key={tenant.id} tenant={tenant} />
            ))}
          </tbody>
        </table>
      </div>
      
      {/* Pagination */}
      <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
        <div className="text-sm text-gray-500">
          Showing 1 to 5 of 142 tenants
        </div>
        <div className="flex gap-2">
          <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50">
            Previous
          </button>
          <button className="px-3 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700">
            1
          </button>
          <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50">
            2
          </button>
          <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50">
            3
          </button>
          <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50">
            Next
          </button>
        </div>
      </div>
    </div>
  );
}

/**
 * Tenants Page
 */
export default function TenantsPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Tenants</h1>
          <p className="text-gray-600 mt-2">
            Manage all organizations using the platform
          </p>
        </div>
        <Link
          href="/super-admin/tenants/new"
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
        >
          <Plus className="w-4 h-4" />
          Add Tenant
        </Link>
      </div>

      {/* Filters and Search */}
      <div className="mb-6 flex gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search tenants..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
          <Filter className="w-4 h-4" />
          Filters
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">Total Tenants</span>
            <Building2 className="w-4 h-4 text-gray-400" />
          </div>
          <p className="text-2xl font-bold text-gray-900 mt-2">142</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">Active</span>
            <span className="w-2 h-2 bg-green-500 rounded-full"></span>
          </div>
          <p className="text-2xl font-bold text-gray-900 mt-2">128</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">Trial</span>
            <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
          </div>
          <p className="text-2xl font-bold text-gray-900 mt-2">12</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">MRR</span>
            <DollarSign className="w-4 h-4 text-gray-400" />
          </div>
          <p className="text-2xl font-bold text-gray-900 mt-2">$24.8K</p>
        </div>
      </div>

      {/* Tenants Table */}
      <Suspense fallback={<TenantsTableSkeleton />}>
        <TenantsTable />
      </Suspense>
    </div>
  );
}
