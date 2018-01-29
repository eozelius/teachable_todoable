require_relative '../../../app/api'
require 'rack/test'

module Todoable
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    let(:hard_coded_response) do
      {'lists' => [
        {
          "name" => "Urgent Things",
          "src" =>  "http://todoable.teachable.tech/api/lists/:list_id",
          "id" =>  ":list_id"
        }
      ]}
    end


    let(:ledger) { instance_double('Todoable::Ledger') }

    # Retrieve a single list
    describe 'GET /lists/:list_id' do
      context 'when list with given id exists' do
        let(:list_id) { '42' }

        before do
          allow(ledger).to receive(:retrieve)
            .with(list_id)
            .and_return(RecordResult.new(true, hard_coded_response, nil))
        end

        it 'returns the list as JSON' do
          get "/lists/#{list_id}"
          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq(hard_coded_response)
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
            .with(list_id)
            .and_return(RecordResult.new(false, nil, 'List does not exist'))
        end

        it 'returns a helpful error message' do
          get "/lists/#{list_id}"
          parsed = JSON.parse(last_response.body)
          expect(parsed).to match(
            a_hash_including('error_message' => 'List does not exist')
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
        let(:list) { { 'some' => 'dummy_data' } }
        let(:response) { { 'list_id' => 417 } }

        before do
          allow(ledger).to receive(:record)
            .with(list)
            .and_return(RecordResult.new(true, response, nil))
        end

        it 'returns the list id' do
          post '/lists', JSON.generate(list)
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('list_id' => 417)
        end

        it 'responds with a 201 (OK)' do
          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(201)
        end
      end

      context 'when the expense fails validation' do
        let(:invalid_list) { { 'list_name' => 'dummy data' } }

        before do
          allow(ledger).to receive(:record)
            .with(invalid_list)
            .and_return(RecordResult.new(false, nil, 'Error name cannot be blank'))
        end

        it 'returns a helpful error message' do
          post '/lists', JSON.generate(invalid_list)
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('error_message' => 'Error name cannot be blank')
        end
        it 'responds with a 422 (Unprocessable entity)' do
          post '/lists', JSON.generate(invalid_list)
          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end