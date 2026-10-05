# frozen_string_literal: true
# =============================================================================
# dn1sup_time_project2/tracker.rb — счётчик активного времени.
#
# Тик каждые TICK_INTERVAL секунд (UI.start_timer):
#   1. Определяем текущую модель. Сменилась — хвост интервала дописываем
#      прежнему проекту и переключаем сессию.
#   2. Активность = окно SketchUp в фокусе И ввод свежее порога
#      (Config#idle_minutes, WinAPI через Activity). Иначе тик не начисляется.
#   3. Активный интервал разбивается по границам часов/суток (segments) и
#      попадает в бакеты StatsStore — в памяти текущей модели.
#
# Хранение — внутри файла модели (атрибут-словарь, см. stats_store.rb):
#   • при сохранении модели (onSaveModel) статистика всегда пишется в файл;
#   • при переключении моделей и на выходе (Tracker#stop) — только если
#     модель уже изменена пользователем: запись атрибута помечает модель
#     изменённой, и расширение не должно провоцировать лишний вопрос
#     «Сохранить изменения?» на чистой модели.
#   • периодического флаша нет: накопленное между сохранениями живёт
#     в памяти и теряется при крахе так же, как несохранённая работа.
#
# Несохранённая модель копится под ключом UNSAVED и переносится под именем
# файла при первом сохранении (merge_project!). Данные открытых моделей
# держатся в кэше (@cache), чтобы переключение туда-обратно не теряло
# несохранённый хвост.
# =============================================================================

module Dn1supTimeProject2
  module Tracker
    extend self

    TICK_INTERVAL = 30.0
    MAX_GAP = 120.0 # разрыв больше этого (сон/зависание) не начисляется
    UNSAVED = 'Без имени (не сохранён)'
    CACHE_LIMIT = 16 # сколько моделей держать в памяти между переключениями

    attr_reader :current_folder, :current_name, :session_seconds

    # -- жизненный цикл ---------------------------------------------------------

    def start
      return if @timer_id

      reset_state
      @app_observer = Observers::App.new
      Sketchup.add_observer(@app_observer)
      Dn1supTimeProject2.track_observer(Sketchup, @app_observer)

      @timer_id = UI.start_timer(TICK_INTERVAL, true) { tick }
      Dn1supTimeProject2.track_timer(@timer_id)

      tick # сразу фиксируем текущую модель и точку отсчёта
      puts "[TimeProject2] Учёт времени запущен (тик #{TICK_INTERVAL.to_i} с, порог бездействия #{Config.idle_minutes} мин)"
    end

    def stop
      persist_if_dirty # хвост дописываем в файл, если модель уже изменена
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

    # Сохранение модели: первый save-as безымянной переносит бакеты UNSAVED
    # под имя файла, «Сохранить как» — под новое имя. Затем статистика
    # записывается в файл модели.
    def on_save(model)
      path = model.path.to_s
      return if path.empty?

      folder = File.dirname(path)
      name = File.basename(path)
      if folder != @current_folder || name != @current_name
        # доначисляем интервал с последнего тика, чтобы не потерять хвост
        credit(@last_tick, Time.now) if @last_tick && (Time.now - @last_tick) <= MAX_GAP && active_now?
        if @current_folder.nil?
          moved = StatsStore.merge_project!(@store, @store, UNSAVED, name)
          puts "[TimeProject2] Модель сохранена как #{name}: перенесено #{moved.round(1)} с" if moved.positive?
        else
          StatsStore.merge_project!(@store, @store, @current_name, name)
          puts "[TimeProject2] Модель сохранена как #{name}: статистика перенесена под новое имя"
        end
        @current_folder = folder
        @current_name = name
        @session_seconds = 0.0
        @last_tick = Time.now
      end

      @current_model = model
      attach_save_observer(model)
      persist_now
    rescue StandardError => e
      puts "[TimeProject2] Ошибка при сохранении: #{e.class}: #{e.message}"
    end

    # -- основной тик ------------------------------------------------------------

    def tick
      now = Time.now
      t0 = @last_tick
      @last_tick = now
      gap = t0 ? now - t0 : 0.0

      model = Sketchup.active_model
      folder, name = identify(model)
      if folder != @current_folder || name != @current_name
        # хвост интервала до переключения относится к прежнему проекту
        credit(t0, now) if t0 && gap <= MAX_GAP && active_now?
        switch_to(folder, name, model)
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
      @store
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
        'version' => Dn1supTimeProject2::VERSION,
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
      @cache = {}
      @current_key = nil
      @current_model = nil
      @current_folder = nil
      @current_name = nil
      @store = nil
      @store_dirty = false
      @session_seconds = 0.0
      @last_tick = nil
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
      @store_dirty = true
    end

    def switch_to(folder, name, model)
      # прежнюю модель дописываем в её файл, если пользователь её уже менял
      persist_if_dirty
      cache_put(@current_key, @store, @store_dirty) if @current_key && @store

      @current_model = model
      @current_folder = folder
      @current_name = name
      @session_seconds = 0.0
      @last_tick = Time.now
      @current_key = model_key(model)
      @store, @store_dirty = cache_get(@current_key, model)
      attach_save_observer(model)
      puts "[TimeProject2] Отслеживание: #{name}#{folder ? " → #{folder}" : ''}"
    end

    # -- запись статистики в модель ------------------------------------------------

    # Безусловная запись в файл модели — вызывается при сохранении модели.
    def persist_now
      return unless @current_model && @store

      if StatsStore.save(@current_model, @store)
        @store_dirty = false
        cache_put(@current_key, @store, false) if @current_key
      end
    end

    # Запись только если модель уже изменена пользователем — расширение
    # само не должно помечать «чистую» модель изменённой (иначе при её
    # закрытии появится лишний вопрос «Сохранить изменения?»).
    def persist_if_dirty
      return unless @store_dirty
      return unless @current_model&.respond_to?(:modified?) && @current_model.modified?

      persist_now
    rescue StandardError => e
      puts "[TimeProject2] Не удалось дописать статистику в прежнюю модель: #{e.message}"
    end

    # -- кэш данных открытых моделей -------------------------------------------------

    def model_key(model)
      "m#{model.persistent_id}"
    rescue StandardError
      "m#{model.object_id}"
    end

    def cache_get(key, model)
      entry = @cache[key]
      return [entry[:data], entry[:dirty]] if entry

      data = StatsStore.load(model)
      # данные, которых ещё нет в атрибутах модели (импорт из старого
      # stats.yaml), помечаем несохранёнными — попадут в файл при первом
      # же сохранении
      has_attrs = !!model.get_attribute(StatsStore::DICT_NAME, StatsStore::KEY)
      [data, !has_attrs && data['projects'].any?]
    end

    def cache_put(key, data, dirty)
      @cache.delete(key)
      @cache[key] = { data: data, dirty: dirty }
      @cache.shift while @cache.size > CACHE_LIMIT
    end

    def attach_save_observer(model)
      return unless model

      @attached_models ||= {}
      return if @attached_models[model.object_id]

      @save_observer ||= Observers::SaveModel.new
      model.add_observer(@save_observer)
      Dn1supTimeProject2.track_observer(model, @save_observer)
      @attached_models[model.object_id] = true
    rescue StandardError => e
      puts "[TimeProject2] Не удалось подключить наблюдатель сохранения: #{e.message}"
    end
  end
end
