Sequel.migration do
  change do
    create_table :lists do
      primary_key :id
      String :name
      String :src
      Integer :user_id, index: true, foreign_key: true

      Sequel::Model.plugin :timestamps
    end
  end
end