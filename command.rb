require 'dogapi'
require 'json'
require 'optparse'
require 'yaml'
require 'logger'

class ArgumentError < StandardError; end
class RetryError < StandardError; end

class Command
  DEFAULT_DELAY = 0.5
  DEFAULT_RETRIES = 2

  def initialize()
    begin
      @options, @args = _parse_args(ARGV)

      config = YAML.load_file(@options[:config_file])

      @api_key = config['api_key']
      @app_key = config['app_key']

      @templates = config.fetch('templates', {})

      @dog_client = Dogapi::Client.new(@api_key, @app_key)

      @status_printed = false

      @logger = Logger.new(STDOUT)
      @logger.formatter = method(:format_log)
      @logger.level = @options[:log_level]
    rescue StandardError => e
      STDERR.puts("Error loading YAML file `~/.datadog.yaml`: #{e.message}")
      exit(-1)
    end
  end

  def status(msg)
    @last_status = msg
    str = format_msg('DEBUG', Time.now, nil, msg)

    if @options[:use_color]
      str = "\e[F#{str}\e[K" if @status_printed
    else
      str = "\r#{str}" if @status_printed
    end

    @status_printed = true

    puts(str)
  end

  def keeping_status
    yield
    status(@last_status) if defined?(@last_status)
  end

  def _parse_args(_argv)
    argv = _argv.dup
    options = {
      use_color: STDOUT.isatty,
      log_level: Logger::INFO,
      config_file: File.join(Dir.home, '/.datadog.yaml'),
      delay: DEFAULT_DELAY,
      retries: DEFAULT_RETRIES
    }

    parser = OptionParser.new do |parser|
      @parser = parser

      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:log_level] = Logger::DEBUG if v
      end

      parser.on("-c", "--[no-]color", "Colorize output") do |v|
        options[:use_color] = v
      end

      parser.on(
        "-d [secs]",
        "--delay [secs]",
        Float,
        "Delay between requests (default: #{DEFAULT_DELAY}"
      ) do |v|
        options[:delay] = v
      end

      parser.on(
        "-r [num]",
        "--retries [num]",
        Integer,
        "Number of retry attempts (default: #{DEFAULT_RETRIES}"
      ) do |v|
        options[:retries] = v
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

  def format_msg(severity, timestamp, progname, msg)
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

    str = ''

    if @options[:use_color]
      str += "\e[#{color}m#{prefix}, [#{time}] : #{msg}\e[0m"
    else
      str += "#{prefix}, [#{time}] : #{msg}"
    end

    str
  end


  def format_log(severity, timestamp, progname, msg)
    str = format_msg(severity, timestamp, progname, msg)

    if @options[:use_color]
      str = "\e[F#{str}\e[K" if @status_printed
    else
      str = "\n#{str}" if @status_printed
    end

    @status_printed = false

    str += "\n"

    str
  end

  def symbolize_keys!(hash)
    hash.keys.each do |key|
      hash[(key.to_sym rescue key) || key] = hash[key]
    end
  end

  def each_with_status_and_delay(things, template: '%{id}...', &blk)
    things.each_with_index do |thing, idx|
      symbolize_keys!(thing)
      str = "#{idx+1}/#{things.length}: "
      str += (template % thing)
      status(str)
      blk.call(thing)
    end
  end

  def with_retries
    retries = @options[:retries]
    status_code = nil
    tries = 0
    begin
      sleep(@options[:delay] + tries)
      tries += 1
      status_code, definition = yield
      raise RetryError.new("Got status_code #{status_code}") if status_code != '200'
      return [status_code, definition]
    rescue RetryError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
           Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e

      if tries > retries
        @logger.error("Failed (out of retries)")
        return [status_code || -1, nil]
      end

      keeping_status do
        @logger.warn("Received error: (#{e.class}) #{e.message}, retrying (#{tries}/#{retries})...")
      end

      retry
    end
  end

  def template(type, *context)
    @templates.fetch(type, '%{id}') % context
  end

  def run
    puts("Implement me!")
  end
end
