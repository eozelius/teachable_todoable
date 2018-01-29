require_relative '../../../../app/models/list'
require_relative '../../../../app/models/user'
require_relative '../../../../app/models/item'

module Todoable
  RSpec.describe List, :db do
    describe 'SQL associations' do
      let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf', token: SecureRandom.urlsafe_base64(nil, false)) }

      before do
        @list = List.create(
          name: 'fruits and vegetables',
          user_id: 1
        )
        @grapes = Item.create(name: 'grapes')
        @list.add_item(@grapes)
        user.add_list(@list)
      end

      it 'has a "many_to_one" relationship with :user' do
        expect(@list.user_id).to eq(user.id)
        expect(user.lists).to include(@list)
      end

      it 'has a "one_to_many" relationship with :items' do
        grapes = Item.create(name: 'grapes')
        @list.add_item(grapes)
        expect(@list.items).to include(grapes)
      end

      it 'can retrieve its associated items' do
        items = @list.items
        expect(items).to include(@grapes)
      end

      it 'can update its own items' do
        item = @list.items.first
        item.name = 'updated - asdf'
        expect(@list.items.first.name).to eq('updated - asdf')
      end

      it 'will not save an Invalid item' do
        pending 'figure out how to expect that an exception will be raised'
        rotten_tomato = Item.new(name: nil)
        expect(rotten_tomato.valid?).to eq(false)
        @list.add_item(rotten_tomato)
      end

      it 'will destroy associated items when List is destroyed' do
        items_count = Item.count
        @list.destroy
        expect(Item.count).to eq(items_count - 1)
      end

      it 'will be destroyed when its user is destroyed' do
        list_count = List.count
        user.destroy
        expect(List.count).to eq(list_count - 1)
      end
    end
  end
end