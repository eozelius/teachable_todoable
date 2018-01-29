require_relative '../../../../app/models/list'
require_relative '../../../../app/models/user'

module Todoable
  RSpec.describe List do
    it 'should have a name' do
      my_list = List.new(name: '', src: 'asdfasdf')
      expect(my_list.valid?).to eq(false)
      my_list.name = 'my hobbies'
      expect(my_list.valid?).to eq(true)
    end

    it 'should have a src' do
      list = List.new(name: 'my hobbies', src: nil)
      expect(list.valid?).to eq(false)
      list.src = 'asdfasdf'
      expect(list.valid?).to eq(true)
    end

    it 'should belong to a user' do
      list = List.new(name: 'my hobbies', src: nil)
      expect(list.valid?).to eq(false)
      list.src = 1
      expect(list.valid?).to eq(true)
    end

    it 'should have 0 or more items' do
      # list.
    end
  end
end