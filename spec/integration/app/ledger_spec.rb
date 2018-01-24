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
  end
end