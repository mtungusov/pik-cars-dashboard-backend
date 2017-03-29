module API
  class App < Sinatra::Base
    register Sinatra::Namespace
    helpers Sinatra::Param

    namespace '/api/v1' do
      before do
        content_type :json
      end

      post '/trackers' do
        param :ids, Array, default: []

        ::Storage.trackers_info($conn_read_api, params[:ids]).to_json
      end

      get '/zones' do
        ::Storage.zones($conn_read_api).to_json
      end
    end
  end
end
