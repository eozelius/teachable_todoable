require_relative '../../../../app/models/list'

module Todoable
  RSpec.describe List do
    let(:src) { 'http://todoable.teachable.tech/api/lists/1' }

    it 'should have a name' do
      my_list = List.new(name: '', user_id: 1)
      expect(my_list.valid?).to eq(false)
      my_list.set(name: 'my hobbies')
      expect(my_list.valid?).to eq(true)
    end

    it 'should belong to a user' do
      pending 'implement user authentication and ownership'
      list = List.new(name: 'my hobbies', user_id: nil)
      expect(list.valid?).to eq(false)
      list.user_id = 1
      expect(list.valid?).to eq(true)
    end
  end
end