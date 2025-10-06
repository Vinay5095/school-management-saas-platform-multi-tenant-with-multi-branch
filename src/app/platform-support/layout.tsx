/**
 * PHASE 3: PLATFORM SUPPORT PORTAL - LAYOUT
 * Layout for the Platform Support Portal
 */

import { ReactNode } from 'react';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  Ticket, 
  MessageSquare, 
  BookOpen,
  BarChart3,
  Clock,
  Users,
  Settings
} from 'lucide-react';

interface PlatformSupportLayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/platform-support/dashboard', icon: LayoutDashboard },
  { name: 'Tickets', href: '/platform-support/tickets', icon: Ticket },
  { name: 'Live Chat', href: '/platform-support/chat', icon: MessageSquare },
  { name: 'Knowledge Base', href: '/platform-support/knowledge-base', icon: BookOpen },
  { name: 'Analytics', href: '/platform-support/analytics', icon: BarChart3 },
  { name: 'SLA Tracking', href: '/platform-support/sla', icon: Clock },
  { name: 'Agents', href: '/platform-support/agents', icon: Users },
  { name: 'Settings', href: '/platform-support/settings', icon: Settings },
];

export default function PlatformSupportLayout({ children }: PlatformSupportLayoutProps) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex-shrink-0">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-xl font-bold text-gray-900">Support Portal</h1>
          <p className="text-sm text-gray-500 mt-1">Customer Service</p>
        </div>
        
        <nav className="px-3 py-4 space-y-1">
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                href={item.href}
                className="flex items-center gap-3 px-3 py-2 text-sm font-medium text-gray-700 rounded-lg hover:bg-gray-100 hover:text-gray-900 transition-colors"
              >
                <Icon className="w-5 h-5" />
                {item.name}
              </Link>
            );
          })}
        </nav>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {children}
        </div>
      </main>
    </div>
  );
}
