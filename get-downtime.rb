#!/usr/bin/env ruby

require_relative 'command'

class GetDowntime < Command

  def run()
    id = ARGV[0] || raise("You must specify an ID!")
    @logger.info("Looking for downtime: '#{id}'")
    result = @dog_client.get_downtime(id)

    puts(result)
  end
end

GetDowntime.new().run()
