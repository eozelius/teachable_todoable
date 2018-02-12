require_relative '../../app/models/item'

module Todoable
  RSpec.describe Item do
    describe 'validates' do
      it 'name' do
        item = Item.new(name: nil, list_id: 1)
        expect(item.valid?).to eq(false)
        item.name = 'apples'
        expect(item.valid?).to eq(true)
      end

      it 'finished_at' do
        item = Item.new(name: 'oranges', finished_at: nil, list_id: 1)
        expect(item.valid?).to eq(true)
        item.finished_at = DateTime.now
        expect(item.valid?).to eq(true)
      end

      it 'list_id' do
        item = Item.new(name: 'golf', list_id: nil)
        expect(item.valid?).to eq(false)
        item.list_id = 1
        expect(item.valid?).to eq(true)
      end
    end
  end
end