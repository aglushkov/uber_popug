class Account < Sequel::Model
  plugin :enum

  enum :role, worker: "worker", admin: "admin", accountant: "accountant"

  one_to_many :balance_logs
  one_to_many :daily_payouts

  def self.create_or_find(public_id:, &block)
    account = find(public_id: public_id)
    return account if account

    DB.transaction(savepoint: true) { create(public_id: public_id, &block) }
  rescue Sequel::UniqueConstraintViolation
    find(public_id: public_id) || raise(Sequel::NoMatchingRow)
  end
end
