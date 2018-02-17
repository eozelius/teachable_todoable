require 'rack/test'
require 'json'
require_relative '../../app/api'

module Todoable
  RSpec.describe 'Todoable API endpoint', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    before do
      @ledger = Ledger.new
      @user = User.create(email: 'asdf@adsf.com', password: 'asdfasdf')
      # @bucket_list  = @user.add_list(name: 'Bucket List')
      # @grand_canyon = @bucket_list.add_item(name: 'visit grand canyon')
    end

    describe 'Token based Authentication' do
    end

    describe 'post /authenticate => email:password Authentication' do
      context 'User already exists' do
        context 'valid request: email:password present and correct' do
          before { create_auth_header(@user.email, 'asdfasdf') }

          it 'generates a new token' do
            old_token = @user.token
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
            create_auth_header(@user.email, 'This is not the password you are looking for')
            post '/authenticate'
            expect(last_response.status).to eq(401)
            expect(parsed_response[:error_message]).to eq('Invalid e-mail/password combination')
          end

          it 'does not generate a new token' do
            old_token = @user.token
            create_auth_header('invalid email address', 'asdfasdf')
            post '/authenticate'
            expect(old_token).to eq(@user.token)
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

    describe 'List Endpoints' do
      before { create_token_header(@user.token) }

      describe 'get /lists => fetch all lists that belong to user' do
        it 'returns [] if NO lists exist' do
          get '/lists'
          expect(parsed_response[:lists]).to eq([])
        end

        context 'when lists exist' do
          let(:urgent) { { name: 'Urgent Things' } }
          let(:medium) { { name: 'Medium Priority' } }
          let(:trivial){ { name: 'Low Priority' } }

          before do
            create_list(urgent, @user.token)
            create_list(medium, @user.token)
            create_list(trivial, @user.token)
          end

          it 'returns all lists' do
            get '/lists'
            expect(parsed_response[:lists]).to match([ {:list=>{:id=>1, :name=>"Urgent Things", :items=>[]}},
                                                       {:list=>{:id=>2, :name=>"Medium Priority", :items=>[]}},
                                                       {:list=>{:id=>3, :name=>"Low Priority", :items=>[]}} ])
          end
        end
      end

      describe 'get /lists/:list_id => fetch a particular list' do
        it 'returns a particular list' do
          bucket_list = { name: 'Bucket List' }
          id = create_list(bucket_list, @user.token)
          get "lists/#{id}"
          expect(parsed_response).to match(list: {
                                             id: id,
                                             name: 'Bucket List',
                                             items: [] } )
        end

        context 'when List does NOT exist' do
          it 'returns a 404 and a helpful error message' do
            get '/lists/-1'
            expect(last_response.status).to eq(404)
            expect(parsed_response[:error_message]).to eq('List does not exist')
            expect(parsed_response[:list]).to eq(nil)
          end
        end
      end

      describe 'post /lists => create a list' do
        context 'valid data' do
          it 'returns the ID' do
            list = { name: 'Bucket List' }
            id = create_list(list, @user.token)
            expect(parsed_response).to match( { id: id })
          end
        end

        context 'with Invalid data' do
          it 'rejects lists without a name key' do
            list = { this_is_invalid: 44 }
            post '/lists', JSON.generate(list)
            expect(last_response.status).to eq(422)
          end

          it 'rejects lists with invalid name values, and provides a helpful error message' do
            list = { name: '' }
            post '/lists', JSON.generate(list)
            expect(parsed_response[:error_message]).to eq('Error list could not be created')
          end

          it 'rejects a request without list params' do
            post '/lists', JSON.generate({})
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('List is required')
          end
        end
      end

      describe 'patch /lists/:list_id => update a list' do
        before do
          list = { name: 'Original Bucket List' }
          @patch_list_id = create_list(list, @user.token)
        end

        context 'Valid request (List exists & name is valid)' do
          it 'responds with a status code 201 (OK)' do
            patch "/lists/#{@patch_list_id}", JSON.generate(name: 'Name has been updated')
            expect(last_response.status).to eq(201)
          end

          it 'Updates the list' do
            patch "/lists/#{@patch_list_id}", JSON.generate(name: 'Updated!!!')
            get "/lists/#{@patch_list_id}"
            expect(parsed_response[:list][:name]).to eq('Updated!!!')
          end

          it 'Returns the new list once it has been updated' do
            patch "/lists/#{@patch_list_id}", JSON.generate(name: 'Updated!!!')
            expect(parsed_response).to include({ list: {
                                                   id: a_kind_of(Integer),
                                                   name: 'Updated!!!' }} )
          end
        end

        context 'Invalid Request (List doesnt exist, or name/items are invalid)' do
          it 'rejects request without a list name, with a 422 and a helpful message' do
            patch "/lists/#{@patch_list_id}", JSON.generate({})
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('List is required')
          end

          it 'Does NOT update the list' do
            patch "/lists/#{@patch_list_id}", JSON.generate(name: '')
            get "/lists/#{@patch_list_id}"
            expect(parsed_response).to include({ list: {
                                                   name: 'Original Bucket List',
                                                   id: @patch_list_id,
                                                   items: [] } })
          end
        end
      end

      describe 'delete /lists/:list_id' do

      end
    end

    describe 'Item Endpoints' do
      describe 'post /lists/:list_id/items' do

      end

      describe 'put /lists/:list_id/items/:item_id/finish' do
      end

      describe 'delete /lists/:list_id/items/:item_id' do
      end
    end
  end
end