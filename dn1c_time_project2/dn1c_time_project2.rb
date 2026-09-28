# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2.rb — регистратор расширения «DN1C Time Project 2» (единственный файл в корне
# Plugins). SketchUp автозагружает top-level .rb при старте; весь код лежит
# рядом в подпапке dn1c_time_project2/.
#
# Регистратор идемпотентен: повторный load (горячая перезагрузка через
# ext_reload) не дублирует запись в Extension Manager — main.rb при этом
# загружается отдельным load (см. ext_reload MCP-сервера sketchup-dev).
# =============================================================================

require 'sketchup.rb'
require 'extensions.rb'

# ExtensionManager не включает Enumerable — только each/[]/size.
_registered = false
Sketchup.extensions.each { |e| _registered = true if e.name == "DN1C Time Project 2" }

unless _registered
  ext = SketchupExtension.new("DN1C Time Project 2", File.join('dn1c_time_project2', 'main'))
  ext.description = "Учёт активного времени работы над проектом: статистика по дням, часам и дням недели"
  ext.version     = '0.1.0'
  ext.creator     = "DN1Code"
  ext.copyright   = '2026, DN1Code'
  Sketchup.register_extension(ext, true) # true = загружать при старте SketchUp
end
