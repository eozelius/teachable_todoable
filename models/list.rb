require_relative '../../config/sequel'

module Todoable
  class List < Sequel::Model
    # SQL relationships
    many_to_one :user
    one_to_many :items

    # Attributes
    attr_accessor :name, :src

    # Validations
    def validate
      super
      # name
      unless @name && @name.length >= 1
        errors.add(:name, 'invalid name')
      end

      # src
      unless @src
        errors.add(:src, 'invalid src')
      end
    end
  end
end