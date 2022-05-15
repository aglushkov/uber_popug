class AccountingApp < Roda
  class AuthorizationError < StandardError; end

  HEADERS = {"Content-Type" => "application/json"}.freeze

  plugin :request_headers
  plugin :json, serializer: proc { |obj| Oj.dump(obj, mode: :compat) }
  plugin :json_parser, parser: proc { |str| Oj.load(str) }
  plugin :error_handler do |error|
    case error
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
      raise AccountingApp::AuthorizationError, "Only workers can view their balance" unless current_account.worker?

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
      raise AccountingApp::AuthorizationError, "Only workers can view their balance" unless current_account.worker?

      date_param = request.GET['date']
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
    request.get "dashboard" do
      current_account = Authenticate.call(request)
      raise AccountingApp::AuthorizationError, "Only admins and accountants can view dashboard" if current_account.worker?

      from = request.GET["from"]
      to = request.GET["to"]
      from = from ? Date.iso8601(from) : Time.now.utc.to_date
      to = to ? Date.iso8601(to) : Time.now.utc.to_date

      totals =
        (from..to).each_with_object({}) do |date, obj|
          date_str = date.iso8601
          from_time = Time.utc(*date_str.split("-"))
          to_time = from_time + 60 * 60 * 24

          income =
            BalanceLog
              .where(operation_name: %w[task_assigned task_completed])
              .where(created_at: (from_time...to_time))
              .get(Sequel.lit("SUM(credit_amount) - SUM(debit_amount)"))

          obj[date.iso8601] = income
        end

      request.halt [200, HEADERS, [totals.to_json]]
    end

    #
    # Simulating CRON job by running it manually
    #
    # curl -i -X POST http://127.0.0.1:9294/daily_payouts
    #
    request.post "daily_payouts" do
      DailyPayouts::Generate.new.call # actions/daily_payots/generate.rb

      request.halt [200, HEADERS, []]
    end
  end
end
