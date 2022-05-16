Sequel.migration do
  change do
    create_table(:balance_transactions) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false
      foreign_key :task_id, :tasks, null: true

      String :public_id, null: false, unique: true
      Integer :debit, null: false, default: 0
      Integer :credit, null: false, default: 0

      # task_assigned
      # task_completed
      # payout
      String :type, null: false

      DateTime :created_at, null: false
    end
  end
end
