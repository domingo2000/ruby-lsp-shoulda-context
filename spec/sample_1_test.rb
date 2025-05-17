# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "shoulda/context"

class CalculatorTest < Minitest::Test
  should "test 1" do
    assert true
  end

  should validate_prescence_of(:name)
end
