class List < Sequel::Model
  # SQL relationships
  many_to_one :user
  one_to_many :items

  # def validate
  #   super
  #   errors.add(:name, "can't be empty") if name.empty?
  #   errors.add(:written_on, "should be in the past") if written_on >= Time.now
  # end
end