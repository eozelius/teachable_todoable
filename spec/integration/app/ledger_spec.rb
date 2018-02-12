require_relative '../../../app/ledger'
require_relative '../../../app/models/user'

module Todoable
  # Each example will be wrapped in a transaction via :db meta tag
  RSpec.describe Ledger, :db do
    let(:ledger) { Ledger.new }
    let(:list) { { name: 'Ultra Important' } }
    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }

    # Save a new List to DB
    describe '#create_list' do
      context 'with a valid list' do
        it 'successfully saves the list in the DB' do
          result = ledger.create_list(user.token, list)
          expect(result.success?).to eq(true)
          expect(DB[:lists].all).to match [a_hash_including(
            id: a_kind_of(Integer),
            name: 'Ultra Important'
          )]
        end
      end

      context 'with an invalid list' do
        it 'rejects the list as invalid' do
          list.delete(:name)
          result = ledger.create_list(user.token, list)
          expect(result.success?).to eq(false)
          expect(result.response).to eq(nil)
          expect(result.error_message).to eq('Error list could not be created')
          expect(DB[:lists].count).to eq(0)
        end
      end
    end

    # Query a List from DB
    describe '#retrieve' do
      before do
        ledger.create_list(user.token, { name: 'Utmost Importance' })
        ledger.create_list(user.token, { name: 'Mid Level Importance' })
        ledger.create_list(user.token, { name: 'Trivial Importance' })
      end

      it 'returns ONE list when a list_id is provided' do
        result = ledger.retrieve(user.token, '1')
        response = result.response

        expect(result).to match(a_kind_of(Todoable::RecordResult))
        expect(result.success?).to eq(true)

        expect(response).to match(a_kind_of(Hash))
        expect(response[:list]).to match(a_kind_of(Hash))
        expect(response.count).to eq(1)
        expect(response[:list][:id].to_i).to match(a_kind_of(Integer))
        expect(response[:list][:name]).to match(a_kind_of(String))
      end

      it 'retrieves ALL lists when NO list_id is provided' do
        retrieve = ledger.retrieve(user.token, nil)
        response = retrieve.response
        expect(retrieve).to match(a_kind_of(Todoable::RecordResult))
        expect(retrieve).to be_success
        expect(response).to match(a_kind_of(Hash))
        expect(response[:lists].count).to eq(3)

      end

      it 'returns an empty array when there are no matching lists' do
        retrieved_result = ledger.retrieve(user.token, -1)
        expect(retrieved_result).to match(a_kind_of(Todoable::RecordResult))
        expect(retrieved_result.response).to eq([])
        expect(retrieved_result.error_message).to eq('List does not exist')
      end
    end
  end
end