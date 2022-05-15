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
    when App::AuthorizationError
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
          {message: "No check for date #{date}"}.to_json
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
  end
end
