# frozen_string_literal: true
# =============================================================================
# tools/make_icons.rb — генерация иконки секундомера тулбара:
#   • векторный SVG: icons/timer.svg (для современных версий SketchUp);
#   • растровые PNG: icons/timer_16.png, timer_24.png (фолбэк)
#   (рендеринг чистым Ruby с 4x суперсэмплингом и антиалиасингом).
# =============================================================================

require 'zlib'
require 'fileutils'

SVG_CONTENT = <<~SVG
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
    <defs>
      <linearGradient id="timBlue" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#36abf7"/><stop offset="100%" stop-color="#006fb8"/></linearGradient>
    </defs>
    <rect x="10.6" y="1.2" width="2.8" height="2" rx=".8" fill="#015995"/>
    <rect x="11.6" y="3" width=".8" height="1.8" fill="#015995"/>
    <circle cx="12" cy="13.5" r="8" fill="url(#timBlue)"/>
    <circle cx="12" cy="13.5" r="5.6" fill="#ffffff"/>
    <path d="M12 8.6v1M16.9 13.5h-1M12 18.4v-1M7.1 13.5h1" stroke="#94a3b8" stroke-width="1" stroke-linecap="round"/>
    <path d="M12 13.5V9.9" stroke="#015995" stroke-width="1.4" stroke-linecap="round"/>
    <path d="M12 13.5l2.4 1.6" stroke="#015995" stroke-width="1.4" stroke-linecap="round"/>
    <circle cx="12" cy="13.5" r="1.1" fill="#16a34a"/>
  </svg>
SVG

# -- PNG сборщик -------------------------------------------------------------

def png_chunk(type, data)
  [data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
end

def write_png(path, pixels, width, height)
  raw = pixels.map { |row| "\x00" + row.map { |px| px.pack('C4') }.join }.join
  png = "\x89PNG\r\n\x1a\n".b +
        png_chunk('IHDR', [width, height, 8, 6, 0, 0, 0].pack('N5')) +
        png_chunk('IDAT', Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION)) +
        png_chunk('IEND', '')
  File.binwrite(path, png)
  puts "  ✓ #{File.basename(path)} (#{width}x#{height})"
end

# -- Канва с альфа-блендингом -------------------------------------------------

class ImageBuffer
  attr_reader :w, :h, :pixels

  def initialize(w, h)
    @w = w
    @h = h
    @pixels = Array.new(h) { Array.new(w) { [0, 0, 0, 0] } }
  end

  def blend_pixel(x, y, r, g, b, a)
    return if x < 0 || x >= @w || y < 0 || y >= @h || a <= 0

    cur = @pixels[y][x]
    sa = a / 255.0
    da = cur[3] / 255.0
    out_a = sa + da * (1.0 - sa)
    return if out_a.zero?

    out_r = ((r * sa + cur[0] * da * (1.0 - sa)) / out_a).round.clamp(0, 255)
    out_g = ((g * sa + cur[1] * da * (1.0 - sa)) / out_a).round.clamp(0, 255)
    out_b = ((b * sa + cur[2] * da * (1.0 - sa)) / out_a).round.clamp(0, 255)
    @pixels[y][x] = [out_r, out_g, out_b, (out_a * 255).round.clamp(0, 255)]
  end

  # Сглаженный спуск (4x бокс-фильтр) в результирующий буфер
  def downsample(scale = 4)
    target_w = @w / scale
    target_h = @h / scale
    out = Array.new(target_h) { Array.new(target_w) { [0, 0, 0, 0] } }

    target_h.times do |ty|
      target_w.times do |tx|
        sum_r = 0.0
        sum_g = 0.0
        sum_b = 0.0
        sum_a = 0.0

        scale.times do |sy|
          scale.times do |sx|
            px = @pixels[ty * scale + sy][tx * scale + sx]
            a = px[3] / 255.0
            sum_r += px[0] * a
            sum_g += px[1] * a
            sum_b += px[2] * a
            sum_a += a
          end
        end

        count = (scale * scale).to_f
        avg_a = sum_a / count
        if avg_a > 0.001
          avg_r = (sum_r / sum_a).round.clamp(0, 255)
          avg_g = (sum_g / sum_a).round.clamp(0, 255)
          avg_b = (sum_b / sum_a).round.clamp(0, 255)
          out[ty][tx] = [avg_r, avg_g, avg_b, (avg_a * 255).round.clamp(0, 255)]
        end
      end
    end
    out
  end
end

# Расстояние от точки (px, py) до отрезка (x1, y1)-(x2, y2), с круглыми
# колпачками (расстояние до отрезка уже учитывает колпачки).
def seg_dist(px, py, x1, y1, x2, y2)
  dx = x2 - x1
  dy = y2 - y1
  len_sq = dx * dx + dy * dy
  t = len_sq.zero? ? 0.0 : (((px - x1) * dx + (py - y1) * dy) / len_sq).clamp(0.0, 1.0)
  cx = x1 + dx * t
  cy = y1 + dy * t
  Math.sqrt((px - cx)**2 + (py - cy)**2)
end

# -- Рендеринг иконки высокого разрешения (на сетке 24 x 24) ------------------

def render_icon(target_size)
  scale = 4
  hires = target_size * scale
  buf = ImageBuffer.new(hires, hires)
  s = hires / 24.0

  cx = 12.0
  cy = 13.5

  hires.times do |y|
    ny = (y + 0.5) / s
    hires.times do |x|
      nx = (x + 0.5) / s

      # 1. Кнопка сверху: скруглённый прямоугольник x: 10.6..13.4, y: 1.2..3.2 (r = 0.8)
      in_btn = nx >= 10.6 && nx <= 13.4 && ny >= 1.2 && ny <= 3.2
      if in_btn
        # Скругление углов радиусом 0.8
        r = 0.8
        ok = true
        ok &&= ((nx - (10.6 + r))**2 + (ny - (1.2 + r))**2 <= r * r) if nx < 10.6 + r && ny < 1.2 + r
        ok &&= ((nx - (13.4 - r))**2 + (ny - (1.2 + r))**2 <= r * r) if nx > 13.4 - r && ny < 1.2 + r
        ok &&= ((nx - (10.6 + r))**2 + (ny - (3.2 - r))**2 <= r * r) if nx < 10.6 + r && ny > 3.2 - r
        ok &&= ((nx - (13.4 - r))**2 + (ny - (3.2 - r))**2 <= r * r) if nx > 13.4 - r && ny > 3.2 - r
        buf.blend_pixel(x, y, 1, 89, 149, 255) if ok # #015995
        next
      end

      # 2. Ножка кнопки: x: 11.6..12.4, y: 3.0..4.8
      if nx >= 11.6 && nx <= 12.4 && ny >= 3.0 && ny <= 4.8
        buf.blend_pixel(x, y, 1, 89, 149, 255) # #015995
        next
      end

      # 3. Корпус секундомера: круг r = 8, градиент #36abf7 -> #006fb8
      d_body = Math.sqrt((nx - cx)**2 + (ny - cy)**2)
      next if d_body > 8.0

      t = ((ny - (cy - 8.0)) / 16.0).clamp(0.0, 1.0)
      r = (54 * (1 - t) + 0 * t).round
      g = (171 * (1 - t) + 111 * t).round
      b = (247 * (1 - t) + 184 * t).round
      buf.blend_pixel(x, y, r, g, b, 255)

      # 4. Белый циферблат r = 5.6
      if d_body <= 5.6
        buf.blend_pixel(x, y, 255, 255, 255, 255)
      end

      # 5. Tick-метки (ширина 1, цвет #94a3b8): верх/право/низ/лево
      on_tick = seg_dist(nx, ny, 12.0, 8.6, 12.0, 9.6) <= 0.5 ||
                seg_dist(nx, ny, 16.9, 13.5, 15.9, 13.5) <= 0.5 ||
                seg_dist(nx, ny, 12.0, 18.4, 12.0, 17.4) <= 0.5 ||
                seg_dist(nx, ny, 7.1, 13.5, 8.1, 13.5) <= 0.5
      buf.blend_pixel(x, y, 148, 163, 184, 255) if on_tick

      # 6. Стрелки (ширина 1.4, цвет #015995): минутная вверх, часовая вправо-вниз
      on_hand = seg_dist(nx, ny, 12.0, 13.5, 12.0, 9.9) <= 0.7 ||
                seg_dist(nx, ny, 12.0, 13.5, 14.4, 15.1) <= 0.7
      buf.blend_pixel(x, y, 1, 89, 149, 255) if on_hand

      # 7. Зелёная центральная точка r = 1.1 (#16a34a) — поверх стрелок
      if Math.sqrt((nx - cx)**2 + (ny - cy)**2) <= 1.1
        buf.blend_pixel(x, y, 22, 163, 74, 255)
      end
    end
  end

  buf.downsample(scale)
end

# -- Генерация файлов в папке icons ------------------------------------------

dest_dirs = [
  File.join(__dir__, '..', 'dn1sup_time_project', 'dn1sup_time_project', 'icons')
]

dest_dirs.each do |out|
  FileUtils.mkdir_p(out)
  puts "Генерация иконок в #{out}:"

  # 1. SVG вектор (канон)
  svg_path = File.join(out, 'timer.svg')
  File.write(svg_path, SVG_CONTENT, encoding: 'UTF-8')
  puts '  ✓ timer.svg (Vector)'

  # 2. PNG размеры (фолбэк для старых SketchUp)
  [16, 24].each do |size|
    px = render_icon(size)
    write_png(File.join(out, "timer_#{size}.png"), px, size, size)
  end
end

puts "\nГотово! Все иконки успешно созданы."
