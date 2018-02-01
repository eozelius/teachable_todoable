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
      get_lists
    end

    # Retrieve a single list
    get '/lists/:list_id' do
      get_lists
    end

    # Creates a list
    post '/lists' do
      list = JSON.parse(request.body.read)
      # todo add error checking
      record = @ledger.create_list(list)

      if record.success?
        status 201
        JSON.generate(record.response)
      else
        status 422
        message = record.error_message || 'List not created'
        JSON.generate('error_message' => message)
      end
    end

    # Create an item
    post '/lists/:list_id/items' do
      list_id = params[:list_id]
      item = JSON.parse(request.body.read)
      created_item = @ledger.create_item(list_id, item)

      if created_item.success?
        status 201
        JSON.generate(created_item.response)
      else
        status 422
        message = created_item.error_message || 'Item not created'
        JSON.generate('error_message' => message)
      end
    end

    # Updates the list
    patch '/lists/:list_id' do
      new_name = JSON.parse(request.body.read)
      list_id  = params[:list_id]
      update = @ledger.update(list_id, new_name)
      if update.success?
        status 201
        JSON.generate(update.response)
      else
        status 422
        message = update.error_message || 'Error - must provide a valid id and name'
        JSON.generate('error_message' => message)
      end
    end

    # Deletes the list and all items in it
    delete '/lists/:list_id' do
      list_id = params[:list_id]
      delete = @ledger.delete(list_id)

      if delete.success?
        status 201
        JSON.generate(delete.response)
      else
        status 422
        message = delete.error_message || 'List could not be deleted'
        JSON.generate('error_message' => message)
      end
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

    private

    def get_lists
      result = @ledger.retrieve(params[:list_id])
      if result.success?
        JSON.generate(result.response)
      else
        status 404
        message = result.error_message || 'No lists exist'
        JSON.generate('error_message' => message)
      end
    end
  end
end