# frozen_string_literal: true

module Cybros
  class User < ApplicationRecord
    default_scope { where.not(clerk_code: '').where.not(clerk_code: nil) }
    scope :active, -> { where(locked_at: nil).joins(:position_users).distinct }

    has_many :department_users
    has_many :departments, through: :department_users
    has_many :position_users, -> { order(main_position: :desc) }
    has_many :positions, through: :position_users
  end
end
