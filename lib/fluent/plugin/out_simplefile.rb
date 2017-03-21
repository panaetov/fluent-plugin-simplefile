# Скрипт для вывода информации в файл, используя имя, указанное
# в конфигах td-agent-а (без дополнительных суффиксов, нумераций и т.д.)

require 'fileutils'

require 'fluent/output'
require 'fluent/config/error'

module Fluent
  class FileStraightOutput < BufferedOutput
    Plugin.register_output('simplefile', self)

    desc "The Path of the file."
    config_param :path, :string

    desc "The format of the file content. The default is out_file."
    config_param :format, :string, default: 'out_file'

    def initialize
      require 'fluent/plugin/file_util'
      super
    end

    def configure(conf)
      if path = conf['path']
        @path = path
      end
      unless @path
        raise ConfigError, "'path' parameter is required on file output"
      end

      unless ::Fluent::FileUtil.writable_p?(path)
        raise ConfigError, "out_file: `#{path}` is not writable"
      end

      super

      @formatter = Plugin.new_formatter(@format)
      @formatter.configure(conf)
    end

    def format(tag, time, record)
      @formatter.format(tag, time, record)
    end

    def write(chunk)
      path = @path
      FileUtils.mkdir_p File.dirname(path), mode: DEFAULT_DIR_PERMISSION

      File.open(path, "a", DEFAULT_FILE_PERMISSION) {|f|
        chunk.write_to(f)
      }
      return path
    end

    def secondary_init(primary)
      # don't warn even if primary.class is not FileOutput
    end

  end
end
