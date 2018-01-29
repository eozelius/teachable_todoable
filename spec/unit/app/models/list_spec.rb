require_relative '../../../../app/models/list'

module Todoable
  RSpec.describe List do
    it 'should have a name' do
      my_list = List.new(name: '', user_id: 1)
      expect(my_list.valid?).to eq(false)
      my_list.set(name: 'my hobbies')     # Alternative to my_list.name.  Both methods work fine http://sequel.jeremyevans.net/rdoc/files/doc/mass_assignment_rdoc.html
      expect(my_list.valid?).to eq(true)
    end

    it 'should belong to a user' do
      list = List.new(name: 'my hobbies')
      expect(list.valid?).to eq(false)
      list.user_id = 1
      expect(list.valid?).to eq(true)
    end
  end
end