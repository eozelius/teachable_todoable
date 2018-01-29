require_relative '../../config/sequel'

module Todoable
  class Item < Sequel::Model
    # SQL relationships
    many_to_one :list

    # Attributes
    attr_accessor :name, :finished_at, :src

    # Validations
    def validate
      super

      # name
      unless @name && @name.length >= 1
        errors.add(:name, 'invalid name')
      end

      unless @src
        errors.add(:src, 'invalid src')
      end
    end
  end
end