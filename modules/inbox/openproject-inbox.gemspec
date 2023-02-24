Gem::Specification.new do |s|
  s.name        = 'openproject-inbox'
  s.version     = '1.0.0'
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.summary     = 'OpenProject Inbox'
  s.description = 'Provides inbox views'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib}/**/*']
  s.metadata['rubygems_mfa_required'] = 'true'
end
