require_relative '../../../../app/models/user'
require_relative '../../../../app/models/list'

module Todoable
  RSpec.describe User, :db do
    describe 'SQL associations' do
      # let(:token) { SecureRandom.urlsafe_base64(nil, false) }
      let(:grocery_list) { List.new(name: 'grocery store') }

      before do
        @user = User.create(
          email: 'asdf@asdf.com'
        )
        @user.add_list(grocery_list)
      end

      it 'has a "one_to_many" relationship with :lists', :db do
        expect(@user.lists.count).to eq(1)
        @hobbies = List.new(
          name: 'hobbies',
          src: 'asdfasdf'
        )
        @user.add_list(@hobbies)
        expect(@user.lists.count).to eq(2)
      end

      it 'can retrieve it\'s associated lists' do
        lists = @user.lists
        expect(lists).to include(grocery_list)
      end

      it 'can update its own list' do
        list = @user.lists.first
        list.name = 'updated - asdf'
        expect(@user.lists.first.name).to eq('updated - asdf')
      end

      it 'will destroy associated lists when User is destroyed' do
        list_count = List.count
        @user.destroy
        expect(List.count).to eq(list_count - 1)
      end

      it 'can add items to it\'s own lists' do
        apples = Item.create(name: 'apples', src: 'asdfasfd')
        @user.lists.first.add_item(apples)
        expect(@user.lists.first.items).to include(apples)
      end
    end
  end
end