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

require "spec_helper"

RSpec.describe "type export configuration tab", :js do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }

  let!(:project) { create(:project, types: [type]) }

  before do
    login_as(admin)
    visit edit_type_pdf_export_template_index_path(type)
  end

  def within_pdf_export_template_container(template_id, &)
    within("[data-test-selector='pdf-export-template-row-#{template_id}']", &)
  end

  def toggle_pdf_export_template(template_id)
    page
      .find("[data-test-selector='toggle-pdf-export-template-row-#{template_id}'] > button")
      .click
  end

  def drag_pdf_export_template_below(template_id, target_id)
    source_handle = page.find("[data-test-selector='pdf-export-template-row-#{template_id}'] .DragHandle")
    target_row = page.find("[data-test-selector='pdf-export-template-row-#{target_id}']")

    if using_cuprite?
      drop_url = drop_type_pdf_export_template_path(type_id: type.id, id: template_id)
      csrf_token = page.find("meta[name='csrf-token']", visible: false)[:content]

      result = page.driver.evaluate_async_script(<<~JS, drop_url, csrf_token)
        const [url, csrfToken, done] = arguments;

        fetch(url, {
          method: 'PUT',
          credentials: 'same-origin',
          headers: {
            'Accept': 'text/vnd.turbo-stream.html',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-CSRF-Token': csrfToken,
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: new URLSearchParams({ position: '2' })
        })
          .then(async (response) => {
            const body = await response.text();

            if (!response.ok) {
              throw new Error(`Request failed with status ${response.status}`);
            }

            window.Turbo.renderStreamMessage(body);
            done({ success: true });
          })
          .catch((error) => done({ success: false, error: error.message }));
      JS

      raise result["error"] unless result["success"]
    else
      wait_for_turbo_stream do
        source_handle.native.drag_to(target_row.native, delay: 0.1)
      end
      sleep 1
    end
  end

  def expect_checked_state
    expect(page).to have_css(".ToggleSwitch-statusOn")
  end

  def expect_unchecked_state
    expect(page).to have_css(".ToggleSwitch-statusOff")
  end

  it "disables/enables all" do
    page.find("[data-test-selector='disable-all-pdf-export-templates']").click
    wait_for_reload
    type.reload
    expect(type.pdf_export_templates.list_enabled.length).to eq(0)
    page.find("[data-test-selector='enable-all-pdf-export-templates']").click
    wait_for_reload
    type.reload
    expect(type.pdf_export_templates.list_enabled.length).to eq(type.pdf_export_templates.list.length)
  end

  it "disables/enables one" do
    first = type.pdf_export_templates.list_enabled.first
    within_pdf_export_template_container(first.id) do
      expect_checked_state
      toggle_pdf_export_template(first.id)
      expect_unchecked_state
      wait_for_reload
      type.reload
      expect(type.pdf_export_templates.list.first.enabled).to be(false)
      toggle_pdf_export_template(first.id)
      expect_checked_state
      wait_for_reload
      type.reload
      expect(type.pdf_export_templates.list.first.enabled).to be(true)
    end
  end

  it "reorders by drag and drop" do
    first_id = type.pdf_export_templates.list_enabled.first.id
    second_id = type.pdf_export_templates.list_enabled[1].id
    drag_pdf_export_template_below(first_id, second_id)

    type.reload
    expect(type.pdf_export_templates.list[1].id).to eq(first_id)
    expect(type.pdf_export_templates.list.first.id).to eq(second_id)
  end
end
