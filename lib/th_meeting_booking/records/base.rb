module ThMeetingBooking::Records
  class Base
    Fields = []

    def initialize(attributes = {})
      hash = attributes.deep_transform_keys { |key| key.to_s.underscore.to_sym }


      self.class::Fields.each do |field|
        self.send("#{field}=", hash[field])
      end
    end
  end
end
