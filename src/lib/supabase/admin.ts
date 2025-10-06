/**
 * Supabase Admin Client
 * Uses Service Role Key for admin operations
 * ⚠️ ONLY use in server-side code, NEVER expose to client
 */

import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')
}

export const supabaseAdmin = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        'x-application-name': 'school-management-saas-admin',
      },
    },
    db: {
      schema: 'public',
    },
  }
)

/**
 * Admin functions that bypass RLS policies
 */

export async function getUserById(userId: string) {
  const { data, error } = await supabaseAdmin.auth.admin.getUserById(userId)
  if (error) throw error
  return data
}

export async function listUsers(page = 1, perPage = 10) {
  const { data, error } = await supabaseAdmin.auth.admin.listUsers({
    page,
    perPage,
  })
  if (error) throw error
  return data
}

export async function deleteUser(userId: string) {
  const { data, error } = await supabaseAdmin.auth.admin.deleteUser(userId)
  if (error) throw error
  return data
}

export async function updateUserMetadata(userId: string, metadata: Record<string, any>) {
  const { data, error } = await supabaseAdmin.auth.admin.updateUserById(userId, {
    user_metadata: metadata,
  })
  if (error) throw error
  return data
}
