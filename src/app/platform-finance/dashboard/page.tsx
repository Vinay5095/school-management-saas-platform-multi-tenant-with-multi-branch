/**
 * PHASE 3: FINANCE DASHBOARD - MODERN MINIMALISTIC DESIGN
 */

'use client';

import { TrendingUp, TrendingDown, DollarSign, CreditCard, FileText, AlertCircle } from 'lucide-react';

export default function FinanceDashboard() {
  const metrics = [
    {
      label: 'MRR',
      value: '$24,800',
      change: '+15.2%',
      trend: 'up',
      icon: DollarSign,
      color: 'from-green-500 to-emerald-600'
    },
    {
      label: 'ARR',
      value: '$297,600',
      change: '+12.8%',
      trend: 'up',
      icon: TrendingUp,
      color: 'from-blue-500 to-blue-600'
    },
    {
      label: 'Subscriptions',
      value: '128',
      change: '+8%',
      trend: 'up',
      icon: CreditCard,
      color: 'from-purple-500 to-purple-600'
    },
    {
      label: 'This Month',
      value: '$18,650',
      change: '+18.5%',
      trend: 'up',
      icon: FileText,
      color: 'from-orange-500 to-orange-600'
    },
  ];

  const transactions = [
    {
      type: 'subscription',
      description: 'Monthly subscription',
      customer: 'Greenwood Academy',
      amount: '+$99.00',
      time: '2 hours ago'
    },
    {
      type: 'subscription',
      description: 'Annual subscription',
      customer: 'Riverside School',
      amount: '+$990.00',
      time: '5 hours ago'
    },
    {
      type: 'refund',
      description: 'Refund processed',
      customer: 'Mountain View',
      amount: '-$99.00',
      time: '1 day ago'
    },
    {
      type: 'subscription',
      description: 'Monthly subscription',
      customer: 'Lakeside Elementary',
      amount: '+$99.00',
      time: '1 day ago'
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Finance Dashboard</h1>
        <p className="text-gray-500 mt-2">Platform-wide revenue metrics and financial performance</p>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {metrics.map((metric) => {
          const Icon = metric.icon;
          return (
            <div key={metric.label} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Transactions */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Recent Transactions</h2>
            <button className="text-sm font-medium text-blue-600 hover:text-blue-700">View All</button>
          </div>
          <div className="space-y-4">
            {transactions.map((tx, index) => (
              <div key={index} className="flex items-start gap-4 pb-4 border-b border-gray-100 last:border-0">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-green-100 to-green-200 flex items-center justify-center flex-shrink-0">
                  <DollarSign className="w-5 h-5 text-green-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900">{tx.description}</p>
                  <p className="text-sm text-gray-500 mt-0.5">{tx.customer}</p>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className={`text-sm font-semibold ${tx.amount.startsWith('+') ? 'text-green-600' : 'text-red-600'}`}>
                    {tx.amount}
                  </p>
                  <p className="text-xs text-gray-400 mt-0.5">{tx.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Alerts */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3 mb-4">
              <FileText className="w-5 h-5 text-blue-600 mt-0.5" />
              <div>
                <h3 className="text-sm font-semibold text-gray-900">Pending Invoices</h3>
                <p className="text-xs text-gray-500 mt-1">Awaiting payment</p>
              </div>
            </div>
            <p className="text-3xl font-bold text-gray-900">12</p>
            <p className="text-sm text-gray-500 mt-1">invoices</p>
          </div>

          <div className="bg-gradient-to-br from-red-500 to-pink-500 rounded-2xl p-6 text-white">
            <div className="flex items-start gap-3 mb-4">
              <AlertCircle className="w-5 h-5 mt-0.5" />
              <div>
                <h3 className="text-sm font-semibold">Overdue Amount</h3>
                <p className="text-xs opacity-90 mt-1">Requires follow-up</p>
              </div>
            </div>
            <p className="text-3xl font-bold mb-4">$2,340</p>
            <button className="w-full bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white text-sm font-medium py-2 px-4 rounded-lg transition-colors">
              Send Reminders
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
