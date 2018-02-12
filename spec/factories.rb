FactoryBot.define do
  factory :user, class: Todoable::User  do
    email "asdf@asdf.com"
    password 'asdfasdf'
  end
end