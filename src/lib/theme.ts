import type { CSSProperties } from 'react'

export type ThemeMode = 'dark' | 'light'

export const DEFAULT_THEME_COLOR = '#355e3b'
export const DEFAULT_THEME_MODE: ThemeMode = 'dark'

/** Selectable accent colors — the app's signature green plus the same palette
 *  offered in the program builder ("Accent color"). */
export const THEME_COLORS = [
  '#355e3b',
  '#e9b949',
  '#7f1d1d',
  '#3b82f6',
  '#22c55e',
  '#a855f7',
  '#f97316',
  '#14b8a6',
  '#ec4899',
]

type RGB = [number, number, number]

function hexToRgb(hex: string): RGB {
  const h = hex.replace('#', '')
  const full = h.length === 3 ? h.split('').map((c) => c + c).join('') : h
  const n = parseInt(full, 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

function mix(a: RGB, b: RGB, t: number): RGB {
  return [
    Math.round(a[0] + (b[0] - a[0]) * t),
    Math.round(a[1] + (b[1] - a[1]) * t),
    Math.round(a[2] + (b[2] - a[2]) * t),
  ]
}

/** Apply the user's accent color + light/dark mode to the document root by
 *  setting the CSS variables consumed by Tailwind (see tailwind.config.js). */
export function applyTheme(color: string, mode: ThemeMode): void {
  const root = document.documentElement
  const base = hexToRgb(color || DEFAULT_THEME_COLOR)
  root.style.setProperty('--accent', base.join(' '))
  root.style.setProperty('--accent-400', mix(base, [255, 255, 255], 0.22).join(' '))
  root.style.setProperty('--accent-600', mix(base, [0, 0, 0], 0.22).join(' '))
  root.classList.toggle('light', mode === 'light')
}

/** Inline-style object that overrides the accent CSS variables for a subtree,
 *  so all `gold` / accent Tailwind utilities inside it render in the given color
 *  (e.g. a program's own accent on its detail page) instead of the app theme. */
export function accentVars(color: string): CSSProperties {
  const base = hexToRgb(color || DEFAULT_THEME_COLOR)
  return {
    '--accent': base.join(' '),
    '--accent-400': mix(base, [255, 255, 255], 0.22).join(' '),
    '--accent-600': mix(base, [0, 0, 0], 0.22).join(' '),
  } as CSSProperties
}
