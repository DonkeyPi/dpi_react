defmodule Ash.HelpersTest do
  use ExUnit.Case
  alias Ash.React.Helpers

  test "helpers test" do
    assert "1" = Helpers.hex(1)
    assert "01" = Helpers.hex(1, 2)
    assert 2 = Helpers.clamp(1, 2, 3)
    assert 3 = Helpers.clamp(4, 2, 3)
  end
end
