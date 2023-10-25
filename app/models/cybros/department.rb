# frozen_string_literal: true

module Cybros
  class Department < ApplicationRecord
    has_many :department_users
    has_many :users, through: :department_users

    default_scope { where.not(dept_code: '').where.not(dept_code: nil) }
  end
end
