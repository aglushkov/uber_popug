class PublishEvent
  class << self
    def call(event_name, payload, metadata = {})
      topic.publish(payload, routing_key: event_name, **meta(metadata))
    end

    private

    def topic
      @topic ||= BUNNY_CONNECTION.create_channel.topic("app", auto_delete: true)
    end

    def meta(metadata)
      {content_type: "application/json", **metadata}
    end
  end
end
