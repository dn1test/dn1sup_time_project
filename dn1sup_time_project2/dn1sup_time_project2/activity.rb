# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project2/activity.rb — определение активности пользователя (WinAPI
# через fiddle, по образцу mouse_tracker.rb из dn1sup_menu_screen):
#   • окно SketchUp в фокусе — GetForegroundWindow + GetWindowThreadProcessId;
#   • секунд с последнего ввода (мышь/клавиатура) — GetLastInputInfo.
# Если библиотеки недоступны (не Windows) — считаем пользователя активным,
# чтобы учёт не прерывался.
# =============================================================================

module Dn1supTimeProject2
  module Activity
    extend self

    begin
      require 'fiddle'
      require 'fiddle/import'

      module WinAPI
        extend Fiddle::Importer
        dlload 'user32.dll', 'kernel32.dll'

        extern 'void* GetForegroundWindow()'
        extern 'int GetWindowThreadProcessId(void*, void*)'
        extern 'int GetCurrentProcessId()'
        extern 'int GetLastInputInfo(void*)'
        extern 'unsigned long GetTickCount()'
      end

      SUPPORTED = true
    rescue LoadError, StandardError
      SUPPORTED = false
    end

    # Активное (в фокусе) окно принадлежит процессу SketchUp?
    def foreground?
      return true unless SUPPORTED

      hwnd = WinAPI.GetForegroundWindow
      return false if hwnd.nil? || (hwnd.respond_to?(:null?) && hwnd.null?)

      pid = [0].pack('L')
      WinAPI.GetWindowThreadProcessId(hwnd, pid)
      pid.unpack1('L') == WinAPI.GetCurrentProcessId
    rescue StandardError
      true
    end

    # Сколько секунд прошло с последнего ввода мыши/клавиатуры в системе
    def seconds_since_input
      return 0.0 unless SUPPORTED

      # LASTINPUTINFO { UINT cbSize; DWORD dwTime; } — время в тиках GetTickCount
      info = [8, 0].pack('L2')
      return 0.0 if WinAPI.GetLastInputInfo(info).zero?

      last_tick = info.unpack('L2')[1]
      ((WinAPI.GetTickCount - last_tick) & 0xFFFF_FFFF) / 1000.0
    rescue StandardError
      0.0
    end

    # Пользователь активно работает: SketchUp в фокусе и ввод свежее порога
    def active?(idle_minutes)
      foreground? && seconds_since_input <= idle_minutes * 60.0
    end
  end
end
