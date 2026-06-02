import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { useStore, loadCurrentUserData } from './store'

export interface AuthUser {
  id: string
  name: string
  email: string
  salt: string
  passwordHash: string
  createdAt: string
}

interface AuthResult {
  ok: boolean
  error?: string
}

interface AuthState {
  users: AuthUser[]
  currentUserId: string | null
  signUp: (name: string, email: string, password: string) => Promise<AuthResult>
  login: (email: string, password: string) => Promise<AuthResult>
  logout: () => void
}

function uid(): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
}

async function hashPassword(password: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(`${salt}:${password}`)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      users: [],
      currentUserId: null,

      signUp: async (name, email, password) => {
        const cleanName = name.trim()
        const cleanEmail = email.trim().toLowerCase()
        if (!cleanName) return { ok: false, error: 'Enter your name.' }
        if (!EMAIL_RE.test(cleanEmail)) return { ok: false, error: 'Enter a valid email address.' }
        if (password.length < 6)
          return { ok: false, error: 'Password must be at least 6 characters.' }
        if (get().users.some((u) => u.email === cleanEmail))
          return { ok: false, error: 'An account with that email already exists.' }

        const salt = uid()
        const passwordHash = await hashPassword(password, salt)
        const user: AuthUser = {
          id: uid(),
          name: cleanName,
          email: cleanEmail,
          salt,
          passwordHash,
          createdAt: new Date().toISOString(),
        }
        set((s) => ({ users: [...s.users, user], currentUserId: user.id }))
        await loadCurrentUserData()
        useStore.getState().setName(cleanName)
        return { ok: true }
      },

      login: async (email, password) => {
        const cleanEmail = email.trim().toLowerCase()
        const user = get().users.find((u) => u.email === cleanEmail)
        if (!user) return { ok: false, error: 'No account found for that email.' }
        const hash = await hashPassword(password, user.salt)
        if (hash !== user.passwordHash) return { ok: false, error: 'Incorrect password.' }
        set({ currentUserId: user.id })
        await loadCurrentUserData()
        return { ok: true }
      },

      logout: () => {
        set({ currentUserId: null })
        void loadCurrentUserData()
      },
    }),
    { name: 'smellis-auth-v1' },
  ),
)

export function getCurrentUserId(): string | null {
  return useAuth.getState().currentUserId
}
