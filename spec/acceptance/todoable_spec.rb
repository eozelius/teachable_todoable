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
        context 'valid request ' do
          it 'returns a 204 (no content), and a blank response' do
            delete "/lists/#{@item_bucket_list.id}/items/#{@yosemite.id}"
            expect(last_response.status).to eq(204)
            expect(parsed_response).to eq('')
          end

          it 'deletes the item' do
            expect(@item_bucket_list.reload.items).to include(@yosemite)
            delete "/lists/#{@item_bucket_list.id}/items/#{@yosemite.id}"
            expect(@item_bucket_list.reload.items).not_to include(@yosemite)
          end
        end

        context 'invalid request' do
          it 'doesnt delete the item unless the item is owned by the correct user' do
            qwerty = User.create(email: 'qwerty@qwerty.com', password: 'qwerty')
            create_token_header(qwerty.token)
            delete "/lists/#{@item_bucket_list.id}/items/#{@yosemite.id}"
            expect(last_response.status).to eq(422)
            expect(@item_bucket_list.reload.items).to include(@yosemite)
          end

          it 'doesnt delete the item unless the item is part of the correct list' do
            hobbies = @user.add_list(name: 'hobbies')
            delete "/lists/#{hobbies.id}/items/#{@yosemite.id}"
            expect(@item_bucket_list.reload.items).to include(@yosemite)
          end

          it 'rejects invalid list_ids' do
            invalid_list_id = '-1'
            delete "/lists/#{invalid_list_id}/items/#{@yosemite.id}"
            expect(last_response.status).to eq(422)
            expect(@item_bucket_list.reload.items).to include(@yosemite)
          end

          it 'rejects invalid item_ids' do
            invalid_item_id = '-1'
            delete "/lists/#{@item_bucket_list.id}/items/#{invalid_item_id}"
            expect(last_response.status).to eq(422)
            expect(@item_bucket_list.reload.items).to include(@yosemite)
          end
        end
      end
    end
  end
end