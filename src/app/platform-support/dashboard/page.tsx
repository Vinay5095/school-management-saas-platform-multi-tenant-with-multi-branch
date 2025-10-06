/**
 * PHASE 3: SUPPORT DASHBOARD - MODERN MINIMALISTIC DESIGN
 */

'use client';

import { TrendingUp, TrendingDown, Ticket, CheckCircle, Clock, Star, MessageSquare, Users } from 'lucide-react';

export default function SupportDashboard() {
  const metrics = [
    {
      label: 'Open Tickets',
      value: '23',
      change: '-12%',
      trend: 'down',
      icon: Ticket,
      color: 'from-red-500 to-orange-600'
    },
    {
      label: 'Resolved Today',
      value: '42',
      change: '+18%',
      trend: 'up',
      icon: CheckCircle,
      color: 'from-green-500 to-emerald-600'
    },
    {
      label: 'Avg Response',
      value: '2.4h',
      change: '-8%',
      trend: 'down',
      icon: Clock,
      color: 'from-blue-500 to-blue-600'
    },
    {
      label: 'Satisfaction',
      value: '4.6/5',
      change: '+0.2',
      trend: 'up',
      icon: Star,
      color: 'from-yellow-500 to-orange-600'
    },
  ];

  const tickets = [
    {
      title: 'Unable to login to dashboard',
      tenant: 'Greenwood Academy',
      priority: 'urgent',
      time: '5 min ago'
    },
    {
      title: 'Feature request: Custom reports',
      tenant: 'Riverside School',
      priority: 'low',
      time: '30 min ago'
    },
    {
      title: 'Payment failed error',
      tenant: 'Mountain View',
      priority: 'high',
      time: '1 hour ago'
    },
    {
      title: 'How to add new users?',
      tenant: 'Lakeside Elementary',
      priority: 'medium',
      time: '2 hours ago'
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Support Dashboard</h1>
        <p className="text-gray-500 mt-2">Real-time support metrics and ticket analytics</p>
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
                      <TrendingDown className="w-4 h-4 text-green-500" />
                    )}
                    <span className="text-sm font-medium text-green-600">{metric.change}</span>
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
        {/* Recent Tickets */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Recent Tickets</h2>
            <button className="text-sm font-medium text-blue-600 hover:text-blue-700">View All</button>
          </div>
          <div className="space-y-4">
            {tickets.map((ticket, index) => (
              <div key={index} className="flex items-start gap-4 pb-4 border-b border-gray-100 last:border-0">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-purple-100 to-pink-200 flex items-center justify-center flex-shrink-0">
                  <Ticket className="w-5 h-5 text-purple-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900">{ticket.title}</p>
                  <p className="text-sm text-gray-500 mt-0.5">{ticket.tenant} • {ticket.time}</p>
                </div>
                <span className={`px-2.5 py-1 rounded-full text-xs font-medium flex-shrink-0 ${
                  ticket.priority === 'urgent'
                    ? 'bg-red-100 text-red-700'
                    : ticket.priority === 'high'
                    ? 'bg-orange-100 text-orange-700'
                    : ticket.priority === 'medium'
                    ? 'bg-yellow-100 text-yellow-700'
                    : 'bg-gray-100 text-gray-700'
                }`}>
                  {ticket.priority.toUpperCase()}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Stats */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3 mb-4">
              <MessageSquare className="w-5 h-5 text-blue-600 mt-0.5" />
              <div>
                <h3 className="text-sm font-semibold text-gray-900">Active Chats</h3>
                <p className="text-xs text-gray-500 mt-1">Live sessions</p>
              </div>
            </div>
            <p className="text-3xl font-bold text-gray-900">8</p>
            <p className="text-sm text-gray-500 mt-1">ongoing</p>
          </div>

          <div className="bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl p-6 text-white">
            <div className="flex items-start gap-3 mb-4">
              <Users className="w-5 h-5 mt-0.5" />
              <div>
                <h3 className="text-sm font-semibold">Agents Online</h3>
                <p className="text-xs opacity-90 mt-1">Available now</p>
              </div>
            </div>
            <p className="text-3xl font-bold mb-1">12</p>
            <p className="text-sm opacity-90">of 15</p>
          </div>
        </div>
      </div>
    </div>
  );
}
