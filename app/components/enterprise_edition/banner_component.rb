# frozen_string_literal: true

# -- copyright
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
# ++

module EnterpriseEdition
  # A banner indicating that a given feature requires the enterprise edition of OpenProject.
  # This component uses conventional names for translation keys or URL look-ups based on the feature_key passed in.
  # It will only be rendered if necessary.
  class BannerComponent < ApplicationComponent
    include Primer::FetchOrFallbackHelper
    include Primer::ClassNameHelper
    include Primer::JoinStyleArgumentsHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include PlanForFeature

    DEFAULT_VARIANT = :inline
    VARIANT_OPTIONS = %i[inline medium large].freeze

    # @param feature_key [Symbol, NilClass] The key of the feature to show the banner for.
    # @param variant [Symbol, NilClass] The variant of the banner component.
    # @param image [String, NilClass] Path to the image to show on the banner, or nil.
    #   Only applicable and required when variant is :medium.
    # @param video [String, NilClass] Path to the video to show on the banner, or nil.
    #   Only applicable and required when variant is :video.
    # @param i18n_scope [String] Provide the i18n scope to look for title, description, and features.
    #                            Defaults to "ee.upsell.{feature_key}"
    # @param dismissable [boolean] Allow this banner to be dismissed.
    # @param show_always [boolean] Always show the banner, regardless of the dismissed or feature state.
    # @param dismiss_key [String] Provide a string to identify this banner when being dismissed. Defaults to feature_key
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(feature_key,
                   variant: DEFAULT_VARIANT,
                   image: nil,
                   video: nil,
                   i18n_scope: "ee.upsell.#{feature_key}",
                   dismissable: false,
                   show_always: false,
                   dismiss_key: feature_key,
                   **system_arguments)
      @variant = fetch_or_fallback(VARIANT_OPTIONS, variant, DEFAULT_VARIANT)
      @image = image
      @video = video
      @dismissable = dismissable
      @dismiss_key = dismiss_key.to_s

      @show_always = show_always

      self.feature_key = feature_key
      self.i18n_scope = i18n_scope

      trial_overrides! if trial_feature?

      if @variant == :medium && @image.nil?
        raise ArgumentError, "The 'image' parameter is required when the variant is :medium."
      end

      if @variant == :large && @video.nil?
        raise ArgumentError, "The 'video' parameter is required when the variant is :large."
      end

      set_system_arguments(system_arguments, feature_key)

      super
    end

    def before_render
      @image_arguments = {}
      @image_arguments[:style] = @image.present? ? "background-image: url(#{helpers.image_path(@image)})" : nil
    end

    def medium?
      @variant == :medium
    end

    def large?
      @variant == :large
    end

    def inline?
      @variant == :inline
    end

    def wrapper_key
      "enterprise_banner_#{@dismiss_key}"
    end

    private

    def set_system_arguments(system_arguments, feature_key)
      @system_arguments = system_arguments
      @system_arguments[:tag] = :div
      @system_arguments[:mb] ||= 2
      @system_arguments[:id] = "op-enterprise-banner-#{feature_key.to_s.tr('_', '-')}"
      @system_arguments[:test_selector] = "op-enterprise-banner"
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "op-enterprise-banner",
        "op-enterprise-banner_medium" => @variant == :medium,
        "op-enterprise-banner_large" => @variant == :large,
        "op-enterprise-banner_trial" => trial_feature?
      )
    end

    def trial_overrides!
      @dismissable = true
      @dismiss_key += "_trial" unless @dismiss_key.end_with?("_trial")
      @variant = :inline
    end

    def render?
      return true if @show_always
      return false if dismissed?
      return true if feature_available? && trial_feature?
      return false if EnterpriseToken.hide_banners?

      !feature_available?
    end

    def feature_available?
      true
    end

    def dismissed?
      return false unless @dismissable

      User.current.pref.dismissed_banner?(@dismiss_key)
    end

    def trial_feature?
      EnterpriseToken.trialling?(feature_key)
    end
  end
end
