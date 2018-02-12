require_relative '../../app/ledger'
require_relative '../../app/models/user'

module Todoable
  RSpec.describe Ledger, :db do
    let(:ledger) { Ledger.new }

    describe '#create_user(email, password) => creates a user' do
      context 'email & password are valid' do
        it 'returns new users id and token ' do
          created_user = ledger.create_user('asdf@asdf.com', 'asdfasdf')
          expect(created_user.success?).to eq(true)
          expect(created_user.response).to match({ id: a_kind_of(Integer),
                                                token: a_kind_of(String) })
        end
      end

      context 'email & password are invalid' do
        it 'rejects blank passwords' do
          created_user = ledger.create_user(nil, 'asdfasdf')
          expect(created_user.success?).to eq(false)
          expect(created_user.error_message).to eq('user could not be created')
        end
      end
    end

    describe '#generate_token(email, password) => returns a new token or creates a new user' do
      context 'user exists and email and password are valid' do
        it 'generates and returns a new token' do
          user = User.create(email: 'asdf@asdf.com', password: 'asdfasdf')
          generated_token = ledger.generate_token(user.email, 'asdfasdf')
          expect(generated_token.success?).to eq(true)
          expect(generated_token.response).to match({ token: a_kind_of(String) })
        end
      end

      context 'user exists, BUT email:password are invalid' do
        it 'returns "Invalid email/password combination"' do
          user = User.create(email: 'asdf@asdf.com', password: 'asdfasdf')
          generated_token = ledger.generate_token(user.email, 'these are not the droids your looking for')
          expect(generated_token.success?).to eq(false)
          expect(generated_token.error_message).to eq('Invalid e-mail/password combination')
        end

        it 'does not generate a new token for the existing user' do
          user = User.create(email: 'asdf@asdf.com', password: 'asdfasdf')
          user_token = user.token
          ledger.generate_token(user.email, 'these are not the droids your looking for')
          expect(user.token).to eq(user_token)
        end
      end

      context 'user does not exist, email:password are Invalid' do
        it 'does not create a new user' do
          user_count = User.count
          generated_token = ledger.generate_token('asdf_is not an email', 'asdfasdf')
          expect(generated_token.success?).to eq(false)
          expect(generated_token.error_message).to eq('user could not be created')
          expect(User.count).to eq(user_count)
        end
      end

      context 'user does not exist, email:password are Valid => create new user' do
        it 'creates a new user, returns id and token ' do
          user_count = User.count
          generated_token = ledger.generate_token('asdf@asdf.com', 'asdfasdf')
          expect(generated_token.success?).to eq(true)
          expect(generated_token.response).to match({ id: a_kind_of(Integer),
                                                      token: a_kind_of(String) })
          expect(User.count).to eq(user_count + 1)
        end
      end
    end

    describe 'List methods' do
      it 'fetch a single or set of list(s) => #retrieve(token, list_id)'
      it 'creates a list => #create_list(token, list)'
      it 'updates a list => #update_list(list_id, token, new_list)'
      it 'deletes a list => #delete_list(list_id, token'
    end


    describe 'Item methods' do
      it 'creates an item => #create_item(list_id, token, item)'
      it 'marks an item as finished => #finish_item(list_id,token, item_id)'
      it 'deletes an item => #delete_item(list_id, token, item_id'
    end



    # # Save a new List to DB
    # describe '#create_list' do
    #   context 'with a valid list' do
    #     it 'successfully saves the list in the DB' do
    #       result = ledger.create_list(user.token, list)
    #       expect(result.success?).to eq(true)
    #       expect(DB[:lists].all).to match [a_hash_including(
    #                                          id: a_kind_of(Integer),
    #                                          name: 'Ultra Important'
    #                                        )]
    #     end
    #   end
    #
    #   context 'with an invalid list' do
    #     it 'rejects the list as invalid' do
    #       list.delete(:name)
    #       result = ledger.create_list(user.token, list)
    #       expect(result.success?).to eq(false)
    #       expect(result.response).to eq(nil)
    #       expect(result.error_message).to eq('Error list could not be created')
    #       expect(DB[:lists].count).to eq(0)
    #     end
    #   end
    # end
    #
    # # Query a List from DB
    # describe '#retrieve' do
    #   before do
    #     ledger.create_list(user.token, { name: 'Utmost Importance' })
    #     ledger.create_list(user.token, { name: 'Mid Level Importance' })
    #     ledger.create_list(user.token, { name: 'Trivial Importance' })
    #   end
    #
    #   it 'returns ONE list when a list_id is provided' do
    #     result = ledger.retrieve(user.token, '1')
    #     response = result.response
    #
    #     expect(result).to match(a_kind_of(Todoable::RecordResult))
    #     expect(result.success?).to eq(true)
    #
    #     expect(response).to match(a_kind_of(Hash))
    #     expect(response[:list]).to match(a_kind_of(Hash))
    #     expect(response.count).to eq(1)
    #     expect(response[:list][:id].to_i).to match(a_kind_of(Integer))
    #     expect(response[:list][:name]).to match(a_kind_of(String))
    #   end
    #
    #   it 'retrieves ALL lists when NO list_id is provided' do
    #     retrieve = ledger.retrieve(user.token, nil)
    #     response = retrieve.response
    #     expect(retrieve).to match(a_kind_of(Todoable::RecordResult))
    #     expect(retrieve).to be_success
    #     expect(response).to match(a_kind_of(Hash))
    #     expect(response[:lists].count).to eq(3)
    #
    #   end
    #
    #   it 'returns an empty array when there are no matching lists' do
    #     retrieved_result = ledger.retrieve(user.token, -1)
    #     expect(retrieved_result).to match(a_kind_of(Todoable::RecordResult))
    #     expect(retrieved_result.response).to eq([])
    #     expect(retrieved_result.error_message).to eq('List does not exist')
    #   end
    # end
  end
end