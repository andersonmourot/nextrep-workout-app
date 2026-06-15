import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { apiLogin, apiMe, apiSignup, type SessionUser } from './api'
import { useStore, loadCurrentUserData, syncFromServer, clearStore } from './store'

interface AuthResult {
  ok: boolean
  error?: string
}

interface AuthState {
  token: string | null
  user: SessionUser | null
  ready: boolean
  signUp: (name: string, email: string, password: string) => Promise<AuthResult>
  login: (email: string, password: string) => Promise<AuthResult>
  logout: () => void
  init: () => Promise<void>
}

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      user: null,
      ready: false,

      signUp: async (name, email, password) => {
        const cleanName = name.trim()
        const cleanEmail = email.trim().toLowerCase()
        if (!cleanName) return { ok: false, error: 'Enter your name.' }
        if (!EMAIL_RE.test(cleanEmail)) return { ok: false, error: 'Enter a valid email address.' }
        if (password.length < 6)
          return { ok: false, error: 'Password must be at least 6 characters.' }

        const res = await apiSignup(cleanName, cleanEmail, password)
        if (!res.ok || !res.data) return { ok: false, error: res.error ?? 'Sign up failed.' }
        set({ token: res.data.token, user: res.data.user })
        await loadCurrentUserData()
        await syncFromServer()
        useStore.getState().setName(res.data.user.name)
        return { ok: true }
      },

      login: async (email, password) => {
        const cleanEmail = email.trim().toLowerCase()
        if (!EMAIL_RE.test(cleanEmail)) return { ok: false, error: 'Enter a valid email address.' }

        const res = await apiLogin(cleanEmail, password)
        if (!res.ok || !res.data) return { ok: false, error: res.error ?? 'Login failed.' }
        set({ token: res.data.token, user: res.data.user })
        await loadCurrentUserData()
        await syncFromServer()
        return { ok: true }
      },

      logout: () => {
        set({ token: null, user: null })
        clearStore()
      },

      init: async () => {
        const token = get().token
        if (!token) {
          set({ ready: true })
          return
        }
        // Optimistic hydrate from the local cache for instant UI.
        await loadCurrentUserData()
        const res = await apiMe(token)
        if (!res.ok || !res.data) {
          // Token invalid/expired — drop the session.
          set({ token: null, user: null })
          clearStore()
          set({ ready: true })
          return
        }
        set({ user: res.data })
        await syncFromServer()
        set({ ready: true })
      },
    }),
    {
      name: 'smellis-auth-v2',
      partialize: (s) => ({ token: s.token, user: s.user }),
    },
  ),
)

export function getToken(): string | null {
  return useAuth.getState().token
}

export function getCurrentUserId(): string | null {
  return useAuth.getState().user?.id ?? null
}
