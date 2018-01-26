require_relative '../../../app/ledger'

module Todoable
  # Each example will be wrapped in a transaction via :db meta tag
  RSpec.describe Ledger, :db do
    # include Rack::Test::Methods
    # def app
    #   Todoable::API.new
    # end

    let(:ledger) { Ledger.new }
    let(:list) { { 'name' => 'Ultra Important' } }

    # Save a new List to DB
    describe '#record' do
      context 'with a valid list' do
        it 'successfully saves the list in the DB' do
          result = ledger.record(list)
          expect(result).to be_success
          expect(DB[:lists].all).to match [a_hash_including(
            id: result.response['list_id'],
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
      it 'retrieves the list with the requested list_id' do
        result_1 = ledger.record({ 'name' => 'Utmost Importance' })
        result_2 = ledger.record({ 'name' => 'Mid Level Importance' })
        result_3 = ledger.record({ 'name' => 'Trivial Importance' })

        [result_1, result_2, result_3].each do |r|
          retrieved_result = ledger.retrieve(r.response['list_id'])
          # <struct Todoable::RecordResult :success?=true, response={:list=>{:id=>1, :name=>"Utmost Importance"}}, error_message=nil>
          expect(retrieved_result).to match(a_kind_of(Todoable::RecordResult))
          expect(retrieved_result).to be_success

          expect(retrieved_result.response).to match(a_kind_of(Hash))
          expect(retrieved_result.response[:list]).to match(a_kind_of(Hash))
          expect(retrieved_result.response[:list][:id].to_i).to match(a_kind_of(Integer))
          expect(retrieved_result.response[:list][:name]).to match(a_kind_of(String))
        end
      end

      it 'returns an empty array when there are no matching lists' do
        retrieved_result = ledger.retrieve(-1)
        expect(retrieved_result).to match(a_kind_of(Todoable::RecordResult))
        expect(retrieved_result.response).to eq(nil)
        expect(retrieved_result.error_message).to eq('List does not exist')
      end
    end

    # Update a List Name
=begin
    describe '#update_list' do
      it 'updates the list name, with the requested list_id' do
        result = ledger.record({ 'name' => 'name WILL be updated' })
        # retrieve = ledger.retrieve(result.list_id)
        # [{:id=>1, :name=>"name needs to be updated"}]

        patch "/lists/#{result.list_id}", { 'name' => 'name SUCCESSFULLY updated' }
        retrieve = ledger.retrieve(result.list_id)

        expect(retrieve).to contain_exactly(
          a_hash_including(
            id: result.list_id,
            name: 'name has been updated'
          )
        )
      end
    end
=end
  end
end