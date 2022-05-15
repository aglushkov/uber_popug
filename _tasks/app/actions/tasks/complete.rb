module Tasks
  class Complete
    def call(task, by_account: task.account)
      accounts_task =
        DB.transaction do
          task.lock!
          accounts_task = task.accounts_task
          next if accounts_task.is_completed || (accounts_task.account_id != by_account.id)

          accounts_task.update(is_completed: true)
        end

      publish_events(accounts_task) if accounts_task
    end

    private

    def publish_events(accounts_task)
      PublishEvent.call(
        event: Events::TaskCompleted.new(accounts_task.task, accounts_task.account),
        schema: "tasks.tasks_lifecycle.task_completed",
        version: 1
      )
    end
  end
end
