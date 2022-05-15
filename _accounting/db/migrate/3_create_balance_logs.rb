Sequel.migration do
  change do
    create_table(:daily_payouts) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false
      Date :date, null: false
      Integer :amount, null: false, default: 0
      DateTime :created_at, null: false

      index %i[date account_id], unique: true
    end

    create_table(:balance_logs) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false
      foreign_key :task_id, :tasks, null: true
      foreign_key :daily_payout_id, :daily_payouts, null: true

      String :public_id, null: false, unique: true

      # adds this amount to balance
      Integer :debit_amount, null: false, default: 0

      # removes this amount from balance
      Integer :credit_amount, null: false, default: 0

      # task_assigned - adds credit_amount
      # task_completed - adds debit_amount
      # payout - adds credit_amount
      String :operation_name, null: false

      DateTime :created_at, null: false
    end
  end
end
