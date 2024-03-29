# frozen_string_literal: true

module Events
  class TaskCompleted
    include EventPayloadHelper

    attr_reader :task, :account

    def initialize(task, account)
      @task = task
      @account = account
    end

    def name
      "task_completed"
    end

    def topic
      "tasks_lifecycle"
    end

    def payload
      {
        **event_payload,
        data: {
          task_public_id: task.public_id,
          completed_by_account_public_id: account.public_id
        }
      }
    end
  end
end
