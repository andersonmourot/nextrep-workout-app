import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import { ScrollToTop } from './components/ScrollToTop.tsx'

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

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <ScrollToTop />
      <App />
    </BrowserRouter>
  </StrictMode>,
)

// Register the service worker (PWA install + offline shell) in production only.
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // Registration failure is non-fatal; the app still works online.
    })
  })
}
