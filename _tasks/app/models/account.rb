class Account < Sequel::Model
  plugin :enum

  one_to_many :accounts_tasks
  many_to_many :tasks, join_table: :accounts_tasks
  many_to_many :uncompleted_tasks, class: :Task,
    left_key: :account_id,
    right_key: :task_id,
    join_table: :accounts_tasks,
    conditions: {is_completed: false}

  enum :role, worker: "worker", admin: "admin", accountant: "accountant"

  def self.rand_worker
    rand_workers.first
  end

  def self.create_or_find(public_id:, &block)
    account = find(public_id: public_id)
    return account if account

    DB.transaction(savepoint: true) { create(public_id: public_id, &block) }
  rescue Sequel::UniqueConstraintViolation
    find(public_id: public_id) || raise(Sequel::NoMatchingRow)
  end

  dataset_module do
    def rand_workers
      worker.order(Sequel.lit("RANDOM()"))
    end
  end
end
