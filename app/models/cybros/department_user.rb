# frozen_string_literal: true

module Cybros
  class DepartmentUser < ApplicationRecord
    belongs_to :department
    belongs_to :user
  end
end
