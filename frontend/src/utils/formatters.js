export function formatDuration(sec, compact = false) {
  sec = Math.round(Number(sec) || 0)
  if (sec <= 0) return '0 с'

  const h = Math.floor(sec / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = sec % 60

  if (h > 0) {
    if (compact) {
      return `${h}ч ${m}м`
    }
    return `${h} ч ${m > 0 ? `${m} мин` : ''}`.trim()
  }
  if (m > 0) {
    if (compact) {
      return `${m}м ${s > 0 ? `${s}с` : ''}`.trim()
    }
    return `${m} мин ${s > 0 ? `${s} с` : ''}`.trim()
  }
  return `${s} с`
}

export function formatHoursDecimal(sec) {
  const h = (Number(sec) || 0) / 3600
  if (h < 0.1) return null
  return `${h.toFixed(1)} ч`
}

const MONTHS_RU = [
  'янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
]

export function formatDateRu(dateStr, todayStr) {
  if (!dateStr) return '—'
  if (dateStr === todayStr) return 'Сегодня'

  const parts = dateStr.split('-')
  if (parts.length !== 3) return dateStr

  const year = parseInt(parts[0], 10)
  const month = parseInt(parts[1], 10) - 1
  const day = parseInt(parts[2], 10)

  const curYear = new Date().getFullYear()
  const monthName = MONTHS_RU[month] || ''

  if (year === curYear) {
    return `${day} ${monthName}`
  }
  return `${day} ${monthName} ${year}`
}

export function formatDateRange(firstSeen, lastSeen) {
  if (!firstSeen || !lastSeen) return null
  if (firstSeen === lastSeen) return formatDateRu(firstSeen)
  return `${formatDateRu(firstSeen)} — ${formatDateRu(lastSeen)}`
}
