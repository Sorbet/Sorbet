Gem::Specification.new do |s|
  s.name        = 'sorbet'
  s.version     = '0.0.0'
  s.summary     = 'A Typechecker for Ruby'
  s.description = 'The main entrypoint for using Sorbet'
  s.authors     = ['Stripe']
  s.email       = 'sorbet@stripe.com'
  s.files       = Dir.glob('lib/**/*')
  s.executables = Dir.glob('bin/**/*').map {|path| path.gsub('bin/', '')}
  s.homepage    = 'https://sorbet.run'
  s.license     = 'Apache-2.0'

  s.add_dependency 'sorbet-static', '0.0.0'

  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'mocha', '~> 1.7'
  s.add_development_dependency 'rake'

  s.post_install_message = %q{
  Thanks for installing Sorbet! To use it in your project, first run:

    bundle exec srb init

  which will get your project ready to use with Sorbet.
  After that whenever you want to typecheck your code, run:

    bundle exec srb tc

  For more docs see: https://sorbet.org/docs/adopting
}

  # TODO this is temporary, to prevent leaking publicly.
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless s.respond_to?(:metadata)
  s.metadata['allowed_push_host'] = ''
end
