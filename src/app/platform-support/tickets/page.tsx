/**
 * PHASE 3: PLATFORM SUPPORT PORTAL - TICKETS PAGE
 * SPEC-132: Ticket Management Dashboard
 * Complete ticket management interface
 */

import { Suspense } from 'react';
import Link from 'next/link';
import { 
  Plus,
  Search,
  Filter,
  Clock,
  User
} from 'lucide-react';

/**
 * Status badge
 */
function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    open: 'bg-blue-100 text-blue-800',
    in_progress: 'bg-yellow-100 text-yellow-800',
    resolved: 'bg-green-100 text-green-800',
    closed: 'bg-gray-100 text-gray-800',
  };

  return (
    <span className={`px-2 py-1 text-xs font-medium rounded ${styles[status] || styles.open}`}>
      {status.replace('_', ' ').toUpperCase()}
    </span>
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
 * Ticket row component
 */
function TicketRow({ ticket }: { ticket: any }) {
  return (
    <tr className="border-b border-gray-200 hover:bg-gray-50">
      <td className="px-6 py-4">
        <Link 
          href={`/platform-support/tickets/${ticket.id}`}
          className="font-medium text-blue-600 hover:text-blue-700"
        >
          #{ticket.ticketNumber}
        </Link>
      </td>
      <td className="px-6 py-4">
        <div>
          <p className="font-medium text-gray-900 truncate max-w-md">{ticket.subject}</p>
          <p className="text-sm text-gray-500">{ticket.tenant}</p>
        </div>
      </td>
      <td className="px-6 py-4">
        <StatusBadge status={ticket.status} />
      </td>
      <td className="px-6 py-4">
        <PriorityBadge priority={ticket.priority} />
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center gap-2 text-sm text-gray-600">
          <User className="w-4 h-4" />
          {ticket.assignedTo || 'Unassigned'}
        </div>
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center gap-1 text-sm text-gray-500">
          <Clock className="w-4 h-4" />
          {ticket.time}
        </div>
      </td>
    </tr>
  );
}

/**
 * Tickets table with data
 */
async function TicketsTable() {
  // Mock data - In production, fetch from API
  const tickets = [
    {
      id: '1',
      ticketNumber: 'TKT-1842',
      subject: 'Unable to login to dashboard',
      tenant: 'Greenwood Academy',
      status: 'open',
      priority: 'urgent',
      assignedTo: 'Sarah Johnson',
      time: '5 min ago'
    },
    {
      id: '2',
      ticketNumber: 'TKT-1841',
      subject: 'Payment processing error',
      tenant: 'Riverside School',
      status: 'in_progress',
      priority: 'high',
      assignedTo: 'Mike Chen',
      time: '1 hour ago'
    },
    {
      id: '3',
      ticketNumber: 'TKT-1840',
      subject: 'Feature request: Export reports',
      tenant: 'Mountain View',
      status: 'open',
      priority: 'low',
      assignedTo: null,
      time: '2 hours ago'
    },
    {
      id: '4',
      ticketNumber: 'TKT-1839',
      subject: 'User permissions not working',
      tenant: 'Lakeside Elementary',
      status: 'resolved',
      priority: 'medium',
      assignedTo: 'Alex Rivera',
      time: '4 hours ago'
    },
    {
      id: '5',
      ticketNumber: 'TKT-1838',
      subject: 'Data export taking too long',
      tenant: 'Oakwood High',
      status: 'in_progress',
      priority: 'medium',
      assignedTo: 'Sarah Johnson',
      time: '6 hours ago'
    },
  ];

  return (
    <div className="bg-white rounded-lg border border-gray-200">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Ticket
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Subject
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Priority
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Assigned To
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Created
              </th>
            </tr>
          </thead>
          <tbody>
            {tickets.map((ticket) => (
              <TicketRow key={ticket.id} ticket={ticket} />
            ))}
          </tbody>
        </table>
      </div>
      
      {/* Pagination */}
      <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
        <div className="text-sm text-gray-500">
          Showing 1 to 5 of 156 tickets
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
 * Tickets Page
 */
export default function TicketsPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Support Tickets</h1>
          <p className="text-gray-600 mt-2">
            Manage all customer support tickets
          </p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium">
          <Plus className="w-4 h-4" />
          New Ticket
        </button>
      </div>

      {/* Filters and Search */}
      <div className="mb-6 flex gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search tickets..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
          <Filter className="w-4 h-4" />
          Filters
        </button>
      </div>

      {/* Quick Filter Tabs */}
      <div className="mb-6 flex gap-2">
        <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium">
          All Tickets
        </button>
        <button className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50">
          Open
        </button>
        <button className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50">
          In Progress
        </button>
        <button className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50">
          My Tickets
        </button>
        <button className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50">
          Unassigned
        </button>
      </div>

      {/* Tickets Table */}
      <Suspense fallback={<div>Loading tickets...</div>}>
        <TicketsTable />
      </Suspense>
    </div>
  );
}
