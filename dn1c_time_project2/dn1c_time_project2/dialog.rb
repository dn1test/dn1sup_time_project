# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2/dialog.rb — окно статистики времени (UI::HtmlDialog).
# Стиль GUI — Modus Bootstrap (дизайн-система Trimble/SketchUp), светлая тема;
# CSS вендорен в ui/assets/modus-bootstrap.min.css — офлайн без CDN.
# Разметка: ui/index.html, логика: ui/app.js.
# Обмен Ruby ↔ JS: один экшен-колбэк 'call_ruby' + execute_script(updateUI).
# JS сам опрашивает данные раз в 5 с и по кнопке «Обновить».
# =============================================================================

require 'json'

module Dn1cTimeProject2
  class << self
    def show_dialog
      dlg = @dialog
      if dlg && dlg.visible?
        dlg.bring_to_front
        return dlg
      end
      # Закрытый HtmlDialog повторным show не поднимается — пересоздаём
      # (как в dn1c_menu_screen/settings_dialog.rb)
      dialogs.delete(dlg) if dlg
      dlg = track_dialog(UI::HtmlDialog.new(
        dialog_title: 'DN1C Time Project 2 — статистика',
        preferences_key: 'dn1c_time_project2_dialog',
        width: 480, height: 720,
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
        when 'select_project'
          safe { Tracker.ui_project = param.to_s }
          push_data(dlg)
        when 'set_idle_minutes'
          safe { Tracker.idle_minutes = param.to_f }
          push_data(dlg)
        when 'open_folder'
          safe { open_stats_file }
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
