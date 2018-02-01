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
      expect(parsed).to include('list')
      parsed['list']['id'] ? parsed['list']['id'] : false
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
          pending 'fucking hate this shit'
          list = { 'name' => 'important things' }
          id = post_list(list)
          get "lists/#{id}"
          expect(parsed).to include(
                              'list' => {
                                'id' => id,
                                'name' => 'important things',
                                'src' => a_kind_of(String)
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
            'list' => { 'id' => a_kind_of(Integer) }
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
        list = { "name" => 'List - todo' }
        @id  = post_list(list)
      end

      let(:item) { { name: 'Item 1 - have fun' } }
      let(:invalid_list_id) { '9999999' }

      context 'with valid data' do
        it 'returns a 201 (OK) and the id' do
          post "/lists/#{@id}/items", JSON.generate(item)
          expect(last_response.status).to eq(201)
          expect(parsed['id']).to match(a_kind_of(Integer))
          # expect(parsed['name']).to eq(list)
          expect(parsed['name']).to eq('Item 1 - have fun')
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

      context 'with Invalid data' do
        context 'Invalid list_id' do
          it 'returns a 422 (Unprocessible entity)' do
            post "/lists/#{invalid_list_id}/items", JSON.generate(item)
            expect(last_response.status).to eq(422)
          end
        end

        context 'Invalid Item properties' do
          it 'returns a 422 (Unprocessible entity)' do
            post "/lists/#{@id}/items", JSON.generate(name: '')
            expect(last_response.status).to eq(422)
          end
        end

        it 'does not create any new items' do
          item_count = Item.count
          post "/lists/#{@id}/items", JSON.generate({ invalid_name_key: '' })
          expect(Item.count).to eq(item_count)
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
          pending 'need to implement src'
          patch "/lists/#{@id}", JSON.generate('incorrect_name' => [])
          get "/lists/#{@id}"
          expect(parsed).to include({
            'list' => {
              'name' => 'to be updated',
              'id' => @id,
              'src' => a_kind_of(String)
            }
          })
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

          it 'returns a status 201 (no content)' do
            delete "/lists/#{@id}"
            expect(last_response.status).to eq(201)
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
        end
      # end

      # context 'when user is not authorized to delete list' do
        # it 'Does Not delete any lists'

        # it 'returns a status 401 (unauthorized) and a helpful error message'
      # end
    end
  end
end