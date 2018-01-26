require 'rack/test'
require 'json'
require_relative '../../app/api'

module Todoable
  RSpec.describe 'Todoable API', :db do
    include Rack::Test::Methods # 'post' to send an api request to our directly instead of creating an actually http request

    def post_list(list)
      post '/lists', JSON.generate(list)
      expect(last_response.status).to eq(201)
      parsed = JSON.parse(last_response.body)
      expect(parsed).to include('list_id')
    end

    def app
      Todoable::API.new
    end

    it 'records submitted lists and retrieves them' do
      urgent  = { 'name' => 'Urgent Things' }
      medium  = { 'name' => 'Medium Priority' }
      trivial = { 'name' => 'Low Priority' }

      post_list(urgent)
      post_list(medium)
      post_list(trivial)

      get '/lists' # {"lists"=>[{"id"=>1, "name"=>"Urgent Things"}, {"id"=>2, "name"=>"Medium Priority"}, {"id"=>3, "name"=>"Low Priority"}]}
      expect(last_response.status).to eq(200)
      response = JSON.parse(last_response.body)
      expect(response['lists']).to include(
        {"id"=>1, "name"=>"Urgent Things"},
        {"id"=>2, "name"=>"Medium Priority"},
        {"id"=>3, "name"=>"Low Priority"}
      )
    end
  end
end