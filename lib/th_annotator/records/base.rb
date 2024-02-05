module ThAnnotator::Records
  class Base
    FIELDS = [].freeze

    def initialize(attributes = {})
      hash = attributes.deep_transform_keys { |key| key.to_s.underscore.to_sym }

      self.class::FIELDS.each do |field|
        send("#{field}=", hash[field])
      end
    end
  end
end
