require_relative '../../config/sequel'

module Todoable
  class Item < Sequel::Model
    # Database columns
    # :id, :name, :finished_at, :src, :list_id, :timestamps

    # SQL relationships
    many_to_one :list

    # Callbacks
    def after_create
      self.src = "http://todoable.teachable.tech/api/lists/#{self.id}"
    end

    # Validations
    def validate
      super

      unless name && name.length >= 1
        errors.add(:name, 'invalid name')
      end

      unless list_id
        errors.add(:list_id, 'list_id is required')
      end
    end

    def json_response
      { id: id,
        name: name,
        finished_at: finished_at }
    end
  end
end