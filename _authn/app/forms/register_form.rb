RegisterForm = Dry::Schema.JSON do
  required(:email).filled(:string)
  required(:name).filled(:string)
  required(:password).filled(:string)
  required(:role).filled(:string, included_in?: %w[admin worker])
end
