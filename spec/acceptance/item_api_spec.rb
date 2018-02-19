require 'rack/test'
require 'json'
require_relative '../../app/api'
require_relative '../../app/models/item'

module Todoable
  RSpec.describe 'Item API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    before do
      @user = User.create(email: 'asdf@adsf.com', password: 'asdfasdf')
      create_token_header(@user.token)
      @bucket_list = @user.add_list(name: 'Bucket List')
      @yosemite = @bucket_list.add_item(name: 'visit yosemite national park')
      @grand_canyon_params = { name: 'visit grand canyon' }
    end

    describe 'post /lists/:list_id/items => create an item' do
      context 'with valid data' do
        it 'returns a 201 (OK) and the id' do
          post "/lists/#{@bucket_list.id}/items", JSON.generate(@grand_canyon_params)
          expect(last_response.status).to eq(201)
          expect(parsed_response[:id]).to match(a_kind_of(Integer))
        end

        it 'creates a new item' do
          item_count = Item.count
          post "/lists/#{@bucket_list.id}/items", JSON.generate(@grand_canyon_params)
          expect(Item.count).to eq(item_count + 1)
        end

        it 'associates the newly created item with the correct list' do
          post "/lists/#{@bucket_list.id}/items", JSON.generate(@grand_canyon_params)
          list_items = List.find(@bucket_list.id).first.items
          expect(list_items.last.name).to eq(@grand_canyon_params[:name])
        end
      end

      context 'Invalid Data' do
        it 'rejects invalid list_ids' do
          post '/lists/-1/items', JSON.generate(@grand_canyon_params)
          expect(last_response.status).to eq(422)
          expect(parsed_response[:error_message]).to eq('List does not exist')
        end

        it 'rejects invalid Item params' do
          post "/lists/#{@bucket_list.id}/items", JSON.generate(name: '')
          expect(last_response.status).to eq(422)
          expect(parsed_response[:error_message]).to eq('Item could not be created')
        end

        it 'does not create any new items' do
          item_count = Item.count
          post "/lists/#{@bucket_list.id}/items", JSON.generate(invalid_name_key: '')
          expect(Item.count).to eq(item_count)
        end

        it 'rejects empty Item params' do
          post "/lists/#{@bucket_list.id}/items", JSON.generate({})
          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'put /lists/:list_id/items/:item_id/finish => Mark an item as finished' do
      context 'Valid request: (List & item exist)' do
        it 'marks the item as finished (if unfinished) and returns a 201' do
          @yosemite.set(finished_at: nil)
          @yosemite.save
          put "/lists/#{@bucket_list.id}/items/#{@yosemite.id}/finish"
          expect(last_response.status).to eq(200)
          @yosemite.reload
          expect(@yosemite.finished_at.class).to eq(Time)
        end

        it 'marks the item as incomplete (if previously marked finished)' do
          @yosemite.set(finished_at: DateTime.now)
          @yosemite.save
          put "/lists/#{@bucket_list.id}/items/#{@yosemite.id}/finish"
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
          put "/lists/#{@bucket_list.id}/items/-1/finish"
          expect(last_response.status).to eq(422)
          expect(parsed_response[:error_message]).to eq('Item does not exist')
        end

        it 'does not mark the item as finished' do
          put "/lists/#{@bucket_list.id}/items/-1/finish"
          expect(@yosemite.finished_at).to eq(nil)
        end
      end
    end

    describe 'delete /lists/:list_id/items/:item_id' do
      context 'valid request ' do
        it 'returns a 204 (no content), and a blank response' do
          delete "/lists/#{@bucket_list.id}/items/#{@yosemite.id}"
          expect(last_response.status).to eq(204)
          expect(parsed_response).to eq('')
        end

        it 'deletes the item' do
          expect(@bucket_list.reload.items).to include(@yosemite)
          delete "/lists/#{@bucket_list.id}/items/#{@yosemite.id}"
          expect(@bucket_list.reload.items).not_to include(@yosemite)
        end
      end

      context 'invalid request' do
        it 'doesnt delete the item unless the item is owned by the correct user' do
          qwerty = User.create(email: 'qwerty@qwerty.com', password: 'qwerty')
          create_token_header(qwerty.token)
          delete "/lists/#{@bucket_list.id}/items/#{@yosemite.id}"
          expect(last_response.status).to eq(422)
          expect(@bucket_list.reload.items).to include(@yosemite)
        end

        it 'doesnt delete the item unless the item is part of the correct list' do
          hobbies = @user.add_list(name: 'hobbies')
          delete "/lists/#{hobbies.id}/items/#{@yosemite.id}"
          expect(@bucket_list.reload.items).to include(@yosemite)
        end

        it 'rejects invalid list_ids' do
          invalid_list_id = '-1'
          delete "/lists/#{invalid_list_id}/items/#{@yosemite.id}"
          expect(last_response.status).to eq(422)
          expect(@bucket_list.reload.items).to include(@yosemite)
        end

        it 'rejects invalid item_ids' do
          invalid_item_id = '-1'
          delete "/lists/#{@bucket_list.id}/items/#{invalid_item_id}"
          expect(last_response.status).to eq(422)
          expect(@bucket_list.reload.items).to include(@yosemite)
        end
      end
    end
  end
end
