AuthenticateForm = Dry::Schema.JSON do
  required(:public_id).filled(:string)
  required(:session_token).filled(:string)
end
