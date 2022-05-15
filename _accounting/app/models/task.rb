class Task < Sequel::Model
  one_to_many :balance_logs

  def self.create_or_find(public_id:, &block)
    task = find(public_id: public_id)
    return task if task

    DB.transaction(savepoint: true) do
      create(public_id: public_id) do |record|
        record.assign_cost = rand(10..20)
        record.complete_cost = rand(20..40)
        block&.call(record)
      end
    end
  rescue Sequel::UniqueConstraintViolation
    find(public_id: public_id) || raise(Sequel::NoMatchingRow)
  end
end
