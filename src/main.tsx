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

// iOS standalone (PWA) reports a too-short screen height on the first paint, so
// `height: 100%`/`100dvh`/`position:fixed` all leave the bottom nav floating
// high until a touch forces a reflow. We instead drive the shell height from a
// JS-measured pixel value and re-measure whenever the viewport actually changes
// (and a few times right after load, since iOS settles the real height a beat
// after launch). `window.innerHeight` is the full screen in standalone and does
// NOT shrink when the keyboard opens, so the keyboard keeps covering the nav as
// before instead of squashing the layout.
function setAppHeight() {
  document.documentElement.style.setProperty('--app-height', `${window.innerHeight}px`)
}
setAppHeight()
window.addEventListener('resize', setAppHeight)
window.addEventListener('orientationchange', setAppHeight)
window.addEventListener('pageshow', setAppHeight)
window.addEventListener('load', () => {
  setAppHeight()
  // iOS may not have finalized the viewport on `load`; re-measure as it settles.
  setTimeout(setAppHeight, 100)
  setTimeout(setAppHeight, 300)
  setTimeout(setAppHeight, 600)
})

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
