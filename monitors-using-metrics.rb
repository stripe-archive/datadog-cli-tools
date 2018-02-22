#!/usr/bin/env ruby

require_relative 'command'

class MonitorsUsingMetrics < Command
  def parse_args(options, parser)
    parser.banner = "Usage: #{$0} [options] <metric>\n"+
                    "Example: #{$0} 'system.load.1'"

    options[:is_regex] = false
    options[:file] = nil

    parser.on('-r', '--[no-]regex', 'Input is a regular expression (don\'t quote)') do |v|
      options[:is_regex] = v
    end

    parser.on('-fFILE', '--file=FILE', String, 'File to store queries') do |v|
      options[:file] = File.new(v, 'a')
    end
  end

  def metric_regex(metric)
    if @options[:is_regex]
      /#{metric}/
    else
      /#{Regexp.quote(metric)}/
    end
  end

  def print_monitor_matches(metric)
    regex = metric_regex(metric)
    @logger.info("Looking for monitors using metric: #{regex.inspect}")
    _, monitors = with_retries { @dog_client.get_all_monitors() }

    each_with_status_and_delay(
      monitors,
      template: '%{name} (#%{id})...',
    ) do |monitor|
      next unless monitor['query'] =~ regex
      url = template('monitor', id: monitor['id'])

      @logger.info "Found: #{monitor['name']} - #{url}"
      @logger.debug "  #{monitor['query']}"
      if @options[:file]
        @options[:file].puts(monitor['query'])
        @options[:file].flush
      end
    end
  end

  def run()
    super do
      raise ArgumentError.new("You must specify a metric name!") unless @args.length > 0
    end

    metric = @args[0]

    print_monitor_matches(metric)
  end
end

MonitorsUsingMetrics.new().run()
