# frozen_string_literal: true

require_relative "./with_helper"

module EventSubscriptions
  class TaskCompleted
    extend WithHelper

    class << self
      def subscribe(topic_name:, event_name:, schema:, version:)
        with(topic_name: topic_name, event_name: event_name, schema: schema, version: version) do |data|
          balance_transaction =
            DB.transaction do
              task = Task.create_or_find(public_id: data.fetch(:task_public_id))
              account = Account.create_or_find(public_id: data.fetch(:completed_by_account_public_id))

              # Lock account and task to ensure nobody will change balance simultaneously
              account.lock!
              task.lock!

              # Check task was already completed
              last_log = BalanceLog.where(operation_name: "task_completed", task_id: task.id).last
              next if last_log

              BalanceLog.create(
                task_id: task.id,
                account_id: account.id,
                operation_name: "task_completed",
                debit_amount: task.complete_cost
              ).tap do |rec|
                account.update(balance: account.balance + rec.debit_amount) # safe as account is locked
              end
            end

          next unless balance_transaction

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

EventSubscriptions::TaskCompleted.subscribe(
  topic_name: "tasks_lifecycle",
  event_name: "task_completed",
  schema: "tasks.tasks_lifecycle.task_completed",
  version: 1
)
