# frozen_string_literal: true

module EventSubscriptions
  module WithHelper
    private

    def with(topic_name:, event_name:, schema:, version:, &block)
      queue = connect_to_queue(topic_name, event_name)

      queue.subscribe do |_delivery_info, _metadata, json_payload|
        payload = parse_payload(json_payload, schema: schema, version: version)
        block.call(payload.fetch(:data)) if payload
      rescue # rescue from any error
        # @TODO: save event data somewhere
        raise
      end
    end

    def connect_to_queue(topic_name, event_name)
      channel = BunnyChannel.connection
      exchange = channel.topic(topic_name, auto_delete: true)
      channel.queue("").bind(exchange, routing_key: event_name)
    end

    def parse_payload(json_payload, schema:, version:)
      validation_result = SchemaRegistry.validate_event(json_payload, schema, version: version)

      if validation_result.success?
        Oj.load(json_payload, symbol_keys: true)
      else
        handle_invalid_payload(json_payload, validation_result.failure)
        nil
      end
    end

    def handle_invalid_payload(json_payload, error_messages)
      # @TODO: save or log error somewhere
    end
  end
end
