require_relative '../../config/sequel'

module Todoable
  class Item < Sequel::Model
    # Database columns
    # :id, :name, :finished_at, :src, :list_id, :timestamps

    # SQL relationships
    many_to_one :list

    # Validations
    def validate
      super

      # name
      unless name && name.length >= 1
        errors.add(:name, 'invalid name')
      end
    end

    def json_response
      {
        id: id,
        name: name,
        finished_at: finished_at,
      }
      #
      # {
      #   "list": {
      #     "name": "Urgent Things",
      #     "items": [
      #       {
      #         "name":         "Feed the cat",
      #         "finished_at":  null,
      #         "src":          "http://todoable.teachable.tech/api/lists/:list_id/items/:item_id",
      #         "id":          ":item_id"
      #       },
      #       {
      #         "name":        "Get cat food",
      #         "finished_at":  null,
      #         "src":          "http://todoable.teachable.tech/api/lists/:list_id/items/:item_id",
      #         "id":          ":item_id"
      #       },
      #     ]
      #   }
      # }
    end
  end
end