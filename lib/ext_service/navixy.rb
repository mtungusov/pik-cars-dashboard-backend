require 'faraday'
require 'faraday_middleware'

module ExtService; end

module ExtService::Navixy
  class NavixyApi
    def initialize
      @url = 'https://api.navixy.com'
      @login = ENV['API_USER']
      @password = ENV['API_PASSWORD']

      @token_update_period = Settings::ALL.period_in_days_api_token_update
      @token_file = Settings::API_TOKEN_FILE
      @token, @token_created_at = _token_from_file

      @connection = _create_connection
    end

    def auth?
      if (Date.today - Time.at(@token_created_at).to_date) > @token_update_period
        @token = _token_from_api
        @token_created_at = Time.now.to_i
        _token_to_file
      end
      !@token.empty?
    end

    def trackers
      return [] unless auth?
      resp = @connection.post do |req|
        req.url '/v2/tracker/list'
        req.params['hash'] = @token
      end
      resp.body['success'] ? resp.body['list'] : []
    end

    def groups
      return [] unless auth?
      resp = @connection.post do |req|
        req.url '/v2/tracker/group/list'
        req.params['hash'] = @token
      end
      resp.body['success'] ? resp.body['list'] : []
    end

    def zones
      return [] unless auth?
      resp = @connection.post do |req|
        req.url '/v2/zone/list'
        req.params['hash'] = @token
      end
      resp.body['success'] ? resp.body['list'] : []
    end

    def rules
      return [] unless auth?
      resp = @connection.post do |req|
        req.url '/v2/tracker/rule/list'
        req.params['hash'] = @token
      end
      resp.body['success'] ? resp.body['list'] : []
    end

    def _token_to_file
      f = File.open @token_file, 'w'
      f.write @token
    ensure
      f.close if f
    end

    def _token_from_file
      result = ['', 0]
      return result unless File.exist? @token_file
      begin
        f = File.open @token_file, 'r'
        result = [f.readline.strip, f.mtime.to_i]
      rescue
        result = ['', 0]
      ensure
        f.close if f
      end
      result
    end

    def _token_from_api
      url = '/v2/user/auth'
      result = ''
      resp = @connection.post do |req|
        req.url url
        req.params['login'] = @login
        req.params['password'] = @password
      end
      result = resp.body['hash'] if resp.body['success']
      result
    end

    def _create_connection
      Faraday.new(url: @url) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.response :json, 'content-type' => 'application/json; charset=utf-8'
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end
  end

  module_function

  def api
    @@navixy ||= NavixyApi.new
  end

  def trackers
    api.trackers.map do |h|
      {
        'id' => h['id'],
        'label' => h['label'],
        'group_id' => h['group_id']
      }
    end
  end

  def groups
    api.groups.map do |h|
      {
        'id' => h['id'],
        'title' => h['title']
      }
    end
  end

  def rules
    filter = 'inoutzone'
    api.rules.select do |elem|
      elem['type'] == filter
    end.map do |h|
      {
        'id' => h['id'],
        'type' => h['type'],
        'name' => h['name'],
        'zone_id' => h['zone_id']
      }
    end
  end

  def zones
    api.zones.map do |h|
      {
        'id' => h['id'],
        'label' => h['label']
      }
    end
  end
end
