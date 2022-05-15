# frozen_string_literal: true

class BunnyChannel
  def self.connection
    @connection ||= begin
      bunny = Bunny.new
      bunny.start
      bunny.create_channel
    end
  end
end
