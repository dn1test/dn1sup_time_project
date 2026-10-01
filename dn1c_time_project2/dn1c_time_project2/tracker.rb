# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2/tracker.rb — счётчик активного времени.
#
# Тик каждые TICK_INTERVAL секунд (UI.start_timer):
#   1. Определяем текущую модель (папка + имя файла). Сменилась — хвост
#      интервала дописываем прежнему проекту и переключаем сессию.
#   2. Активность = окно SketchUp в фокусе И ввод свежее порога
#      (Config#idle_minutes, WinAPI через Activity). Иначе тик не начисляется.
#   3. Активный интервал разбивается по границам часов/суток (segments) и
#      попадает в бакеты StatsStore.
# Накопленное сбрасывается в stats.yaml каждые FLUSH_INTERVAL секунд,
# при смене файла, по onSaveModel, при выходе (AppObserver#onQuit) и в unload!.
#
# Несохранённая модель копится в памяти (@unsaved_store) и переносится
# в stats.yaml папки при первом сохранении (merge_project!).
# =============================================================================

module Dn1cTimeProject2
  module Tracker
    extend self

    TICK_INTERVAL = 30.0
    FLUSH_INTERVAL = 60.0
    MAX_GAP = 120.0 # разрыв больше этого (сон/зависание) не начисляется
    UNSAVED = 'Без имени (не сохранён)'

    attr_reader :current_folder, :current_name, :session_seconds

    # -- жизненный цикл ---------------------------------------------------------

    def start
      return if @timer_id

      reset_state
      @app_observer = Observers::App.new
      Sketchup.add_observer(@app_observer)
      Dn1cTimeProject2.track_observer(Sketchup, @app_observer)

      @timer_id = UI.start_timer(TICK_INTERVAL, true) { tick }
      Dn1cTimeProject2.track_timer(@timer_id)

      tick # сразу фиксируем текущую модель и точку отсчёта
      puts "[TimeProject2] Учёт времени запущен (тик #{TICK_INTERVAL.to_i} с, порог бездействия #{Config.idle_minutes} мин)"
    end

    def stop
      flush_now
      if @timer_id
        UI.stop_timer(@timer_id)
        @timer_id = nil
      end
      @status = :off
      true
    end

    def running?
      !!@timer_id
    end

    # -- обработка событий ------------------------------------------------------

    # Пауза вручную (меню/диалог). Возвращает новое состояние.
    def toggle_pause
      Config.paused = !Config.paused?
      puts "[TimeProject2] #{Config.paused? ? 'Пауза учёта' : 'Учёт продолжается'}"
      Config.paused?
    end

    # Сохранение модели: безымянную переносим в stats.yaml папки, остальное — flush
    def on_save(model)
      path = model.path.to_s
      if @current_folder.nil? && !path.empty?
        # доначисляем интервал с последнего тика, чтобы не потерять хвост
        credit(@last_tick, Time.now) if @last_tick && (Time.now - @last_tick) <= MAX_GAP && active_now?
        folder = File.dirname(path)
        name = File.basename(path)
        store = StatsStore.load(folder)
        moved = StatsStore.merge_project!(@unsaved_store, store, UNSAVED, name)
        @unsaved_store = StatsStore.fresh_data
        @current_folder = folder
        @current_name = name
        @store = store
        @session_seconds = 0.0
        @last_tick = Time.now
        attach_save_observer(model)
        StatsStore.save(folder, store)
        @last_flush = Time.now
        puts "[TimeProject2] Модель сохранена как #{name}: перенесено #{moved.round(1)} с"
      else
        flush_now
      end
    rescue StandardError => e
      puts "[TimeProject2] Ошибка при сохранении: #{e.class}: #{e.message}"
    end

    # -- основной тик ------------------------------------------------------------

    def tick
      now = Time.now
      t0 = @last_tick
      @last_tick = now
      gap = t0 ? now - t0 : 0.0

      folder, name = identify(Sketchup.active_model)
      if folder != @current_folder || name != @current_name
        # хвост интервала до переключения относится к прежнему проекту
        credit(t0, now) if t0 && gap <= MAX_GAP && active_now?
        switch_to(folder, name)
        return
      end

      if Config.paused?
        @status = :paused
      elsif gap > MAX_GAP
        @status = :idle # большой разрыв (сон/зависание) — время не начисляем
      elsif active_now?
        credit(t0, now) if t0
        @session_seconds += gap
        @status = :active
      else
        @status = :idle
      end

      flush_now if @last_flush.nil? || now - @last_flush >= FLUSH_INTERVAL
    rescue StandardError => e
      puts "[TimeProject2] Ошибка тика: #{e.class}: #{e.message}"
    end

    # Разбивка интервала по границам часов: [[начало, конец], ...]
    # (используется в credit и в тестах)
    def segments(t0, t1)
      out = []
      t = t0
      while t < t1
        boundary = Time.new(t.year, t.month, t.day, t.hour) + 3600
        e = t1 < boundary ? t1 : boundary
        out << [t, e]
        t = e
      end
      out
    end

    # -- данные для диалога -------------------------------------------------------

    def status
      @status || :off
    end

    def store_data
      @current_folder ? @store : @unsaved_store
    end

    def idle_minutes=(value)
      Config.idle_minutes = value
    end

    attr_accessor :selected_project

    def ui_payload
      data = store_data || StatsStore.fresh_data
      available = data['projects'].keys
      selected = @selected_project && available.include?(@selected_project) ? @selected_project : (@current_name || UNSAVED)
      {
        'version' => Dn1cTimeProject2::VERSION,
        'status' => status.to_s,
        'paused' => Config.paused?,
        'idle_minutes' => Config.idle_minutes,
        'current' => @current_name,
        'folder' => @current_folder.to_s,
        'session_seconds' => @session_seconds.round(1),
        'today' => Time.now.strftime('%Y-%m-%d'),
        'tick_interval' => TICK_INTERVAL.to_i,
        'projects' => available,
        'selected' => selected,
        'stats' => StatsStore.aggregates(data, selected)
      }
    end

    private

    def reset_state
      @store = nil
      @unsaved_store = StatsStore.fresh_data
      @current_folder = nil
      @current_name = nil
      @session_seconds = 0.0
      @last_tick = nil
      @last_flush = nil
      @status = :off
      @attached_models = {}
    end

    def identify(model)
      return [nil, UNSAVED] if model.nil? || model.path.to_s.empty?

      [File.dirname(model.path), File.basename(model.path)]
    end

    def active_now?
      Activity.active?(Config.idle_minutes)
    end

    # Начислить интервал текущему проекту (разбивка по часам/суткам)
    def credit(t0, t1)
      data = store_data
      return unless data && @current_name

      segments(t0, t1).each do |t, e|
        StatsStore.add_seconds!(data, @current_name, t.strftime('%Y-%m-%d'), t.hour.to_s, e - t)
      end
    end

    def switch_to(folder, name)
      flush_now # дописываем прежний проект, если был
      @current_folder = folder
      @current_name = name
      @session_seconds = 0.0
      @last_tick = Time.now
      if folder
        @store = StatsStore.load(folder)
        attach_save_observer(Sketchup.active_model)
      else
        @store = nil
      end
      @last_flush = Time.now
      puts "[TimeProject2] Отслеживание: #{name}#{folder ? " → #{folder}" : ''}"
    end

    def flush_now
      return unless @current_folder && @store

      StatsStore.save(@current_folder, @store)
      @last_flush = Time.now
    end

    def attach_save_observer(model)
      return unless model

      @attached_models ||= {}
      return if @attached_models[model.object_id]

      @save_observer ||= Observers::SaveModel.new
      model.add_observer(@save_observer)
      Dn1cTimeProject2.track_observer(model, @save_observer)
      @attached_models[model.object_id] = true
    rescue StandardError => e
      puts "[TimeProject2] Не удалось подключить наблюдатель сохранения: #{e.message}"
    end
  end
end
