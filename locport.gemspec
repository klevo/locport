# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "locport"
  spec.version     = "1.2.0"
  spec.summary     = "localhost port management"
  spec.description = "Overview of localhost ports used across projects. Prevent conflicts."
  spec.authors     = ["Robert Starsi"]
  spec.email       = "klevo@klevo.sk"
  spec.homepage    = "https://github.com/klevo/locport"
  spec.license     = "MIT"

  spec.files = Dir["lib/**/*", "LICENSE"]
  spec.executables = %w[ locport ]

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "thor", "~> 1.3"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "testerobly", "~> 1.0"
end
