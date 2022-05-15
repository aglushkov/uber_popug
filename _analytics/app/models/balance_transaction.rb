class BalanceTransaction < Sequel::Model
  plugin :enum

  many_to_one :account
  many_to_one :task

  enum :type,
    task_assigned: "task_assigned",
    task_completed: "task_completed",
    payout: "payout"

  def self.create_or_find(public_id:, &block)
    record = find(public_id: public_id)
    return record if record

    DB.transaction(savepoint: true) { create(public_id: public_id, &block) }
  rescue Sequel::UniqueConstraintViolation
    find(public_id: public_id) || raise(Sequel::NoMatchingRow)
  end
end
