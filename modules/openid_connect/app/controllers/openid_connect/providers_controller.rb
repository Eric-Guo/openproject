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

module OpenIDConnect
  class ProvidersController < ::ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :plugin_openid_connect

    before_action :require_admin
    before_action :find_provider, only: %i[edit show update confirm_destroy destroy]
    before_action :set_edit_state, only: %i[create edit update]

    def index
      @providers = ::OpenIDConnect::Provider.all
    end

    def show; end

    def new
      oidc_provider = case params[:oidc_provider]
                      when "google"
                        "google"
                      when "microsoft_entra"
                        "microsoft_entra"
                      else
                        "custom"
                      end
      @provider = OpenIDConnect::Provider.new(oidc_provider:)
    end

    def create
      create_params = params
                        .require(:openid_connect_provider)
                        .permit(:display_name, :oidc_provider, :tenant)

      call = ::OpenIDConnect::Providers::CreateService
        .new(user: User.current)
        .call(**create_params)

      @provider = call.result

      if call.success?
        successful_save_response
      else
        failed_save_response(:new)
      end
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          component = OpenIDConnect::Providers::ViewComponent.new(@provider,
                                                                  view_mode: :edit,
                                                                  edit_mode: @edit_mode,
                                                                  edit_state: @edit_state)
          update_via_turbo_stream(component:)
          scroll_into_view_via_turbo_stream("openid-connect-providers-edit-form", behavior: :instant)
          render turbo_stream: turbo_streams
        end
        format.html
      end
    end

    def update
      update_params = params
                        .require(:openid_connect_provider)
                        .permit(:display_name, :oidc_provider, :limit_self_registration,
                                *OpenIDConnect::Provider.stored_attributes[:options])
      call = OpenIDConnect::Providers::UpdateService
        .new(model: @provider, user: User.current, fetch_metadata: fetch_metadata?)
        .call(update_params)

      if call.success?
        successful_save_response
      else
        @provider = call.result
        failed_save_response(:edit)
      end
    end

    def confirm_destroy; end

    def destroy
      if @provider.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = @provider.errors.full_messages
      end

      redirect_to action: :index
    end

    private

    def find_provider
      @provider = OpenIDConnect::Provider.find(params[:id])
    end

    def successful_save_response
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: OpenIDConnect::Providers::ViewComponent.new(
              @provider,
              edit_mode: @edit_mode,
              edit_state: @next_edit_state,
              view_mode: :show
            )
          )
          render turbo_stream: turbo_streams
        end
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update) unless @edit_mode
          if @edit_mode && @next_edit_state
            redirect_to edit_openid_connect_provider_path(@provider,
                                                          anchor: "openid-connect-providers-edit-form",
                                                          edit_mode: true,
                                                          edit_state: @next_edit_state)
          else
            redirect_to openid_connect_provider_path(@provider)
          end
        end
      end
    end

    def failed_save_response(action_to_render)
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: OpenIDConnect::Providers::ViewComponent.new(
              @provider,
              edit_mode: @edit_mode,
              edit_state: @edit_state,
              view_mode: :show
            )
          )
          render turbo_stream: turbo_streams
        end
        format.html do
          render action: action_to_render, status: :unprocessable_entity
        end
      end
    end

    def set_edit_state
      @edit_state = params[:edit_state].to_sym if params.key?(:edit_state)
      @edit_mode = ActiveRecord::Type::Boolean.new.cast(params[:edit_mode])
      @next_edit_state = params[:next_edit_state].to_sym if params.key?(:next_edit_state)
    end

    def fetch_metadata?
      params[:fetch_metadata] == "true"
    end
  end
end
