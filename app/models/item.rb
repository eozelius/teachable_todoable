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
  end
end