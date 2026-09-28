# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2/main.rb — основная логика расширения «DN1C Time Project 2».
#
# Код рассчитан на горячую перезагрузку (ext_reload MCP-сервера sketchup-dev):
#   • меню/таймеры/наблюдатели/диалоги регистрируются через track_* и
#     снимаются в unload! — старая версия не оставляет следов;
#   • код не использует file_loaded? (его состояние переживает reload и
#     заблокировало бы пересоздание меню).
# =============================================================================

begin
  require 'sketchup.rb'
rescue LoadError
  # загрузка в обычном Ruby — только для локального запуска тестов
end
require 'uri'

%w[config activity stats_store observers tracker dialog].each do |name|
  require File.join(File.dirname(__FILE__), "#{name}.rb")
end

module Dn1cTimeProject2
  VERSION   = '0.1.0'.freeze
  PLUG_ROOT = File.dirname(__FILE__).freeze

  class << self
    # -- отслеживаемые ресурсы (снимаются в unload!) ---------------------------

    def menu_pairs;  @menu_pairs  ||= []; end # [[родительский UI::Menu, пункт], ...]
    def timers;      @timers      ||= []; end # [id таймера, ...]
    def observers;   @observers   ||= []; end # [[цель, наблюдатель], ...]
    def dialogs;     @dialogs     ||= []; end # [UI::HtmlDialog, ...]

    def track_menu(parent, item)
      menu_pairs << [parent, item]
      item
    end

    def track_timer(id)
      timers << id
      id
    end

    def track_observer(target, observer)
      observers << [target, observer]
      observer
    end

    def track_dialog(dialog)
      dialogs << dialog
      dialog
    end

    # -- выгрузка: вызвать ПЕРЕД remove_const (это делает ext_reload) ----------

    def unload!
      Tracker.stop # финальный сброс статистики
      menu_pairs.each do |parent, item|
        begin
          parent.remove_item(item)
        rescue StandardError
          nil # меню уже пересоздано/закрыто
        end
      end
      timers.each do |id|
        begin
          UI.stop_timer(id)
        rescue StandardError
          nil
        end
      end
      observers.each do |target, observer|
        begin
          target.remove_observer(observer)
        rescue StandardError
          nil # модель уже закрыта
        end
      end
      dialogs.each do |dialog|
        begin
          dialog.close
        rescue StandardError
          nil
        end
      end
      true
    end

    # -- построение интерфейса --------------------------------------------------

    def setup!
      return if @setup_done
      return unless defined?(UI) && UI.respond_to?(:menu)

      @setup_done = true
      Tracker.start

      parent = UI.menu('Plugins')
      menu = track_menu(parent, parent.add_submenu('DN1C Time Project 2'))

      cmd_stats = UI::Command.new('Статистика времени...') { safe { show_dialog } }
      cmd_stats.menu_text = 'Статистика времени...'
      cmd_stats.tooltip = 'Статистика времени работы над проектом: дни, часы, дни недели'
      cmd_stats.status_bar_text = 'Открыть окно статистики времени работы'
      menu.add_item(cmd_stats)

      cmd_pause = UI::Command.new('Пауза отслеживания') { safe { Tracker.toggle_pause } }
      cmd_pause.menu_text = 'Пауза отслеживания'
      cmd_pause.tooltip = 'Приостановить или возобновить учёт времени'
      cmd_pause.set_validation_proc { Config.paused? ? MF_CHECKED : MF_UNCHECKED }
      menu.add_item(cmd_pause)

      menu.add_item('Открыть stats.yaml') { safe { open_stats_file } }
      menu.add_separator
      menu.add_item('О расширении') { about }
    end

    # Открыть stats.yaml текущего проекта в системном редакторе/браузере
    def open_stats_file
      folder = Tracker.current_folder
      if folder.nil? || folder.to_s.empty?
        UI.messagebox('Модель ещё не сохранена — stats.yaml появится в папке проекта после первого сохранения.')
        return
      end
      path = StatsStore.path_for(folder)
      url = 'file:///' + URI::DEFAULT_PARSER.escape(path.tr('\\', '/'))
      UI.openURL(url)
    end

    def about
      UI.messagebox(
        "DN1C Time Project 2 v#{VERSION}\n\n" \
        "Учёт активного времени работы над проектом.\n" \
        "Статистика по дням, часам и дням недели в stats.yaml рядом с файлом проекта.\n\n" \
        "Активным считается время, пока окно SketchUp в фокусе и не истёк порог бездействия (#{Config.idle_minutes} мин)."
      )
    end

    # Ошибки команд не должны ронять SketchUp — показываем их пользователю.
    def safe
      yield
    rescue StandardError => e
      UI.messagebox("DN1C Time Project 2: #{e.class}: #{e.message}")
    end
  end
end

Dn1cTimeProject2.setup!
