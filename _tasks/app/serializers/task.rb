module Serializers
  class Task
    def self.call(task)
      Oj.dump(
        {
          task: {
            id: task.id,
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
