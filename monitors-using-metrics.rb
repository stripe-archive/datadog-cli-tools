#!/usr/bin/env ruby

require_relative 'command'

class MonitorsUsingMetrics < Command
  def parse_args(options, parser)
    options[:is_regex] = false

    parser.on('-r', '--[no-]regex', 'Input is a regular expression (don\'t quote)') do |v|
      options[:is_regex] = v
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
    _, monitors = @dog_client.get_all_monitors()

    monitors.each do |monitor|
      next unless monitor['query'] =~ regex
      url = template('monitor', id: monitor['id'])

      @logger.info "Found: #{monitor['name']} - #{url}"
      @logger.debug "  #{monitor['query']}"
    end
  end

  def run()
    metric = @args[0] || raise("You must specify a metric name!")

    print_monitor_matches(metric)
  end
end

MonitorsUsingMetrics.new().run()
