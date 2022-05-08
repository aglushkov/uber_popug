Sequel.migration do
  change do
    create_table(:accounts_tasks) do
      primary_key :id

      foreign_key :account_id, :accounts, index: false
      foreign_key :task_id, :tasks, index: true
      Boolean :is_completed, null: false, default: false, index: true

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index %i[account_id task_id], unique: true
    end
  end
end
