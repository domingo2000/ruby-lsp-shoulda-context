# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "shoulda/context"

class CalculatorTest < Minitest::Test
  context "context 1" do
    should "test 1" do
      assert true
    end
  end

  context "context 2" do
    should "test 1" do
      assert true
    end

    should "test 2" do
      assert true
    end
  end
end
