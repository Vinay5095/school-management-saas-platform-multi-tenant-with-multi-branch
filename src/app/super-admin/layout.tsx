/**
 * PHASE 3: SUPER ADMIN PORTAL - MAIN LAYOUT
 * Layout for the Super Admin Portal with navigation and permissions
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
  FileText
} from 'lucide-react';

interface SuperAdminLayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/super-admin/dashboard', icon: LayoutDashboard },
  { name: 'Tenants', href: '/super-admin/tenants', icon: Building2 },
  { name: 'Users', href: '/super-admin/users', icon: Users },
  { name: 'System', href: '/super-admin/system', icon: Settings },
  { name: 'Analytics', href: '/super-admin/analytics', icon: BarChart3 },
  { name: 'Support', href: '/super-admin/support', icon: HeadphonesIcon },
  { name: 'Security', href: '/super-admin/security', icon: Shield },
  { name: 'Database', href: '/super-admin/database', icon: Database },
  { name: 'Feature Flags', href: '/super-admin/features', icon: Flag },
  { name: 'Documentation', href: '/super-admin/docs', icon: FileText },
];

export default function SuperAdminLayout({ children }: SuperAdminLayoutProps) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200">
        <div className="p-6">
          <h1 className="text-xl font-bold text-gray-900">Super Admin</h1>
          <p className="text-sm text-gray-500">Platform Management</p>
        </div>
        
        <nav className="px-3 space-y-1">
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
      <main className="flex-1 overflow-y-auto">
        <div className="p-8">
          {children}
        </div>
      </main>
    </div>
  );
}
