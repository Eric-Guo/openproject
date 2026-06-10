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

module Storages
  module Adapters
    module Providers
      module EdocDds
        RSpec.describe Client, :webmock do
          let(:storage) { build_stubbed(:edoc_dds_storage) }
          let(:client) { described_class.new(storage) }
          let(:file) do
            Tempfile.new(["edoc-dds-upload", ".jpeg"]).tap do |tempfile|
              tempfile.write("content")
              tempfile.flush
              tempfile.rewind
            end
          end

          after do
            file.close
            file.unlink
          end

          describe "#post_multipart" do
            it "casts multipart field names and scalar values to strings" do
              response = instance_double(Net::HTTPSuccess, body: { status: "Ok" }.to_json)
              body_data = nil

              allow(client).to receive(:perform_request) do |_uri, request|
                body_data = request.instance_variable_get(:@body_data)
                response
              end

              client.send(
                :post_multipart,
                "https://dds.example.com/document/upload?token=secret-token",
                uploadId: "upload-id",
                chunkSize: 5.megabytes,
                chunk: 0,
                blockSize: 12_345,
                file: file.path
              )

              expect(body_data).to include(
                ["uploadId", "upload-id"],
                ["chunkSize", "5242880"],
                ["chunk", "0"],
                ["blockSize", "12345"]
              )
              expect(body_data.last.first).to eq("file")
              expect(body_data.last.second).to be_a(File)
            end
          end

          describe "#upload" do
            before do
              stub_request(:post, %r{\Ahttps://dds\.example\.com/WebCore})
                .to_return_json(
                  status: 200,
                  body: {
                    result: 0,
                    secondPass: false,
                    data: {
                      FileId: "123",
                      FileVerId: "456",
                      ParentFolderId: "11619178",
                      RegionHash: "region-hash",
                      RegionId: "region-id",
                      RegionType: 1,
                      RegionUrl: nil
                    }
                  }
                )

              stub_request(:post, %r{\Ahttps://dds\.example\.com/document/upload})
                .to_return_json(status: 200, body: { status: "Ok" })
            end

            it "uploads file chunks as multipart form data" do
              result = client.upload(file, folder_id: "11619178", file_name: "G6ltS4qbYAANxtF.jpeg")

              expect(result).to include(
                id: "123",
                file_id: "123",
                file_ver_id: "456",
                folder_id: "11619178",
                name: "G6ltS4qbYAANxtF.jpeg"
              )

              expect(WebMock).to have_requested(:post, %r{\Ahttps://dds\.example\.com/document/upload})
            end
          end
        end
      end
    end
  end
end
