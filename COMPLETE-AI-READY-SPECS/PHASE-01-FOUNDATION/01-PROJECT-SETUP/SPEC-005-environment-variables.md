# SPEC-005: Environment Variables Configuration

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-005  
**Title**: Environment Variables & Configuration Management  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 15 minutes  

---

## 📋 DESCRIPTION

Set up a comprehensive environment variables system for the Multi-Tenant School Management SaaS platform. This includes configuration for different environments (development, staging, production), database connections, authentication secrets, and external service integrations.

## 🎯 SUCCESS CRITERIA

- [ ] Environment variables structure defined
- [ ] Example configuration files created
- [ ] Type-safe environment variable access
- [ ] Different environment configurations
- [ ] Security best practices implemented
- [ ] Documentation for all variables
- [ ] Validation for required variables
- [ ] Git security maintained

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. Environment Variables Structure

**File**: `.env.example`
```bash
# ==============================================
# SCHOOL MANAGEMENT SAAS - ENVIRONMENT VARIABLES
# ==============================================

# Basic App Configuration
NEXT_PUBLIC_APP_NAME="School Management SaaS"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NEXT_PUBLIC_APP_VERSION="1.0.0"
NODE_ENV="development"

# ==============================================
# DATABASE CONFIGURATION
# ==============================================

# Supabase Configuration (Primary Database)
NEXT_PUBLIC_SUPABASE_URL="https://your-project.supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
DATABASE_URL="postgresql://postgres:password@localhost:5432/school_management"

# Direct Database Connection (Alternative)
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="school_management"
DB_USER="postgres"
DB_PASSWORD="your-password"

# ==============================================
# AUTHENTICATION & SECURITY
# ==============================================

# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-min-256-bits"
JWT_EXPIRES_IN="7d"
JWT_REFRESH_EXPIRES_IN="30d"

# NextAuth.js Configuration
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="your-nextauth-secret-key"

# OAuth Providers
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"
MICROSOFT_CLIENT_ID="your-microsoft-client-id"
MICROSOFT_CLIENT_SECRET="your-microsoft-client-secret"

# Two-Factor Authentication
TWILIO_ACCOUNT_SID="your-twilio-account-sid"
TWILIO_AUTH_TOKEN="your-twilio-auth-token"
TWILIO_PHONE_NUMBER="+1234567890"

# ==============================================
# EMAIL SERVICES
# ==============================================

# Resend (Primary Email Service)
RESEND_API_KEY="your-resend-api-key"
NEXT_PUBLIC_FROM_EMAIL="noreply@yourschool.com"

# SendGrid (Alternative)
SENDGRID_API_KEY="your-sendgrid-api-key"

# SMTP Configuration (Fallback)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"

# ==============================================
# FILE STORAGE & CDN
# ==============================================

# Supabase Storage
NEXT_PUBLIC_SUPABASE_STORAGE_URL="https://your-project.supabase.co/storage/v1"

# AWS S3 (Alternative)
AWS_ACCESS_KEY_ID="your-aws-access-key"
AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
AWS_REGION="us-east-1"
AWS_S3_BUCKET="your-s3-bucket"

# Cloudinary (Alternative)
CLOUDINARY_CLOUD_NAME="your-cloud-name"
CLOUDINARY_API_KEY="your-api-key"
CLOUDINARY_API_SECRET="your-api-secret"

# ==============================================
# PAYMENT PROCESSING
# ==============================================

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY="pk_test_your-stripe-key"
STRIPE_SECRET_KEY="sk_test_your-stripe-secret"
STRIPE_WEBHOOK_SECRET="whsec_your-webhook-secret"

# PayPal (Alternative)
PAYPAL_CLIENT_ID="your-paypal-client-id"
PAYPAL_CLIENT_SECRET="your-paypal-client-secret"

# ==============================================
# COMMUNICATION SERVICES
# ==============================================

# WhatsApp Business API
WHATSAPP_ACCESS_TOKEN="your-whatsapp-token"
WHATSAPP_PHONE_NUMBER_ID="your-phone-number-id"

# SMS Service
SMS_API_KEY="your-sms-api-key"
SMS_SENDER_ID="SchoolSMS"

# Push Notifications
FIREBASE_PROJECT_ID="your-firebase-project"
FIREBASE_PRIVATE_KEY="your-firebase-private-key"
FIREBASE_CLIENT_EMAIL="your-firebase-client-email"

# ==============================================
# MONITORING & ANALYTICS
# ==============================================

# Sentry (Error Tracking)
NEXT_PUBLIC_SENTRY_DSN="your-sentry-dsn"
SENTRY_ORG="your-sentry-org"
SENTRY_PROJECT="your-sentry-project"
SENTRY_AUTH_TOKEN="your-sentry-auth-token"

# Google Analytics
NEXT_PUBLIC_GA_TRACKING_ID="G-XXXXXXXXXX"

# PostHog (Product Analytics)
NEXT_PUBLIC_POSTHOG_KEY="your-posthog-key"
NEXT_PUBLIC_POSTHOG_HOST="https://app.posthog.com"

# ==============================================
# EXTERNAL INTEGRATIONS
# ==============================================

# OpenAI (AI Features)
OPENAI_API_KEY="sk-your-openai-api-key"

# Maps & Location Services
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY="your-google-maps-key"

# Video Conferencing
ZOOM_API_KEY="your-zoom-api-key"
ZOOM_API_SECRET="your-zoom-api-secret"

# ==============================================
# FEATURE FLAGS & CONFIGURATION
# ==============================================

# Feature Flags
NEXT_PUBLIC_ENABLE_MULTITENANCY="true"
NEXT_PUBLIC_ENABLE_PAYMENTS="true"
NEXT_PUBLIC_ENABLE_CHAT="true"
NEXT_PUBLIC_ENABLE_VIDEO_CALLS="false"
NEXT_PUBLIC_ENABLE_AI_FEATURES="true"

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE="100"
RATE_LIMIT_REQUESTS_PER_HOUR="1000"

# ==============================================
# DEVELOPMENT & DEBUGGING
# ==============================================

# Logging
LOG_LEVEL="info"
ENABLE_REQUEST_LOGGING="true"

# Database Debugging
ENABLE_QUERY_LOGGING="false"
DATABASE_SLOW_QUERY_THRESHOLD="100"

# Performance Monitoring
ENABLE_PERFORMANCE_MONITORING="true"
```

### 2. Local Development Environment

**File**: `.env.local` (create from example)
```bash
# ==============================================
# LOCAL DEVELOPMENT ENVIRONMENT
# ==============================================

# Copy from .env.example and fill with your local values
# This file is gitignored and should contain your actual secrets

NEXT_PUBLIC_APP_URL="http://localhost:3000"
NODE_ENV="development"

# Local Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/school_management_dev"

# Development Secrets (use simple values for local dev)
JWT_SECRET="dev-jwt-secret-key-for-local-development-only"
NEXTAUTH_SECRET="dev-nextauth-secret-for-local-only"

# ... add your actual API keys here
```

### 3. Type-Safe Environment Variables

**File**: `src/lib/env.ts`
```typescript
import { z } from 'zod';

// Environment variable validation schema
const envSchema = z.object({
  // App Configuration
  NEXT_PUBLIC_APP_NAME: z.string().default('School Management SaaS'),
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_APP_VERSION: z.string().default('1.0.0'),
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),

  // Database
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string(),
  SUPABASE_SERVICE_ROLE_KEY: z.string(),
  DATABASE_URL: z.string().url(),

  // Authentication
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  NEXTAUTH_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(32),

  // Email Service
  RESEND_API_KEY: z.string().optional(),
  NEXT_PUBLIC_FROM_EMAIL: z.string().email(),

  // OAuth (Optional)
  GOOGLE_CLIENT_ID: z.string().optional(),
  GOOGLE_CLIENT_SECRET: z.string().optional(),

  // Payments (Optional)
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().optional(),
  STRIPE_SECRET_KEY: z.string().optional(),

  // Feature Flags
  NEXT_PUBLIC_ENABLE_MULTITENANCY: z.string().transform(val => val === 'true').default('true'),
  NEXT_PUBLIC_ENABLE_PAYMENTS: z.string().transform(val => val === 'true').default('false'),
  NEXT_PUBLIC_ENABLE_AI_FEATURES: z.string().transform(val => val === 'true').default('false'),

  // Monitoring (Optional)
  NEXT_PUBLIC_SENTRY_DSN: z.string().optional(),
  NEXT_PUBLIC_GA_TRACKING_ID: z.string().optional(),

  // Development
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  ENABLE_REQUEST_LOGGING: z.string().transform(val => val === 'true').default('false'),
});

// Parse and validate environment variables
function validateEnv() {
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const missingVars = error.errors.map(err => `${err.path.join('.')}: ${err.message}`);
      throw new Error(
        `❌ Invalid environment variables:\n${missingVars.join('\n')}\n\nPlease check your .env.local file.`
      );
    }
    throw error;
  }
}

// Export validated environment variables
export const env = validateEnv();

// Type for environment variables
export type Env = typeof env;

// Helper function to check if we're in production
export const isProduction = env.NODE_ENV === 'production';
export const isDevelopment = env.NODE_ENV === 'development';
export const isStaging = env.NODE_ENV === 'staging';

// Helper function to get base URL
export const getBaseUrl = () => {
  if (typeof window !== 'undefined') {
    // Browser should use relative URL
    return '';
  }
  
  if (env.NEXT_PUBLIC_APP_URL) {
    // Use configured URL
    return env.NEXT_PUBLIC_APP_URL;
  }
  
  // Fallback for development
  return 'http://localhost:3000';
};

// Database configuration helper
export const getDatabaseConfig = () => ({
  url: env.DATABASE_URL,
  supabase: {
    url: env.NEXT_PUBLIC_SUPABASE_URL,
    anonKey: env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    serviceRoleKey: env.SUPABASE_SERVICE_ROLE_KEY,
  },
});

// Authentication configuration helper
export const getAuthConfig = () => ({
  jwt: {
    secret: env.JWT_SECRET,
    expiresIn: env.JWT_EXPIRES_IN,
  },
  nextAuth: {
    url: env.NEXTAUTH_URL,
    secret: env.NEXTAUTH_SECRET,
  },
  oauth: {
    google: {
      clientId: env.GOOGLE_CLIENT_ID,
      clientSecret: env.GOOGLE_CLIENT_SECRET,
    },
  },
});

// Feature flags helper
export const getFeatureFlags = () => ({
  multitenancy: env.NEXT_PUBLIC_ENABLE_MULTITENANCY,
  payments: env.NEXT_PUBLIC_ENABLE_PAYMENTS,
  aiFeatures: env.NEXT_PUBLIC_ENABLE_AI_FEATURES,
});
```

### 4. Environment Configuration Hook

**File**: `src/hooks/use-env.ts`
```typescript
import { env, getFeatureFlags } from '@/lib/env';

export function useEnv() {
  return {
    env,
    features: getFeatureFlags(),
    isProduction: env.NODE_ENV === 'production',
    isDevelopment: env.NODE_ENV === 'development',
    appName: env.NEXT_PUBLIC_APP_NAME,
    appUrl: env.NEXT_PUBLIC_APP_URL,
    appVersion: env.NEXT_PUBLIC_APP_VERSION,
  };
}

// Feature flag hooks
export function useFeatureFlag(flag: keyof ReturnType<typeof getFeatureFlags>) {
  const features = getFeatureFlags();
  return features[flag];
}

export function useMultitenancy() {
  return useFeatureFlag('multitenancy');
}

export function usePayments() {
  return useFeatureFlag('payments');
}

export function useAiFeatures() {
  return useFeatureFlag('aiFeatures');
}
```

### 5. Environment-Specific Configurations

**File**: `.env.development`
```bash
# Development Environment Overrides
NODE_ENV="development"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
LOG_LEVEL="debug"
ENABLE_REQUEST_LOGGING="true"
ENABLE_QUERY_LOGGING="true"
```

**File**: `.env.staging`
```bash
# Staging Environment Overrides
NODE_ENV="staging"
NEXT_PUBLIC_APP_URL="https://staging.yourschool.com"
LOG_LEVEL="info"
ENABLE_REQUEST_LOGGING="false"
```

**File**: `.env.production`
```bash
# Production Environment Overrides
NODE_ENV="production"
LOG_LEVEL="warn"
ENABLE_REQUEST_LOGGING="false"
ENABLE_QUERY_LOGGING="false"
```

### 6. Package.json Dependencies

**File**: `package.json` (add these dependencies)
```json
{
  "dependencies": {
    "zod": "^3.22.4"
  },
  "scripts": {
    "env:check": "node -e \"require('./src/lib/env.ts')\"",
    "env:example": "cp .env.example .env.local"
  }
}
```

### 7. Git Configuration Updates

**File**: `.gitignore` (add these lines)
```
# Environment variables
.env
.env.local
.env.development.local
.env.staging.local
.env.production.local

# Backup env files
.env.backup
*.env.backup
```

### 8. Documentation

**File**: `docs/ENVIRONMENT_SETUP.md`
```markdown
# Environment Variables Setup Guide

## Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env.local
   ```

2. Fill in the required values in `.env.local`

3. Verify your configuration:
   ```bash
   npm run env:check
   ```

## Required Variables

### Critical (Must be set)
- `NEXT_PUBLIC_APP_URL`: Your application URL
- `NEXT_PUBLIC_SUPABASE_URL`: Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Supabase anonymous key
- `JWT_SECRET`: JWT signing secret (min 32 characters)
- `NEXTAUTH_SECRET`: NextAuth.js secret (min 32 characters)

### Optional (Can be added later)
- OAuth credentials (Google, Microsoft)
- Payment processing (Stripe, PayPal)
- Email services (Resend, SendGrid)
- Monitoring (Sentry, Analytics)

## Environment-Specific Files

- `.env.local`: Local development (gitignored)
- `.env.development`: Development defaults
- `.env.staging`: Staging configuration
- `.env.production`: Production configuration

## Security Best Practices

1. Never commit `.env.local` or any file with real secrets
2. Use different secrets for each environment
3. Rotate secrets regularly
4. Use strong, randomly generated secrets
5. Limit access to production environment variables

## Troubleshooting

Common issues and solutions:

### "Invalid environment variables" error
- Check that all required variables are set
- Verify the format of URLs and email addresses
- Ensure JWT_SECRET is at least 32 characters

### Database connection issues
- Verify DATABASE_URL format
- Check Supabase credentials
- Ensure database is accessible

### OAuth login not working
- Verify OAuth client IDs and secrets
- Check redirect URLs in OAuth provider settings
- Ensure NEXTAUTH_URL matches your domain
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Environment Validation Test
```bash
# Test environment variable parsing
npm run env:check

# Verify validation catches missing variables
# Test with invalid values
```

### 2. Type Safety Test
```typescript
// Test in a TypeScript file
import { env } from '@/lib/env';

// Should have IntelliSense and type checking
console.log(env.NEXT_PUBLIC_APP_NAME);
console.log(env.NEXT_PUBLIC_ENABLE_MULTITENANCY); // boolean
```

### 3. Feature Flag Test
```bash
# Test feature flags work
# Verify environment-specific overrides
# Test hook functionality
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] Complete environment variables structure
- [x] Type-safe environment variable access
- [x] Validation for required variables
- [x] Example configuration file
- [x] Git security maintained (.env.local ignored)
- [x] Documentation for setup
- [x] Environment-specific configurations

### Should Have
- [x] Feature flags system
- [x] Helper functions for common configs
- [x] React hooks for environment access
- [x] Development vs production settings
- [x] Error handling for missing variables
- [x] Security best practices documented

### Could Have
- [x] Environment checking scripts
- [x] Multiple environment file support
- [x] Configuration helpers
- [x] Troubleshooting documentation
- [x] Type-safe feature flags
- [x] Environment setup automation

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-004 (ESLint & Prettier Configuration)  
**Depends On**: Project structure and TypeScript setup  
**Blocks**: SPEC-006 (Package.json Configuration)  

---

## 📝 IMPLEMENTATION NOTES

### Key Design Decisions
1. **Zod Validation**: Runtime validation ensures environment integrity
2. **Type Safety**: Full TypeScript support for environment variables
3. **Feature Flags**: Built-in feature toggle system
4. **Environment Separation**: Clear separation between environments
5. **Security First**: Comprehensive security practices

### Environment Variable Categories
- **App Configuration**: Basic app settings
- **Database**: All database connection settings
- **Authentication**: JWT, OAuth, and auth services
- **External Services**: Email, payments, storage, etc.
- **Feature Flags**: Toggle features on/off
- **Monitoring**: Analytics and error tracking

### Security Considerations
- Never commit actual secrets to version control
- Use different secrets for each environment
- Minimum length requirements for sensitive keys
- Clear documentation on secret management

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-006 (Package.json Dependencies)
2. ✅ Set up local development environment
3. ✅ Test environment variable validation
4. ✅ Document team environment setup process

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-006-package-json.md