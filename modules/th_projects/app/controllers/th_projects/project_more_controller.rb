module ::ThProjects
  class ProjectMoreController < ApplicationController
    before_action :find_optional_project
    before_action :authorize

    menu_item :project_more

    def show
    end
  end
end
