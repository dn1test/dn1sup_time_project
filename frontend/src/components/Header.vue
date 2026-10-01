<template>
  <header class="flex items-center justify-between px-3.5 py-2.5 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200/80 dark:border-slate-800/80 sticky top-0 z-20 transition-colors">
    <!-- Brand / Title -->
    <div class="flex items-center gap-2.5 min-w-0">
      <div class="w-7 h-7 rounded-lg bg-gradient-to-tr from-brand-600 to-sky-400 flex items-center justify-center text-white shadow-sm shadow-brand-500/20 shrink-0">
        <Clock :size="15" class="stroke-[2.5]" />
      </div>
      <div class="flex items-center gap-1.5 min-w-0">
        <h1 class="text-sm font-bold tracking-tight text-slate-800 dark:text-slate-100 truncate">
          DN1C Time
        </h1>
        <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 border border-slate-200 dark:border-slate-700/60 shrink-0">
          {{ versionTag }}
        </span>
      </div>
    </div>

    <!-- Right Controls: Status & Theme -->
    <div class="flex items-center gap-2 shrink-0">
      <!-- Status Badge -->
      <div
        class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border transition-all duration-200 shadow-2xs"
        :class="statusConfig.badgeClass"
      >
        <span class="relative flex h-2 w-2">
          <span
            v-if="statusConfig.pulse"
            class="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75"
            :class="statusConfig.dotClass"
          ></span>
          <span class="relative inline-flex rounded-full h-2 w-2" :class="statusConfig.dotClass"></span>
        </span>
        <span class="tracking-wide text-[11px]">{{ statusConfig.label }}</span>
      </div>

      <!-- Theme Switcher -->
      <button
        @click="toggleTheme"
        class="p-1.5 rounded-lg text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
        :title="isDark ? 'Переключить на светлую тему' : 'Переключить на тёмную тему'"
      >
        <Sun v-if="isDark" :size="15" />
        <Moon v-else :size="15" />
      </button>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue'
import { Clock, Sun, Moon } from 'lucide-vue-next'
import { useTheme } from '../composables/useTheme'

const props = defineProps({
  version: {
    type: String,
    default: '2.2.6'
  },
  status: {
    type: String,
    default: 'off'
  },
  paused: {
    type: Boolean,
    default: false
  }
})

const { isDark, toggleTheme } = useTheme()

const versionTag = computed(() => {
  if (!props.version) return 'v2.2.6'
  return props.version.startsWith('v') ? props.version : `v${props.version}`
})

const statusConfig = computed(() => {
  if (props.paused || props.status === 'paused') {
    return {
      label: 'Пауза',
      badgeClass: 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200/80 dark:border-amber-800/60',
      dotClass: 'bg-amber-500',
      pulse: false
    }
  }

  switch (props.status) {
    case 'active':
      return {
        label: 'В работе',
        badgeClass: 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200/80 dark:border-emerald-800/60',
        dotClass: 'bg-emerald-500',
        pulse: true
      }
    case 'idle':
      return {
        label: 'Бездействие',
        badgeClass: 'bg-slate-100 dark:bg-slate-800/80 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700',
        dotClass: 'bg-slate-400',
        pulse: false
      }
    default:
      return {
        label: 'Остановлен',
        badgeClass: 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 border-slate-200 dark:border-slate-700',
        dotClass: 'bg-slate-400',
        pulse: false
      }
  }
})
</script>
