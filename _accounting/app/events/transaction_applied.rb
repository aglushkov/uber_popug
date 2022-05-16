# frozen_string_literal: true

module Events
  class TransactionApplied
    include EventPayloadHelper

    attr_reader :balance_log

    def initialize(balance_log)
      @balance_log = balance_log
    end

    def name
      "transaction_applied"
    end

    def topic
      "balance_transactions"
    end

    def payload
      {
        **event_payload,
        data: {
          public_id: balance_log.public_id,
          account_public_id: balance_log.account.public_id,
          task_public_id: balance_log.task&.public_id,
          type: balance_log.operation_name,
          debit: balance_log.debit_amount,
          credit: balance_log.credit_amount
        }
      }
    end
  end
end
