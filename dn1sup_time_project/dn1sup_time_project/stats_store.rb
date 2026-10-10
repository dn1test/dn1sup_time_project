# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project/stats_store.rb — хранение статистики ВНУТРИ файла
# модели (.skp) в атрибут-словаре. Внешние файлы статистики не создаются.
#
#   model.get_attribute('dn1sup_time_project', 'stats')
#   => JSON-строка:
#   { "projects": {
#       "Проект.skp": {
#         "total_seconds": 12345.6,
#         "first_seen": "2026-09-01",
#         "last_seen": "2026-09-28",
#         "days": { "2026-09-28": { "seconds": 7200.5,
#                                   "hours": { "14": 3600.0, "15": 3600.5 } } }
#       } } }
#
# День недели не хранится — вычисляется из даты. Все ключи после загрузки
# нормализуются к строкам, числа к Float.
#
# ВАЖНО: запись атрибута помечает модель изменённой и создаёт шаг undo,
# поэтому save вызывается только при сохранении модели или когда модель
# уже изменена пользователем (см. Tracker#persist_if_dirty).
#
# Миграция: если в модели атрибутов ещё нет, при первом чтении секция
# переносится из старого stats.yaml папки (файл только читается — не
# удаляется и не переписывается).
# =============================================================================

require 'json'
require 'yaml' # только для чтения старых stats.yaml при миграции
require 'date'

module Dn1supTimeProject
  module StatsStore
    extend self

    DICT_NAME = 'dn1sup_time_project'
    LEGACY_DICT_NAME = 'dn1sup_time_project2' # словарь до переименования расширения
    KEY = 'stats'
    LEGACY_FILE_NAME = 'stats.yaml'
    OPERATION_NAME = 'Статистика времени'

    def fresh_data
      { 'projects' => {} }
    end

    def fresh_project
      { 'total_seconds' => 0.0, 'first_seen' => nil, 'last_seen' => nil, 'days' => {} }
    end

    # Чтение статистики из файла модели; пустая модель — импорт из старого stats.yaml
    def load(model)
      raw = model.get_attribute(DICT_NAME, KEY)
      # модели, сохранённые до переименования расширения: читаем старый словарь,
      # при следующем сохранении данные запишутся уже под новый ключ
      raw = model.get_attribute(LEGACY_DICT_NAME, KEY) unless raw.is_a?(String) && !raw.empty?
      if raw.is_a?(String) && !raw.empty?
        data = JSON.parse(raw)
        return data.is_a?(Hash) ? normalize(data) : fresh_data
      end
      legacy_import(model)
    rescue StandardError => e
      puts "[TimeProject] Статистика в файле модели не прочитана (#{e.message}); начинаю с нуля"
      fresh_data
    end

    # Запись статистики в атрибуты модели одной JSON-строкой.
    # См. шапку файла: помечает модель изменённой — вызывать только
    # при сохранении модели или если модель уже изменена пользователем.
    def save(model, data)
      json = JSON.generate(round_data(data))
      in_op = false
      if model.respond_to?(:start_operation) && model.respond_to?(:commit_operation)
        model.start_operation(OPERATION_NAME, true)
        in_op = true
      end
      model.set_attribute(DICT_NAME, KEY, json)
      model.commit_operation if in_op
      true
    rescue StandardError => e
      begin
        model.abort_operation if in_op && model.respond_to?(:abort_operation)
      rescue StandardError
        nil
      end
      puts "[TimeProject] Не удалось записать статистику в файл модели: #{e.message}"
      false
    end

    # Начислить секунды в бакет (проект, день "ГГГГ-ММ-ДД", час "Ч")
    def add_seconds!(data, project_name, day_key, hour_key, seconds)
      return if seconds.nil? || seconds <= 0

      proj = data['projects'][project_name] ||= fresh_project
      proj['total_seconds'] += seconds

      day = proj['days'][day_key] ||= { 'seconds' => 0.0, 'hours' => {} }
      day['seconds'] += seconds
      day['hours'][hour_key.to_s] = (day['hours'][hour_key.to_s] || 0.0) + seconds

      proj['first_seen'] = min_date(proj['first_seen'], day_key)
      proj['last_seen'] = max_date(proj['last_seen'], day_key)
      true
    end

    # Перенос всех бакетов проекта from (src_data) в проект to (dst_data) —
    # для безымянной модели, сохранённой впервые, и при «Сохранить как».
    # Возвращает перенесённые секунды.
    def merge_project!(src_data, dst_data, from, to)
      src = src_data['projects'][from]
      return 0.0 unless src

      moved = 0.0
      src['days'].each do |day_key, day|
        day['hours'].each do |hour_key, seconds|
          add_seconds!(dst_data, to, day_key, hour_key, seconds)
          moved += seconds
        end
      end
      src_data['projects'].delete(from)
      moved
    end

    # Агрегаты проекта для диалога; nil если проекта нет в данных.
    # День недели не отправляем — UI вычисляет его из даты (локализация на фронте).
    def aggregates(data, project_name, today: Date.today.strftime('%Y-%m-%d'))
      proj = data['projects'][project_name]
      return nil unless proj

      days = proj['days'].keys.sort.map do |date|
        { 'date' => date, 'seconds' => proj['days'][date]['seconds'].round(1) }
      end

      hours = Array.new(24, 0.0)
      weekdays = Array.new(7, 0.0) # понедельник первый
      proj['days'].each do |date, day|
        weekdays[(Date.parse(date).wday + 6) % 7] += day['seconds']
        day['hours'].each { |h, s| hours[h.to_i] += s }
      end

      {
        'total_seconds' => proj['total_seconds'].round(1),
        'today_seconds' => (proj['days'][today] && proj['days'][today]['seconds'] || 0.0).round(1),
        'first_seen' => proj['first_seen'],
        'last_seen' => proj['last_seen'],
        'days' => days.reverse, # новые сверху
        'hours' => hours.map { |s| s.round(1) },
        'weekdays' => weekdays.map { |s| s.round(1) }
      }
    end

    # Приведение прочитанных данных к каноническому виду (строки/Float)
    def normalize(data)
      fresh = fresh_data
      projects = data['projects'].is_a?(Hash) ? data['projects'] : {}
      projects.each do |name, proj|
        next unless proj.is_a?(Hash)

        p2 = fresh_project
        p2['total_seconds'] = float_or_zero(proj['total_seconds'])
        p2['first_seen'] = proj['first_seen'].to_s.empty? ? nil : proj['first_seen'].to_s
        p2['last_seen'] = proj['last_seen'].to_s.empty? ? nil : proj['last_seen'].to_s
        days = proj['days'].is_a?(Hash) ? proj['days'] : {}
        days.each do |date, day|
          next unless day.is_a?(Hash)

          d2 = { 'seconds' => float_or_zero(day['seconds']), 'hours' => {} }
          hours = day['hours'].is_a?(Hash) ? day['hours'] : {}
          hours.each { |h, s| d2['hours'][h.to_s] = float_or_zero(s) }
          p2['days'][date.to_s] = d2
        end
        fresh['projects'][name.to_s] = p2
      end
      fresh
    end

    def round_data(data)
      (data['projects'] || {}).each_value do |proj|
        proj['total_seconds'] = proj['total_seconds'].round(2)
        proj['days'].each_value do |day|
          day['seconds'] = day['seconds'].round(2)
          day['hours'].transform_values! { |s| s.round(2) }
        end
      end
      data
    end

    private

    # Одноразовый импорт секции этого файла из старого stats.yaml папки.
    # Старый файл только читается: не удаляется и не переписывается.
    def legacy_import(model)
      path = model.path.to_s
      return fresh_data if path.empty?

      yaml_path = File.join(File.dirname(path), LEGACY_FILE_NAME)
      return fresh_data unless File.exist?(yaml_path)

      raw = YAML.safe_load(File.read(yaml_path, encoding: 'UTF-8'), permitted_classes: [Date, Time])
      projects = raw.is_a?(Hash) ? raw['projects'] : nil
      section = projects.is_a?(Hash) ? projects[File.basename(path)] : nil
      return fresh_data unless section.is_a?(Hash)

      data = fresh_data
      data['projects'][File.basename(path)] = section
      puts "[TimeProject] Статистика импортирована из #{LEGACY_FILE_NAME} в файл модели (#{File.basename(path)})"
      normalize(data)
    rescue StandardError => e
      puts "[TimeProject] Старый #{LEGACY_FILE_NAME} не прочитан (#{e.message})"
      fresh_data
    end

    def float_or_zero(v)
      v.is_a?(Numeric) ? v.to_f : v.to_s.to_f
    end

    def min_date(a, b)
      return b if a.nil? || a.to_s.empty?

      a < b ? a : b
    end

    def max_date(a, b)
      return b if a.nil? || a.to_s.empty?

      a > b ? a : b
    end
  end
end
