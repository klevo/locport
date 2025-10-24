# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "locport"
  spec.version     = "1.1.3"
  spec.summary     = "localhost port management"
  spec.description = "Overview of localhost ports used across projects. Prevent conflicts."
  spec.authors     = ["Robert Starsi"]
  spec.email       = "klevo@klevo.sk"
  spec.homepage    = "https://github.com/klevo/locport"
  spec.license     = "MIT"

  spec.files = Dir["lib/**/*", "LICENSE"]
  spec.executables = %w[ locport ]

  spec.add_dependency "thor", "~> 1.3"
end
