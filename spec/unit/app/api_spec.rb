require_relative '../../../app/api'
require 'rack/test'

module Todoable
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    let(:ledger) { instance_double('Todoable::Ledger') }

    # Retrieve a single list
    describe 'GET /lists/:list_id' do
      context 'when list with given id exists' do
        let(:list_id) { '42' }

        before do
          allow(ledger).to receive(:retrieve)
            .with(list_id)
            .and_return(RecordResult.new(true, 42, nil))
        end

        it 'returns the list as JSON' do
          get '/lists/42'
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('list_id' => 42)
        end

        it 'responds with 200' do
          get '/lists/42'
          expect(last_response.status).to eq(201)
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
          get '/lists/-1'
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('error' => 'List does not exist')
        end

        it 'responds with 404' do
          get '/lists/-1'
          expect(last_response.status).to eq(404)
        end
      end
    end

    # Creates a list
    describe 'POST /lists' do
      context 'when the list is successfully recorded' do
        let(:list) { { 'list_name' => 'dummy_data' } }

        before do
          allow(ledger).to receive(:record)
            .with(list)
            .and_return(RecordResult.new(true, 417, nil))
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
        let(:invalid_list) { { 'list_name' => '' } }

        before do
          allow(ledger).to receive(:record)
            .with(invalid_list)
            .and_return(RecordResult.new(false, 417, 'Error name cannot be blank'))
        end

        it 'returns a helpful error message' do
          post '/lists', JSON.generate(invalid_list)
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('error' => 'Error name cannot be blank')
        end
        it 'responds with a 422 (Unprocessable entity)' do
          post '/lists', JSON.generate(invalid_list)
          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end