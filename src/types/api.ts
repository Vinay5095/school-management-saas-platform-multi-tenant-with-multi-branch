import { NextRequest, NextResponse } from 'next/server';
import { User } from './index';

// API Handler Types
export type ApiHandler = (
  request: NextRequest,
  context?: { params: Record<string, string> }
) => Promise<NextResponse>;

export interface ApiError {
  message: string;
  statusCode: number;
  code?: string;
}

export interface ApiSuccess<T = unknown> {
  data: T;
  message?: string;
  statusCode?: number;
}

// Request/Response Types
export interface CreateUserRequest {
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  tenantId: string;
  branchId?: string;
}

export interface UpdateUserRequest {
  firstName?: string;
  lastName?: string;
  isActive?: boolean;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  token: string;
  refreshToken: string;
}

// Pagination Types
export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  search?: string;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}
