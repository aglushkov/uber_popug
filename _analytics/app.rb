class AnalyticsApp < Roda
  class AuthorizationError < StandardError; end

  HEADERS = {"Content-Type" => "application/json"}.freeze

  plugin :request_headers
  plugin :json, serializer: proc { |obj| Oj.dump(obj, mode: :compat) }
  plugin :json_parser, parser: proc { |str| Oj.load(str) }
  plugin :error_handler do |error|
    case error
    when Authenticate::Error
      request.halt [401, HEADERS, [{message: error.message}.to_json]]
    when AnalyticsApp::AuthorizationError
      request.halt [403, HEADERS, [{message: error.message}.to_json]]
    when Sequel::NoMatchingRow
      request.halt [404, HEADERS, [{message: error.message}.to_json]]
    else
      raise error
    end
  end

  route do |request|
    #
    # Shows one completed task per day with largest `completed` cost.
    #
    request.get "best_tasks" do
      current_account = Authenticate.call(request)
      raise AnalyticsApp::AuthorizationError, "Only for admins" unless current_account.admin?

      from = request.GET["from"]
      to = request.GET["to"]
      from = from ? Date.iso8601(from) : Time.now.utc.to_date
      to = to ? Date.iso8601(to) : Time.now.utc.to_date

      best_tasks =
        (from..to).each_with_object({}) do |date, obj|
          date_str = date.iso8601
          from_time = Time.utc(*date_str.split("-"))
          to_time = from_time + 60 * 60 * 24

          tr =
            BalanceTransaction
              .where(created_at: (from_time...to_time))
              .where(type: "task_completed")
              .order(:debit)
              .last

          obj[date.iso8601] = {}
          next unless tr

          task = tr.task
          obj[date.iso8601] = {amount: tr.debit, task_id: task.public_id, title: task.title}
        end

      request.halt [200, HEADERS, [best_tasks.to_json]]
    end

    #
    # Shows totals:
    # - income for each requested day, or for yesterday
    # - count of accounts with negative balance
    #
    request.get "totals" do
      current_account = Authenticate.call(request)
      raise AnalyticsApp::AuthorizationError, "Only for admins" unless current_account.admin?

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
            BalanceTransaction
              .where(operation_name: %w[task_assigned task_completed])
              .where(created_at: (from_time...to_time))
              .get(Sequel.lit("SUM(credit) - SUM(debit)"))

          accounts_with_negative_balance =
            BalanceTransaction
              .select(Sequel.lit("COUNT(*)"))
              .having(Sequel.lit("SUM(debit) - SUM(credit) < 0"))
              .where(created_at: (...to_time))
              .group(:account_id)

          obj[date.iso8601] = {
            income: income,
            accounts_with_negative_balance: accounts_with_negative_balance
          }
        end

      request.halt [200, HEADERS, [totals.to_json]]
    end
  end
end
