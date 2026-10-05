# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project2/dialog.rb — окно статистики времени (UI::HtmlDialog).
# Стиль GUI — Vue 3 + Tailwind CSS (Vite singlefile bundle), тёмная/светлая тема.
# Разметка и логика: ui/index.html (собран из frontend/).
# Обмен Ruby ↔ JS: один экшен-колбэк 'call_ruby' + execute_script(updateUI).
# JS сам опрашивает данные раз в 5 с и по кнопке «Обновить».
# =============================================================================

require 'json'

module Dn1supTimeProject2
  # Свёрнутый диалог для visible? «видим», но bring_to_front и show его не
  # разворачивают — окно остаётся в панели задач и кнопка выглядит мёртвой.
  # Поднимаем окно вручную через WinAPI (не Windows — no-op).
  module DialogWindow
    extend self

    begin
      require 'fiddle/import'

      module WinAPI
        extend Fiddle::Importer
        dlload 'user32.dll'
        extern 'void* FindWindowW(const void*, const void*)'
        extern 'int IsIconic(void*)'
        extern 'int ShowWindow(void*, int)'
        extern 'int SetForegroundWindow(void*)'
      end

      SUPPORTED = true
    rescue LoadError, StandardError
      SUPPORTED = false
    end

    SW_RESTORE = 9

    def raise_from_taskbar
      return unless SUPPORTED

      title = (Dn1supTimeProject2.window_title + "\0").encode('UTF-16LE')
      hwnd = WinAPI.FindWindowW(nil, title)
      return if hwnd.nil? || (hwnd.respond_to?(:null?) && hwnd.null?)
      return if WinAPI.IsIconic(hwnd).zero?

      WinAPI.ShowWindow(hwnd, SW_RESTORE)
      WinAPI.SetForegroundWindow(hwnd)
    rescue StandardError
      nil
    end
  end

  class << self
    def window_title
      "Time Project v#{VERSION} — статистика"
    end

    def show_dialog
      dlg = @dialog
      if dlg && dlg.visible?
        dlg.bring_to_front
        DialogWindow.raise_from_taskbar
        return dlg
      end
      # Закрытый HtmlDialog повторным show не поднимается — пересоздаём
      # (как в dn1sup_menu_screen/settings_dialog.rb)
      dialogs.delete(dlg) if dlg
      dlg = track_dialog(UI::HtmlDialog.new(
        dialog_title: window_title,
        preferences_key: 'dn1sup_time_project2_dialog',
        width: 480, height: 720,
        min_width: 380, min_height: 520,
        resizable: true,
        style: UI::HtmlDialog::STYLE_DIALOG
      ))
      dlg.set_file(File.join(PLUG_ROOT, 'ui', 'index.html'))
      register_callbacks(dlg)
      dlg.show
      @dialog = dlg
    end

    def register_callbacks(dlg)
      dlg.add_action_callback('call_ruby') do |_ctx, name, param|
        case name.to_s
        when 'ready', 'get_stats'
          push_data(dlg)
        when 'toggle_pause'
          safe { Tracker.toggle_pause }
          push_data(dlg)
        when 'set_idle_minutes'
          safe { Tracker.idle_minutes = param.to_f }
          push_data(dlg)
        when 'select_project'
          safe { Tracker.selected_project = param.to_s.empty? ? nil : param.to_s }
          push_data(dlg)
        when 'open_folder'
          safe { open_model_file }
        when 'update_from_dev'
          safe do
            if defined?(UI) && UI.respond_to?(:start_timer)
              UI.start_timer(0.05, false) do
                res = DevUpdater.update_and_reload!(reopen_dialog: true, notify: false)
                if !res[:success] && defined?(UI)
                  UI.messagebox("Ошибка обновления из dev-папки:\n#{res[:error]}")
                end
              end
            else
              DevUpdater.update_and_reload!(reopen_dialog: true, notify: false)
            end
          end
        end
      end
    end

    def push_data(dlg)
      payload = safe { Tracker.ui_payload } || {}
      dlg.execute_script("window.updateUI(#{JSON.generate(payload)});")
    rescue StandardError => e
      puts "[TimeProject2] Не удалось передать данные в диалог: #{e.message}"
    end
  end
end
