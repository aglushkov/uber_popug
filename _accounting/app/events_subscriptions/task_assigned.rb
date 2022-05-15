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
              account = Account.create_or_find(public_id: data.fetch(:assigned_to_account_public_id))
              task = Task.create_or_find(public_id: data.fetch(:task_public_id))

              # Lock account and task to ensure nobody will change balance simultaneously
              account.lock!
              task.lock!

              # Check task was already assigned to current account
              last_log = BalanceLog.where(operation_name: "task_assigned", task_id: task.id).last
              next if last_log&.account_id == account.id

              # Add balance transaction
              BalanceLog.create(
                task_id: task.id,
                account_id: account.id,
                operation_name: "task_assigned",
                credit_amount: task.assign_cost
              ).tap do |rec|
                account.update(balance: account.balance - rec.credit_amount) # safe as account is locked
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

EventSubscriptions::TaskAssigned.subscribe(
  topic_name: "tasks_lifecycle",
  event_name: "task_assigned",
  schema: "tasks.tasks_lifecycle.task_assigned",
  version: 1
)
