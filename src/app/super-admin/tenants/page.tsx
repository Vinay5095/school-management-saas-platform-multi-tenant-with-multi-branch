/**
 * PHASE 3: TENANT MANAGEMENT - MODERN MINIMALISTIC DESIGN
 * Clean tenant management interface
 */

'use client';

import { Search, Filter, Plus, MoreVertical, Building2, Users } from 'lucide-react';

export default function TenantsPage() {
  const tenants = [
    {
      id: 1,
      name: 'Greenwood Academy',
      domain: 'greenwood.school.com',
      status: 'active',
      plan: 'Professional',
      users: 245,
      revenue: '$99',
      created: '1/15/2024'
    },
    {
      id: 2,
      name: 'Riverside School',
      domain: 'riverside.school.com',
      status: 'active',
      plan: 'Enterprise',
      users: 842,
      revenue: '$299',
      created: '2/3/2024'
    },
    {
      id: 3,
      name: 'Mountain View Institute',
      domain: 'mountainview.school.com',
      status: 'trial',
      plan: 'Starter',
      users: 45,
      revenue: '$0',
      created: '3/10/2024'
    },
    {
      id: 4,
      name: 'Lakeside Elementary',
      domain: 'lakeside.school.com',
      status: 'active',
      plan: 'Professional',
      users: 156,
      revenue: '$99',
      created: '2/28/2024'
    },
  ];

  const stats = [
    { label: 'Total', value: '142' },
    { label: 'Active', value: '128' },
    { label: 'Trial', value: '12' },
    { label: 'MRR', value: '$24.8K' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Tenants</h1>
          <p className="text-gray-500 mt-2">Manage all organizations using the platform</p>
        </div>
        <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2.5 rounded-xl hover:bg-blue-700 transition-colors font-medium">
          <Plus className="w-5 h-5" />
          Add Tenant
        </button>
      </div>

      {/* Stats Bar */}
      <div className="grid grid-cols-4 gap-4">
        {stats.map((stat) => (
          <div key={stat.label} className="bg-white rounded-xl p-4 border border-gray-100">
            <p className="text-sm text-gray-500">{stat.label}</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
          </div>
        ))}
      </div>

      {/* Search and Filter */}
      <div className="flex items-center gap-4">
        <div className="flex-1 flex items-center gap-3 px-4 py-2.5 bg-white rounded-xl border border-gray-200">
          <Search className="w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search tenants..."
            className="flex-1 border-none outline-none text-sm bg-transparent"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 bg-white rounded-xl border border-gray-200 hover:bg-gray-50 transition-colors">
          <Filter className="w-5 h-5 text-gray-600" />
          <span className="text-sm font-medium text-gray-700">Filters</span>
        </button>
      </div>

      {/* Tenants Table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Tenant
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Plan
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Users
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Revenue
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Created
                </th>
                <th className="px-6 py-4"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {tenants.map((tenant) => (
                <tr key={tenant.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
                        <Building2 className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-gray-900">{tenant.name}</p>
                        <p className="text-xs text-gray-500">{tenant.domain}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${
                      tenant.status === 'active'
                        ? 'bg-green-100 text-green-700'
                        : 'bg-yellow-100 text-yellow-700'
                    }`}>
                      {tenant.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-900">{tenant.plan}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <Users className="w-4 h-4 text-gray-400" />
                      <span className="text-sm text-gray-900">{tenant.users}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm font-medium text-gray-900">{tenant.revenue}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-600">{tenant.created}</span>
                  </td>
                  <td className="px-6 py-4">
                    <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                      <MoreVertical className="w-4 h-4 text-gray-400" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
