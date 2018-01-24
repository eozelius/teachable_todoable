require_relative '../config/sequel'

module Todoable
  RecordResult = Struct.new(:success?, :list_id, :error_message)

  class Ledger
    def record(list)
      unless list.key?('name')
        message = 'Invalid list: `name is required`'
        return RecordResult.new(false, nil, message)
      end

      DB[:lists].insert(list)
      id = DB[:lists].max(:id)
      RecordResult.new(true, id, nil)
    end

    def retrieve(list_id)
      DB[:lists].where(id: list_id).all
    end
  end
end