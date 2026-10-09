import { dict } from '../i18n'

export function formatDuration(sec, compact = false) {
  const u = dict.value.fmt
  sec = Math.round(Number(sec) || 0)
  if (sec <= 0) return u.zero

  const h = Math.floor(sec / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = sec % 60

  const H = compact ? u.hShort : u.hLong
  const M = compact ? u.minShort : u.minLong
  const S = compact ? u.sShort : u.sLong

  if (h > 0) {
    if (compact) {
      return `${h}${H} ${m}${M}`
    }
    return `${h} ${H} ${m > 0 ? `${m} ${M}` : ''}`.trim()
  }
  if (m > 0) {
    if (compact) {
      return `${m}${M} ${s > 0 ? `${s}${S}` : ''}`.trim()
    }
    return `${m} ${M} ${s > 0 ? `${s} ${S}` : ''}`.trim()
  }
  return compact ? `${s}${S}` : `${s} ${S}`
}

export function formatHoursDecimal(sec) {
  const h = (Number(sec) || 0) / 3600
  if (h < 0.1) return null
  return `${h.toFixed(1)} ${dict.value.fmt.hoursDecimal}`
}

// Индекс дня недели (0 — понедельник) из ISO-даты "ГГГГ-ММ-ДД".
// Ruby присылает день недели по-русски — UI теперь сам вычисляет его из даты.
export function weekdayIndexFrom(dateStr) {
  const parts = String(dateStr || '').split('-').map(Number)
  if (parts.length !== 3 || parts.some(Number.isNaN)) return -1
  const d = new Date(parts[0], parts[1] - 1, parts[2])
  return (d.getDay() + 6) % 7
}

export function formatDate(dateStr, todayStr) {
  if (!dateStr) return '—'
  const u = dict.value.fmt
  if (dateStr === todayStr) return u.today

  const parts = dateStr.split('-')
  if (parts.length !== 3) return dateStr

  const year = parseInt(parts[0], 10)
  const month = parseInt(parts[1], 10) - 1
  const day = parseInt(parts[2], 10)
  const monthName = u.months[month] || ''

  if (year === new Date().getFullYear()) {
    return u.dateShort.replace('{day}', day).replace('{month}', monthName)
  }
  return u.dateLong
    .replace('{day}', day)
    .replace('{month}', monthName)
    .replace('{year}', year)
}

export function formatDateRange(firstSeen, lastSeen) {
  if (!firstSeen || !lastSeen) return null
  if (firstSeen === lastSeen) return formatDate(firstSeen)
  return `${formatDate(firstSeen)} — ${formatDate(lastSeen)}`
}
