module Validation
  class Error < StandardError
  end

  def self.call(data, form_schema)
    result = form_schema.call(data)
    errors = result.errors(full: true)
    errors.any? ? raise(Error, errors.to_h.values.flatten.join("\n")) : result.to_h
  end
end
