require_relative '../../app/models/list'
require_relative '../../app/models/item'

module Todoable
  RSpec.describe 'List SQL associations', :db do
    let(:goals) { List.create(name: 'Life Goals', user_id: 1) }
    let(:yosemite) { Item.new(name: 'Yosemite') }
    let(:grand_canyon) { Item.new(name: 'Grand Canyon') }

    describe 'association with List' do
      it 'has a many_to_one relationship with List' do
        expect(goals.items).to eq([])
        goals.add_item(yosemite)
        goals.add_item(grand_canyon)
        expect(goals.items).to include(grand_canyon, yosemite)
        expect(yosemite.list_id).to eq(goals.id)
      end
    end
  end
end
