# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project/config.rb — настройки расширения.
# Хранятся в реестре SketchUp (Sketchup.read_default/write_default):
# переживают перезагрузку расширения и переустановку, не создают файлов.
# =============================================================================

module Dn1supTimeProject
  module Config
    extend self

    KEY = 'dn1sup_time_project'
    LEGACY_KEY = 'dn1sup_time_project2' # раздел до переименования расширения

    def paused?
      !!Sketchup.read_default(KEY, 'paused', false)
    end

    def paused=(value)
      Sketchup.write_default(KEY, 'paused', value ? true : false)
    end

    # Порог бездействия: если ввода (мышь/клавиатура) нет дольше указанных
    # минут, время не начисляется.
    def idle_minutes
      (Sketchup.read_default(KEY, 'idle_minutes', 5) || 5).to_f
    end

    def idle_minutes=(value)
      v = value.to_f
      v = 5.0 if v.nan? || v <= 0.0
      v = 1.0 if v < 1.0
      v = 240.0 if v > 240.0
      Sketchup.write_default(KEY, 'idle_minutes', v)
    end

    # Разовый перенос настроек из раздела старого имени расширения:
    # значения по умолчанию неотличимы от «не задано», поэтому фиксируем
    # выполнение маркером в новом разделе.
    def migrate_legacy!
      return if Sketchup.read_default(KEY, 'legacy_migrated')

      Sketchup.write_default(KEY, 'legacy_migrated', true)
      ['paused', 'idle_minutes'].each do |name|
        value = Sketchup.read_default(LEGACY_KEY, name, nil)
        Sketchup.write_default(KEY, name, value) unless value.nil?
      end
      true
    rescue StandardError
      nil
    end
  end
end
