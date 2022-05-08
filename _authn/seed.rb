require "json"

URL = "http://127.0.0.1:9292/accounts/register"

def payload(counter, role:)
  %(-d '{"email":"email_#{counter}@example.com","password":"password", "name":"name", "role":"worker"}')
end

def register_user(counter, role)
  payload = JSON.dump(
    {
      email: "email_#{counter}@example.com",
      role: role,
      name: "name_#{counter}",
      password: "password"
    }
  )

  [
    "curl", "-i", "-X", "POST", URL,
    "-H", "Content-Type: application/json",
    "-d", payload
  ]
end

(1..20).each do |counter|
  system(*register_user(counter, "worker"))
end

(21..23).each do |counter|
  system(*register_user(counter, "admin"))
end
