class Task < Sequel::Model
  one_to_many :balance_logs

  def self.create_or_find(public_id:, &block)
    task = find(public_id: public_id)
    return task if task

    DB.transaction(savepoint: true) { create(public_id: public_id, &block) }
  rescue Sequel::UniqueConstraintViolation
    find(public_id: public_id) || raise(Sequel::NoMatchingRow)
  end
end
