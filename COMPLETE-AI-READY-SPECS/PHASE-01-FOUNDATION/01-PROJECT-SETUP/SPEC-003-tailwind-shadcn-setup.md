# SPEC-003: Tailwind CSS + shadcn/ui Setup

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-003  
**Title**: Tailwind CSS + shadcn/ui Component Library Setup  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 25 minutes  

---

## 📋 DESCRIPTION

Set up Tailwind CSS with shadcn/ui component library for consistent, accessible, and beautiful UI components. This includes theme configuration, design tokens, and essential UI components for the School Management SaaS.

## 🎯 SUCCESS CRITERIA

- [ ] Tailwind CSS fully configured and optimized
- [ ] shadcn/ui component library integrated
- [ ] Theme system with light/dark mode support
- [ ] Design tokens and color palette defined
- [ ] Essential UI components installed
- [ ] Typography and spacing system configured
- [ ] Responsive design utilities ready
- [ ] Production-ready CSS optimization

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. Tailwind CSS Configuration

**File**: `tailwind.config.js`
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        // Brand Colors
        brand: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
          950: '#172554',
        },
        // Educational Colors
        education: {
          primary: '#2563eb',
          secondary: '#7c3aed',
          success: '#059669',
          warning: '#d97706',
          error: '#dc2626',
          info: '#0891b2',
        },
        // Semantic Colors
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Consolas', 'monospace'],
      },
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1' }],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.2s ease-out",
        "slide-in": "slide-in 0.3s ease-out",
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
        "fade-in": {
          from: { opacity: 0 },
          to: { opacity: 1 },
        },
        "slide-in": {
          from: { transform: 'translateX(-100%)' },
          to: { transform: 'translateX(0)' },
        },
      },
    },
  },
  plugins: [
    require("tailwindcss-animate"),
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/aspect-ratio"),
  ],
}
```

### 2. Global CSS with CSS Variables

**File**: `src/app/globals.css`
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* Light theme variables */
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96%;
    --secondary-foreground: 222.2 84% 4.9%;
    --muted: 210 40% 96%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96%;
    --accent-foreground: 222.2 84% 4.9%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
    
    /* Educational specific variables */
    --success: 142.1 76.2% 36.3%;
    --warning: 32.2 95% 44%;
    --info: 195.7 97.3% 32.2%;
  }

  .dark {
    /* Dark theme variables */
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 84% 4.9%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 94.1%;
    
    /* Educational specific variables - dark */
    --success: 142.1 70.6% 45.3%;
    --warning: 32.2 95% 54%;
    --info: 195.7 97.3% 42.2%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  
  body {
    @apply bg-background text-foreground;
    font-feature-settings: "rlig" 1, "calt" 1;
  }
  
  h1, h2, h3, h4, h5, h6 {
    @apply font-semibold tracking-tight;
  }
  
  /* Custom scrollbar */
  ::-webkit-scrollbar {
    @apply w-2 h-2;
  }
  
  ::-webkit-scrollbar-track {
    @apply bg-muted;
  }
  
  ::-webkit-scrollbar-thumb {
    @apply bg-border rounded-full;
  }
  
  ::-webkit-scrollbar-thumb:hover {
    @apply bg-muted-foreground;
  }
}

@layer components {
  /* Educational specific components */
  .btn-primary {
    @apply bg-primary text-primary-foreground hover:bg-primary/90 focus:ring-2 focus:ring-primary focus:ring-offset-2;
  }
  
  .btn-secondary {
    @apply bg-secondary text-secondary-foreground hover:bg-secondary/80 focus:ring-2 focus:ring-secondary focus:ring-offset-2;
  }
  
  .card-gradient {
    @apply bg-gradient-to-br from-card to-card/80 backdrop-blur-sm;
  }
  
  .text-gradient {
    @apply bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent;
  }
  
  /* Educational status indicators */
  .status-active {
    @apply bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300;
  }
  
  .status-pending {
    @apply bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300;
  }
  
  .status-inactive {
    @apply bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300;
  }
}

@layer utilities {
  /* Educational specific utilities */
  .text-balance {
    text-wrap: balance;
  }
  
  .sidebar-width {
    width: 280px;
  }
  
  .content-max-width {
    max-width: 1200px;
  }
}
```

### 3. shadcn/ui Installation and Setup

```bash
# Install shadcn/ui CLI
npx shadcn-ui@latest init

# Install essential components
npx shadcn-ui@latest add button
npx shadcn-ui@latest add input
npx shadcn-ui@latest add label
npx shadcn-ui@latest add card
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add dropdown-menu
npx shadcn-ui@latest add form
npx shadcn-ui@latest add toast
npx shadcn-ui@latest add table
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add separator
npx shadcn-ui@latest add skeleton
npx shadcn-ui@latest add alert
```

### 4. Component Library Configuration

**File**: `components.json`
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/app/globals.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
```

### 5. Theme Provider Setup

**File**: `src/components/providers/theme-provider.tsx`
```tsx
"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";
import { type ThemeProviderProps } from "next-themes/dist/types";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
```

### 6. Update Root Layout with Theme Provider

**File**: `src/app/layout.tsx` (update)
```tsx
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { ThemeProvider } from '@/components/providers/theme-provider';
import { Toaster } from '@/components/ui/toaster';

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
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <main className="min-h-screen">
            {children}
          </main>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
```

### 7. Example Component Usage

**File**: `src/app/page.tsx` (update with styled components)
```tsx
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, Rocket, Palette } from 'lucide-react';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-muted/20">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-12">
          <Badge variant="secondary" className="mb-4">
            <Palette className="w-4 h-4 mr-2" />
            UI Ready
          </Badge>
          <h1 className="text-4xl md:text-6xl font-bold text-gradient mb-6">
            School Management SaaS
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            Complete Multi-Tenant School Management Platform with Beautiful UI Components
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="gap-2">
              <Rocket className="w-5 h-5" />
              Get Started
            </Button>
            <Button variant="outline" size="lg">
              View Documentation
            </Button>
          </div>
        </div>

        <div className="grid md:grid-cols-3 gap-6 max-w-4xl mx-auto">
          <Card className="card-gradient border-0 shadow-lg">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-green-500" />
                Next.js 15
              </CardTitle>
              <CardDescription>
                Latest Next.js with App Router and Server Components
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Badge className="status-active">Complete</Badge>
            </CardContent>
          </Card>

          <Card className="card-gradient border-0 shadow-lg">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-green-500" />
                TypeScript
              </CardTitle>
              <CardDescription>
                Strict TypeScript configuration for type safety
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Badge className="status-active">Complete</Badge>
            </CardContent>
          </Card>

          <Card className="card-gradient border-0 shadow-lg">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-green-500" />
                Tailwind + shadcn/ui
              </CardTitle>
              <CardDescription>
                Beautiful UI components with consistent design system
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Badge className="status-active">Complete</Badge>
            </CardContent>
          </Card>
        </div>

        <div className="mt-16 text-center">
          <p className="text-muted-foreground">
            🎨 Design system ready • 🌙 Dark mode support • 📱 Fully responsive
          </p>
        </div>
      </div>
    </div>
  );
}
```

### 8. Package Dependencies

**File**: `package.json` (add these dependencies)
```json
{
  "dependencies": {
    "next-themes": "^0.2.1",
    "lucide-react": "^0.292.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "@radix-ui/react-avatar": "^1.0.4"
  },
  "devDependencies": {
    "tailwindcss-animate": "^1.0.7",
    "@tailwindcss/forms": "^0.5.7",
    "@tailwindcss/typography": "^0.5.10",
    "@tailwindcss/aspect-ratio": "^0.4.2"
  }
}
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Visual Testing
```bash
# Start development server
npm run dev

# Verify homepage renders with new styling
# Test light/dark mode switching
# Verify responsive design
# Check component styling
```

### 2. Component Testing
```bash
# Test shadcn/ui components work
# Verify theme provider functionality
# Test CSS variables in both themes
# Verify animations work
```

### 3. Build Testing
```bash
# Test production build
npm run build

# Verify CSS optimization
# Check bundle size
# Verify no styling errors
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] Tailwind CSS fully configured and working
- [x] shadcn/ui components installed and functional
- [x] Theme system with light/dark mode
- [x] CSS variables for consistent theming
- [x] Responsive design system
- [x] Essential UI components available
- [x] Typography and spacing system

### Should Have
- [x] Educational-specific color palette
- [x] Custom animations and transitions
- [x] Consistent component styling
- [x] Theme provider integration
- [x] Optimized CSS output
- [x] Custom utility classes

### Could Have
- [x] Advanced animations
- [x] Custom scrollbar styling
- [x] Gradient utilities
- [x] Status indicator classes
- [x] Educational-specific components

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-002 (TypeScript Configuration)  
**Depends On**: TypeScript paths and Next.js setup  
**Blocks**: SPEC-004 (ESLint & Prettier)  

---

## 📝 IMPLEMENTATION NOTES

### Key Design Decisions
1. **shadcn/ui**: Chosen for high-quality, accessible components
2. **CSS Variables**: Enable easy theme switching
3. **Educational Colors**: Custom palette for school management context
4. **Responsive First**: Mobile-first design approach
5. **Dark Mode**: Built-in theme switching support

### Component Strategy
- Start with essential components (Button, Card, Input, etc.)
- Add more components as needed in later specifications
- Maintain consistent design language
- Focus on accessibility and usability

### Performance Considerations
- CSS optimization through Tailwind's JIT compiler
- Tree-shaking of unused styles
- Minimal runtime JavaScript for theming
- Optimized animation performance

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-004 (ESLint & Prettier Configuration)
2. ✅ Verify all components render correctly
3. ✅ Test theme switching functionality
4. ✅ Update component documentation

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-004-eslint-prettier.md