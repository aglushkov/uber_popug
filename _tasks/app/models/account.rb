class Account < Sequel::Model
  plugin :enum

  one_to_many :accounts_tasks
  many_to_many :tasks, join_table: :accounts_tasks
  many_to_many :uncompleted_tasks, class: :Task,
    left_key: :account_id,
    right_key: :task_id,
    join_table: :accounts_tasks,
    conditions: {is_completed: false}

  enum :role, worker: "worker", admin: "admin"

  def self.rand_worker
    rand_workers.first
  end

  dataset_module do
    def rand_workers
      worker.order(Sequel.lit("RANDOM()"))
    end
  end
end
