import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'

export function ScrollToTop() {
  const { pathname } = useLocation()
  useEffect(() => {
    // The app-shell scrolls inside <main id="app-scroll">, not the window.
    const main = document.getElementById('app-scroll')
    if (main) main.scrollTo(0, 0)
    window.scrollTo(0, 0)
  }, [pathname])
  return null
}
