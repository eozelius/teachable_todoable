require 'json'
require 'rack/test'
require_relative '../../../app/api'


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
    end

    def parsed
      JSON.parse(last_response.body)
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
        before do
          urgent  = { 'name' => 'Urgent Things' }
          medium  = { 'name' => 'Medium Priority' }
          trivial = { 'name' => 'Low Priority' }

          post_list(urgent)
          post_list(medium)
          post_list(trivial)
        end

        it 'returns all lists' do
          get '/lists'
          expect(parsed['lists'].count).to eq(3)
          expect(parsed['lists']).to include(
            { 'id' => 1, "name" => "Urgent Things" },
            { 'id' => 2, "name" => "Medium Priority" },
            { 'id' => 3, "name" => "Low Priority" }
          )
        end

        it 'Obeys correct format' do
          get '/lists'
          expect(parsed['lists']).to include(
            a_hash_including(
              'id' => a_kind_of(Integer),
              'name' => a_kind_of(String),
            )
          )
        end
      end
    end

    # Create a list
    describe 'POST /lists' do
      context 'with valid data' do
        it 'returns the ID and list name' do
          list = { 'name' => 'important things' }
          post_list(list)
          expect(parsed).to include('list' => {
            'name' => 'important things',
            'id' => a_kind_of(Integer)
          })
        end
      end

      context 'with Invalid data' do
        it 'rejects the list' do
          list = { 'this_is_invalid' => 44 }
          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(422)
          expect(parsed['error_message']).to eq('Error name cannot be blank')
        end
      end
    end

    # Retrieve a single list
    describe 'GET /lists/:list_id' do
      context 'when List exists' do
        it 'returns the list' do
          list = { 'name' => 'important things' }
          post_list(list)
          get 'lists/1'
          expect(parsed).to include('list' => {
            'id' => 1,
            'name' => 'important things'
          })
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

    # Update a list
    describe 'PATCH /lists/:list_id' do
      before do
        list = { 'name' => 'to be updated' }
        post_list(list)
      end

      context 'When request is valid (List exists & name is valid)' do
        it 'responds with a status code 201 (OK)' do
          patch '/lists/1', JSON.generate('name' => 'Name has been updated')
          expect(last_response.status).to eq(201)
        end

        it 'Updates the list' do
          get '/lists/1'
          expect(parsed['list']['name']).to eq('to be updated')
          patch '/lists/1', JSON.generate('name' => 'Name has been updated')
          get '/lists/1'
          expect(parsed['list']['name']).to eq('Name has been updated')
        end

        it 'Returns the new list once it has been updated' do
          patch '/lists/1', JSON.generate('name' => 'Name has been updated')
          expect(parsed).to include({
            "list" => {
              "name" => "Name has been updated"
            }
          })
        end
      end

      context 'When request is Invalid (List doesnt exist, or name/items are invalid)' do
        it 'returns a helpful error message' do
          patch '/lists/1', JSON.generate('incorrect_name' => [])
          expect(parsed['error_message']).to eq('Error - must provide a valid id and name')
        end

        it 'responds with status code 422' do
          patch '/lists/1', JSON.generate('incorrect_name' => [])
          expect(last_response.status).to eq(422)
        end

        it 'Does NOT update the list' do
          patch '/lists/1', JSON.generate('incorrect_name' => [])
          get '/lists/1'
          expect(parsed).to include({
            'list' => {
              'name' => 'to be updated',
              'id' => 1
            }
          })
        end
      end
    end

    # Delete a list
    describe 'DELETE /lists/:list_id' do
      # context 'when user is authorized to delete list' do
        context 'when list exists' do
          it 'deletes the list and the list items' do
            list = { 'name' => 'to be deleted' }
            post_list(list)
            delete '/lists/1'
            get '/lists/1'
            expect(parsed["error_message"]).to eq('List does not exist')
            expect(last_response.status).to eq(404)
          end

          it 'returns a status 201 (no content)'
        end

        context 'when list does not exists' do
          it 'doesn\'t delete any lists or items'
        end
      # end

      # context 'when user is not authorized to delete list' do
        # it 'Does Not delete any lists'

        # it 'returns a status 401 (unauthorized) and a helpful error message'
      # end
    end
  end
end