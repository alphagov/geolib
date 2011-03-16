# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "geolib"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Griffiths"]
  s.email       = ["bengriffiths@gmail.com"]
  s.homepage    = "http://github.com/alphagov/geolib"
  s.summary     = %q{Alphagov Geo provider}
  s.description = %q{Alphagov Geo provider}

  s.rubyforge_project = "geolib"

  s.files         = Dir[
    'lib/**/*',
    'Rakefile'
  ]
  s.test_files    = Dir['spec/**/*']
  s.executables   = []
  s.require_paths = ["lib"]
end
