require 'json'
require 'rack/test'
require_relative '../../../app/api'
require_relative '../../../app/models/item'
require_relative '../../../app/models/list'

module Todoable
  RSpec.describe 'Todoable ENDPOINTS', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    def post_list(list)
      post '/lists', JSON.generate(list)
      expect(last_response.status).to eq(201)
      expect(parsed).to include('id')
      parsed['id'] ? parsed['id'] : false
    end

    def parsed
      JSON.parse(last_response.body)
    end

    def get_lists_response
      [
        {
          "list" => {
            "id" => 1,
            "name" => "Urgent Things",
            "items" => []
          }
        },
        {
          "list" => {
            "id" => 2,
            "name" => "Medium Priority",
            "items" => []
          }
        },
        {
          "list" => {
            "id" => 3,
            "name" => "Low Priority",
            "items" => []
          }
        }
      ]
    end

    # Retrieves lists
    describe 'GET /lists' do
      context 'when NO lists exist' do
        it 'returns []' do
          get '/lists'
          expect(parsed['lists']).to eq(nil)
        end

        it 'sends a status 404' do
          get '/lists'
          expect(last_response.status).to eq(404)
        end

        it 'informs user no lists exist' do
          get '/lists'
          expect(parsed['error_message']).to eq('No lists exists')
        end
      end

      context 'when lists exist' do
        let(:urgent) { { 'name' => 'Urgent Things' } }
        let(:medium) { { 'name' => 'Medium Priority' } }
        let(:trivial){ { 'name' => 'Low Priority' } }

        before do
          post_list(urgent)
          post_list(medium)
          post_list(trivial)
        end

        it 'returns all lists' do
          get '/lists'
          expect(parsed['lists'].count).to eq(3)
          expect(parsed['lists']).to match(get_lists_response)
        end

        it 'Obeys correct format' do
          get '/lists'
          expect(parsed['lists']).to match(get_lists_response)
        end
      end
    end

    # Retrieve a single list
    describe 'GET /lists/:list_id' do
      context 'when List exists' do
        it 'returns the list' do
          list = { 'name' => 'important things' }
          id = post_list(list)
          get "lists/#{id}"
          expect(parsed).to match(
            'list' => {
              'id' => id,
              'name' => 'important things',
              'items' => []
            }
          )
        end
      end

      context 'when List does NOT exist' do
        it 'returns a 404' do
          get '/lists/-1'
          expect(last_response.status).to eq(404)
        end

        it 'provides a helpful error message' do
          get '/lists/-1'
          expect(parsed["error_message"]).to eq('List does not exist')
        end

        it 'returns a nil List' do
          get '/lists/-1'
          expect(parsed["list"]).to eq(nil)
        end
      end
    end

    # Create a list
    describe 'POST /lists' do
      context 'with valid data' do
        it 'returns the ID and list name' do
          list = { 'name' => 'important things' }
          post_list(list)
          expect(parsed).to match(
            { 'id' => a_kind_of(Integer) }
          )
        end
      end

      context 'with Invalid data' do
        it 'rejects the list' do
          list = { 'this_is_invalid' => 44 }
          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(422)
        end

        it 'provides a helpful message' do
          list = { 'name' => '' }
          post '/lists', JSON.generate(list)
          expect(parsed['error_message']).to eq('Error list could not be created')
        end
      end
    end

    # Create an item
    describe 'POST /lists/:list_id/items' do
      # create one list to add items to
      before do
        @id = post_list({ name: 'fruits' })
      end

      let(:item) { { name: 'Item 1 - have fun' } }
      let(:invalid_list_id) { '-1' }

      context 'with valid data' do
        it 'returns a 201 (OK) and the id' do
          post "/lists/#{@id}/items", JSON.generate(item)
          expect(last_response.status).to eq(201)
          expect(parsed['id']).to match(a_kind_of(Integer))
          # expect(parsed['name']).to eq(list)
          # expect(parsed['name']).to eq('Item 1 - have fun')
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
            expect(parsed['error_message']).to eq('Error - item is required')
          end

          it 'returns a helpful error message' do
            post "/lists/#{invalid_list_id}/items", JSON.generate( name: 'mangos' )
            expect(parsed['error_message']).to eq('Error - list does not exist')
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

    # Update a list
    describe 'PATCH /lists/:list_id' do
      before do
        list = { 'name' => 'to be updated' }
        @id = post_list(list)
      end

      context 'When request is valid (List exists & name is valid)' do
        it 'responds with a status code 201 (OK)' do
          patch "/lists/#{@id}", JSON.generate('name' => 'Name has been updated')
          expect(last_response.status).to eq(201)
        end

        it 'Updates the list' do
          get "/lists/#{@id}"
          expect(parsed['list']['name']).to eq('to be updated')
          patch "/lists/#{@id}", JSON.generate('name' => 'Name has been updated')
          get "/lists/#{@id}"
          expect(parsed['list']['name']).to eq('Name has been updated')
        end

        it 'Returns the new list once it has been updated' do
          patch '/lists/1', JSON.generate('name' => 'Name has been updated')
          expect(parsed).to include({
            "list" => {
              "id" => a_kind_of(Integer),
              "name" => "Name has been updated"
            }
          })
        end
      end

      context 'When request is Invalid (List doesnt exist, or name/items are invalid)' do
        it 'returns a helpful error message' do
          patch "/lists/#{@id}", JSON.generate('incorrect_name' => [])
          expect(parsed['error_message']).to eq('Error - list is not valid')
        end

        it 'responds with status code 422' do
          patch "/lists/#{@id}", JSON.generate('incorrect_name' => [])
          expect(last_response.status).to eq(422)
        end

        it 'Does NOT update the list' do
          patch "/lists/#{@id}", JSON.generate('incorrect_name' => [])
          get "/lists/#{@id}"
          expect(parsed).to include({
            'list' => {
              'name' => 'to be updated',
              'id' => @id,
              'items' => []
            }
          })
        end
      end
    end

    # Update an item - mark it finished
    describe 'PUT /lists/:list_id/items/:item_id/finish' do
      before do
        @list = List.create(name: 'books')
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
            get "/lists/#{@list.id}"
            first_item = parsed["list"]["items"].first
            expect(first_item["finished_at"]).not_to eq(nil)
          end
        end

        context 'when @item.finished_at == DateTime' do
          it 'marks the item as unfinished' do
            put "/lists/#{@list.id}/items/#{@finished_item.id}/finish"
            get "/lists/#{@list.id}"
            first_item = parsed["list"]["items"].last
            expect(first_item["finished_at"]).to eq(nil) # todo
          end
        end
      end

      context 'Invalid request: (List or Item does not exist)' do
        let(:invalid_list_id) { '-1' }
        let(:invalid_item_id) { '-1' }

        it 'will not mark a list item as finished' do
          put "/lists/#{@list.id}/items/#{invalid_item_id}/finish"
          get "/lists/#{@list.id}"
          first_item = parsed['list']['items'].first
          expect(first_item['finished_at']).to eq(nil)
        end

        it 'returns a 422(Unprocessable entity)' do
          put "/lists/#{invalid_list_id}/items/1/finish"
          expect(last_response.status).to eq(422)
          put "/lists/1/items/#{invalid_item_id}/finish"
          expect(last_response.status).to eq(422)
        end

        it 'returns a helpful error message' do
          put "/lists/#{@list.id}/items/#{invalid_item_id}/finish"
          expect(parsed['error_message']).to eq('Error - Item does not exist')
        end
      end
    end

    # Delete a list
    describe 'DELETE /lists/:list_id' do
      before do
        list = { 'name' => 'to be deleted' }
        @id = post_list(list)
      end

      # context 'when user is authorized to delete list' do
        context 'when list exists' do
          it 'deletes the list and the list items' do
            delete "/lists/#{@id}"
            get "/lists/#{@id}"
            expect(parsed["error_message"]).to eq('List does not exist')
            expect(last_response.status).to eq(404)
          end

          it 'returns a status 204 (no content)' do
            delete "/lists/#{@id}"
            expect(last_response.status).to eq(204)
          end
        end

        context 'when list does not exists' do
          it "doesn't delete any lists or items" do
            get "/lists"
            list_count = parsed['lists'].count
            delete '/lists/-1'
            get "/lists"
            new_list_count = parsed['lists'].count
            expect(list_count).to eq(new_list_count)
          end

          it 'returns a 422 (Unprocessable entity)' do
            delete '/lists/-1'
            expect(last_response.status).to eq(422)
          end
        end
      # end

      # context 'when user is not authorized to delete list' do
        # it 'Does Not delete any lists'

        # it 'returns a status 401 (unauthorized) and a helpful error message'
      # end
    end

    # Delete a list
    describe 'DELETE /list/:list_id/:item_id' do
      before do
        @list = List.create(name: 'books')
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
          expect(parsed['error_message']).to eq('Error - Item could not be deleted')
        end
      end
    end
  end
end