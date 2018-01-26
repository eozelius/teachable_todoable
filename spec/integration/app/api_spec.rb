require 'json'
require 'rack/test'
require_relative '../../../app/api'


module Todoable
  RSpec.describe 'Todoable ENDPOINTS', :db do
    it 'is true' do
      expect(1).to eq(1)
    end
  end
end