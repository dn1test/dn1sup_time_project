<template>
  <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200/90 dark:border-slate-800/90 shadow-2xs transition-all">
    <!-- Header of Card: label & date range + pause -->
    <div class="flex items-center justify-between gap-2 mb-1.5">
      <div class="flex items-center gap-1.5 text-[11px] font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wider min-w-0">
        <Box :size="13" class="text-brand-500 shrink-0" />
        <span class="truncate">{{ t('model.title') }}</span>
      </div>
      <div class="flex items-center gap-1.5 shrink-0">
        <div
          v-if="dateRange"
          class="inline-flex items-center gap-1 text-[11px] px-2 py-0.5 rounded-md bg-slate-100 dark:bg-slate-800/80 text-slate-600 dark:text-slate-400 font-medium whitespace-nowrap"
          :title="t('model.period')"
        >
          <Calendar :size="11" class="text-slate-400" />
          <span>{{ dateRange }}</span>
        </div>
        <button
          @click="$emit('toggle-pause')"
          class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold shadow-xs transition-all cursor-pointer whitespace-nowrap"
          :class="paused
            ? 'bg-amber-500 hover:bg-amber-600 active:scale-98 text-white shadow-amber-500/20'
            : 'bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700/80'"
          :title="paused ? t('controls.resumeTip') : t('controls.pauseTip')"
        >
          <Play v-if="paused" :size="14" class="fill-current" />
          <Pause v-else :size="14" />
          <span>{{ paused ? t('controls.resume') : t('controls.pause') }}</span>
        </button>
      </div>
    </div>

    <!-- Model Name & Switcher -->
    <div class="flex items-center justify-between gap-2">
      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-2">
          <span
            class="font-bold text-sm text-slate-800 dark:text-slate-100 truncate block select-text"
            :title="modelDisplayName"
          >
            {{ modelDisplayName }}
          </span>
        </div>
      </div>

      <!-- Multiple Projects Selector -->
      <div v-if="projects && projects.length > 1" class="shrink-0 relative">
        <select
          :value="selectedProject"
          @change="$emit('select-project', $event.target.value)"
          class="text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg px-2 py-1 pr-6 text-slate-700 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium cursor-pointer"
          :title="t('model.pickProject')"
        >
          <option v-for="p in projects" :key="p" :value="p">
            {{ p }}
          </option>
        </select>
      </div>
    </div>

    <!-- Folder path row with Copy / Open -->
    <div class="mt-2 pt-2 border-t border-slate-100 dark:border-slate-800/60 flex items-center justify-between gap-2">
      <div
        class="flex items-center gap-1.5 min-w-0 flex-1 text-slate-500 dark:text-slate-400 text-[11px] font-mono truncate"
        :title="folder || t('model.noFileYet')"
      >
        <Folder :size="12" class="shrink-0 text-slate-400" />
        <span class="truncate select-text">{{ folder || t('model.inMemory') }}</span>
      </div>

      <div class="flex items-center gap-1 shrink-0">
        <!-- Copy path button -->
        <button
          v-if="folder"
          @click="$emit('copy-folder')"
          class="p-1 rounded text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          :title="isCopied ? t('model.copied') : t('model.copyPath')"
        >
          <Check v-if="isCopied" :size="12" class="text-emerald-500" />
          <Copy v-else :size="12" />
        </button>

        <!-- Open folder button -->
        <button
          v-if="folder"
          @click="$emit('open-folder')"
          class="p-1 rounded text-slate-400 hover:text-brand-600 dark:hover:text-brand-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          :title="t('model.openInExplorer')"
        >
          <ExternalLink :size="12" />
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { Box, Calendar, Folder, Copy, Check, ExternalLink, Play, Pause } from 'lucide-vue-next'
import { formatDateRange } from '../utils/formatters'
import { t } from '../i18n'

const props = defineProps({
  current: { type: String, default: null },
  selectedProject: { type: String, default: null },
  folder: { type: String, default: '' },
  projects: { type: Array, default: () => [] },
  firstSeen: { type: String, default: null },
  lastSeen: { type: String, default: null },
  isCopied: { type: Boolean, default: false },
  paused: { type: Boolean, default: false }
})

defineEmits(['select-project', 'open-folder', 'copy-folder', 'toggle-pause'])

// Метка, которой Ruby помечает модель без имени (Tracker::UNSAVED)
const RUBY_UNSAVED = 'Без имени (не сохранён)'

const modelDisplayName = computed(() => {
  const name = props.selectedProject || props.current
  if (!name) return t('model.unnamed')
  if (name === RUBY_UNSAVED) return t('model.rubyUnsaved')
  return name
})

const dateRange = computed(() => {
  return formatDateRange(props.firstSeen, props.lastSeen)
})
</script>
