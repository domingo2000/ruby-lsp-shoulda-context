# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "shoulda/context"

class Calculator
  def initialize; end

  def sum(a, b)
    a + b
  end

  def product(a, b)
    a * b
  end
end

class CalculatorTest < Minitest::Test
  context "context 1" do
    should "test 1" do
      assert true
    end
  end

  should "test 2" do
    assert true
  end
end
