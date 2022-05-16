module Serializers
  class Tasks
    def self.call(tasks)
      tasks = tasks.map do |task|
        {
          id: task.id,
          public_id: task.public_id,
          title: task.title,
          jira_id: task.jira_id,
          description: task.description
        }
      end

      Oj.dump({tasks: tasks}, mode: :compat)
    end
  end
end
