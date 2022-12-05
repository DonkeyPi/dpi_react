defmodule Ash.React.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

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

  test "use state test" do
    State.start()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    set_id.(:value)

    # Cannot be called twice.
    assert_raise RuntimeError, "Duplicated state id: [:id]", fn ->
      Api.use_state(:id, :initial)
    end

    # Can be called again after reset.
    State.reset_state()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :value

    # Setters can be called from any process.
    spawn_link(fn -> set_id.(:remote) end)

    # Setters are synchronized to the main process.
    receive do
      {:react_cb, callback} -> callback.()
    end

    State.reset_state()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :remote
  end
end
