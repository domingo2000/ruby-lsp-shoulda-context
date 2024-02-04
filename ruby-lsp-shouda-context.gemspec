# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ruby_lsp_shoulda_context/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-lsp-shoulda-context"
  spec.version = RubyLsp::ShouldaContext::VERSION
  spec.authors = ["Domingo Edwards"]
  spec.email = ["domingo.edwards@uc.cl"]
  spec.homepage = "https://github.com/domingo2000/ruby-lsp-shoulda-context"
  spec.summary = "Ruby LSP shoulda-context"
  spec.description = "An addon for the Ruby LSP that enables shoulda-context testing"
  spec.license = "MIT"

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
          ".git",
          ".circleci",
          "appveyor",
          "Gemfile",
          "misc/",
          "sorbet/",
        )
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("ruby-lsp", ">= 0.12.0")
end
