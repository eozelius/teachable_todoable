require 'rack/test'
require 'json'
require_relative '../../app/api'

module Todoable
  RSpec.describe 'Todoable API', :db do
    include Rack::Test::Methods

    def parsed
      JSON.parse(last_response.body, { symbolize_names: true })
    end

    def post_list(list)
      post '/lists', JSON.generate(list)
      expect(last_response.status).to eq(201)
      expect(parsed).to match({ id: a_kind_of(Integer) })
    end

    def app
      Todoable::API.new
    end

    let(:get_lists_response) do
      [
        {
          list: {
            id: 1,
            name: 'Urgent Things',
            items: []
          }
        },
        {
          list: {
            id: 2,
            name: 'Medium Priority',
            items: []
          }
        },
        {
          list: {
            id: 3,
            name: 'Low Priority',
            items: []
          }
        }
      ]
    end

    it 'records submitted lists and retrieves them' do
      urgent  = { name: 'Urgent Things' }
      medium  = { name: 'Medium Priority' }
      trivial = { name: 'Low Priority' }

      post_list(urgent)
      post_list(medium)
      post_list(trivial)

      get '/lists'
      expect(last_response.status).to eq(200)
      expect(parsed[:lists]).to match(get_lists_response)
    end
  end
end