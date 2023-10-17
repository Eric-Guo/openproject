class WorkPackageEdocFiles::CreateService < BaseServices::BaseCallable
  attr_accessor :user,
                :contract_class

  def initialize(user:, contract_class: WorkPackageEdocFiles::CreateContract)
    self.user = user
    self.contract_class = contract_class
  end

  def perform(edoc_file: WorkPackageEdocFile.new, **attributes)
    create(attributes, edoc_file)
  end

  protected

  def create(attributes, edoc_file)
    result = set_attributes(attributes, edoc_file)

    result.success =
      if result.success
        edoc_file.save
      else
        false
      end

    result
  end

  def set_attributes(attributes, eodc_file)
    attributes_service_class
      .new(user:,
           model: eodc_file,
           contract_class:)
      .call(attributes)
  end

  def attributes_service_class
    ::WorkPackageEdocFiles::SetAttributesService
  end
end
