require_relative '../app/models/list'
require_relative '../app/models/item'

module Todoable
  RecordResult = Struct.new(:success?, :response, :error_message)

  class Ledger
    # Fetch a List from the DB
    def retrieve(list_id = false)
      if list_id
        fetch_single_list(list_id)
      else
        fetch_all_records
      end
    end

    # Create a List
    def create_list(list)
      unless list.key?('name')
        message = 'Error name cannot be blank'
        return RecordResult.new(false, nil, message)
      end

      new_list = List.new(name: list['name'])
      if new_list.valid?
        new_list.save
        response = {
          list: {
            id: new_list.id
          }
        }
        RecordResult.new(true, response, nil)
      else
        RecordResult.new(false, nil, 'Error list could not be created')
      end
    end

    # Create an Item
    def create_item(list_id, item)
      unless item.key?('name') && list_id
        return RecordResult.new(false, nil, 'Error name cannot be blank')
      end

      list = List.find(id: list_id.to_i)
      new_item = Item.new(name: item['name'])
      if list && new_item.valid?
        list.add_item(new_item)
        response = {
          id: new_item.id,
          name: new_item.name
        }
        RecordResult.new(true, response, nil)
      else
        RecordResult.new(false, nil, 'Error list not found')
      end
    end

    # Update a List in the DB
    def update(list_id, new_name)
      list = List.find(id: list_id.to_i)
      return RecordResult.new(false, nil, 'Error - list does not exist') if list.nil?
      list.set(name: new_name['name'])

      if list.valid?
        list.save
        response = {
          'list' => {
            'id' => list.id,
            'name' => list.name
          }
        }
        RecordResult.new(true, response, nil)
      else
        RecordResult.new(false, nil, "Error - list is not valid")
      end
    end

    def delete(list_id)
      list = DB[:lists].where(id: list_id).all
      if list.empty?
        RecordResult.new(false, nil, 'List does not exist')
      else
        DB[:lists].where(id: list_id).delete
        RecordResult.new(true, nil, nil)
      end
    end

    private

    def fetch_all_records
      lists = List.all
      if lists.empty?
        RecordResult.new(false, [], 'No lists exists')
      else
        response = []
        lists.each { |l| response.push(l.json_response) }
        RecordResult.new(true, { lists: response }, nil)
      end
    end

    def fetch_single_list(list_id)
      list = List.find(id: list_id.to_i)
      if list.nil?
        RecordResult.new(false, [], 'List does not exist')
      else
        response = list.json_response
        RecordResult.new(true, response, nil)
      end
    end
  end
end