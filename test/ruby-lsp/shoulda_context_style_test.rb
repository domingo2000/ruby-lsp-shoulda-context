# typed: true
# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module RubyLspShouldaContext
    class ShouldaContextStyleTest < Minitest::Test
      def test_discover_context_with_should
        source = <<~RUBY
          module Foo
            class MyTest < Minitest::Test
              context "test 1" do
                should "test 11" do
                  assert true
                end

                should "test 12" do
                  assert true
                end
              end

              context "test 2" do
                should "test 21" do
                  assert true
                end
              end
            end
          end
        RUBY

        file = URI("file:///test.rb")

        with_server(source, file) do |server, uri|
          server.process_message(id: 1, method: "rubyLsp/discoverTests", params: {
            textDocument: { uri: uri },
          })

          result = pop_result(server)

          items = result.response
          assert_equal 1, items.size

          # Check class is root
          # TODO: Improve taking into account the module
          class_item = items.first
          assert_equal "Foo::MyTest", class_item.fetch(:id)
          assert_equal "Foo::MyTest", class_item.fetch(:label)
          assert_equal "framework:shoulda", class_item.fetch(:tags).first
          assert_equal 2, class_item.fetch(:children).size

          # Check context is child of class
          context_item = class_item.fetch(:children).first
          assert_equal "test 1", context_item.fetch(:id)
          assert_equal "test 1", context_item.fetch(:label)
          assert_equal "framework:shoulda", context_item.fetch(:tags).first
          assert_equal 2, context_item.fetch(:children).size

          # Check the should inside the class is child of context
          should_item = context_item.fetch(:children).first
          assert_equal "test 11", should_item.fetch(:id)
          assert_equal "test 11", should_item.fetch(:label)
          assert_equal "framework:shoulda", should_item.fetch(:tags).first
          assert_equal 0, should_item.fetch(:children).size

          # Check the second should inside the class is child of context
          should_item = context_item.fetch(:children).last
          assert_equal "test 12", should_item.fetch(:id)
          assert_equal "test 12", should_item.fetch(:label)
          assert_equal "framework:shoulda", should_item.fetch(:tags).first
          assert_equal 0, should_item.fetch(:children).size

          # Check second context
          context_item = class_item.fetch(:children).last
          assert_equal "test 2", context_item.fetch(:id)
          assert_equal "test 2", context_item.fetch(:label)
          assert_equal "framework:shoulda", context_item.fetch(:tags).first
          assert_equal 1, context_item.fetch(:children).size

          # Check the should inside the class is child of
          # the class
          should_item = context_item.fetch(:children).first
          assert_equal "test 21", should_item.fetch(:id)
          assert_equal "test 21", should_item.fetch(:label)
          assert_equal "framework:shoulda", should_item.fetch(:tags).first
          assert_equal 0, should_item.fetch(:children).size
        end
      end

      def test_discover_context
        source = <<~RUBY
          class MyTest < Minitest::Test
            context "test 1" do
              assert true
            end
          end
        RUBY

        file = URI("file:///test.rb")

        with_server(source, file) do |server, uri|
          server.process_message(id: 1, method: "rubyLsp/discoverTests", params: {
            textDocument: { uri: uri },
          })

          result = pop_result(server)

          items = result.response
          assert_equal 1, items.size

          test_item = items.first

          assert_equal "MyTest", test_item.fetch(:id)
          assert_equal "MyTest", test_item.fetch(:label)
          assert_equal "framework:shoulda", test_item.fetch(:tags).first
          assert_equal 1, test_item.fetch(:children).size

          # Inner context
          assert_equal "test 1", test_item.fetch(:children).first.fetch(:id)
          assert_equal "test 1", test_item.fetch(:children).first.fetch(:label)
          assert_equal "framework:shoulda", test_item.fetch(:children).first.fetch(:tags).first
          assert_equal 0, test_item.fetch(:children).first.fetch(:children).size
        end
      end

      def test_discover_should_with_methods
        source = <<~RUBY
          class MyTest < Minitest::Test
            should validate_prescence_of(:name)
          end
        RUBY

        file = URI("file:///test.rb")

        with_server(source, file) do |server, uri|
          server.process_message(id: 1, method: "rubyLsp/discoverTests", params: {
            textDocument: { uri: uri },
          })

          result = pop_result(server)

          items = result.response
          assert_equal 1, items.size

          class_item = items.first
          assert_equal "MyTest", class_item.fetch(:id)
          assert_equal "MyTest", class_item.fetch(:label)
          assert_equal "framework:shoulda", class_item.fetch(:tags).first

          # Check the should inside the class is child of
          # the class
          should_item = class_item.fetch(:children).first
          assert_equal "<validate_prescence_of(:name)>", should_item.fetch(:id)
          assert_equal "<validate_prescence_of(:name)>", should_item.fetch(:label)
          assert_equal "framework:shoulda", should_item.fetch(:tags).first
          assert_equal 0, should_item.fetch(:children).size
        end
      end

      def test_discover_should
        source = <<~RUBY
          class MyTest < Minitest::Test
            should "test 1" do
              assert true
            end
          end
        RUBY

        file = URI("file:///test.rb")

        with_server(source, file) do |server, uri|
          server.process_message(id: 1, method: "rubyLsp/discoverTests", params: {
            textDocument: { uri: uri },
          })

          result = pop_result(server)

          items = result.response
          assert_equal 1, items.size

          class_item = items.first
          assert_equal "MyTest", class_item.fetch(:id)
          assert_equal "MyTest", class_item.fetch(:label)
          assert_equal "framework:shoulda", class_item.fetch(:tags).first

          # Check the should inside the class is child of
          # the class
          should_item = class_item.fetch(:children).first
          assert_equal "test 1", should_item.fetch(:id)
          assert_equal "test 1", should_item.fetch(:label)
          assert_equal "framework:shoulda", should_item.fetch(:tags).first
          assert_equal 0, should_item.fetch(:children).size
        end
      end

      def test_not_discover_invalid_context
        source = <<~RUBY
          class MyTest < Minitest::Test
            context do
            end
          end
        RUBY

        file = URI("file:///test.rb")

        with_server(source, file) do |server, uri|
          server.process_message(id: 1, method: "rubyLsp/discoverTests", params: {
            textDocument: { uri: uri },
          })

          result = pop_result(server)

          items = result.response
          assert_equal 1, items.size

          test_item = items.first
          assert_equal "MyTest", test_item.fetch(:id)
          assert_equal "MyTest", test_item.fetch(:label)
          assert_equal "framework:shoulda", test_item.fetch(:tags).first
          assert_equal 0, test_item.fetch(:children).size
        end
      end

      def test_not_parse_if_not_in_test_class
        source = <<~RUBY
          context "test 1" do
            assert true
          end
        RUBY

        file = URI("file:///test.rb")

        with_server(source, file) do |server, uri|
          server.process_message(id: 1, method: "rubyLsp/discoverTests", params: {
            textDocument: { uri: uri },
          })

          result = pop_result(server)

          items = result.response
          assert_equal 0, items.size
        end
      end

      # Command Resolution

      def test_resolve_test_commands
        with_server do |server|
          server.process_message({
            id: 1,
            method: "rubyLsp/resolveTestCommands",
            params: {
              items: [
                {
                  id: "Foo::MyTest",
                  uri: "file:///test/my_test.rb",
                  label: "Foo::MyTest",
                  tags: ["framework:shoulda", "test_group"],
                  children: [
                    {
                      id: "test 1",
                      uri: "file:///test/my_test.rb",
                      label: "test 1",
                      tags: ["framework:shoulda", "test_group"],
                      children: [
                        {
                          id: "test 11",
                          uri: "file:///test/my_test.rb",
                          label: "test 11",
                          tags: ["framework:shoulda"],
                          children: [],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          })

          response = pop_result(server).response
          assert_equal(
            [
              "bundle exec ruby -ITest /test/my_test.rb --name \"/Foo::MyTest#test_: test 1 should test 11/\"",
            ],
            response[:commands],
          )
        end
      end
    end
  end
end
