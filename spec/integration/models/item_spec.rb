require_relative '../../../app/models/item'

module Todoable
  RSpec.describe Item, :db do
    describe 'SQL relationships' do
      it 'has a "many_to_one" relationship with :list'
    end
  end
end