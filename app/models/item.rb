class Item < Sequel::Model
  # SQL relationships
  many_to_one :list


end