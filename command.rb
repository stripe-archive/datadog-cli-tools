require 'dogapi'
require 'json'
require 'optparse'
require 'yaml'
require 'logger'

class ArgumentError < StandardError
end

class Command
  def initialize()
    begin
      @options, @args = _parse_args(ARGV)

      config = YAML.load_file(@options[:config_file])

      @api_key = config['api_key']
      @app_key = config['app_key']

      @templates = config.fetch('templates', {})

      @dog_client = Dogapi::Client.new(@api_key, @app_key)

      @logger = Logger.new(STDOUT)
      @logger.formatter = method(:format_log)
      @logger.level = @options[:log_level]
    rescue StandardError => e
      STDERR.puts("Error loading YAML file `~/.datadog.yaml`: #{e.message}")
      exit(-1)
    end
  end

  def _parse_args(_argv)
    argv = _argv.dup
    options = {
      use_color: STDOUT.isatty,
      log_level: Logger::INFO,
      config_file: File.join(Dir.home, '/.datadog.yaml')
    }

    parser = OptionParser.new do |parser|
      @parser = parser

      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:log_level] = Logger::DEBUG if v
      end

      parser.on("-c", "--[no-]color", "Colorize output") do |v|
        options[:use_color] = v
      end

      parser.on("--config [file]", "Specify config file") do |v|
        options[:config_file] = v
      end

      # allow extension by subclasses
      if self.respond_to?(:parse_args)
        self.send(:parse_args, options, parser)
      end
    end.parse!(argv)

    [options, argv]
  end

  def format_log(severity, timestamp, progname, msg)
    prefix = '?'
    color = '0'
    time = timestamp.strftime('%H:%M:%S')

    case severity
    when 'DEBUG'
      prefix = 'D'
      color = '36'
    when 'INFO'
      prefix = 'I'
      color = '1;36'
    when 'WARN'
      prefix = 'W'
      color = '1;33'
    when 'ERROR'
      prefix = 'E'
      color = '1;31'
    when 'FATAL'
      prefix = 'F'
      color = '1;37;41'
    else # when 'UNKNOWN'
      prefix = '?'
      color = '1;30'
    end

    if @options[:use_color]
      "\e[#{color}m#{prefix}, [#{time}] : #{msg}\e[0m\n"
    else
      "#{prefix}, [#{time}] : #{msg}\n"
    end
  end

  def template(type, *context)
    @templates.fetch(type, '%{id}') % context
  end

  def run
    puts("Implement me!")
  end
end
