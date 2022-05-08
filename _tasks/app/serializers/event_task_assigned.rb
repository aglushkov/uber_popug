module Serializers
  class EventTaskAssigned
    def self.call(task, account)
      Oj.dump(
        {
          task: {public_id: task.public_id},
          account: {public_id: account.public_id}
        },
        mode: :compat
      )
    end
  end
end
