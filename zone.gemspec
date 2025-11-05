# frozen_string_literal: true

require_relative "lib/zone/version"

Gem::Specification.new do |spec|
  spec.name = "zone"
  spec.version = Zone::VERSION
  spec.authors = ["David Gillis"]
  spec.email = ["david@flipmine.com"]

  spec.summary = "An ergonomic CLI for quick time-zone conversion"
  spec.homepage = "https://github.com/gillisd/zone"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gillisd/zone"
  spec.metadata["changelog_uri"] = "https://github.com/gillisd/zone/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
