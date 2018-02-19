require 'sinatra/base'
require 'json'
require 'base64'
require_relative 'ledger'

module Todoable
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    # Every route except '/authenticate' requires a valid token.
    before { parse_token }

    post '/authenticate' do
      email_password = parse_email_password
      token = @ledger.generate_token(email_password[:email], email_password[:password])
      if token.success?
        status 201
        JSON.generate(token.response)
      else
        status 401
        JSON.generate(error_message: token.error_message)
      end
    end

    # Retrieves all lists
    get '/lists' do
      get_lists(@token)
    end

    # Retrieve a single list
    get '/lists/:list_id' do
      get_lists(@token, params[:list_id])
    end

    # Creates a list
    post '/lists' do
      list_params = JSON.parse(request.body.read, symbolize_names: true)
      if list_params.empty?
        halt 422, JSON.generate(error_message: 'List is required')
      end

      created_list = @ledger.create_list(@token, list_params)
      if created_list.success?
        status 201
        JSON.generate(created_list.response)
      else
        status 422
        message = created_list.error_message || 'List not created'
        JSON.generate(error_message: message)
      end
    end

    # Create an item
    post '/lists/:list_id/items' do
      item = JSON.parse(request.body.read, symbolize_names: true)
      if item.empty?
        halt 422, JSON.generate(error_message: 'Item name is required')
      end

      created_item = @ledger.create_item(params[:list_id], @token, item)
      if created_item.success?
        status 201
        JSON.generate(created_item.response)
      else
        status 422
        message = created_item.error_message || 'Item not created'
        JSON.generate(error_message: message)
      end
    end

    # Updates the list
    patch '/lists/:list_id' do
      new_list = JSON.parse(request.body.read, symbolize_names: true)
      if new_list.empty?
        halt 422, JSON.generate(error_message: 'List is required')
      end

      updated_list = @ledger.update_list(params[:list_id], @token, new_list)
      if updated_list.success?
        status 201
        JSON.generate(updated_list.response)
      else
        status 422
        message = updated_list.error_message || 'Error - must provide a valid id and name'
        JSON.generate(error_message: message)
      end
    end

    # Deletes the list and all items in it
    delete '/lists/:list_id' do
      deleted_list = @ledger.delete_list(params[:list_id], @token)
      if deleted_list.success?
        status 204
        JSON.generate(deleted_list.response)
      else
        status 422
        message = deleted_list.error_message || 'List could not be deleted'
        JSON.generate(error_message: message)
      end
    end

    # Mark this to_do item as finished
    put '/lists/:list_id/items/:item_id/finish' do
      finished_item = @ledger.finish_item(params[:list_id], @token, params[:item_id])
      if finished_item.success?
        JSON.generate(finished_item.response)
      else
        status 422
        message = finished_item.error_message || 'Item could not be finished'
        JSON.generate(error_message: message)
      end
    end

    # Deletes the item
    delete '/lists/:list_id/items/:item_id' do
      deleted_item = @ledger.delete_item(params[:list_id], @token, params[:item_id])
      if deleted_item.success?
        status 204
      else
        status 422
        message = deleted_item.error_message || 'Item could not be deleted'
        JSON.generate(error_message: message)
      end
    end

    private

    def get_lists(token, list_id = nil)
      result = @ledger.retrieve(token, list_id)
      if result.success?
        JSON.generate(result.response)
      else
        status 404
        message = result.error_message || 'No lists exist'
        JSON.generate(error_message: message)
      end
    end

    def parse_email_password
      if @env['HTTP_AUTHORIZATION'].nil?
        halt 401, JSON.generate(error_message: 'Invalid email/password')
      end

      begin
        auth_header = @env['HTTP_AUTHORIZATION'] # "Basic <long encrypted string representing email:password>"
        email_pass_digest = auth_header.split(' ')[1] # "<long encrypted string representing email:password>"
        email_pass = Base64.decode64(email_pass_digest).split(':') # [ 'asdf@example.com', 'asdfasdf' ]
        email = email_pass.first
        password = email_pass.last
        { email: email, password: password }
      rescue Exception
        halt 422, JSON.generate(error_message: 'Invalid email/password')
      end
    end

    def parse_token
      return false if request.path_info == '/authenticate'

      if @env['HTTP_AUTHORIZATION'].nil?
        halt 401, JSON.generate(error_message: 'Token required')
      end

      begin
        token_digest = @env['HTTP_AUTHORIZATION'].gsub(/Token token=/, '').delete('"') # 0mETCsD-M7Jc54bGiO1GTkXOcxUf-Dtq19Sj4nOscsRnhWvNfeU0KjpMkSxFzaxIw7S6P4ujF18gvYhq3HD_Zw
        @token = Base64.decode64(token_digest)
        # t = Base64.decode64(token_digest)
        #
        # user = User.find(token: t)
        #
        # if user.nil?
        #   halt 401, JSON.generate(error_message: 'Invalid Token')
        # end
        #
        # if user.token_timestamp < 20.minutes.ago
        #   halt 401, JSON.generate(error_message: 'Token has expired, please log in again')
        # end
        #
        # @token = t
      rescue Exception
        halt 401, JSON.generate(error_message: 'Invalid Token')
      end
    end
  end
end
