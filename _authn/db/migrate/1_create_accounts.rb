Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id

      String :public_id, null: false, unique: true
      String :name, null: false
      String :email, null: false, unique: true
      String :encrypted_password, null: false
      String :role, null: false
      String :session_token

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
