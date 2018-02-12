require_relative '../../config/sequel'
require_relative '../../app/models/item'

module Todoable
  class List < Sequel::Model
    # Database columns
    # :id, :name, :src, :user_id, :timestamps

    # SQL relationships
    many_to_one :user
    one_to_many :items

    # Call Backs
    def before_destroy
      self.items.each { |i| i.destroy }
    end

    def after_create
      self.src = "http://todoable.teachable.tech/api/lists/#{self.id}"
    end

    # Validations
    def validate
      super
      # name
      unless name && name.length >= 1
        errors.add(:name, 'invalid name')
      end

      unless user_id && user_id > 0
        errors.add(:user_id, 'invalid user_id')
      end
    end

    def json_response
      {
        list: {
          id: id,
          name: name,
          items: self.items.map { |i| i.json_response }
        }
      }
    end
  end
end