require 'settingslogic'
require 'dotenv'

module Settings
  ROOT_DIR = File.dirname(__dir__).to_s
  puts "Dir: #{Settings::ROOT_DIR}"

  CUR_DIR = ROOT_DIR.include?('uri:classloader:') ? File.split(ROOT_DIR).first : ROOT_DIR
  puts "Cur Dir: #{CUR_DIR}"

  API_TOKEN_FILE = File.join(CUR_DIR, 'config', '.api_token')

  CONFIG_FILE = File.join(CUR_DIR, 'config', 'config.yml')
  puts "Config File: #{CONFIG_FILE}"
  unless File.exist? CONFIG_FILE
    puts "Error: Not found config file - #{CONFIG_FILE}!"
    exit!
  end

  SECRETS_FILE = File.join(CUR_DIR, 'config', "secrets.env.#{ENV['RUN_ENV']}")
  puts "Secrets Env File: #{SECRETS_FILE}"
  unless File.exist? SECRETS_FILE
    puts "Error: Not found secrets file - #{SECRETS_FILE}!"
    exit!
  end

  class Config < Settingslogic
    namespace ENV['RUN_ENV']
  end

  ALL = Config.new CONFIG_FILE

  Dotenv.load SECRETS_FILE
end
