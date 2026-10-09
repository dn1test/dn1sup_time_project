# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project/win_shell.rb — открытие файлов средствами Windows.
# UI.openURL не открывает file:// URL (возвращает false), поэтому Проводник
# запускаем через ShellExecuteW (не Windows — no-op).
# =============================================================================

module Dn1supTimeProject
  module WinShell
    extend self

    begin
      require 'fiddle/import'

      module API
        extend Fiddle::Importer
        dlload 'shell32.dll'
        extern 'void* ShellExecuteW(void*, const void*, const void*, const void*, const void*, int)'
      end

      SUPPORTED = true
    rescue LoadError, StandardError
      SUPPORTED = false
    end

    SW_SHOWNORMAL = 1

    # Открыть Проводник с выделенным файлом. true — окно запрошено.
    def reveal(path)
      return false unless SUPPORTED

      ret = API.ShellExecuteW(nil, nil,
                              wide('explorer.exe'),
                              wide(%(/select,"#{path.tr('/', '\\')}")),
                              nil, SW_SHOWNORMAL)
      ret.to_i > 32
    rescue StandardError
      false
    end

    private

    # LPCWSTR: UTF-16LE с нулевым терминатором
    def wide(str)
      (str + "\0").encode('UTF-16LE')
    end
  end
end
