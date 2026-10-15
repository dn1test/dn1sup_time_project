# Публикация расширения на GitHub

> Полная общая инструкция — мастер `U:\dn1code\sketchup_ext\PUBLISHING.md`
> (единственная полная копия: как Store ищет репозитории, обязательные
> требования, registry.json, версии и changelog, релизы). Ниже — локальный
> чек-лист этого репозитория.

## Чек-лист этого репозитория

| Требование | Статус |
|---|---|
| Имя `dn1sup_*` в аккаунте `dn1test` | ✅ `dn1test/dn1sup_time_project` |
| Не archived | ✅ |
| `registry.json` в корне `main` | ✅ (id `dn1sup_time_project`, version 0.7.1) |
| Стабильные релизы с `.rbz` | ✅ 10 релизов, последний `v0.7.1` — ассет `dn1sup_time_project-0.7.1.rbz` |
| Теги `vMAJOR.MINOR.PATCH` | ✅ теги `v*` у всех релизов |
| Регистратор `<id>.rb` + `ext.id` | ✅ `dn1sup_time_project.rb`, `ext.id = 'dn1sup_time_project'` |

**Каталог менеджера: исправлено.** В `registry.json` менеджера запись
`dn1sup_time_project2` (имя репозитория до переименования на GitHub) заменена
на `{"id": "dn1sup_time_project", "name": "DN1Sup Time Project",
"repo": "dn1test/dn1sup_time_project"}`. Изменение пока не опубликовано —
не забудьте закоммитить и запушить репозиторий менеджера.
