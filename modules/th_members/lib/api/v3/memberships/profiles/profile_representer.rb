module API
  module V3
    module Memberships
      module Profiles
        class ProfileRepresenter < ::API::Decorators::Single
          link :self do
            if represented.member_id && represented.member_id != 0
              {
                href: api_v3_paths.membership_profile(represented.member_id)
              }
            else
              {
                href: nil
              }
            end
          end

          property :id

          property :company

          property :position

          property :remark

          def _type
            'MembershipProfile'
          end
        end
      end
    end
  end
end
