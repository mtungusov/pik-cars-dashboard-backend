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

        { ids: params[:ids] }.to_json
      end
    end
  end
end
