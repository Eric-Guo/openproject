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

class WorkPackage::PDFExport::View
  include Prawn::View
  include Redmine::I18n

  def initialize(lang)
    set_language_if_valid lang
  end

  def options
    @options ||= {}
  end

  def info
    @info ||= {
      Creator: OpenProject::Info.app_name,
      CreationDate: Time.now
    }
  end

  def document
    @document ||= Prawn::Document.new(options.merge(info:)).tap do |document|
      register_fonts! document

      document.set_font document.font("NotoSansSC")
      document.fallback_fonts = fallback_fonts
    end
  end

  def fallback_fonts
    [noto_font_base_path.join("NotoSansSymbols2-Regular.ttf")]
  end

  def register_fonts!(document)
    register_font!("NotoSansSC", noto_font_base_path, document)
    register_font!("SpaceMono", spacemono_font_base_path, document)
  end

  def register_font!(family, font_path, document)
    document.font_families[family] = {
      normal: {
        file: font_path.join("#{family}-Regular.ttf"),
        font: "#{family}-Regular"
      },
      italic: {
        file: font_path.join("#{family}-Light.ttf" ""),
        font: "#{family}-Light"
      },
      bold: {
        file: font_path.join("#{family}-SemiBold.ttf"),
        font: "#{family}-SemiBold"
      },
      bold_italic: {
        file: font_path.join("#{family}-Bold.ttf"),
        font: "#{family}-Bold"
      }
    }
  end

  def title=(title)
    info[:Title] = title
  end

  def title
    info[:Title]
  end

  def apply_font(name: nil, font_style: nil, size: nil)
    name ||= document.font.basename.split("-").first # e.g. NotoSans-Bold => NotoSans
    font_opts = {}
    font_opts[:style] = font_style if font_style

    document.font name, font_opts
    document.font_size size if size

    document.font
  end

  private

  def noto_font_base_path
    if RUBY_PLATFORM.include?("darwin")
      Pathname.new("/Users/#{ENV['USER']}/Library/Fonts")
    else
      Rails.public_path.join("fonts/noto")
    end
  end

  def spacemono_font_base_path
    if RUBY_PLATFORM.include?("darwin")
      Pathname.new("/Users/#{ENV['USER']}/Library/Fonts")
    else
      Rails.public_path.join("fonts/spacemono")
    end
  end
end
