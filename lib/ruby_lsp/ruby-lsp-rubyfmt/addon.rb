# typed: false
# frozen_string_literal: true

require "open3"

module RubyLsp
  module RubyLspRubyfmt
# frozen_string_literal: true

    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { override.params(message_queue: Thread::Queue).void }
      def activate(message_queue)
        @message_queue = message_queue
        @config = nil
      end

      sig { override.void }
      def deactivate
      end

      sig { override.returns(String) }
      def name
        "Ruby LSP My Gem"
      end

      sig do
        override.params(
          nesting: T::Array[String],
          index: RubyIndexer::Index,
          dispatcher: Prism::Dispatcher,
        ).returns(T.nilable(Listener[T.nilable(Interface::Hover)]))
      end
      def create_hover_listener(nesting, index, dispatcher)
        # Use the listener factory methods to instantiate listeners with parameters sent by the LSP combined with any
        # pre-computed information in the addon. These factory methods are invoked on every request
        Hover.new(@config, dispatcher)
      end
    end

    # All listeners have to inherit from ::RubyLsp::Listener
    class Hover < ::RubyLsp::Listener
      extend T::Sig
      extend T::Generic

      ResponseType = type_member { { fixed: T.nilable(::RubyLsp::Interface::Hover) } }

      sig { override.returns(ResponseType) }
      attr_reader :_response

      # Listeners are initialized with the Prism::Dispatcher. This object is used by the Ruby LSP to emit the events
      # when it finds nodes during AST analysis. Listeners must register which nodes they want to handle with the
      # dispatcher (see below).
      # Additionally, listeners are instantiated with a message_queue to push notifications (not used in this example).
      # See "Sending notifications to the client" for more information.
      sig { params(conig: nil, dispatcher: Prism::Dispatcher).void }
      def initialize(config, dispatcher)
        super(dispatcher)

        @_response = T.let(nil, ResponseType)
        @config = config

        # Register that this listener will handle `on_constant_read_node_enter` events (i.e.: whenever a constant read
        # is found in the code)
        dispatcher.register(self, :on_constant_read_node_enter)
      end

      # Listeners must define methods for each event they registered with the dispatcher. In this case, we have to
      # define `on_constant_read_node_enter` to specify what this listener should do every time we find a constant
      sig { params(node: Prism::ConstantReadNode).void }
      def on_constant_read_node_enter(node)
        # Certain helpers are made available to listeners to build LSP responses. The classes under `RubyLsp::Interface`
        # are generally used to build responses and they match exactly what the specification requests.
        contents = RubyLsp::Interface::MarkupContent.new(kind: "markdown", value: "Hello!")
        @_response = RubyLsp::Interface::Hover.new(range: range_from_node(node), contents: contents)
      end
    end
  end
end
