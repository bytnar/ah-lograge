$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ah/lograge/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ah-lograge"
  s.version     = Ah::Lograge::VERSION
  s.authors     = ["Przemyslaw Wroblewski"]
  s.email       = ["przemyslaw.wroblewski@gmail.com"]
  s.homepage    = "https://github.com/AirHelp/ah-lograge"
  s.summary     = "Common initializer for Lograge across Airhelp Rails projects"
  s.description = "Extracted initializer so all Airhelp apps can utilize it"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "lograge"
  s.add_dependency "logstash-event"
end
