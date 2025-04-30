# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/internal"
require "dotenv/load"

require_relative "code_lens"
require_relative "../shoulda_context/version"

RubyLsp::Addon.depend_on_ruby_lsp!("~> 0.23.0")

module RubyLsp
  module ShouldaContext
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { void }
      def initialize
        super
        @global_state = T.let(nil, T.nilable(RubyLsp::GlobalState))
        @message_queue = T.let(nil, T.nilable(Thread::Queue))
      end

      sig { override.params(global_state: RubyLsp::GlobalState, message_queue: Thread::Queue).void }
      def activate(global_state, message_queue)
        @message_queue = message_queue
        @global_state = global_state
        Dotenv.load(".env.development.local", ".env.development")
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
        CodeLens.new(response_builder, uri, dispatcher, T.must(@global_state))
      end

      sig { override.returns(String) }
      def version
        RubyLsp::ShouldaContext::VERSION
      end
    end
  end
end
