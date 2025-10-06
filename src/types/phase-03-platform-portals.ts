/**
 * PHASE 3: PLATFORM PORTALS - TYPE DEFINITIONS
 * Type definitions for all 35 specifications in Phase 3
 */

// ============================================================================
// SUPER ADMIN PORTAL TYPES (SPEC-116 to SPEC-130)
// ============================================================================

/**
 * Platform metrics for dashboard overview (SPEC-116)
 */
export interface PlatformMetrics {
  id: string;
  metricDate: Date;
  totalTenants: number;
  activeTenants: number;
  trialTenants: number;
  suspendedTenants: number;
  churnedTenants: number;
  totalUsers: number;
  activeUsers30d: number;
  newTenantsToday: number;
  newUsersToday: number;
  mrr: number;
  arr: number;
  churnRate?: number;
  growthRate?: number;
  avgRevenuePerTenant?: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Platform dashboard data
 */
export interface PlatformDashboard {
  totalTenants: number;
  activeTenants: number;
  trialTenants: number;
  totalUsers: number;
  currentMrr: number;
  openTickets: number;
  lastUpdated: Date;
}

/**
 * Tenant status types
 */
export type TenantStatus = 'active' | 'trial' | 'suspended' | 'churned' | 'inactive';

/**
 * Subscription plan types
 */
export type SubscriptionPlan = 'starter' | 'professional' | 'enterprise';

/**
 * Enhanced tenant with platform management features (SPEC-117)
 */
export interface Tenant {
  id: string;
  name: string;
  slug: string;
  subdomain: string;
  domain?: string;
  billingEmail: string;
  subscriptionPlan: SubscriptionPlan;
  status: TenantStatus;
  plan: string;
  isActive: boolean;
  maxBranches: number;
  maxStudents?: number;
  maxStaff?: number;
  settings: Record<string, any>;
  featureFlags: Record<string, boolean>;
  limits: TenantLimits;
  metadata: Record<string, any>;
  lastActivityAt?: Date;
  suspendedAt?: Date;
  suspendedReason?: string;
  trialEndsAt?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

/**
 * Tenant usage limits
 */
export interface TenantLimits {
  maxUsers: number;
  maxBranches: number;
  maxStudents: number;
  maxStorage: number; // in MB
  apiCallsPerMonth: number;
  emailsPerMonth: number;
}

/**
 * Tenant form data for creation/update
 */
export interface TenantFormData {
  name: string;
  slug: string;
  subdomain: string;
  domain?: string;
  billingEmail: string;
  subscriptionPlan: SubscriptionPlan;
  settings?: {
    timezone?: string;
    dateFormat?: string;
    currency?: string;
    language?: string;
  };
  featureFlags?: {
    advancedReporting?: boolean;
    apiAccess?: boolean;
    customBranding?: boolean;
    ssoIntegration?: boolean;
  };
  limits?: Partial<TenantLimits>;
  notes?: string;
}

/**
 * Tenant overview for listing
 */
export interface TenantOverview {
  id: string;
  name: string;
  slug: string;
  domain?: string;
  status: TenantStatus;
  subscriptionPlan: SubscriptionPlan;
  billingEmail: string;
  trialEndsAt?: Date;
  createdAt: Date;
  lastActivityAt?: Date;
  userCount: number;
  branchCount: number;
  monthlyPrice?: number;
  subscriptionStatus?: string;
}

/**
 * Tenant audit log entry (SPEC-119)
 */
export interface TenantAuditLog {
  id: string;
  tenantId: string;
  action: string;
  performedBy?: string;
  changes?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

/**
 * Platform activity log (SPEC-119)
 */
export interface PlatformActivityLog {
  id: string;
  entityType: string;
  entityId?: string;
  action: string;
  performedBy?: string;
  tenantId?: string;
  details?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

/**
 * System health metrics (SPEC-118)
 */
export interface SystemHealthMetric {
  id: string;
  metricType: string;
  metricName: string;
  value?: number;
  status: 'healthy' | 'warning' | 'critical' | 'unknown';
  details?: Record<string, any>;
  recordedAt: Date;
  createdAt: Date;
}

/**
 * Feature flag (SPEC-121)
 */
export interface FeatureFlag {
  id: string;
  name: string;
  key: string;
  description?: string;
  enabled: boolean;
  rolloutPercentage: number;
  targetTenants?: string[];
  targetPlans?: string[];
  conditions?: Record<string, any>;
  createdBy?: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * System configuration (SPEC-122)
 */
export interface SystemConfiguration {
  id: string;
  key: string;
  value: any;
  category?: string;
  description?: string;
  isSensitive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * API key (SPEC-124)
 */
export interface ApiKey {
  id: string;
  tenantId?: string;
  name: string;
  keyHash: string;
  keyPrefix: string;
  permissions: string[];
  rateLimit: number;
  expiresAt?: Date;
  lastUsedAt?: Date;
  isActive: boolean;
  createdBy?: string;
  createdAt: Date;
  revokedAt?: Date;
}

// ============================================================================
// PLATFORM FINANCE PORTAL TYPES (SPEC-131 to SPEC-140)
// ============================================================================

/**
 * Subscription billing cycle
 */
export type BillingCycle = 'monthly' | 'yearly';

/**
 * Subscription status
 */
export type SubscriptionStatus = 'active' | 'trialing' | 'past_due' | 'canceled' | 'unpaid';

/**
 * Subscription (SPEC-123, SPEC-134)
 */
export interface Subscription {
  id: string;
  tenantId: string;
  planName: string;
  billingCycle: BillingCycle;
  status: SubscriptionStatus;
  monthlyPrice: number;
  yearlyPrice?: number;
  currency: string;
  stripeSubscriptionId?: string;
  stripeCustomerId?: string;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
  trialStart?: Date;
  trialEnd?: Date;
  canceledAt?: Date;
  endedAt?: Date;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Invoice status
 */
export type InvoiceStatus = 'draft' | 'open' | 'paid' | 'void' | 'uncollectible';

/**
 * Invoice (SPEC-132)
 */
export interface Invoice {
  id: string;
  tenantId: string;
  subscriptionId?: string;
  invoiceNumber: string;
  status: InvoiceStatus;
  subtotal: number;
  tax: number;
  discount: number;
  total: number;
  currency: string;
  stripeInvoiceId?: string;
  stripePaymentIntentId?: string;
  dueDate?: Date;
  paidAt?: Date;
  items: InvoiceItem[];
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Invoice line item
 */
export interface InvoiceItem {
  id: string;
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
}

/**
 * Payment status
 */
export type PaymentStatus = 'pending' | 'succeeded' | 'failed' | 'refunded';

/**
 * Payment (SPEC-133)
 */
export interface Payment {
  id: string;
  tenantId: string;
  invoiceId?: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  paymentMethod?: string;
  stripePaymentId?: string;
  stripeChargeId?: string;
  failureReason?: string;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Refund status
 */
export type RefundStatus = 'pending' | 'succeeded' | 'failed' | 'canceled';

/**
 * Refund (SPEC-137)
 */
export interface Refund {
  id: string;
  paymentId: string;
  tenantId: string;
  amount: number;
  currency: string;
  reason?: string;
  status: RefundStatus;
  stripeRefundId?: string;
  createdBy?: string;
  createdAt: Date;
  processedAt?: Date;
}

/**
 * Pricing plan (SPEC-138)
 */
export interface PricingPlan {
  id: string;
  name: string;
  slug: string;
  description?: string;
  monthlyPrice: number;
  yearlyPrice?: number;
  currency: string;
  features: string[];
  limits: Record<string, number>;
  isActive: boolean;
  isFeatured: boolean;
  sortOrder: number;
  stripeMonthlyPriceId?: string;
  stripeYearlyPriceId?: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Coupon discount type
 */
export type DiscountType = 'percentage' | 'fixed';

/**
 * Coupon (SPEC-139)
 */
export interface Coupon {
  id: string;
  code: string;
  name: string;
  description?: string;
  discountType: DiscountType;
  discountValue: number;
  currency: string;
  maxRedemptions?: number;
  timesRedeemed: number;
  validFrom?: Date;
  validUntil?: Date;
  appliesTo: 'all' | 'specific_plans';
  planIds?: string[];
  isActive: boolean;
  stripeCouponId?: string;
  createdBy?: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Coupon redemption
 */
export interface CouponRedemption {
  id: string;
  couponId: string;
  tenantId: string;
  subscriptionId?: string;
  redeemedAt: Date;
}

/**
 * Revenue metrics (SPEC-131)
 */
export interface RevenueMetrics {
  id: string;
  metricDate: Date;
  tenantId?: string;
  mrr: number;
  arr: number;
  newMrr: number;
  expansionMrr: number;
  contractionMrr: number;
  churnedMrr: number;
  totalRevenue: number;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// PLATFORM SUPPORT PORTAL TYPES (SPEC-131 to SPEC-140)
// ============================================================================

/**
 * Support ticket status
 */
export type TicketStatus = 
  | 'open' 
  | 'in_progress' 
  | 'waiting_on_customer' 
  | 'waiting_on_agent'
  | 'resolved' 
  | 'closed';

/**
 * Support ticket priority
 */
export type TicketPriority = 'low' | 'medium' | 'high' | 'urgent';

/**
 * Support ticket (SPEC-131, SPEC-132)
 */
export interface SupportTicket {
  id: string;
  ticketNumber: string;
  tenantId?: string;
  subject: string;
  description: string;
  status: TicketStatus;
  priority: TicketPriority;
  category?: string;
  assignedTo?: string;
  createdBy: string;
  tags: string[];
  slaDueAt?: Date;
  firstResponseAt?: Date;
  resolvedAt?: Date;
  closedAt?: Date;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Ticket message (SPEC-133)
 */
export interface TicketMessage {
  id: string;
  ticketId: string;
  message: string;
  isInternal: boolean;
  createdBy: string;
  attachments: Attachment[];
  createdAt: Date;
}

/**
 * File attachment
 */
export interface Attachment {
  id: string;
  filename: string;
  filesize: number;
  mimeType: string;
  url: string;
}

/**
 * Ticket assignment (SPEC-134)
 */
export interface TicketAssignment {
  id: string;
  ticketId: string;
  assignedTo: string;
  assignedBy?: string;
  assignedAt: Date;
  unassignedAt?: Date;
}

/**
 * Knowledge base article (SPEC-136)
 */
export interface KnowledgeBaseArticle {
  id: string;
  title: string;
  slug: string;
  content: string;
  excerpt?: string;
  category?: string;
  tags: string[];
  isPublished: boolean;
  viewCount: number;
  helpfulCount: number;
  authorId: string;
  publishedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Chat session status
 */
export type ChatStatus = 'active' | 'ended' | 'transferred';

/**
 * Live chat session (SPEC-137)
 */
export interface ChatSession {
  id: string;
  tenantId?: string;
  visitorId: string;
  agentId?: string;
  status: ChatStatus;
  startedAt: Date;
  endedAt?: Date;
  metadata: Record<string, any>;
}

/**
 * Chat message type
 */
export type MessageType = 'text' | 'file' | 'system';

/**
 * Chat message
 */
export interface ChatMessage {
  id: string;
  sessionId: string;
  senderId: string;
  message: string;
  messageType: MessageType;
  createdAt: Date;
}

/**
 * Email template (SPEC-138)
 */
export interface EmailTemplate {
  id: string;
  name: string;
  subject: string;
  bodyHtml: string;
  bodyText?: string;
  category?: string;
  variables: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Support metrics (SPEC-139)
 */
export interface SupportMetrics {
  id: string;
  metricDate: Date;
  totalTickets: number;
  openTickets: number;
  resolvedTickets: number;
  avgFirstResponseTime?: number; // in minutes
  avgResolutionTime?: number; // in minutes
  customerSatisfactionScore?: number;
  ticketsByPriority: Record<string, number>;
  ticketsByCategory: Record<string, number>;
  createdAt: Date;
}

/**
 * SLA policy (SPEC-140)
 */
export interface SlaPolicy {
  id: string;
  name: string;
  priority: TicketPriority;
  firstResponseTime: number; // in minutes
  resolutionTime: number; // in minutes
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// NOTIFICATIONS (SPEC-129)
// ============================================================================

/**
 * System notification
 */
export interface Notification {
  id: string;
  userId: string;
  tenantId?: string;
  type: string;
  title: string;
  message: string;
  link?: string;
  isRead: boolean;
  readAt?: Date;
  metadata: Record<string, any>;
  createdAt: Date;
}

// ============================================================================
// API RESPONSE TYPES
// ============================================================================

/**
 * Paginated response
 */
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  perPage: number;
  totalPages: number;
}

/**
 * API success response
 */
export interface ApiResponse<T> {
  success: true;
  data: T;
  message?: string;
}

/**
 * API error response
 */
export interface ApiError {
  success: false;
  error: string;
  message: string;
  details?: any;
}

/**
 * Statistics for dashboard cards
 */
export interface DashboardStat {
  label: string;
  value: number | string;
  change?: number;
  changeType?: 'increase' | 'decrease';
  trend?: number[];
  icon?: string;
}

// ============================================================================
// FILTER AND SEARCH TYPES
// ============================================================================

/**
 * Common filter parameters
 */
export interface FilterParams {
  page?: number;
  perPage?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  search?: string;
}

/**
 * Tenant filter parameters
 */
export interface TenantFilterParams extends FilterParams {
  status?: TenantStatus[];
  plan?: SubscriptionPlan[];
  createdAfter?: Date;
  createdBefore?: Date;
}

/**
 * Ticket filter parameters
 */
export interface TicketFilterParams extends FilterParams {
  status?: TicketStatus[];
  priority?: TicketPriority[];
  category?: string[];
  assignedTo?: string;
  tenantId?: string;
  createdAfter?: Date;
  createdBefore?: Date;
}

/**
 * Invoice filter parameters
 */
export interface InvoiceFilterParams extends FilterParams {
  status?: InvoiceStatus[];
  tenantId?: string;
  dueAfter?: Date;
  dueBefore?: Date;
  paidAfter?: Date;
  paidBefore?: Date;
}
