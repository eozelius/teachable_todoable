require_relative '../../../app/ledger'
require_relative '../../../config/sequel'

module Todoable
  RSpec.describe Ledger, :db do
    let(:ledger) { Ledger.new }
    let(:list) do
      {
        'name' => 'Ultra Important'
      }
    end

    describe '#record' do
      context 'with a valid list' do
        it 'successfully saves the list in the DB' do
          result = ledger.record(list)
          expect(result).to be_success
          expect(DB[:lists].all).to match [a_hash_including(
            id: result.list_id,
            name: 'Ultra Important'
          )]
        end
      end

      context 'with an invalid list' do
        it 'rejects the list as invalid' do
          list.delete('name')
          result = ledger.record(list)
          expect(result).not_to be_success
          expect(result.list_id).to eq(nil)
          expect(result.error_message).to include('Invalid list: `name is required`')
          expect(DB[:lists].count).to eq(0)
        end
      end
    end

    describe '#retrieve' do
      it 'retrieves the list with the requested list_id' do
        result_1 = ledger.record({ 'name' => 'Utmost Importance' })
        result_2 = ledger.record({ 'name' => 'Mid Level Importance' })
        result_3 = ledger.record({ 'name' => 'Trivial Importance' })

        [result_1, result_2, result_3].each do |r|
          expect(ledger.retrieve(r.list_id)).to contain_exactly(
            a_hash_including(id: r.list_id)
          )
        end
      end

      it 'returns an empty array when there are no matching lists' do
        expect(ledger.retrieve('-1')).to eq([])
      end
    end
  end
end