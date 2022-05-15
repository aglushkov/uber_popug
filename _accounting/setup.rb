# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default, ENV["RACK_ENV"] || "development")

# Config
Dir["./config/*.rb"].each { |file| require file }

# App files
Dir["./app/**/*.rb"].each { |file| require file }

# Roda App
require "./app"

AccountingApp.freeze
