# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ruby_lsp/shoulda_context/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-lsp-shoulda-context"
  spec.version = RubyLsp::ShouldaContext::VERSION
  spec.authors = ["Domingo Edwards"]
  spec.email = ["domingo.edwards@uc.cl"]

  spec.summary = "Ruby LSP shoulda-context"
  spec.description = "An addon for the Ruby LSP that enables shoulda-context testing"
  spec.homepage = "https://github.com/domingo2000/ruby-lsp-shoulda-context"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/domingo2000/ruby-lsp-shoulda-context"
  spec.metadata["changelog_uri"] = "https://github.com/domingo2000/ruby-lsp-shoulda-context/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    %x(git ls-files -z).split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(
          "bin/",
          "test/",
          "spec/",
          "features/",
          "examples/",
          ".git",
          ".circleci",
          "rubocop.yml",
          "appveyor",
          "Gemfile",
          "misc/",
          "sorbet/",
        )
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("ruby-lsp", ">= 0.12.0")
end
