class DailyPayout < Sequel::Model
  one_to_many :balance_logs
  many_to_one :account
end
