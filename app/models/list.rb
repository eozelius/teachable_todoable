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
      items.each(&:destroy)
    end

    def after_create
      self.src = "http://todoable.teachable.tech/api/lists/#{id}"
    end

    # Validations
    def validate
      super
      # name
      errors.add(:name, 'invalid name') unless name && name.length >= 1

      errors.add(:user_id, 'invalid user_id') unless user_id && user_id > 0
    end

    def json_response
      {
        list: {
          id: id,
          name: name,
          items: items.map(&:json_response)
        }
      }
    end
  end
end
