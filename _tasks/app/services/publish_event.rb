# frozen_string_literal: true

class PublishEvent
  class Error < StandardError
  end

  class InvalidPayload < Error
  end

  class << self
    def call(event:, schema:, version:)
      payload = event.payload
      validation_result = SchemaRegistry.validate_event(payload, schema, version: version)

      if validation_result.success?
        publish(topic_name: event.topic, event_name: event.name, payload: payload)
      else
        handle_invalid_payload(event, validation_result.failure)
      end
    end

    private

    def publish(topic_name:, event_name:, payload:)
      puts <<~MESSAGE
        Publish Event:
          topic_name: #{topic_name}
          event_name: #{event_name}
          payload: #{payload}
      MESSAGE

      json_payload = Oj.dump(payload, mode: :compat)
      topics(topic_name).publish(json_payload, routing_key: event_name)
    rescue Bunny::Exception => error
      handle_message_broker_exception(event, error)
    end

    def handle_invalid_payload(event, error_messages)
      # @TODO: save event somewhere in `invalid_events` storage
      raise InvalidPayload, error_messages.join("\n")
    end

    def handle_message_broker_exception(_event, error)
      # @TODO: publish event in asynchronous job
      raise error
    end

    def topics(topic_name)
      @topics ||= {}
      @topics[topic_name] ||= BunnyChannel.connection.topic(topic_name, auto_delete: true)
    end
  end
end
