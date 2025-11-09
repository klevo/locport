# frozen_string_literal: true

class LocportMainTest < Minitest::Test
  def test_default_task_is_list
    assert_equal "list", Locport::Main.default_task
  end
end
