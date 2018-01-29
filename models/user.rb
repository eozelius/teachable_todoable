require 'securerandom'
require_relative '../../config/sequel'

module Todoable
  class User < Sequel::Model
    # SQL relationships
    one_to_many :lists

    # Accessors
    attr_accessor :email, :password, :password_digest, :token

    # Validations
    def validate
      super
      # email
      unless @email && /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i =~ @email
        errors.add(:email, 'invalid email')
      end

      # password
      unless @password && @password.length > 6
        errors.add(:password, 'invalid password')
      end

      # token
      unless @token && @token.length > 10
        errors.add(:token, 'invalid token')
      end
    end
  end
end