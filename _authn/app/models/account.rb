class Account < Sequel::Model
  plugin :enum

  enum :role, worker: "worker", admin: "admin", accountant: "accountant"
end
