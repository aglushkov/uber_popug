module Serializers
  class EventAccountCreated
    def self.call(account)
      Oj.dump(
        {
          account: {
            public_id: account.public_id,
            name: account.name,
            role: account.role
          }
        },
        mode: :compat
      )
    end
  end
end
