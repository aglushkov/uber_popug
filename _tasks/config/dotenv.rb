if defined?(Dotenv)
  app_env = ENV["RACK_ENV"] || "development"
  dotenv_files = [
    ".env.#{app_env}.local",
    ".env.#{app_env}",
    ".env"
  ]
  Dotenv.load(*dotenv_files)
end
