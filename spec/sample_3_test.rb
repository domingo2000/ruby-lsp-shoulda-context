# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "shoulda/context"

class CalculatorTest < Minitest::Test
  context "context 1" do
    should "test 1.1" do
      assert true
    end
  end

  context "context 2" do
    context "context 2.1" do
      should "test 2.1.1" do
        assert true
      end
    end
    should "test 2.1" do
      assert true
    end
  end

  should "test 3" do
  end

  should "test 4" do
  end
end
