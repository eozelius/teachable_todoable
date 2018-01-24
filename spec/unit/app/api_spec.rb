require_relative '../../../app/api'
require 'rack/test'

module Todoable
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    let(:ledger) { instance_double('Todoable::Ledger') }

    describe 'POST /lists' do
      context 'when the expense is successfully recorded' do
        let(:list) { { 'some' => 'dummy_data' } }

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
        let(:list) { { 'some' => 'dummy_data' } }

        before do
          allow(ledger).to receive(:record)
            .with(list)
            .and_return(RecordResult.new(false, 417, 'List Incomplete'))
        end

        it 'returns a helpful error message' do
          post '/lists', JSON.generate(list)
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('error' => 'List Incomplete')
        end
        it 'responds with a 422 (Unprocessable entity)' do
          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end