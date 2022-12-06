defmodule Ash.React.UseEffect.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  # Effects are all about guaranteed cleanups.
  # Resources that require explicit cleanup to avoid accumulating
  # overtime must be started and stopped from within an effect.
  test "use effect test - always effect without cleanup" do
    Buffer.start()

    # FORWARD RESETS SYNC TO TRUE
    State.start()

    State.before_markup()
    # MARKUP - SYNC READ / ASYNC WRITE
    Api.use_effect(:effect, fn -> Buffer.add("0") end)
    assert Buffer.get() == ""
    State.after_markup()

    assert Buffer.get() == "0"

    # FORWARD RESETS SYNC TO TRUE
    State.forward()

    State.before_markup()
    assert Buffer.get() == "0"
    # MARKUP - SYNC READ / ASYNC WRITE
    Api.use_effect(:effect, fn -> Buffer.add("0") end)
    assert Buffer.get() == "0"
    State.after_markup()

    assert Buffer.get() == "00"
  end

  test "use effect test - always effect with cleanup removed" do
    Buffer.start()

    # FORWARD RESETS SYNC TO TRUE
    State.start()

    State.before_markup()
    # MARKUP - SYNC READ / ASYNC WRITE
    Api.use_effect(:effect, fn ->
      Buffer.add("0")
      fn -> Buffer.add("1") end
    end)

    assert Buffer.get() == ""
    State.after_markup()

    assert Buffer.get() == "0"

    # FORWARD RESETS SYNC TO TRUE
    State.forward()

    State.before_markup()
    assert Buffer.get() == "0"
    # MARKUP - SYNC READ / ASYNC WRITE
    Api.use_effect(:effect, fn ->
      Buffer.add("0")
      fn -> Buffer.add("1") end
    end)

    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "010"
  end
end
