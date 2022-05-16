module Tasks
  class Shuffle
    def call
      Task.uncompleted.order(Sequel.lit("tasks.id")).each_page(100) do |tasks|
        tasks.each do |task|
          account = Account.rand_worker
          account_task = assign_new_account(task, account)
          next unless account_task

          publish_events(task, account)
        end
      end
    end

    private

    def assign_new_account(task, account)
      DB.transaction do
        task.lock!
        account_task = task.accounts_task
        account_task.update(account_id: account.id) unless account_task.completed?
      end
    end

    def publish_events(task, account)
      PublishEvent.call(
        event: Events::TaskAssigned.new(task, account),
        schema: "tasks.tasks_lifecycle.task_assigned",
        version: 1
      )
    end
  end
end
