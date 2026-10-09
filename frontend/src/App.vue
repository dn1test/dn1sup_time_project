<template>
  <div class="h-full flex flex-col bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-100 transition-colors">
    <!-- Top Fixed Header -->
    <Header
      :version="state.version"
      :status="state.status"
      :paused="state.paused"
    />

    <!-- Main Scrollable Content Area -->
    <main class="flex-1 overflow-y-auto p-3 space-y-3">
      <!-- Active Model & Folder Card -->
      <ModelCard
        :current="state.current"
        :selected-project="state.selected"
        :folder="state.folder"
        :projects="state.projects"
        :first-seen="state.stats?.first_seen"
        :last-seen="state.stats?.last_seen"
        :is-copied="isCopied"
        @select-project="selectProject"
        @open-folder="openFolder"
        @copy-folder="copyFolder"
      />

      <!-- KPI Metrics Row -->
      <MetricsCards
        :today-seconds="state.stats?.today_seconds || 0"
        :session-seconds="state.session_seconds || 0"
        :total-seconds="state.stats?.total_seconds || 0"
        :is-active="state.status === 'active' && !state.paused"
      />

      <!-- Action & Control Bar -->
      <ControlBar
        :paused="state.paused"
        :idle-minutes="state.idle_minutes"
        :is-refreshing="isRefreshing"
        :is-updating-dev="isUpdatingDev"
        @toggle-pause="togglePause"
        @refresh="refresh"
        @open-folder="openFolder"
        @update-from-dev="updateFromDev"
        @set-idle-minutes="setIdleMinutes"
      />

      <!-- Analytics Tabs Section -->
      <section class="space-y-2 pt-1">
        <TabsNav v-model="activeTab" />

        <div class="pt-0.5">
          <!-- Tab 1: По дням -->
          <TabDays
            v-if="activeTab === 'days'"
            :days="state.stats?.days || []"
            :today="state.today"
          />

          <!-- Tab 2: По часам -->
          <TabHours
            v-else-if="activeTab === 'hours'"
            :hours="state.stats?.hours || []"
          />

          <!-- Tab 3: По дням недели -->
          <TabWeekdays
            v-else-if="activeTab === 'weekdays'"
            :weekdays="state.stats?.weekdays || []"
          />
        </div>
      </section>
    </main>

    <!-- Bottom Status Strip -->
    <footer class="px-3.5 py-1.5 bg-white/70 dark:bg-slate-900/70 border-t border-slate-200/70 dark:border-slate-800/70 flex items-center text-[10px] text-slate-400 dark:text-slate-500 shrink-0">
      <div class="flex items-center gap-1">
        <span class="w-1.5 h-1.5 rounded-full bg-slate-300 dark:bg-slate-600"></span>
        <span>{{ t('footer.sync', { n: state.tick_interval }) }}</span>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useSketchupBridge } from './composables/useSketchupBridge'
import { t } from './i18n'
import Header from './components/Header.vue'
import ModelCard from './components/ModelCard.vue'
import MetricsCards from './components/MetricsCards.vue'
import ControlBar from './components/ControlBar.vue'
import TabsNav from './components/TabsNav.vue'
import TabDays from './components/TabDays.vue'
import TabHours from './components/TabHours.vue'
import TabWeekdays from './components/TabWeekdays.vue'

const activeTab = ref('days')

const {
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
} = useSketchupBridge()
</script>
