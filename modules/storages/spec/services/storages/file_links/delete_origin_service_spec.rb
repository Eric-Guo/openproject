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
require_module_spec_helper

RSpec.describe Storages::FileLinks::DeleteOriginService, type: :model do
  let(:storage) { create(:edoc_dds_storage) }
  let(:project_storage) { create(:project_storage, storage:) }
  let(:work_package) { create(:work_package, project: project_storage.project).tap(&:clear_changes_information) }
  let(:file_link) { create(:file_link, container: work_package, storage: project_storage.storage, origin_id: "1337") }
  let(:user) { create(:admin) }
  let(:auth_strategy) { Storages::Adapters::Input::Strategy.build(key: :basic_auth).value! }
  let(:file_info) do
    Storages::Adapters::Results::StorageFileInfo.new(
      status: "ok",
      status_code: 200,
      id: file_link.origin_id,
      name: file_link.origin_name,
      location: "/folder/file.txt"
    )
  end
  let(:file_info_query) { class_double(Storages::Adapters::Providers::EdocDds::Queries::FileInfoQuery) }
  let(:delete_file_command) { class_double(Storages::Adapters::Providers::EdocDds::Commands::DeleteFileCommand) }

  before do
    Storages::Adapters::Registry.stub("#{project_storage.storage}.authentication.user_bound", ->(*) { auth_strategy })
    Storages::Adapters::Registry.stub("#{project_storage.storage}.queries.file_info", file_info_query)
    if project_storage.storage.provider_type_edoc_dds?
      Storages::Adapters::Registry.stub("#{project_storage.storage}.commands.delete_file", delete_file_command)
    end
    allow(file_info_query).to receive(:call).and_return(Dry::Monads::Success(file_info))
  end

  it "deletes the origin file and then the file link" do
    allow(delete_file_command).to receive(:call).and_return(Dry::Monads::Success())

    result = described_class.new(model: file_link, user:, contract_class: Storages::FileLinks::DeleteContract).call

    expect(result).to be_success
    expect(delete_file_command)
      .to have_received(:call)
      .with(
        storage: project_storage.storage,
        auth_strategy:,
        input_data: have_attributes(file_id: file_link.origin_id, location: file_info.location)
      )
    expect(Storages::FileLink.exists?(id: file_link.id)).to be false
  end

  it "keeps the file link when the origin file could not be deleted" do
    allow(delete_file_command)
      .to receive(:call)
      .and_return(Dry::Monads::Failure(Storages::Adapters::Results::Error.new(source: self.class, code: :error)))

    result = described_class.new(model: file_link, user:, contract_class: Storages::FileLinks::DeleteContract).call

    expect(result).not_to be_success
    expect(delete_file_command).to have_received(:call)
    expect(Storages::FileLink.exists?(id: file_link.id)).to be true
  end

  context "with an official storage provider" do
    let(:storage) { create(:nextcloud_storage) }

    it "does not delete the origin file" do
      result = described_class.new(model: file_link, user:, contract_class: Storages::FileLinks::DeleteContract).call

      expect(result).not_to be_success
      expect(file_info_query).not_to have_received(:call)
      expect(Storages::FileLink.exists?(id: file_link.id)).to be true
    end
  end
end
