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

module API
  module Caching
    module CachedRepresenter
      extend ::ActiveSupport::Concern

      DEFAULT_CONFIGURATION = {
        disabled: false,
        # Associations to include
        key_parts: []
      }.freeze

      included do
        def to_json(*)
          return super if no_caching?

          cached_json_rep = OpenProject::Cache.fetch(json_cache_key) do
            with_caching_state :cacheable do
              super
            end
          end

          uncached_json_rep = with_caching_state :uncacheable do
            super
          end

          cached_hash_rep = ::JSON.parse(cached_json_rep)

          apply_link_cache_ifs(cached_hash_rep)
          apply_property_cache_ifs(cached_hash_rep)

          add_uncacheable_links(cached_hash_rep)

          uncached_hash_rep = ::JSON.parse(uncached_json_rep)

          ::JSON.dump(uncached_hash_rep.deep_merge(cached_hash_rep))
        end

        # When this representer is a nested value inside another
        # representer, the JSON adapter (multi_json >= 1.21 json_gem) serializes it
        # via #as_json instead of #to_json. Needs to be routed through the cache-aware #to_json
        # so cache_if/uncacheable stripping is applied. Without it, ActiveSupport's
        # Object#as_json falls back to #to_hash and leaks guarded fields.
        def as_json(*)
          ::JSON.parse(to_json)
        end

        def json_cache_key
          # In case of dynamically created classes like
          # custom field injected subclasses.
          classname = if self.class.name.nil?
                        self.class.superclass.name
                      else
                        self.class.name
                      end

          classname.to_s.split("::") + [
            "json",
            I18n.locale,
            json_key_representer_parts
          ]
        end

        protected

        attr_accessor :caching_state

        class_attribute :_cached_representer_config

        private

        def apply_link_cache_ifs(hash_rep)
          link_conditions = representable_attrs["links"]
                            .link_configs
                            .select { |config, _block| config[:cache_if] }

          link_conditions.each do |(config, _block)|
            condition = config[:cache_if]
            next if instance_exec(&condition)

            name = config[:rel]

            delete_from_hash(hash_rep, "_links", name.to_s)
          end
        end

        def apply_property_cache_ifs(hash_rep)
          attrs = representable_attrs
                  .select { |_name, config| config[:cache_if] }

          attrs.each do |name, config|
            condition = config[:cache_if]
            next if instance_exec(&condition)

            hash_name = (config[:as] && instance_exec(&config[:as])) || name

            delete_from_hash(hash_rep, config[:embedded] ? "_embedded" : nil, hash_name)
          end
        end

        def add_uncacheable_links(hash_rep)
          link_conditions = representable_attrs["links"]
                            .link_configs
                            .select { |config, _block| config[:uncacheable] }

          link_conditions.each do |config, block|
            name = config[:rel]
            block_result = instance_exec(&block)

            if block_result
              hash_rep["_links"][name] = block_result
            else
              hash_rep["_links"].delete(name)
            end
          end
        end

        # Overriding Roar::Hypermedia#perpare_link_for
        # to remove the cache_if option which would otherwise
        # be visible in the output
        def prepare_link_for(href, options)
          sanitized_options = normalize_link_options(options)
          sanitized_options.except!(:cache_if, :uncacheable)

          sanitized_href = sanitized_options[:array] ? normalize_link_array(href) : href

          super(sanitized_href, sanitized_options)
        end

        # Overriding Roar::Hypermedia#combile_links_for
        # to remove all uncacheable links if the caching_state is set to :cacheable
        def compile_links_for(configs, *)
          filtered_configs = filter_link_configs(configs)

          super(filtered_configs, *)
        end

        def delete_from_hash(hash, path, key)
          pathed_hash = path ? hash[path] : hash

          pathed_hash&.delete(key.to_s)
        end

        def representable_map(*)
          ret = super

          current_map = case caching_state
                        when :cacheable
                          ret.reject { |b| b[:uncacheable] }
                        when :uncacheable
                          ret.select { |b| b[:uncacheable] }
                        else
                          ret
                        end

          Representable::Binding::Map.new(current_map)
        end

        def with_caching_state(state)
          self.caching_state = state
          ret = yield
          self.caching_state = nil
          ret
        end

        def json_key_representer_parts
          cacheable = json_key_part_represented
          cacheable << json_key_custom_fields
          cacheable << json_key_parts_of_represented
          cacheable << json_key_dependencies

          OpenProject::Cache::CacheKey.expand(OpenProject::Cache::CacheKey.key(cacheable.flatten.compact))
        end

        def json_key_part_represented
          [represented]
        end

        def json_key_parts_of_represented
          self.class.cached_representer_configuration[:key_parts].map do |association|
            represented.send(association)
          end
        end

        def json_key_custom_fields
          represented.available_custom_fields if represented.respond_to?(:available_custom_fields)
        end

        def json_key_dependencies
          callable_dependencies = self.class.cached_representer_configuration[:dependencies]

          return unless callable_dependencies

          instance_exec(&callable_dependencies)
        end

        def no_caching?
          self.class.cached_representer_configuration[:disabled]
        end

        def filter_link_configs(configs)
          valid_configs = normalize_link_configs(configs)

          case caching_state
          when :cacheable
            valid_configs.reject { |config| link_uncacheable?(config.first) }
          when :uncacheable
            valid_configs.select { |config| link_uncacheable?(config.first) }
          else
            valid_configs
          end
        end

        def normalize_link_configs(configs)
          return [] unless configs.respond_to?(:each)

          configs.each_with_object([]) do |config, normalized|
            next unless config.respond_to?(:first) && config.respond_to?(:last)

            normalized << [normalize_link_options(config.first), config.last]
          end
        end

        def link_uncacheable?(options)
          options.respond_to?(:[]) && options[:uncacheable]
        end

        def normalize_link_options(options)
          coerce_link_hash(options, fallback_key: :rel, nil_fallback: {})
        end

        def normalize_link_array(entries)
          Array(entries).each_with_object([]) do |entry, normalized|
            sanitized_entry = normalize_link_fragment(entry)
            normalized << sanitized_entry if sanitized_entry
          end
        end

        def normalize_link_fragment(fragment)
          coerce_link_hash(fragment, fallback_key: :href, nil_fallback: nil)
        end

        def coerce_link_hash(value, fallback_key:, nil_fallback:)
          normalized_hash = extract_hash_like(value)
          return normalized_hash if normalized_hash

          return nil_fallback if value.nil?

          { fallback_key => value }
        end

        def extract_hash_like(value)
          if value.is_a?(Hash)
            value.dup
          elsif value.respond_to?(:to_hash)
            hash_like = value.to_hash
            hash_like.is_a?(Hash) ? hash_like : nil
          end
        rescue TypeError
          nil
        end
      end

      class_methods do
        def cached_representer_configuration
          self._cached_representer_config ||= DEFAULT_CONFIGURATION
        end

        def cached_representer(config)
          self._cached_representer_config = cached_representer_configuration.deep_merge(config)
        end

        def link(name, options = {}, &)
          rel_hash = name.is_a?(Hash) ? name : { rel: name }
          super(rel_hash.merge(options), &)
        end

        def links(name, options = {}, &)
          rel_hash = name.is_a?(Hash) ? name : { rel: name }
          super(rel_hash.merge(options), &)
        end
      end
    end
  end
end
