module Serializers
  class EventTaskCreated
    def self.call(task)
      Oj.dump(
        {
          task: {
            public_id: task.public_id,
            title: task.title,
            description: task.description
          }
        },
        mode: :compat
      )
    end
  end
end
