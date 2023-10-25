# frozen_string_literal: true

module Cybros
  class Position < ApplicationRecord
    belongs_to :department, optional: true

    default_scope { joins(:department).where.not(department: { dept_code: '' }).where.not(department: { dept_code: nil }) }
  end
end
