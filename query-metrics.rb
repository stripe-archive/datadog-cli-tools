#!/usr/bin/env ruby

require 'chronic'
require 'date'
require_relative 'command'

class QueryMetrics < Command

  def parse_args(options, parser)
    parser.banner = "Usage: #{$0} [options] <query>\n"+
                    "Example: #{$0} 'avg:system.load.1{*}'"

    options[:from] = Chronic.parse('30 minutes ago')
    options[:to] = Chronic.parse('now')

    parser.on('-f SPEC', '--from SPEC', 'From date, which can be anything Chronic can parse (https://github.com/mojombo/chronic). Defaults to 30m ago') do |f|
      parsed = Chronic.parse(f)
      raise ArgumentError.new("Invalid time specification: '#{f}'") if parsed.nil?
      options[:from] = parsed
    end

    parser.on('-t SPEC', '--to SPEC', 'To date, which can be anything Chronic can parse (https://github.com/mojombo/chronic). Defaults to now') do |t|
      parsed = Chronic.parse(f)
      raise ArgumentError.new("Invalid time specification: '#{f}'") if parsed.nil?
      options[:to] = parsed
    end

    parser.on('-j', '--json', 'Output JSON instead of text') do |j|
      options[:json] = j
    end
  end

  def run()
    super do
      raise ArgumentError.new("You must specify a query!") unless @args.length > 0
    end

    query = @args[0]
    resp = @dog_client.get_points(query, @options[:from].to_time.to_i, @options[:to].to_time.to_i)[1]
    series = resp.fetch('series', [])

    # unfortunately, ruby's logger doesn't switch between stderr/stdout depending on severity,
    # and for the other commands it writes to stdout, so we can't use it for this warning
    @error_logger.warn("No results for query") if series.empty?

    if @options[:json]
      puts(resp.to_json)
    else
      for s in series
        puts(s['metric'])
        for p in s['pointlist']
          puts("\t#{Time.at(p[0].to_i / 1000).to_datetime}, #{p[1]}")
        end
      end
    end
  end
end

QueryMetrics.new().run()
