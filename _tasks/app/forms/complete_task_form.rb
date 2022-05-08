CompleteTaskForm = Dry::Schema.JSON do
  required(:task_id).filled(:integer)
end
