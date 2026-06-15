/** Thin client for the NextRep backend (secure auth + per-user data sync). */

const BASE = (import.meta.env.VITE_API_URL ?? '').replace(/\/$/, '')

export interface SessionUser {
  id: string
  name: string
  email: string
  is_admin?: boolean
}

export interface AdminUser {
  id: string
  name: string
  email: string
  created_at: string
  last_login: string
  last_active: string
}

export interface AuthResponse {
  token: string
  user: SessionUser
}

export interface ApiResult<T> {
  ok: boolean
  data?: T
  error?: string
}

async function request<T>(
  path: string,
  options: RequestInit = {},
  token?: string | null,
): Promise<ApiResult<T>> {
  try {
    const res = await fetch(`${BASE}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        // Sent as X-Auth-Token (not Authorization) so the app token doesn't
        // clash with an upstream proxy/tunnel's HTTP basic auth.
        ...(token ? { 'X-Auth-Token': token } : {}),
        ...(options.headers ?? {}),
      },
    })
    if (!res.ok) {
      let detail = `Request failed (${res.status}).`
      try {
        const body = await res.json()
        if (typeof body?.detail === 'string') detail = body.detail
      } catch {
        /* keep default */
      }
      return { ok: false, error: detail }
    }
    const data = (await res.json().catch(() => undefined)) as T
    return { ok: true, data }
  } catch {
    return { ok: false, error: 'Could not reach the server. Check your connection.' }
  }
}

export function apiSignup(
  name: string,
  email: string,
  password: string,
): Promise<ApiResult<AuthResponse>> {
  return request('/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ name, email, password }),
  })
}

export function apiLogin(email: string, password: string): Promise<ApiResult<AuthResponse>> {
  return request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
}

export function apiMe(token: string): Promise<ApiResult<SessionUser>> {
  return request('/me', {}, token)
}

export function apiAdminUsers(token: string): Promise<ApiResult<AdminUser[]>> {
  return request('/api/admin/users', {}, token)
}

export function apiChangePassword(
  token: string,
  currentPassword: string,
  newPassword: string,
): Promise<ApiResult<{ ok: boolean }>> {
  return request(
    '/auth/password',
    {
      method: 'POST',
      body: JSON.stringify({ current_password: currentPassword, new_password: newPassword }),
    },
    token,
  )
}

export function apiForgotPassword(email: string): Promise<ApiResult<{ ok: boolean }>> {
  return request('/auth/forgot-password', {
    method: 'POST',
    body: JSON.stringify({ email }),
  })
}

export function apiResetPassword(
  token: string,
  newPassword: string,
): Promise<ApiResult<{ ok: boolean }>> {
  return request('/auth/reset-password', {
    method: 'POST',
    body: JSON.stringify({ token, new_password: newPassword }),
  })
}

export function apiAdminResetPassword(
  token: string,
  userId: string,
  newPassword: string,
): Promise<ApiResult<{ ok: boolean }>> {
  return request(
    `/api/admin/users/${userId}/reset-password`,
    { method: 'POST', body: JSON.stringify({ new_password: newPassword }) },
    token,
  )
}

export interface Catalog<P = unknown, E = unknown> {
  programs: P[]
  exercises: E[]
}

/**
 * Built-in program/exercise catalog, served unauthenticated. Shared by every
 * client so the catalog has one source of truth. The web app falls back to its
 * bundled copy if this can't be reached.
 */
export function apiGetCatalog<P = unknown, E = unknown>(): Promise<ApiResult<Catalog<P, E>>> {
  return request('/api/catalog')
}

/** Admin-only: replace the whole built-in catalog (persisted server-side). */
export function apiAdminPutCatalog<P = unknown, E = unknown>(
  token: string,
  catalog: Catalog<P, E>,
): Promise<ApiResult<Catalog<P, E>>> {
  return request('/api/admin/catalog', { method: 'PUT', body: JSON.stringify(catalog) }, token)
}

export function apiGetData<T = Record<string, unknown>>(token: string): Promise<ApiResult<T>> {
  return request('/api/data', {}, token)
}

export function apiPutData(
  token: string,
  data: Record<string, unknown>,
): Promise<ApiResult<{ ok: boolean }>> {
  return request('/api/data', { method: 'PUT', body: JSON.stringify({ data }) }, token)
}

// ---- Social: search / follow / shared programs ----
export interface DiscoverUser {
  id: string
  name: string
  color: string
  following: boolean
  program_count: number
  exercise_count: number
}

export interface FollowUser {
  id: string
  name: string
  color: string
  program_count: number
  exercise_count: number
}

export interface SharedUser {
  id: string
  name: string
}

export interface SharedPrograms<P = unknown> {
  user: SharedUser
  programs: P[]
}

export interface SharedExercises<E = unknown> {
  user: SharedUser
  exercises: E[]
}

export function apiSearchUsers(token: string, q: string): Promise<ApiResult<DiscoverUser[]>> {
  return request(`/api/users/search?q=${encodeURIComponent(q)}`, {}, token)
}

export function apiFollow(token: string, userId: string): Promise<ApiResult<{ ok: boolean }>> {
  return request(`/api/users/${userId}/follow`, { method: 'POST' }, token)
}

export function apiUnfollow(token: string, userId: string): Promise<ApiResult<{ ok: boolean }>> {
  return request(`/api/users/${userId}/follow`, { method: 'DELETE' }, token)
}

export function apiFollowing(token: string): Promise<ApiResult<FollowUser[]>> {
  return request('/api/following', {}, token)
}

export function apiUserPrograms<P = unknown>(
  token: string,
  userId: string,
): Promise<ApiResult<SharedPrograms<P>>> {
  return request(`/api/users/${userId}/programs`, {}, token)
}

export function apiUserExercises<E = unknown>(
  token: string,
  userId: string,
): Promise<ApiResult<SharedExercises<E>>> {
  return request(`/api/users/${userId}/exercises`, {}, token)
}

// ---- Shared programs (cross-account canonical store) ----
export function apiUpsertProgram<P>(token: string, program: P): Promise<ApiResult<{ program: P }>> {
  const id = (program as { id: string }).id
  return request(`/api/programs/${id}`, { method: 'PUT', body: JSON.stringify({ program }) }, token)
}

export function apiAddProgram<P>(token: string, id: string): Promise<ApiResult<{ program: P }>> {
  return request(`/api/programs/${id}/add`, { method: 'POST' }, token)
}

export function apiRemoveProgramMember(
  token: string,
  id: string,
): Promise<ApiResult<{ ok: boolean }>> {
  return request(`/api/programs/${id}/member`, { method: 'DELETE' }, token)
}

export function apiProgramsBatch<P>(
  token: string,
  ids: string[],
): Promise<ApiResult<{ programs: P[] }>> {
  return request('/api/programs/batch', { method: 'POST', body: JSON.stringify({ ids }) }, token)
}

// ---- Shared exercises (cross-account canonical store) ----
export function apiUpsertExercise<E>(
  token: string,
  exercise: E,
): Promise<ApiResult<{ exercise: E }>> {
  const id = (exercise as { id: string }).id
  return request(
    `/api/exercises/${id}`,
    { method: 'PUT', body: JSON.stringify({ exercise }) },
    token,
  )
}

export function apiAddExercise<E>(token: string, id: string): Promise<ApiResult<{ exercise: E }>> {
  return request(`/api/exercises/${id}/add`, { method: 'POST' }, token)
}

export function apiRemoveExerciseMember(
  token: string,
  id: string,
): Promise<ApiResult<{ ok: boolean }>> {
  return request(`/api/exercises/${id}/member`, { method: 'DELETE' }, token)
}

export function apiExercisesBatch<E>(
  token: string,
  ids: string[],
): Promise<ApiResult<{ exercises: E[] }>> {
  return request('/api/exercises/batch', { method: 'POST', body: JSON.stringify({ ids }) }, token)
}
