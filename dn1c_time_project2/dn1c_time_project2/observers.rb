# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2/observers.rb — наблюдатели SketchUp.
# Учёт построен на тиках таймера (Tracker#tick сам замечает смену файла),
# обсерверы нужны только для мгновенной реакции: открытие/создание модели,
# сохранение, выход из SketchUp.
# =============================================================================

module Dn1cTimeProject2
  module Observers
    # Классы определяются только внутри SketchUp — чтобы модуль грузился
    # и в обычном Ruby (локальный прогон тестов).
    if defined?(Sketchup::AppObserver)
      # События приложения
      class App < Sketchup::AppObserver
        def expectsStartupModelNotifications
          true # onNewModel/onOpenModel для модели, открытой при старте
        end

        def onNewModel(_model)
          puts '[TimeProject2] Создана новая модель'
          Tracker.tick
        end

        def onOpenModel(_model)
          puts '[TimeProject2] Модель открыта'
          Tracker.tick
        end

        def onQuit
          Tracker.stop # финальный сброс статистики перед выходом
        end
      end

      # Сохранение модели — точка мгновенного сброса статистики
      class SaveModel < Sketchup::ModelObserver
        def onSaveModel(model)
          Tracker.on_save(model)
        end
      end
    end
  end
end
