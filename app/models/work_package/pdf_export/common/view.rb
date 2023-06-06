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

class WorkPackage::PDFExport::Common::View
  include Prawn::View
  include Redmine::I18n

  FONT_SPEC = {
    latin: [
      { name: "NotoSans", path: "noto" }
    ],
    mono: [
      { name: "SpaceMono", path: "spacemono" }
    ],
    fonts: [
      { name: "GoNotoKurrent", path: "noto-kurrent" }
    ],
    symbols: [
      { name: "NotoEmoji", path: "noto-emoji" },
      { name: "NotoSansSymbols2", path: "noto-symbols" },
      { name: "GoNotoAncient", path: "noto-ancient" }
    ]
  }.freeze

  def initialize(lang)
    set_language_if_valid lang
  end

  def options
    @options ||= {}
  end

  def info
    @info ||= {
      Creator: OpenProject::Info.app_name,
      CreationDate: Time.zone.now
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
    FONT_SPEC[:fonts].pluck(:name).concat fallback_symbol_fonts
  end

  def fallback_symbol_fonts
    FONT_SPEC[:symbols].map do |symbol|
      font_base_path.join(symbol[:path], "#{symbol[:name]}.ttf")
    end
  end

  def register_fonts!(document) # rubocop:disable Metrics/AbcSize
    register_font_legacy!("NotoSansSC", noto_font_base_path, document)
    FONT_SPEC[:latin].each do |font|
      register_full_font!(font[:name], font_base_path.join(font[:path]), document)
    end
    FONT_SPEC[:fonts].each do |font|
      register_base_font!(font[:name], font_base_path.join(font[:path]), document)
    end
    FONT_SPEC[:mono].each do |font|
      register_full_font!(font[:name], font_base_path.join(font[:path]), document)
    end
  end

  def register_base_font!(family, font_path, document)
    document.font_families[family] = {
      normal: {
        file: font_path.join("#{family}-Regular.ttf"),
        font: "#{family}-Regular"
      },
      bold: {
        file: font_path.join("#{family}-Bold.ttf"),
        font: "#{family}-Bold"
      },
      italic: { # most i18n languages do not have italic, so we use regular instead
        file: font_path.join("#{family}-Regular.ttf"),
        font: "#{family}-Regular"
      },
      bold_italic: { # most i18n languages do not have bold-italic, so we use bold instead
        file: font_path.join("#{family}-Bold.ttf"),
        font: "#{family}-Bold"
      }
    }
  end

  def register_full_font!(family, font_path, document)
    document.font_families[family] = {
      normal: {
        file: font_path.join("#{family}-Regular.ttf"),
        font: "#{family}-Regular"
      },
      italic: {
        file: font_path.join("#{family}-Italic.ttf"),
        font: "#{family}-Italic"
      },
      bold: {
        file: font_path.join("#{family}-Bold.ttf"),
        font: "#{family}-Bold"
      },
      bold_italic: {
        file: font_path.join("#{family}-BoldItalic.ttf"),
        font: "#{family}-BoldItalic"
      }
    }
  end

  # Legacy method for NotoSansSC support (preserving existing behavior)
  def register_font_legacy!(family, font_path, document)
    document.font_families[family] = {
      normal: {
        file: font_path.join("#{family}-Regular.ttf"),
        font: "#{family}-Regular"
      },
      italic: {
        file: font_path.join("#{family}-Light.ttf"),
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

  def font_base_path
    if RUBY_PLATFORM.include?("darwin")
      Pathname.new("/Users/#{ENV['USER']}/Library/Fonts")
    else
      Rails.public_path.join("fonts")
    end
  end

  # Preserved macOS font path support for NotoSansSC
  def noto_font_base_path
    if RUBY_PLATFORM.include?("darwin")
      Pathname.new("/Users/#{ENV['USER']}/Library/Fonts")
    else
      Rails.public_path.join("fonts/noto")
    end
  end
end
