# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  class CustomFieldFormat
    include Redmine::I18n

    class_attribute :registered, default: {}

    attr_reader :name, :order, :label, :edit_as, :class_names, :enterprise_feature

    def initialize(name,
                   label:,
                   order:,
                   edit_as: name,
                   only: nil,
                   multi_value_possible: false,
                   enterprise_feature: nil,
                   enabled: lambda { true },
                   formatter: "CustomValue::StringStrategy")
      @name = name
      @label = label
      @order = order
      @edit_as = edit_as
      @class_names = only
      @multi_value_possible = multi_value_possible
      @enterprise_feature = enterprise_feature
      @enabled = enabled
      @formatter = formatter
    end

    def multi_value_possible?
      @multi_value_possible
    end

    def formatter
      # avoid using stale definitions in dev mode
      Kernel.const_get(@formatter)
    end

    def enabled?
      @enabled.call
    end

    def disabled?
      !enabled?
    end

    class << self
      def map(&)
        yield self
      end

      # Registers a custom field format
      def register(custom_field_format, _options = {})
        registered[custom_field_format.name] = custom_field_format unless registered.include?(custom_field_format.name)
      end

      def available
        registered.select do |_, format|
          format.enabled? && (!format.enterprise_feature)
        end
      end

      def available_formats
        available.keys
      end

      def find_by(name:)
        registered[name.to_s]
      end

      def available_for_class_name(class_name)
        available
          .values
          .select { |field| field.class_names.nil? || field.class_names.include?(class_name) }
          .sort_by(&:order)
          .reject { |format| format.label.nil? }
      end

      def disabled_formats
        registered.select { |_, format| format.disabled? }.keys
      end
    end
  end
end
