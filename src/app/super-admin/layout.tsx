/**
 * PHASE 3: SUPER ADMIN PORTAL - MODERN MINIMALISTIC LAYOUT
 * Clean, contemporary design with focus on usability
 */

import { ReactNode } from 'react';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  Building2, 
  Users, 
  Settings, 
  BarChart3,
  HeadphonesIcon,
  Shield,
  Database,
  Flag,
  FileText,
  Bell,
  Search
} from 'lucide-react';

interface SuperAdminLayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/super-admin/dashboard', icon: LayoutDashboard },
  { name: 'Tenants', href: '/super-admin/tenants', icon: Building2 },
  { name: 'Users', href: '/super-admin/users', icon: Users },
  { name: 'Analytics', href: '/super-admin/analytics', icon: BarChart3 },
  { name: 'Support', href: '/super-admin/support', icon: HeadphonesIcon },
  { name: 'Security', href: '/super-admin/security', icon: Shield },
  { name: 'Database', href: '/super-admin/database', icon: Database },
  { name: 'Features', href: '/super-admin/features', icon: Flag },
  { name: 'System', href: '/super-admin/system', icon: Settings },
  { name: 'Docs', href: '/super-admin/docs', icon: FileText },
];

export default function SuperAdminLayout({ children }: SuperAdminLayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top Navigation Bar */}
      <header className="sticky top-0 z-50 bg-white border-b border-gray-200">
        <div className="flex items-center justify-between h-16 px-6">
          {/* Logo and Brand */}
          <div className="flex items-center gap-8">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-lg"></div>
              <div>
                <h1 className="text-lg font-semibold text-gray-900">Platform Admin</h1>
              </div>
            </div>
            
            {/* Search */}
            <div className="hidden md:flex items-center gap-2 px-4 py-2 bg-gray-50 rounded-lg w-96">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search..."
                className="bg-transparent border-none outline-none text-sm w-full text-gray-700 placeholder-gray-400"
              />
            </div>
          </div>

          {/* Right Actions */}
          <div className="flex items-center gap-4">
            <button className="relative p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100">
              <Bell className="w-5 h-5" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
            <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full"></div>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar Navigation */}
        <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-gray-200 min-h-[calc(100vh-64px)]">
          <nav className="flex-1 p-4 space-y-1">
            {navigation.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className="flex items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-600 rounded-xl hover:bg-gray-50 hover:text-gray-900 transition-all duration-200"
                >
                  <Icon className="w-5 h-5" />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>
          
          {/* Footer Info */}
          <div className="p-4 border-t border-gray-200">
            <div className="px-4 py-3 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl">
              <p className="text-xs font-medium text-gray-700">Platform Status</p>
              <p className="text-xs text-gray-500 mt-1">All systems operational</p>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 p-8 bg-gray-50">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
