# frozen_string_literal: true

require_relative "./with_helper"

module EventSubscriptions
  class TaskAssigned
    extend WithHelper

    class << self
      def subscribe(topic_name:, event_name:, schema:, version:)
        with(topic_name: topic_name, event_name: event_name, schema: schema, version: version) do |data|
          balance_transaction =
            DB.transaction do
              task = Task.create_or_find(public_id: data.fetch(:task_public_id))
              account = Account.create_or_find(public_id: data.fetch(:assigned_to_account_public_id))

              BalanceLog.create(
                task_id: task.id,
                account_id: account.id,
                operation_name: "task_assigned",
                credit_amount: task.assign_cost
              )
            end

          PublishEvent.call(
            event: Events::TransactionApplied.new(balance_transaction),
            schema: "accounting.balance_transactions.transaction_applied",
            version: 1
          )
        end
      end
    end
  end
end

EventSubscriptions::TaskAssigned.subscribe(
  topic_name: "tasks_lifecycle",
  event_name: "task_assigned",
  schema: "tasks.tasks_lifecycle.task_assigned",
  version: 1
)
