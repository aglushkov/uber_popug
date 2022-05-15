module Serializers
  class DailyPayout
    def self.call(payout)
      Oj.dump(
        {
          daily_payout: {
            date: payout.date.iso8601,
            amount: payout.amount,
            logs: payout.logs.map do |log|
              {
                created_at: log.created_at,
                operation_name: log.operation_name,
                debit: log.debit,
                credit: log.credit
              }
            end
          }
        },
        mode: :compat
      )
    end
  end
end
