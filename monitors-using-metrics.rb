#!/usr/bin/env ruby

require_relative 'command'

class MonitorsUsingMetrics < Command

  def run()
    metric = ARGV[0] || raise("You must specify a metric name!")
    @logger.info("Looking for monitors using metric: '#{metric}'")
    result = @dog_client.get_all_monitors()

    monitors = result[1]
    monitors.each do |monitor|
      if monitor['query'] =~ /#{Regexp.quote(metric)}/
        puts("#{monitor['id']}")
      end
    end
  end
end

MonitorsUsingMetrics.new().run()
