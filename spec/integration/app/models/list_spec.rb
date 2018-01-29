require_relative '../../../../app/models/list'

module Todoable
  RSpec.describe List, :db do
    describe 'SQL relationships' do
      it 'has a "many_to_one" relationship with :user'

      it 'has a "one_to_many" relationship with :items'
    end
  end
end