require "securerandom"

module Utils
  class RandID
    def self.call
      SecureRandom.rand(1000..9999)
    end
  end
end
