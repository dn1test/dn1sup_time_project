# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project2/stats_store.rb — хранение статистики в stats.yaml рядом
# с файлом проекта. Один файл на папку, секции по каждому .skp:
#
#   projects:
#     "Проект.skp":
#       total_seconds: 12345.6
#       first_seen: "2026-09-01"
#       last_seen: "2026-09-28"
#       days:
#         "2026-09-28":
#           seconds: 7200.5
#           hours: { "14": 3600.0, "15": 3600.5 }
#
# День недели не хранится — вычисляется из даты. Все ключи после загрузки
# нормализуются к строкам, числа к Float. Запись атомарная (tmp + rename),
# битый файл уходит в бэкап *.broken-*.
# =============================================================================

require 'yaml'
require 'date'

module Dn1supTimeProject2
  module StatsStore
    extend self

    FILE_NAME = 'stats.yaml'
    WD_RU = %w[Воскресенье Понедельник Вторник Среда Четверг Пятница Суббота].freeze

    def fresh_data
      { 'projects' => {} }
    end

    def fresh_project
      { 'total_seconds' => 0.0, 'first_seen' => nil, 'last_seen' => nil, 'days' => {} }
    end

    def path_for(folder)
      File.join(folder, FILE_NAME)
    end

    # Чтение stats.yaml папки
    def load(folder)
      path = path_for(folder)
      return fresh_data unless File.exist?(path)

      data = YAML.safe_load(File.read(path, encoding: 'UTF-8'), permitted_classes: [Date, Time])
      data.is_a?(Hash) ? normalize(data) : fresh_data
    rescue StandardError => e
      backup_path = "#{path}.broken-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
      begin
        File.rename(path, backup_path)
      rescue StandardError
        nil
      end
      puts "[TimeProject2] stats.yaml не прочитан (#{e.message}); файл сохранён как #{File.basename(backup_path)}"
      fresh_data
    end

    # Атомарная запись: временный файл + rename
    def save(folder, data)
      path = path_for(folder)
      tmp = "#{path}.tmp"
      File.open(tmp, 'w:UTF-8') { |f| f.write(YAML.dump(round_data(data))) }
      File.delete(path) if File.exist?(path)
      File.rename(tmp, path)
      true
    rescue StandardError => e
      puts "[TimeProject2] Не удалось записать #{path}: #{e.message}"
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
    # для безымянной модели, сохранённой впервые. Возвращает перенесённые секунды.
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

    # Агрегаты проекта для диалога; nil если проекта нет в данных
    def aggregates(data, project_name, today: Date.today.strftime('%Y-%m-%d'))
      proj = data['projects'][project_name]
      return nil unless proj

      days = proj['days'].keys.sort.map do |date|
        wday = Date.parse(date).wday
        { 'date' => date, 'weekday' => WD_RU[wday], 'seconds' => proj['days'][date]['seconds'].round(1) }
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

    # Приведение прочитанного YAML к каноническому виду (строки/Float)
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
