/**
 * PHASE 3: PLATFORM SUPPORT PORTAL - DASHBOARD
 * SPEC-139: Support Analytics Dashboard
 * Real-time support metrics and ticket analytics
 */

import { Suspense } from 'react';
import { 
  Ticket, 
  Clock, 
  CheckCircle2,
  TrendingUp,
  TrendingDown,
  MessageSquare,
  Users
} from 'lucide-react';

/**
 * Support metric card
 */
function SupportMetricCard({ 
  title, 
  value, 
  change, 
  changeType,
  icon: Icon,
  color = 'blue'
}: { 
  title: string; 
  value: string | number; 
  change?: string;
  changeType?: 'increase' | 'decrease';
  icon: any;
  color?: 'blue' | 'green' | 'orange' | 'red';
}) {
  const colorClasses = {
    blue: { bg: 'bg-blue-50', text: 'text-blue-600' },
    green: { bg: 'bg-green-50', text: 'text-green-600' },
    orange: { bg: 'bg-orange-50', text: 'text-orange-600' },
    red: { bg: 'bg-red-50', text: 'text-red-600' },
  };

  const colorClass = colorClasses[color];

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm font-medium text-gray-600">{title}</span>
        <div className={`p-2 ${colorClass.bg} rounded-lg`}>
          <Icon className={`w-5 h-5 ${colorClass.text}`} />
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
              <span className="text-sm text-gray-500">vs last week</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * Priority badge
 */
function PriorityBadge({ priority }: { priority: string }) {
  const styles: Record<string, string> = {
    urgent: 'bg-red-100 text-red-800',
    high: 'bg-orange-100 text-orange-800',
    medium: 'bg-blue-100 text-blue-800',
    low: 'bg-gray-100 text-gray-800',
  };

  return (
    <span className={`px-2 py-0.5 text-xs font-medium rounded ${styles[priority] || styles.medium}`}>
      {priority.toUpperCase()}
    </span>
  );
}

/**
 * Recent ticket row
 */
function TicketRow({ ticket }: { ticket: any }) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex items-center gap-3 flex-1 min-w-0">
        <div className="w-8 h-8 bg-blue-50 rounded flex items-center justify-center flex-shrink-0">
          <Ticket className="w-4 h-4 text-blue-600" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-gray-900 truncate">{ticket.subject}</p>
          <p className="text-xs text-gray-500">{ticket.tenant} • {ticket.time}</p>
        </div>
      </div>
      <div className="flex items-center gap-2 ml-2">
        <PriorityBadge priority={ticket.priority} />
      </div>
    </div>
  );
}

/**
 * Support dashboard content
 */
async function SupportDashboardContent() {
  // Mock data - In production, fetch from API
  const metrics = {
    totalTickets: 156,
    openTickets: 23,
    resolvedToday: 42,
    avgResponseTime: '2.4h',
    avgResolutionTime: '18.5h',
    satisfactionScore: 4.6,
    activeChatSessions: 8,
    activeAgents: 12,
  };

  const recentTickets = [
    {
      id: '1',
      subject: 'Unable to login to dashboard',
      tenant: 'Greenwood Academy',
      priority: 'urgent',
      time: '5 min ago'
    },
    {
      id: '2',
      subject: 'Feature request: Custom reports',
      tenant: 'Riverside School',
      priority: 'low',
      time: '30 min ago'
    },
    {
      id: '3',
      subject: 'Payment failed error',
      tenant: 'Mountain View',
      priority: 'high',
      time: '1 hour ago'
    },
    {
      id: '4',
      subject: 'How to add new users?',
      tenant: 'Lakeside Elementary',
      priority: 'medium',
      time: '2 hours ago'
    },
  ];

  return (
    <div className="space-y-6">
      {/* Support Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <SupportMetricCard
          title="Open Tickets"
          value={metrics.openTickets}
          change="-12%"
          changeType="decrease"
          icon={Ticket}
          color="orange"
        />
        <SupportMetricCard
          title="Resolved Today"
          value={metrics.resolvedToday}
          change="+18%"
          changeType="increase"
          icon={CheckCircle2}
          color="green"
        />
        <SupportMetricCard
          title="Avg Response Time"
          value={metrics.avgResponseTime}
          change="-8%"
          changeType="decrease"
          icon={Clock}
          color="blue"
        />
        <SupportMetricCard
          title="Satisfaction Score"
          value={`${metrics.satisfactionScore}/5`}
          change="+0.2"
          changeType="increase"
          icon={Users}
          color="green"
        />
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Tickets */}
        <div className="lg:col-span-2 bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Recent Tickets</h2>
            <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
              View All
            </button>
          </div>
          <div className="space-y-1">
            {recentTickets.map((ticket) => (
              <TicketRow key={ticket.id} ticket={ticket} />
            ))}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="space-y-4">
          {/* Active Chats */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-blue-50 rounded-lg">
                <MessageSquare className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-900">Active Chats</h3>
                <p className="text-xs text-gray-500">Live sessions</p>
              </div>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-gray-900">{metrics.activeChatSessions}</span>
              <span className="text-sm text-gray-500">ongoing</span>
            </div>
          </div>

          {/* Agents Online */}
          <div className="bg-white rounded-lg border border-green-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-green-50 rounded-lg">
                <Users className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-900">Agents Online</h3>
                <p className="text-xs text-gray-500">Available now</p>
              </div>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-green-600">{metrics.activeAgents}</span>
              <span className="text-sm text-gray-500">of 15</span>
            </div>
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Ticket Volume Trend</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Ticket trend chart - Integrate charting library
          </div>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Resolution Time</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Resolution time chart - Integrate charting library
          </div>
        </div>
      </div>

      {/* Ticket Distribution */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Tickets by Priority</h2>
        <div className="grid grid-cols-4 gap-4">
          <div className="text-center p-4 bg-red-50 rounded-lg">
            <p className="text-2xl font-bold text-red-600">4</p>
            <p className="text-sm text-gray-600">Urgent</p>
          </div>
          <div className="text-center p-4 bg-orange-50 rounded-lg">
            <p className="text-2xl font-bold text-orange-600">8</p>
            <p className="text-sm text-gray-600">High</p>
          </div>
          <div className="text-center p-4 bg-blue-50 rounded-lg">
            <p className="text-2xl font-bold text-blue-600">11</p>
            <p className="text-sm text-gray-600">Medium</p>
          </div>
          <div className="text-center p-4 bg-gray-50 rounded-lg">
            <p className="text-2xl font-bold text-gray-600">23</p>
            <p className="text-sm text-gray-600">Low</p>
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Platform Support Dashboard Page
 */
export default function PlatformSupportDashboardPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Support Dashboard</h1>
        <p className="text-gray-600 mt-2">
          Real-time support metrics and ticket analytics
        </p>
      </div>

      {/* Dashboard Content */}
      <Suspense fallback={<div>Loading...</div>}>
        <SupportDashboardContent />
      </Suspense>
    </div>
  );
}
