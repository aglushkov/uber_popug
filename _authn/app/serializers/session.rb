module Serializers
  class Session
    def self.call(account)
      Oj.dump(
        {
          pid: account.public_id,
          token: account.session_token
        },
        mode: :compat
      )
    end
  end
end
