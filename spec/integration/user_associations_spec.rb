require_relative '../../app/models/user'
require_relative '../../app/models/list'

module Todoable
  RSpec.describe 'User SQL associations', :db do
    let(:user) { User.create(email: 'asdf@asdf.com', password: 'asdfasdf') }

    describe 'association with List' do
      it 'has a one_to_many relationship with List' do
        expect(user.lists).to eq([])
        grocery_list = List.new(name: 'grocery list')
        user.add_list(grocery_list)
        expect(user.lists).to include(grocery_list)
      end

      it 'will destroy associated lists when User is destroyed' do
        list_count = List.count
        grocery_list = List.new(name: 'grocery list')
        user.add_list(grocery_list)
        expect(List.count).to eq(list_count + 1)
        user.destroy
        expect(List.count).to eq(list_count)
      end
    end
  end
end
