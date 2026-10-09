// English strings of the statistics window. Flat keys: t('status.active').
// Arrays (weekday names, months) are read from dict directly.
export default {
  // Header: status and theme
  'status.paused': 'Paused',
  'status.active': 'Working',
  'status.idle': 'Idle',
  'status.off': 'Stopped',
  'theme.toLight': 'Switch to light theme',
  'theme.toDark': 'Switch to dark theme',

  // ModelCard
  'model.title': 'SketchUp Model',
  'model.period': 'Project work period',
  'model.unnamed': 'Unnamed model',
  'model.pickProject': 'Select a project from this folder',
  'model.noFileYet': 'File not saved to disk yet',
  'model.inMemory': 'In memory (not saved)',
  'model.copied': 'Copied to clipboard!',
  'model.copyPath': 'Copy folder path',
  'model.openInExplorer': 'Open folder in Windows Explorer',
  // string comes from Ruby (Tracker::UNSAVED) — substituted via the dictionary
  'model.rubyUnsaved': 'Unnamed (not saved)',

  // MetricsCards
  'metrics.today': 'Today',
  'metrics.session': 'Session',
  'metrics.total': 'Total',
  'metrics.counting': 'counting',
  'metrics.pausedAfk': 'paused/afk',

  // ControlBar
  'controls.pause': 'Pause',
  'controls.resume': 'Resume',
  'controls.pauseTip': 'Pause time tracking',
  'controls.resumeTip': 'Resume automatic time tracking',
  'controls.refresh': 'Refresh',
  'controls.refreshTip': 'Fetch fresh statistics from the model file',
  'controls.folder': 'Folder',
  'controls.folderTip': 'Open model folder in Windows Explorer',
  'controls.fromDev': 'From Dev',
  'controls.building': 'Building...',
  'controls.devTip': 'Update the extension from the dev folder and hot-reload',
  'controls.afkLabel': 'AFK threshold:',
  'controls.afkTip': 'If there is no mouse or keyboard input for longer than this, time is not counted',
  'controls.minShort': 'm',

  // TabsNav
  'tabs.days': 'By days',
  'tabs.hours': 'By hours',
  'tabs.weekdays': 'By weekday',

  // TabDays
  'days.activeDays': 'Active days',
  'days.avgPerDay': 'Avg / day',
  'days.record': 'Day record',
  'days.show': 'Show:',
  'days.filterAll': 'All',
  'days.filter30': '30 d',
  'days.filter7': '7 d',
  'days.empty': 'No records for this project.',
  'days.emptyHint': 'Time will be tracked while you work on the model.',
  'days.recordPct': '% of record',

  // TabHours
  'hours.peak': 'Peak productivity:',
  'hours.distTitle': 'HOURLY DISTRIBUTION (0–23 h)',
  'hours.h': 'h',
  'hours.night': 'Night',
  'hours.morning': 'Morning',
  'hours.day': 'Day',
  'hours.evening': 'Evening',

  // TabWeekdays
  'wd.load': 'Main load:',
  'wd.title': 'BY WEEKDAY (TOTAL)',
  'wd.weekdays': 'Weekdays (Mon–Fri)',
  'wd.weekend': 'Weekend (Sat–Sun)',
  'wd.short': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  'wd.full': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],

  // App: footer
  'footer.sync': 'Sync every {n} s',

  // formatters.js: units, months, date patterns
  fmt: {
    zero: '0 s',
    hLong: 'h',
    minLong: 'min',
    sLong: 's',
    hShort: 'h',
    minShort: 'm',
    sShort: 's',
    hoursDecimal: 'h',
    today: 'Today',
    dateShort: '{month} {day}',
    dateLong: '{month} {day}, {year}',
    months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  },
}
