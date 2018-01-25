require_relative '../config/sequel'

module Todoable
  RecordResult = Struct.new(:success?, :list_id, :name, :error_message)

  class Ledger
    def record(list)
      unless list.key?('name')
        message = 'Error name cannot be blank'
        return RecordResult.new(false, nil, nil, message)
      end

      DB[:lists].insert(list)
      id = DB[:lists].max(:id)
      RecordResult.new(true, id, list[:name], nil)
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
      records = []
      lists = DB[:lists].all

      if lists.empty?
        RecordResult.new(false, nil, nil, 'No lists exists')
      else
        lists.each { |l| records.push(RecordResult.new(true, l[:id], l[:name], nil)) }
        records
      end
    end

    def fetch_single_record(list_id)
      lists = DB[:lists].where(id: list_id).all
      if lists.empty?
        RecordResult.new(false, nil, nil, 'List does not exist')
      else
        RecordResult.new(true, list[:id], list[:name], nil)
      end
    end
  end
end