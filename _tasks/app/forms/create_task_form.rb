CreateTaskForm = Dry::Schema.JSON do
  required(:title).filled(:string)
  optional(:description).filled(:string)
end
