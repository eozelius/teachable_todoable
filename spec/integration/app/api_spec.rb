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
      parsed = JSON.parse(last_response.body)
      expect(parsed).to include('list_id')
    end

    let(:parsed) { JSON.parse(last_response.body) }

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
          expect(parsed['lists']).to include(
            {"id"=>1, "name"=>"Urgent Things"},
            {"id"=>2, "name"=>"Medium Priority"},
            {"id"=>3, "name"=>"Low Priority"}
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

    describe 'POST /lists' do
      context 'with valid data' do
        it 'returns the list id' do
          list = {'name' => 'important things' }
          post_list(list)
          expect(parsed).to include('list_id' => a_kind_of(Integer))
        end
      end

      context 'with Invalid data' do
        it 'rejects the list' do
          list = { 'this_is_invalid' => 44 }
          post '/lists', JSON.generate(list)
          parsed = JSON.parse(last_response.body)
          expect(last_response.status).to eq(422)
          expect(parsed['error_message']).to eq('Error name cannot be blank')
        end
      end
    end
  end
end