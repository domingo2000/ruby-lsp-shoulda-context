# typed: true
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
        source = <<~RUBY
          class MyTest < Minitest::Test
            should "test 1" do
              assert true
            end
          end
        RUBY

        with_server(source, uri) do |server, uri|
          server.process_message(
            {
              id: 1,
              method: "textDocument/codeLens",
              params: {
                textDocument: { uri: uri },
                position: { line: 0, character: 0 },
              },
            },
          )

          server.pop_response # Drop the notification change message

          response = server.pop_response
          response = response.response

          assert_equal 9, response.count

          # Class
          assert_equal({ type: "test", kind: :group, group_id: nil, id: 1 }, response[3].data)
          assert_equal({ type: "test_in_terminal", kind: :group, group_id: nil, id: 1 }, response[4].data)
          assert_equal({ type: "debug", kind: :group, group_id: nil, id: 1 }, response[5].data)

          response[3..5].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("MyTest", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/MyTest/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 0, start_column: 0, end_line: 4, end_column: 3 }, response_.command.arguments[3])
          end

          assert_equal({ type: "test", kind: :example, group_id: 1 }, response[6].data)
          assert_equal({ type: "test_in_terminal", kind: :example, group_id: 1 }, response[7].data)
          assert_equal({ type: "debug", kind: :example, group_id: 1 }, response[8].data)

          response[6..8].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("test 1", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: My should test 1/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 1, start_column: 2, end_line: 3, end_column: 5 }, response_.command.arguments[3])
          end
        end
      end

      def test_that_context_with_should_are_parsed
        uri = URI("file:///fake_test.rb")
        source = <<~RUBY
          class MyTest < Minitest::Test
            context "context 1" do
              should "test 1" do
                assert true
              end
            end
          end
        RUBY

        with_server(source, uri) do |server, uri|
          server.process_message(
            {
              id: 1,
              method: "textDocument/codeLens",
              params: {
                textDocument: { uri: uri },
                position: { line: 0, character: 0 },
              },
            },
          )

          server.pop_response # Drop the notification change message

          response = server.pop_response
          response = response.response

          assert_equal 12, response.count

          # Class
          assert_equal({ type: "test", kind: :group, group_id: nil, id: 1 }, response[3].data)
          assert_equal({ type: "test_in_terminal", kind: :group, group_id: nil, id: 1 }, response[4].data)
          assert_equal({ type: "debug", kind: :group, group_id: nil, id: 1 }, response[5].data)

          response[3..5].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("MyTest", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/MyTest/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 0, start_column: 0, end_line: 6, end_column: 3 }, response_.command.arguments[3])
          end

          assert_equal({ type: "test", kind: :group, group_id: 1, id: 2 }, response[6].data)
          assert_equal({ type: "test_in_terminal", kind: :group, group_id: 1, id: 2 }, response[7].data)
          assert_equal({ type: "debug", kind: :group, group_id: 1, id: 2 }, response[8].data)

          response[6..8].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("context 1", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: context 1/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 1, start_column: 2, end_line: 5, end_column: 5 }, response_.command.arguments[3])
          end

          assert_equal({ type: "test", kind: :example, group_id: 2 }, response[9].data)
          assert_equal({ type: "test_in_terminal", kind: :example, group_id: 2 }, response[10].data)
          assert_equal({ type: "debug", kind: :example, group_id: 2 }, response[11].data)

          response[9..11].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("test 1", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: context 1 should test 1/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 2, start_column: 4, end_line: 4, end_column: 7 }, response_.command.arguments[3])
          end
        end
      end

      def test_multiple_contexts
        uri = URI("file:///fake_test.rb")

        source = <<~RUBY
          class MyTest < Minitest::Test
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
          end
        RUBY

        with_server(source, uri) do |server, uri|
          server.process_message(
            {
              id: 1,
              method: "textDocument/codeLens",
              params: {
                textDocument: { uri: uri },
                position: { line: 0, character: 0 },
              },
            },
          )

          server.pop_response # Drop the notification change message

          response = server.pop_response
          response = response.response

          assert_equal 18, response.count

          # Class
          assert_equal({ type: "test", kind: :group, group_id: nil, id: 1 }, response[3].data)
          assert_equal({ type: "test_in_terminal", kind: :group, group_id: nil, id: 1 }, response[4].data)
          assert_equal({ type: "debug", kind: :group, group_id: nil, id: 1 }, response[5].data)

          response[3..5].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("MyTest", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/MyTest/\"",
              response_.command.arguments[2],
            )
            assert_equal(
              { start_line: 0, start_column: 0, end_line: 12, end_column: 3 },
              response_.command.arguments[3],
            )
          end

          # Context 1
          assert_equal({ type: "test", kind: :group, group_id: 1, id: 2 }, response[6].data)
          assert_equal({ type: "test_in_terminal", kind: :group, group_id: 1, id: 2 }, response[7].data)
          assert_equal({ type: "debug", kind: :group, group_id: 1, id: 2 }, response[8].data)

          response[6..8].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("context 1", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: context 1/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 1, start_column: 2, end_line: 5, end_column: 5 }, response_.command.arguments[3])
          end

          # Context 1 -- Test 1
          assert_equal({ type: "test", kind: :example, group_id: 2 }, response[9].data)
          assert_equal({ type: "test_in_terminal", kind: :example, group_id: 2 }, response[10].data)
          assert_equal({ type: "debug", kind: :example, group_id: 2 }, response[11].data)

          response[9..11].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("test 1", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: context 1 should test 1/\"",
              response_.command.arguments[2],
            )
            assert_equal({ start_line: 2, start_column: 4, end_line: 4, end_column: 7 }, response_.command.arguments[3])
          end

          # Context 2
          assert_equal({ type: "test", kind: :group, group_id: 1, id: 3 }, response[12].data)
          assert_equal({ type: "test_in_terminal", kind: :group, group_id: 1, id: 3 }, response[13].data)
          assert_equal({ type: "debug", kind: :group, group_id: 1, id: 3 }, response[14].data)

          response[12..14].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("context 2", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: context 2/\"",
              response_.command.arguments[2],
            )
            assert_equal(
              { start_line: 7, start_column: 2, end_line: 11, end_column: 5 },
              response_.command.arguments[3],
            )
          end

          # Context 2 -- Test 1
          assert_equal({ type: "test", kind: :example, group_id: 3 }, response[15].data)
          assert_equal({ type: "test_in_terminal", kind: :example, group_id: 3 }, response[16].data)
          assert_equal({ type: "debug", kind: :example, group_id: 3 }, response[17].data)

          response[15..17].each do |response_|
            assert_equal("/fake_test.rb", response_.command.arguments[0])
            assert_equal("test 1", response_.command.arguments[1])
            assert_equal(
              "bundle exec ruby -ITest /fake_test.rb --name \"/test_: context 2 should test 1/\"",
              response_.command.arguments[2],
            )
            assert_equal(
              { start_line: 8, start_column: 4, end_line: 10, end_column: 7 },
              response_.command.arguments[3],
            )
          end
        end
      end
    end
  end
end
