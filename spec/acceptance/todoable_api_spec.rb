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
      expect(parsed).to match(a_hash_including(
        'list' => a_hash_including('name' => a_kind_of(String))
      ))
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

      get '/lists'
      expect(last_response.status).to eq(200)
      response = JSON.parse(last_response.body)
      expect(response['lists']).to include(
        a_hash_including(urgent),
        a_hash_including({ "name"=>"Medium Priority" }),
        a_hash_including({ "name"=>"Low Priority" })
      )
    end
  end
end