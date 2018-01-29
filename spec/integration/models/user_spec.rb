require_relative '../../../app/models/user'

module Todoable
  RSpec.describe User, :db do
    describe 'SQL relationships' do
      it 'has a "one_to_many" relationship with :lists'
    end
  end
end