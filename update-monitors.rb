require 'rubygems'
require 'dogapi'

def is_eligible_for_update(monitor)
  # ADD YOUR OWN RULES HERE! Something like:
  # return true if monitor['name'] =~ /delivery:/i
  false 
end

dog = Dogapi::Client.new(API_KEY, APP_KEY)

status, monitors = dog.get_all_monitors

raise "Bad status! Got [#{status}], expecting 200 -- #{monitors}" if status != "200"

monitors.select { |m| is_eligible_for_update(m) }.each do |monitor|
  puts "Updating monitor #{monitor['id']}: #{monitor['name']}"

  # Put in whatever updates you want:
  monitor['name'].gsub!(/delivery:/i, 'Compute:')

  res, msg = dog.update_monitor(monitor['id'], monitor['query'], message: monitor['message'], name: monitor['name'])

  raise "Bad status updating monitor: #{res}: #{msg}" if res != "200"
end


