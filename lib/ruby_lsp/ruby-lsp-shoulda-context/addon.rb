# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/internal"

require_relative "../shoulda_context/version"
require_relative "listeners/test_discovery"

RubyLsp::Addon.depend_on_ruby_lsp!("~> 0.23.17")

module RubyLsp
  module ShouldaContext
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { void }
      def initialize
        super
        @global_state = T.let(nil, T.nilable(RubyLsp::GlobalState))
        @message_queue = T.let(nil, T.nilable(Thread::Queue))
        @settings = T.let(nil, T.nilable(T::Hash[String, T.untyped]))
        @enabled = T.let(true, T::Boolean)
      end

      sig { override.params(global_state: RubyLsp::GlobalState, message_queue: Thread::Queue).void }
      def activate(global_state, message_queue)
        @message_queue = message_queue
        @global_state = global_state
        @settings = @global_state.settings_for_addon(name)
        @enabled = @settings.fetch(:enabled, true)
      end

      sig { override.void }
      def deactivate; end

      sig { override.returns(String) }
      def name
        "Ruby LSP Shoulda Context"
      end

      sig do
        override.params(
          response_builder: ResponseBuilders::TestCollection,
          dispatcher: Prism::Dispatcher,
          uri: URI::Generic,
        ).void
      end
      def create_discover_tests_listener(response_builder, dispatcher, uri)
        global_state = @global_state
        return unless global_state
        return unless @enabled

        ShouldaTestStyle.new(
          response_builder,
          global_state,
          dispatcher,
          uri,
        )
      end

      sig { override.returns(String) }
      def version
        RubyLsp::ShouldaContext::VERSION
      end
    end
  end
end
