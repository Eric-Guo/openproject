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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Authentication
    module Strategies
      module Warden
        class SharedSecretJwt < ::Warden::Strategies::Base
          include FailWithHeader

          def valid?
            @access_token = ::Doorkeeper::OAuth::Token.from_bearer_authorization(
              ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
            )
            return false if @access_token.blank?
            return false if shared_secret.blank?

            unverified_payload, unverified_header = JWT.decode(@access_token, nil, false)
            unverified_payload.present? && unverified_header["alg"] == "HS256"
          rescue JWT::DecodeError
            false
          end

          def authenticate!
            payload = decoded_jwt_payload(verify_expiration: true)
            return fail_with_header!(error: "invalid_token") if payload.blank?

            subject = payload["sub"].to_s.strip
            return fail_with_header!(error: "invalid_token") if subject.blank?

            authentication_result(User.find_by(mail: subject))
          end

          private

          def decoded_jwt_payload(verify_expiration:)
            jwt_secret = shared_secret
            return if jwt_secret.blank?

            JWT.decode(
              @access_token,
              jwt_secret,
              true,
              algorithm: "HS256",
              verify_expiration:,
              required_claims: ["exp"]
            ).first
          rescue JWT::DecodeError, TypeError, ArgumentError
            nil
          end

          def shared_secret
            Rails.application.credentials.devise_jwt_secret_key.presence ||
              ENV["THAPE_SSO_JWT_SECRET_KEY"].presence
          end

          def authentication_result(user)
            if user.nil?
              return fail_with_header!(
                error: "invalid_token",
                error_description: "The user identified by the token is not known"
              )
            end

            if user.active?
              success!(user)
            else
              fail_with_header!(
                error: "invalid_token",
                error_description: "The user account is locked"
              )
            end
          end
        end
      end
    end
  end
end
