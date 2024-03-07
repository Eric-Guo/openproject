module ThAnnotationDocuments::Callbacks
  class Base
    FIELDS = [].freeze

    def initialize(attributes = {})
      hash = attributes.deep_transform_keys { |key| key.to_s.underscore.to_sym }

      self.class::FIELDS.each do |field|
        send("#{field}=", hash[field])
      end
    end

    def call
      raise NotImplementedError, 'You must implement the #write_to_db method in your subclass'
    end
  end
end
