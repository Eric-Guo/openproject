module ::ThProjects
  class ProjectTimelinesController < ApplicationController
    before_action :find_optional_project
    before_action :authorize

    menu_item :project_timeline

    def show
      respond_to do |format|
        format.html do
          render layout: 'angular/angular'
        end
      end
    end
  end
end
