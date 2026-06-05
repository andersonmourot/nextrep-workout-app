import { useEffect, useState } from 'react'

/** The non-standard beforeinstallprompt event (Chromium browsers only). */
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

/** True when the app is running as an installed PWA (standalone display). */
function detectStandalone(): boolean {
  if (typeof window === 'undefined') return false
  const iosStandalone = (window.navigator as { standalone?: boolean }).standalone === true
  return window.matchMedia('(display-mode: standalone)').matches || iosStandalone
}

/** True for iOS Safari, where install must be done via the Share menu. */
function detectIOS(): boolean {
  if (typeof navigator === 'undefined') return false
  const ua = navigator.userAgent
  const isIOSDevice =
    /iphone|ipad|ipod/i.test(ua) ||
    // iPadOS 13+ reports as Mac but is touch-capable.
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  return isIOSDevice
}

interface PwaInstall {
  /** Android/desktop Chrome captured a native install prompt we can fire. */
  canPrompt: boolean
  /** Fire the native install prompt; resolves to true if the user accepted. */
  promptInstall: () => Promise<boolean>
  /** Running on iOS, where we show manual Share-menu instructions instead. */
  isIOS: boolean
  /** Already installed / launched from the home screen. */
  isStandalone: boolean
}

export function usePwaInstall(): PwaInstall {
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null)
  const [isStandalone, setIsStandalone] = useState(detectStandalone)
  const isIOS = detectIOS()

  useEffect(() => {
    const onBeforeInstall = (e: Event) => {
      e.preventDefault() // stop Chrome's mini-infobar; we trigger it from our button
      setDeferred(e as BeforeInstallPromptEvent)
    }
    const onInstalled = () => {
      setDeferred(null)
      setIsStandalone(true)
    }
    window.addEventListener('beforeinstallprompt', onBeforeInstall)
    window.addEventListener('appinstalled', onInstalled)

    const mq = window.matchMedia('(display-mode: standalone)')
    const onChange = () => setIsStandalone(detectStandalone())
    mq.addEventListener?.('change', onChange)

    return () => {
      window.removeEventListener('beforeinstallprompt', onBeforeInstall)
      window.removeEventListener('appinstalled', onInstalled)
      mq.removeEventListener?.('change', onChange)
    }
  }, [])

  async function promptInstall(): Promise<boolean> {
    if (!deferred) return false
    await deferred.prompt()
    const choice = await deferred.userChoice
    setDeferred(null)
    return choice.outcome === 'accepted'
  }

  return { canPrompt: deferred !== null, promptInstall, isIOS, isStandalone }
}
