require_relative '../config/sequel'

module Todoable
  RecordResult = Struct.new(:success?, :response, :error_message)

  class Ledger
    def record(list)
      unless list.key?('name')
        message = 'Error name cannot be blank'
        return RecordResult.new(false, nil, message)
      end

      DB[:lists].insert(list)
      id = DB[:lists].max(:id)
      RecordResult.new(true, { 'list_id' => id }, nil)
    end

    def retrieve(list_id = false)
      if list_id
        fetch_single_record(list_id)
      else
        fetch_all_records
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