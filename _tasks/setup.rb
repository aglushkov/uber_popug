require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  ruby "3.1.0"

  gem "roda"
  gem "puma"
  gem "pg"
  gem "bunny"
  gem "dry-schema"
  gem "sequel"
  gem "oj"
  gem "bcrypt"
  gem "httpx"
  gem "dotenv"
  gem "debug"
end

# Gems
require "roda"
require "puma"
require "pg"
require "dry-schema"
require "sequel"
require "oj"
require "bcrypt"
require "httpx"
require "dotenv"
require "debug"
require "securerandom"

# Config
require "./config/bcrypt"
require "./config/dotenv"
require "./config/dry-schema"
require "./config/sequel"
require "./config/bunny"

# Models
require "./app/models/account"
require "./app/models/task"
require "./app/models/accounts_task"

# Forms
require "./app/forms/complete_task_form"
require "./app/forms/create_task_form"

# Services
require "./app/services/authenticate"
require "./app/services/publish_event"
require "./app/services/validation"

# Serializers
require "./app/serializers/event_task_assigned"
require "./app/serializers/event_task_completed"
require "./app/serializers/event_task_created"
require "./app/serializers/task"
require "./app/serializers/tasks"

# App
require "./app"

App.freeze
