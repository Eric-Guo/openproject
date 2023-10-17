module API
  module V3
    module WorkPackageEdocFiles
      class ParseParamsService < API::V3::ParseResourceParamsService
        # Be compatible to super
        def initialize(user, **_args)
          super(user, model: WorkPackageEdocFile, representer: ::API::V3::WorkPackageEdocFiles::WorkPackageEdocFilePayloadRepresenter)
        end

        private

        def parse_attributes(request_body)
          Hash(request_body)
        end
      end
    end
  end
end
