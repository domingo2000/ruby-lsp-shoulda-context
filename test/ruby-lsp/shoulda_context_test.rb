# typed: strict
# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module RubyLspShouldaContext
    class ShouldaContextTest < Minitest::Test
      def test_that_it_has_a_version_number
        refute_nil(::RubyLsp::ShouldaContext::VERSION)
      end

      def test_should_only
        uri = URI("file:///fake_test.rb")
        store = RubyLsp::Store.new
        message_queue = Thread::Queue.new

        store.set(uri: uri, source: <<~RUBY, version: 1)
          should "test 1" do
            assert true
          end
        RUBY

        response = RubyLsp::Executor.new(store, message_queue).execute(
          {
            method: "textDocument/codeLens",
            params: {
              textDocument: { uri: uri },
              position: { line: 0, character: 0 },
            },
          },
        )

        assert_nil response.error

        response = response.response

        assert_equal 3, response.count

        assert_equal({ type: "test", kind: :example, group_id: nil, id: 1 }, response[0].data)
        assert_equal({ type: "test_in_terminal", kind: :example, group_id: nil, id: 1 }, response[1].data)
        assert_equal({ type: "debug", kind: :example, group_id: nil, id: 1 }, response[2].data)

        response[0..2].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("test 1", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/test 1/\"", response_.command.arguments[2])
          assert_equal({ start_line: 0, start_column: 0, end_line: 2, end_column: 3 }, response_.command.arguments[3])
        end
      end

      def test_that_context_with_should_are_parsed
        uri = URI("file:///fake_test.rb")
        store = RubyLsp::Store.new
        message_queue = Thread::Queue.new

        store.set(uri: uri, source: <<~RUBY, version: 1)
          context "context 1" do
            should "test 1" do
              assert true
            end
          end
        RUBY

        response = RubyLsp::Executor.new(store, message_queue).execute(
          {
            method: "textDocument/codeLens",
            params: {
              textDocument: { uri: uri },
              position: { line: 0, character: 0 },
            },
          },
        )

        assert_nil response.error

        response = response.response

        assert_equal 6, response.count

        assert_equal({ type: "test", kind: :group, group_id: nil, id: 1 }, response[0].data)
        assert_equal({ type: "test_in_terminal", kind: :group, group_id: nil, id: 1 }, response[1].data)
        assert_equal({ type: "debug", kind: :group, group_id: nil, id: 1 }, response[2].data)

        response[0..2].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("context 1", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/context 1/\"", response_.command.arguments[2])
          assert_equal({ start_line: 0, start_column: 0, end_line: 4, end_column: 3 }, response_.command.arguments[3])
        end

        assert_equal({ type: "test", kind: :example, group_id: 1, id: 2 }, response[3].data)
        assert_equal({ type: "test_in_terminal", kind: :example, group_id: 1, id: 2 }, response[4].data)
        assert_equal({ type: "debug", kind: :example, group_id: 1, id: 2 }, response[5].data)

        response[3..5].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("test 1", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/test 1/\"", response_.command.arguments[2])
          assert_equal({ start_line: 1, start_column: 2, end_line: 3, end_column: 5 }, response_.command.arguments[3])
        end
      end

      def test_multiple_contexts
        uri = URI("file:///fake_test.rb")
        store = RubyLsp::Store.new
        message_queue = Thread::Queue.new

        store.set(uri: uri, source: <<~RUBY, version: 1)
          context "context 1" do
            should "test 1" do
              assert true
            end
          end

          context "context 2" do
            should "test 1" do
              assert true
            end
          end
        RUBY

        response = RubyLsp::Executor.new(store, message_queue).execute(
          {
            method: "textDocument/codeLens",
            params: {
              textDocument: { uri: uri },
              position: { line: 0, character: 0 },
            },
          },
        )

        assert_nil response.error

        response = response.response

        # Number of LSP returned to server
        assert_equal 12, response.count

        # Context 1
        assert_equal({ type: "test", kind: :group, group_id: nil, id: 1 }, response[0].data)
        assert_equal({ type: "test_in_terminal", kind: :group, group_id: nil, id: 1 }, response[1].data)
        assert_equal({ type: "debug", kind: :group, group_id: nil, id: 1 }, response[2].data)

        response[0..2].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("context 1", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/context 1/\"", response_.command.arguments[2])
          assert_equal({ start_line: 0, start_column: 0, end_line: 4, end_column: 3 }, response_.command.arguments[3])
        end

        # Context 1 -- Test 1
        assert_equal({ type: "test", kind: :example, group_id: 1, id: 2 }, response[3].data)
        assert_equal({ type: "test_in_terminal", kind: :example, group_id: 1, id: 2 }, response[4].data)
        assert_equal({ type: "debug", kind: :example, group_id: 1, id: 2 }, response[5].data)

        response[3..5].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("test 1", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/test 1/\"", response_.command.arguments[2])
          assert_equal({ start_line: 1, start_column: 2, end_line: 3, end_column: 5 }, response_.command.arguments[3])
        end

        # Context 2
        assert_equal({ type: "test", kind: :group, group_id: nil, id: 3 }, response[6].data)
        assert_equal({ type: "test_in_terminal", kind: :group, group_id: nil, id: 3 }, response[7].data)
        assert_equal({ type: "debug", kind: :group, group_id: nil, id: 3 }, response[8].data)

        response[6..8].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("context 2", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/context 2/\"", response_.command.arguments[2])
          assert_equal(
            { start_line: 6, start_column: 0, end_line: 10, end_column: 3 },
            response_.command.arguments[3],
          )
        end

        # Context 2 -- Test 1
        assert_equal({ type: "test", kind: :example, group_id: 3, id: 4 }, response[9].data)
        assert_equal({ type: "test_in_terminal", kind: :example, group_id: 3, id: 4 }, response[10].data)
        assert_equal({ type: "debug", kind: :example, group_id: 3, id: 4 }, response[11].data)

        response[9..11].each do |response_|
          assert_equal("/fake_test.rb", response_.command.arguments[0])
          assert_equal("test 1", response_.command.arguments[1])
          assert_equal("bundle exec ruby -ITest /fake_test.rb -n \"/test 1/\"", response_.command.arguments[2])
          assert_equal({ start_line: 7, start_column: 2, end_line: 9, end_column: 5 }, response_.command.arguments[3])
        end
      end
    end
  end
end
