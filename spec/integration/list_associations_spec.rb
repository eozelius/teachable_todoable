require_relative '../../app/models/user'
require_relative '../../app/models/list'
require_relative '../../app/models/item'

module Todoable
  RSpec.describe 'List SQL associations', :db do
    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }
    let(:goals) { List.new(name: 'Life Goals') }
    let(:yosemite) { Item.new(name: 'Yosemite') }
    let(:grand_canyon) { Item.new(name: 'Grand Canyon') }

    describe 'association with User' do
      it 'has a many_to_one relationship with User' do
        expect(user.lists).to eq([])
        user.add_list(goals)
        expect(user.lists).to include(goals)
        hobbies = List.new(name: 'hobbies')
        user.add_list(hobbies)
        expect(user.lists).to include(goals, hobbies)
      end
    end

    describe 'association with Item' do
      before { user.add_list(goals) }

      it 'has a one_to_many relationship with Item' do
        expect(goals.items).to eq([])
        goals.add_item(grand_canyon)
        goals.add_item(yosemite)
        expect(goals.items).to include(grand_canyon, yosemite)
      end

      it 'destroys associated items when List is destroyed' do
        item_count = Item.count
        goals.add_item(grand_canyon)
        goals.add_item(yosemite)
        expect(Item.count).to eq(item_count + 2)
        goals.destroy
        expect(Item.count).to eq(item_count)
        expect(Item.all).not_to include(yosemite)
      end
    end
  end
end
