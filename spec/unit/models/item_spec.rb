require_relative '../../../models/item'

module Todoable
  RSpec.describe Item do
    it 'should have a name' do
      item = Item.new(name: nil, finished_at: DateTime.now, src: 'asdfasdf')
      expect(item.valid?).to eq(false)
      item.name = 'apples'
      expect(item.valid?).to eq(true)
    end

    it 'should have a src' do
      item = Item.new(name: 'apples', finished_at: DateTime.now, src: nil)
      expect(item.valid?).to eq(false)
      item.src = 'asdfasdf'
      expect(item.valid?).to eq(true)
    end
  end
end