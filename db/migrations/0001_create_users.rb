Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :email, unique: true
      String :password_digest
      String :token, index: true
      DateTime :token_created_at

      Sequel::Model.plugin :timestamps
    end
  end
end
