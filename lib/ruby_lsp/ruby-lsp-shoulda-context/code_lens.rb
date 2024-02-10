# typed: strict
# frozen_string_literal: true

module RubyLsp
  module ShouldaContext
    class CodeLens < ::RubyLsp::Listener
      extend T::Sig
      extend T::Generic

      include ::RubyLsp::Requests::Support::Common

      BASE_COMMAND = T.let(
        begin
          Bundler.with_original_env { Bundler.default_lockfile }
          "bundle exec ruby"
        rescue Bundler::GemfileNotFound
          "ruby"
        end + " -ITest",
        String,
      )

      REQUIRED_LIBRARY = T.let("shoulda-context", String)

      ResponseType = type_member { { fixed: T::Array[::RubyLsp::Interface::CodeLens] } }

      sig { override.returns(ResponseType) }
      attr_reader :_response

      sig { params(uri: URI::Generic, dispatcher: Prism::Dispatcher).void }
      def initialize(uri, dispatcher)
        @_response = T.let([], ResponseType)
        # Listener is only initialized if uri.to_standardized_path is valid
        @path = T.let(T.must(uri.to_standardized_path), String)
        @class_name = T.let("", String)
        @group_id = T.let(1, Integer)
        @group_id_stack = T.let([], T::Array[Integer])
        @pattern = T.let("test_: ", String)
        dispatcher.register(self, :on_call_node_enter, :on_call_node_leave, :on_class_node_enter, :on_class_node_leave)

        @base_command = BASE_COMMAND

        super(dispatcher)
      end

      sig { params(node: Prism::CallNode).void }
      def on_call_node_enter(node)
        case node.message
        when "should"
          name = generate_name(node)

          # If is top level should without context the DSL is different
          if @group_id_stack.length == 1
            @pattern += "#{@class_name} "
          end

          @pattern += "should #{name} "
          add_test_code_lens(node, name: name, kind: :example)
        when "context"
          return unless valid_group?(node)

          name = generate_name(node)
          @pattern += "#{name} "
          add_test_code_lens(node, name: name, kind: :group)

          @group_id_stack.push(@group_id)
          @group_id += 1
        end
      end

      sig { params(node: Prism::CallNode).void }
      def on_call_node_leave(node)
        case node.message
        when "should"
          name = generate_name(node)

          @pattern = remove_last_pattern_in_string(@pattern, "should #{name} ")

          # If is top level should without context the DSL is different
          if @group_id_stack.length == 1
            @pattern = remove_last_pattern_in_string(@pattern, "#{@class_name} ")
          end
        when "context"
          return unless valid_group?(node)

          name = generate_name(node)
          @pattern = remove_last_pattern_in_string(@pattern, "#{name} ")
          @group_id_stack.pop
        end
      end

      sig { params(node: Prism::ClassNode).void }
      def on_class_node_enter(node)
        class_name = node.constant_path.slice
        @class_name = remove_last_pattern_in_string(class_name, "Test")

        if @path && class_name.end_with?("Test")
          add_test_code_lens(
            node,
            name: class_name,
            kind: :group,
          )
        end

        @group_id_stack.push(@group_id)
        @group_id += 1
      end

      sig { params(node: Prism::ClassNode).void }
      def on_class_node_leave(node)
        @group_id_stack.pop
      end

      private

      def remove_last_pattern_in_string(string, pattern)
        string.sub(/#{pattern}$/, "")
      end

      sig { params(node: Prism::CallNode).returns(T::Boolean) }
      def valid_group?(node)
        !node.block.nil?
      end

      sig { params(node: Prism::CallNode).returns(String) }
      def generate_name(node)
        arguments = node.arguments&.arguments

        if arguments
          argument = arguments.first

          case argument
          when Prism::StringNode
            argument.content
          when Prism::CallNode
            "<#{argument.name}>"
          when nil
            ""
          else
            argument.slice
          end
        else
          "<unnamed>"
        end
      end

      sig { params(node: Prism::Node, name: String, kind: Symbol).void }
      def add_test_code_lens(node, name:, kind:)
        return unless DependencyDetector.instance.dependencies.include?(REQUIRED_LIBRARY)

        command = "#{@base_command} #{@path} -n \"/#{@pattern.strip}/\""

        grouping_data = { group_id: @group_id_stack.last, kind: kind }
        grouping_data[:id] = @group_id if kind == :group

        arguments = [
          @path,
          name,
          command,
          {
            start_line: node.location.start_line - 1,
            start_column: node.location.start_column,
            end_line: node.location.end_line - 1,
            end_column: node.location.end_column,
          },
        ]

        @_response << create_code_lens(
          node,
          title: "Run",
          command_name: "rubyLsp.runTest",
          arguments: arguments,
          data: { type: "test", **grouping_data },
        )

        @_response << create_code_lens(
          node,
          title: "Run In Terminal",
          command_name: "rubyLsp.runTestInTerminal",
          arguments: arguments,
          data: { type: "test_in_terminal", **grouping_data },
        )

        @_response << create_code_lens(
          node,
          title: "Debug",
          command_name: "rubyLsp.debugTest",
          arguments: arguments,
          data: { type: "debug", **grouping_data },
        )
      end
    end
  end
end
