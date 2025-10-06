/**
 * PHASE 3: SUPER ADMIN DASHBOARD - MODERN MINIMALISTIC DESIGN
 * Clean metrics-focused dashboard with contemporary styling
 */

'use client';

import { TrendingUp, TrendingDown, Building2, Users, DollarSign, Activity } from 'lucide-react';

export default function SuperAdminDashboard() {
  const metrics = [
    {
      label: 'Total Tenants',
      value: '142',
      change: '+12%',
      trend: 'up',
      icon: Building2,
      color: 'from-blue-500 to-blue-600'
    },
    {
      label: 'Active Users',
      value: '8,453',
      change: '+18%',
      trend: 'up',
      icon: Users,
      color: 'from-purple-500 to-purple-600'
    },
    {
      label: 'Monthly Revenue',
      value: '$24.8K',
      change: '+15%',
      trend: 'up',
      icon: DollarSign,
      color: 'from-green-500 to-green-600'
    },
    {
      label: 'System Health',
      value: '99.9%',
      change: '+0.1%',
      trend: 'up',
      icon: Activity,
      color: 'from-orange-500 to-orange-600'
    },
  ];

  const activities = [
    {
      title: 'New Tenant Created',
      description: 'Greenwood Academy signed up',
      time: '2 min ago',
      type: 'tenant'
    },
    {
      title: 'Subscription Upgraded',
      description: 'Riverside School upgraded to Professional',
      time: '15 min ago',
      type: 'subscription'
    },
    {
      title: 'Support Ticket Resolved',
      description: 'Ticket #1842 closed',
      time: '1 hour ago',
      type: 'support'
    },
    {
      title: 'Payment Received',
      description: 'Invoice #INV-2024-0234 paid',
      time: '2 hours ago',
      type: 'payment'
    },
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500 mt-2">Welcome back! Here's what's happening with your platform today.</p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {metrics.map((metric) => {
          const Icon = metric.icon;
          return (
            <div key={metric.label} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-500">{metric.label}</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{metric.value}</p>
                  <div className="flex items-center gap-1 mt-3">
                    {metric.trend === 'up' ? (
                      <TrendingUp className="w-4 h-4 text-green-500" />
                    ) : (
                      <TrendingDown className="w-4 h-4 text-red-500" />
                    )}
                    <span className={`text-sm font-medium ${metric.trend === 'up' ? 'text-green-600' : 'text-red-600'}`}>
                      {metric.change}
                    </span>
                    <span className="text-sm text-gray-500 ml-1">vs last month</span>
                  </div>
                </div>
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${metric.color} flex items-center justify-center`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Activity */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Recent Activity</h2>
            <button className="text-sm font-medium text-blue-600 hover:text-blue-700">View All</button>
          </div>
          <div className="space-y-4">
            {activities.map((activity, index) => (
              <div key={index} className="flex items-start gap-4 pb-4 border-b border-gray-100 last:border-0">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center flex-shrink-0">
                  <Activity className="w-5 h-5 text-gray-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900">{activity.title}</p>
                  <p className="text-sm text-gray-500 mt-0.5">{activity.description}</p>
                </div>
                <span className="text-xs text-gray-400 flex-shrink-0">{activity.time}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="space-y-6">
          {/* System Health */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">System Health</h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Database</span>
                <span className="text-sm font-medium text-green-600">Healthy</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">API Server</span>
                <span className="text-sm font-medium text-green-600">Healthy</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Storage</span>
                <span className="text-sm font-medium text-yellow-600">Warning</span>
              </div>
            </div>
          </div>

          {/* Open Tickets */}
          <div className="bg-gradient-to-br from-orange-500 to-red-500 rounded-2xl p-6 text-white">
            <h3 className="text-lg font-semibold mb-2">Open Tickets</h3>
            <p className="text-3xl font-bold mb-1">23</p>
            <p className="text-sm opacity-90 mb-4">requiring attention</p>
            <button className="w-full bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white text-sm font-medium py-2 px-4 rounded-lg transition-colors">
              View Tickets
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
