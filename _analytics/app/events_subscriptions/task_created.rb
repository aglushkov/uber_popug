# frozen_string_literal: true

require_relative "./with_helper"

module EventSubscriptions
  class TaskCreated
    extend WithHelper

    class << self
      def subscribe(topic_name:, event_name:, schema:, version:)
        with(topic_name: topic_name, event_name: event_name, schema: schema, version: version) do |data|
          Task.create_or_find(public_id: data.fetch(:public_id)) do |task|
            task.title = data.fetch(:title)
            task.role = data.fetch(:role)
          end
        end
      end
    end
  end
end

EventSubscriptions::TaskCreated.subscribe(
  topic_name: "tasks_streaming",
  event_name: "task_created",
  schema: "tasks.tasks_streaming.task_created",
  version: 1
)
