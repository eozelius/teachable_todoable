module Todoable
  RecordResult = Struct.new(:success?, :list_id, :error_message)

  class Ledger
    def record(list)
    end

    def retrieve(list_id)
    end
  end
end