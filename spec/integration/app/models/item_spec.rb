require_relative '../../../../app/models/item'
require_relative '../../../../app/models/list'

module Todoable
  RSpec.describe Item, :db do
    describe 'SQL associations' do
      # let(:list) { List.create(name: 'sports', user_id: 1) }
      # let(:item) { Item.create(name: 'hockey', list_id: list.id) }

      before do
        @list = List.create(name: 'sports', user_id: 1)
        @item = Item.new(name: 'hockey')
        @list.add_item(@item)
        # list.add_item(@item)
      end

      it 'has a "many_to_one" relationship with :list' do
        expect(@item.list_id).to eq(@list.id)
        expect(@list.items).to include(@item)
      end

      it 'can be retrieved by its list' do
        items = @list.items
        expect(items).to include(@item)
      end

      it 'can update its name' do
        @item.set(name: 'baseball')
        @item.save
        expect(@list.items.first.name).to eq('baseball')
      end

      it 'will be destroyed when its list is destroyed' do
        items_count = Item.count
        @list.destroy
        expect(Item.count).to eq(items_count - 1)
      end
    end
  end
end