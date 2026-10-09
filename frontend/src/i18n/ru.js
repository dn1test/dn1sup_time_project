// Русские строки окна статистики. Ключи плоские: t('status.active').
// Массивы (имена дней недели, месяцы) достаются напрямую из dict.
export default {
  // Header: статус и тема
  'status.paused': 'Пауза',
  'status.active': 'В работе',
  'status.idle': 'Бездействие',
  'status.off': 'Остановлен',
  'theme.toLight': 'Переключить на светлую тему',
  'theme.toDark': 'Переключить на тёмную тему',

  // ModelCard
  'model.title': 'Модель SketchUp',
  'model.period': 'Период работы над проектом',
  'model.unnamed': 'Безымянная модель',
  'model.pickProject': 'Выбрать проект из этой папки',
  'model.noFileYet': 'Файл ещё не сохранён на диск',
  'model.inMemory': 'В памяти (не сохранён)',
  'model.copied': 'Скопировано в буфер!',
  'model.copyPath': 'Копировать путь к папке',
  'model.openInExplorer': 'Открыть папку в Проводнике Windows',
  // строка приходит из Ruby (Tracker::UNSAVED) — подменяется по словарю
  'model.rubyUnsaved': 'Без имени (не сохранён)',

  // MetricsCards
  'metrics.today': 'Сегодня',
  'metrics.session': 'Сессия',
  'metrics.total': 'Всего',
  'metrics.counting': 'идет счет',
  'metrics.pausedAfk': 'пауза/afk',

  // ControlBar
  'controls.pause': 'Пауза',
  'controls.resume': 'Продолжить',
  'controls.pauseTip': 'Приостановить учёт времени',
  'controls.resumeTip': 'Возобновить автоматический учёт времени',
  'controls.refresh': 'Обновить',
  'controls.refreshTip': 'Запросить свежую статистику из файла',
  'controls.folder': 'Папка',
  'controls.folderTip': 'Открыть папку модели в Проводнике Windows',
  'controls.fromDev': 'Из Dev',
  'controls.building': 'Сборка...',
  'controls.devTip': 'Обновить расширение из dev-папки разработки и перезагрузить на лету',
  'controls.afkLabel': 'Порог AFK:',
  'controls.afkTip': 'Если нет мыши и клавиш дольше указанного времени — время не засчитывается',
  'controls.minShort': 'м',

  // TabsNav
  'tabs.days': 'По дням',
  'tabs.hours': 'По часам',
  'tabs.weekdays': 'По дням недели',

  // TabDays
  'days.activeDays': 'Активных дней',
  'days.avgPerDay': 'В среднем / день',
  'days.record': 'Рекорд за день',
  'days.show': 'Показать:',
  'days.filterAll': 'Все',
  'days.filter30': '30 дн',
  'days.filter7': '7 дн',
  'days.empty': 'Нет записей по этому проекту.',
  'days.emptyHint': 'Время начнёт учитываться при работе над моделью.',
  'days.recordPct': '% от рекорда',

  // TabHours
  'hours.peak': 'Пиковая продуктивность:',
  'hours.distTitle': 'РАСПРЕДЕЛЕНИЕ ПО ЧАСАМ (0–23 ч)',
  'hours.h': 'ч',
  'hours.night': 'Ночь',
  'hours.morning': 'Утро',
  'hours.day': 'День',
  'hours.evening': 'Вечер',

  // TabWeekdays
  'wd.load': 'Основная нагрузка:',
  'wd.title': 'ПО ДНЯМ НЕДЕЛИ (СУММАРНО)',
  'wd.weekdays': 'Будни (Пн–Пт)',
  'wd.weekend': 'Выходные (Сб–Вс)',
  'wd.short': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
  'wd.full': ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'],

  // App: футер
  'footer.sync': 'Синхронизация раз в {n} с',

  // formatters.js: единицы, месяцы, шаблоны дат
  fmt: {
    zero: '0 с',
    hLong: 'ч',
    minLong: 'мин',
    sLong: 'с',
    hShort: 'ч',
    minShort: 'м',
    sShort: 'с',
    hoursDecimal: 'ч',
    today: 'Сегодня',
    dateShort: '{day} {month}',
    dateLong: '{day} {month} {year}',
    months: ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'],
  },
}
