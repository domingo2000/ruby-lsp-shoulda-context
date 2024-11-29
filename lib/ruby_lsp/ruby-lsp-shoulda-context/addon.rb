# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/internal"
require "dotenv/load"

require_relative "code_lens"
require_relative "../shoulda_context/version"

RubyLsp::Addon.depend_on_ruby_lsp!("~> 0.22.0")

module RubyLsp
  module ShouldaContext
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { override.params(global_state: GlobalState, message_queue: Thread::Queue).void }
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

      def create_code_lens_listener(response_builder, uri, dispatcher)
        CodeLens.new(response_builder, uri, dispatcher, @global_state)
      end

      def version
        RubyLsp::ShouldaContext::VERSION
      end
    end
  end
end
