Sequel.migration do
  change do
    create_table :items do
      primary_key :id
      String :name
      DateTime :finished_at
      String :src
      Integer :list_id, index: true, foreign_key: true

      Sequel::Model.plugin :timestamps
    end
  end
end
