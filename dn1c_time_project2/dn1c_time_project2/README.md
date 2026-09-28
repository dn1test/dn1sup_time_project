# DN1C Time Project 2

Расширение SketchUp: учёт **активного** времени работы над проектом (.skp) со
статистикой **по дням, часам и дням недели**. Продолжение `dn1c_su_time_project`.

## Как считает

- Тик таймера каждые 30 с. Засчитываются только интервалы, когда:
  - окно SketchUp в фокусе (`GetForegroundWindow`, fiddle/WinAPI);
  - с последнего ввода (мышь/клавиатура) прошло не больше порога бездействия
    (по умолчанию 5 мин, настраивается в окне статистики; `GetLastInputInfo`).
- Свёрнутое окно и AFK не считаются; разрыв больше 2 мин (сон/зависание) не
  начисляется.
- Учёт продолжается между сессиями: при каждом тике запоминается, над каким
  файлом идёт работа; статистика накапливается в `stats.yaml` рядом с .skp.
- Несохранённая модель: время копится в памяти и переносится в статистику
  при первом «Сохранить как».
- Пауза: меню или кнопка ⏸ в окне статистики.

## stats.yaml

Один файл на папку, секция на каждый проект:

```yaml
projects:
  "Проект.skp":
    total_seconds: 12345.6
    first_seen: "2026-09-01"
    last_seen: "2026-09-28"
    days:
      "2026-09-28":
        seconds: 7200.5
        hours: { "14": 3600.0, "15": 3600.5 }
```

День недели вычисляется из даты. Запись атомарная (tmp + rename), битый файл
уходит в бэкап `stats.yaml.broken-*`.

## Окно статистики

Plugins → **DN1C Time Project 2** → «Статистика времени...»:

- сводка: файл, сегодня, сессия, всего, статус (активен / бездействие / пауза);
- вкладка «По дням» — таблица (дата, день недели, время);
- «По часам» — 24 столбца; «По дням недели» — 7 столбцов (Пн первый);
- выбор проекта из папки, пауза, открытие stats.yaml, порог бездействия;
- данные обновляются раз в 5 с.

Стиль — Modus Bootstrap (тёмная тема), CSS грузится с CDN — нужен интернет.

## Структура

```
dn1c_time_project2.rb            регистратор (SketchupExtension + Extension Manager)
dn1c_time_project2/
  main.rb                неймспейс Dn1cTimeProject2: setup!/unload!, меню
  tracker.rb             тики, активность, сессии, сброс в stats.yaml
  activity.rb            WinAPI через fiddle: фокус окна, последний ввод
  stats_store.rb         YAML: загрузка/запись, бакеты, агрегаты
  observers.rb           AppObserver (onQuit/onNewModel/onOpenModel), onSaveModel
  config.rb              настройки в реестре SketchUp (read_default/write_default)
  dialog.rb              HtmlDialog статистики
  ui/index.html, ui/app.js
  test/test_helper.rb    мини-харнесс (run! / assert / skip)
  test/stats_store_test.rb
  .sketchup_dev.json     манифест для инструментов MCP (display name, namespace)
```

## Разработка с живой обратной связью (MCP sketchup-dev)

1. Правка кода в этой папке (dev-копия).
2. `ext_install` — скопировать в Plugins живого SketchUp.
3. `ext_reload` — горячая перезагрузка: unload! → чистка $LOADED_FEATURES → load.
4. `ext_test` — прогон тестов внутри SketchUp.
5. `ext_pack` — собрать .rbz для распространения.

Локально (без SketchUp): `ruby test/stats_store_test.rb` — модельные тесты
уйдут в skip.

## Совместимость

Windows (WinAPI-детект активности), SketchUp 2024–2026 (Ruby 3.2), проверено
на SU 2026.2. На не-Windows учёт работает без проверки фокуса/ввода.
