# frozen_string_literal: true

require_relative "./with_helper"

module EventSubscriptions
  class TaskCompleted
    extend WithHelper

    class << self
      def subscribe(topic_name:, event_name:, schema:, version:)
        with(topic_name: topic_name, event_name: event_name, schema: schema, version: version) do |data|
          DB.transaction do
            task = Task.create_or_find(public_id: data.fetch(:task_public_id))
            account = Account.create_or_find(public_id: data.fetch(:completed_by_account_public_id))

            BalanceLog.create(
              task_id: task.id,
              account_id: account.id,
              operation_name: "task_completed",
              debit_amount: task.complete_cost
            )
          end
        end
      end
    end
  end
end

EventSubscriptions::TaskCompleted.subscribe(
  topic_name: "tasks_lifecycle",
  event_name: "task_completed",
  schema: "tasks.tasks_lifecycle.task_completed",
  version: 1
)
