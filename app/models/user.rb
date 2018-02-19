require 'bcrypt'
require_relative '../../config/sequel'
require 'securerandom'

module Todoable
  class User < Sequel::Model
    # Database columns
    # :id, :email, password_digest, :token, :token_created_at  :timestamps

    # SQL relationships
    one_to_many :lists

    # Authentication
    include BCrypt

    def generate_token!
      self.token = SecureRandom.urlsafe_base64(64)
      self.token_created_at = Time.now
      save
      token
    end

    def password
      @password ||= Password.new(password_digest)
    end

    def password=(new_password)
      @password = Password.create(new_password)
      self.password_digest = @password
    end

    # Call Backs
    def before_destroy
      lists.each(&:destroy)
    end

    def before_save
      self.email = email.downcase
    end

    def after_create
      generate_token!
    end

    # Validations
    def validate
      super
      unless email && /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i =~ email
        errors.add(:email, 'invalid email')
      end

      errors.add(:password, 'invalid password') unless @password
    end
  end
end
