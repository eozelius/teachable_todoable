require_relative '../config/sequel'

module Todoable
  RecordResult = Struct.new(:success?, :response, :error_message)

  class Ledger
    # Save a List to the DB
    def record(list)
      unless list.key?('name')
        message = 'Error name cannot be blank'
        return RecordResult.new(false, nil, message)
      end

      DB[:lists].insert(list)
      response = {
        'list' => {
          'name' => list['name']
        }
      }
      RecordResult.new(true, response, nil)
    end

    # Fetch a List from the DB
    def retrieve(list_id = false)
      if list_id
        fetch_single_record(list_id)
      else
        fetch_all_records
      end
    end

    def update(list_id, new_name)
      # todo: this should be combined into ONE DB request to save time/resources
      list = DB[:lists].where(id: list_id).all
      if list.empty?
        RecordResult.new(false, [], 'List does not exist')
      else
        DB[:lists].where(id: list_id).update(:name => new_name["name"])
        reloaded_name = DB[:lists].where(id: list_id).all[0][:name]
        response = {
          'list' => {
            'name' => reloaded_name
          }
        }
        RecordResult.new(true, response, nil)
      end
    end

    private

    def fetch_all_records
      lists = DB[:lists].all

      if lists.empty?
        RecordResult.new(false, [], 'No lists exists')
      else
        response = { 'lists' => lists }
        RecordResult.new(true, response, nil)
      end
    end

    def fetch_single_record(list_id)
      record = DB[:lists].where(id: list_id).all # example: "[{:id=>1, :name=>\"Utmost Importance\"}]"
      if record.empty?
        RecordResult.new(false, [], 'List does not exist')
      else
        response = { list: record.first }
        RecordResult.new(true, response, nil)
      end
    end
  end
end