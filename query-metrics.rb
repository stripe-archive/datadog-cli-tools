#!/usr/bin/env ruby

require 'chronic'
require 'date'
require_relative 'command'

class QueryMetrics < Command

  def parse_args(options, parser)
    options[:from] = Chronic.parse('30 minutes ago')
    options[:to] = Chronic.parse('now')

    parser.on('-f', '--from', 'From date, which can be anything Chronic can parse (https://github.com/mojombo/chronic). Defaults to 30m ago') do |f|
      options[:from] = Chronic.parse(f)
    end

    parser.on('-t', '--to', 'To date, which can be anything Chronic can parse (https://github.com/mojombo/chronic). Defaults to now') do |t|
      options[:to] = Chronic.parse(f)
    end

    parser.on('-j', '--json', 'Output JSON instead of text') do |j|
      options[:json] = j
    end
  end

  def run()
    @args.length > 0 || raise("You must specify a query!")
    query = @args[0]
    resp = @dog_client.get_points(query, @options[:from].to_time.to_i, @options[:to].to_time.to_i)[1]
    if @options[:json]
      puts(resp.to_json)
    else
      for s in resp['series']
        puts(s['metric'])
        for p in s['pointlist']
          puts("\t#{Time.at(p[0].to_i / 1000).to_datetime}, #{p[1]}")
        end
      end
    end
  end
end

QueryMetrics.new().run()
