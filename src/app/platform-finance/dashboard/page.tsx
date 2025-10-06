/**
 * PHASE 3: PLATFORM FINANCE PORTAL - DASHBOARD
 * SPEC-131: Revenue Dashboard
 * Real-time revenue metrics and financial performance
 */

import { Suspense } from 'react';
import { 
  DollarSign, 
  TrendingUp, 
  TrendingDown,
  CreditCard,
  FileText,
  AlertCircle
} from 'lucide-react';

/**
 * Revenue metric card
 */
function RevenueCard({ 
  title, 
  value, 
  change, 
  changeType,
  icon: Icon 
}: { 
  title: string; 
  value: string; 
  change?: string;
  changeType?: 'increase' | 'decrease';
  icon: any;
}) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm font-medium text-gray-600">{title}</span>
        <div className="p-2 bg-green-50 rounded-lg">
          <Icon className="w-5 h-5 text-green-600" />
        </div>
      </div>
      <div className="flex items-end justify-between">
        <div>
          <p className="text-3xl font-bold text-gray-900">{value}</p>
          {change && (
            <div className="flex items-center gap-1 mt-2">
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
 * Recent transaction row
 */
function TransactionRow({ transaction }: { transaction: any }) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex items-center gap-3">
        <div className={`p-2 rounded-lg ${
          transaction.type === 'payment' ? 'bg-green-50' : 'bg-blue-50'
        }`}>
          <DollarSign className={`w-4 h-4 ${
            transaction.type === 'payment' ? 'text-green-600' : 'text-blue-600'
          }`} />
        </div>
        <div>
          <p className="text-sm font-medium text-gray-900">{transaction.description}</p>
          <p className="text-xs text-gray-500">{transaction.tenant}</p>
        </div>
      </div>
      <div className="text-right">
        <p className="text-sm font-semibold text-gray-900">
          {transaction.type === 'payment' ? '+' : ''}{transaction.amount}
        </p>
        <p className="text-xs text-gray-500">{transaction.date}</p>
      </div>
    </div>
  );
}

/**
 * Dashboard content with data
 */
async function FinanceDashboardContent() {
  // Mock data - In production, fetch from API
  const metrics = {
    mrr: 24800,
    arr: 297600,
    activeSubscriptions: 128,
    totalRevenue: 18650,
    pendingInvoices: 12,
    overdueAmount: 2340,
  };

  const recentTransactions = [
    {
      id: '1',
      type: 'payment',
      description: 'Monthly subscription payment',
      tenant: 'Greenwood Academy',
      amount: '$99.00',
      date: '2 hours ago'
    },
    {
      id: '2',
      type: 'payment',
      description: 'Annual subscription payment',
      tenant: 'Riverside School',
      amount: '$990.00',
      date: '5 hours ago'
    },
    {
      id: '3',
      type: 'refund',
      description: 'Refund processed',
      tenant: 'Mountain View',
      amount: '-$99.00',
      date: '1 day ago'
    },
    {
      id: '4',
      type: 'payment',
      description: 'Monthly subscription payment',
      tenant: 'Lakeside Elementary',
      amount: '$99.00',
      date: '1 day ago'
    },
  ];

  return (
    <div className="space-y-6">
      {/* Revenue Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <RevenueCard
          title="Monthly Recurring Revenue"
          value={`$${metrics.mrr.toLocaleString()}`}
          change="+15.2%"
          changeType="increase"
          icon={DollarSign}
        />
        <RevenueCard
          title="Annual Recurring Revenue"
          value={`$${metrics.arr.toLocaleString()}`}
          change="+12.8%"
          changeType="increase"
          icon={TrendingUp}
        />
        <RevenueCard
          title="Active Subscriptions"
          value={metrics.activeSubscriptions.toString()}
          change="+8%"
          changeType="increase"
          icon={CreditCard}
        />
        <RevenueCard
          title="This Month Revenue"
          value={`$${metrics.totalRevenue.toLocaleString()}`}
          change="+18.5%"
          changeType="increase"
          icon={FileText}
        />
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Transactions */}
        <div className="lg:col-span-2 bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Recent Transactions</h2>
            <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
              View All
            </button>
          </div>
          <div className="space-y-1">
            {recentTransactions.map((transaction) => (
              <TransactionRow key={transaction.id} transaction={transaction} />
            ))}
          </div>
        </div>

        {/* Alerts & Actions */}
        <div className="space-y-4">
          {/* Pending Invoices */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-orange-50 rounded-lg">
                <AlertCircle className="w-5 h-5 text-orange-600" />
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-900">Pending Invoices</h3>
                <p className="text-xs text-gray-500">Awaiting payment</p>
              </div>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-gray-900">{metrics.pendingInvoices}</span>
              <span className="text-sm text-gray-500">invoices</span>
            </div>
          </div>

          {/* Overdue Amount */}
          <div className="bg-white rounded-lg border border-red-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-red-50 rounded-lg">
                <DollarSign className="w-5 h-5 text-red-600" />
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-900">Overdue Amount</h3>
                <p className="text-xs text-gray-500">Requires follow-up</p>
              </div>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-red-600">
                ${metrics.overdueAmount.toLocaleString()}
              </span>
            </div>
            <button className="mt-4 w-full px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors text-sm font-medium">
              Send Reminders
            </button>
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trend</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Revenue chart - Integrate charting library
          </div>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Revenue by Plan</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Plan distribution chart - Integrate charting library
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Finance Dashboard Page
 */
export default function PlatformFinanceDashboardPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="pb-5 border-b border-gray-200">
        <h1 className="text-3xl font-bold text-gray-900">Finance Dashboard</h1>
        <p className="text-gray-600 mt-2">
          Platform-wide revenue metrics and financial performance
        </p>
      </div>

      {/* Dashboard Content */}
      <Suspense fallback={<div>Loading...</div>}>
        <FinanceDashboardContent />
      </Suspense>
    </div>
  );
}
