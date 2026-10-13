<template>
  <div class="bg-white dark:bg-slate-900 rounded-xl p-2.5 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs">
    <!-- AFK Settings Row -->
    <div class="flex items-center justify-between gap-2 text-xs">
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
import { Clock } from 'lucide-vue-next'
import { t } from '../i18n'

const props = defineProps({
  idleMinutes: { type: Number, default: 5 }
})

const emit = defineEmits([
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
