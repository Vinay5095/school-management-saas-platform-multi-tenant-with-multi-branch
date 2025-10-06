/**
 * PHASE 3: PLATFORM FINANCE PORTAL - LAYOUT
 * Layout for the Platform Finance Portal
 */

import { ReactNode } from 'react';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  FileText, 
  CreditCard, 
  DollarSign,
  TrendingUp,
  Tag,
  RotateCcw,
  PieChart
} from 'lucide-react';

interface PlatformFinanceLayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/platform-finance/dashboard', icon: LayoutDashboard },
  { name: 'Invoices', href: '/platform-finance/invoices', icon: FileText },
  { name: 'Subscriptions', href: '/platform-finance/subscriptions', icon: CreditCard },
  { name: 'Revenue', href: '/platform-finance/revenue', icon: DollarSign },
  { name: 'Pricing Plans', href: '/platform-finance/pricing', icon: Tag },
  { name: 'Refunds', href: '/platform-finance/refunds', icon: RotateCcw },
  { name: 'Analytics', href: '/platform-finance/analytics', icon: TrendingUp },
  { name: 'Reports', href: '/platform-finance/reports', icon: PieChart },
];

export default function PlatformFinanceLayout({ children }: PlatformFinanceLayoutProps) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex-shrink-0">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-xl font-bold text-gray-900">Finance Portal</h1>
          <p className="text-sm text-gray-500 mt-1">Revenue & Billing</p>
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
