<template>
  <div class="space-y-2.5">
    <!-- Quick Insights Bar -->
    <div v-if="days && days.length > 0" class="grid grid-cols-3 gap-1.5 p-2 bg-slate-100/70 dark:bg-slate-800/50 rounded-xl text-center text-xs">
      <div>
        <div class="text-[10px] text-slate-400 font-medium">{{ t('days.activeDays') }}</div>
        <div class="font-bold text-slate-700 dark:text-slate-200 mt-0.5">{{ days.length }}</div>
      </div>
      <div>
        <div class="text-[10px] text-slate-400 font-medium">{{ t('days.avgPerDay') }}</div>
        <div class="font-bold text-slate-700 dark:text-slate-200 mt-0.5">{{ formatDuration(averagePerDay, true) }}</div>
      </div>
      <div>
        <div class="text-[10px] text-slate-400 font-medium">{{ t('days.record') }}</div>
        <div class="font-bold text-brand-600 dark:text-brand-400 mt-0.5">{{ formatDuration(maxSeconds, true) }}</div>
      </div>
    </div>

    <!-- Filter chips -->
    <div v-if="days && days.length > 7" class="flex items-center justify-between gap-1 text-[11px] px-1">
      <span class="text-slate-400 font-medium">{{ t('days.show') }}</span>
      <div class="flex items-center gap-1">
        <button
          v-for="f in [ { id: 'all', label: t('days.filterAll') }, { id: '30', label: t('days.filter30') }, { id: '7', label: t('days.filter7') } ]"
          :key="f.id"
          type="button"
          @click="filter = f.id"
          class="px-2 py-0.5 rounded-md font-medium transition-colors cursor-pointer"
          :class="filter === f.id
            ? 'bg-slate-200 dark:bg-slate-700 text-slate-800 dark:text-slate-200'
            : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'"
        >
          {{ f.label }}
        </button>
      </div>
    </div>

    <!-- Days Table / List Container -->
    <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200/90 dark:border-slate-800/90 overflow-hidden shadow-2xs">
      <div v-if="!filteredDays.length" class="py-8 px-4 text-center text-slate-400 dark:text-slate-500 text-xs">
        <CalendarX :size="24" class="mx-auto mb-2 opacity-50" />
        <p>{{ t('days.empty') }}</p>
        <p class="text-[11px] mt-1 text-slate-400">{{ t('days.emptyHint') }}</p>
      </div>

      <div v-else class="max-h-[310px] overflow-y-auto divide-y divide-slate-100 dark:divide-slate-800/60">
        <div
          v-for="row in filteredDays"
          :key="row.date"
          class="p-2.5 px-3 flex items-center gap-3 transition-colors group"
          :class="row.date === today ? 'bg-brand-50/50 dark:bg-brand-950/20' : 'hover:bg-slate-50/80 dark:hover:bg-slate-800/40'"
        >
          <!-- Date & Weekday -->
          <div class="w-24 shrink-0">
            <div class="flex items-center gap-1">
              <span
                v-if="row.date === today"
                class="inline-block w-1.5 h-1.5 rounded-full bg-brand-500 shrink-0"
              ></span>
              <span
                class="text-xs font-semibold"
                :class="row.date === today ? 'text-brand-600 dark:text-brand-400 font-bold' : 'text-slate-700 dark:text-slate-200'"
              >
              {{ formatDate(row.date, today) }}
            </span>
          </div>
          <div class="text-[10px] text-slate-400 dark:text-slate-500 font-medium">
            {{ weekdayName(row.date) }}
          </div>
          </div>

          <!-- Progress bar -->
          <div class="flex-1 min-w-0">
            <div class="w-full bg-slate-100 dark:bg-slate-800 rounded-full h-2 overflow-hidden">
              <div
                class="h-full rounded-full transition-all duration-300"
                :class="row.date === today
                  ? 'bg-gradient-to-r from-emerald-500 to-teal-400'
                  : 'bg-gradient-to-r from-brand-500 to-sky-400'"
                :style="{ width: Math.min(100, Math.max(3, Math.round((row.seconds / maxSeconds) * 100))) + '%' }"
                :title="`${Math.round((row.seconds / maxSeconds) * 100)}${t('days.recordPct')}`"
              ></div>
            </div>
          </div>

          <!-- Duration -->
          <div class="text-right shrink-0 min-w-[70px]">
            <span
              class="text-xs font-bold"
              :class="row.date === today ? 'text-brand-600 dark:text-brand-400' : 'text-slate-800 dark:text-slate-100'"
            >
              {{ formatDuration(row.seconds) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { CalendarX } from 'lucide-vue-next'
import { formatDuration, formatDate, weekdayIndexFrom } from '../utils/formatters'
import { t, dict } from '../i18n'

const props = defineProps({
  days: { type: Array, default: () => [] },
  today: { type: String, default: '' }
})

const filter = ref('all')

// Имя дня недели локализуется на фронте — из даты (Ruby шлёт его по-русски)
function weekdayName(dateStr) {
  const idx = weekdayIndexFrom(dateStr)
  return idx >= 0 ? dict.value['wd.full'][idx] : ''
}

const filteredDays = computed(() => {
  if (!props.days) return []
  if (filter.value === '7') return props.days.slice(0, 7)
  if (filter.value === '30') return props.days.slice(0, 30)
  return props.days.slice(0, 60)
})

const maxSeconds = computed(() => {
  if (!props.days || props.days.length === 0) return 1
  let max = 1
  props.days.forEach(d => {
    if (d.seconds > max) max = d.seconds
  })
  return max
})

const averagePerDay = computed(() => {
  if (!props.days || props.days.length === 0) return 0
  const sum = props.days.reduce((acc, d) => acc + (d.seconds || 0), 0)
  return sum / props.days.length
})
</script>
