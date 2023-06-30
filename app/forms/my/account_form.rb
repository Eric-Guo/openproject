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

class My::AccountForm < ApplicationForm
  form do |f|
    f.text_field(
      name: :username,
      label: User.human_attribute_name(:login),
      input_width: :small,
      value: @user.login,
      readonly: disabled?(:login)
    )

    f.text_field(
      name: :firstname,
      label: User.human_attribute_name(:firstname),
      input_width: :small,
      readonly: disabled?(:firstname),
      caption: disabled_caption(:firstname),
      required: true,
      autocomplete: "given-name"
    )

    f.text_field(
      name: :lastname,
      label: User.human_attribute_name(:lastname),
      input_width: :small,
      readonly: disabled?(:lastname),
      caption: disabled_caption(:lastname),
      required: true,
      autocomplete: "family-name"
    )

    f.text_field(
      name: :mail,
      type: :email,
      label: User.human_attribute_name(:mail),
      input_width: :small,
      readonly: disabled?(:mail),
      caption: disabled_caption(:mail),
      required: true,
      autocomplete: "email"
    )
  end

  def initialize(user:)
    super()
    @user = user

    @contract = Users::UpdateContract.new(@user, User.current)
  end

  def disabled?(attribute)
    !@contract.writable?(attribute)
  end

  def disabled_caption(attribute)
    return nil if @contract.writable?(attribute)

    return externally_managed_attribute_caption if %i[firstname lastname mail].include?(attribute)

    nil
  end

  private

  def externally_managed_attribute_caption
    if @user.identity_url.present?
      I18n.t("user.text_change_disabled_for_provider_login")
    elsif @user.ldap_auth_source_id.present?
      I18n.t("user.text_change_disabled_for_ldap_login")
    end
  end
end
