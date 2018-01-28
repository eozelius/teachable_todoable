class Item < Sequel::Model
  many_to_one :list

end