require 'rack/test'
require 'json'
require_relative '../../app/api'
require_relative '../../spec/support/helper_methods'

module Todoable
  RSpec.describe 'Todoable API', :db do
    include Rack::Test::Methods

    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }

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

      create_list(urgent, user.token)
      create_list(medium, user.token)
      create_list(trivial, user.token)

      create_token_header(user.token)
      get '/lists'

      expect(last_response.status).to eq(200)
      expect(parsed_response[:lists]).to match(get_lists_response)
    end
  end
end