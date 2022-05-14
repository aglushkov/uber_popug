# frozen_string_literal: true

require_relative './with_helper'

module EventSubscriptions
  class AccountCreated
    extend WithHelper

    class << self
      def subscribe(topic_name:, event_name:, schema:, version:)
        with(topic_name: topic_name, event_name: event_name, schema: schema, version: version) do |data|
          Account.find_or_create(public_id: data.fetch(:public_id)) do |account|
            account.name = data.fetch(:name)
            account.role = data.fetch(:role)
          end
        end
      end
    end
  end
end

EventSubscriptions::AccountCreated.subscribe(
  topic_name: 'accounts_streaming',
  event_name: 'account_created',
  schema: 'accounts.accounts_streaming.account_created',
  version: 1
)
