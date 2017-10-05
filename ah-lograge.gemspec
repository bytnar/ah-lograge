$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ah/lograge/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ah-lograge"
  s.version     = Ah::Lograge::VERSION
  s.authors     = ["AirHelp Developers"]
  s.email       = ["developers@airhelp.com"]
  s.homepage    = "https://github.com/AirHelp/ah-lograge"
  s.summary     = "Common initializers for logging and monitoring across Airhelp Rails projects"
  s.description = "Extracted initializers so all Airhelp apps can utilize it"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "lograge"
  s.add_dependency "logstash-event"

  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "rails"
  s.add_development_dependency "sidekiq"
  s.add_development_dependency "statsd-ruby"
end
