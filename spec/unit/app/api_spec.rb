require_relative '../../../app/api'
require 'rack/test'

module Todoable
  RecordResult = Struct.new(:success?, :list_id, :error_message)

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    let(:ledger) { instance_double('Todoable::Ledger') }

    describe 'POST /lists' do
      context 'when the expense is successfully recorded' do
        it 'returns the list id' do
          list = { 'some' => 'dummy_data' }

          allow(ledger).to receive(:record)
            .with(list)
            .and_return(RecordResult.new(true, 417, nil))

          post '/lists', JSON.generate(list)
          parsed = JSON.parse(last_response.body)
          expect(parsed).to include('list_id' => 417)
        end

        it 'responds with a 201 (OK)' do
          list = { 'some' => 'dummy_data' }
          allow(ledger).to receive(:record)
            .with(list)
            .and_return(RecordResult.new(true, 417, nil))

          post '/lists', JSON.generate(list)
          expect(last_response.status).to eq(201)
        end
      end

      context 'when the expense fails validation' do
        it 'returns a helpful error message'
        it 'responds with a 422 (Unprocessable entity)'
      end
    end
  end
end