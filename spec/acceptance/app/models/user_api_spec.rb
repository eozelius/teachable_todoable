require 'rack/test'

module Todoable
  RSpec.describe 'User API endpoints', :db do
    include Rack::Test::Methods

    def app
      Todoable::API.new
    end
  end
end