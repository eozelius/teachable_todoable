require 'rack/test'
require 'json'
require_relative '../../app/api'

module Todoable
  RSpec.describe 'User Authentication API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }

    describe 'Token based Authentication' do
      it 'returns false if user attempting to authenticate with -u (email:password) header' do
        # No Token header Sent - no error returned
        create_auth_header(user.email, 'asdfasdf')
        post '/authenticate'
        expect(parsed_response[:error_message]).to eq(nil)
      end

      it 'halts Sinatra and returns a 401 (Unauthorized), unless HTTP_AUTHORIZATION header is present' do
        get '/lists'
        expect(last_response.status).to eq(401)
        expect(parsed_response[:error_message]).to eq('Token required')
      end

      it 'decodes an HTTP_AUTHORIZATION header, and assigns a @token var to be used in all subsequent Sinatra routes' do
        create_token_header(user.token)
        get '/lists'
        expect(last_response.status).to eq(200)
        expect(parsed_response[:error_message]).to eq(nil)
        expect(parsed_response[:lists]).not_to eq(nil)
      end
    end

    describe 'post /authenticate => email:password Authentication' do
      context 'User already exists' do
        context 'valid request: email:password present and correct' do
          before { create_auth_header(user.email, 'asdfasdf') }

          it 'generates a new token' do
            old_token = user.token
            post '/authenticate'
            expect(old_token).not_to eq(parsed_response[:token])
          end

          it 'returns a 201' do
            post '/authenticate'
            expect(last_response.status).to eq(201)
          end
        end

        context 'invalid request: email:password missing or incorrect' do
          it 'returns 401 (unauthorized) and helpful error message' do
            create_auth_header(user.email, 'This is not the password you are looking for')
            post '/authenticate'
            expect(last_response.status).to eq(401)
            expect(parsed_response[:error_message]).to eq('Invalid e-mail/password combination')
          end

          it 'does not generate a new token' do
            old_token = user.token
            create_auth_header('invalid email address', 'asdfasdf')
            post '/authenticate'
            expect(old_token).to eq(user.token)
          end
        end
      end

      context 'User does not exist' do
        context 'valid request: email:password present and correct' do
          let(:new_valid_email) { 'qwerty@qwerty.com' }
          let(:new_valid_password) { 'qwerty' }

          before { create_auth_header(new_valid_email, new_valid_password) }

          it 'creates a new user' do
            user_count = User.count
            post '/authenticate'
            expect(User.count).to eq(user_count + 1)
          end

          it 'returns status 201 and a valid token' do
            post '/authenticate'
            expect(last_response.status).to eq(201)
            expect(parsed_response[:token]).not_to eq(nil)
          end
        end

        context 'invalid request: email:password missing or incorrect' do
          let(:invalid_email) { 'this is not a valid email' }
          let(:invalid_password) { '' }

          it 'returns a 401 when NO header is sent' do
            post '/authenticate'
            expect(last_response.status).to eq(401)
            expect(parsed_response[:error_message]).to eq('Invalid email/password')
          end

          it 'returns a 401 (unauthorized) and a helpful error message' do
            create_auth_header(invalid_email, 'asdfasdf')
            post '/authenticate'
            expect(last_response.status).to eq(401)
            expect(parsed_response[:error_message]).to eq('user could not be created')
          end

          it 'does not create a user' do
            user_count = User.count
            create_auth_header(invalid_email, invalid_password)
            post '/authenticate'
            expect(User.count).to eq(user_count)
          end

          it 'does not create a token' do
            create_auth_header(invalid_email, invalid_password)
            post '/authenticate'
            expect(parsed_response[:token]).to eq(nil)
          end
        end
      end
    end
  end
end
