/**
 * Supabase Database Types
 * Generated from database schema
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      tenants: {
        Row: {
          id: string
          name: string
          domain: string | null
          status: 'active' | 'inactive' | 'suspended'
          subscription_plan: string | null
          subscription_status: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: string
          name: string
          domain?: string | null
          status?: 'active' | 'inactive' | 'suspended'
          subscription_plan?: string | null
          subscription_status?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          name?: string
          domain?: string | null
          status?: 'active' | 'inactive' | 'suspended'
          subscription_plan?: string | null
          subscription_status?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
      }
      users: {
        Row: {
          id: string
          tenant_id: string
          branch_id: string | null
          email: string
          first_name: string
          last_name: string
          role: 'super_admin' | 'tenant_admin' | 'branch_admin' | 'teacher' | 'student' | 'parent' | 'staff'
          status: 'active' | 'inactive' | 'suspended'
          phone: string | null
          avatar_url: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id: string
          tenant_id: string
          branch_id?: string | null
          email: string
          first_name: string
          last_name: string
          role: 'super_admin' | 'tenant_admin' | 'branch_admin' | 'teacher' | 'student' | 'parent' | 'staff'
          status?: 'active' | 'inactive' | 'suspended'
          phone?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          tenant_id?: string
          branch_id?: string | null
          email?: string
          first_name?: string
          last_name?: string
          role?: 'super_admin' | 'tenant_admin' | 'branch_admin' | 'teacher' | 'student' | 'parent' | 'staff'
          status?: 'active' | 'inactive' | 'suspended'
          phone?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
      }
      // Add other tables as needed
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_user_tenant_id: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      get_user_role: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      get_user_branch_id: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
    }
    Enums: {
      user_role: 'super_admin' | 'tenant_admin' | 'branch_admin' | 'teacher' | 'student' | 'parent' | 'staff'
      user_status: 'active' | 'inactive' | 'suspended'
      tenant_status: 'active' | 'inactive' | 'suspended'
    }
  }
}
