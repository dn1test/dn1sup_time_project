import { ref, reactive, onMounted, onUnmounted } from 'vue'

const mockData = {
  status: 'active',
  paused: false,
  idle_minutes: 5,
  current: 'Малиновка ~ Детская (2 этаж).skp',
  folder: 'U:\\dn1desn\\mihail\\home\\Вадим ~ Малиновка\\Детская (2 этаж) ~ Шкафы, Стол, Потолок',
  session_seconds: 869.7,
  today: '2026-10-01',
  tick_interval: 30,
  projects: ['Малиновка ~ Детская (2 этаж).skp', 'Шкаф_встроенный_вариант2.skp'],
  selected: 'Малиновка ~ Детская (2 этаж).skp',
  stats: {
    total_seconds: 25030.0,
    today_seconds: 4948.5,
    first_seen: '2026-09-28',
    last_seen: '2026-10-01',
    days: [
      { date: '2026-10-01', weekday: 'Четверг', seconds: 4948.5 },
      { date: '2026-09-30', weekday: 'Среда', seconds: 13781.4 },
      { date: '2026-09-29', weekday: 'Вторник', seconds: 3810.1 },
      { date: '2026-09-28', weekday: 'Понедельник', seconds: 2490.0 },
    ],
    hours: [
      773.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 480.0,
      1082.2, 1014.6, 2168.8, 1957.6, 1502.9, 1408.4, 1590.0, 360.0,
      1560.1, 4023.5, 2193.5, 1830.1, 1458.5, 1626.5
    ],
    weekdays: [2490.0, 3810.1, 13781.4, 4948.5, 0.0, 0.0, 0.0]
  }
}

function getSketchup() {
  if (typeof sketchup !== 'undefined' && sketchup && typeof sketchup.call_ruby === 'function') {
    return sketchup
  }
  if (typeof window !== 'undefined' && window.sketchup && typeof window.sketchup.call_ruby === 'function') {
    return window.sketchup
  }
  return null
}

let activeUpdateCallback = null
let hasReceivedRealData = false

// Register window.updateUI at script evaluation time so SketchUp cannot execute it before ready
if (typeof window !== 'undefined') {
  window.updateUI = function (payload) {
    hasReceivedRealData = true
    if (activeUpdateCallback) {
      activeUpdateCallback(payload)
    } else {
      window._pendingPayload = payload
    }
  }
}

export function useSketchupBridge() {
  const state = reactive({
    version: '2.4.0',
    status: 'off',
    paused: false,
    idle_minutes: 5,
    current: null,
    folder: '',
    session_seconds: 0,
    today: new Date().toISOString().slice(0, 10),
    tick_interval: 30,
    projects: [],
    selected: null,
    stats: {
      total_seconds: 0,
      today_seconds: 0,
      first_seen: null,
      last_seen: null,
      days: [],
      hours: Array(24).fill(0),
      weekdays: Array(7).fill(0),
    }
  })

  const isUpdatingDev = ref(false)
  const isRefreshing = ref(false)
  const isCopied = ref(false)
  let pollTimer = null
  let sessionTimer = null

  function callRuby(name, param) {
    const bridge = getSketchup()
    if (bridge) {
      try {
        bridge.call_ruby(name, param !== undefined ? String(param) : '')
        return true
      } catch (e) {
        console.warn('Call Ruby error:', e)
      }
    } else {
      // In browser mock mode
      console.log('[Mock Dev] callRuby:', name, param)
      if (name === 'toggle_pause') {
        state.paused = !state.paused
        state.status = state.paused ? 'paused' : 'active'
      } else if (name === 'set_idle_minutes') {
        state.idle_minutes = parseFloat(param) || 5
      } else if (name === 'select_project') {
        state.selected = param
      } else if (name === 'update_from_dev') {
        isUpdatingDev.value = true
        setTimeout(() => {
          isUpdatingDev.value = false
        }, 1200)
      }
    }
    return false
  }

  function applyPayload(payload) {
    if (!payload) return
    if (payload.version) state.version = payload.version
    state.status = payload.status || 'off'
    state.paused = Boolean(payload.paused)
    state.idle_minutes = payload.idle_minutes ?? 5
    state.current = payload.current || null
    state.folder = payload.folder || ''
    state.session_seconds = payload.session_seconds ?? 0
    state.today = payload.today || new Date().toISOString().slice(0, 10)
    state.tick_interval = payload.tick_interval || 30
    state.projects = payload.projects || []
    state.selected = payload.selected || payload.current || null

    if (payload.stats) {
      state.stats.total_seconds = payload.stats.total_seconds || 0
      state.stats.today_seconds = payload.stats.today_seconds || 0
      state.stats.first_seen = payload.stats.first_seen || null
      state.stats.last_seen = payload.stats.last_seen || null
      state.stats.days = payload.stats.days || []
      state.stats.hours = payload.stats.hours || Array(24).fill(0)
      state.stats.weekdays = payload.stats.weekdays || Array(7).fill(0)
    }
  }

  function togglePause() {
    callRuby('toggle_pause')
  }

  function refresh() {
    isRefreshing.value = true
    callRuby('get_stats')
    setTimeout(() => {
      isRefreshing.value = false
    }, 600)
  }

  function openFolder() {
    callRuby('open_folder')
  }

  function updateFromDev() {
    isUpdatingDev.value = true
    callRuby('update_from_dev')
    setTimeout(() => {
      isUpdatingDev.value = false
    }, 3000)
  }

  function setIdleMinutes(val) {
    const num = parseFloat(val)
    if (!isNaN(num) && num > 0) {
      state.idle_minutes = num
      callRuby('set_idle_minutes', num)
    }
  }

  function selectProject(proj) {
    state.selected = proj
    callRuby('select_project', proj)
  }

  function copyFolder() {
    if (!state.folder) return
    try {
      navigator.clipboard.writeText(state.folder)
      isCopied.value = true
      setTimeout(() => {
        isCopied.value = false
      }, 2000)
    } catch {
      // fallback
    }
  }

  onMounted(() => {
    activeUpdateCallback = (payload) => {
      applyPayload(payload)
    }

    if (window._pendingPayload) {
      applyPayload(window._pendingPayload)
      window._pendingPayload = null
    }

    // Call ready
    callRuby('ready')

    // Retry ready shortly in case CEF takes a moment to bind callbacks
    setTimeout(() => {
      if (!hasReceivedRealData) {
        callRuby('ready')
        callRuby('get_stats')
      }
    }, 150)

    // In local browser mode outside SketchUp, load mock data after 400ms if no real data
    setTimeout(() => {
      if (!hasReceivedRealData && !getSketchup()) {
        applyPayload(mockData)
      }
    }, 400)

    // Periodic poll every 5 sec
    pollTimer = setInterval(() => {
      callRuby('get_stats')
    }, 5000)

    // Local tick for live session timer when active
    sessionTimer = setInterval(() => {
      if (state.status === 'active' && !state.paused) {
        state.session_seconds += 1
        if (state.stats) {
          state.stats.today_seconds += 1
          state.stats.total_seconds += 1
        }
      }
    }, 1000)
  })

  onUnmounted(() => {
    activeUpdateCallback = null
    if (pollTimer) clearInterval(pollTimer)
    if (sessionTimer) clearInterval(sessionTimer)
  })

  return {
    state,
    isUpdatingDev,
    isRefreshing,
    isCopied,
    togglePause,
    refresh,
    openFolder,
    updateFromDev,
    setIdleMinutes,
    selectProject,
    copyFolder,
  }
}
