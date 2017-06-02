# frozen_string_literal: true

module Starter
  class Orms
    class << self
      def build(dest, orm)
        case orm.downcase
        when 'sequel'
          require 'starter/builder/templates/sequel'
          extend(::Starter::Templates::Sequel)
        when 'activerecord', 'ar'
          require 'starter/builder/templates/activerecord'
          extend(::Starter::Templates::ActiveRecord)
          # Fixes pooling
          add_middleware(dest, 'ActiveRecord::Rack::ConnectionManagement')
        else
          return
        end

        build_initializer(File.join(dest, 'config', 'initializers'))
        build_config(File.join(dest, 'config'))
        append_to_file(File.join(dest, 'Rakefile'), rakefile)
        append_to_file(File.join(dest, 'Gemfile'), gemfile)
        prepare_for_migrations(File.join(dest, 'db'))

        Starter::Config.save(dest: dest, content: { orm: orm.downcase })
      end

      private

      def build_initializer(dest)
        FileUtils.mkdir_p(dest)
        FileFoo.write_file(File.join(dest, 'database.rb'), initializer)
      end

      def build_config(dest)
        FileFoo.write_file(File.join(dest, 'database.yml'), config)
      end

      # adds a middleware to config.ru
      def add_middleware(dest, middleware)
        replacement = "use #{middleware}\n\n\\1"
        FileFoo.call!(File.join(dest, 'config.ru')) { |content| content.sub!(/^(run.+)$/, replacement) }
      end

      def append_to_file(file_name, content)
        original = FileFoo.read_file(file_name)
        FileFoo.write_file(file_name, "#{original}\n\n#{content}")
      end

      def prepare_for_migrations(dest)
        migrations = File.join(dest, 'migrations')
        FileUtils.mkdir_p(migrations)
        `touch #{migrations}/.keep`
      end
    end
  end
end
