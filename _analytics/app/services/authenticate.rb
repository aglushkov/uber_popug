class Authenticate
  class Error < StandardError
  end

  AUTH_URL = ENV.fetch("AUTH_URL")
  OK_STATUS = [200, 201].freeze

  class << self
    def call(request)
      public_id = request.headers["pid"]
      session_token = request.headers["token"]

      result = connection.post(
        AUTH_URL,
        json: {public_id: public_id, session_token: session_token}
      )

      raise Error, "Not authenticated" unless OK_STATUS.include?(result.status)

      # create if not found?
      # update attributes if different ?
      # result.json['account']
      Account.find(public_id: public_id) || raise(Sequel::NoMatchingRow)
    end

    private

    def connection
      @connection ||= HTTPX.plugin(:persistent)
    end
  end
end
