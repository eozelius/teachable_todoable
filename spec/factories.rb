require_relative '../app/ledger'

# This will guess the User class
FactoryBot.define do
  factory :user do
    email 'asdf@asdf.com'
    password 'asdfasdf'
  end

  factory :list do
    name: 'Life goals'
    user_id: 1
  end

  factory :mocked_valid_ledger, class: Ledger do
    # create_user {
    #   RecordResult.new(
    #     true,
    #     { id: user.id,
    #       token: user.token },
    #     nil
    #   )
    # }
    #
    # generate_token
    # retrieve
    # create_list
    # create_item
    # update_list
    # finish_item
    # delete_list
    # delete_item



#    first_name "John"
#    last_name  "Doe"
#    admin false

  end

  # This will use the User class (Admin would have been guessed)
  # factory :admin, class: User do
  #   first_name "Admin"
  #   last_name  "User"
  #   admin      true
  # end
end