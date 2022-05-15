class AccountingApp < Roda
  class AuthorizationError < StandardError; end

  HEADERS = {"Content-Type" => "application/json"}.freeze

  plugin :request_headers
  plugin :json, serializer: proc { |obj| Oj.dump(obj, mode: :compat) }
  plugin :json_parser, parser: proc { |str| Oj.load(str) }
  plugin :error_handler do |error|
    case error
    when Validation::Error
      request.halt [422, HEADERS, [{message: error.message}.to_json]]
    when Authenticate::Error
      request.halt [401, HEADERS, [{message: error.message}.to_json]]
    when AccountingApp::AuthorizationError
      request.halt [403, HEADERS, [{message: error.message}.to_json]]
    when Sequel::NoMatchingRow
      request.halt [404, HEADERS, [{message: error.message}.to_json]]
    else
      raise error
    end
  end

  route do |request|
    #
    # Returns current worker balance information
    #
    # curl -i -H "pid: 8335" -H "token: 8330" http://127.0.0.1:9294/balance
    #
    request.get "balance" do
      current_account = Authenticate.call(request)
      raise App::AuthorizationError, "Only workers can view their balance" unless current_account.worker?

      balance_payload = Serializers::Account.call(current_account)
      request.halt [200, HEADERS, [balance_payload]]
    end

    #
    # Returns current worker daily payout information
    #
    # curl -i -H "pid: 8335" -H "token: 8330" http://127.0.0.1:9294/daily_payout
    #
    request.get "daily_payout" do
      current_account = Authenticate.call(request)
      raise App::AuthorizationError, "Only workers can view their balance" unless current_account.worker?

      date = date_param ? Date.iso8601(date_param) : Time.now.utc.to_date.iso8601
      payout = DailyPayout.find(account_id: current_account.id, date: date)

      payload =
        if payout
          Serializers::DailyPayout.call(payout)
        else
          {message: "No payout on #{date}"}.to_json
        end

      request.halt [200, HEADERS, [payload]]
    end

    #
    # Returns totals for admins and accountants
    #
    # curl -i -H "pid: 8335" -H "token: 8330" http://127.0.0.1:9294/totals
    #
    request.get "totals" do
      current_account = Authenticate.call(request)
      raise App::AuthorizationError, "Only admins and accountants can view totals" if current_account.worker?

      # WIP
      # date = date_param ? Date.iso8601(date_param) : Time.now.utc.to_date.iso8601

      payload = "{}"
      request.halt [200, HEADERS, [payload]]
    end

    #
    # Simulating CRON job by running it manually
    #
    # curl -i -X POST http://127.0.0.1:9294/daily_payouts
    #
    request.post "daily_payouts" do
      date = Time.now.utc.to_date

      transactions =
        BalanceLog
          .where(operation_name: ["task_assigned", "task_completed"])
          .where(daily_payout_id: nil)
          .select_map([:account_id, :id, :debit_amount, :credit_amount])
          .group_by(&:first)

      transactions.each do |account_id, transactions|
        transaction_ids = transactions.map { |transaction| transaction[1] }
        debit = transactions.sum { |transaction| transaction[2] }
        credit = transactions.sum { |transaction| transaction[3] }
        total = debit - credit

        if total > 0
          balance_transaction =
            DB.transaction do
              account = Account.for_update[id: account_id]
              next if DailyPayout[account_id: account.id, date: date]

              daily_payout = DailyPayout.create(account_id: account.id, amount: total, date: date)

              # Set daily_payout_id so transactions will not be used in other payouts
              BalanceLog.where(id: transaction_ids).update(daily_payout_id: daily_payout.id)

              # Add payout transaction
              BalanceLog.create(account_id: account.id, credit_amount: total, operation_name: "payout").tap do |rec|
                account.update(balance: account.balance - rec.credit_amount)
              end
            end

          if balance_transaction
            PublishEvent.call(
              event: Events::TransactionApplied.new(balance_transaction),
              schema: "accounting.balance_transactions.transaction_applied",
              version: 1
            )

            # @TODO send email
            # AsyncEmailJob.(account, balance_transaction)
          end
        end
      end

      request.halt [200, HEADERS, []]
    end
  end
end
