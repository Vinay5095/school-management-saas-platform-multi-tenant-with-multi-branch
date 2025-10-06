/**
 * PHASE 3: SUPPORT TICKETS - MODERN MINIMALISTIC DESIGN
 */

'use client';

import { Search, Filter, Plus, Ticket } from 'lucide-react';

export default function TicketsPage() {
  const tickets = [
    {
      id: '#1234',
      title: 'Unable to login to dashboard',
      tenant: 'Greenwood Academy',
      status: 'open',
      priority: 'urgent',
      agent: 'John Doe',
      created: '5 min ago'
    },
    {
      id: '#1235',
      title: 'Feature request: Custom reports',
      tenant: 'Riverside School',
      status: 'in-progress',
      priority: 'low',
      agent: 'Jane Smith',
      created: '30 min ago'
    },
    {
      id: '#1236',
      title: 'Payment failed error',
      tenant: 'Mountain View',
      status: 'open',
      priority: 'high',
      agent: 'Unassigned',
      created: '1 hour ago'
    },
    {
      id: '#1237',
      title: 'How to add new users?',
      tenant: 'Lakeside Elementary',
      status: 'resolved',
      priority: 'medium',
      agent: 'Mike Johnson',
      created: '2 hours ago'
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Support Tickets</h1>
          <p className="text-gray-500 mt-2">Manage and resolve customer support requests</p>
        </div>
        <button className="flex items-center gap-2 bg-purple-600 text-white px-4 py-2.5 rounded-xl hover:bg-purple-700 transition-colors font-medium">
          <Plus className="w-5 h-5" />
          New Ticket
        </button>
      </div>

      {/* Search and Filter */}
      <div className="flex items-center gap-4">
        <div className="flex-1 flex items-center gap-3 px-4 py-2.5 bg-white rounded-xl border border-gray-200">
          <Search className="w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search tickets..."
            className="flex-1 border-none outline-none text-sm bg-transparent"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 bg-white rounded-xl border border-gray-200 hover:bg-gray-50 transition-colors">
          <Filter className="w-5 h-5 text-gray-600" />
          <span className="text-sm font-medium text-gray-700">Filters</span>
        </button>
      </div>

      {/* Tickets List */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">ID</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Ticket</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Status</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Priority</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Agent</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Created</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {tickets.map((ticket) => (
                <tr key={ticket.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <span className="text-sm font-medium text-gray-900">{ticket.id}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
                        <Ticket className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-gray-900">{ticket.title}</p>
                        <p className="text-xs text-gray-500">{ticket.tenant}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${
                      ticket.status === 'open'
                        ? 'bg-blue-100 text-blue-700'
                        : ticket.status === 'in-progress'
                        ? 'bg-yellow-100 text-yellow-700'
                        : 'bg-green-100 text-green-700'
                    }`}>
                      {ticket.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${
                      ticket.priority === 'urgent'
                        ? 'bg-red-100 text-red-700'
                        : ticket.priority === 'high'
                        ? 'bg-orange-100 text-orange-700'
                        : ticket.priority === 'medium'
                        ? 'bg-yellow-100 text-yellow-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}>
                      {ticket.priority}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-900">{ticket.agent}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-600">{ticket.created}</span>
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
