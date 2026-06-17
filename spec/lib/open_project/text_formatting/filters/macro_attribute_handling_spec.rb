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

RSpec.describe "macro element attribute handling" do # rubocop:disable RSpec/DescribeClass
  def sanitize(html)
    filter = OpenProject::TextFormatting::Filters::SanitizationFilter.new(html, {})
    result = filter.call
    result.respond_to?(:to_html) ? result.to_html : result.to_s
  end

  def apply_macro_filter(html)
    filter = OpenProject::TextFormatting::Filters::MacroFilter.new(html, {})
    result = filter.call
    result.respond_to?(:to_html) ? result.to_html : result.to_s
  end

  describe OpenProject::TextFormatting::Filters::SanitizationFilter do
    describe "macro element data attribute restrictions" do
      it "strips data-controller from macro elements" do
        html = '<macro class="x" data-controller="poll-for-changes">.</macro>'
        expect(sanitize(html)).not_to include("data-controller")
      end

      it "strips data-action from macro elements" do
        html = '<macro class="x" data-action="click->foo#bar">.</macro>'
        expect(sanitize(html)).not_to include("data-action")
      end

      it "strips arbitrary data-* stimulus value attributes from macro elements" do
        html = '<macro class="x" data-poll-for-changes-url-value="/api/v3/attachments/1/content" ' \
               'data-poll-for-changes-interval-value="2000">.</macro>'
        output = sanitize(html)
        expect(output).not_to include("data-poll-for-changes-url-value")
        expect(output).not_to include("data-poll-for-changes-interval-value")
      end

      it "strips data-controller from arbitrary non-macro elements" do
        html = '<div data-controller="poll-for-changes"><p data-controller="evil">text</p></div>'
        output = sanitize(html)
        expect(output).not_to include("data-controller")
      end

      it "preserves data-type on macro elements (used by create-work-package-link macro)" do
        html = '<macro class="create-work-package-link" data-type="Task">.</macro>'
        expect(sanitize(html)).to include('data-type="Task"')
      end

      it "preserves data-page on macro elements (used by child-pages macro)" do
        html = '<macro class="child-pages" data-page="some-page" data-include-parent="true">.</macro>'
        output = sanitize(html)
        expect(output).to include('data-page="some-page"')
        expect(output).to include('data-include-parent="true"')
      end

      it "preserves data-macro-name on macro elements (used by placeholder rendering)" do
        html = '<macro class="macro-placeholder" data-macro-name="toc">placeholder</macro>'
        expect(sanitize(html)).to include('data-macro-name="toc"')
      end

      it "preserves data-file on macro elements (used by show_dds_file_link macro)" do
        html = '<macro class="show_dds_file_link" data-file="{&quot;name&quot;:&quot;file&quot;,&quot;url&quot;:&quot;https://example.com&quot;}">.</macro>'
        expect(sanitize(html)).to include("data-file=")
      end
    end
  end

  describe OpenProject::TextFormatting::Filters::MacroFilter do
    describe "DDS file link macro elements" do
      it "renders the DDS link after sanitization preserves its file payload" do
        file = {
          name: "20250514文保结构提资天华",
          isFolder: true,
          url: "https://edoc.thape.com.cn:8022/index.html#doc/enterprise/15110763",
          parentFolderFullPath: "企业内容库\\01-项目工作区"
        }
        html = '<macro class="show_dds_file_link op-macro-dds-file-box" ' \
               "data-file=\"#{ERB::Util.html_escape(file.to_json)}\">&nbsp;</macro>"

        output = apply_macro_filter(sanitize(html))

        expect(output).to include("op-macro-dds-file-box")
        expect(output).to include("20250514文保结构提资天华")
        expect(output).to include("企业内容库\\01-项目工作区")
        expect(output).not_to include("macro-unavailable")
      end
    end

    describe "unrecognized macro elements" do
      it "replaces macro elements whose class does not match any registered macro with an unavailable placeholder" do
        html = '<p><macro class="x">.</macro></p>'
        output = apply_macro_filter(html)
        expect(output).not_to include('class="x"')
        expect(output).to include("macro-unavailable")
        expect(output).to include("Unknown or unsupported macro.")
      end

      it "replaces macro elements with no class with an unavailable placeholder" do
        html = "<p><macro>.</macro></p>"
        output = apply_macro_filter(html)
        expect(output).to include("macro-unavailable")
        expect(output).to include("Unknown or unsupported macro.")
      end
    end
  end
end
