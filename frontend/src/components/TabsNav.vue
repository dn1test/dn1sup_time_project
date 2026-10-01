<template>
  <div class="flex items-center p-1 bg-slate-200/70 dark:bg-slate-800/80 rounded-xl">
    <button
      v-for="tab in tabs"
      :key="tab.id"
      type="button"
      @click="$emit('update:modelValue', tab.id)"
      class="flex-1 flex items-center justify-center gap-1.5 py-1.5 px-2 rounded-lg text-xs font-semibold transition-all duration-150 cursor-pointer"
      :class="modelValue === tab.id
        ? 'bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 shadow-xs'
        : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200'"
    >
      <component :is="tab.icon" :size="13" />
      <span>{{ tab.label }}</span>
    </button>
  </div>
</template>

<script setup>
import { Calendar, BarChart3, CalendarRange } from 'lucide-vue-next'

defineProps({
  modelValue: { type: String, default: 'days' }
})

defineEmits(['update:modelValue'])

const tabs = [
  { id: 'days', label: 'По дням', icon: Calendar },
  { id: 'hours', label: 'По часам', icon: BarChart3 },
  { id: 'weekdays', label: 'По дням недели', icon: CalendarRange }
]
</script>
