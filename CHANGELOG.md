# Changelog (Лог изменений)

Лог изменений **DN1Sup Time Project** (`dn1sup_time_project`).
Формат версий соответствует правилам `MAJOR.MINOR.PATCH`.

## [0.6.0] — 2026-10-13

- Удалён функционал dev/prod (второй id `dn1sup_time_project_dev`): удалены
  `DEV_BUILD`, поле `dev_build` в данных трекера и бейдж DEV в шапке.
  Разработка — рабочая копия под тем же id («Обновить из рабочей копии» /
  reload); self-update рабочей копии отключён по пути загрузки
  (`Dn1sup::Updater.dev_source?`); файлы `.sketchup_dev.json` удалены.
- feat(gui): кнопка паузы/продолжения перенесена в шапку карточки модели
  рядом с периодом; кнопки обновления/папки/dev убраны из панели управления.

## [0.5.3] — 2026-10-10

- feat: dev/prod placement split, self-update guard for dev installs; v0.5.3
- docs: PUBLISHING.md - GitHub repo requirements for Extension Store; link in README
