/**
 * PHASE 3: PLATFORM FINANCE PORTAL - MODERN MINIMALISTIC LAYOUT
 */

import { ReactNode } from 'react';
import Link from 'next/link';
import { 
  LayoutDashboard, 
  FileText, 
  CreditCard, 
  DollarSign,
  Tag,
  RotateCcw,
  BarChart3,
  FileBarChart,
  Bell,
  Search
} from 'lucide-react';

interface FinanceLayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/platform-finance/dashboard', icon: LayoutDashboard },
  { name: 'Invoices', href: '/platform-finance/invoices', icon: FileText },
  { name: 'Subscriptions', href: '/platform-finance/subscriptions', icon: CreditCard },
  { name: 'Revenue', href: '/platform-finance/revenue', icon: DollarSign },
  { name: 'Pricing', href: '/platform-finance/pricing', icon: Tag },
  { name: 'Refunds', href: '/platform-finance/refunds', icon: RotateCcw },
  { name: 'Analytics', href: '/platform-finance/analytics', icon: BarChart3 },
  { name: 'Reports', href: '/platform-finance/reports', icon: FileBarChart },
];

export default function FinanceLayout({ children }: FinanceLayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top Navigation */}
      <header className="sticky top-0 z-50 bg-white border-b border-gray-200">
        <div className="flex items-center justify-between h-16 px-6">
          <div className="flex items-center gap-8">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-gradient-to-br from-green-600 to-emerald-600 rounded-lg"></div>
              <h1 className="text-lg font-semibold text-gray-900">Finance Portal</h1>
            </div>
            
            <div className="hidden md:flex items-center gap-2 px-4 py-2 bg-gray-50 rounded-lg w-96">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search..."
                className="bg-transparent border-none outline-none text-sm w-full"
              />
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button className="relative p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100">
              <Bell className="w-5 h-5" />
            </button>
            <div className="w-8 h-8 bg-gradient-to-br from-green-500 to-emerald-500 rounded-full"></div>
          </div>
        </div>
      </header>

      <div className="flex">
        <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-gray-200 min-h-[calc(100vh-64px)]">
          <nav className="flex-1 p-4 space-y-1">
            {navigation.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className="flex items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-600 rounded-xl hover:bg-gray-50 hover:text-gray-900 transition-all"
                >
                  <Icon className="w-5 h-5" />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>
        </aside>

        <main className="flex-1 p-8 bg-gray-50">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
