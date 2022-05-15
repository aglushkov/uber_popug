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
    request.get "best_task" do
      # @WIP
    end

    request.get "totals" do
      # @WIP
    end
  end
end
