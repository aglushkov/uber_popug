Sequel.extension :migration
Sequel::Model.plugin :timestamps, update_on_create: true

DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
DB.extension(:pagination)
Sequel::Migrator.run(DB, "./db/migrate")

DB.logger = Logger.new($stdout)
