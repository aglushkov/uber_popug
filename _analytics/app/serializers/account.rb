module Serializers
  class Account
    def self.call(account)
      Oj.dump(
        {
          account: {
            balance: account.balance
          }
        },
        mode: :compat
      )
    end
  end
end
