require_relative '../../../../app/models/item'

module Todoable
  RSpec.describe Item do
    it 'should have a name' do
      item = Item.new(name: nil, finished_at: DateTime.now)
      expect(item.valid?).to eq(false)
      item.name = 'apples'
      expect(item.valid?).to eq(true)
    end

    it 'should have a "finished_at" attr' do
      item = Item.new(name: 'oranges', finished_at: nil)
      expect(item.valid?).to eq(true)
      item.finished_at = DateTime.now
      expect(item.valid?).to eq(true)
    end
  end
end