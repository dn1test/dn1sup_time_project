<template>
  <div class="space-y-2.5">
    <!-- Peak Day & Insights Header -->
    <div class="flex items-center justify-between p-2.5 bg-slate-100/70 dark:bg-slate-800/50 rounded-xl text-xs">
      <div class="flex items-center gap-1.5 text-slate-600 dark:text-slate-300">
        <Flame :size="13" class="text-orange-500" />
        <span class="font-medium">Основная нагрузка:</span>
      </div>
      <div v-if="peakDayIndex !== null && peakValue > 0" class="font-bold text-brand-600 dark:text-brand-400">
        {{ FULL_DAYS[peakDayIndex] }} ({{ formatDuration(peakValue, true) }})
      </div>
      <div v-else class="text-slate-400">
        —
      </div>
    </div>

    <!-- Chart Container -->
    <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs">
      <div class="text-[11px] font-semibold text-slate-400 dark:text-slate-500 mb-2 flex items-center justify-between">
        <span>ПО ДНЯМ НЕДЕЛИ (СУММАРНО)</span>
        <span v-if="hoveredDay !== null" class="text-brand-600 dark:text-brand-400 font-bold">
          {{ FULL_DAYS[hoveredDay] }}: {{ formatDuration(weekdays[hoveredDay]) }}
        </span>
      </div>

      <!-- Bars Chart Area -->
      <div class="h-28 flex items-end gap-2.5 pt-3 pb-1 border-b border-slate-100 dark:border-slate-800 px-2">
        <div
          v-for="(val, idx) in weekdays"
          :key="idx"
          class="flex-1 flex flex-col justify-end items-center h-full group relative cursor-pointer"
          @mouseenter="hoveredDay = idx"
          @mouseleave="hoveredDay = null"
        >
          <!-- Hover Tooltip Popup -->
          <div
            v-if="hoveredDay === idx"
            class="absolute -top-7 left-1/2 -translate-x-1/2 z-20 px-1.5 py-0.5 rounded bg-slate-800 text-white text-[10px] font-medium whitespace-nowrap shadow-md pointer-events-none"
          >
            {{ FULL_DAYS[idx] }}: {{ formatDuration(val, true) }}
          </div>

          <!-- Bar -->
          <div
            class="w-full max-w-[28px] rounded-t-sm transition-all duration-200"
            :class="getBarClass(idx, val)"
            :style="{ height: getBarHeight(val) }"
          ></div>
        </div>
      </div>

      <!-- Axis Labels (Пн..Вс) -->
      <div class="flex justify-between text-[11px] font-semibold text-slate-500 dark:text-slate-400 mt-2 px-3">
        <span
          v-for="(name, idx) in SHORT_DAYS"
          :key="idx"
          :class="{
            'text-brand-600 dark:text-brand-400 font-bold': idx === todayDayIndex,
            'text-amber-600 dark:text-amber-500': idx >= 5
          }"
        >
          {{ name }}
        </span>
      </div>
    </div>

    <!-- Weekday vs Weekend Split Cards -->
    <div class="grid grid-cols-2 gap-2 text-xs">
      <div class="bg-white dark:bg-slate-900 p-2.5 rounded-xl border border-slate-200/90 dark:border-slate-800/90 shadow-2xs">
        <div class="flex items-center justify-between text-slate-400 text-[11px] mb-1">
          <span>Будни (Пн–Пт)</span>
          <span class="font-bold text-slate-700 dark:text-slate-200">{{ weekdayPct }}%</span>
        </div>
        <div class="font-extrabold text-slate-800 dark:text-slate-100 text-sm">
          {{ formatDuration(weekdayTotal) }}
        </div>
      </div>

      <div class="bg-white dark:bg-slate-900 p-2.5 rounded-xl border border-slate-200/90 dark:border-slate-800/90 shadow-2xs">
        <div class="flex items-center justify-between text-slate-400 text-[11px] mb-1">
          <span>Выходные (Сб–Вс)</span>
          <span class="font-bold text-slate-700 dark:text-slate-200">{{ weekendPct }}%</span>
        </div>
        <div class="font-extrabold text-slate-800 dark:text-slate-100 text-sm">
          {{ formatDuration(weekendTotal) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Flame } from 'lucide-vue-next'
import { formatDuration } from '../utils/formatters'

const props = defineProps({
  weekdays: {
    type: Array,
    default: () => Array(7).fill(0)
  }
})

const SHORT_DAYS = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
const FULL_DAYS = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье']

const hoveredDay = ref(null)

// Current day index 0..6 (0 is Monday)
const todayDayIndex = (new Date().getDay() + 6) % 7

const maxDayValue = computed(() => {
  return Math.max(1, ...props.weekdays)
})

const peakDayIndex = computed(() => {
  let max = 0
  let p = null
  props.weekdays.forEach((v, i) => {
    if (v > max) {
      max = v
      p = i
    }
  })
  return p
})

const peakValue = computed(() => {
  return peakDayIndex.value !== null ? props.weekdays[peakDayIndex.value] : 0
})

function getBarHeight(val) {
  if (!val || val <= 0) return '3px'
  const pct = Math.max(4, Math.round((val / maxDayValue.value) * 100))
  return `${pct}%`
}

function getBarClass(idx, val) {
  const isToday = idx === todayDayIndex
  const isPeak = idx === peakDayIndex.value && val > 0

  if (!val || val <= 0) {
    return 'bg-slate-200/60 dark:bg-slate-800'
  }

  if (isToday) {
    return 'bg-emerald-500 hover:bg-emerald-400'
  }

  if (isPeak) {
    return 'bg-brand-600 dark:bg-brand-500 hover:brightness-110'
  }

  return 'bg-indigo-400 dark:bg-indigo-600 hover:bg-indigo-500'
}

const weekdayTotal = computed(() => {
  return props.weekdays.slice(0, 5).reduce((acc, v) => acc + v, 0)
})

const weekendTotal = computed(() => {
  return props.weekdays.slice(5, 7).reduce((acc, v) => acc + v, 0)
})

const totalWeek = computed(() => weekdayTotal.value + weekendTotal.value)

const weekdayPct = computed(() => {
  if (totalWeek.value <= 0) return 0
  return Math.round((weekdayTotal.value / totalWeek.value) * 100)
})

const weekendPct = computed(() => {
  if (totalWeek.value <= 0) return 0
  return 100 - weekdayPct.value
})
</script>
