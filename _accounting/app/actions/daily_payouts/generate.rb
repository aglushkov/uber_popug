module DailyPayouts
  class Generate
    def call
      date = Time.now.utc.to_date

      free_transactions.each do |account_id, transactions|
        total = total_amount(transactions)
        next if total <= 0

        daily_payout, balance_transaction =
          generate_payout(
            account_id: account_id,
            date: date,
            amount: total,
            transaction_ids: transactions.map { |transaction| transaction[1] }
          )

        next unless balance_transaction

        publish_events(balance_transaction)
        send_email(daily_payout)
      end
    end

    private

    def free_transactions
      BalanceLog
        .where(operation_name: ["task_assigned", "task_completed"])
        .where(daily_payout_id: nil)
        .select_map([:account_id, :id, :debit_amount, :credit_amount])
        .group_by(&:first)
    end

    def total_amount(transactions)
      debit = transactions.sum { |transaction| transaction[2] }
      credit = transactions.sum { |transaction| transaction[3] }
      debit - credit
    end

    def generate_payout(account_id:, date:, transaction_ids:, amount:)
      DB.transaction do
        account = Account.for_update[id: account_id]
        next if DailyPayout[account_id: account.id, date: date]

        daily_payout = DailyPayout.create(account_id: account.id, amount: amount, date: date)

        # Mark transactions as used in payout
        BalanceLog.where(id: transaction_ids).update(daily_payout_id: daily_payout.id)

        # Add payout transaction
        transaction = BalanceLog.create(account_id: account.id, credit_amount: amount, operation_name: "payout")

        # Update total amount
        account.update(balance: account.balance - amount)

        [daily_payout, transaction]
      end
    end

    def publish_events(balance_transaction)
      PublishEvent.call(
        event: Events::TransactionApplied.new(balance_transaction),
        schema: "accounting.balance_transactions.transaction_applied",
        version: 1
      )
    end

    def send_email(_daily_payout)
      # @TODO send email
    end
  end
end
