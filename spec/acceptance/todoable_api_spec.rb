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
      expect(parsed).to include('list_id' => a_kind_of(Integer))
      list.merge('id' => parsed['list_id'])
    end

    def app
      Todoable::API.new
    end

    it 'records submitted lists and retrieves them' do
      urgent = post_list({ 'name' => 'Urgent Things' })
      medium = post_list({ 'name' => 'Medium Priority' })
      low =    post_list({ 'name' => 'Low Priority' })

      get '/lists'
      expect(last_response.status).to eq(200)
      lists = JSON.parse(last_response.body)
      expect(lists).to contain_exactly(urgent, medium, low)
    end
  end
end