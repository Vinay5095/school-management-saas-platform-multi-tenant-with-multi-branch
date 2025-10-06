import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'School Management SaaS',
  description: 'Complete Multi-Tenant School Management Platform',
  keywords: 'school, management, education, SaaS, multi-tenant',
  authors: [{ name: 'Your Company' }],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <main className="min-h-screen">
          {children}
        </main>
      </body>
    </html>
  );
}
