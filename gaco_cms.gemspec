# frozen_string_literal: true

require_relative 'lib/gaco_cms/version'
Gem::Specification.new do |spec|
  spec.name        = 'gaco_cms'
  spec.version     = GacoCms::VERSION
  spec.authors     = ['Owen Peredo Diaz']
  spec.email       = ['owenperedo@gmail.com']
  spec.homepage    = 'https://github.com/owen2345/gaco_cms'
  spec.summary     = 'A lightweight Ruby on Rails cms suitable for any Rails application'
  spec.description = spec.summary
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata['allowed_push_host'] = ''

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'buddy_translatable', '>= 1.1.0'
  spec.add_dependency 'rails', '>= 5.0'
end
