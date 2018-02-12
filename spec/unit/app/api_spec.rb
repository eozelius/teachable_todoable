require_relative '../../../app/api'
require_relative '../../../app/models/user'
require 'base64'
require 'rack/test'

module Todoable
  RSpec.describe API, :db do
    include Rack::Test::Methods
    let(:ledger) { instance_double('Todoable::Ledger') }
    let(:hard_coded_response) do
      {lists: [
        {
          name: "Urgent Things",
          src: "http://todoable.teachable.tech/api/lists/:list_id",
          id: ":list_id"
        }
      ]}
    end

    def app
      API.new(ledger: ledger)
    end

    before do
      token_header = "Token token=\"7Xa8Im35hqUkldOp5ZxZJYuBJCqI9yQghvEumLjyXlZM1TjZEK2p1XOcuKt1kkQF83BSPVA2aIpW_bqsLyR0sg\""
      header 'Authorization', token_header
    end

    # Retrieve a single list
    describe 'GET /lists/:list_id' do
      context 'when list with given id exists' do
        let(:list_id) { '42' }

        before do
          allow(ledger).to receive(:retrieve)
            .and_return(RecordResult.new(true, hard_coded_response, nil))
        end

        it 'returns the list as JSON' do
          get "/lists/#{list_id}"
          expect(parsed_response).to eq(hard_coded_response)
        end

        it 'responds with 200' do
          get "/lists/#{list_id}"
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the list with given id does Not exist' do
        let(:list_id) { '-1' }

        before do
          allow(ledger).to receive(:retrieve)
            .and_return(RecordResult.new(false, nil, 'List does not exist'))
        end

        it 'returns a helpful error message' do
          get "/lists/#{list_id}"
          expect(parsed_response).to match(
            a_hash_including(error_message: 'List does not exist')
          )
        end

        it 'responds with 404' do
          get "/lists/#{list_id}"
          expect(last_response.status).to eq(404)
        end
      end
    end

    # Creates a list
    describe 'POST /lists' do
      context 'when the list is successfully recorded' do
        let(:list) { JSON.generate(some: 'dummy_data') }
        let(:response) { { list_id: 417 } }

        before do
          allow(ledger).to receive(:create_list)
            .and_return(RecordResult.new(true, response, nil))
        end

        it 'returns the list id' do
          post '/lists', JSON.generate(list)
          expect(parsed_response).to include(list_id: 417)
        end

        it 'responds with a 201 (OK)' do
          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(201)
        end
      end

      context 'when the expense fails validation' do
        let(:invalid_list) { JSON.generate(list_name: 'dummy data') }

        before do
          allow(ledger).to receive(:create_list)
            .and_return(RecordResult.new(false, nil, 'Error name cannot be blank'))
        end

        it 'returns a helpful error message' do
          post '/lists', JSON.generate(invalid_list)
          expect(parsed_response).to include(error_message: 'Error name cannot be blank')
        end
        it 'responds with a 422 (Unprocessable entity)' do
          post '/lists', JSON.generate(invalid_list)
          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end