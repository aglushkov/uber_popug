Sequel.migration do
  change do
    create_table(:tasks) do
      primary_key :id

      String :public_id, null: false, unique: true
      String :title
      String :description
      String :jira_id

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
