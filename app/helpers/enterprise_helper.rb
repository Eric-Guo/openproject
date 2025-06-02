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

module EnterpriseHelper
  ##
  # Renders the enterprise banner component with a guard for the given feature key.
  # If the feature is not enabled, it will not render the given block.
  def with_enterprise_banner_guard(feature_key, **args)
    concat(render(EnterpriseEdition::BannerComponent.new(feature_key, **args)))
    yield
  end

  def enterprise_angular_trial_inputs
    trial_key = Token::EnterpriseTrialKey.find_by(user_id: User.system.id)

    if EnterpriseToken.active? || trial_key.blank?
      enterprise_angular_static_inputs
    else
      enterprise_angular_static_inputs.merge(
        trialKey: trial_key.value,
        trialCreatedAt: trial_key.created_at.to_date.iso8601
      )
    end
  end

  def enterprise_angular_static_inputs
    {
      augurUrl: OpenProject::Configuration.enterprise_trial_creation_host,
      tokenVersion: OpenProject::Token::VERSION
    }
  end

  def enterprise_token_plan_name(enterprise_token)
    plan = enterprise_token.plan.to_s
    I18n.t(plan, scope: [:enterprise_plans], default: plan.humanize)
  end

  def enterprise_plan_additional_features(enterprise_token)
    (enterprise_token.try(:features) || [])
      .filter_map { |feature| I18n.t(feature, scope: :"ee.features", default: nil) }
      .sort
      .join(", ")
  end
end
