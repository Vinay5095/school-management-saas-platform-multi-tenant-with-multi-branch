# SPEC-001: Next.js 15 Project Initialization

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-001  
**Title**: Next.js 15 Project Initialization  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 30 minutes  

---

## 📋 DESCRIPTION

Initialize a new Next.js 15 project with the latest features, proper folder structure, and optimal configuration for a multi-tenant School Management SaaS platform.

## 🎯 SUCCESS CRITERIA

- [ ] Next.js 15 project created successfully
- [ ] Project uses App Router (not Pages Router)
- [ ] TypeScript is enabled by default
- [ ] Proper folder structure is established
- [ ] Development server runs without errors
- [ ] All default configurations are optimized
- [ ] Project is ready for further development

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. Project Creation

```bash
# Create new Next.js 15 project
npx create-next-app@latest school-management-saas --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# Navigate to project directory
cd school-management-saas
```

### 2. Required Folder Structure

```
school-management-saas/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── loading.tsx
│   │   ├── error.tsx
│   │   └── not-found.tsx
│   ├── components/
│   │   ├── ui/
│   │   ├── forms/
│   │   ├── layout/
│   │   └── common/
│   ├── lib/
│   │   ├── utils.ts
│   │   ├── auth.ts
│   │   ├── database.ts
│   │   └── validations.ts
│   ├── hooks/
│   ├── context/
│   ├── types/
│   └── constants/
├── public/
│   ├── images/
│   ├── icons/
│   └── favicon.ico
├── docs/
├── tests/
│   ├── __tests__/
│   ├── __mocks__/
│   └── setup.ts
├── .env.local
├── .env.example
├── .gitignore
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
├── package.json
└── README.md
```

### 3. Next.js Configuration

**File**: `next.config.js`
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable React strict mode
  reactStrictMode: true,
  
  // Enable SWC minification
  swcMinify: true,
  
  // Optimize images
  images: {
    domains: ['localhost'],
    formats: ['image/webp', 'image/avif'],
  },
  
  // Enable experimental features
  experimental: {
    // Server actions
    serverActions: true,
    // Partial prerendering
    ppr: true,
  },
  
  // Environment variables
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
  
  // Headers for security
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
```

### 4. Root Layout Configuration

**File**: `src/app/layout.tsx`
```tsx
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'School Management SaaS',
  description: 'Complete Multi-Tenant School Management Platform',
  keywords: 'school, management, education, SaaS, multi-tenant',
  authors: [{ name: 'Your Company' }],
  viewport: 'width=device-width, initial-scale=1',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <main className="min-h-screen">
          {children}
        </main>
      </body>
    </html>
  );
}
```

### 5. Homepage Setup

**File**: `src/app/page.tsx`
```tsx
export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          School Management SaaS
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Complete Multi-Tenant School Management Platform
        </p>
        <div className="space-y-4">
          <p className="text-green-600 font-semibold">
            ✅ Next.js 15 Project Initialized
          </p>
          <p className="text-blue-600">
            🚀 Ready for development
          </p>
        </div>
      </div>
    </div>
  );
}
```

### 6. Essential Utility Files

**File**: `src/lib/utils.ts`
```typescript
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: Date | string): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date(date));
}

export function generateId(): string {
  return Math.random().toString(36).substring(2, 15);
}
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Development Server Test
```bash
# Start development server
npm run dev

# Verify server runs on http://localhost:3000
# Verify page loads without errors
# Verify no console errors
```

### 2. Build Test
```bash
# Test production build
npm run build

# Verify build completes successfully
# Verify no build errors
# Verify optimized output
```

### 3. Type Checking
```bash
# Run TypeScript type checking
npm run type-check

# Verify no type errors
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] Next.js 15 project created with App Router
- [x] TypeScript enabled and configured
- [x] Tailwind CSS integrated
- [x] ESLint configured
- [x] Proper folder structure established
- [x] Development server runs successfully
- [x] Homepage displays correctly
- [x] No console errors or warnings

### Should Have
- [x] Optimized Next.js configuration
- [x] Security headers configured
- [x] Image optimization enabled
- [x] SWC minification enabled
- [x] React strict mode enabled

### Could Have
- [x] Experimental features enabled
- [x] Custom metadata configured
- [x] Utility functions created
- [x] Basic styling applied

---

## 🔗 DEPENDENCIES

**Prerequisites**: None (This is the starting point)  
**Depends On**: None  
**Blocks**: SPEC-002 (TypeScript Configuration)  

---

## 📝 IMPLEMENTATION NOTES

### Key Decisions Made
1. **App Router**: Using Next.js 13+ App Router for better performance
2. **TypeScript**: Enabled by default for type safety
3. **Source Directory**: Using `src/` folder for better organization
4. **Import Alias**: Using `@/*` for cleaner imports
5. **Security**: Added security headers by default

### Common Issues & Solutions
1. **Port conflicts**: Use `npm run dev -- -p 3001` for different port
2. **Type errors**: Run `npm run type-check` to identify issues
3. **Build failures**: Check `next.config.js` configuration
4. **Styling issues**: Verify Tailwind CSS integration

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-002 (TypeScript Configuration)
2. ✅ Verify all tests pass
3. ✅ Commit changes to version control
4. ✅ Update project documentation

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-002-typescript-config.md