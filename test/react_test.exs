defmodule Ash.React.Test do
  use ExUnit.Case
  alias Ash.React.State

  test "assert pid test" do
    State.start()

    pid = self()

    # API restricted to react process.
    spawn_link(fn ->
      assert_raise RuntimeError, "Invalid caller: #{inspect(self())}", fn ->
        State.assert_pid()
      end

      send(pid, :done)
    end)

    receive do
      :done -> :ok
    end
  end
end
