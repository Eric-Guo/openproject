# frozen_string_literal: true

module Cybros
  class PositionUser < ApplicationRecord
    belongs_to :user
    belongs_to :position

    delegate :name, to: :position, prefix: :position
  end
end
