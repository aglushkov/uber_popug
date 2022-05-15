Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id

      String :public_id, null: false, unique: true
      String :name
      String :role

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
