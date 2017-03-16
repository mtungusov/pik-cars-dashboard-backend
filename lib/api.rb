require 'json'
require 'sinatra/base'
require 'sinatra/param'

module API
  class App < Sinatra::Base
    helpers Sinatra::Param

    before do
      content_type :json
    end

    get '/' do
      { result: 'Pik-Cars-Dashboard API Server' }.to_json
    end

    post '/trackers' do
      param :ids, Array, default: []

      { ids: params[:ids] }.to_json
    end
  end
end
