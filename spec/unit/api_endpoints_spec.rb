require_relative '../../app/api'
require 'rack/test'

module Todoable
  RSpec.describe 'API Endpoints' do
    include Rack::Test::Methods

    let(:ledger) { instance_double('Todoable::Ledger') }
    let(:email)  { 'asdf@asdf.com' }
    let(:password) { 'asdfasdf' }
    let(:token) { '7Xa8Im35hqUkldOp5ZxZJYuBJCqI9yQghvEumLjyXlZM1TjZEK2p1XOcuKt1kkQF83BSPVA2aIpW_bqsLyR0sg' }
    let(:get_list_response) do
      {
        lists: [
          {
            name: 'Urgent Things',
            src:  'http://todoable.teachable.tech/api/lists/1',
            id:  '1'
          }
        ]
      }
    end

    def app
      API.new(ledger: ledger)
    end

    before { create_token_header(token) }

    describe 'post /authenticate' do
      before { create_auth_header(email, password) }

      it 'returns a user id and token' do
        allow(ledger).to receive(:generate_token)
          .with(email, password)
          .and_return(RecordResult.new(true, { id: 1, token: token }, nil))

        post '/authenticate'
        expect(parsed_response).to eq(id: 1, token: token)
      end
    end

    describe 'get /lists' do
      it 'retrieves several lists' do
        allow(ledger).to receive(:retrieve)
          .with(token, nil)
          .and_return(RecordResult.new(true, get_list_response, nil))

        get '/lists'
        expect(parsed_response).to eq(get_list_response)
      end
    end

    describe 'get /lists/:list_id' do
      it 'retrieves a particular list' do
        allow(ledger).to receive(:retrieve)
          .with(token, '1')
          .and_return(RecordResult.new(true, get_list_response, nil))
        get '/lists/1'
        expect(parsed_response).to eq(get_list_response)
      end
    end

    describe 'post /lists' do
      it 'creates a new list' do
        dummy_list = { dummy: 'list' }
        allow(ledger).to receive(:create_list)
          .with(token, dummy_list)
          .and_return(RecordResult.new(true, { id: 2 }, nil))

        post '/lists', JSON.generate(dummy_list)
        expect(parsed_response).to eq(id: 2)
      end
    end

    describe 'post /lists/:list_id/items' do
      it 'creates a new item' do
        dummy_item = { dummy: 'item' }
        allow(ledger).to receive(:create_item)
          .with('1', token, dummy_item)
          .and_return(RecordResult.new(true, { id: 99 }, nil))

        post '/lists/1/items', JSON.generate(dummy_item)
        expect(parsed_response).to eq(id: 99)
      end
    end

    describe 'patch /lists/:list_id' do
      it 'updates a list' do
        new_list = { new_dummy: 'new list' }
        allow(ledger).to receive(:update_list)
          .with('1', token, new_list)
          .and_return(RecordResult.new(true, { name: 'new list' }, nil))

        patch '/lists/1', JSON.generate(new_list)
        expect(parsed_response).to eq(name: 'new list')
      end
    end

    describe 'delete /lists/:list_id' do
      it 'deletes a list' do
        allow(ledger).to receive(:delete_list)
          .with('1', token)
          .and_return(RecordResult.new(true, '', nil))

        delete '/lists/1'
        expect(last_response.status).to eq(204)
        expect(parsed_response).to eq('')
      end
    end

    describe 'put /lists/:list_id/items/:item_id/finish' do
      it 'marks an item as finished' do
        now = DateTime.now
        allow(ledger).to receive(:finish_item)
          .with('1', token, '99')
          .and_return(RecordResult.new(true, now, nil))

        put '/lists/1/items/99/finish'
        expect(parsed_response).to eq(now.to_s)
      end
    end

    describe 'delete /lists/:list_id/items/:item_id' do
      it 'deletes an item' do
        allow(ledger).to receive(:delete_item)
          .with('1', token, '99')
          .and_return(RecordResult.new(true, '', nil))

        delete '/lists/1/items/99'
        expect(last_response.status).to eq(204)
        expect(parsed_response).to eq('')
      end
    end
  end
end
