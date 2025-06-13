# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/internal"

require_relative "code_lens"
require_relative "../shoulda_context/version"

RubyLsp::Addon.depend_on_ruby_lsp!("~> 0.24.0")

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
          response_builder: ResponseBuilders::CollectionResponseBuilder[Interface::CodeLens],
          uri: URI::Generic,
          dispatcher: Prism::Dispatcher,
        ).void
      end
      def create_code_lens_listener(response_builder, uri, dispatcher)
        CodeLens.new(response_builder, uri, dispatcher, T.must(@global_state), enabled: @enabled)
      end

      sig { override.returns(String) }
      def version
        RubyLsp::ShouldaContext::VERSION
      end
    end
  end
end
