<template>
  <div class="space-y-2.5">
    <!-- Peak Hour & Insights Header -->
    <div class="flex items-center justify-between p-2.5 bg-slate-100/70 dark:bg-slate-800/50 rounded-xl text-xs">
      <div class="flex items-center gap-1.5 text-slate-600 dark:text-slate-300">
        <Sparkles :size="13" class="text-amber-500" />
        <span class="font-medium">{{ t('hours.peak') }}</span>
      </div>
      <div v-if="peakHour !== null && peakValue > 0" class="font-bold text-brand-600 dark:text-brand-400">
        {{ peakHour }}:00 – {{ peakHour + 1 }}:00 ({{ formatDuration(peakValue, true) }})
      </div>
      <div v-else class="text-slate-400">
        —
      </div>
    </div>

    <!-- Chart Container -->
    <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs">
      <div class="text-[11px] font-semibold text-slate-400 dark:text-slate-500 mb-2 flex items-center justify-between">
        <span>{{ t('hours.distTitle') }}</span>
        <span v-if="hoveredHour !== null" class="text-brand-600 dark:text-brand-400 font-bold">
          {{ hoveredHour }}:00: {{ formatDuration(hours[hoveredHour]) }}
        </span>
      </div>

      <!-- Bars Chart Area -->
      <div class="h-28 flex items-end gap-1 pt-3 pb-1 border-b border-slate-100 dark:border-slate-800">
        <div
          v-for="(val, h) in hours"
          :key="h"
          class="flex-1 flex flex-col justify-end items-center h-full group relative cursor-pointer"
          @mouseenter="hoveredHour = h"
          @mouseleave="hoveredHour = null"
        >
          <!-- Hover Tooltip Popup -->
          <div
            v-if="hoveredHour === h"
            class="absolute -top-7 left-1/2 -translate-x-1/2 z-20 px-1.5 py-0.5 rounded bg-slate-800 text-white text-[10px] font-medium whitespace-nowrap shadow-md pointer-events-none"
          >
            {{ h }}:00 — {{ formatDuration(val, true) }}
          </div>

          <!-- Bar -->
          <div
            class="w-full rounded-t-sm transition-all duration-200"
            :class="getBarClass(h, val)"
            :style="{ height: getBarHeight(val) }"
          ></div>
        </div>
      </div>

      <!-- Axis Labels (Every 3 hours to prevent crowding) -->
      <div class="flex justify-between text-[9px] font-mono text-slate-400 dark:text-slate-500 mt-1.5 px-0.5">
        <span v-for="h in [0, 3, 6, 9, 12, 15, 18, 21, 23]" :key="h">
          {{ h }}{{ t('hours.h') }}
        </span>
      </div>
    </div>

    <!-- Time of Day Segments -->
    <div class="grid grid-cols-4 gap-1.5 text-center text-xs">
      <div
        v-for="seg in daySegments"
        :key="seg.name"
        class="bg-white dark:bg-slate-900 p-2 rounded-xl border border-slate-200/90 dark:border-slate-800/90 shadow-2xs"
      >
        <div class="text-[10px] text-slate-400 font-medium">{{ seg.name }}</div>
        <div class="text-[9px] text-slate-400 mb-1">{{ seg.hours }}</div>
        <div class="font-bold text-slate-700 dark:text-slate-200 text-xs">
          {{ formatDuration(seg.total, true) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Sparkles } from 'lucide-vue-next'
import { formatDuration } from '../utils/formatters'
import { t } from '../i18n'

const props = defineProps({
  hours: {
    type: Array,
    default: () => Array(24).fill(0)
  }
})

const hoveredHour = ref(null)
const curHour = new Date().getHours()

const maxHourValue = computed(() => {
  return Math.max(1, ...props.hours)
})

const peakHour = computed(() => {
  let max = 0
  let p = null
  props.hours.forEach((v, i) => {
    if (v > max) {
      max = v
      p = i
    }
  })
  return p
})

const peakValue = computed(() => {
  return peakHour.value !== null ? props.hours[peakHour.value] : 0
})

function getBarHeight(val) {
  if (!val || val <= 0) return '3px'
  const pct = Math.max(4, Math.round((val / maxHourValue.value) * 100))
  return `${pct}%`
}

function getBarClass(h, val) {
  const isCurrent = h === curHour
  const isPeak = h === peakHour.value && val > 0

  if (!val || val <= 0) {
    return 'bg-slate-200/60 dark:bg-slate-800'
  }

  if (isCurrent) {
    return 'bg-emerald-500 hover:bg-emerald-400'
  }

  if (isPeak) {
    return 'bg-brand-600 dark:bg-brand-500 hover:brightness-110'
  }

  return 'bg-sky-400 dark:bg-sky-600 hover:bg-sky-500'
}

const daySegments = computed(() => {
  const unit = t('hours.h')
  const segs = [
    { name: t('hours.night'), hours: `0–6${unit}`, total: 0 },
    { name: t('hours.morning'), hours: `6–12${unit}`, total: 0 },
    { name: t('hours.day'), hours: `12–18${unit}`, total: 0 },
    { name: t('hours.evening'), hours: `18–24${unit}`, total: 0 },
  ]
  props.hours.forEach((val, hour) => {
    if (hour < 6) segs[0].total += val
    else if (hour < 12) segs[1].total += val
    else if (hour < 18) segs[2].total += val
    else segs[3].total += val
  })
  return segs
})
</script>
