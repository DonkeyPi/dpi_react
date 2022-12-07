defmodule Ash.React.Timer.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  test "timer test - set_timeout" do
    State.start()
    Buffer.start()

    timer = Api.set_timeout(0, fn -> Buffer.add("a") end)
    Tester.on_callback()
    assert Buffer.get() == "a"
    timer.()
  end

  test "timer test - set_interval" do
    State.start()
    Buffer.start()

    timer = Api.set_interval(0, fn -> Buffer.add("a") end)
    Tester.on_callback()
    assert Buffer.get() == "a"
    Tester.on_callback()
    assert Buffer.get() == "aa"
    timer.()
  end
end
