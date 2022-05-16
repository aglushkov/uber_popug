# frozen_string_literal: true

module Events
  module EventPayloadHelper
    private

    def event_payload
      {
        event_id: SecureRandom.uuid,
        event_version: 1,
        event_name: name,
        event_time: Time.now.utc.iso8601(6),
        producer: "accounts_app"
      }
    end
  end
end
