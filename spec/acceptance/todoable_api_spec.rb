require 'rack/test'
require 'json'
require_relative '../../app/api'
require_relative '../../spec/support/helper_methods'

module Todoable
  RSpec.describe 'Todoable API', :db do
    include Rack::Test::Methods

    def parsed
      JSON.parse(last_response.body, { symbolize_names: true })
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

      create_list(urgent)
      create_list(medium)
      create_list(trivial)

      get '/lists'
      expect(last_response.status).to eq(200)
      expect(parsed[:lists]).to match(get_lists_response)
    end
  end
end