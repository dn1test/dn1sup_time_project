# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project2.rb — регистратор расширения «DN1Sup Time Project 2» (единственный файл в корне
# Plugins). SketchUp автозагружает top-level .rb при старте; весь код лежит
# рядом в подпапке dn1sup_time_project2/.
#
# Регистратор идемпотентен: повторный load (горячая перезагрузка через
# ext_reload) не дублирует запись в Extension Manager — main.rb при этом
# загружается отдельным load (см. ext_reload MCP-сервера sketchup-dev).
#
# Author: DN1Sup <dn1codegen@gmail.com>
# License: MIT
# =============================================================================

require 'sketchup.rb'
require 'extensions.rb'

# ExtensionManager не включает Enumerable — только each/[]/size.
_registered = false
Sketchup.extensions.each { |e| _registered = true if e.name == "DN1Sup Time Project 2" }

unless _registered
  ext = SketchupExtension.new("DN1Sup Time Project 2", File.join('dn1sup_time_project2', 'main'))
  ext.description = "Учёт активного времени работы над проектом: статистика по дням, часам и дням недели хранится внутри файла модели (.skp)"
  ext.version     = '0.5.0'
  ext.creator     = "DN1Sup"
  ext.copyright   = '2026 DN1Sup <dn1codegen@gmail.com> (MIT)'
  ext.id          = 'dn1sup_time_project2' if ext.respond_to?(:id=)
  Sketchup.register_extension(ext, true) # true = загружать при старте SketchUp
end
