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
        context 'when list exists' do
          before do
            @delete_list = List.create(name: 'to be deleted', user_id: @user.id)
            @delete_list.add_item(name: 'item to be deleted')
          end

          it 'deletes the list and the list items' do
            delete "/lists/#{@delete_list.id}"
            get "/lists/#{@delete_list.id}"
            expect(parsed_response[:error_message]).to eq('List does not exist')
            expect(last_response.status).to eq(404)
          end

          it 'returns a status 204 (no content)' do
            delete "/lists/#{@delete_list.id}"
            expect(last_response.status).to eq(204)
          end

          it 'deletes the associated items' do
            item_count = Item.count
            delete "/lists/#{@delete_list.id}"
            expect(Item.count).to eq(item_count - 1)
          end
        end

        context 'when list does not exists' do
          it "doesn't delete any lists" do
            list_count = List.count
            delete '/lists/-1'
            expect(List.count).to eq(list_count)
          end

          it 'returns a 422 (Unprocessable entity) and a helpful error message' do
            delete '/lists/-1'
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('List does not exist')
          end
        end
      end
    end

    describe 'Item Endpoints' do
      before do
        create_token_header(@user.token)
        @item_bucket_list = List.create(name: 'Bucket List', user_id: @user.id)
        @grand_canyon_params = { name: 'visit grand canyon' }
        @yosemite = @item_bucket_list.add_item(name: 'visit yosemite national park')
      end

      describe 'post /lists/:list_id/items => create an item' do
        context 'with valid data' do
          it 'returns a 201 (OK) and the id' do
            post "/lists/#{@item_bucket_list.id}/items", JSON.generate(@grand_canyon_params)
            expect(last_response.status).to eq(201)
            expect(parsed_response[:id]).to match(a_kind_of(Integer))
          end

          it 'creates a new item' do
            item_count = Item.count
            post "/lists/#{@item_bucket_list.id}/items", JSON.generate(@grand_canyon_params)
            expect(Item.count).to eq(item_count + 1)
          end

          it 'associates the newly created item with the correct list' do
            post "/lists/#{@item_bucket_list.id}/items", JSON.generate(@grand_canyon_params)
            list_items = List.find(@item_bucket_list.id).first.items
            expect(list_items.last.name).to eq(@grand_canyon_params[:name])
          end
        end

        context 'Invalid Data' do
          it 'rejects invalid list_ids' do
            post "/lists/-1/items", JSON.generate(@grand_canyon_params)
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('List does not exist')
          end

          it 'rejects invalid Item params' do
            post "/lists/#{@item_bucket_list.id}/items", JSON.generate(name: '')
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('Item could not be created')
          end

          it 'does not create any new items' do
            item_count = Item.count
            post "/lists/#{@item_bucket_list.id}/items", JSON.generate({ invalid_name_key: '' })
            expect(Item.count).to eq(item_count)
          end

          it 'rejects empty Item params' do
            post "/lists/#{@item_bucket_list.id}/items", JSON.generate({})
            expect(last_response.status).to eq(422)
          end
        end
      end

      describe 'put /lists/:list_id/items/:item_id/finish => Mark an item as finished' do
        context 'Valid request: (List & item exist)' do
          it 'marks the item as finished (if unfinished) and returns a 201' do
            @yosemite.set(finished_at: nil)
            @yosemite.save
            put "/lists/#{@item_bucket_list.id}/items/#{@yosemite.id}/finish"
            expect(last_response.status).to eq(200)
            @yosemite.reload
            expect(@yosemite.finished_at.class).to eq(Time)
          end

          it 'marks the item as incomplete (if previously marked finished)' do
            @yosemite.set(finished_at: DateTime.now)
            @yosemite.save
            put "/lists/#{@item_bucket_list.id}/items/#{@yosemite.id}/finish"
            expect(last_response.status).to eq(200)
            @yosemite.reload
            expect(@yosemite.finished_at).to eq(nil)
          end
        end

        context 'invalid request: list_id or item_id are invalid' do
          it 'rejects invalid list_ids' do
            put "/lists/-1/items/#{@yosemite.id}/finish"
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('List does not exist')
          end

          it 'rejects invalid item_ids' do
            put "/lists/#{@item_bucket_list.id}/items/-1/finish"
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('Item does not exist')
          end

          it 'does not mark the item as finished' do
            put "/lists/#{@item_bucket_list.id}/items/-1/finish"
            expect(@yosemite.finished_at).to eq(nil)
          end
        end
      end

      describe 'delete /lists/:list_id/items/:item_id' do
      end
    end
  end
end