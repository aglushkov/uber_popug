# frozen_string_literal: true

require_relative "./with_helper"

module EventSubscriptions
  class TransactionApplied
    extend WithHelper

    class << self
      def subscribe(topic_name:, event_name:, schema:, version:)
        with(topic_name: topic_name, event_name: event_name, schema: schema, version: version) do |data|
          account = Account.create_or_find(public_id: data.fetch(:account_public_id))

          task_id = data.fetch(:task_public_id)
          task = Task.create_or_find(public_id: data.fetch(:task_public_id)) if task_id

          BalanceTransaction.create_or_find(public_id: data.fetch(:public_id)) do |rec|
            rec.account_id = account.id
            rec.task_id = task&.id
            rec.debit = data.fetch(:debit)
            rec.credit = data.fetch(:credit)
            rec.type = data.fetch(:type)
          end
        end
      end
    end
  end
end

EventSubscriptions::TransactionApplied.subscribe(
  topic_name: "balance_transactions",
  event_name: "transaction_applied",
  schema: "accounting.balance_transactions.transaction_applied",
  version: 1
)
