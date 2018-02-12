require 'rack/test'
require_relative '../../../../app/api'
require_relative '../../../../app/models/list'
require_relative '../../../../app/models/item'

module Todoable
  RSpec.describe 'List API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }

    before do
      create_token_header(user.token)
    end

    # Create an item
    describe 'POST /lists/:list_id/items' do
      # create one list to add items to
      before do
        @id = create_list({ name: 'fruits' }, user.token)
      end

      let(:item) { { name: 'Item 1 - have fun' } }
      let(:invalid_list_id) { '-1' }

      context 'with valid data' do
        it 'returns a 201 (OK) and the id' do
          post "/lists/#{@id}/items", JSON.generate(item)
          expect(last_response.status).to eq(201)
          expect(parsed_response[:id]).to match(a_kind_of(Integer))
        end

        it 'creates a new item' do
          item_count = Item.count
          post "/lists/#{@id}/items", JSON.generate(item)
          expect(Item.count).to eq(item_count + 1)
        end

        it 'associates the newly created item with the correct list' do
          post "/lists/#{@id}/items", JSON.generate(item)
          list_items = List.find(@id).first.items
          expect(list_items.first.name).to eq(item[:name])
        end
      end

      context 'Valid request: List exists & item is valid' do
        context 'Invalid list_id' do
          it 'returns a 422 (Unprocessible entity)' do
            post "/lists/#{invalid_list_id}/items", JSON.generate(item)
            expect(last_response.status).to eq(422)
          end
        end

        context 'Invalid request: List does not exist, or item is invalid' do
          it 'returns a 422 (Unprocessible entity)' do
            post "/lists/#{@id}/items", JSON.generate(nil)
            expect(last_response.status).to eq(422)
            expect(parsed_response[:error_message]).to eq('Item name is required')
          end

          it 'returns a helpful error message' do
            post "/lists/#{invalid_list_id}/items", JSON.generate( name: 'mangos' )
            expect(parsed_response[:error_message]).to eq('List does not exist')
          end
        end

        it 'does not create any new items' do
          item_count = Item.count
          post "/lists/#{@id}/items", JSON.generate({ invalid_name_key: '' })
          expect(Item.count).to eq(item_count)
        end

        it 'does not add the item to the list' do
          list = List.find(id: @id)
          list_items = list.items
          list_items_count = list_items.count

          post "/lists/#{@id}/items", JSON.generate( invalid_name: 'sandwich?' )
          expect(list.items.count).to eq(list_items_count)
          # expect(list.items).not_to include('sandwich')
        end
      end
    end

    # Update an item - mark it finished
    describe 'PUT /lists/:list_id/items/:item_id/finish' do
      before do
        @list = List.create(name: 'books', user_id: user.id)
        @item = @list.add_item(name: 'fiction')
        @finished_item = @list.add_item(name: 'biographies', finished_at: DateTime.now)
      end

      context 'Valid request: (List & item exist)' do
        it 'returns a 201' do
          put "/lists/#{@list.id}/items/#{@item.id}/finish"
          expect(last_response.status).to eq(200)
        end

        context 'when @item.finished_at == nil' do
          it 'marks the item as finished' do
            put "/lists/#{@list.id}/items/#{@item.id}/finish"
            create_token_header(user.token)
            get "/lists/#{@list.id}"
            first_item = parsed_response[:list][:items].first
            expect(first_item[:finished_at]).not_to eq(nil)
          end
        end

        context 'when @item.finished_at == DateTime' do
          it 'marks the item as unfinished' do
            put "/lists/#{@list.id}/items/#{@finished_item.id}/finish"
            create_token_header(user.token)
            get "/lists/#{@list.id}"
            first_item = parsed_response[:list][:items].last
            expect(first_item[:finished_at]).to eq(nil)
          end
        end
      end

      context 'Invalid request: (List or Item does not exist)' do
        let(:invalid_list_id) { '-1' }
        let(:invalid_item_id) { '-1' }

        it 'will not mark a list item as finished' do
          put "/lists/#{@list.id}/items/#{invalid_item_id}/finish"
          create_token_header(user.token)
          get "/lists/#{@list.id}"
          first_item = parsed_response[:list][:items].first
          expect(first_item['finished_at']).to eq(nil)
        end

        it 'returns a 422(Unprocessable entity)' do
          put "/lists/#{invalid_list_id}/items/1/finish"
          expect(last_response.status).to eq(422)
          create_token_header(user.token)
          put "/lists/1/items/#{invalid_item_id}/finish"
          expect(last_response.status).to eq(422)
        end

        it 'returns a helpful error message' do
          put "/lists/#{@list.id}/items/#{invalid_item_id}/finish"
          expect(parsed_response[:error_message]).to eq('Item does not exist')
        end
      end
    end

    # Delete an Item
    describe 'DELETE /list/:list_id/:item_id' do
      before do
        @list = List.create(name: 'books', user_id: user.id)
        @item = @list.add_item(name: 'fiction')
        @finished_item = @list.add_item(name: 'biographies', finished_at: DateTime.now)
      end

      context 'Valid request: List exists & Item exists' do
        it 'Deletes an item' do
          list_items_count = @list.items.count
          delete "/lists/#{@list.id}/items/#{@item.id}"
          @list.reload
          expect(@list.items.count).to eq(list_items_count - 1)
        end

        it 'deleted the correct item' do
          delete "/lists/#{@list.id}/items/#{@item.id}"
          expect(@list.items).not_to include(@item)
          expect(@list.items).to include(@finished_item)
        end

        it 'returns a 204 (no content)' do
          delete "/lists/#{@list.id}/items/#{@item.id}"
          expect(last_response.status).to eq(204)
        end
      end

      context 'Invalid request: List or Item do not exist' do
        let(:invalid_item_id) { '-1' }
        let(:invalid_list_id) { '-1' }

        it 'returns a 422 (Unprocessable entity)' do
          delete "/lists/#{invalid_list_id}/items/#{@item.id}"
          expect(last_response.status).to eq(422)
        end

        it 'does not delete any items' do
          item_count = Item.count
          delete "/lists/#{@list.id}/items/#{invalid_item_id}"
          expect(Item.count).to eq(item_count)
        end

        it 'returns a helpful error message' do
          delete "/lists/#{@list.id}/items/#{invalid_item_id}"
          expect(parsed_response[:error_message]).to eq('Item does not exist')
        end
      end
    end
  end
end