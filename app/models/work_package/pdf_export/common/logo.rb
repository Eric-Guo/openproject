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

module WorkPackage::PDFExport::Common::Logo
  def logo_image
    image_obj, image_info = pdf.build_image_object(logo_image_filename)
    [image_obj, image_info]
  end

  def logo_image_filename
    custom_logo_image_filename || Rails.root.join("app/assets/images/logo_plm.png")
  end

  def custom_logo_image_filename
    return unless CustomStyle.current.present? &&
      CustomStyle.current.export_logo.present? && CustomStyle.current.export_logo.local_file.present?

    image_file = CustomStyle.current.export_logo.local_file.path
    content_type = OpenProject::ContentTypeDetector.new(image_file).detect
    return unless pdf_embeddable?(content_type)

    image_file
  end
end
