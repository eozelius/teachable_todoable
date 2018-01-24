require_relative '../../../app/api'

module Todoable
  RSpec.describe API do
    describe 'POST /lists' do
      context 'when the expense is successfully recorded' do
        it 'returns the list id'
        it 'responds with a 201 (OK)'
      end

      context 'when the expense fails validation' do
        it 'returns a helpful error message'
        it 'responds iwth a 422 (Unprocessable entity)'
      end
    end
  end
end