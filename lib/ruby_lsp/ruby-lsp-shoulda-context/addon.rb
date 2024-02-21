# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/internal"
require "dotenv/load"

require_relative "code_lens"

module RubyLsp
  module ShouldaContext
    # frozen_string_literal: true

    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { override.params(message_queue: Thread::Queue).void }
      def activate(message_queue)
        Dotenv.load(".env.development.local", ".env.development")
      end

      sig { override.void }
      def deactivate; end

      sig { override.returns(String) }
      def name
        "Ruby LSP My Gem"
      end

      # Creates a new CodeLens listener. This method is invoked on every CodeLens request
      sig do
        override.params(
          uri: URI::Generic,
          emitter: Prism::Dispatcher,
        ).returns(T.nilable(Listener[T::Array[Interface::CodeLens]]))
      end
      def create_code_lens_listener(uri, emitter)
        return unless uri.to_standardized_path&.end_with?("_test.rb") || uri.to_standardized_path&.end_with?("_spec.rb")

        CodeLens.new(uri, emitter)
      end
    end
  end
end
