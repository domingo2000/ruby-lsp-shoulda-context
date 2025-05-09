# typed: strict
# frozen_string_literal: true

module RubyLsp
  module ShouldaContext
    class ShouldaTestStyle < Listeners::TestDiscovery
      extend T::Sig
      include Requests::Support::Common

      sig { params(response_builder: ResponseBuilders::TestCollection, global_state: GlobalState, dispatcher: Prism::Dispatcher, uri: URI::Generic).void }
      def initialize(response_builder, global_state, dispatcher, uri)
        super
        @response_builder = response_builder
        @uri = uri
        @visibility_stack = T.let([], T::Array[Symbol])
        @nesting = T.let([], T::Array[String])
        @context_block_nesting = T.let([], T::Array[String])

        dispatcher.register(
          self,
          :on_class_node_enter,
          :on_class_node_leave,
          :on_call_node_enter,
          :on_call_node_leave,
        )
      end

      sig { params(node: Prism::ClassNode).void }
      def on_class_node_enter(node)
        @nesting << constant_name(node.constant_path)

        # TODO: Improve based on ancestor classes
        class_name = @nesting.join("::")
        return unless class_name.end_with?("Test")

        test_item = Requests::Support::TestItem.new(
          class_name,
          class_name,
          @uri,
          range_from_node(node),
          framework: :shoulda,
        )

        @response_builder.add(test_item)
        @response_builder.add_code_lens(test_item)
      end

      sig { params(node: Prism::ClassNode).void }
      def on_class_node_leave(node)
        @nesting.pop
      end

      sig { params(node: Prism::CallNode).void }
      def on_call_node_enter(node)
        case node.name
        when :context
          handle_context(node)
        when :should
          handle_should(node)
        end
      end

      sig { params(node: Prism::CallNode).void }
      def on_call_node_leave(node)
        return unless node.name == :context

        handle_context_leave(node)
      end

      private

      sig { params(node: Prism::CallNode).void }
      def handle_context(node)
        return unless valid_context?(node)

        description = extract_description(node)
        return unless description

        add_to_parent_test_group(description, node)

        @context_block_nesting << description
      end

      sig { params(node: Prism::CallNode).void }
      def handle_context_leave(node)
        return unless valid_context?(node)

        @context_block_nesting.pop
      end

      sig { params(node: Prism::CallNode).void }
      def handle_should(node)
        return unless in_test_class?

        description = extract_description(node)
        return unless description

        add_to_parent_test_group(description, node)
      end

      sig { params(node: Prism::CallNode).returns(T.nilable(String)) }
      def extract_description(node)
        first_argument = node.arguments&.arguments&.first
        return unless first_argument

        case first_argument
        when Prism::StringNode
          first_argument.content
        when Prism::CallNode
          "<#{first_argument.slice}>"
        else
          first_argument.slice
        end
      end

      sig { params(node: Prism::CallNode).returns(T::Boolean) }
      def valid_context?(node)
        return false unless in_test_class?
        return false if node.block.nil?

        first_argument = node.arguments&.arguments&.first
        return false unless first_argument.is_a?(Prism::StringNode)

        true
      end

      sig { params(description: String, node: Prism::CallNode).void }
      def add_to_parent_test_group(description, node)
        parent_test_group = find_parent_test_group

        return unless parent_test_group

        test_item = Requests::Support::TestItem.new(
          description,
          description,
          @uri,
          range_from_node(node),
          framework: :shoulda,
        )

        parent_test_group.add(test_item)
        @response_builder.add_code_lens(test_item)
      end

      sig { returns(T.nilable(Requests::Support::TestItem)) }
      def find_parent_test_group
        root_group_name = RubyIndexer::Index.actual_nesting(@nesting, nil).join("::")
        return unless root_group_name

        root_test_group = @response_builder[root_group_name]
        return root_test_group if @context_block_nesting.empty?

        test_group = root_test_group

        @context_block_nesting.each do |description|
          test_group = test_group[description]
        end

        test_group
      end

      sig { returns(T::Boolean) }
      def in_test_class?
        return false if @nesting.empty?

        class_name = @nesting.join("::")
        return false unless class_name.end_with?("Test")

        true
      end
    end
  end
end
