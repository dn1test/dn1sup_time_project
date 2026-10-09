import { ref, computed } from 'vue'
import ru from './ru'
import en from './en'

const LOCALES = { ru, en }
const STORAGE_KEY = 'dn1sup_time_project.locale'
const LEGACY_STORAGE_KEY = 'dn1sup_time_project2.locale' // до переименования расширения

function storedLocale() {
  try {
    let saved = window.localStorage.getItem(STORAGE_KEY)
    if (!saved || !LOCALES[saved]) {
      saved = window.localStorage.getItem(LEGACY_STORAGE_KEY)
    }
    return saved && LOCALES[saved] ? saved : null
  } catch {
    return null
  }
}

// Реактивная локаль: t() читает dict, поэтому шаблоны перерисовываются при смене языка.
export const locale = ref(storedLocale() || 'ru')

export const dict = computed(() => LOCALES[locale.value] || ru)

export function setLocale(next) {
  if (!LOCALES[next]) return
  locale.value = next
  try {
    window.localStorage.setItem(STORAGE_KEY, next)
  } catch {
    // нет localStorage — выбор языка живёт до перезагрузки окна
  }
}

export function t(key, params) {
  let text = dict.value[key]
  if (text === undefined) text = ru[key] !== undefined ? ru[key] : key
  if (params) {
    for (const [name, value] of Object.entries(params)) {
      text = String(text).replaceAll(`{${name}}`, value)
    }
  }
  return text
}
