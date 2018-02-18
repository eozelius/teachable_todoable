require 'rack/test'
require 'json'
require_relative '../../app/api'
require_relative '../../app/models/list'

module Todoable
  RSpec.describe 'List API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end

    before do
      @user = User.create(email: 'asdf@adsf.com', password: 'asdfasdf')
      create_token_header(@user.token)
    end

    describe 'get /lists => fetch all lists that belong to user' do
      it 'returns [] if NO lists exist' do
        get '/lists'
        expect(parsed_response[:lists]).to eq([])
      end

      it 'returns lists' do
        urgent = { name: 'Urgent Things' }
        medium = { name: 'Medium Priority' }
        trivial = { name: 'Low Priority' }

        create_list(urgent, @user.token)
        create_list(medium, @user.token)
        create_list(trivial, @user.token)

        get '/lists'
        expect(parsed_response[:lists]).to match([ {:list=>{:id=>1, :name=>"Urgent Things", :items=>[]}},
                                                   {:list=>{:id=>2, :name=>"Medium Priority", :items=>[]}},
                                                   {:list=>{:id=>3, :name=>"Low Priority", :items=>[]}} ])
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
      before { @bucket_list = @user.add_list(name: 'Original Bucket List') }

      context 'Valid request (List exists & name is valid)' do
        it 'responds with a status code 201 (OK)' do
          patch "/lists/#{@bucket_list.id}", JSON.generate(name: 'Name has been updated')
          expect(last_response.status).to eq(201)
        end

        it 'Updates the list' do
          patch "/lists/#{@bucket_list.id}", JSON.generate(name: 'Updated!!!')
          get "/lists/#{@bucket_list.id}"
          expect(parsed_response[:list][:name]).to eq('Updated!!!')
        end

        it 'Returns the new list once it has been updated' do
          patch "/lists/#{@bucket_list.id}", JSON.generate(name: 'Updated!!!')
          expect(parsed_response).to include({ list: {
            id: a_kind_of(Integer),
            name: 'Updated!!!' }} )
        end
      end

      context 'Invalid Request (List doesnt exist, or name/items are invalid)' do
        it 'rejects request without a list name, with a 422 and a helpful message' do
          patch "/lists/#{@bucket_list.id}", JSON.generate({})
          expect(last_response.status).to eq(422)
          expect(parsed_response[:error_message]).to eq('List is required')
        end

        it 'Does NOT update the list' do
          patch "/lists/#{@bucket_list.id}", JSON.generate(name: '')
          get "/lists/#{@bucket_list.id}"
          expect(parsed_response).to include({ list: {
            name: @bucket_list.name,
            id: @bucket_list.id,
            items: [] } })
        end
      end
    end

    describe 'delete /lists/:list_id' do
      context 'when list exists' do
        before do
          @delete_list = @user.add_list(name: 'to be deleted')
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
end
