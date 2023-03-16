# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-th_members"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.homepage    = "https://community.openproject.org/projects/th-members"  # TODO check this URL
  s.summary     = 'OpenProject Th Members'
  s.description = "项目成员资料"
  s.license     = "MIT" # e.g. "MIT" or "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)
end
