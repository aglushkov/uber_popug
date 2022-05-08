class AccountsTask < Sequel::Model
  many_to_one :account
  many_to_one :task

  def self.find!(opts)
    find(opts) || raise(Sequel::NoMatchingRow)
  end

  def completed?
    is_completed
  end

  def uncompleted?
    !completed?
  end
end
