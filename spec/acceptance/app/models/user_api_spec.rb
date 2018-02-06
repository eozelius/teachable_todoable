require 'rack/test'
require_relative '../../../../app/models/user'
require_relative '../../../../app/api'
require 'base64'


module Todoable
  RSpec.describe 'User API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    def parsed
      JSON.parse(last_response.body, { symbolize_names: true })
    end

    def create_auth_header(email, password)
      user_pass_digest = Base64.encode64("#{email}:#{password}")
      "Basic #{user_pass_digest}"
    end

    describe 'Authentication' do
      context 'user already exists' do
        let(:password) { 'asdfasdf' }
        let(:user) { User.create(email: 'user@example.com', password: password) }

        context 'valid request: email:password present and correct' do
          before do
            auth_header = create_auth_header(user.email, password)
            header 'Authorization', auth_header
          end

          it 'generates a new token' do
            old_token = user.generate_token!
            post '/authenticate'
            expect(old_token).not_to eq(parsed[:token])
          end

          it 'returns a 201' do
            post '/authenticate'
            expect(last_response.status).to eq(201)
          end
        end

        context 'invalid request: email:password missing or incorrect' do
          it 'returns a helpful error message' do
            auth_header = create_auth_header(user.email, '')
            header 'Authorization', auth_header
            post '/authenticate'
            expect(last_response.status).to eq(422)
            expect(parsed[:error_message]).to eq('invalid email:password combination')
          end

          it 'does not generate a new token' do
            old_token = user.generate_token!
            auth_header = create_auth_header(user.email, 6)
            header 'Authorization', auth_header
            post '/authenticate'
            expect(old_token).to eq(user.token)
          end
        end
      end

      context 'user does not exist' do
        context 'valid request: email:password present and correct' do
          let(:valid_email) { 'asdf@asdf.com' }
          let(:valid_password) { 'asdfasdf' }

          before do
            auth_header = create_auth_header(valid_email, valid_password)
            header 'Authorization', auth_header
          end

          it 'creates a new user' do
            user_count = User.count
            post '/authenticate'
            expect(User.count).to eq(user_count + 1)
          end

          it 'returns status 201' do
            post '/authenticate'
            expect(last_response.status).to eq(201)
          end

          it 'returns a new token' do
            post '/authenticate'
            expect(parsed[:token]).not_to eq(nil)
          end
        end

        context 'invalid request: email:password missing or incorrect' do
          let(:non_existent_email) { 'aiblseusn8478@aolbgmcgh.jj2' }
          let(:invalid_password) { '' }

          it 'returns a 401 when NO header is sent' do
            post '/authenticate'
            expect(last_response.status).to eq(401)
            expect(parsed[:error_message]).not_to eq(nil)
          end

          it 'returns a 422 (unprocessable entity)' do
            auth_header = create_auth_header(non_existent_email, invalid_password)
            header 'Authorization', auth_header
            post '/authenticate'
            expect(last_response.status).to eq(422)
          end

          it 'returns a helpful error message' do
            auth_header = create_auth_header(non_existent_email, nil)
            header 'Authorization', auth_header
            post '/authenticate'
            expect(parsed[:error_message]).to eq('user could not be created')
          end

          it 'does not create a user' do
            user_count = User.count
            auth_header = create_auth_header(non_existent_email, invalid_password)
            header 'Authorization', auth_header
            post '/authenticate'
            expect(User.count).to eq(user_count)
          end

          it 'does not create a token' do
            auth_header = create_auth_header(non_existent_email, invalid_password)
            header 'Authorization', auth_header
            post '/authenticate'
            expect(parsed[:token]).to eq(nil)
          end
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