class Task < Sequel::Model
  one_to_one :accounts_task
  one_through_one :account, join_table: :accounts_tasks

  dataset_module do
    def uncompleted
      association_join(:accounts_task)
        .select(Sequel.lit("tasks.*"))
        .where(is_completed: false)
    end
  end
end
