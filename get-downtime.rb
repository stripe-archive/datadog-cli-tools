#!/usr/bin/env ruby

require_relative 'command'

class GetDowntime < Command

  def run()
    super do
      raise ArgumentError.new("You must specify an ID!") unless ARGV[0]
    end
    id = ARGV[0]

    @error_logger.info("Looking for downtime: '#{id}'")
    status, result = @dog_client.get_downtime(id)

    if status = 200
      puts(result)
    else
      @error_logger.error(result)
    end
  end
end

GetDowntime.new().run()
