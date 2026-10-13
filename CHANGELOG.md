# Changelog (Лог изменений)

Лог изменений **DN1Sup Time Project** (`dn1sup_time_project`).
Формат версий соответствует правилам `MAJOR.MINOR.PATCH`.

## [0.6.0] — 2026-10-13

- Удалён функционал dev/prod (второй id `dn1sup_time_project_dev`): удалены
  `DEV_BUILD`, поле `dev_build` в данных трекера и бейдж DEV в шапке.
  Разработка — рабочая копия под тем же id («Обновить из рабочей копии» /
  reload); self-update рабочей копии отключён по пути загрузки
  (`Dn1sup::Updater.dev_source?`); файлы `.sketchup_dev.json` удалены.

## [0.5.4] — unreleased

- feat: DEV badge in dialog header when running the dev build (dev_build flag)
- feat(gui): pause/resume button moved to model card header next to period; refresh/folder/dev buttons removed from control bar, AFK threshold bar only

## [0.5.3] — 2026-10-10

- feat: dev/prod placement split, self-update guard for dev installs; v0.5.3
- docs: PUBLISHING.md - GitHub repo requirements for Extension Store; link in README
