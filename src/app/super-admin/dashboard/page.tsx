/**
 * PHASE 3: SUPER ADMIN PORTAL - DASHBOARD PAGE
 * SPEC-116: Platform Dashboard Overview
 * Real-time platform metrics and key performance indicators
 */

import { Suspense } from 'react';
import { 
  Building2, 
  Users, 
  DollarSign, 
  Ticket,
  TrendingUp,
  TrendingDown,
  Activity
} from 'lucide-react';

/**
 * Dashboard statistics card component
 */
function StatCard({ 
  title, 
  value, 
  change, 
  changeType,
  icon: Icon 
}: { 
  title: string; 
  value: string | number; 
  change?: string;
  changeType?: 'increase' | 'decrease';
  icon: any;
}) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm font-medium text-gray-600">{title}</span>
        <div className="p-2 bg-blue-50 rounded-lg">
          <Icon className="w-5 h-5 text-blue-600" />
        </div>
      </div>
      <div className="flex items-end justify-between">
        <div>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          {change && (
            <div className="flex items-center gap-1 mt-1">
              {changeType === 'increase' ? (
                <TrendingUp className="w-4 h-4 text-green-500" />
              ) : (
                <TrendingDown className="w-4 h-4 text-red-500" />
              )}
              <span className={`text-sm font-medium ${
                changeType === 'increase' ? 'text-green-600' : 'text-red-600'
              }`}>
                {change}
              </span>
              <span className="text-sm text-gray-500">vs last month</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * Recent activity item
 */
function ActivityItem({ 
  action, 
  description, 
  time 
}: { 
  action: string; 
  description: string; 
  time: string;
}) {
  return (
    <div className="flex items-start gap-3 py-3 border-b border-gray-100 last:border-0">
      <div className="p-1.5 bg-blue-50 rounded">
        <Activity className="w-4 h-4 text-blue-600" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900">{action}</p>
        <p className="text-sm text-gray-500 truncate">{description}</p>
      </div>
      <span className="text-xs text-gray-400 whitespace-nowrap">{time}</span>
    </div>
  );
}

/**
 * Dashboard loading state
 */
function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="bg-white rounded-lg border border-gray-200 p-6 animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-1/2 mb-4"></div>
            <div className="h-8 bg-gray-200 rounded w-3/4"></div>
          </div>
        ))}
      </div>
    </div>
  );
}

/**
 * Main dashboard component with data fetching
 */
async function DashboardContent() {
  // Mock data - In production, this would fetch from API
  const stats = {
    totalTenants: 142,
    activeTenants: 128,
    totalUsers: 8453,
    currentMrr: 24800,
    openTickets: 23,
  };

  const recentActivity = [
    {
      action: 'New Tenant Created',
      description: 'Greenwood Academy signed up',
      time: '2 min ago'
    },
    {
      action: 'Subscription Upgraded',
      description: 'Riverside School upgraded to Professional',
      time: '15 min ago'
    },
    {
      action: 'Support Ticket Resolved',
      description: 'Ticket #1842 closed',
      time: '1 hour ago'
    },
    {
      action: 'Payment Received',
      description: 'Invoice #INV-2024-0234 paid',
      time: '2 hours ago'
    },
  ];

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Tenants"
          value={stats.totalTenants}
          change="+12%"
          changeType="increase"
          icon={Building2}
        />
        <StatCard
          title="Active Tenants"
          value={stats.activeTenants}
          change="+8%"
          changeType="increase"
          icon={Activity}
        />
        <StatCard
          title="Total Users"
          value={stats.totalUsers.toLocaleString()}
          change="+18%"
          changeType="increase"
          icon={Users}
        />
        <StatCard
          title="Monthly Revenue"
          value={`$${stats.currentMrr.toLocaleString()}`}
          change="+15%"
          changeType="increase"
          icon={DollarSign}
        />
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Activity */}
        <div className="lg:col-span-2 bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
            <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
              View All
            </button>
          </div>
          <div className="space-y-1">
            {recentActivity.map((activity, index) => (
              <ActivityItem key={index} {...activity} />
            ))}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="space-y-6">
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Open Tickets</h2>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-bold text-gray-900">{stats.openTickets}</span>
              <span className="text-sm text-gray-500">requiring attention</span>
            </div>
            <button className="mt-4 w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium">
              View Tickets
            </button>
          </div>

          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">System Health</h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Database</span>
                <span className="px-2 py-1 bg-green-100 text-green-800 text-xs font-medium rounded">
                  Healthy
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">API Server</span>
                <span className="px-2 py-1 bg-green-100 text-green-800 text-xs font-medium rounded">
                  Healthy
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Storage</span>
                <span className="px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-medium rounded">
                  Warning
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trend</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Chart Placeholder - Integrate with charting library
          </div>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">User Growth</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Chart Placeholder - Integrate with charting library
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Super Admin Dashboard Page
 */
export default function SuperAdminDashboardPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Platform Dashboard</h1>
        <p className="text-gray-600 mt-2">
          Real-time metrics and key performance indicators for the entire platform
        </p>
      </div>

      {/* Dashboard Content */}
      <Suspense fallback={<DashboardSkeleton />}>
        <DashboardContent />
      </Suspense>
    </div>
  );
}
