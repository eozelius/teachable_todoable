require_relative '../../config/sequel'

module Todoable
  class List < Sequel::Model
    # SQL relationships
    many_to_one :user
    one_to_many :items

    # Attributes
    attr_accessor :name, :src

    # Call Backs
    def before_destroy
      self.items.each { |i| i.destroy }
    end

    # Validations
    def validate
      super
      # name
      unless @name && @name.length >= 1
        errors.add(:name, 'invalid name')
      end

      unless self.user_id && self.user_id > 0
        errors.add(:user_id, 'invalid user_id')
      end
    end
  end
end