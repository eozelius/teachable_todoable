require 'rack/test'
require 'json'
require_relative '../../app/api'

module Todoable
  RSpec.describe 'Todoable API' do
    include Rack::Test::Methods # 'post' to send an api request to our directly instead of creating an actually http request

    def app
      Todoable::API.new
    end

    it 'creates a todo list' do
      list = {
        'list': {
          'name': "Urgent Things"
        }
      }

      post '/lists', JSON.generate(list)
    end
  end
end