<template>
  <div class="grid grid-cols-3 gap-2">
    <!-- Сегодня -->
    <div class="bg-white dark:bg-slate-900 rounded-xl p-2.5 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs relative overflow-hidden group hover:border-brand-300 dark:hover:border-brand-700 transition-all">
      <div class="flex items-center justify-between mb-1">
        <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
          Сегодня
        </span>
        <div class="w-5 h-5 rounded-md bg-brand-50 dark:bg-brand-950/60 text-brand-500 flex items-center justify-center">
          <CalendarDays :size="12" />
        </div>
      </div>
      <div class="font-extrabold text-sm sm:text-base text-brand-600 dark:text-brand-400 tracking-tight leading-tight">
        {{ formatDuration(todaySeconds) }}
      </div>
      <div v-if="todayDecimal" class="text-[10px] font-medium text-slate-400 dark:text-slate-500 mt-0.5">
        {{ todayDecimal }}
      </div>
    </div>

    <!-- Сессия -->
    <div class="bg-white dark:bg-slate-900 rounded-xl p-2.5 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs relative overflow-hidden group hover:border-emerald-300 dark:hover:border-emerald-700 transition-all">
      <div class="flex items-center justify-between mb-1">
        <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
          Сессия
        </span>
        <div class="w-5 h-5 rounded-md bg-emerald-50 dark:bg-emerald-950/60 text-emerald-500 flex items-center justify-center">
          <Timer :size="12" />
        </div>
      </div>
      <div class="font-extrabold text-sm sm:text-base text-emerald-600 dark:text-emerald-400 tracking-tight leading-tight">
        {{ formatDuration(sessionSeconds) }}
      </div>
      <div class="text-[10px] font-medium text-slate-400 dark:text-slate-500 mt-0.5 flex items-center gap-1">
        <span class="w-1.5 h-1.5 rounded-full" :class="isActive ? 'bg-emerald-500 animate-pulse' : 'bg-slate-300 dark:bg-slate-600'"></span>
        <span>{{ isActive ? 'идет счет' : 'пауза/afk' }}</span>
      </div>
    </div>

    <!-- Всего -->
    <div class="bg-white dark:bg-slate-900 rounded-xl p-2.5 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs relative overflow-hidden group hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
      <div class="flex items-center justify-between mb-1">
        <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
          Всего
        </span>
        <div class="w-5 h-5 rounded-md bg-indigo-50 dark:bg-indigo-950/60 text-indigo-500 flex items-center justify-center">
          <History :size="12" />
        </div>
      </div>
      <div class="font-extrabold text-sm sm:text-base text-slate-800 dark:text-slate-100 tracking-tight leading-tight">
        {{ formatDuration(totalSeconds) }}
      </div>
      <div v-if="totalDecimal" class="text-[10px] font-medium text-slate-400 dark:text-slate-500 mt-0.5">
        {{ totalDecimal }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { CalendarDays, Timer, History } from 'lucide-vue-next'
import { formatDuration, formatHoursDecimal } from '../utils/formatters'

const props = defineProps({
  todaySeconds: { type: Number, default: 0 },
  sessionSeconds: { type: Number, default: 0 },
  totalSeconds: { type: Number, default: 0 },
  isActive: { type: Boolean, default: false }
})

const todayDecimal = computed(() => formatHoursDecimal(props.todaySeconds))
const totalDecimal = computed(() => formatHoursDecimal(props.totalSeconds))
</script>
