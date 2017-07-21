require 'dogapi'
require 'json'
require 'optparse'
require 'yaml'
require 'logger'

class ArgumentError < StandardError; end
class ConfigError < StandardError; end

class Command
  DEFAULT_OPTIONS = {
    use_color: STDOUT.isatty,
    log_level: Logger::INFO,
    config_file: File.join(Dir.home, '/.datadog.yaml')
  }.freeze

  def initialize()
    @options = DEFAULT_OPTIONS.dup
    reconfigure(false)
  end

  private

  def _parse_args(_argv)
    argv = _argv.dup
    options = {}

    parser = OptionParser.new do |parser|
      @parser = parser

      parser.banner = "Usage: #{$0} [options]"

      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:log_level] = Logger::DEBUG if v
      end

      parser.on("-c", "--[no-]color", "Colorize output") do |v|
        options[:use_color] = v
      end

      parser.on("--config FILE", "Specify config file") do |v|
        options[:config_file] = v
      end

      # allow extension by subclasses
      if self.respond_to?(:parse_args)
        self.send(:parse_args, options, parser)
      end
    end.parse!(argv)

    [@options.merge(options), argv]
  rescue OptionParser::MissingArgument => e
    raise ArgumentError.new("Switch(es) require an argument: #{e.args.join(', ')}")
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

  def load_config(file, fatal)
    config = YAML.load_file(@options[:config_file])
    raise ConfigError.new("Invalid config file") unless config.respond_to?(:fetch)

    @api_key = config.fetch('api_key', nil)
    @app_key = config.fetch('app_key', nil)

    @templates = config.fetch('templates', {})

    @dog_client = Dogapi::Client.new(@api_key, @app_key)

    raise ConfigError.new("Missing api or app key") if @api_key.nil? || @app_key.nil?
  rescue StandardError => e
    raise e, "Unable to load config from #{@options[:config_file]}: #{e.message}" if fatal
  end

  def reconfigure(fatal=true)
    @logger = Logger.new(STDOUT)
    @logger.level = @options[:log_level]
    @logger.formatter = method(:format_log)

    @error_logger = Logger.new(STDERR)
    @error_logger.level = @options[:log_level]
    @error_logger.formatter = method(:format_log)

    @api_key = nil
    @app_key = nil
    @templates = {}
    @dog_client = nil

    load_config(@options[:config_file], fatal)
  end

  def run
    @options, @args = _parse_args(ARGV)
    yield if block_given?
    reconfigure(true)
  rescue ArgumentError, ConfigError => e
    puts @parser
    @error_logger.error(e.to_s)
    exit(1)
  rescue StandardError => e
    @error_logger.error(e.to_s)
    e.backtrace.each do |line|
      @error_logger.error(line)
    end

    exit(1)
  end
end
