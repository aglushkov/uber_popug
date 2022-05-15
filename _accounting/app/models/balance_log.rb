class BalanceLog < Sequel::Model
  plugin :enum

  many_to_one :account
  many_to_one :daily_payout
  many_to_one :task

  enum :operation_name,
    task_assigned: "task_assigned",
    task_completed: "task_completed",
    payout: "payout"

  def before_create
    self.public_id = SecureRandom.uuid
    super
  end
end
