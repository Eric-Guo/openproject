require "rails_helper"

RSpec.describe API::Caching::CachedRepresenter do
  let(:base_module) do
    Module.new do
      attr_reader :passed_configs, :prepared_options, :prepared_href

      def compile_links_for(configs, *args)
        @passed_configs = configs
        configs
      end

      def prepare_link_for(href, options)
        @prepared_href = href
        @prepared_options = options
      end
    end
  end

  let(:representer_class) do
    base = base_module

    Class.new do
      include base
      include API::Caching::CachedRepresenter

      attr_accessor :caching_state
    end
  end

  subject(:representer) { representer_class.new }

  describe "#compile_links_for" do
    it "ignores invalid link definitions before delegating" do
      representer.caching_state = :cacheable
      valid_config = [{ rel: :self }, -> {}]

      representer.send(:compile_links_for, [valid_config, :legacy_entry], {})

      expect(representer.passed_configs).to eq([valid_config])
    end

    it "filters to uncacheable links when requested" do
      representer.caching_state = :uncacheable
      uncacheable_config = [{ rel: :foo, uncacheable: true }, -> {}]
      cacheable_config = [{ rel: :bar }, -> {}]

      representer.send(:compile_links_for, [uncacheable_config, cacheable_config], {})

      expect(representer.passed_configs).to eq([uncacheable_config])
    end
  end

  describe "#prepare_link_for" do
    it "coerces non-hash options into rel hashes" do
      representer.send(:prepare_link_for, "/foo", :self)

      expect(representer.prepared_options).to eq(rel: :self)
    end

    it "strips caching flags before delegating" do
      representer.send(:prepare_link_for,
                       "/foo",
                       { rel: :self, cache_if: -> { true }, uncacheable: true })

      expect(representer.prepared_options).to eq(rel: :self)
    end

    it "wraps array fragments that are not hashes" do
      representer.send(:prepare_link_for,
                       [:foo, { href: "/bar" }, nil],
                       { rel: :children, array: true })

      expect(representer.prepared_href).to eq([{ href: :foo }, { href: "/bar" }])
    end
  end
end
