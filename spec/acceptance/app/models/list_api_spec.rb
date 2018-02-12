require 'rack/test'
require_relative '../../../../app/api'
require_relative '../../../../app/models/list'

module Todoable
  RSpec.describe 'List API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }

    let(:get_lists_response) do
      [
        {
          list: {
            id: 1,
            name: "Urgent Things",
            items: []
          }
        },
        {
          list: {
            id: 2,
            name: "Medium Priority",
            items: []
          }
        },
        {
          list: {
            id: 3,
            name: "Low Priority",
            items: []
          }
        }
      ]
    end

    before do
      create_token_header(user.token)
    end

    # Retrieves lists
    describe 'GET /lists' do
      context 'when NO lists exist' do
        it 'returns []' do
          get '/lists'
          expect(parsed_response[:lists]).to eq([])
        end
      end

      context 'when lists exist' do
        let(:urgent) { { name: 'Urgent Things' } }
        let(:medium) { { name: 'Medium Priority' } }
        let(:trivial){ { name: 'Low Priority' } }

        before do
          create_list(urgent, user.token)
          create_list(medium, user.token)
          create_list(trivial, user.token)
        end

        it 'returns all lists' do
          get '/lists'
          expect(parsed_response[:lists].count).to eq(3)
          expect(parsed_response[:lists]).to match(get_lists_response)
        end

        it 'Obeys correct format' do
          get '/lists'
          expect(parsed_response[:lists]).to match(get_lists_response)
        end
      end
    end

    # Retrieve a single list
    describe 'GET /lists/:list_id' do
      context 'when List exists' do
        it 'returns the list' do
          list = { name: 'important things' }
          id = create_list(list, user.token)
          get "lists/#{id}"
          expect(parsed_response).to match(
            list: {
              id: id,
              name: 'important things',
              items: []
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
          expect(parsed_response[:error_message]).to eq('List does not exist')
        end

        it 'returns a nil List' do
          get '/lists/-1'
          expect(parsed_response[:list]).to eq(nil)
        end
      end
    end

    # Create a list
    describe 'POST /lists' do
      context 'with valid data' do
        it 'returns the ID and list name' do
          list = { name: 'important things' }
          create_list(list, user.token)
          expect(parsed_response).to match( { id: a_kind_of(Integer) })
        end
      end

      context 'with Invalid data' do
        it 'rejects the list' do
          list = { this_is_invalid: 44 }
          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(422)
        end

        it 'provides a helpful message' do
          list = { name: '' }
          post '/lists', JSON.generate(list)
          expect(parsed_response[:error_message]).to eq('Error list could not be created')
        end
      end
    end

    # Update a list
    describe 'PATCH /lists/:list_id' do
      before do
        list = { name: 'to be updated' }
        @id = create_list(list, user.token)
      end

      context 'When request is valid (List exists & name is valid)' do
        it 'responds with a status code 201 (OK)' do
          patch "/lists/#{@id}", JSON.generate(name: 'Name has been updated')
          expect(last_response.status).to eq(201)
        end

        it 'Updates the list' do
          get "/lists/#{@id}"
          expect(parsed_response[:list][:name]).to eq('to be updated')
          create_token_header(user.token)
          patch "/lists/#{@id}", JSON.generate(name: 'Name has been updated')
          create_token_header(user.token)
          get "/lists/#{@id}"
          expect(parsed_response[:list][:name]).to eq('Name has been updated')
        end

        it 'Returns the new list once it has been updated' do
          patch '/lists/1', JSON.generate(name: 'Name has been updated')
          expect(parsed_response).to include({
            list: {
              id: a_kind_of(Integer),
              name: 'Name has been updated'
            }
          })
        end
      end

      context 'When request is Invalid (List doesnt exist, or name/items are invalid)' do
        it 'returns a helpful error message' do
          patch "/lists/#{@id}", JSON.generate(incorrect_name: [])
          expect(parsed_response[:error_message]).to eq('Error - list is not valid')
        end

        it 'responds with status code 422' do
          patch "/lists/#{@id}", JSON.generate(incorrect_name: [])
          expect(last_response.status).to eq(422)
        end

        it 'Does NOT update the list' do
          patch "/lists/#{@id}", JSON.generate(incorrect_name: [])
          create_token_header(user.token)
          get "/lists/#{@id}"
          expect(parsed_response).to include({
            list: {
              name: 'to be updated',
              id: @id,
              items: []
            }
          })
        end
      end
    end

    # Delete a list
    describe 'DELETE /lists/:list_id' do
      before do
        list = { name: 'to be deleted' }
        @id = create_list(list, user.token)
      end

      context 'when list exists' do
        it 'deletes the list and the list items' do
          delete "/lists/#{@id}"
          create_token_header(user.token)
          get "/lists/#{@id}"
          expect(parsed_response[:error_message]).to eq('List does not exist')
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
          list_count = parsed_response[:lists].count
          create_token_header(user.token)
          delete '/lists/-1'
          create_token_header(user.token)
          get "/lists"
          new_list_count = parsed_response[:lists].count
          expect(list_count).to eq(new_list_count)
        end

        it 'returns a 422 (Unprocessable entity)' do
          delete '/lists/-1'
          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end