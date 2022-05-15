module Tasks
  class Create
    def call(attrs)
      account = Account.rand_worker
      task = create_and_assign(attrs, account)

      publish_events(task, account)
      task
    end

    private

    def create_and_assign(attrs, account)
      attrs = prepare_jira_id(attrs)

      DB.transaction do
        task = Task.create(public_id: SecureRandom.uuid, **attrs)
        AccountsTask.create(task_id: task.id, account_id: account.id, is_completed: false)
        task
      end
    end

    def prepare_jira_id(attrs)
      title = attrs[:title]
      jira_id = title[/\[.*?\]/]

      if jira_id
        title = title.sub(jira_id, "").gsub(/^[\s-]+|[\s-]+$/, "")
        jira_id = jira_id.gsub(/^[\[\s-]+|[\]\s-]+$/, "")
      end

      {**attrs, title: title, jira_id: jira_id}
    end

    def publish_events(task, account)
      PublishEvent.call(
        event: Events::TaskCreated.new(task),
        schema: "tasks.tasks_streaming.task_created",
        version: 2
      )

      PublishEvent.call(
        event: Events::TaskAssigned.new(task, account),
        schema: "tasks.tasks_lifecycle.task_assigned",
        version: 1
      )
    end
  end
end
