/** Thin client for the SMELLIS backend (secure auth + per-user data sync). */

const BASE = (import.meta.env.VITE_API_URL ?? '').replace(/\/$/, '')

export interface SessionUser {
  id: string
  name: string
  email: string
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

export function apiGetData<T = Record<string, unknown>>(token: string): Promise<ApiResult<T>> {
  return request('/api/data', {}, token)
}

export function apiPutData(
  token: string,
  data: Record<string, unknown>,
): Promise<ApiResult<{ ok: boolean }>> {
  return request('/api/data', { method: 'PUT', body: JSON.stringify({ data }) }, token)
}
