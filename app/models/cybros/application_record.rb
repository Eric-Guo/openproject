# frozen_string_literal: true

module Cybros
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.default_timezone = :local
    establish_connection :cybros unless Rails.env.test?
  end
end
