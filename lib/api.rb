require 'json'
require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/param'

module API
  class App < Sinatra::Base
    before do
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept'
      content_type :json
    end

    get '/api' do
      { result: 'Pik-Cars-Dashboard API Server. Path: /api/v1/' }.to_json
    end

    get '/api/ping' do
      { result: 'pong' }.to_json
    end
  end
end

require_relative 'api/v1'
