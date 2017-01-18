require 'dogapi'
require 'json'
require 'optparse'
require 'yaml'
require 'logger'

class Command
  def initialize()
    begin
      config = YAML.load_file(ENV['HOME'] + '/.datadog.yaml')
      @api_key = config['api_key']
      @app_key = config['app_key']
      @dog_client = Dogapi::Client.new(@api_key, @app_key)
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    rescue StandardError => e
      STDERR.puts("Error loading YAML file `~/.datadog.yaml`: #{e.message}")
      exit(-1)
    end
  end

  def run
    puts("Implement me!")
  end
end
