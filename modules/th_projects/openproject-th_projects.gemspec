# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-th_projects"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.homepage    = "https://community.openproject.org/projects/th-projects"  # TODO check this URL
  s.summary     = 'OpenProject Th Projects'
  s.description = "天华项目"
  s.license     = "MIT" # e.g. "MIT" or "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)
end
