# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2/test/stats_store_test.rb — тесты логики учёта времени.
# Запуск: внутри SketchUp через ext_test (MCP sketchup-dev) или меню
# «Тесты»; локально — ruby test/stats_store_test.rb.
# =============================================================================

require_relative 'test_helper'
require 'tmpdir'
require 'fileutils'

module Dn1cTimeProject2
  module Test
    test 'версия расширения задана' do
    assert_equal '0.2.1', Dn1cTimeProject2::VERSION
  end

  test 'unload! определён (нужен для ext_reload)' do
    assert(Dn1cTimeProject2.respond_to?(:unload!), 'нет unload!')
  end

  # -- Tracker.segments ---------------------------------------------------------

  test 'интервал внутри одного часа даёт один сегмент' do
    t0 = Time.new(2026, 9, 28, 14, 10)
    segs = Tracker.segments(t0, t0 + 20 * 60)
    assert_equal 1, segs.size
    assert_equal 20 * 60, segs[0][1] - segs[0][0]
  end

  test 'интервал через границу часа разбивается на два' do
    t0 = Time.new(2026, 9, 28, 13, 50)
    segs = Tracker.segments(t0, t0 + 20 * 60)
    assert_equal 2, segs.size
    assert_equal Time.new(2026, 9, 28, 14, 0), segs[1][0]
    assert_equal 13, segs[0][0].hour
    assert_equal 14, segs[1][0].hour
  end

  test 'интервал через полночь переходит на следующий день' do
    t0 = Time.new(2026, 9, 28, 23, 50)
    segs = Tracker.segments(t0, t0 + 20 * 60)
    assert_equal 2, segs.size
    assert_equal '2026-09-28', segs[0][0].strftime('%Y-%m-%d')
    assert_equal '2026-09-29', segs[1][0].strftime('%Y-%m-%d')
  end

  test 'длинный интервал через полночь: 4 сегмента и точная сумма' do
    t0 = Time.new(2026, 9, 28, 22, 0)
    segs = Tracker.segments(t0, t0 + 4 * 3600)
    assert_equal 4, segs.size
    total = segs.sum { |a, b| b - a }
    assert_equal 4 * 3600, total
  end

  test 'нулевой интервал даёт пустой список' do
    t = Time.new(2026, 9, 28, 10, 0)
    assert_equal [], Tracker.segments(t, t)
  end

  # -- StatsStore.add_seconds! ---------------------------------------------------

  test 'add_seconds! создаёт структуру и суммирует' do
    data = StatsStore.fresh_data
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-28', '14', 60.0)
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-28', '14', 30.0)
    proj = data['projects']['a.skp']
    assert_equal 90.0, proj['total_seconds']
    assert_equal 90.0, proj['days']['2026-09-28']['seconds']
    assert_equal 90.0, proj['days']['2026-09-28']['hours']['14']
    assert_equal '2026-09-28', proj['first_seen']
    assert_equal '2026-09-28', proj['last_seen']
  end

  test 'add_seconds! обновляет границы first/last_seen' do
    data = StatsStore.fresh_data
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-20', '9', 10.0)
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-28', '9', 10.0)
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-25', '9', 10.0)
    proj = data['projects']['a.skp']
    assert_equal '2026-09-20', proj['first_seen']
    assert_equal '2026-09-28', proj['last_seen']
  end

  test 'add_seconds! игнорирует нулевые и отрицательные секунды' do
    data = StatsStore.fresh_data
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-28', '14', 0.0)
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-28', '14', -5.0)
    assert_equal({}, data['projects'])
  end

  # -- YAML round-trip и повреждённый файл ----------------------------------------

  test 'сохранение и чтение stats.yaml (round-trip, кириллица)' do
    Dir.mktmpdir('tp2test') do |dir|
      data = StatsStore.fresh_data
      StatsStore.add_seconds!(data, 'Проект ~ Этаж (2).skp', '2026-09-28', '9', 1234.5)
      assert(StatsStore.save(dir, data), 'save вернул false')
      assert(File.exist?(StatsStore.path_for(dir)), 'stats.yaml не создан')

      loaded = StatsStore.load(dir)
      proj = loaded['projects']['Проект ~ Этаж (2).skp']
      assert(proj, 'проект не прочитан')
      assert_equal 1234.5, proj['total_seconds']
      assert_equal({ '9' => 1234.5 }, proj['days']['2026-09-28']['hours'])
    end
  end

  test 'чтение несуществующей папки даёт пустые данные' do
    Dir.mktmpdir('tp2test') do |dir|
      assert_equal({}, StatsStore.load(dir)['projects'])
    end
  end

  test 'битый YAML уходит в бэкап, данные начинаются с чистого листа' do
    Dir.mktmpdir('tp2test') do |dir|
      File.write(StatsStore.path_for(dir), '{ broken: [')
      loaded = StatsStore.load(dir)
      assert_equal({}, loaded['projects'])
      backups = Dir.glob(File.join(dir, 'stats.yaml.broken-*'))
      assert_equal 1, backups.size, 'бэкап битого файла не создан'
    end
  end

  # -- StatsStore.aggregates -------------------------------------------------------

  test 'агрегаты: часы, дни недели (Пн первый), сегодня' do
    data = StatsStore.fresh_data
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-28', '14', 3600.0) # понедельник
    StatsStore.add_seconds!(data, 'a.skp', '2026-09-27', '10', 60.0)   # воскресенье
    agg = StatsStore.aggregates(data, 'a.skp', today: '2026-09-28')
    assert_equal 3660.0, agg['total_seconds']
    assert_equal 3600.0, agg['today_seconds']
    assert_equal 3600.0, agg['hours'][14]
    assert_equal 60.0, agg['hours'][10]
    assert_equal 3600.0, agg['weekdays'][0], 'понедельник должен быть первым'
    assert_equal 60.0, agg['weekdays'][6], 'воскресенье должно быть последним'
    assert_equal 'Понедельник', agg['days'].first['weekday']
    assert_equal '2026-09-28', agg['days'].first['date'], 'новые дни сверху'
  end

  test 'агрегаты отсутствующего проекта — nil' do
    assert_nil StatsStore.aggregates(StatsStore.fresh_data, 'нет.skp')
  end

  # -- StatsStore.merge_project! ---------------------------------------------------

  test 'merge_project! переносит бакеты безымянной модели в сохранённую' do
    src = StatsStore.fresh_data
    StatsStore.add_seconds!(src, Tracker::UNSAVED, '2026-09-28', '18', 120.0)
    StatsStore.add_seconds!(src, Tracker::UNSAVED, '2026-09-28', '19', 60.0)
    dst = StatsStore.fresh_data
    StatsStore.add_seconds!(dst, 'b.skp', '2026-09-28', '18', 30.0)

    moved = StatsStore.merge_project!(src, dst, Tracker::UNSAVED, 'b.skp')
    assert_equal 180.0, moved
    assert_nil src['projects'][Tracker::UNSAVED], 'исходный проект не удалён'
    proj = dst['projects']['b.skp']
    assert_equal 210.0, proj['total_seconds']
    assert_equal 150.0, proj['days']['2026-09-28']['hours']['18']
  end

  test 'merge_project! с отсутствующим источником — 0' do
    moved = StatsStore.merge_project!(StatsStore.fresh_data, StatsStore.fresh_data, 'x', 'y.skp')
    assert_equal 0.0, moved
  end

  # -- normalize / round_data --------------------------------------------------------

  test 'normalize приводит ключи к строкам и числа к Float' do
    raw = {
      'projects' => {
        'a.skp' => {
          'total_seconds' => 90,
          'first_seen' => Date.new(2026, 9, 28),
          'last_seen' => nil,
          'days' => { Date.new(2026, 9, 28) => { 'seconds' => 90, 'hours' => { 14 => 90 } } }
        }
      }
    }
    norm = StatsStore.normalize(raw)
    proj = norm['projects']['a.skp']
    assert_equal 90.0, proj['total_seconds']
    assert_equal '2026-09-28', proj['first_seen']
    assert_nil proj['last_seen']
    assert_equal({ '14' => 90.0 }, proj['days']['2026-09-28']['hours'])
  end

  # -- день недели ---------------------------------------------------------------------

  test 'имена дней недели: 2026-09-28 — понедельник' do
    assert_equal 1, Date.parse('2026-09-28').wday
    assert_equal 'Понедельник', StatsStore::WD_RU[Date.parse('2026-09-28').wday]
  end

  # -- живые проверки (только в SketchUp) ------------------------------------------------

  test 'Tracker запущен и знает текущую модель' do
    skip('вне SketchUp') unless defined?(Sketchup)

    assert(Tracker.running?, 'Tracker не запущен после setup!')
    assert(Tracker.current_name, 'имя текущей модели не определено')
    payload = Tracker.ui_payload
    assert(payload['selected'], 'в payload нет выбранного проекта')
    assert(payload['projects'].is_a?(Array), 'projects не массив')
  end

  test 'Activity определяет фокус и время ввода' do
    skip('вне SketchUp') unless defined?(Sketchup)

    assert([true, false].include?(Activity.foreground?), 'foreground? не булево')
    assert(Activity.seconds_since_input.is_a?(Numeric), 'seconds_since_input не число')
    assert([true, false].include?(Activity.active?(5)), 'active? не булево')
  end
end

if __FILE__ == $PROGRAM_NAME
  r = Dn1cTimeProject2::Test.run!
  puts "[TimeProject2] тесты: #{r['passed']}/#{r['total']} пройдено, падений: #{r['failures'].size}, пропусков: #{r['skipped'].size} (#{r['duration_ms']} мс)"
  r['failures'].each { |f| puts "FAIL #{f['name']}: #{f['error']}" }
  r['skipped'].each { |s| puts "SKIP #{s['name']}: #{s['reason']}" }
  exit(1) unless r['failures'].empty?
  end
end
