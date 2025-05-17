# typed: strict
# frozen_string_literal: true

module RubyLsp
  module ShouldaContext
    class ShouldaTestStyle < Listeners::TestDiscovery
      extend T::Sig
      include Requests::Support::Common

      class << self
        extend T::Sig

        # Return a minimal set of test commands
        # to run the given test items
        sig { params(items: T::Array[T::Hash[String, T.untyped]]).returns(T::Array[String]) }
        def resolve_test_commands(items)
          # A nested hash of file_path => test_regex to ensure we build the
          # minimum amount of commands needed to execute the requested tests.
          aggregated_tests = Hash.new { |hash, key| hash[key] = Set.new }

          # Full files are paths that should be executed as a whole
          full_files = []
          queue = items.dup

          until queue.empty?
            item = T.must(queue.shift)
            tags = Set.new(item[:tags])
            next unless tags.include?("framework:shoulda")

            children = item[:children]
            uri = URI(item[:uri])
            path = uri.to_standardized_path
            next unless path

            if tags.include?("test_dir")
              if children.empty?
                full_files.concat(Dir.glob(
                  "#{path}/**/{*_test,test_*}.rb",
                  File::Constants::FNM_EXTGLOB | File::Constants::FNM_PATHNAME,
                ))
              end
            elsif tags.include?("test_file")
              full_files << path if children.empty?
            elsif tags.include?("test_group")
              # If this is a class (contains "::"), process it with its children
              if item[:id].include?("::") || item[:id].end_with?("Test")
                process_test_group(aggregated_tests, path, item, [])
              end
              # NOTE: We intentionally don't process non-class groups at the top level
            end

            queue.concat(children) unless children.empty?
          end

          commands = []

          aggregated_tests.each do |file_path, test_patterns|
            test_patterns.each do |pattern|
              commands << "#{BASE_COMMAND} -ITest #{file_path} --name \"/#{pattern}/\""
            end
          end

          unless full_files.empty?
            commands << "echo \"debug\"; #{BASE_COMMAND} -Itest -e \"ARGV.each { |f| require f }\" #{full_files.join(" ")}"
          end

          commands
        end

        private

        # Process a test group and all its children recursively to build the test regex pattern
        def process_test_group(aggregated_tests, file_path, item, pattern_parts)
          pattern_parts = pattern_parts.dup

          # Check if this is a class (test group with ::)
          is_class = item[:id].include?("::")

          if is_class
            # For class, store the full class name
            class_name = item[:id]
            # Start with the class prefix for further patterns
            updated_pattern = ["#{class_name}#test_:"]
          elsif pattern_parts.empty?
            # For context, add the context name to the pattern
            # This should not happen as the first item should always be a class
            updated_pattern = ["test_: #{item[:label]}"]
          else
            # Add this context to the existing pattern
            updated_pattern = pattern_parts.dup
            updated_pattern[-1] = "#{updated_pattern[-1]} #{item[:label]}"
          end

          children = item[:children] || []

          if children.empty?
            # If no children, add the pattern that matches the group itself
            pattern = updated_pattern.join(" ")
            aggregated_tests[file_path].add(pattern)
          else
            children.each do |child|
              if (child[:tags] || []).include?("test_group")
                # Recursively process nested test groups
                process_test_group(aggregated_tests, file_path, child, updated_pattern)
              else
                # Handle should items
                should_pattern = updated_pattern.dup
                # Add "should" and the should label
                should_pattern[-1] = "#{should_pattern[-1]} should #{child[:label]}"
                aggregated_tests[file_path].add(should_pattern.join(" "))
              end
            end
          end
        end

        BASE_COMMAND = begin
          Bundler.with_original_env { Bundler.default_lockfile }
          "bundle exec ruby"
        rescue Bundler::GemfileNotFound
          "ruby"
        end
      end

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
