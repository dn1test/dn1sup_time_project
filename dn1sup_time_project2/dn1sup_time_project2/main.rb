# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project2/main.rb — основная логика расширения «DN1Sup Time Project 2».
#
# Код рассчитан на горячую перезагрузку (ext_reload MCP-сервера sketchup-dev):
#   • таймеры/наблюдатели/диалоги регистрируются через track_* и снимаются
#     в unload! — старая версия не оставляет следов;
#   • меню и тулбар создаются один раз на сессию SketchUp: UI::Menu в
#     современных версиях не имеет API удаления, поэтому пункты ссылаются на
#     Dn1supTimeProject2.* через константу и после перезагрузки вызывают
#     уже новый код.
# =============================================================================

begin
  require 'sketchup.rb'
rescue LoadError
  # загрузка в обычном Ruby — только для локального запуска тестов
end
require 'uri'

%w[config activity stats_store observers tracker dialog win_shell].each do |name|
  require File.join(File.dirname(__FILE__), "#{name}.rb")
end
begin
  dev_file = File.join(File.dirname(__FILE__), "dev_updater.rb")
  require dev_file if File.file?(dev_file)
rescue LoadError
  nil
end

module Dn1sup
  def self.common_menu
    @common_menu ||= begin
      legacy = (defined?($dn1sup_common_menu) && $dn1sup_common_menu) || (defined?($dn1sup_menu) && $dn1sup_menu)
      legacy || UI.menu('Extensions').add_submenu('DN1Sup')
    end
  end
end

module Dn1supTimeProject2
  VERSION   = '2.4.1'.freeze
  PLUG_ROOT = File.dirname(__FILE__).freeze

  COMMON_MENU  = 'DN1Sup'.freeze # общее меню всех расширений DN1Sup
  MENU_NAME    = 'Time Project 2'.freeze # подменю расширения внутри COMMON_MENU

  TOOLBAR_NAME  = 'DN1Sup Time Project 2'.freeze
  CMD_TOOLTIP   = 'DN1Sup Time Project 2 — статистика времени'.freeze

  class << self
    # -- отслеживаемые ресурсы (снимаются в unload!) ---------------------------

    def timers;    @timers    ||= []; end # [id таймера, ...]
    def observers; @observers ||= []; end # [[цель, наблюдатель], ...]
    def dialogs;   @dialogs   ||= []; end # [UI::HtmlDialog, ...]

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
    # Меню здесь не трогаем: UI::Menu не имеет API удаления, пункты живут
    # всю сессию и продолжают работать, ссылаясь на константу модуля.

    def unload!
      Tracker.stop # финальный сброс статистики
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

      setup_ui
    end

    # Меню и панель инструментов создаются один раз на сессию SketchUp:
    # UI::Menu в современных версиях не имеет API удаления (remove_item
    # отсутствует), и пересоздание при горячей перезагрузке накопило бы
    # дубли. Ссылка на общее меню DN1Sup живёт в глобальной переменной
    # (глобалы переживают remove_const и чистку $LOADED_FEATURES), а все
    # пункты вызывают Dn1supTimeProject2.* через константу — после
    # перезагрузки они dispatch-атся уже в новый код, как и кнопка тулбара.
    # Меню «Extensions > DN1Sup» создаётся первым загрузившимся расширением
    # через Dn1sup.common_menu без глобальных переменных. Своё подменю создаётся один раз.
    def setup_ui
      return if @menu_created || (defined?(Dn1sup) && Dn1sup.instance_variable_get(:@tp2_menu))

      common = Dn1sup.common_menu
      menu = common.add_submenu(MENU_NAME)
      @menu_created = true
      Dn1sup.instance_variable_set(:@tp2_menu, menu) if defined?(Dn1sup)

      cmd_stats = UI::Command.new('Статистика времени...') do
        Dn1supTimeProject2.safe { Dn1supTimeProject2.show_dialog }
      end
      cmd_stats.menu_text = 'Статистика времени...'
      cmd_stats.tooltip = 'Статистика времени работы над проектом: дни, часы, дни недели'
      cmd_stats.status_bar_text = 'Открыть окно статистики времени работы'
      menu.add_item(cmd_stats)

      cmd_pause = UI::Command.new('Пауза отслеживания') do
        Dn1supTimeProject2.safe { Dn1supTimeProject2::Tracker.toggle_pause }
      end
      cmd_pause.menu_text = 'Пауза отслеживания'
      cmd_pause.tooltip = 'Приостановить или возобновить учёт времени'
      cmd_pause.set_validation_proc do
        Dn1supTimeProject2::Config.paused? ? MF_CHECKED : MF_UNCHECKED
      end
      menu.add_item(cmd_pause)

      menu.add_item('Показать модель в Проводнике') { Dn1supTimeProject2.safe { Dn1supTimeProject2.open_model_file } }
      menu.add_separator
      menu.add_item('🔄 Обновить из dev-папки') { Dn1supTimeProject2.safe { Dn1supTimeProject2.update_from_dev } }
      menu.add_item('⚡ Перезагрузить (Hot Reload)') { Dn1supTimeProject2.safe { Dn1supTimeProject2.hot_reload } }
      menu.add_separator
      menu.add_item('О расширении') { Dn1supTimeProject2.about }

      setup_toolbar
    end

    # Панель инструментов с кнопкой запуска панели статистики.
    # Тулбар нельзя удалить через API, поэтому кнопка создаётся один раз:
    # после горячей перезагрузки UI::Toolbar.new возвращает существующую
    # панель, а блок старой кнопки ссылается на константу модуля, которая
    # к этому моменту указывает уже на новый код.
    def setup_toolbar
      toolbar = UI::Toolbar.new(TOOLBAR_NAME)
      return if toolbar.any? { |c| c.tooltip == CMD_TOOLTIP }

      cmd = UI::Command.new('Статистика времени') do
        Dn1supTimeProject2.show_dialog if defined?(Dn1supTimeProject2)
      end
      cmd.menu_text = 'Статистика времени...'
      cmd.tooltip = CMD_TOOLTIP
      cmd.status_bar_text = 'Открыть окно статистики времени работы'
      cmd.small_icon = File.join(PLUG_ROOT, 'icons', 'timer_16.png')
      cmd.large_icon = File.join(PLUG_ROOT, 'icons', 'timer_24.png')
      toolbar.add_item(cmd)
      toolbar.restore
    rescue StandardError => e
      puts "[TimeProject2] Не удалось создать панель инструментов: #{e.message}"
    end

    # Показать файл модели в Проводнике (файл выделен)
    def open_model_file
      folder = Tracker.current_folder
      if folder.nil? || folder.to_s.empty?
        UI.messagebox('Модель ещё не сохранена на диск — статистика хранится в файле модели и появится после первого сохранения.')
        return
      end
      path = File.join(folder, Tracker.current_name.to_s)
      UI.messagebox("Файл не найден: #{path}") unless File.exist?(path) && WinShell.reveal(path)
    end

    def update_from_dev(dev_dir = nil)
      return unless defined?(DevUpdater)
      was_open = @dialog && @dialog.visible?
      DevUpdater.update_and_reload!(dev_dir: dev_dir, reopen_dialog: was_open, notify: true)
    end

    def hot_reload
      return unless defined?(DevUpdater)
      DevUpdater.reload!
      UI.messagebox("⚡ Time Project v#{VERSION} перезагружен!") if defined?(UI)
    end

    def about
      UI.messagebox(
        "Time Project v#{VERSION}\n\n" \
        "Учёт активного времени работы над проектом.\n" \
        "Статистика по дням, часам и дням недели хранится внутри файла модели (.skp).\n\n" \
        "Активным считается время, пока окно SketchUp в фокусе и не истёк порог бездействия (#{Config.idle_minutes} мин)."
      )
    end

    # Ошибки команд не должны ронять SketchUp — показываем их пользователю.
    def safe
      yield
    rescue StandardError => e
      UI.messagebox("Time Project: #{e.class}: #{e.message}")
    end
  end
end

Dn1supTimeProject2.setup!
