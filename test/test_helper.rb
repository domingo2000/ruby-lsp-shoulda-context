# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "ruby_lsp/internal"
require "ruby_lsp/ruby-lsp-shoulda-context/addon"
require "ruby_lsp/test_helper"
require "minitest/autorun"
require "minitest/reporters"
require "debug"

minitest_reporter = if ENV["SPEC_REPORTER"]
  Minitest::Reporters::SpecReporter.new(color: true)
else
  Minitest::Reporters::DefaultReporter.new(color: true)
end
Minitest::Reporters.use!(minitest_reporter)

module Minitest
  class Test
    extend T::Sig
    include RubyLsp::TestHelper

    Minitest::Test.make_my_diffs_pretty!
  end
end
