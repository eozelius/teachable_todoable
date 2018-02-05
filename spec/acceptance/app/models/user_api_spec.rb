require 'rack/test'

module Todoable
  RSpec.describe 'User API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    def parsed
      JSON.parse(last_response.body)
    end

    describe 'Authentication' do
      context 'user already exists' do
        context 'valid request: email:password present and correct' do
          it 'generates a new token'
          it 'returns a 200'
        end

        context 'invalid request: email:password missing or incorrect' do
          it 'returns a helpful error message' do

          end
          it 'does not generate a new token'
        end
      end

      context 'user does not exist' do
        context 'valid request: email:password present and correct' do
          it 'creates a new user'
          it 'returns status 201'
          it 'returns a new token'
        end

        context 'invalid request: email:password missing or incorrect' do
          let(:invalid_email) { 'aiblseusn8478@aolbgmcgh.jj2' }
          let(:invalid_password) { '' }

          it 'returns a 422 (unprocessable entity)' do
            #   header 'Test-Header', 'Test value'

            # header 'AUTHORIZATION', 'Basic c2FyYWg6YXNkZmFzZGYxMjM0MTIzNA=='
            header 'Authorization', "Basic #{invalid_email}:#{invalid_password}"
            post '/authenticate'
            expect(last_response.status).to eq(422)
            expect(parsed['error_message']).to eq('user could not be created')

          end
          it 'returns a helpful error message'
          it 'does not create a user, or token'
        end
      end
    end

    # describe 'token' do
    #   it 'expires after 20 minutes'
    #
    #   it 'is required to do anything'
    # end





    # Authentication - Request a token
  end
end