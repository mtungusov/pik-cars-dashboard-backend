require 'faraday'
require 'faraday_middleware'

module ExtService; end

module ExtService::Navixy
  API_LIMIT = 1000
  TIME_FMT = '%Y-%m-%-d %H:%M:%S'


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

    def list(url)
      return [] unless auth?
      resp = @connection.post do |req|
        req.url url
        req.params['hash'] = @token
      end
      resp.body['success'] ? resp.body['list'] : []
    end

    def events(from:, to:, tracker_ids:, event_types:)
      r, err = [], nil
      return [r, 'Empty tracker_ids or event_types'] if (tracker_ids.empty? or event_types.empty?)
      return [r, 'Unauthorized'] unless auth?
      url = '/v2/history/tracker/list'
      resp = @connection.post do |req|
        req.url url
        req.params['hash'] = @token
        req.body = _events_params_encode(from, to, tracker_ids, event_types)
      end
      resp.body['success'] ? r = resp.body['list'] : err = resp.body['status']['description']
      [r, err]
    rescue => e
      [r, e.message]
    end

    def _events_params_encode(from, to, tracker_ids, event_types)
      params = []
      params << "from=#{URI.encode_www_form_component(from)}"
      params << "to=#{URI.encode_www_form_component(to)}"
      params << "trackers=#{URI.encode_www_form_component(tracker_ids)}"
      params << "events=#{URI.encode_www_form_component(event_types)}"
      params.join('&')
    end

    def tracker_state(tracker_id)
      return {} unless auth?
      url = '/v2/tracker/get_state'
      resp = @connection.post do |req|
        req.url url
        req.params['hash'] = @token
        req.body = "tracker_id=#{tracker_id}"
      end
      if resp.body['success']
        resp.body['state']
      elsif resp.body['status']['code'] == 208
        { 'movement_status' => 'unknown', 'connection_status' => 'blocked', 'last_update' => Time.now.strftime(TIME_FMT) }
      else
        {}
      end
    end

    def tracker_states(tracker_ids)
      return {} if tracker_ids.empty?
      return {} unless auth?
      url = '/v2/tracker/get_states'
      resp = @connection.post do |req|
        req.url url
        req.params['hash'] = @token
        req.body = "trackers=#{URI.encode_www_form_component(tracker_ids)}"
      end
      resp.body['success'] ? resp.body['states'] : {}
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
        faraday.request  :url_encoded # form-encode POST params
        faraday.response :logger, @logger, headers: false # log requests to STDOUT
        faraday.response :json, 'content-type' => 'application/json; charset=utf-8'
        faraday.adapter  Faraday.default_adapter # make requests with Net::HTTP
      end
    end
  end

  module_function

  def api
    @@navixy ||= NavixyApi.new
  end

  def trackers
    api.list('/v2/tracker/list').map do |h|
      {
        'id' => h['id'],
        'label' => h['label'],
        'group_id' => h['group_id']
      }
    end
  end

  def groups
    initial = [{ 'id' => 0, 'title' => 'Основная' }]

    initial + api.list('/v2/tracker/group/list').map do |h|
      {
        'id' => h['id'],
        'title' => h['title']
      }
    end
  end

  def rules
    api.list('/v2/tracker/rule/list').select { |elem| elem['type'] == 'inoutzone' }.map do |h|
      {
        'id' => h['id'],
        'type' => h['type'],
        'name' => h['name'],
        'zone_id' => h['zone_id']
      }
    end
  end

  def zones
    api.list('/v2/zone/list').map do |h|
      {
        'id' => h['id'],
        'label' => h['label']
      }
    end
  end

  def _tracker_states(tracker_ids)
    # return { id:{movement_status:'', last_update:'', connection_status:''}, ...}
    tracker_ids.inject({}) do |acc, id|
      begin
        resp = api.tracker_state(id)
        acc[id] = resp unless resp.empty?
      rescue
        puts "Error: get state for tracker #{id}"
      end
      acc
    end
  end

  def tracker_states(tracker_ids)
    # return { state1:[ [id, changed_at],... ], ... }

    # api.tracker_states(tracker_ids).inject({}) do |acc, (k, v)|
    _tracker_states(tracker_ids).inject({}) do |acc, (k, v)|
      status = v['movement_status']
      changed_at = v['last_update']
      connection = v['connection_status']
      acc[status] = [] unless acc.key?(status)
      acc[status] << [k.to_i, changed_at, connection]
      acc
    end
  end

  def events_by(tracker, from, to, result: [])
    event_types = ['inzone', 'outzone']
    _to = from == to ? (Time.parse(to) + 1).strftime(TIME_FMT) : to
    r, err = api.events(from: from, to: _to, tracker_ids: [tracker], event_types: event_types)
    result += r
    if err
      puts "ERROR when get history: #{err}"
      return result
    end
    if r.size >= API_LIMIT
      _from = r.last['time']
      events_by(tracker, _from, _to, result: result)
    end
    result
  end

end
