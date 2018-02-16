require_relative '../app/models/list'
require_relative '../app/models/item'
require_relative '../app/models/user'

module Todoable
  RecordResult = Struct.new(:success?, :response, :error_message)

  class Ledger
    # Create a User
    def create_user(email, password)
      user = User.new(email: email, password: password)

      if user.valid?
        user.save
        response = {
          id: user.id,
          token: user.token
        }
        RecordResult.new(true, response, nil)
      else
        #error_message = user.errors || 'user could not be created'
        RecordResult.new(false, nil, 'user could not be created')
      end
    end

    def generate_token(email, password)
      user = User.find(email: email)
      if user.nil?
        return create_user(email, password)
      end

      if user.password == password
        token = user.generate_token!
        RecordResult.new(true, { token: token }, nil)
      else
        RecordResult.new(false, nil, 'Invalid e-mail/password combination')
      end
    end

    # Fetch a List
    def retrieve(token, list_id)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      if list_id
        fetch_single_list(user.id, list_id)
      else
        fetch_all_records(user.id)
      end
    end

    # Create a List
    def create_list(token, list)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      new_list = List.new(name: list[:name], user_id: user.id)

      if user && new_list.valid?
        user.add_list(new_list)
        response = { id: new_list.id }
        RecordResult.new(true, response, nil)
      else
        RecordResult.new(false, nil, 'Error list could not be created')
      end
    end

    # Create an Item
    def create_item(list_id, token, item)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      list = List.find(id: list_id, user_id: user.id)
      if list.nil?
        return RecordResult.new(false, nil, 'List does not exist')
      end

      new_item = Item.new(name: item[:name], list_id: list_id)

      if new_item.valid?
        list.add_item(new_item)
        response = { id: new_item.id }
        RecordResult.new(true, response, nil)
      else
        #error = new_item.errors || 'Error item could not be added to the list'
        RecordResult.new(false, nil, 'Error item could not be added to the list')
      end
    end

    # Update a List in the DB
    def update_list(list_id, token, new_list)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      list = List.find(id: list_id, user_id: user.id)
      if list.nil?
        return RecordResult.new(false, nil, 'List does not exist')
      end

      list.set(name: new_list[:name])

      if list.valid?
        list.save
        response = {
          list: {
            id: list.id,
            name: list.name
          }
        }
        RecordResult.new(true, response, nil)
      else
        RecordResult.new(false, nil, 'Error - list is not valid')
      end
    end

    # Update an Item - toggle complete field
    def finish_item(list_id, token, item_id)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      list = List.find(id: list_id, user_id: user.id)
      if list.nil?
        return RecordResult.new(false, nil, 'List does not exist')
      end

      item = Item.find(id: item_id, list_id: list_id)
      if item.nil?
        return RecordResult.new(false, nil, 'Item does not exist')
      end

      if item.finished_at.nil?
        item.set(finished_at: DateTime.now)
      else
        item.set(finished_at: nil)
      end
      item.save
      RecordResult.new(true, item.finished_at, nil)
    end

    def delete_list(list_id, token)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      list = List.find(id: list_id, user_id: user.id)
      if list.nil?
        return RecordResult.new(false, nil, 'List does not exist')
      end

      list.destroy
      RecordResult.new(true, 'List successfully deleted', nil)
    end

    def delete_item(list_id, token, item_id)
      user = User.find(token: token)
      if user.nil?
        return RecordResult.new(false, nil, 'Invalid Token')
      end

      list = List.find(id: list_id, user_id: user.id)
      if list.nil?
        return RecordResult.new(false, nil, 'List does not exist')
      end

      item = Item.find(id: item_id, list_id: list_id)
      if item.nil?
        return RecordResult.new(false, nil, 'Item does not exist')
      end

      item.destroy
      RecordResult.new(true, 'Item successfully deleted', nil)
    end

    private

    def fetch_all_records(user_id)
      lists = List.where(user_id: user_id).all
      response = lists.map { |l| l.json_response }
      RecordResult.new(true, { lists: response }, nil)
    end

    def fetch_single_list(user_id, list_id)
      list = List.find(user_id: user_id, id: list_id)

      if list.nil?
        RecordResult.new(false, [], 'List does not exist')
      else
        response = list.json_response
        RecordResult.new(true, response, nil)
      end
    end
  end
end