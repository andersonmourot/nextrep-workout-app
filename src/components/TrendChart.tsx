/** A small SVG line/area chart for a dated series of values. */
export function TrendChart({
  points,
  accent = 'rgb(var(--accent))',
  emptyLabel = 'Add an entry to start a trend line.',
  oneMoreLabel = 'Add one more entry to see your trend.',
}: {
  points: { value: number }[]
  accent?: string
  emptyLabel?: string
  oneMoreLabel?: string
}) {
  if (points.length < 2) {
    return (
      <div className="grid h-32 place-items-center rounded-xl border border-dashed border-white/10 bg-ink-900/50 text-center text-xs text-zinc-500">
        {points.length === 0 ? emptyLabel : oneMoreLabel}
      </div>
    )
  }

  const w = 320
  const h = 120
  const pad = 12
  const values = points.map((p) => p.value)
  const min = Math.min(...values)
  const max = Math.max(...values)
  const range = max - min || 1
  const n = points.length

  const coords = points.map((p, i) => {
    const x = pad + (i / (n - 1)) * (w - pad * 2)
    const y = pad + (1 - (p.value - min) / range) * (h - pad * 2)
    return [x, y] as const
  })

  const path = coords
    .map(([x, y], i) => `${i === 0 ? 'M' : 'L'} ${x.toFixed(1)} ${y.toFixed(1)}`)
    .join(' ')
  const area = `${path} L ${coords[n - 1][0].toFixed(1)} ${h - pad} L ${coords[0][0].toFixed(1)} ${h - pad} Z`
  const gid = `tc-${Math.round(min)}-${Math.round(max)}-${n}`

  return (
    <svg viewBox={`0 0 ${w} ${h}`} className="w-full" preserveAspectRatio="none">
      <defs>
        <linearGradient id={gid} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={accent} stopOpacity="0.35" />
          <stop offset="100%" stopColor={accent} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill={`url(#${gid})`} />
      <path
        d={path}
        fill="none"
        stroke={accent}
        strokeWidth={2.5}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      {coords.map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r={2.5} fill={accent} />
      ))}
    </svg>
  )
}
