# frozen_string_literal: true

module Locport
  class ProjectTest < Minitest::Test
    def test_hello
      assert_equal "hi", Project.new.hello
    end
  end
end
