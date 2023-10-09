# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-th_work_packages"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.homepage    = "https://community.openproject.org/projects/th-work-packages"  # TODO check this URL
  s.summary     = 'OpenProject Th Work Packages'
  s.description = "天华工作包"
  s.license     = "MIT" # e.g. "MIT" or "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)
end
