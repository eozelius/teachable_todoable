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
          expect(result.error_message).to include('Error name cannot be blank')
          expect(DB[:lists].count).to eq(0)
        end
      end
    end

    # Query a List from DB
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

=begin
      # this extra test would ensure that the record that is retrieved contains the correct list_id as well as name
        [result_1, result_2, result_3].each do |r|
          expect(ledger.retrieve(r.list_id)).to match [
            a_hash_containing(
              id: r.list_id,
              name: r[:name]
            )
          ]
        end
      end
=end
      it 'returns an empty array when there are no matching lists' do
        expect(ledger.retrieve('-1')).to eq([])
      end
    end
  end
end