module Serializers
  class Tasks
    def self.call(tasks)
      tasks = tasks.map do |task|
        {
          id: task.id,
          public_id: task.public_id,
          title: task.title,
          description: task.description
        }
      end

      Oj.dump({tasks: tasks}, mode: :compat)
    end
  end
end
