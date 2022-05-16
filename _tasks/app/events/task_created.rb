# frozen_string_literal: true

module Events
  class TaskCreated
    include EventPayloadHelper

    attr_reader :task

    def initialize(task)
      @task = task
    end

    def name
      "task_created"
    end

    def topic
      "tasks_streaming"
    end

    def payload
      {
        **event_payload(version: 2),
        data: {
          public_id: task.public_id,
          title: task.title,
          jira_id: task.jira_id,
          description: task.description
        }
      }
    end
  end
end
