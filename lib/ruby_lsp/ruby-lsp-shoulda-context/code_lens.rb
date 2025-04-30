# typed: strict
# frozen_string_literal: true

module RubyLsp
  module ShouldaContext
    class CodeLens
      extend T::Sig
      extend T::Generic

      include ::RubyLsp::Requests::Support::Common

      REQUIRED_LIBRARY = T.let("shoulda-context", String)

      ResponseType = type_member { { fixed: T::Array[::RubyLsp::Interface::CodeLens] } }

      sig do
        params(
          response_builder: RubyLsp::ResponseBuilders::CollectionResponseBuilder[Interface::CodeLens],
          uri: URI::Generic,
          dispatcher: Prism::Dispatcher,
          global_state: RubyLsp::GlobalState,
        ).void
      end
      def initialize(response_builder, uri, dispatcher, global_state)
        @response_builder = response_builder
        @global_state = global_state
        return if ENV["RUBY_LSP_SHOULDA_CONTEXT"] == "false"

        # Listener is only initialized if uri.to_standardized_path is valid
        @path = T.let(uri.to_standardized_path, String)
        @class_name = T.let("", String)
        @group_id = T.let(1, Integer)
        @group_id_stack = T.let([], T::Array[Integer])
        @pattern = T.let("test_: ", String)
        dispatcher.register(self, :on_call_node_enter, :on_call_node_leave, :on_class_node_enter, :on_class_node_leave)

        @base_command = T.let(initialize_base_command, String)
      end

      sig { returns(String) }
      def initialize_base_command
        cmd = File.exist?(File.join(Dir.pwd, "bin", "rails")) ? "bin/rails test" : "ruby -ITest"
        begin
          Bundler.with_original_env { Bundler.default_lockfile }
          "bundle exec #{cmd}"
        rescue Bundler::GemfileNotFound
          cmd
        end
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

        if class_name.end_with?("Test")
          add_test_code_lens(
            node,
            name: class_name,
            kind: :class,
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

      sig { params(string: String, pattern: String).returns(String) }
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
        return unless are_required_libraries_installed?

        if kind == :class
          pattern = "#{@class_name}Test"
          kind = :group
        else
          pattern = @pattern.strip
        end
        command = "#{@base_command} #{@path} --name \"/#{pattern}/\""

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

        @response_builder << create_code_lens(
          node,
          title: "Run",
          command_name: "rubyLsp.runTest",
          arguments: arguments,
          data: { type: "test", **grouping_data },
        )

        @response_builder << create_code_lens(
          node,
          title: "Run In Terminal",
          command_name: "rubyLsp.runTestInTerminal",
          arguments: arguments,
          data: { type: "test_in_terminal", **grouping_data },
        )

        @response_builder << create_code_lens(
          node,
          title: "Debug",
          command_name: "rubyLsp.debugTest",
          arguments: arguments,
          data: { type: "debug", **grouping_data },
        )
      end

      sig { returns(T::Boolean) }
      def are_required_libraries_installed?
        Bundler.locked_gems.dependencies.keys.include?(REQUIRED_LIBRARY)
      end
    end
  end
end
