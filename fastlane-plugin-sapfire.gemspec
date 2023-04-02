require_relative "lib/fastlane/plugin/sapfire/version"

Gem::Specification.new do |spec|
  spec.name = "fastlane-plugin-sapfire"
  spec.version = Fastlane::Sapfire::VERSION
  spec.authors = ["CheeryLee"]
  spec.email = ["cheerylee90@gmail.com"]

  spec.summary = "A bunch of fastlane actions to work with MSBuild, NuGet and Microsoft Store"
  spec.homepage = "https://github.com/CheeryLee/fastlane-plugin-sapfire"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("fastlane", ">= 2.200.0")
  spec.add_development_dependency("pry")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("rspec")
  spec.add_development_dependency("rubocop", ">= 1.48.0")
end
