# frozen_string_literal: true

require_relative './event_payload_helper'

module Events
  class AccountCreated
    include EventPayloadHelper

    attr_reader :account

    def initialize(account)
      @account = account
    end

    def name
      'account_created'
    end

    def topic
      'accounts_streaming'
    end

    def payload
      {
        **event_payload,
        data: {
          public_id: account.public_id,
          name: account.name,
          role: account.role
        }
      }
    end
  end
end
