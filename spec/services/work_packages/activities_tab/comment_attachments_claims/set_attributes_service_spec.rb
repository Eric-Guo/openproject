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

RSpec.describe WorkPackages::ActivitiesTab::CommentAttachmentsClaims::SetAttributesService do
  let(:user) { build_stubbed(:user) }

  let(:journal) { build_stubbed(:work_package_journal, notes:) }

  subject(:set_attributes_service) do
    described_class.new(
      user:,
      model: journal,
      contract_class: EmptyContract
    ).call
  end

  describe "#call" do
    context "when the journal notes have attachments" do
      let(:attachment1) { build_stubbed(:attachment, container: nil) }
      let(:attachment2) { build_stubbed(:attachment, container: nil) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">
          Lorem ipsum dolor sit amet
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">
          consectetur adipiscing elit
        HTML
      end

      before do
        relation = double("ActiveRecord::Relation")

        # SQL-level filtering chain used by the service
        allow(Attachment).to receive(:where).with(container: nil).and_return(relation)
        allow(Attachment).to receive(:where).with(container: journal).and_return(relation)
        allow(relation).to receive(:or).with(anything).and_return(relation)
        allow(relation).to receive(:where).with(id: [attachment1.id.to_s, attachment2.id.to_s]).and_return(relation)
        allow(relation).to receive(:pluck).with(:id).and_return([attachment1.id, attachment2.id])

        # Final lookup for replacements inside Attachments::SetReplacements
        allow(Attachment).to receive(:where)
          .with(id: [attachment1.id.to_s, attachment2.id.to_s])
          .and_return([attachment1, attachment2])
      end

      it "sets the attachments replacements" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to contain_exactly(attachment1, attachment2)
      end
    end

    context "when the journal notes reference an attachment already assigned to a container" do
      let(:assigned_attachment) { build_stubbed(:attachment, container: build_stubbed(:work_package)) }
      let(:unattached_attachment) { build_stubbed(:attachment, container: nil) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{assigned_attachment.id}/content">
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{unattached_attachment.id}/content">
        HTML
      end

      before do
        relation = double("ActiveRecord::Relation")

        # SQL-level filtering chain used by the service
        allow(Attachment).to receive(:where).with(container: nil).and_return(relation)
        allow(Attachment).to receive(:where).with(container: journal).and_return(relation)
        allow(relation).to receive(:or).with(anything).and_return(relation)
        allow(relation).to receive(:where).with(id: [assigned_attachment.id.to_s,
                                                     unattached_attachment.id.to_s]).and_return(relation)
        # Only the unattached one should be returned by the filter
        allow(relation).to receive(:pluck).with(:id).and_return([unattached_attachment.id])

        # Final lookup for replacements inside Attachments::SetReplacements
        allow(Attachment).to receive(:where)
          .with(id: [unattached_attachment.id.to_s])
          .and_return([unattached_attachment])
      end

      it "filters out the assigned attachment and only sets unattached ones" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to contain_exactly(unattached_attachment)
      end
    end

    context "when the journal notes have no attachments" do
      let(:notes) { "Lorem ipsum dolor sit amet" }

      it "defines empty attachments" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to be_empty
      end
    end

    context "when the journal notes are nil" do
      let(:notes) { nil }

      it "defines atttachments as empty" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to be_empty
      end
    end
  end
end
