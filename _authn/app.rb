# frozen_string_literal: true

class AccountsApp < Roda
  class AuthenticationError < StandardError; end
  HEADERS = {"Content-Type" => "application/json"}.freeze

  plugin :json, serializer: proc { |obj| Oj.dump(obj, mode: :compat) }
  plugin :json_parser, parser: proc { |str| Oj.load(str) }
  plugin :error_handler do |error|
    case error
    when Validation::Error
      request.halt [422, HEADERS, [{message: error.message}.to_json]]
    when App::AuthenticationError
      request.halt [401, HEADERS, [{message: error.message}.to_json]]
    else
      raise error
    end
  end

  route do |request|
    #
    # Register new account
    #
    request.post "accounts/register" do
      attrs = Validation.call(request.POST, RegisterForm)

      if Account.find(email: attrs[:email])
        raise Validation::Error, "Account with email '#{attrs[:email]}' already exists"
      end

      account = Account.create(
        role: attrs[:role],
        email: attrs[:email],
        name: attrs[:name],
        public_id: SecureRandom.uuid,
        session_token: SecureRandom.uuid,
        encrypted_password: BCrypt::Password.create(attrs[:password])
      )

      PublishEvent.call(
        event: Events::AccountCreated.new(account),
        schema: "accounts.accounts_streaming.account_created",
        version: 1
      )

      payload = Serializers::Account.call(account)
      headers = HEADERS.merge("pid" => account.public_id, "token" => account.session_token)
      request.halt [201, headers, [payload]]
    end

    #
    # Login
    #
    request.post "accounts/login" do
      attrs = Validation.call(request.POST, LoginForm)
      account = Account.find(email: attrs[:email])

      if account && BCrypt::Password.new(account.encrypted_password) == attrs[:password]
        account.update(session_token: SecureRandom.uuid)

        headers = HEADERS.merge("pid" => account.public_id, "token" => account.session_token)
        request.halt [201, headers, [Serializers::Session.call(account)]]
      else
        request.halt [404, HEADERS, []]
      end
    end

    #
    # Authenticates account using :public_id and :session_token
    #
    request.post "accounts/authenticate" do
      attrs = Validation.call(request.POST, AuthenticateForm)
      account = Account.find(public_id: attrs[:public_id])

      if !account || (account.session_token != attrs[:session_token])
        raise App::AuthenticationError, "Invalid credentials"
      end

      payload = Serializers::Account.call(account)
      request.halt [200, HEADERS, [payload]]
    end
  end
end
