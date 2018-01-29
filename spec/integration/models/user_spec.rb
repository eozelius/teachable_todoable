require_relative '../../../models/user'
require_relative '../../../models/list'
require_relative '../../../models/item'

module Todoable
  RSpec.describe User, :db do
    describe 'SQL relationships' do
      # it 'has a "one_to_many" relationship with :lists', :db do
        # user.save
        #   allow(grocery_list).to receive(:valid?)
        #     .and_return(true)
        #
        #   user.add_list(grocery_list)
        #   expect(user.lists).to include(grocery_list)
      # end


    end
  end
end