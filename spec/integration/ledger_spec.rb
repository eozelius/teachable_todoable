require_relative '../../app/ledger'
require_relative '../../app/models/user'
require_relative '../../app/models/list'
require_relative '../../app/models/item'

module Todoable
  RSpec.describe Ledger, :db do
    before do
      @ledger = Ledger.new
      @user = User.create(email: 'asdf@adsf.com', password: 'asdfasdf')
      @bucket_list  = @user.add_list(name: 'Bucket List')
      @grand_canyon = @bucket_list.add_item(name: 'visit grand canyon')
    end

    describe 'User integration methods' do
      describe '#create_user(email, password)' do
        context 'email & password are valid' do
          it 'returns new users id and token ' do
            created_user = @ledger.create_user('qwerty@qwerty.com', 'qwerty')
            expect(created_user.success?).to eq(true)
            expect(created_user.response).to match(id: a_kind_of(Integer),
                                                   token: a_kind_of(String))
          end
        end

        context 'email & password are invalid' do
          it 'rejects blank passwords' do
            created_user = @ledger.create_user(nil, 'asdfasdf')
            expect(created_user.success?).to eq(false)
            expect(created_user.error_message).to eq('user could not be created')
          end
        end
      end

      describe '#generate_token(email, password) => returns a new token or creates a new user' do
        context 'user exists and email and password are valid' do
          it 'generates and returns a new token' do
            generated_token = @ledger.generate_token(@user.email, 'asdfasdf')
            expect(generated_token.success?).to eq(true)
            expect(generated_token.response).to match(token: a_kind_of(String))
          end
        end

        context 'user exists, BUT email:password are invalid' do
          it 'returns "Invalid email/password combination"' do
            generated_token = @ledger.generate_token(@user.email, 'these is not the password youre looking for')
            expect(generated_token.success?).to eq(false)
            expect(generated_token.error_message).to eq('Invalid e-mail/password combination')
          end

          it 'does not generate a new token for the existing user' do
            user_token = @user.token
            @ledger.generate_token(@user.email, 'these is not the password youre looking for')
            expect(@user.token).to eq(user_token)
          end
        end

        context 'user does not exist, email:password are Invalid' do
          it 'does not create a new user' do
            user_count = User.count
            generated_token = @ledger.generate_token('asdf_is not an email', 'asdfasdf')
            expect(generated_token.success?).to eq(false)
            expect(generated_token.error_message).to eq('user could not be created')
            expect(User.count).to eq(user_count)
          end
        end

        context 'user does not exist, email:password are Valid => create new user' do
          it 'creates a new user, returns id and token ' do
            user_count = User.count
            generated_token = @ledger.generate_token('asdf@asdf.com', 'asdfasdf')
            expect(generated_token.success?).to eq(true)
            expect(generated_token.response).to match(id: a_kind_of(Integer),
                                                      token: a_kind_of(String))
            expect(User.count).to eq(user_count + 1)
          end
        end
      end
    end

    describe 'List integration methods' do
      describe '#retrieve(token, list_id) => fetch a single or set of list(s)' do
        context 'token and list_id are valid' do
          it 'returns a single list' do
            retrieved_list = @ledger.retrieve(@user.token, @bucket_list.id)
            expect(retrieved_list.success?).to eq(true)
            expect(retrieved_list.response).to match(list: { id: 1,
                                                             name: 'Bucket List',
                                                             items: [{ id: 1,
                                                                       name: 'visit grand canyon',
                                                                       finished_at: nil }] })
          end

          it 'returns a set of lists' do
            @user.add_list(name: 'hobbies')
            retrieved_lists = @ledger.retrieve(@user.token, nil)
            expect(retrieved_lists.success?).to eq(true)
            expect(retrieved_lists.response).to match(lists:                                                          [{ list: { id: 1, name: 'Bucket List', items: [{ id: 1,
                                                                                                                                                                       name: 'visit grand canyon',
                                                                                                                                                                       finished_at: nil }] } },
                                                                                                                       { list: { id: 2, name: 'hobbies', items: [] } }])
          end

          it 'returns only the lists that are associated with token' do
            hobbies = @user.add_list(name: 'hobbies')
            retrieved_list = @ledger.retrieve(@user.token, hobbies.id)
            expect(retrieved_list.success?).to eq(true)
            expect(retrieved_list.response).to match(list:                                                         { id: 2,
                                                                                                                     name: 'hobbies',
                                                                                                                     items: [] })
          end
        end

        context 'token or list_id are invalid' do
          it 'returns an error if the token is invalid' do
            retrieved_list = @ledger.retrieve('invalid token', @bucket_list.id)
            expect(retrieved_list.success?).to eq(false)
            expect(retrieved_list.error_message).to eq('Invalid Token')
          end

          it 'returns [] and an error message if list does not exist' do
            retrieved_list = @ledger.retrieve(@user.token, 'invalid token')
            expect(retrieved_list.success?).to eq(false)
            expect(retrieved_list.error_message).to eq('List does not exist')
          end
        end
      end

      describe '#create_list(token, list)' do
        context 'token and list are valid' do
          let(:books) { { name: 'books to read' } }

          it 'creates a new list' do
            list_count = List.count
            created_list = @ledger.create_list(@user.token, books)
            expect(created_list.success?).to eq(true)
            expect(List.count).to eq(list_count + 1)
          end

          it 'returns the list id' do
            created_list = @ledger.create_list(@user.token, books)
            expect(created_list.response).to match(id: a_kind_of(Integer))
          end

          it 'associates the list with the user' do
            created_list = @ledger.create_list(@user.token, books)
            created_list_id = created_list.response[:id]
            expect(@user.lists.last.id).to eq(created_list_id)
          end
        end

        context 'token or list are invalid' do
          let(:movies) { { name: 'movies to watch - this list will not be created :)' } }

          it 'Does Not create a new list' do
            list_count = List.count
            created_list = @ledger.create_list('invalid token', @movies)
            expect(created_list.success?).to eq(false)
            expect(created_list.error_message).to eq('Invalid Token')
            expect(List.count).to eq(list_count)
          end

          it 'returns a helpful error' do
            created_list = @ledger.create_list(@user.token, name: nil)
            expect(created_list.success?).to eq(false)
            expect(created_list.error_message).to eq('Error list could not be created')
          end
        end
      end

      describe '#update_list(list_id, token, new_list) => updates a list' do
        context 'list_id, token, new_list are valid' do
          let(:new_bucket_list) { { name: 'revised for a longer life bucket list' } }

          it 'updates the users list' do
            updated_list = @ledger.update_list(@bucket_list.id, @user.token, new_bucket_list)
            expect(updated_list.success?).to eq(true)
            @bucket_list.reload
            expect(@bucket_list.name).to eq(new_bucket_list[:name])
          end

          it 'returns the id and new name' do
            updated_list = @ledger.update_list(@bucket_list.id, @user.token, new_bucket_list)
            expect(updated_list.success?).to eq(true)
            expect(updated_list.response).to match(list:                                                        { id: 1,
                                                                                                                  name: new_bucket_list[:name] })
          end
        end

        context 'list_id, token, or new_list are invalid' do
          it 'rejects invalid list ids' do
            updated_list = @ledger.update_list(0, @user.token, name: 'valid new name')
            expect(updated_list.success?).to eq(false)
            expect(updated_list.error_message).to eq('List does not exist')
          end

          it 'rejects invalid tokens' do
            updated_list = @ledger.update_list(@bucket_list.id, 'invalid user token', name: 'valid new name')
            expect(updated_list.success?).to eq(false)
            expect(updated_list.error_message).to eq('Invalid Token')
          end

          it 'rejects invalid updated properties' do
            updated_list = @ledger.update_list(@bucket_list.id, @user.token, name: nil)
            expect(updated_list.success?).to eq(false)
            expect(updated_list.error_message).to eq('Error - list is not valid')
          end
        end
      end

      describe '#delete_list(list_id, token) => deletes a list' do
        context 'list_id and token are valid' do
          it 'deletes the list' do
            deleted_list = @ledger.delete_list(@bucket_list.id, @user.token)
            expect(deleted_list.success?).to eq(true)
            expect(@user.lists).to eq([])
          end

          it 'deletes the list items' do
            item_count = Item.count
            deleted_list = @ledger.delete_list(@bucket_list.id, @user.token)
            expect(Item.count).to eq(item_count - 1)
          end
        end

        context 'list_id or token are invalid' do
          it 'rejects invalid list_ids' do
            deleted_list = @ledger.delete_list('invalid list_id', @user.token)
            expect(deleted_list.success?).to eq(false)
            expect(@user.lists.last.id).to eq(@bucket_list.id)
          end

          it 'does not delete anything, unless the list belongs to the correct user' do
            user_2 = User.create(email: 'qwerty@qwerty.com', password: 'qwerty')
            deleted_list = @ledger.delete_list(@bucket_list.id, user_2.token)
            expect(deleted_list.success?).to eq(false)
            expect(@user.lists.last.name).to eq('Bucket List')
          end

          it 'rejects invalid tokens' do
            deleted_list = @ledger.delete_list(@bucket_list.id, 'invalid token')
            expect(deleted_list.success?).to eq(false)
            expect(List.find(@bucket_list.id)).not_to eq([])
          end
        end
      end
    end

    describe 'Item integration methods' do
      describe '#create_item(list_id, token, item)' do
        let(:yosemite) { { name: 'visit yosemite national park' } }

        context 'list_id, token and item are valid' do
          it 'creates a new list' do
            item_count = Item.count
            created_list = @ledger.create_item(@bucket_list.id, @user.token, yosemite)
            expect(created_list.success?).to eq(true)
            expect(Item.count).to eq(item_count + 1)
          end

          it 'associates the new item with the given' do
            created_list = @ledger.create_item(@bucket_list.id, @user.token, yosemite)
            expect(created_list.success?).to eq(true)
            expect(@bucket_list.items.last.name).to eq(yosemite[:name])
          end
        end

        context 'list_id, token or item are invalid' do
          it 'rejects invalid list_id' do
            created_list = @ledger.create_item('invalid list id', @user.token, yosemite)
            expect(created_list.success?).to eq(false)
            expect(created_list.error_message).to eq('List does not exist')
          end

          it 'rejects invalid tokens' do
            created_list = @ledger.create_item(@bucket_list.id, 'invalid user token', yosemite)
            expect(created_list.success?).to eq(false)
            expect(created_list.error_message).to eq('Invalid Token')
          end

          it 'rejects invalid items' do
            created_list = @ledger.create_item(@bucket_list.id, @user.token, name: nil)
            expect(created_list.success?).to eq(false)
            expect(created_list.error_message).to eq('Item could not be created')
          end
        end
      end

      describe '#finish_item(list_id,token, item_id)' do
        context 'valid list_id, token and item_id' do
          it 'marks the item as finished' do
            expect(@grand_canyon.finished_at).to eq(nil)
            finished_item = @ledger.finish_item(@bucket_list.id, @user.token, @grand_canyon.id)
            expect(finished_item.success?).to eq(true)
            @grand_canyon.reload
            expect(@grand_canyon.finished_at).to match(a_kind_of(Time))
          end

          it 'marks the item as incomplete if it was already marked finished' do
            yosemite = @bucket_list.add_item(name: 'visit yosemite national park', finished_at: DateTime.now)
            expect(yosemite.finished_at).to match(a_kind_of(Time))
            finished_item = @ledger.finish_item(@bucket_list.id, @user.token, yosemite.id)
            expect(finished_item.success?).to eq(true)
            yosemite.reload
            expect(yosemite.finished_at).to eq(nil)
          end
        end

        context 'list_id, token or item_id are invalid' do
          it 'rejects invalid list_ids' do
            finished_item = @ledger.finish_item('invalid list id', @user.token, @grand_canyon.id)
            expect(finished_item.success?).to eq(false)
            expect(@grand_canyon.finished_at).to eq(nil)
          end

          it 'rejects invalid tokens' do
            finished_item = @ledger.finish_item(@bucket_list.id, 'invalid token', @grand_canyon.id)
            expect(finished_item.success?).to eq(false)
            expect(finished_item.error_message).to eq('Invalid Token')
            expect(@grand_canyon.finished_at).to eq(nil)
          end

          it 'rejects invalid item_ids' do
            finished_item = @ledger.finish_item(@bucket_list.id, @user.token, 'invalid item id')
            expect(finished_item.success?).to eq(false)
            expect(finished_item.error_message).to eq('Item does not exist')
            expect(@grand_canyon.finished_at).to eq(nil)
          end
        end
      end

      describe '#delete_item(list_id, token, item_id)' do
        context 'valid list_id, token and item_id' do
          it 'deletes the item' do
            deleted_item = @ledger.delete_item(@bucket_list.id, @user.token, @grand_canyon.id)
            expect(deleted_item.success?).to eq(true)
            expect(deleted_item.response).to eq('Item successfully deleted')
            expect(Item.find(@grand_canyon.id)).to eq([])
          end
        end

        context 'invalid list_id, token or item_id' do
          it 'rejects invalid list_ids' do
            deleted_item = @ledger.delete_item('invalid list id', @user.token, @grand_canyon.id)
            expect(deleted_item.success?).to eq(false)
            expect(deleted_item.error_message).to eq('List does not exist')
          end

          it 'rejects invalid tokens' do
            deleted_item = @ledger.delete_item(@bucket_list.id, nil, @grand_canyon.id)
            expect(deleted_item.success?).to eq(false)
            expect(deleted_item.error_message).to eq('Invalid Token')
          end

          it 'rejects invalid item_ids' do
            deleted_item = @ledger.delete_item(@bucket_list.id, @user.token, 0)
            expect(deleted_item.success?).to eq(false)
            expect(deleted_item.error_message).to eq('Item does not exist')
          end
        end
      end
    end
  end
end
