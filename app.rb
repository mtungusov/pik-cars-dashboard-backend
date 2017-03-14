require 'java'

java_import java.lang.System

puts 'Start App'
puts "Java:  #{System.getProperties['java.runtime.version']}"
puts "Jruby: #{ENV['RUBY_VERSION']}"

require 'lib/settings'
puts "Namespace: #{Settings::Config.namespace}"
puts "App: #{Settings::ALL.app_name}"
puts "Update NSI in: #{Settings::ALL.perion_nsi_update} sec"


require 'lib/ext_service'
require 'lib/storage'

require 'lib/updater'

# require 'thread'
# Thread.abort_on_exception = true
#
# Thread.new do
#   $conn_write_nsi = Storage.client(db_file: File.join(Settings::CUR_DIR, 'db', 'db.sqlite')).open
#   loop do
#     Updater.update_nsi $conn_write_nsi
#     sleep Settings::ALL.perion_nsi_update
#   end
# end
#
# sleep
#
# at_exit {
#   puts "Terminate:at_exit:start"
#   Storage.client.close $conn_write_nsi
#   sleep 1
#   puts "Terminate:at_exit:end"
#   exit!
# }

$conn_write_live = Storage.client(db_file: File.join(Settings::CUR_DIR, 'db', 'db.sqlite')).open


require 'pry'
binding.pry
