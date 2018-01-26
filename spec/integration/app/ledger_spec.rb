require_relative '../../../app/ledger'

module Todoable
  # Each example will be wrapped in a transaction via :db meta tag
  RSpec.describe Ledger, :db do
    let(:ledger) { Ledger.new }
    let(:list) { { 'name' => 'Ultra Important' } }

    # Save a new List to DB
    describe '#record' do
      context 'with a valid list' do
        it 'successfully saves the list in the DB' do
          result = ledger.record(list)
          expect(result).to be_success
          expect(DB[:lists].all).to match [a_hash_including(
            id: a_kind_of(Integer),
            name: 'Ultra Important'
          )]
        end
      end

      context 'with an invalid list' do
        it 'rejects the list as invalid' do
          list.delete('name')
          result = ledger.record(list)
          expect(result).not_to be_success
          expect(result.response).to eq(nil)
          expect(result.error_message).to eq('Error name cannot be blank')
          expect(DB[:lists].count).to eq(0)
        end
      end
    end

    # Query a List from DB
    describe '#retrieve' do
      before do
        ledger.record({ 'name' => 'Utmost Importance' })
        ledger.record({ 'name' => 'Mid Level Importance' })
        ledger.record({ 'name' => 'Trivial Importance' })
      end

      it 'returns ONE list when a list_id is provided' do
        # {
        #   "list": {
        #     "name": "Urgent Things",
        #     "items": [
        #       {
        #         "name":         "Feed the cat",
        #         "finished_at":  null,
        #         "src":          "http://todoable.teachable.tech/api/lists/:list_id/items/:item_id",
        #         "id":          ":item_id"
        #       },
        #       {
        #         "name":        "Get cat food",
        #         "finished_at":  null,
        #         "src":          "http://todoable.teachable.tech/api/lists/:list_id/items/:item_id",
        #         "id":          ":item_id"
        #       },
        #     ]
        #   }, {...}
        # }

        # ACTUAL
        # {
        #   :list => {
        #     :id=>1,
        #     :name=>"Utmost Importance"
        #   }
        # }

        retrieve = ledger.retrieve('1')
        response = retrieve.response

        expect(retrieve).to match(a_kind_of(Todoable::RecordResult))
        expect(retrieve).to be_success

        expect(response).to match(a_kind_of(Hash))
        expect(response[:list]).to match(a_kind_of(Hash))
        expect(response.count).to eq(1)
        expect(response[:list][:id].to_i).to match(a_kind_of(Integer))
        expect(response[:list][:name]).to match(a_kind_of(String))
      end

      it 'retrieves ALL lists when NO list_id is provided' do
        retrieve = ledger.retrieve
        response = retrieve.response
        expect(retrieve).to match(a_kind_of(Todoable::RecordResult))
        expect(retrieve).to be_success

        expect(response).to match(a_kind_of(Hash))
        expect(response["lists"].count).to eq(3)

      end

      it 'returns an empty array when there are no matching lists' do
        retrieved_result = ledger.retrieve(-1)
        expect(retrieved_result).to match(a_kind_of(Todoable::RecordResult))
        expect(retrieved_result.response).to eq([])
        expect(retrieved_result.error_message).to eq('List does not exist')
      end
    end
  end
end