class User < Sequel::Model
  # SQL relationships
  one_to_many :lists
end