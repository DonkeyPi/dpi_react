defmodule Ash.React.UseEffect.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  # Effect are all about guaranteed cleanups.
  # Resources that require explicit cleanup
  # to avoid accumulating overtime must be
  # started and stopped from within an effect.
  test "use effect test - always effect without cleanup" do
    State.start()
    Buffer.start()

    # Called during markup building.
    Api.use_effect(:effect, fn -> Buffer.add("0") end)

    State.push()
  end
end
