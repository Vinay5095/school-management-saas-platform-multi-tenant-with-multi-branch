# SPEC-006: Package.json Complete Configuration

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-006  
**Title**: Complete Package.json Dependencies & Scripts  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 25 minutes  

---

## 📋 DESCRIPTION

Configure a comprehensive package.json file with all necessary dependencies, dev dependencies, scripts, and metadata for the Multi-Tenant School Management SaaS platform. This includes production dependencies, development tools, testing frameworks, and utility scripts.

## 🎯 SUCCESS CRITERIA

- [ ] All production dependencies included
- [ ] Development tools and dependencies configured  
- [ ] Comprehensive script collection for all workflows
- [ ] Proper versioning and metadata
- [ ] Security and performance optimizations
- [ ] Testing and quality assurance tools
- [ ] Build and deployment scripts ready
- [ ] Documentation and maintenance scripts

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. Complete Package.json Configuration

**File**: `package.json`
```json
{
  "name": "school-management-saas",
  "version": "1.0.0",
  "description": "Complete Multi-Tenant School Management SaaS Platform built with Next.js 15, TypeScript, and Supabase",
  "author": {
    "name": "Your Company",
    "email": "dev@yourcompany.com",
    "url": "https://yourcompany.com"
  },
  "license": "MIT",
  "homepage": "https://github.com/yourcompany/school-management-saas",
  "repository": {
    "type": "git",
    "url": "https://github.com/yourcompany/school-management-saas.git"
  },
  "bugs": {
    "url": "https://github.com/yourcompany/school-management-saas/issues"
  },
  "keywords": [
    "school-management",
    "education",
    "saas",
    "multi-tenant",
    "nextjs",
    "typescript",
    "supabase",
    "react",
    "tailwindcss"
  ],
  "engines": {
    "node": ">=18.17.0",
    "npm": ">=9.0.0"
  },
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "export": "next export",
    
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "lint:strict": "eslint --ext .js,.jsx,.ts,.tsx .",
    "lint:strict:fix": "eslint --ext .js,.jsx,.ts,.tsx . --fix",
    
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    
    "type-check": "tsc --noEmit",
    "type-check:watch": "tsc --noEmit --watch",
    
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --ci --coverage --watchAll=false",
    
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed",
    "test:e2e:debug": "playwright test --debug",
    
    "quality": "npm run type-check && npm run lint:strict && npm run format:check && npm run test:ci",
    "quality:fix": "npm run type-check && npm run lint:strict:fix && npm run format && npm run test",
    
    "build:analyze": "ANALYZE=true npm run build",
    "build:production": "NODE_ENV=production npm run build",
    "build:staging": "NODE_ENV=staging npm run build",
    
    "db:generate": "supabase gen types typescript --project-id $SUPABASE_PROJECT_ID --schema public > src/types/database.types.ts",
    "db:reset": "supabase db reset",
    "db:migrate": "supabase migration up",
    "db:seed": "supabase seed run",
    
    "env:check": "node -e \"require('./src/lib/env.ts')\"",
    "env:example": "cp .env.example .env.local",
    
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build",
    
    "prepare": "husky install",
    "postinstall": "npm run prepare",
    
    "security:audit": "npm audit",
    "security:fix": "npm audit fix",
    "security:check": "npm audit --audit-level high",
    
    "deps:check": "npm-check-updates",
    "deps:update": "npm-check-updates -u",
    "deps:install": "npm install",
    
    "clean": "rm -rf .next out dist coverage .nyc_output",
    "clean:deps": "rm -rf node_modules package-lock.json && npm install",
    "clean:all": "npm run clean && npm run clean:deps",
    
    "docker:build": "docker build -t school-management-saas .",
    "docker:run": "docker run -p 3000:3000 -e NODE_ENV=production school-management-saas",
    
    "deploy:vercel": "vercel",
    "deploy:production": "vercel --prod"
  },
  "dependencies": {
    "next": "14.0.3",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    
    "@next/font": "14.0.3",
    "next-themes": "^0.2.1",
    
    "@supabase/supabase-js": "^2.38.4",
    "@supabase/auth-helpers-nextjs": "^0.8.7",
    "@supabase/auth-helpers-react": "^0.4.2",
    "@supabase/auth-ui-react": "^0.4.6",
    "@supabase/auth-ui-shared": "^0.1.8",
    
    "next-auth": "^4.24.5",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    
    "@radix-ui/react-accordion": "^1.1.2",
    "@radix-ui/react-alert-dialog": "^1.0.5",
    "@radix-ui/react-avatar": "^1.0.4",
    "@radix-ui/react-checkbox": "^1.0.4",
    "@radix-ui/react-collapsible": "^1.0.3",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-hover-card": "^1.0.7",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-menubar": "^1.0.4",
    "@radix-ui/react-navigation-menu": "^1.1.4",
    "@radix-ui/react-popover": "^1.0.7",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-radio-group": "^1.1.3",
    "@radix-ui/react-scroll-area": "^1.0.5",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-sheet": "^0.2.3",
    "@radix-ui/react-slider": "^1.1.2",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "@radix-ui/react-toggle": "^1.0.3",
    "@radix-ui/react-toggle-group": "^1.0.4",
    "@radix-ui/react-tooltip": "^1.0.7",
    
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "tailwindcss-animate": "^1.0.7",
    
    "lucide-react": "^0.292.0",
    "@heroicons/react": "^2.0.18",
    
    "react-hook-form": "^7.48.2",
    "@hookform/resolvers": "^3.3.2",
    "zod": "^3.22.4",
    
    "@tanstack/react-query": "^5.8.4",
    "@tanstack/react-query-devtools": "^5.8.4",
    "@tanstack/react-table": "^8.10.7",
    
    "date-fns": "^2.30.0",
    "react-datepicker": "^4.21.0",
    
    "recharts": "^2.8.0",
    "react-chartjs-2": "^5.2.0",
    "chart.js": "^4.4.0",
    
    "framer-motion": "^10.16.5",
    
    "react-hot-toast": "^2.4.1",
    "sonner": "^1.2.4",
    
    "cmdk": "^0.2.0",
    "react-dropzone": "^14.2.3",
    
    "stripe": "^14.7.0",
    "react-stripe-js": "@stripe/react-stripe-js",
    "@stripe/stripe-js": "^2.1.11",
    
    "resend": "^2.0.0",
    "@react-email/components": "^0.0.12",
    "@react-email/render": "^0.0.10",
    
    "jose": "^5.1.3",
    "crypto-js": "^4.2.0",
    
    "react-pdf": "^7.5.1",
    "jspdf": "^2.5.1",
    "xlsx": "^0.18.5",
    
    "socket.io-client": "^4.7.4",
    
    "lodash": "^4.17.21",
    "ramda": "^0.29.1",
    
    "uuid": "^9.0.1",
    "nanoid": "^5.0.4"
  },
  "devDependencies": {
    "@types/node": "^20.9.0",
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    
    "typescript": "^5.2.2",
    
    "@typescript-eslint/eslint-plugin": "^6.10.0",
    "@typescript-eslint/parser": "^6.10.0",
    "eslint": "^8.53.0",
    "eslint-config-next": "14.0.3",
    "eslint-config-prettier": "^9.0.0",
    "eslint-import-resolver-typescript": "^3.6.1",
    "eslint-plugin-import": "^2.29.0",
    "eslint-plugin-jsx-a11y": "^6.8.0",
    "eslint-plugin-react": "^7.33.2",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-unused-imports": "^3.0.0",
    
    "prettier": "^3.0.3",
    "prettier-plugin-tailwindcss": "^0.5.7",
    
    "tailwindcss": "^3.3.5",
    "@tailwindcss/forms": "^0.5.7",
    "@tailwindcss/typography": "^0.5.10",
    "@tailwindcss/aspect-ratio": "^0.4.2",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.1.4",
    "@testing-library/user-event": "^14.5.1",
    "jest": "^29.7.0",
    "jest-environment-jsdom": "^29.7.0",
    "@jest/types": "^29.6.3",
    
    "@playwright/test": "^1.40.0",
    
    "@storybook/addon-essentials": "^7.5.3",
    "@storybook/addon-interactions": "^7.5.3",
    "@storybook/addon-links": "^7.5.3",
    "@storybook/blocks": "^7.5.3",
    "@storybook/nextjs": "^7.5.3",
    "@storybook/react": "^7.5.3",
    "@storybook/testing-library": "^0.2.2",
    "storybook": "^7.5.3",
    
    "husky": "^8.0.3",
    "lint-staged": "^15.1.0",
    
    "@next/bundle-analyzer": "14.0.3",
    
    "@types/bcryptjs": "^2.4.6",
    "@types/jsonwebtoken": "^9.0.5",
    "@types/crypto-js": "^4.2.1",
    "@types/lodash": "^4.14.202",
    "@types/uuid": "^9.0.7",
    
    "supabase": "^1.123.4",
    
    "npm-check-updates": "^16.14.11",
    
    "cross-env": "^7.0.3",
    "dotenv": "^16.3.1",
    
    "@sentry/nextjs": "^7.81.1",
    "@sentry/webpack-plugin": "^2.8.0"
  },
  "peerDependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,css,md,mdx}": [
      "prettier --write"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "jest": {
    "testEnvironment": "jsdom",
    "setupFilesAfterEnv": ["<rootDir>/jest.setup.js"],
    "testPathIgnorePatterns": ["<rootDir>/.next/", "<rootDir>/node_modules/"],
    "moduleNameMapping": {
      "^@/(.*)$": "<rootDir>/src/$1"
    },
    "collectCoverageFrom": [
      "src/**/*.{js,jsx,ts,tsx}",
      "!src/**/*.d.ts",
      "!src/**/*.stories.{js,jsx,ts,tsx}",
      "!src/**/__tests__/**",
      "!src/**/node_modules/**"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  },
  "packageManager": "npm@9.8.1"
}
```

### 2. Jest Configuration

**File**: `jest.config.js`
```javascript
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  // Provide the path to your Next.js app to load next.config.js and .env files
  dir: './',
});

// Add any custom config to be passed to Jest
const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
    '!src/**/__tests__/**',
    '!src/**/node_modules/**',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  testMatch: [
    '**/__tests__/**/*.(js|jsx|ts|tsx)',
    '**/*.(test|spec).(js|jsx|ts|tsx)',
  ],
  testPathIgnorePatterns: [
    '<rootDir>/.next/',
    '<rootDir>/node_modules/',
    '<rootDir>/e2e/',
  ],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': ['babel-jest', { presets: ['next/babel'] }],
  },
  transformIgnorePatterns: [
    '/node_modules/',
    '^.+\\.module\\.(css|sass|scss)$',
  ],
};

// createJestConfig is exported this way to ensure that next/jest can load the Next.js config which is async
module.exports = createJestConfig(customJestConfig);
```

**File**: `jest.setup.js`
```javascript
import '@testing-library/jest-dom';

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  
  disconnect() {}
  
  observe() {}
  
  unobserve() {}
};

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});

// Mock next/router
jest.mock('next/router', () => ({
  useRouter() {
    return {
      route: '/',
      pathname: '/',
      query: {},
      asPath: '/',
      push: jest.fn(),
      pop: jest.fn(),
      reload: jest.fn(),
      back: jest.fn(),
      prefetch: jest.fn().mockResolvedValue(undefined),
      beforePopState: jest.fn(),
      events: {
        on: jest.fn(),
        off: jest.fn(),
        emit: jest.fn(),
      },
    };
  },
}));

// Mock next/navigation
jest.mock('next/navigation', () => ({
  useRouter() {
    return {
      push: jest.fn(),
      replace: jest.fn(),
      prefetch: jest.fn(),
      back: jest.fn(),
    };
  },
  useSearchParams() {
    return new URLSearchParams();
  },
  usePathname() {
    return '/';
  },
}));
```

### 3. Playwright Configuration

**File**: `playwright.config.ts`
```typescript
import { defineConfig, devices } from '@playwright/test';

/**
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './e2e',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: 'http://localhost:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Test against mobile viewports. */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },

    /* Test against branded browsers. */
    {
      name: 'Microsoft Edge',
      use: { ...devices['Desktop Edge'], channel: 'msedge' },
    },
    {
      name: 'Google Chrome',
      use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    },
  ],

  /* Run your local dev server before starting the tests */
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### 4. Bundle Analyzer Configuration

**File**: `next.config.js` (update)
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // ... existing configuration

  // Bundle Analyzer
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    // Bundle Analyzer
    if (process.env.ANALYZE === 'true') {
      const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;
      config.plugins.push(
        new BundleAnalyzerPlugin({
          analyzerMode: 'static',
          openAnalyzer: true,
        })
      );
    }

    return config;
  },
};

module.exports = nextConfig;
```

### 5. Storybook Configuration

**File**: `.storybook/main.ts`
```typescript
import type { StorybookConfig } from '@storybook/nextjs';

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(js|jsx|mjs|ts|tsx)'],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
  ],
  framework: {
    name: '@storybook/nextjs',
    options: {},
  },
  docs: {
    autodocs: 'tag',
  },
  typescript: {
    check: false,
    reactDocgen: 'react-docgen-typescript',
    reactDocgenTypescriptOptions: {
      shouldExtractLiteralValuesFromEnum: true,
      propFilter: (prop) => (prop.parent ? !/node_modules/.test(prop.parent.fileName) : true),
    },
  },
};

export default config;
```

### 6. Additional Configuration Files

**File**: `.nvmrc`
```
18.17.0
```

**File**: `Dockerfile`
```dockerfile
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./
COPY next.config.js ./
COPY tailwind.config.js ./
COPY postcss.config.js ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS runner

WORKDIR /app

ENV NODE_ENV production

# Add non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["npm", "start"]
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Dependencies Installation Test
```bash
# Clean install dependencies
npm ci

# Verify no vulnerabilities
npm audit

# Check for outdated packages
npm outdated
```

### 2. Scripts Functionality Test
```bash
# Test development
npm run dev

# Test build
npm run build

# Test linting
npm run lint

# Test formatting
npm run format:check

# Test type checking
npm run type-check

# Test quality gate
npm run quality
```

### 3. Testing Framework Test
```bash
# Test Jest setup
npm test

# Test Playwright setup
npm run test:e2e

# Test Storybook
npm run storybook
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] All production dependencies included
- [x] Development tools configured
- [x] Comprehensive script collection
- [x] Testing frameworks set up
- [x] Quality assurance tools ready
- [x] Build and deployment scripts
- [x] Security audit capabilities

### Should Have
- [x] Bundle analysis tools
- [x] Storybook integration
- [x] E2E testing with Playwright
- [x] Pre-commit hooks configured
- [x] Docker configuration
- [x] Coverage thresholds set
- [x] Package management scripts

### Could Have
- [x] Database management scripts
- [x] Environment checking scripts
- [x] Dependency update automation
- [x] Performance monitoring
- [x] Documentation generation
- [x] Deployment automation
- [x] Advanced testing configurations

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-005 (Environment Variables Configuration)  
**Depends On**: All previous project setup specifications  
**Blocks**: SPEC-007 (Git Configuration)  

---

## 📝 IMPLEMENTATION NOTES

### Key Package Categories
1. **Core Framework**: Next.js, React, TypeScript
2. **UI Components**: Radix UI, Tailwind CSS, Lucide React  
3. **Database**: Supabase, PostgreSQL drivers
4. **Authentication**: NextAuth.js, JWT, bcrypt
5. **Forms & Validation**: React Hook Form, Zod
6. **Testing**: Jest, Playwright, Testing Library
7. **Development Tools**: ESLint, Prettier, Husky
8. **Build Tools**: Bundle analyzer, Storybook

### Version Management Strategy
- Lock major versions for stability
- Use compatible minor/patch versions
- Regular security updates
- Peer dependency compatibility
- Engine requirements specified

### Script Organization
- **Development**: dev, build, start
- **Quality**: lint, format, type-check, test
- **Database**: migration, seeding scripts  
- **Deployment**: build variants, Docker
- **Maintenance**: clean, update, audit

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-007 (Git Configuration & Hooks)
2. ✅ Run full dependency installation
3. ✅ Test all script functionality
4. ✅ Verify testing framework setup

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-007-git-configuration.md