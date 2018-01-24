require 'sinatra/base'
require 'json'

module Todoable
  class API < Sinatra::Base
    # Retrieves all lists
    get '/lists' do
      JSON.generate([])
    end

    # Creates a list
    post '/lists' do
      JSON.generate('list_id' => 42)
    end

    # Retrieve the list information
    get '/lists/:list_id' do
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