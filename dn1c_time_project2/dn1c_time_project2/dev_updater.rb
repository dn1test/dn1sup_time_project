# frozen_string_literal: true
# =============================================================================
# dn1c_time_project2/dev_updater.rb — сервис обновления расширения из каталога
# разработки (dev-папки) в системную директорию Plugins SketchUp с поддержкой
# горячей перезагрузки (Hot Reload).
# =============================================================================

require 'fileutils'

module Dn1cTimeProject2
  module DevUpdater
    extend self

    DEFAULT_DEV_DIR = 'U:/dn1code/su_plugs_app/dn1c_time_project2/dn1c_time_project2'

    EXCLUDE_PATTERNS = [
      /\A\.git/,
      /\A\.zcode/,
      /\A\.tmp/,
      /\Atest/,
      /\Adist/,
      /\Ascratch/,
      /\AGemfile/,
      /\.bak\z/i,
      /\.tmp\z/i,
      /\.rbz\z/i
    ].freeze

    # Определяет путь к папке разработки (dev_dir)
    def resolve_dev_dir(custom_path = nil)
      plug_root = defined?(PLUG_ROOT) ? PLUG_ROOT : File.dirname(__FILE__)
      candidates = [
        custom_path,
        ENV['DN1C_TIME_PROJECT2_DEV_DIR'],
        ENV['DN1C_DEV_DIR'],
        DEFAULT_DEV_DIR,
        'U:/dn1code/su_plugs_app/dn1c_time_project2/dn1c_time_project2',
        'U:/dn1code/su_plugs_app/dn1c_time_project2',
        File.expand_path('..', plug_root),
        File.expand_path('../..', plug_root)
      ].compact.map { |p| p.to_s.tr('\\', '/').sub(%r{/+\z}, '') }

      candidates.each do |candidate|
        next if candidate.empty?

        # Прямое совпадение: папка содержит dn1c_time_project2.rb и dn1c_time_project2/
        if File.exist?(File.join(candidate, 'dn1c_time_project2.rb')) &&
           File.directory?(File.join(candidate, 'dn1c_time_project2'))
          return candidate
        end

        # Корень репозитория: подпапка dn1c_time_project2/ содержит loader и код
        sub = File.join(candidate, 'dn1c_time_project2')
        if File.exist?(File.join(sub, 'dn1c_time_project2.rb')) &&
           File.directory?(File.join(sub, 'dn1c_time_project2'))
          return sub
        end
      end

      nil
    end

    # Определяет целевой каталог Plugins SketchUp
    def resolve_plugins_dir(custom_plugins_dir = nil)
      if custom_plugins_dir && Dir.exist?(custom_plugins_dir)
        return custom_plugins_dir.tr('\\', '/')
      end

      if defined?(Sketchup) && Sketchup.respond_to?(:find_support_file)
        su_plugins = Sketchup.find_support_file('Plugins')
        return su_plugins.tr('\\', '/') if su_plugins && Dir.exist?(su_plugins)
      end

      appdata = ENV['APPDATA'] || "C:/Users/#{ENV['USERNAME']}/AppData/Roaming"
      su_ver = defined?(Sketchup) && Sketchup.respond_to?(:version) ? Sketchup.version.to_i : 2026
      su_ver = 2026 if su_ver.zero?

      default_path = File.join(appdata, 'SketchUp', "SketchUp #{su_ver}", 'SketchUp', 'Plugins').tr('\\', '/')
      FileUtils.mkdir_p(default_path) unless Dir.exist?(default_path)
      default_path
    end

    # Безопасное копирование файла
    def safe_copy(src, dst, warnings, rel_label)
      return :identical if File.exist?(dst) && FileUtils.identical?(src, dst)

      FileUtils.mkdir_p(File.dirname(dst))
      FileUtils.cp(src, dst)
      :copied
    rescue Errno::EACCES, Errno::EBUSY, Errno::EPERM
      warnings << "#{rel_label}: файл занят другим процессом, пропущен"
      :skipped
    end

    # Копирует файлы плагина из dev-папки в каталог Plugins
    def update!(dev_dir = nil, plugins_dir = nil)
      src_dir = resolve_dev_dir(dev_dir)
      unless src_dir && Dir.exist?(src_dir)
        return {
          success: false,
          error: "Каталог разработки не найден. Проверено: #{dev_dir || DEFAULT_DEV_DIR}"
        }
      end

      dst_plugins = resolve_plugins_dir(plugins_dir)
      unless dst_plugins && Dir.exist?(dst_plugins)
        return {
          success: false,
          error: "Каталог Plugins SketchUp не найден: #{dst_plugins}"
        }
      end

      src_clean = File.expand_path(src_dir).tr('\\', '/').downcase
      dst_ext = File.expand_path(File.join(dst_plugins, 'dn1c_time_project2')).tr('\\', '/').downcase
      if src_clean == dst_ext || src_clean == File.expand_path(dst_plugins).tr('\\', '/').downcase
        return {
          success: true,
          same_dir: true,
          dev_dir: src_dir,
          plugins_dir: dst_plugins,
          files_copied: 0,
          version: (defined?(VERSION) ? VERSION : 'unknown'),
          message: 'Плагин уже работает напрямую из каталога разработки'
        }
      end

      files_copied = 0
      warnings = []

      # 1. Загрузчик dn1c_time_project2.rb в корень Plugins
      root_loader = File.join(src_dir, 'dn1c_time_project2.rb')
      if File.exist?(root_loader)
        target_loader = File.join(dst_plugins, 'dn1c_time_project2.rb')
        copied = safe_copy(root_loader, target_loader, warnings, 'dn1c_time_project2.rb')
        files_copied += 1 if copied == :copied
      end

      # 2. Пакетная директория dn1c_time_project2/
      src_pkg = File.join(src_dir, 'dn1c_time_project2')
      dst_pkg = File.join(dst_plugins, 'dn1c_time_project2')
      FileUtils.mkdir_p(dst_pkg)

      Dir.glob(File.join(src_pkg, '**', '*'), File::FNM_DOTMATCH).each do |entry|
        rel = entry.sub("#{src_pkg}/", '').tr('\\', '/')
        next if rel == '.' || rel == '..'
        next if EXCLUDE_PATTERNS.any? { |pat| rel =~ pat }

        dest_entry = File.join(dst_pkg, rel)
        if File.directory?(entry)
          FileUtils.mkdir_p(dest_entry)
        else
          copied = safe_copy(entry, dest_entry, warnings, rel)
          files_copied += 1 if copied == :copied
        end
      end

      {
        success: true,
        same_dir: false,
        dev_dir: src_dir,
        plugins_dir: dst_plugins,
        files_copied: files_copied,
        warnings: warnings,
        version: (defined?(VERSION) ? VERSION : 'unknown'),
        updated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }
    rescue StandardError => e
      {
        success: false,
        error: "#{e.class}: #{e.message}"
      }
    end

    # Перезагружает плагин в памяти SketchUp
    def reload!(plugins_dir = nil)
      target_plugins = resolve_plugins_dir(plugins_dir)

      # 1. Выгружаем текущие ресурсы
      if defined?(Dn1cTimeProject2) && Dn1cTimeProject2.respond_to?(:unload!)
        begin
          Dn1cTimeProject2.unload!
        rescue StandardError => e
          puts "[TimeProject2] Предупреждение при unload!: #{e.message}"
        end
      end

      # 2. Очищаем $LOADED_FEATURES
      purged = 0
      if defined?($LOADED_FEATURES)
        $LOADED_FEATURES.reject! do |path|
          match = path.include?('dn1c_time_project2')
          purged += 1 if match
          match
        end
      end

      # 3. Удаляем константу модуля для полной переинициализации
      if Object.const_defined?(:Dn1cTimeProject2)
        Object.send(:remove_const, :Dn1cTimeProject2)
      end

      # 4. Загружаем свежие файлы
      loader = File.join(target_plugins, 'dn1c_time_project2.rb')
      main_rb = File.join(target_plugins, 'dn1c_time_project2', 'main.rb')

      load loader if File.exist?(loader)
      load main_rb if File.exist?(main_rb)

      ver = defined?(Dn1cTimeProject2::VERSION) ? Dn1cTimeProject2::VERSION : 'unknown'

      {
        success: true,
        purged_features: purged,
        reloaded_at: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        version: ver
      }
    rescue StandardError => e
      {
        success: false,
        error: "#{e.class}: #{e.message}"
      }
    end

    # Обновляет из dev-папки и сразу перезагружает
    def update_and_reload!(dev_dir: nil, plugins_dir: nil, reopen_dialog: false, notify: false)
      res = update!(dev_dir, plugins_dir)
      unless res[:success]
        if notify && defined?(UI)
          UI.messagebox("❌ Ошибка обновления из dev-папки:\n#{res[:error]}")
        end
        return res
      end

      reload_res = reload!(plugins_dir)
      res = res.merge(reload_res)

      if reopen_dialog && defined?(Dn1cTimeProject2) && Dn1cTimeProject2.respond_to?(:show_dialog)
        Dn1cTimeProject2.show_dialog
      end

      if notify && defined?(UI)
        msg = "✅ DN1C Time Project 2 (v#{res[:version]}) успешно обновлен из dev-папки!\n\n" \
              "Откуда: #{res[:dev_dir]}\n" \
              "Куда: #{res[:plugins_dir]}\n" \
              "Скопировано файлов: #{res[:files_copied]}"
        if res[:warnings] && !res[:warnings].empty?
          msg += "\n\n⚠️ Предупреждения:\n#{res[:warnings].join("\n")}"
        end
        UI.messagebox(msg)
      end

      res
    end
  end
end
