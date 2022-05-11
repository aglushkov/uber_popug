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
  gem "dotenv"
  gem "debug"
end

require "roda"
require "puma"
require "pg"
require "dry-schema"
require "sequel"
require "oj"
require "bcrypt"
require "dotenv"
require "debug"
require "securerandom"

# Config
require "./config/bcrypt"
require "./config/dotenv"
require "./config/dry-schema"
require "./config/sequel"
require "./config/bunny"

# Forms
require "./app/forms/register_form"
require "./app/forms/login_form"
require "./app/forms/authenticate_form"

# Models
require "./app/models/account"

# Serializers
require "./app/serializers/account"
require "./app/serializers/event_account_created"
require "./app/serializers/session"

# Services
require "./app/services/validation"
require "./app/services/publish_event"

# App
require "./app"

App.freeze
