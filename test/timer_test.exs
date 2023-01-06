defmodule Dpi.TimerTest do
  use ExUnit.Case
  alias Dpi.React.State
  alias Dpi.React.Api

  test "timer test - set_timeout" do
    State.start()
    Buffer.start()

    timer = Api.set_timeout(0, fn -> Buffer.add("a") end)
    Tester.on_callback()
    assert Buffer.get() == "a"
    timer.()
  end

  # Cancelation is flag dependant an it is guarantee that
  # callbacks wont fire after timer.() has been called from
  # the same react process that created it. That does not
  # depend on Process.cancel_timer race conditions.
  # Canceling from a different process is supported but
  # wont remove already queue messages.
  test "timer test - set_interval" do
    State.start()
    Buffer.start()

    timer = Api.set_interval(0, fn -> Buffer.add("a") end)
    Tester.on_callback()
    assert Buffer.get() == "a"
    Tester.on_callback()
    assert Buffer.get() == "aa"
    timer.()

    # check first interval wont trigger again
    timer = Api.set_interval(0, fn -> Buffer.add("b") end)

    for i <- 1..100 do
      Tester.on_callback()
      assert Buffer.get() == "aa" <> String.duplicate("b", i)
    end

    timer.()
  end
end
