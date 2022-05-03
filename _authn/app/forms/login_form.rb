LoginForm = Dry::Schema.JSON do
  required(:email).filled(:string)
  required(:password).filled(:string)
end
