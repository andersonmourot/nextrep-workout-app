import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import { ScrollToTop } from './components/ScrollToTop.tsx'
import { hydrateCatalog } from './data/catalog.ts'

// In the installed (standalone) PWA on iOS, lock zoom. This stops pinch-zoom and
// the auto-zoom-on-input-focus that iOS does for small text fields (which shifts
// the layout, e.g. the reps box "sinking" while typing). Normal browser tabs
// keep pinch-zoom for accessibility.
const isStandalone =
  window.matchMedia('(display-mode: standalone)').matches ||
  (navigator as Navigator & { standalone?: boolean }).standalone === true
if (isStandalone) {
  document
    .querySelector('meta[name="viewport"]')
    ?.setAttribute(
      'content',
      'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover',
    )
}

// iOS standalone bug: on first paint innerHeight = screen.height − safeAreaTop
// (793 instead of 852 on the user's device). CSS 100%/100dvh and position:fixed
// all read this wrong value, leaving a 59 px gap below the bottom nav.
// screen.height is the true full-screen CSS-pixel height and is ALWAYS correct
// (confirmed via on-device diagnostics). Setting it as a CSS var lets the shell
// fill the real screen from the very first paint.
if (isStandalone) {
  document.documentElement.style.setProperty('--app-height', `${screen.height}px`)
  // Re-set on orientation change (screen.height swaps with width).
  window.addEventListener('orientationchange', () => {
    setTimeout(() => {
      document.documentElement.style.setProperty('--app-height', `${screen.height}px`)
    }, 150)
  })
}

function renderApp() {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <BrowserRouter>
        <ScrollToTop />
        <App />
      </BrowserRouter>
    </StrictMode>,
  )
}

// Load the shared catalog from the backend (falls back to bundled data), then
// render so all synchronous program/exercise lookups see the server data.
hydrateCatalog().finally(renderApp)

// Register the service worker (PWA install + offline shell) in production only.
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // Registration failure is non-fatal; the app still works online.
    })
  })
}
