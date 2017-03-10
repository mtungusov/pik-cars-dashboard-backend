require 'java'

java_import java.lang.System

puts 'Start App'
puts "Java:  #{System.getProperties['java.runtime.version']}"
puts "Jruby: #{ENV['RUBY_VERSION']}"

require 'lib/settings'
puts "Namespace: #{Settings::Config.namespace}"
puts "App: #{Settings::ALL.app_name}"


# require 'lib/ext_service'
require 'lib/storage'
Storage.client(db_file: File.join(Settings::CUR_DIR, 'db', 'db.sqlite'))

require 'pry'
binding.pry

# require 'thread'
# Thread.abort_on_exception = true

# todo
# Retrive data from API
# init DB
# update DB
