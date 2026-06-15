import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'

export function ScrollToTop() {
  const { pathname } = useLocation()
  useEffect(() => {
    // The app-shell scrolls inside <main id="app-scroll">, not the window.
    const main = document.getElementById('app-scroll')
    window.scrollTo(0, 0)
    if (!main) return
    main.scrollTo(0, 0)

    // iOS standalone PWA bug: after switching pages the scroll container can
    // get "stuck" — touch scrolling does nothing until something forces a
    // reflow (e.g. leaving and returning to the tab). Reproduce that reflow
    // immediately by toggling overflow off then back on across a frame, so iOS
    // recomputes the scrollable height right away instead of intermittently.
    main.style.overflowY = 'hidden'
    // Reading a layout property forces a synchronous reflow.
    void main.offsetHeight
    requestAnimationFrame(() => {
      main.style.overflowY = ''
      // A 1px nudge re-arms iOS momentum scrolling on the recomputed content.
      main.scrollTop = 1
      main.scrollTop = 0
    })
  }, [pathname])
  return null
}
