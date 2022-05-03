module Serializers
  class Account
    def self.call(account)
      Oj.dump(
        {
          account: {
            public_id: account.public_id,
            name: account.name,
            email: account.email,
            role: account.role
          }
        },
        mode: :compat
      )
    end
  end
end
