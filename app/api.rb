require 'sinatra/base'
require 'json'
require_relative 'ledger'

module Todoable
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    # Retrieves all lists
    get '/lists' do
      lists = DB[:lists].all
      JSON.generate(lists)
    end

    # Creates a list
    post '/lists' do
      list = JSON.parse(request.body.read)
      result = @ledger.record(list)

      if result.success?
        status 201
        JSON.generate('list_id' => result.list_id)
      else
        status 422
        JSON.generate('error' => result.error_message)
      end
    end

    # Retrieve a single list
    get '/lists/:list_id' do
      result = @ledger.retrieve(params[:list_id])

      if result.success?
        status 201
        JSON.generate('list_id' => result.list_id)
      else
        status 404
        JSON.generate('error' => result.error_message)
      end
    end

    # Updates the list
    patch '/lists/:list_id' do
    end

    # Deletes the list and all items in it
    delete '/lists/:list_id' do
    end

    # Creates a to_do item in this list
    post '/lists/:list_id/items' do
    end

    # Mark this to_do item as finished
    put '/lists/:list_id/items/:item_id/finish' do
    end

    # Deletes the item
    delete '/lists/:list_id/items/:item_id' do
    end
  end
end