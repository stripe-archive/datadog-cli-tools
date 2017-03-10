#!/usr/bin/env ruby

require_relative 'command'

class DashboardsUsingMetrics < Command
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

  def find_dashboard_graphs(definition, regex)
    definition.fetch('dash', {}).fetch('graphs', []).reduce([]) do |acc, graph|
      queries = graph.fetch('definition', {}).fetch('requests', []).reduce([]) do |acc2, request|
        next acc2 unless request.key?('q') || !request['q'].respond_to?(:to_str)
        next acc2 unless request['q'] =~ regex

        acc2 + [request['q']]
      end

      next acc unless queries.length > 0
      puts(acc)
      puts(queries)

      acc + [{
        title: graph.fetch('title', 'Unknown'),
        queries: queries
      }]
    end
  end

  def find_screenboard_graphs(definition, regex)
    definition.fetch('widgets', []).reduce([]) do |acc, widget|
      queries = widget.fetch('tile_def', {}).fetch('requests', []).reduce([]) do |acc2, request|
        next acc2 unless request.key?('q') || !request['q'].respond_to?(:to_str)
        next acc2 unless request['q'] =~ regex

        acc2 + [request['q']]
      end

      next acc unless queries.length > 0

      puts(acc)
      puts(queries)

      acc + [{
        title: widget.fetch('title_text', 'Unknown'),
        queries: queries
      }]
    end
  end

  def print_dashboard_matches(metric)
    regex = metric_regex(metric)
    @logger.info("Looking for dashboards using metric: #{regex.inspect}")
    _, dashes = @dog_client.get_dashboards()
    dashes['dashes'].each do |dash|
      status_code, definition = @dog_client.get_dashboard(dash['id'])

      if status_code != '200'
        @logger.warn("Got status code #{status_code} querying dashboard #{dash['id']}")
        next
      end

      found = find_dashboard_graphs(definition, regex)

      if found.length > 0
        url = template('dashboard', id: dash['id'])

        @logger.info "Found: #{dash['title']} - #{url}"
        found.each do |graph|
          @logger.debug "  #{graph[:title]}"
          graph[:queries].each do |query|
            @logger.debug "    #{query}"
          end
        end

        @logger.debug ""
      end
    end
  end

  def print_screenboard_matches(metric)
    regex = metric_regex(metric)
    @logger.info("Looking for screenboards using metric: #{regex.inspect}")
    _, screens = @dog_client.get_all_screenboards()

    screens['screenboards'].each do |screen|
      status_code, definition = @dog_client.get_screenboard(screen['id'])

      if status_code != '200'
        @logger.warn("Got status code #{status_code} querying dashboard #{dash['id']}")
        next
      end

      found = find_screenboard_graphs(definition, regex)

      if found.length > 0
        url = template('screenboard', id: screen['id'])

        @logger.info "Found: #{screen['title']} - #{url}"
        found.each do |graph|
          @logger.debug "  #{graph[:title]}"
          graph[:queries].each do |query|
            @logger.debug "    #{query}"
          end
        end

        @logger.debug ""
      end
    end
  end

  def run()
    raise ArgumentError.new("You must specify a metric name!") unless @args.length > 0
    metric = @args[0]

    print_dashboard_matches(metric)
    print_screenboard_matches(metric)
  rescue ArgumentError => e
    puts @parser
    puts e.to_s
  end
end

DashboardsUsingMetrics.new().run()
