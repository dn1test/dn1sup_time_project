<template>
  <div class="bg-white dark:bg-slate-900 rounded-xl p-2.5 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs space-y-2.5">
    <!-- Action Buttons Row -->
    <div class="flex items-center gap-1.5 flex-wrap">
      <!-- Pause / Resume Toggle -->
      <button
        @click="$emit('toggle-pause')"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold shadow-xs transition-all cursor-pointer"
        :class="paused
          ? 'bg-amber-500 hover:bg-amber-600 active:scale-98 text-white shadow-amber-500/20'
          : 'bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700/80'"
        :title="paused ? t('controls.resumeTip') : t('controls.pauseTip')"
      >
        <Play v-if="paused" :size="13" class="fill-current" />
        <Pause v-else :size="13" />
        <span>{{ paused ? t('controls.resume') : t('controls.pause') }}</span>
      </button>

      <!-- Refresh Button -->
      <button
        @click="$emit('refresh')"
        :disabled="isRefreshing"
        class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-slate-50 hover:bg-slate-100 dark:bg-slate-800/80 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200/80 dark:border-slate-700/80 transition-colors cursor-pointer"
        :title="t('controls.refreshTip')"
      >
        <RotateCw :size="13" :class="{ 'animate-spin': isRefreshing }" />
        <span class="hidden sm:inline">{{ t('controls.refresh') }}</span>
      </button>

      <!-- Open Folder Button -->
      <button
        @click="$emit('open-folder')"
        class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-slate-50 hover:bg-slate-100 dark:bg-slate-800/80 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200/80 dark:border-slate-700/80 transition-colors cursor-pointer"
        :title="t('controls.folderTip')"
      >
        <FolderOpen :size="13" />
        <span>{{ t('controls.folder') }}</span>
      </button>

      <!-- Dev Update Button -->
      <button
        @click="$emit('update-from-dev')"
        :disabled="isUpdatingDev"
        class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-brand-50 hover:bg-brand-100 dark:bg-brand-950/40 dark:hover:bg-brand-900/40 text-brand-700 dark:text-brand-300 border border-brand-200/80 dark:border-brand-800/60 transition-colors ml-auto cursor-pointer"
        :title="t('controls.devTip')"
      >
        <RefreshCw :size="13" :class="{ 'animate-spin': isUpdatingDev }" />
        <span>{{ isUpdatingDev ? t('controls.building') : t('controls.fromDev') }}</span>
      </button>
    </div>

    <!-- AFK Settings Row -->
    <div class="flex items-center justify-between gap-2 pt-2 border-t border-slate-100 dark:border-slate-800/60 text-xs">
      <div
        class="flex items-center gap-1.5 text-slate-500 dark:text-slate-400 font-medium"
        :title="t('controls.afkTip')"
      >
        <Clock :size="12" class="text-slate-400" />
        <span>{{ t('controls.afkLabel') }}</span>
      </div>

      <!-- Presets & Input -->
      <div class="flex items-center gap-1">
        <!-- Quick Preset Pills -->
        <button
          v-for="preset in [3, 5, 10, 15]"
          :key="preset"
          type="button"
          @click="selectPreset(preset)"
          class="px-1.5 py-0.5 rounded text-[10px] font-semibold transition-colors cursor-pointer"
          :class="idleMinutes === preset
            ? 'bg-brand-500 text-white shadow-2xs'
            : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'"
        >
          {{ preset }}{{ t('controls.minShort') }}
        </button>

        <!-- Custom Input -->
        <div class="flex items-center bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-md px-1.5 py-0.5 w-14 ml-1">
          <input
            type="number"
            min="1"
            max="240"
            step="1"
            :value="idleMinutes"
            @change="handleInput"
            class="w-full bg-transparent text-center text-xs font-semibold text-slate-700 dark:text-slate-200 focus:outline-none"
          />
          <span class="text-[10px] text-slate-400 ml-0.5">{{ t('controls.minShort') }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Play, Pause, RotateCw, FolderOpen, RefreshCw, Clock } from 'lucide-vue-next'
import { t } from '../i18n'

const props = defineProps({
  paused: { type: Boolean, default: false },
  idleMinutes: { type: Number, default: 5 },
  isRefreshing: { type: Boolean, default: false },
  isUpdatingDev: { type: Boolean, default: false }
})

const emit = defineEmits([
  'toggle-pause',
  'refresh',
  'open-folder',
  'update-from-dev',
  'set-idle-minutes'
])

function selectPreset(val) {
  emit('set-idle-minutes', val)
}

function handleInput(e) {
  const v = parseFloat(e.target.value)
  if (!isNaN(v) && v > 0) {
    emit('set-idle-minutes', v)
  }
}
</script>
