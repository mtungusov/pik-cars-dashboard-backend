require_relative 'ext_service/navixy'

module ExtService
  # token: '1111', createdat: unix_time
  # @@api_token = {}

  module_function

  # def api_token
  #   return @@api_token[:token] if _api_token_valid?
  #   _set_api_token_from_file
  #   return @@api_token[:token] if _api_token_valid?
  #   _api_token_from_online
  # end
  #
  # def _api_token_from_online
  #   token = ExtService::Navixy.api.token
  #   @@api_token = { token: token, created_at: Time.now.to_i }
  #   _save_api_token_to_file(token)
  #   token
  # end
  #
  # def _save_api_token_to_file(token)
  #   f = File.open Settings::API_TOKEN_FILE, 'w'
  #   f.write token
  # ensure
  #   f.close if f
  # end
  #
  # def _set_api_token_from_file
  #   return unless File.exist? Settings::API_TOKEN_FILE
  #   f = File.open Settings::API_TOKEN_FILE, 'r'
  #   @@api_token = { token: f.readline.strip, created_at: f.mtime.to_i }
  # ensure
  #   f.close if f
  # end
  #
  # def _api_token_valid?
  #   return false if @@api_token.empty?
  #   return false if (Date.today - Settings::All.period_in_days_api_token_update).to_time.to_i > @@api_token[:created_at]
  #   true
  # end

  # TODO
  # get api hash
  # get nsi data
  # get evetns
  # get tracker status
end




# url = 'https://api.navixy.com'

# conn = Faraday.new(url: url) do |faraday|
#   faraday.request  :url_encoded             # form-encode POST params
#   faraday.response :logger                  # log requests to STDOUT
#   faraday.response :json, 'content-type' => 'application/json; charset=utf-8'
#   faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
# end

# Content-Type: application/json; charset=utf-8



# resp = conn.post do |req|
#   req.url '/v2/user/auth'
#   req.params['login'] = 'viewgeo@pik-industry.ru'
#   req.params['password'] = '5ziRDy'
# end

# h = '93dd3b3c2f2d626bdaa24dbcf2f264ff'
#
# resp = conn.post do |req|
#   req.url '/v2/user/get_info'
#   req.params['hash'] = h
# end

# resp = conn.post do |req|
#   req.url '/v2/tracker/list1'
#   req.params['hash'] = h
# end
