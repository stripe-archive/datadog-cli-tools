#!/usr/bin/env ruby

require_relative 'command'

class DashboardsUsingMetrics < Command

  def run()
    metric = ARGV[0] || raise("You must specify a metric name!")

    @logger.info("Looking for dashboards using metric: '#{metric}'")
    _, dashes = @dog_client.get_dashboards()
    dashes['dashes'].each do |dash|
      definition = @dog_client.get_dashboard(dash['id']).to_json
      if definition =~ /#{Regexp.quote(metric)}/
        puts(dash['id'])
      end
    end

    @logger.info("Looking for screenboards using metric: '#{metric}'")
    _, screens = @dog_client.get_all_screenboards()
    screens['screenboards'].each do |screen|
      definition = @dog_client.get_screenboard(screen['id']).to_json
      if definition =~ /#{Regexp.quote(metric)}/
        puts(screen['id'])
      end
    end
  end
end

DashboardsUsingMetrics.new().run()
