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

module OpenProject::OpenIDConnect::InvalidStateRedirect
  # omniauth-openid-connect otherwise returns a bare 401 response before the request reaches Rails.
  def callback_phase
    return super unless invalid_callback_state?

    session.delete("omniauth.state")
    redirect "#{request.script_name.to_s.chomp('/')}/"
  end

  private

  def invalid_callback_state?
    return false if params["error_reason"] || params["error"]

    params["state"].to_s.empty? || params["state"] != session["omniauth.state"]
  end
end
